#!/bin/bash

# VPC Dependency Cleanup Script
# This script identifies and removes AWS resources that prevent VPC deletion

set -e

VPC_ID="vpc-0dc7f328726bbe921"
REGION="${AWS_DEFAULT_REGION:-$(aws configure get region)}"

echo "🔍 Analyzing VPC dependencies for: $VPC_ID in region: $REGION"
echo "=================================================="

# Function to delete resources with confirmation
delete_with_confirmation() {
    local resource_type="$1"
    local resource_id="$2"
    local description="$3"
    
    echo "❓ Delete $resource_type: $resource_id ($description)? [y/N]"
    read -r confirm
    if [[ $confirm == [yY] ]]; then
        return 0
    else
        echo "⏭️  Skipping $resource_type: $resource_id"
        return 1
    fi
}

# 1. Check and clean up VPC Endpoints
echo "1️⃣ Checking VPC Endpoints..."
VPC_ENDPOINTS=$(aws ec2 describe-vpc-endpoints \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'VpcEndpoints[*].VpcEndpointId' \
    --output text)

if [[ -n "$VPC_ENDPOINTS" && "$VPC_ENDPOINTS" != "None" ]]; then
    echo "🔍 Found VPC Endpoints:"
    for endpoint in $VPC_ENDPOINTS; do
        endpoint_info=$(aws ec2 describe-vpc-endpoints --vpc-endpoint-ids "$endpoint" --query 'VpcEndpoints[0].{ServiceName:ServiceName,State:State}' --output text)
        echo "  - $endpoint ($endpoint_info)"
        
        if delete_with_confirmation "VPC Endpoint" "$endpoint" "$endpoint_info"; then
            echo "🗑️  Deleting VPC Endpoint: $endpoint"
            aws ec2 delete-vpc-endpoint --vpc-endpoint-id "$endpoint"
            echo "✅ Deleted VPC Endpoint: $endpoint"
        fi
    done
else
    echo "✅ No VPC Endpoints found"
fi

# 2. Check and clean up Network Interfaces (ENIs)
echo -e "\n2️⃣ Checking Network Interfaces..."
ENIS=$(aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkInterfaces[*].{NetworkInterfaceId:NetworkInterfaceId,Status:Status,Description:Description}' \
    --output text)

if [[ -n "$ENIS" && "$ENIS" != "None" ]]; then
    echo "🔍 Found Network Interfaces:"
    while IFS=$'\t' read -r eni_id status description; do
        [[ -z "$eni_id" ]] && continue
        echo "  - $eni_id ($status) - $description"
        
        if [[ "$status" == "available" ]]; then
            if delete_with_confirmation "Network Interface" "$eni_id" "$description"; then
                echo "🗑️  Deleting Network Interface: $eni_id"
                aws ec2 delete-network-interface --network-interface-id "$eni_id"
                echo "✅ Deleted Network Interface: $eni_id"
            fi
        else
            echo "⚠️  Network Interface $eni_id is $status - may need manual detachment"
        fi
    done <<< "$ENIS"
else
    echo "✅ No Network Interfaces found"
fi

# 3. Check and clean up Security Groups (non-default)
echo -e "\n3️⃣ Checking Security Groups..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[?GroupName!=`default`].{GroupId:GroupId,GroupName:GroupName}' \
    --output text)

if [[ -n "$SECURITY_GROUPS" && "$SECURITY_GROUPS" != "None" ]]; then
    echo "🔍 Found Security Groups:"
    while IFS=$'\t' read -r sg_id sg_name; do
        [[ -z "$sg_id" ]] && continue
        echo "  - $sg_id ($sg_name)"
        
        if delete_with_confirmation "Security Group" "$sg_id" "$sg_name"; then
            echo "🗑️  Deleting Security Group: $sg_id"
            aws ec2 delete-security-group --group-id "$sg_id"
            echo "✅ Deleted Security Group: $sg_id"
        fi
    done <<< "$SECURITY_GROUPS"
else
    echo "✅ No non-default Security Groups found"
fi

# 4. Check and clean up Route Tables (non-main)
echo -e "\n4️⃣ Checking Route Tables..."
ROUTE_TABLES=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
    --output text)

if [[ -n "$ROUTE_TABLES" && "$ROUTE_TABLES" != "None" ]]; then
    echo "🔍 Found Route Tables:"
    for rt_id in $ROUTE_TABLES; do
        echo "  - $rt_id"
        
        if delete_with_confirmation "Route Table" "$rt_id" "non-main route table"; then
            echo "🗑️  Deleting Route Table: $rt_id"
            aws ec2 delete-route-table --route-table-id "$rt_id"
            echo "✅ Deleted Route Table: $rt_id"
        fi
    done
else
    echo "✅ No non-main Route Tables found"
fi

# 5. Check and clean up Subnets
echo -e "\n5️⃣ Checking Subnets..."
SUBNETS=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[*].SubnetId' \
    --output text)

if [[ -n "$SUBNETS" && "$SUBNETS" != "None" ]]; then
    echo "🔍 Found Subnets:"
    for subnet_id in $SUBNETS; do
        subnet_info=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --query 'Subnets[0].{AvailabilityZone:AvailabilityZone,State:State}' --output text)
        echo "  - $subnet_id ($subnet_info)"
        
        if delete_with_confirmation "Subnet" "$subnet_id" "$subnet_info"; then
            echo "🗑️  Deleting Subnet: $subnet_id"
            aws ec2 delete-subnet --subnet-id "$subnet_id"
            echo "✅ Deleted Subnet: $subnet_id"
        fi
    done
else
    echo "✅ No Subnets found"
fi

# 6. Check Internet Gateway
echo -e "\n6️⃣ Checking Internet Gateway..."
IGW=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[*].InternetGatewayId' \
    --output text)

if [[ -n "$IGW" && "$IGW" != "None" ]]; then
    echo "🔍 Found Internet Gateway: $IGW"
    
    if delete_with_confirmation "Internet Gateway" "$IGW" "attached to VPC"; then
        echo "🗑️  Detaching and deleting Internet Gateway: $IGW"
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW"
        echo "✅ Deleted Internet Gateway: $IGW"
    fi
else
    echo "✅ No Internet Gateway found"
fi

# 7. Final VPC deletion attempt
echo -e "\n7️⃣ Attempting VPC deletion..."
if delete_with_confirmation "VPC" "$VPC_ID" "the entire VPC"; then
    echo "🗑️  Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id "$VPC_ID"
    echo "✅ Successfully deleted VPC: $VPC_ID"
else
    echo "⏭️  VPC deletion skipped"
fi

echo -e "\n🎉 VPC cleanup script completed!"
echo "💡 If the VPC still can't be deleted, check the AWS console for:"
echo "   - Load Balancers (ALB/NLB/CLB)"
echo "   - NAT Gateways"
echo "   - VPN Connections"
echo "   - VPC Peering Connections"
echo "   - EC2 instances"
echo "   - RDS instances"
echo "   - Lambda functions with VPC configuration"
