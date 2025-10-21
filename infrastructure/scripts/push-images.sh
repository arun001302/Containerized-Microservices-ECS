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
echo -e "${GREEN}Building and Pushing Docker Images to ECR${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}✗ Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account ID: ${AWS_ACCOUNT_ID}${NC}"

# Get ECR Repository URIs
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

if [ -z "$USER_SERVICE_REPO" ] || [ -z "$PRODUCT_SERVICE_REPO" ]; then
    echo -e "${RED}✗ Could not fetch ECR repository URIs. Make sure infrastructure is deployed.${NC}"
    exit 1
fi

echo -e "${GREEN}User Service Repository: ${USER_SERVICE_REPO}${NC}"
echo -e "${GREEN}Product Service Repository: ${PRODUCT_SERVICE_REPO}${NC}"
echo ""

# Login to ECR
echo -e "${YELLOW}Logging in to Amazon ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Successfully logged in to ECR${NC}"
else
    echo -e "${RED}✗ Failed to login to ECR${NC}"
    exit 1
fi
echo ""

# Build and push User Service
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Building User Service${NC}"
echo -e "${GREEN}================================================${NC}"
cd ../../services/user-service

echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t user-service:latest .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ User Service image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build User Service image${NC}"
    exit 1
fi

echo -e "${YELLOW}Tagging image...${NC}"
docker tag user-service:latest ${USER_SERVICE_REPO}:latest
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
docker tag user-service:latest ${USER_SERVICE_REPO}:${COMMIT_HASH}

echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push ${USER_SERVICE_REPO}:latest
docker push ${USER_SERVICE_REPO}:${COMMIT_HASH}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ User Service image pushed successfully${NC}"
else
    echo -e "${RED}✗ Failed to push User Service image${NC}"
    exit 1
fi
echo ""

# Build and push Product Service
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Building Product Service${NC}"
echo -e "${GREEN}================================================${NC}"
cd ../product-service

echo -e "${YELLOW}Building Docker image...${NC}"
docker build -t product-service:latest .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Product Service image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build Product Service image${NC}"
    exit 1
fi

echo -e "${YELLOW}Tagging image...${NC}"
docker tag product-service:latest ${PRODUCT_SERVICE_REPO}:latest
docker tag product-service:latest ${PRODUCT_SERVICE_REPO}:${COMMIT_HASH}

echo -e "${YELLOW}Pushing image to ECR...${NC}"
docker push ${PRODUCT_SERVICE_REPO}:latest
docker push ${PRODUCT_SERVICE_REPO}:${COMMIT_HASH}

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Product Service image pushed successfully${NC}"
else
    echo -e "${RED}✗ Failed to push Product Service image${NC}"
    exit 1
fi
echo ""

# Update ECS services to use new images
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Updating ECS Services${NC}"
echo -e "${GREEN}================================================${NC}"

echo -e "${YELLOW}Updating User Service...${NC}"
aws ecs update-service \
    --cluster ${ENVIRONMENT_NAME}-cluster \
    --service ${ENVIRONMENT_NAME}-user-service \
    --force-new-deployment \
    --region ${AWS_REGION} > /dev/null

echo -e "${GREEN}✓ User Service update initiated${NC}"

echo -e "${YELLOW}Updating Product Service...${NC}"
aws ecs update-service \
    --cluster ${ENVIRONMENT_NAME}-cluster \
    --service ${ENVIRONMENT_NAME}-product-service \
    --force-new-deployment \
    --region ${AWS_REGION} > /dev/null

echo -e "${GREEN}✓ Product Service update initiated${NC}"
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Images Successfully Pushed!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${GREEN}Images pushed:${NC}"
echo -e "  User Service: ${YELLOW}${USER_SERVICE_REPO}:latest${NC}"
echo -e "  User Service: ${YELLOW}${USER_SERVICE_REPO}:${COMMIT_HASH}${NC}"
echo -e "  Product Service: ${YELLOW}${PRODUCT_SERVICE_REPO}:latest${NC}"
echo -e "  Product Service: ${YELLOW}${PRODUCT_SERVICE_REPO}:${COMMIT_HASH}${NC}"
echo ""
echo -e "${YELLOW}ECS services are being updated with new images...${NC}"
echo -e "${YELLOW}This may take a few minutes. Monitor progress in the AWS Console.${NC}"
echo ""

# Get ALB URL
ALB_URL=$(aws cloudformation describe-stacks \
    --stack-name ${STACK_PREFIX}-alb \
    --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerUrl'].OutputValue" \
    --output text \
    --region ${AWS_REGION})

echo -e "${GREEN}Test your services:${NC}"
echo -e "  ${YELLOW}curl ${ALB_URL}/api/users${NC}"
echo -e "  ${YELLOW}curl ${ALB_URL}/api/products${NC}"
echo ""