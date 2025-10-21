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

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Deploying Containerized Microservices Infrastructure${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Function to wait for stack creation/update
wait_for_stack() {
    local stack_name=$1
    local operation=$2
    
    echo -e "${YELLOW}Waiting for stack ${stack_name} to ${operation}...${NC}"
    
    aws cloudformation wait stack-${operation}-complete \
        --stack-name ${stack_name} \
        --region ${AWS_REGION}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Stack ${stack_name} ${operation}d successfully${NC}"
    else
        echo -e "${RED}✗ Stack ${stack_name} ${operation} failed${NC}"
        exit 1
    fi
}

# Function to deploy or update stack
deploy_stack() {
    local stack_name=$1
    local template_file=$2
    local parameters=$3
    
    echo ""
    echo -e "${YELLOW}Deploying stack: ${stack_name}${NC}"
    echo -e "${YELLOW}Template: ${template_file}${NC}"
    
    # Check if stack exists
    aws cloudformation describe-stacks \
        --stack-name ${stack_name} \
        --region ${AWS_REGION} > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # Stack exists, update it
        echo -e "${YELLOW}Stack exists, updating...${NC}"
        
        aws cloudformation update-stack \
            --stack-name ${stack_name} \
            --template-body file://${template_file} \
            --capabilities CAPABILITY_NAMED_IAM \
            --region ${AWS_REGION} \
            ${parameters} > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            wait_for_stack ${stack_name} "update"
        else
            echo -e "${YELLOW}No updates to be performed${NC}"
        fi
    else
        # Stack doesn't exist, create it
        echo -e "${YELLOW}Stack doesn't exist, creating...${NC}"
        
        aws cloudformation create-stack \
            --stack-name ${stack_name} \
            --template-body file://${template_file} \
            --capabilities CAPABILITY_NAMED_IAM \
            --region ${AWS_REGION} \
            ${parameters}
        
        wait_for_stack ${stack_name} "create"
    fi
}

# Check AWS CLI is configured
echo -e "${YELLOW}Checking AWS CLI configuration...${NC}"
aws sts get-caller-identity --region ${AWS_REGION} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ AWS CLI not configured properly${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS CLI configured${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}Region: ${AWS_REGION}${NC}"
echo ""

# Deploy stacks in order
echo -e "${GREEN}Starting deployment...${NC}"
echo ""

# 1. VPC and Network
deploy_stack \
    "${STACK_PREFIX}-vpc" \
    "../cloudformation/01-vpc-network.yaml" \
    "--parameters ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME}"

# 2. ECR Repositories
deploy_stack \
    "${STACK_PREFIX}-ecr" \
    "../cloudformation/02-ecr-repositories.yaml" \
    "--parameters ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME}"

# 3. ECS Cluster
deploy_stack \
    "${STACK_PREFIX}-ecs-cluster" \
    "../cloudformation/03-ecs-cluster.yaml" \
    "--parameters ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME}"

# 4. Application Load Balancer
deploy_stack \
    "${STACK_PREFIX}-alb" \
    "../cloudformation/04-alb.yaml" \
    "--parameters ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME}"

# Get ECR Repository URIs
echo ""
echo -e "${YELLOW}Fetching ECR repository URIs...${NC}"
USER_SERVICE_REPO=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_PREFIX}-ecr \
    --query "Stacks[0].Outputs[?OutputKey=='UserServiceRepositoryUri'].OutputValue" \
    --output text \
    --region ${AWS_REGION})

PRODUCT_SERVICE_REPO=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_PREFIX}-ecr \
    --query "Stacks[0].Outputs[?OutputKey=='ProductServiceRepositoryUri'].OutputValue" \
    --output text \
    --region ${AWS_REGION})

echo -e "${GREEN}User Service Repository: ${USER_SERVICE_REPO}${NC}"
echo -e "${GREEN}Product Service Repository: ${PRODUCT_SERVICE_REPO}${NC}"

# 5. ECS Services (with default images for now)
deploy_stack \
    "${STACK_PREFIX}-ecs-services" \
    "../cloudformation/05-ecs-services.yaml" \
    "--parameters ParameterKey=EnvironmentName,ParameterValue=${ENVIRONMENT_NAME} ParameterKey=UserServiceImage,ParameterValue=${USER_SERVICE_REPO}:latest ParameterKey=ProductServiceImage,ParameterValue=${PRODUCT_SERVICE_REPO}:latest"

# Get ALB URL
echo ""
echo -e "${YELLOW}Fetching Application Load Balancer URL...${NC}"
ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_PREFIX}-alb \
    --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerUrl'].OutputValue" \
    --output text \
    --region ${AWS_REGION})

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${GREEN}Application Load Balancer URL:${NC}"
echo -e "${YELLOW}${ALB_URL}${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo -e "1. Build and push Docker images to ECR:"
echo -e "   ${YELLOW}User Service: ${USER_SERVICE_REPO}${NC}"
echo -e "   ${YELLOW}Product Service: ${PRODUCT_SERVICE_REPO}${NC}"
echo ""
echo -e "2. Test your services:"
echo -e "   ${YELLOW}curl ${ALB_URL}/api/users${NC}"
echo -e "   ${YELLOW}curl ${ALB_URL}/api/products${NC}"
echo ""
echo -e "3. View logs in CloudWatch:"
echo -e "   ${YELLOW}/ecs/${ENVIRONMENT_NAME}/user-service${NC}"
echo -e "   ${YELLOW}/ecs/${ENVIRONMENT_NAME}/product-service${NC}"
echo ""