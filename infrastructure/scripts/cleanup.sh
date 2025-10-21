#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT_NAME="microservices"
AWS_REGION="us-east-1"
STACK_PREFIX="${ENVIRONMENT_NAME}"

echo -e "${RED}================================================${NC}"
echo -e "${RED}WARNING: This will delete ALL infrastructure${NC}"
echo -e "${RED}================================================${NC}"
echo ""
echo -e "${YELLOW}The following stacks will be deleted:${NC}"
echo -e "  - ${STACK_PREFIX}-ecs-services"
echo -e "  - ${STACK_PREFIX}-alb"
echo -e "  - ${STACK_PREFIX}-ecs-cluster"
echo -e "  - ${STACK_PREFIX}-ecr"
echo -e "  - ${STACK_PREFIX}-vpc"
echo ""
echo -e "${YELLOW}This action cannot be undone!${NC}"
echo ""
read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${GREEN}Cleanup cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${RED}Starting cleanup...${NC}"
echo ""

# Function to wait for stack deletion
wait_for_stack_deletion() {
    local stack_name=$1
    
    echo -e "${YELLOW}Waiting for stack ${stack_name} to be deleted...${NC}"
    
    aws cloudformation wait stack-delete-complete \
        --stack-name ${stack_name} \
        --region ${AWS_REGION}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Stack ${stack_name} deleted successfully${NC}"
    else
        echo -e "${RED}✗ Stack ${stack_name} deletion failed${NC}"
    fi
}

# Function to delete stack
delete_stack() {
    local stack_name=$1
    
    echo ""
    echo -e "${YELLOW}Deleting stack: ${stack_name}${NC}"
    
    # Check if stack exists
    aws cloudformation describe-stacks \
        --stack-name ${stack_name} \
        --region ${AWS_REGION} > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        aws cloudformation delete-stack \
            --stack-name ${stack_name} \
            --region ${AWS_REGION}
        
        wait_for_stack_deletion ${stack_name}
    else
        echo -e "${YELLOW}Stack ${stack_name} does not exist, skipping${NC}"
    fi
}

# Empty ECR repositories before deletion
echo -e "${YELLOW}Emptying ECR repositories...${NC}"

USER_REPO_NAME="user-service"
PRODUCT_REPO_NAME="product-service"

# Delete all images from user-service repository
aws ecr list-images \
    --repository-name ${USER_REPO_NAME} \
    --region ${AWS_REGION} \
    --query 'imageIds[*]' \
    --output json | \
jq -r '.[] | "\(.imageDigest)"' | \
while read digest; do
    if [ ! -z "$digest" ]; then
        aws ecr batch-delete-image \
            --repository-name ${USER_REPO_NAME} \
            --image-ids imageDigest=$digest \
            --region ${AWS_REGION} > /dev/null 2>&1
    fi
done

# Delete all images from product-service repository
aws ecr list-images \
    --repository-name ${PRODUCT_REPO_NAME} \
    --region ${AWS_REGION} \
    --query 'imageIds[*]' \
    --output json | \
jq -r '.[] | "\(.imageDigest)"' | \
while read digest; do
    if [ ! -z "$digest" ]; then
        aws ecr batch-delete-image \
            --repository-name ${PRODUCT_REPO_NAME} \
            --image-ids imageDigest=$digest \
            --region ${AWS_REGION} > /dev/null 2>&1
    fi
done

echo -e "${GREEN}✓ ECR repositories emptied${NC}"

# Delete stacks in reverse order
delete_stack "${STACK_PREFIX}-ecs-services"
delete_stack "${STACK_PREFIX}-alb"
delete_stack "${STACK_PREFIX}-ecs-cluster"
delete_stack "${STACK_PREFIX}-ecr"
delete_stack "${STACK_PREFIX}-vpc"

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Cleanup Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${GREEN}All infrastructure has been deleted.${NC}"
echo -e "${YELLOW}Note: Some resources like CloudWatch logs may persist${NC}"
echo -e "${YELLOW}You can manually delete log groups from CloudWatch console if needed${NC}"
echo ""