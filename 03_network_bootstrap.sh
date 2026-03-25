#!/usr/bin/env bash
set -euo pipefail

echo "STEP 3 / 10 — Network Bootstrap"

REGION=$(aws configure get region || echo "us-gov-west-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

PREFIX="dbx-$(date +%s)"
BASE_OCTET=$(( (RANDOM % 200) + 10 ))

COMPUTE_CIDR="10.${BASE_OCTET}.0.0/24"
PL_CIDR="10.${BASE_OCTET}.1.0/26"

aws ec2 describe-vpcs \
  --query "Vpcs[*].[VpcId,CidrBlock]" \
  --output table

read -p "Enter VPC ID: " VPC_ID

GOOD_SUBNET=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $COMPUTE_CIDR \
  --query Subnet.SubnetId --output text)

PL_SUBNET=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PL_CIDR \
  --query Subnet.SubnetId --output text)

COMPUTE_SG=$(aws ec2 create-security-group \
  --group-name "${PREFIX}-compute-sg" \
  --vpc-id $VPC_ID \
  --query GroupId --output text)

VPCE_SG=$(aws ec2 create-security-group \
  --group-name "${PREFIX}-vpce-sg" \
  --vpc-id $VPC_ID \
  --query GroupId --output text)

ensure_ep () {
  SERVICE=$1
  EXISTS=$(aws ec2 describe-vpc-endpoints \
    --filters "Name=service-name,Values=$SERVICE" \
    --query "VpcEndpoints[0].VpcEndpointId" \
    --output text)

  if [ "$EXISTS" = "None" ]; then
    aws ec2 create-vpc-endpoint \
      --vpc-id $VPC_ID \
      --vpc-endpoint-type Interface \
      --service-name $SERVICE \
      --subnet-ids $PL_SUBNET \
      --security-group-ids $VPCE_SG \
      --private-dns-enabled
  fi
}

ensure_ep "com.amazonaws.$REGION.sts"
ensure_ep "com.amazonaws.$REGION.kinesis-streams"

cat > env.sh <<EOF
export VPC_ID=$VPC_ID
export GOOD_SUBNET=$GOOD_SUBNET
export PL_SUBNET=$PL_SUBNET
export COMPUTE_SG=$COMPUTE_SG
export ACCOUNT_ID=$ACCOUNT_ID
export REGION=$REGION
EOF
