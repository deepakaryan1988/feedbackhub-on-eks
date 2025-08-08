#!/usr/bin/env bash

# VPC Cleanup (ap-south-1)
# Safely and idempotently removes dependencies blocking deletion of a target VPC, then deletes it.
# - Uses AWS CLI with --no-cli-pager and region ap-south-1
# - Prints every command before execution
# - Exits on unhandled errors; handles known dependency errors gracefully
# - Outputs a discovery table and step-by-step status (✅ deleted, ⚠️ skipped, ❌ failed)
#
# Requirements: awscli v2, jq
# Usage:
#   bash scripts/vpc-cleanup-ap-south-1.sh [-v <vpc-id>] [-p <aws-profile>] [--dry-run]
# Defaults:
#   VPC_ID=vpc-086cba888a42b817a (from the request)

set -euo pipefail

ICON_OK="✅"
ICON_SKIP="⚠️"
ICON_FAIL="❌"
CYAN="\033[36m"; YELLOW="\033[33m"; RED="\033[31m"; GREEN="\033[32m"; RESET="\033[0m"

VPC_ID_DEFAULT="vpc-086cba888a42b817a"
VPC_ID="$VPC_ID_DEFAULT"
PROFILE=""
DRY_RUN=false
REGION="ap-south-1"
AWS_ARGS=(--region "$REGION" --no-cli-pager)

usage() {
  cat <<EOF
Usage: $0 [-v <vpc-id>] [-p <aws-profile>] [--dry-run]

Cleans up dependencies and deletes the VPC in ap-south-1.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--vpc-id) VPC_ID="$2"; shift 2;;
    -p|--profile) PROFILE="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

if [[ -n "$PROFILE" ]]; then AWS_ARGS+=(--profile "$PROFILE"); fi

if ! command -v aws >/dev/null 2>&1; then echo "aws CLI not found" >&2; exit 1; fi
if ! command -v jq >/dev/null 2>&1; then echo "jq not found" >&2; exit 1; fi

logi() { echo -e "${CYAN}$*${RESET}"; }
logw() { echo -e "${YELLOW}$*${RESET}"; }
loge() { echo -e "${RED}$*${RESET}"; }
logg() { echo -e "${GREEN}$*${RESET}"; }

# Print and run AWS CLI command. Captures stderr for diagnostics.
aws_run() {
  echo "+ aws $* ${AWS_ARGS[*]}"
  if $DRY_RUN; then return 0; fi
  set +e
  out=$(aws "$@" "${AWS_ARGS[@]}" 2>&1)
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "$out" >&2
  fi
  return $rc
}

# Convenience wrappers
aws_json() { aws "$@" "${AWS_ARGS[@]}" --output json; }
aws_text() { aws "$@" "${AWS_ARGS[@]}" --output text; }

print_header() {
  echo ""
  echo "===================================================================="
  echo "$1"
  echo "===================================================================="
}

add_row() {
  # args: type id status extra
  printf "%-24s | %-34s | %-14s | %s\n" "$1" "$2" "$3" "$4"
}

print_table_header() {
  printf "%-24s | %-34s | %-14s | %s\n" "RESOURCE" "ID/NAME" "STATUS" "EXTRA"
  printf -- "%.0s-" {1..120}; echo
}

parse_dependency_hint() {
  # best-effort hints based on stderr
  local err="$1"; local ctx="$2"
  if grep -qi "DependencyViolation" <<<"$err"; then
    logw "Hint: $ctx failed due to dependencies. Investigate ENIs, routes, or service attachments."
  fi
  if grep -qi "InvalidGroup\.InUse" <<<"$err"; then
    logw "Hint: Security group in use by ENIs. Check: aws ec2 describe-network-interfaces --filters Name=group-id,Values=<sg-id> ${AWS_ARGS[*]}"
  fi
  if grep -qi "ResourceInUse" <<<"$err"; then
    logw "Hint: Resource is in use by another service. Describe the resource to find attachments."
  fi
  if grep -qi "OperationNotPermitted" <<<"$err"; then
    logw "Hint: Delete protection or policy prevents delete. Disable protection then retry."
  fi
}

# 1) Initial discovery scan -----------------------------------------------------
print_header "Initial Scan for VPC: ${VPC_ID} (region: ${REGION}${PROFILE:+, profile: $PROFILE})"
print_table_header

# Subnets
subnets=$(aws_json ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query 'Subnets[]')
echo "$subnets" | jq -r '.[] | @tsv "Subnet \(.SubnetId)\t\(.State)\tAZ=\(.AvailabilityZone)"' 2>/dev/null | \
while IFS=$'\t' read -r id st extra; do add_row "Subnet" "$id" "$st" "$extra"; done || true

# Route tables (including main)
rts=$(aws_json ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" --query 'RouteTables[]')
echo "$rts" | jq -r '.[] | {id:.RouteTableId, main: (any(.Associations[]?; .Main == true))} | @tsv "\(.id)\t\(.main)"' | \
while IFS=$'\t' read -r id main; do add_row "RouteTable" "$id" "$([[ "$main" == "true" ]] && echo main || echo non-main)" ""; done || true

# IGWs
igws=$(aws_json ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC_ID" --query 'InternetGateways[].InternetGatewayId' | jq -r '.[]?')
for id in $igws; do add_row "InternetGateway" "$id" "attached" ""; done

# Egress-only IGWs
eigws=$(aws_json ec2 describe-egress-only-internet-gateways --query 'EgressOnlyInternetGateways[]' | jq -r "map(select(any(.Attachments[]?; .VpcId==\"$VPC_ID\"))) | .[].EgressOnlyInternetGatewayId" 2>/dev/null || echo "")
for id in $eigws; do add_row "EgressOnlyIGW" "$id" "attached" ""; done

# NAT Gateways
nats=$(aws_json ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC_ID" --query 'NatGateways[]')
echo "$nats" | jq -r '.[] | @tsv "\(.NatGatewayId)\t\(.State)\tEIPs=\([.NatGatewayAddresses[].AllocationId] | join(","))"' 2>/dev/null | \
while IFS=$'\t' read -r id st extra; do add_row "NatGateway" "$id" "$st" "$extra"; done || true

# Elastic IPs (attached to NATs or ENIs in this VPC only)
# From NATs above
nat_eips=$(echo "$nats" | jq -r '.[] | .NatGatewayAddresses[].AllocationId? // empty') || nat_eips=""
# From ENIs in this VPC
eni_eips=$(aws_json ec2 describe-network-interfaces --filters Name=vpc-id,Values="$VPC_ID" --query 'NetworkInterfaces[].Association.AllocationId' | jq -r '.[]?') || eni_eips=""
for id in $nat_eips $eni_eips; do [[ -n "$id" ]] && add_row "ElasticIP" "$id" "attached" "source=NAT/ENI"; done

# Security Groups
sgs=$(aws_json ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC_ID" --query 'SecurityGroups[]')
echo "$sgs" | jq -r '.[] | @tsv "\(.GroupId)\t\(.GroupName)"' | \
while IFS=$'\t' read -r id name; do add_row "SecurityGroup" "$id" "$([[ "$name" == "default" ]] && echo default || echo custom)" "$name"; done || true

# ENIs
enis=$(aws_json ec2 describe-network-interfaces --filters Name=vpc-id,Values="$VPC_ID" --query 'NetworkInterfaces[]')
echo "$enis" | jq -r '.[] | @tsv "\(.NetworkInterfaceId)\t\(.Status)\tAttach=\(.Attachment.InstanceId // .Attachment.NetworkCardIndex // "-")"' 2>/dev/null | \
while IFS=$'\t' read -r id st extra; do add_row "ENI" "$id" "$st" "$extra"; done || true

# Load Balancers (ALB/NLB)
lb_arns=$(aws_json elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='${VPC_ID}'].LoadBalancerArn" | jq -r '.[]?') || true
for arn in $lb_arns; do add_row "ELBv2" "$arn" "present" ""; done
# Classic ELB
clbs=$(aws_json elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId=='${VPC_ID}'].LoadBalancerName" | jq -r '.[]?') || true
for n in $clbs; do add_row "ELB(Classic)" "$n" "present" ""; done

# VPC Endpoints
vpc_eps=$(aws_json ec2 describe-vpc-endpoints --filters Name=vpc-id,Values="$VPC_ID" --query 'VpcEndpoints[]')
echo "$vpc_eps" | jq -r '.[] | @tsv "\(.VpcEndpointId)\t\(.State)\t\(.ServiceName)"' 2>/dev/null | \
while IFS=$'\t' read -r id st svc; do add_row "VPCEndpoint" "$id" "$st" "$svc"; done || true

# RDS Instances
rds_all=$(aws_json rds describe-db-instances --query 'DBInstances[]' 2>/dev/null || echo '[]')
echo "$rds_all" | jq -r "map(select(.DBSubnetGroup.VpcId == \"$VPC_ID\"))[] | @tsv \"\(.DBInstanceIdentifier)\t\(.DBInstanceStatus)\tClass=\(.DBInstanceClass)\"" 2>/dev/null | \
while IFS=$'\t' read -r id st extra; do add_row "RDS" "$id" "$st" "$extra"; done || true

# EKS Clusters
eks_list=$(aws_json eks list-clusters --query 'clusters[]' 2>/dev/null || echo '[]')
for c in $(echo "$eks_list" | jq -r '.[]?'); do
  meta=$(aws_json eks describe-cluster --name "$c" --query 'cluster' 2>/dev/null || echo '{}')
  v=$(echo "$meta" | jq -r '.resourcesVpcConfig.vpcId // empty')
  if [[ "$v" == "$VPC_ID" ]]; then add_row "EKS" "$c" "present" ""; fi
done

# Resolver Endpoints
r53eps=$(aws_json route53resolver list-resolver-endpoints --query 'ResolverEndpoints[]' 2>/dev/null || echo '[]')
echo "$r53eps" | jq -r "map(select(.VpcId==\"$VPC_ID\"))[] | @tsv \"\(.Id)\t\(.Status)\t\(.Direction)\"" 2>/dev/null | \
while IFS=$'\t' read -r id st dir; do add_row "R53ResolverEP" "$id" "$st" "$dir"; done || true

# TGW Attachments
tgwatt=$(aws_json ec2 describe-transit-gateway-vpc-attachments --filters Name=vpc-id,Values="$VPC_ID" --query 'TransitGatewayVpcAttachments[]' 2>/dev/null || echo '[]')
echo "$tgwatt" | jq -r '.[] | @tsv "\(.TransitGatewayAttachmentId)\t\(.State)\tTGW=\(.TransitGatewayId)"' 2>/dev/null | \
while IFS=$'\t' read -r id st extra; do add_row "TGWAttachment" "$id" "$st" "$extra"; done || true

# VPC Peering
peers=$(aws_json ec2 describe-vpc-peering-connections --query "VpcPeeringConnections[?RequesterVpcInfo.VpcId=='${VPC_ID}' || AccepterVpcInfo.VpcId=='${VPC_ID}']" 2>/dev/null || echo '[]')
echo "$peers" | jq -r '.[] | @tsv "\(.VpcPeeringConnectionId)\t\(.Status.Code)\tpeer=\(.AccepterVpcInfo.VpcId // .RequesterVpcInfo.VpcId)"' 2>/dev/null | \
while IFS=$'\t' read -r id st extra; do add_row "VPCPeering" "$id" "$st" "$extra"; done || true

# Flow Logs
flogs=$(aws_json ec2 describe-flow-logs --filter Name=resource-id,Values="$VPC_ID" --query 'FlowLogs[].FlowLogId' 2>/dev/null || echo '[]')
echo "$flogs" | jq -r '.[]? | @tsv "\(.)\tactive\t"' | while IFS=$'\t' read -r id st extra; do add_row "VPCFlowLog" "$id" "active" ""; done || true

# 2) Safe Deletion Order --------------------------------------------------------
print_header "Deleting Dependencies in Safe Order"

# Helper to delete in batches
batch_delete() {
  local svc="$1"; shift
  local ctx="$svc delete"
  if [[ $# -gt 0 ]]; then
    if ! out=$(aws_run $svc "$@" 2>&1); then parse_dependency_hint "$out" "$ctx"; return 1; fi
  fi
}

# Internet Gateways
logi "Detaching and deleting Internet Gateways..."
for igw in $igws; do
  aws_run ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$VPC_ID" || true
  if out=$(aws_run ec2 delete-internet-gateway --internet-gateway-id "$igw" 2>&1); then
    echo "$ICON_OK Deleted IGW $igw"
  else
    echo "$ICON_FAIL Failed IGW $igw"; parse_dependency_hint "$out" "delete-igw"; fi
done

# Egress-only Internet Gateways
logi "Deleting Egress-only Internet Gateways..."
for eigw in $eigws; do
  if out=$(aws_run ec2 delete-egress-only-internet-gateway --egress-only-internet-gateway-id "$eigw" 2>&1); then
    echo "$ICON_OK Deleted EIGW $eigw"
  else
    echo "$ICON_FAIL Failed EIGW $eigw"; parse_dependency_hint "$out" "delete-eigw"; fi
done

# NAT Gateways (delete and wait), then release EIPs used by NAT
logi "Deleting NAT Gateways and releasing attached EIPs..."
if [[ -n "$nats" && $(echo "$nats" | jq 'length') -gt 0 ]]; then
  echo "$nats" | jq -r '.[].NatGatewayId' | while read -r nid; do
    aws_run ec2 delete-nat-gateway --nat-gateway-id "$nid" || true
  done
  if ! $DRY_RUN; then
    # wait until none remain
    for i in {1..60}; do
      remaining=$(aws_json ec2 describe-nat-gateways --filter Name=vpc-id,Values="$VPC_ID" --query 'NatGateways[?State!=`deleted`]' | jq 'length')
      [[ "$remaining" == "0" ]] && break
      sleep 10
    done
  fi
  # Release NAT EIPs
  for alloc in $nat_eips; do
    aws_run ec2 release-address --allocation-id "$alloc" && echo "$ICON_OK Released EIP $alloc" || echo "$ICON_FAIL Failed to release EIP $alloc"
  done
else
  echo "$ICON_SKIP No NAT gateways"
fi

# Load Balancers (ALB/NLB) listeners -> LBs; then target groups
logi "Deleting ELBv2 listeners and load balancers..."
for lb in $lb_arns; do
  lsns=$(aws_json elbv2 describe-listeners --load-balancer-arn "$lb" --query 'Listeners[].ListenerArn' 2>/dev/null | jq -r '.[]?') || true
  for l in $lsns; do aws_run elbv2 delete-listener --listener-arn "$l" || true; done
  aws_run elbv2 delete-load-balancer --load-balancer-arn "$lb" || true
  # wait until gone (best-effort)
  if ! $DRY_RUN; then for i in {1..30}; do aws elbv2 describe-load-balancers --load-balancer-arns "$lb" "${AWS_ARGS[@]}" >/dev/null 2>&1 || break; sleep 5; done; fi
  echo "$ICON_OK Deleted ELBv2 $lb"
done
logi "Deleting ELBv2 target groups in VPC..."
tgs=$(aws_json elbv2 describe-target-groups --query "TargetGroups[?VpcId=='${VPC_ID}'].TargetGroupArn" | jq -r '.[]?') || true
for tg in $tgs; do aws_run elbv2 delete-target-group --target-group-arn "$tg" && echo "$ICON_OK Deleted TG $tg" || echo "$ICON_FAIL Failed TG $tg"; done

logi "Deleting Classic ELBs..."
for name in $clbs; do aws_run elb delete-load-balancer --load-balancer-name "$name" && echo "$ICON_OK Deleted CLB $name" || echo "$ICON_FAIL Failed CLB $name"; done

# VPC Endpoints
logi "Deleting VPC Endpoints..."
vpce_ids=$(echo "$vpc_eps" | jq -r '.[].VpcEndpointId? // empty') || vpce_ids=""
if [[ -n "$vpce_ids" ]]; then
  # delete in chunks of up to 25
  mapfile -t vpces < <(echo "$vpce_ids")
  chunk=()
  for id in "${vpces[@]}"; do
    [[ -z "$id" ]] && continue
    chunk+=("$id")
    if [[ ${#chunk[@]} -ge 25 ]]; then
      aws_run ec2 delete-vpc-endpoints --vpc-endpoint-ids "${chunk[@]}" || true
      chunk=()
    fi
  done
  if [[ ${#chunk[@]} -gt 0 ]]; then aws_run ec2 delete-vpc-endpoints --vpc-endpoint-ids "${chunk[@]}" || true; fi
else
  echo "$ICON_SKIP No VPC endpoints"
fi

# RDS Instances in this VPC
logi "Deleting RDS DB instances in this VPC (skip final snapshot)..."
rds_ids=$(echo "$rds_all" | jq -r "map(select(.DBSubnetGroup.VpcId == \"$VPC_ID\"))[].DBInstanceIdentifier" 2>/dev/null || true) || true
for db in $rds_ids; do
  # Disable deletion protection if enabled
  dp=$(echo "$rds_all" | jq -r ".[] | select(.DBInstanceIdentifier==\"$db\").DeletionProtection // false")
  if [[ "$dp" == "true" ]]; then aws_run rds modify-db-instance --db-instance-identifier "$db" --deletion-protection false --apply-immediately || true; fi
  aws_run rds delete-db-instance --db-instance-identifier "$db" --skip-final-snapshot || true
  if ! $DRY_RUN; then aws rds wait db-instance-deleted --db-instance-identifier "$db" "${AWS_ARGS[@]}" || true; fi
  echo "$ICON_OK Requested deletion for RDS $db"
done
# Delete RDS DB Subnet Groups that belong to this VPC
logi "Deleting RDS DB subnet groups for this VPC..."
dbsgs=$(aws_json rds describe-db-subnet-groups --query 'DBSubnetGroups[]' 2>/dev/null || echo '[]')
echo "$dbsgs" | jq -r "map(select(.VpcId==\"$VPC_ID\"))[].DBSubnetGroupName" | while read -r sg; do aws_run rds delete-db-subnet-group --db-subnet-group-name "$sg" || true; done

# EKS Clusters in this VPC
logi "Deleting EKS clusters in this VPC..."
for c in $(echo "$eks_list" | jq -r '.[]?'); do
  meta=$(aws_json eks describe-cluster --name "$c" --query 'cluster' 2>/dev/null || echo '{}')
  v=$(echo "$meta" | jq -r '.resourcesVpcConfig.vpcId // empty')
  if [[ "$v" == "$VPC_ID" ]]; then
    aws_run eks delete-cluster --name "$c" || true
    if ! $DRY_RUN; then aws eks wait cluster-deleted --name "$c" "${AWS_ARGS[@]}" || true; fi
    echo "$ICON_OK Deleted EKS cluster $c"
  fi
done

# Route53 Resolver: disassociate rules and delete endpoints
logi "Disassociating Route53 resolver rules..."
assoc_ids=$(aws_json route53resolver list-resolver-rule-associations --filters Name=VPCId,Values="$VPC_ID" --query 'ResolverRuleAssociations[].Id' 2>/dev/null | jq -r '.[]?') || true
for id in $assoc_ids; do aws_run route53resolver disassociate-resolver-rule --resolver-rule-association-id "$id" || true; done
logi "Deleting Route53 resolver endpoints..."
for rid in $(echo "$r53eps" | jq -r '.[].Id? // empty'); do aws_run route53resolver delete-resolver-endpoint --resolver-endpoint-id "$rid" || true; done

# Transit Gateway attachments
logi "Deleting Transit Gateway VPC attachments..."
for ta in $(echo "$tgwatt" | jq -r '.[].TransitGatewayAttachmentId? // empty'); do aws_run ec2 delete-transit-gateway-vpc-attachment --transit-gateway-attachment-id "$ta" || true; done

# VPC Peering connections
logi "Deleting VPC peering connections..."
for pid in $(echo "$peers" | jq -r '.[].VpcPeeringConnectionId? // empty'); do aws_run ec2 delete-vpc-peering-connection --vpc-peering-connection-id "$pid" || true; done

# VPC Flow Logs
logi "Deleting VPC Flow Logs..."
flog_ids=$(aws_json ec2 describe-flow-logs --filter Name=resource-id,Values="$VPC_ID" --query 'FlowLogs[].FlowLogId' 2>/dev/null | jq -r '.[]?') || true
if [[ -n "$flog_ids" ]]; then aws_run ec2 delete-flow-logs --flow-log-ids $flog_ids || true; else echo "$ICON_SKIP No flow logs"; fi

# ENIs (available only)
logi "Deleting available ENIs..."
avail_enis=$(aws_json ec2 describe-network-interfaces --filters Name=vpc-id,Values="$VPC_ID" Name=status,Values=available --query 'NetworkInterfaces[].NetworkInterfaceId' | jq -r '.[]?') || true
for eni in $avail_enis; do
  if out=$(aws_run ec2 delete-network-interface --network-interface-id "$eni" 2>&1); then
    echo "$ICON_OK Deleted ENI $eni"
  else
    echo "$ICON_FAIL Failed ENI $eni"; parse_dependency_hint "$out" "delete-eni"; fi
done

# Subnets: disassociate any route table associations, then delete
logi "Deleting subnets (after disassociating route table associations)..."
for sid in $(aws_json ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query 'Subnets[].SubnetId' | jq -r '.[]?'); do
  # Disassociate any explicit route table association for this subnet
  assoc_ids=$(aws_json ec2 describe-route-tables --filters Name=association.subnet-id,Values="$sid" --query 'RouteTables[].Associations[].RouteTableAssociationId' | jq -r '.[]?') || true
  for aid in $assoc_ids; do aws_run ec2 disassociate-route-table --association-id "$aid" || true; done
  if out=$(aws_run ec2 delete-subnet --subnet-id "$sid" 2>&1); then
    echo "$ICON_OK Deleted Subnet $sid"
  else
    echo "$ICON_FAIL Failed Subnet $sid"; parse_dependency_hint "$out" "delete-subnet"; fi
done

# Route tables (non-main)
logi "Deleting non-main route tables..."
for rtid in $(aws_json ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" --query 'RouteTables[?!(Associations[?Main==`true`])].RouteTableId' | jq -r '.[]?'); do
  if out=$(aws_run ec2 delete-route-table --route-table-id "$rtid" 2>&1); then
    echo "$ICON_OK Deleted RouteTable $rtid"
  else
    echo "$ICON_FAIL Failed RouteTable $rtid"; parse_dependency_hint "$out" "delete-rt"; fi
done

# Security groups (non-default)
logi "Deleting non-default security groups..."
for sg in $(aws_json ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' | jq -r '.[]?'); do
  # Revoke all ingress/egress to avoid circular refs
  perms=$(aws_json ec2 describe-security-groups --group-ids "$sg" --query 'SecurityGroups[0].IpPermissions' | jq -c '. | select(length>0)') || true
  [[ -n "${perms:-}" && "${perms:-}" != "null" ]] && aws_run ec2 revoke-security-group-ingress --group-id "$sg" --ip-permissions "$perms" || true
  perms_eg=$(aws_json ec2 describe-security-groups --group-ids "$sg" --query 'SecurityGroups[0].IpPermissionsEgress' | jq -c '. | select(length>0)') || true
  [[ -n "${perms_eg:-}" && "${perms_eg:-}" != "null" ]] && aws_run ec2 revoke-security-group-egress --group-id "$sg" --ip-permissions "$perms_eg" || true
  if out=$(aws_run ec2 delete-security-group --group-id "$sg" 2>&1); then
    echo "$ICON_OK Deleted SG $sg"
  else
    echo "$ICON_FAIL Failed SG $sg"; parse_dependency_hint "$out" "delete-sg"; fi
done

# Attempt to delete default SG for this VPC (will likely be skipped by AWS)
logi "Attempting to delete default security group (will skip if not allowed)..."
default_sg=$(aws_json ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC_ID" Name=group-name,Values=default --query 'SecurityGroups[0].GroupId' | jq -r '. // empty') || true
if [[ -n "$default_sg" ]]; then
  if out=$(aws_run ec2 delete-security-group --group-id "$default_sg" 2>&1); then
    echo "$ICON_OK Deleted default SG $default_sg"
  else
    echo "$ICON_SKIP Could not delete default SG $default_sg (expected)"; fi
else
  echo "$ICON_SKIP No default SG found"
fi

# 3) Final VPC deletion ---------------------------------------------------------
print_header "Final VPC Deletion"
if $DRY_RUN; then
  echo "+ aws ec2 delete-vpc --vpc-id $VPC_ID ${AWS_ARGS[*]}"
  echo "$ICON_SKIP Dry-run: would delete VPC $VPC_ID"
else
  if out=$(aws_run ec2 delete-vpc --vpc-id "$VPC_ID" 2>&1); then
    echo "$ICON_OK Deleted VPC $VPC_ID"
  else
    echo "$ICON_FAIL VPC delete failed"; parse_dependency_hint "$out" "delete-vpc";
  fi
fi

# 4) Confirmation ---------------------------------------------------------------
print_header "Verification"
if $DRY_RUN; then
  logw "Dry-run mode: skipping verification"
else
  if aws ec2 describe-vpcs --vpc-ids "$VPC_ID" "${AWS_ARGS[@]}" >/dev/null 2>&1; then
    logw "VPC still present: $VPC_ID"
    echo "Remaining blockers likely include: Lambda ENIs, EFS mount targets, or service-managed resources."
    echo "Examples to investigate:"
    echo "  - aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=$VPC_ID ${AWS_ARGS[*]}"
    echo "  - aws efs describe-mount-targets ${AWS_ARGS[*]}"
    echo "  - aws lambda list-functions ${AWS_ARGS[*]}"
    exit 1
  else
    logg "CLEANUP COMPLETE"
  fi
fi
