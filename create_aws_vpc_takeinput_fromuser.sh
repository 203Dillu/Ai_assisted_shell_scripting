#!/bin/bash
##################
# Description: Create a VPC in AWS
# -create a VPC
# -Ask user vpc name and vpc cidr
# -create a public subnet
# -Ask user subnet name and subnet cidr
#
# -Verify if user has aws installed, User might be using Windows, Linux or Mac.
# -Verify if AWS CLI is configured
# -Verify user write file name and pass a parameter crete then crete infrastructure
# -Verify user write file name and pass a parameter terdown then destroy infrastructure
# -Verify user write file name and pass a parameter exipt create and terdown write invaled parameter
#######################
# Ask user for VPC name and CIDR block
read -p "Enter VPC name: " VPC_NAME
read -p "Enter VPC CIDR block: " VPC_CIDR

# Ask user for subnet name and CIDR block
read -p "Enter Subnet name: " SUBNET_NAME
read -p "Enter Subnet CIDR block: " SUBNET_CIDR
# Ask user for region
read -p "Enter AWS region (default: us-east-1): " REGION
REGION=${REGION:-us-east-1}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null
then
    echo "AWS CLI could not be found. Please install it first."
    exit 1
fi
# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null
then
    echo "AWS CLI is not configured. Please configure it first."
    exit 1
fi
# Check if the user provided a parameter
if [ $# -eq 0 ]; then
    echo "No parameters provided. Please provide parameters."
    exit 1
fi
# Check if the user provided a valid parameter
if [ "$1" != "create" ] && [ "$1" != "terdown" ]; then
    echo "Invalid parameter. Please provide 'create' or 'terdown'."
    exit 1
fi
# Create VPC
if [ "$1" == "create" ]; then
    echo "Creating VPC..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
    aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$VPC_NAME
    echo "VPC created with ID: $VPC_ID"

    # Create public subnet
    echo "Creating public subnet..."
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --region $REGION --query 'Subnet.SubnetId' --output text)
    aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value=$SUBNET_NAME
    echo "Public subnet created with ID: $SUBNET_ID"
fi
# Destroy VPC and Subnet
if [ "$1" == "terdown" ]; then
    echo "Destroying VPC and Subnet..."

    # Fetch Subnet ID using Subnet Name
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$SUBNET_NAME" --query 'Subnets[0].SubnetId' --output text 2>/dev/null)

    # Fetch VPC ID using VPC Name
    VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)

    # Delete public subnet
    if [ -n "$SUBNET_ID" ]; then
        if aws ec2 delete-subnet --subnet-id $SUBNET_ID; then
            echo "Public subnet deleted with ID: $SUBNET_ID"
        else
            echo "Failed to delete subnet with ID: $SUBNET_ID"
        fi
    else
        echo "No public subnet found with name: $SUBNET_NAME"
    fi

    # Delete VPC
    if [ -n "$VPC_ID" ]; then
        if aws ec2 delete-vpc --vpc-id $VPC_ID; then
            echo "VPC deleted with ID: $VPC_ID"
        else
            echo "Failed to delete VPC with ID: $VPC_ID. Please ensure all dependencies are removed."
        fi
    else
        echo "No VPC found with name: $VPC_NAME"
    fi
fi
# Check if the user provided a valid parameter
if [ "$1" != "create" ] && [ "$1" != "terdown" ]; then
    echo "Invalid parameter. Please provide 'create' or 'terdown'."
    exit 1
fi
# Check if the user provided a parameter
if [ $# -eq 0 ]; then
    echo "No parameters provided. Please provide parameters."
    exit 1
fi

# end of script









