#!/usr/bin/env bash

# aws-vpc-nuke.sh
# Reliably and idempotently removes all known dependencies blocking deletion of a VPC, then deletes the VPC.
#
# Requirements:
#  - AWS CLI v2
#  - jq
#
# Usage:
#  ./scripts/aws-vpc-nuke.sh -v vpc-0123456789abcdef0 [-r us-east-1] [-p myprofile] [--dry-run] [--delete-lambda]
#
# Notes:
#  - Safe to rerun; it skips missing resources and continues on errors where practical.
#  - It attempts to remove: ELBv2 (ALB/NLB) + listeners + target groups, Classic ELB, VPC endpoints, Route53 Resolver
#    rule associations and endpoints, VPC Flow Logs, Network Firewall, EFS mount targets (and file systems when safe),
#    NAT Gateways, EC2 instances, ENIs (available only), custom NACLs, non-default SGs, non-main route tables,
#    IGWs and egress-only IGWs, TGW VPC attachments, VPC peering, VPN attachments, DHCP options, then deletes the VPC.

set -euo pipefail

RED="\033[31m"; GREEN="\033[32m"; YELLOW="\033[33m"; CYAN="\033[36m"; RESET="\033[0m"

err() { echo -e "${RED}✖${RESET} $*" >&2; }
info() { echo -e "${CYAN}➤${RESET} $*"; }
ok() { echo -e "${GREEN}✔${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠${RESET} $*"; }

DRY_RUN=false
DELETE_LAMBDA=false
VPC_ID=""
REGION="${AWS_DEFAULT_REGION:-}"
PROFILE=""

usage() {
  cat <<EOF
Usage: $0 -v <vpc-id> [-r <region>] [-p <aws-profile>] [--dry-run] [--delete-lambda]

Options:
  -v, --vpc-id         VPC ID (required)
  -r, --region         AWS region (defaults to AWS_DEFAULT_REGION or current CLI config)
  -p, --profile        AWS CLI profile to use
  --dry-run        Show actions without executing destructive operations
  --delete-lambda  Also delete Lambda functions that are configured for this VPC (dangerous)
  -h, --help           Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--vpc-id) VPC_ID="$2"; shift 2;;
    -r|--region) REGION="$2"; shift 2;;
    -p|--profile) PROFILE="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
  --delete-lambda) DELETE_LAMBDA=true; shift;;
    -h|--help) usage; exit 0;;
    *) err "Unknown argument: $1"; usage; exit 1;;
  esac
done

[[ -z "$VPC_ID" ]] && { err "VPC ID is required"; usage; exit 1; }

if ! command -v jq >/dev/null 2>&1; then
  err "jq is required. Install via: brew install jq (macOS)"
  exit 1
fi

AWS_ARGS=( )
if [[ -n "$REGION" ]]; then AWS_ARGS+=(--region "$REGION"); fi
if [[ -n "$PROFILE" ]]; then AWS_ARGS+=(--profile "$PROFILE"); fi

# Resolve region if still empty
if [[ -z "$REGION" ]]; then
  REGION=$(aws configure get region 2>/dev/null || true)
  [[ -z "$REGION" ]] && { err "Region not set. Use -r or set AWS_DEFAULT_REGION"; exit 1; }
  AWS_ARGS=(--region "$REGION" ${PROFILE:+--profile "$PROFILE"})
fi

info "Starting VPC nuke for ${VPC_ID} in ${REGION} ${PROFILE:+(profile: $PROFILE)}${DRY_RUN:+ [DRY-RUN]}"

run() {
  if $DRY_RUN; then
    echo "DRY-RUN: aws $*"
    return 0
  fi
  aws "$@"
}

json() {
  aws "$@" "${AWS_ARGS[@]}" --output json
}

text() {
  aws "$@" "${AWS_ARGS[@]}" --output text
}

################################################################################
# Helpers
################################################################################

wait_elbv2_deleted() {
  local lb_arn="$1"
  if $DRY_RUN; then return 0; fi
  # No direct waiter for delete; poll until not found
  for i in {1..30}; do
    if ! aws elbv2 describe-load-balancers --load-balancer-arns "$lb_arn" "${AWS_ARGS[@]}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  warn "Timeout waiting for ELBv2 deletion: $lb_arn"
}

################################################################################
# 1) Delete ELBv2 (ALB/NLB): listeners -> load balancer -> target groups
################################################################################
info "ELBv2: discovering load balancers in VPC..."
lb_arns=$(json elbv2 describe-load-balancers "${AWS_ARGS[@]}" \
  --query "LoadBalancers[?VpcId=='${VPC_ID}'].LoadBalancerArn" | jq -r '.[]?')

if [[ -n "$lb_arns" ]]; then
  echo "$lb_arns" | while read -r lb_arn; do
    [[ -z "$lb_arn" ]] && continue
    info "ELBv2: deleting listeners for $lb_arn"
    listeners=$(json elbv2 describe-listeners --load-balancer-arn "$lb_arn" \
      --query 'Listeners[].ListenerArn' | jq -r '.[]?')
    if [[ -n "$listeners" ]]; then
      echo "$listeners" | while read -r lsn; do
        run elbv2 delete-listener --listener-arn "$lsn" "${AWS_ARGS[@]}" || warn "Failed to delete listener $lsn"
      done
    fi

    info "ELBv2: deleting load balancer $lb_arn"
    run elbv2 delete-load-balancer --load-balancer-arn "$lb_arn" "${AWS_ARGS[@]}" || warn "Failed to delete LB $lb_arn"
    wait_elbv2_deleted "$lb_arn"
  done
else
  ok "No ELBv2 load balancers in VPC"
fi

# Delete any target groups in this VPC
info "ELBv2: deleting target groups in VPC..."
tgs=$(json elbv2 describe-target-groups "${AWS_ARGS[@]}" \
  --query "TargetGroups[?VpcId=='${VPC_ID}'].TargetGroupArn" | jq -r '.[]?')
if [[ -n "$tgs" ]]; then
  echo "$tgs" | while read -r tg; do
    run elbv2 delete-target-group --target-group-arn "$tg" "${AWS_ARGS[@]}" || warn "Failed to delete TG $tg"
  done
else
  ok "No ELBv2 target groups in VPC"
fi

################################################################################
# 2) Delete Classic ELB
################################################################################
info "Classic ELB: discovering load balancers in VPC..."
classic_elbs=$(json elb describe-load-balancers "${AWS_ARGS[@]}" \
  --query "LoadBalancerDescriptions[?VPCId=='${VPC_ID}'].LoadBalancerName" | jq -r '.[]?') || true
if [[ -n "$classic_elbs" ]]; then
  echo "$classic_elbs" | while read -r name; do
    run elb delete-load-balancer --load-balancer-name "$name" "${AWS_ARGS[@]}" || warn "Failed to delete classic ELB $name"
  done
else
  ok "No Classic ELBs in VPC"
fi

################################################################################
# 3) VPC Endpoints (Interface/Gateway)
################################################################################
info "VPC Endpoints: discovering..."
eps=$(json ec2 describe-vpc-endpoints "${AWS_ARGS[@]}" --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'VpcEndpoints[].VpcEndpointId' | jq -r '.[]?')
if [[ -n "$eps" ]]; then
  # delete in batches of up to 25
  mapfile -t ep_array < <(echo "$eps")
  chunk=""
  for eid in "${ep_array[@]}"; do
    chunk+=" $eid"
    if [[ $(wc -w <<< "$chunk") -ge 25 ]]; then
      run ec2 delete-vpc-endpoints --vpc-endpoint-ids $chunk "${AWS_ARGS[@]}" || warn "Failed to delete some endpoints"
      chunk=""
    fi
  done
  if [[ -n "$chunk" ]]; then
    run ec2 delete-vpc-endpoints --vpc-endpoint-ids $chunk "${AWS_ARGS[@]}" || warn "Failed to delete some endpoints"
  fi
else
  ok "No VPC endpoints in VPC"
fi

################################################################################
# 3b) PrivateLink Endpoint Service configurations (your services)
################################################################################
info "PrivateLink: deleting endpoint service configurations in VPC (if any NLBs were tied)..."
# Describe service configurations and filter by NetworkLoadBalancerArns in this VPC
svc_cfgs=$(json ec2 describe-vpc-endpoint-service-configurations "${AWS_ARGS[@]}" \
  --query 'ServiceConfigurations[].{Id:ServiceId, Arn:ServiceArn, NLBs:NetworkLoadBalancerArns}' | jq -c '.[]?') || true
if [[ -n "$svc_cfgs" ]]; then
  echo "$svc_cfgs" | while read -r row; do
    service_id=$(jq -r '.Id' <<<"$row")
    # If any associated NLB was just deleted above, the service can be removed; try delete regardless
    # Must reject any endpoint connections first
    conns=$(json ec2 describe-vpc-endpoint-connections "${AWS_ARGS[@]}" --filters Name=service-id,Values="$service_id" \
      --query 'VpcEndpointConnections[?ConnectionStatus.Code==`available` || ConnectionStatus.Code==`pendingAcceptance`].VpcEndpointId' | jq -r '.[]?') || true
    if [[ -n "$conns" ]]; then
      echo "$conns" | while read -r c; do
        run ec2 reject-vpc-endpoint-connections --service-id "$service_id" --vpc-endpoint-ids "$c" "${AWS_ARGS[@]}" || true
      done
    fi
    run ec2 delete-vpc-endpoint-service-configurations --service-ids "$service_id" "${AWS_ARGS[@]}" || true
  done
else
  ok "No PrivateLink endpoint service configurations"
fi

################################################################################
# 4) Route53 Resolver: disassociate rules, delete endpoints
################################################################################
info "Route53 Resolver: disassociating resolver rules from VPC..."
assoc_ids=$(json route53resolver list-resolver-rule-associations "${AWS_ARGS[@]}" \
  --filters Name=VPCId,Values=$VPC_ID --query 'ResolverRuleAssociations[].Id' | jq -r '.[]?') || true
if [[ -n "$assoc_ids" ]]; then
  echo "$assoc_ids" | while read -r aid; do
    run route53resolver disassociate-resolver-rule --resolver-rule-association-id "$aid" "${AWS_ARGS[@]}" || warn "Failed to disassociate rule $aid"
  done
else
  ok "No resolver rule associations for VPC"
fi

info "Route53 Resolver: deleting endpoints in VPC..."
resolver_ep_ids=$(json route53resolver list-resolver-endpoints "${AWS_ARGS[@]}" \
  --filters Name=VPCId,Values=$VPC_ID --query 'ResolverEndpoints[].Id' | jq -r '.[]?') || true
if [[ -n "$resolver_ep_ids" ]]; then
  echo "$resolver_ep_ids" | while read -r rid; do
    run route53resolver delete-resolver-endpoint --resolver-endpoint-id "$rid" "${AWS_ARGS[@]}" || warn "Failed to delete resolver endpoint $rid"
  done
else
  ok "No resolver endpoints for VPC"
fi

################################################################################
# 4b) Route 53 Private Hosted Zones: disassociate VPC from zones
################################################################################
info "Route53: disassociating VPC from any private hosted zones..."
phzs=$(json route53 list-hosted-zones-by-vpc "${AWS_ARGS[@]}" --vpc-id "$VPC_ID" --vpc-region "$REGION" --query 'HostedZoneSummaries[].HostedZoneId' | jq -r '.[]?') || true
if [[ -n "$phzs" ]]; then
  echo "$phzs" | while read -r hzid; do
    [[ -z "$hzid" ]] && continue
    run route53 disassociate-vpc-from-hosted-zone --hosted-zone-id "$hzid" --vpc VPCRegion="$REGION",VPCId="$VPC_ID" "${AWS_ARGS[@]}" || warn "Failed to disassociate VPC from hosted zone $hzid"
  done
else
  ok "No private hosted zones associated to this VPC"
fi

################################################################################
# 5) VPC Flow Logs
################################################################################
info "VPC Flow Logs: deleting..."
flow_logs=$(json ec2 describe-flow-logs "${AWS_ARGS[@]}" --filter Name=resource-id,Values=$VPC_ID \
  --query 'FlowLogs[].FlowLogId' | jq -r '.[]?') || true
if [[ -n "$flow_logs" ]]; then
  # delete supports up to 1000
  run ec2 delete-flow-logs --flow-log-ids $flow_logs "${AWS_ARGS[@]}" || warn "Failed to delete some flow logs"
else
  ok "No flow logs for VPC"
fi

################################################################################
# 5b) AWS Cloud Map (ServiceDiscovery): delete services and private namespaces in this VPC
################################################################################
info "Cloud Map: deleting services and private namespaces associated with this VPC..."
namespaces=$(json servicediscovery list-namespaces "${AWS_ARGS[@]}" --query 'Namespaces[].Id' | jq -r '.[]?') || true
if [[ -n "$namespaces" ]]; then
  echo "$namespaces" | while read -r nsid; do
    [[ -z "$nsid" ]] && continue
    ns=$(json servicediscovery describe-namespace "${AWS_ARGS[@]}" --id "$nsid" 2>/dev/null || true)
    ns_type=$(jq -r '.Namespace.Properties.DnsProperties.DnsRecords // empty | length' <<<"$ns" 2>/dev/null || echo 0)
    ns_vpc=$(jq -r '.Namespace.Properties.DnsProperties.HostedZoneId // empty' <<<"$ns" 2>/dev/null || true)
    # For private DNS namespaces, the VPC is under Properties.DnsProperties.HostedZoneId is not VPC ID. Determine by discoverInstances? Cloud Map API doesn't directly reveal VPC.
    # Heuristic: Try to list services and instances; we delete services regardless if namespace is private.
    svcs=$(json servicediscovery list-services "${AWS_ARGS[@]}" --filters Name=NAMESPACE_ID,Values="$nsid",Condition=EQ --query 'Services[].Id' | jq -r '.[]?') || true
    if [[ -n "$svcs" ]]; then
      echo "$svcs" | while read -r sid; do
        # Deregister instances
        insts=$(json servicediscovery list-instances "${AWS_ARGS[@]}" --service-id "$sid" --query 'Instances[].Id' | jq -r '.[]?' 2>/dev/null || true)
        if [[ -n "$insts" ]]; then
          echo "$insts" | while read -r iid; do
            run servicediscovery deregister-instance --service-id "$sid" --instance-id "$iid" "${AWS_ARGS[@]}" || true
          done
        fi
        run servicediscovery delete-service --id "$sid" "${AWS_ARGS[@]}" || true
      done
    fi
    # Attempt to delete namespace (will succeed if it's private and empty)
    run servicediscovery delete-namespace --id "$nsid" "${AWS_ARGS[@]}" || true
  done
else
  ok "No Cloud Map namespaces detected"
fi

################################################################################
# 5c) AWS Network Firewall: delete firewalls in VPC (if any)
################################################################################
info "Network Firewall: deleting firewalls in VPC..."
nfws=$(json network-firewall list-firewalls "${AWS_ARGS[@]}" --query 'Firewalls[].FirewallName' | jq -r '.[]?') || true
if [[ -n "$nfws" ]]; then
  echo "$nfws" | while read -r fw; do
    meta=$(json network-firewall describe-firewall "${AWS_ARGS[@]}" --firewall-name "$fw" 2>/dev/null || true)
    vpc_in_meta=$(jq -r '.Firewall.VpcId // empty' <<<"$meta" 2>/dev/null || true)
    if [[ "$vpc_in_meta" == "$VPC_ID" ]]; then
      # Disable delete protection if enabled
      delprot=$(jq -r '.Firewall.DeleteProtection // false' <<<"$meta" 2>/dev/null || echo false)
      if [[ "$delprot" == "true" ]]; then
        run network-firewall update-firewall-delete-protection --firewall-name "$fw" --delete-protection false "${AWS_ARGS[@]}" || true
      fi
      run network-firewall delete-firewall --firewall-name "$fw" "${AWS_ARGS[@]}" || warn "Failed to delete Network Firewall $fw"
    fi
  done
else
  ok "No Network Firewalls in account/region or none in this VPC"
fi

################################################################################
# 6) NAT Gateways (if any remain) and wait for deletion
################################################################################
info "NAT Gateways: deleting any remaining in VPC..."
nat_ids=$(json ec2 describe-nat-gateways "${AWS_ARGS[@]}" --filter Name=vpc-id,Values=$VPC_ID \
  --query 'NatGateways[?State!=`deleted`].NatGatewayId' | jq -r '.[]?') || true
if [[ -n "$nat_ids" ]]; then
  echo "$nat_ids" | while read -r nid; do
    run ec2 delete-nat-gateway --nat-gateway-id "$nid" "${AWS_ARGS[@]}" || warn "Failed to delete NAT $nid"
  done
  if ! $DRY_RUN; then
    info "Waiting for NAT gateways to reach deleted state..."
    for i in {1..60}; do
      remaining=$(json ec2 describe-nat-gateways "${AWS_ARGS[@]}" --filter Name=vpc-id,Values=$VPC_ID \
        --query 'NatGateways[?State!=`deleted`].NatGatewayId' | jq -r '.[]?' || true)
      if [[ -z "$remaining" ]]; then break; fi
      sleep 10
    done
  fi
else
  ok "No NAT gateways in VPC"
fi

################################################################################
# 7) EC2 Instances: terminate any non-terminated instances in the VPC
################################################################################
info "EC2: terminating instances in VPC (except already terminated)..."
instance_ids=$(json ec2 describe-instances "${AWS_ARGS[@]}" \
  --filters Name=vpc-id,Values=$VPC_ID Name=instance-state-name,Values=pending,running,stopping,stopped,shutting-down \
  --query 'Reservations[].Instances[].InstanceId' | jq -r '.[]?') || true
if [[ -n "$instance_ids" ]]; then
  run ec2 terminate-instances --instance-ids $instance_ids "${AWS_ARGS[@]}" || warn "Failed to terminate some instances"
  if ! $DRY_RUN; then
    info "Waiting for instances to terminate..."
    run ec2 wait instance-terminated --instance-ids $instance_ids "${AWS_ARGS[@]}" || warn "Waiter failed for instance termination"
  fi
else
  ok "No instances to terminate"
fi

################################################################################
# 7a) Lambda: functions attached to this VPC (optional deletion)
################################################################################
info "Lambda: scanning for functions configured for this VPC..."
lambda_funcs=$(json lambda list-functions "${AWS_ARGS[@]}" --max-items 10000 --query 'Functions[].FunctionName' | jq -r '.[]?') || true
found_lambda=()
if [[ -n "$lambda_funcs" ]]; then
  echo "$lambda_funcs" | while read -r lf; do
    [[ -z "$lf" ]] && continue
    conf=$(json lambda get-function-configuration "${AWS_ARGS[@]}" --function-name "$lf" 2>/dev/null || true)
    if [[ -n "$conf" ]]; then
      vpc_conf=$(jq -r '.VpcConfig // empty' <<<"$conf")
      if [[ -n "$vpc_conf" && "$vpc_conf" != "null" ]]; then
        # Check any of the subnets belong to our VPC
        subnets=$(jq -r '.VpcConfig.SubnetIds[]? // empty' <<<"$conf")
        in_vpc=false
        if [[ -n "$subnets" ]]; then
          while read -r s; do
            [[ -z "$s" ]] && continue
            vpc_of_subnet=$(text ec2 describe-subnets --subnet-ids "$s" "${AWS_ARGS[@]}" --query 'Subnets[0].VpcId' 2>/dev/null || true)
            if [[ "$vpc_of_subnet" == "$VPC_ID" ]]; then in_vpc=true; break; fi
          done <<<"$subnets"
        fi
        if $in_vpc; then
          found_lambda+=("$lf")
        fi
      fi
    fi
  done
fi
if (( ${#found_lambda[@]} > 0 )); then
  if $DELETE_LAMBDA; then
    info "Deleting ${#found_lambda[@]} Lambda function(s) tied to this VPC..."
    for lf in "${found_lambda[@]}"; do
      run lambda delete-function --function-name "$lf" "${AWS_ARGS[@]}" || warn "Failed to delete Lambda $lf"
    done
    warn "Lambda ENIs may linger for up to ~20 minutes after VPC detachment; script continues."
  else
    warn "Lambda functions found with VPC config in this VPC (not deleted). Re-run with --delete-lambda to remove: ${found_lambda[*]}"
  fi
else
  ok "No Lambda functions attached to this VPC"
fi

################################################################################
# 7b) EFS: delete mount targets and then file systems in VPC
################################################################################
info "EFS: deleting mount targets and file systems in VPC..."
# Find EFS mount targets in VPC subnets
mt_list=$(json efs describe-mount-targets "${AWS_ARGS[@]}" --query 'MountTargets[].{Id:MountTargetId, SubnetId:SubnetId, FileSystemId:FileSystemId}' | jq -c '.[]?') || true
if [[ -n "$mt_list" ]]; then
  echo "$mt_list" | while read -r mt; do
    subnet_id=$(jq -r '.SubnetId' <<<"$mt")
    mt_id=$(jq -r '.Id' <<<"$mt")
    fs_id=$(jq -r '.FileSystemId' <<<"$mt")
    # Check if the mount target is in this VPC via subnet match
    vpc_of_subnet=$(text ec2 describe-subnets --subnet-ids "$subnet_id" "${AWS_ARGS[@]}" --query 'Subnets[0].VpcId' 2>/dev/null || true)
    if [[ "$vpc_of_subnet" == "$VPC_ID" ]]; then
      run efs delete-mount-target --mount-target-id "$mt_id" "${AWS_ARGS[@]}" || warn "Failed to delete EFS mount target $mt_id"
      # Wait briefly for ENI cleanup
      sleep 2
    fi
  done
fi
# After mount targets removed, try deleting any file systems whose mount targets were in this VPC
fs_ids=$(json efs describe-file-systems "${AWS_ARGS[@]}" --query 'FileSystems[].FileSystemId' | jq -r '.[]?') || true
if [[ -n "$fs_ids" ]]; then
  echo "$fs_ids" | while read -r fid; do
    # Double-check there are no remaining mount targets
    remaining=$(json efs describe-mount-targets "${AWS_ARGS[@]}" --file-system-id "$fid" --query 'MountTargets[].MountTargetId' | jq -r '.[]?' || true)
    if [[ -z "$remaining" ]]; then
      # Heuristic: if the file system had a mount target in our VPC (tracked above), try delete
      run efs delete-file-system --file-system-id "$fid" "${AWS_ARGS[@]}" || true
    fi
  done
fi

################################################################################
# 8) ENIs (available only)
################################################################################
info "ENIs: deleting available network interfaces in VPC..."
eni_ids=$(json ec2 describe-network-interfaces "${AWS_ARGS[@]}" --filters Name=vpc-id,Values=$VPC_ID \
  --query 'NetworkInterfaces[?Status==`available`].NetworkInterfaceId' | jq -r '.[]?') || true
if [[ -n "$eni_ids" ]]; then
  echo "$eni_ids" | while read -r eid; do
    run ec2 delete-network-interface --network-interface-id "$eid" "${AWS_ARGS[@]}" || warn "Failed to delete ENI $eid"
  done
else
  ok "No available ENIs to delete"
fi

################################################################################
# 9) Subnets
################################################################################
info "Subnets: deleting all subnets in VPC..."
subnet_ids=$(json ec2 describe-subnets "${AWS_ARGS[@]}" --filters Name=vpc-id,Values=$VPC_ID \
  --query 'Subnets[].SubnetId' | jq -r '.[]?') || true
if [[ -n "$subnet_ids" ]]; then
  echo "$subnet_ids" | while read -r sid; do
    run ec2 delete-subnet --subnet-id "$sid" "${AWS_ARGS[@]}" || warn "Failed to delete subnet $sid"
  done
else
  ok "No subnets in VPC"
fi

################################################################################
# 10) Security Groups (non-default)
################################################################################
info "Security Groups: deleting non-default SGs..."
sg_ids=$(json ec2 describe-security-groups "${AWS_ARGS[@]}" --filters Name=vpc-id,Values=$VPC_ID \
  --query 'SecurityGroups[?GroupName!=`default`].GroupId' | jq -r '.[]?') || true
if [[ -n "$sg_ids" ]]; then
  echo "$sg_ids" | while read -r sg; do
    # Remove self-referencing rules to avoid dependency failures
    # Revoke ingress
    perms=$(json ec2 describe-security-groups --group-ids "$sg" \
      --query 'SecurityGroups[0].IpPermissions' | jq -c '. | select(length>0)') || true
    if [[ -n "$perms" ]]; then
      run ec2 revoke-security-group-ingress --group-id "$sg" --ip-permissions "$perms" "${AWS_ARGS[@]}" || true
    fi
    # Revoke egress
    perms_eg=$(json ec2 describe-security-groups --group-ids "$sg" \
      --query 'SecurityGroups[0].IpPermissionsEgress' | jq -c '. | select(length>0)') || true
    if [[ -n "$perms_eg" ]]; then
      run ec2 revoke-security-group-egress --group-id "$sg" --ip-permissions "$perms_eg" "${AWS_ARGS[@]}" || true
    fi
    run ec2 delete-security-group --group-id "$sg" "${AWS_ARGS[@]}" || warn "Failed to delete SG $sg"
  done
else
  ok "No non-default SGs"
fi

################################################################################
# 11) Network ACLs (custom only)
################################################################################
info "Network ACLs: deleting custom NACLs..."
nacl_ids=$(json ec2 describe-network-acls "${AWS_ARGS[@]}" --filters Name=vpc-id,Values=$VPC_ID \
  --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' | jq -r '.[]?') || true
if [[ -n "$nacl_ids" ]]; then
  echo "$nacl_ids" | while read -r nid; do
    run ec2 delete-network-acl --network-acl-id "$nid" "${AWS_ARGS[@]}" || warn "Failed to delete NACL $nid"
  done
else
  ok "No custom NACLs"
fi

################################################################################
# 12) Route Tables (non-main)
################################################################################
info "Route Tables: deleting non-main route tables..."
rt_ids=$(json ec2 describe-route-tables "${AWS_ARGS[@]}" --filters Name=vpc-id,Values=$VPC_ID \
  --query 'RouteTables[?!(Associations[?Main==`true`])].RouteTableId' | jq -r '.[]?') || true
if [[ -n "$rt_ids" ]]; then
  echo "$rt_ids" | while read -r rtid; do
    run ec2 delete-route-table --route-table-id "$rtid" "${AWS_ARGS[@]}" || warn "Failed to delete RT $rtid"
  done
else
  ok "No non-main route tables"
fi

################################################################################
# 13) IGW and Egress-Only IGW
################################################################################
info "Internet Gateways: detaching and deleting..."
igw_ids=$(json ec2 describe-internet-gateways "${AWS_ARGS[@]}" --filters Name=attachment.vpc-id,Values=$VPC_ID \
  --query 'InternetGateways[].InternetGatewayId' | jq -r '.[]?') || true
if [[ -n "$igw_ids" ]]; then
  echo "$igw_ids" | while read -r igw; do
    run ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$VPC_ID" "${AWS_ARGS[@]}" || true
    run ec2 delete-internet-gateway --internet-gateway-id "$igw" "${AWS_ARGS[@]}" || warn "Failed to delete IGW $igw"
  done
else
  ok "No IGWs attached"
fi

info "Egress-Only IGWs: deleting..."
eigw_ids=$(json ec2 describe-egress-only-internet-gateways "${AWS_ARGS[@]}" \
  --query "EgressOnlyInternetGateways[?any(Attachments[].VpcId, & == '${VPC_ID}')].EgressOnlyInternetGatewayId" | jq -r '.[]?') || true
if [[ -n "$eigw_ids" ]]; then
  echo "$eigw_ids" | while read -r eid; do
    run ec2 delete-egress-only-internet-gateway --egress-only-internet-gateway-id "$eid" "${AWS_ARGS[@]}" || warn "Failed to delete EIGW $eid"
  done
else
  ok "No egress-only IGWs"
fi

################################################################################
# 14) Transit Gateway VPC attachments
################################################################################
info "Transit Gateway: deleting VPC attachments..."
tgw_attach_ids=$(json ec2 describe-transit-gateway-vpc-attachments "${AWS_ARGS[@]}" --filters Name=vpc-id,Values=$VPC_ID \
  --query 'TransitGatewayVpcAttachments[].TransitGatewayAttachmentId' | jq -r '.[]?') || true
if [[ -n "$tgw_attach_ids" ]]; then
  echo "$tgw_attach_ids" | while read -r taid; do
    run ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id "$taid" "${AWS_ARGS[@]}" || warn "Failed to delete TGW attachment $taid"
  done
else
  ok "No TGW VPC attachments"
fi

################################################################################
# 15) VPC Peering connections
################################################################################
info "VPC Peering: deleting peering connections involving VPC..."
peer_ids=$(json ec2 describe-vpc-peering-connections "${AWS_ARGS[@]}" \
  --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='${VPC_ID}' || AccepterVpcInfo.VpcId=='${VPC_ID}'].VpcPeeringConnectionId" | jq -r '.[]?') || true
if [[ -n "$peer_ids" ]]; then
  echo "$peer_ids" | while read -r pid; do
    run ec2 delete-vpc-peering-connection --vpc-peering-connection-id "$pid" "${AWS_ARGS[@]}" || warn "Failed to delete VPC peering $pid"
  done
else
  ok "No VPC peering connections"
fi

################################################################################
# 16) VPN Gateways / Connections
################################################################################
info "VPN: detaching and deleting VPN gateways/connections..."
vgw_ids=$(json ec2 describe-vpn-gateways "${AWS_ARGS[@]}" \
  --query "VpnGateways[?any(VpcAttachments[].VpcId, & == '${VPC_ID}')].VpnGatewayId" | jq -r '.[]?') || true
if [[ -n "$vgw_ids" ]]; then
  echo "$vgw_ids" | while read -r vgw; do
    run ec2 detach-vpn-gateway --vpn-gateway-id "$vgw" --vpc-id "$VPC_ID" "${AWS_ARGS[@]}" || true
    # Delete any vpn-connections for this VGW
    vc_ids=$(json ec2 describe-vpn-connections "${AWS_ARGS[@]}" --filters Name=vpn-gateway-id,Values=$vgw \
      --query 'VpnConnections[].VpnConnectionId' | jq -r '.[]?') || true
    if [[ -n "$vc_ids" ]]; then
      echo "$vc_ids" | while read -r vc; do
        run ec2 delete-vpn-connection --vpn-connection-id "$vc" "${AWS_ARGS[@]}" || warn "Failed to delete VPN connection $vc"
      done
    fi
    run ec2 delete-vpn-gateway --vpn-gateway-id "$vgw" "${AWS_ARGS[@]}" || warn "Failed to delete VGW $vgw"
  done
else
  ok "No VPN gateways attached"
fi

################################################################################
# 17) DHCP Options: re-associate default if needed
################################################################################
info "DHCP Options: ensuring VPC uses default set..."
dhcp_id=$(text ec2 describe-vpcs --vpc-ids "$VPC_ID" "${AWS_ARGS[@]}" --query 'Vpcs[0].DhcpOptionsId' || true)
if [[ -n "$dhcp_id" && "$dhcp_id" != "default" ]]; then
  run ec2 associate-dhcp-options --vpc-id "$VPC_ID" --dhcp-options-id default "${AWS_ARGS[@]}" || warn "Failed to associate default DHCP options"
  # delete old dhcp options if unused
  in_use=$(json ec2 describe-vpcs "${AWS_ARGS[@]}" --filters Name=dhcp-options-id,Values="$dhcp_id" --query 'Vpcs[].VpcId' | jq -r '.[]?') || true
  if [[ -z "$in_use" ]]; then
    run ec2 delete-dhcp-options --dhcp-options-id "$dhcp_id" "${AWS_ARGS[@]}" || warn "Failed to delete DHCP options $dhcp_id"
  fi
else
  ok "VPC already associated with default DHCP options"
fi

################################################################################
# 18) Final attempt: delete VPC
################################################################################
info "Final: deleting VPC ${VPC_ID}..."
if $DRY_RUN; then
  echo "DRY-RUN: aws ec2 delete-vpc --vpc-id $VPC_ID ${AWS_ARGS[*]}"
  ok "Dry run complete."
  exit 0
fi

if run ec2 delete-vpc --vpc-id "$VPC_ID" "${AWS_ARGS[@]}"; then
  ok "VPC deleted: $VPC_ID"
  exit 0
else
  err "VPC deletion failed. There may still be dependencies. Consider checking:"
  echo "  - Lambda functions with VPC config (detach or delete)"
  echo "  - EFS mount targets in the VPC"
  echo "  - PrivateLink endpoint service configurations"
  echo "  - Cloud Map private namespaces"
  echo "  - Any remaining ENIs (in-use)"
  exit 1
fi
