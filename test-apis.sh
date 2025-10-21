#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get ALB URL
ALB_URL=$1

if [ -z "$ALB_URL" ]; then
    echo -e "${RED}Usage: ./test-apis.sh <ALB_URL>${NC}"
    echo -e "${YELLOW}Example: ./test-apis.sh http://microservices-alb-123456789.us-east-1.elb.amazonaws.com${NC}"
    exit 1
fi

echo -e "${GREEN}Testing Microservices APIs${NC}"
echo -e "${GREEN}=========================${NC}"
echo ""

# Test User Service
echo -e "${YELLOW}1. Testing User Service - Get All Users${NC}"
curl -s ${ALB_URL}/api/users | jq '.'
echo ""

echo -e "${YELLOW}2. Testing User Service - Get User by ID${NC}"
curl -s ${ALB_URL}/api/users/1 | jq '.'
echo ""

echo -e "${YELLOW}3. Testing User Service - Create User${NC}"
curl -s -X POST ${ALB_URL}/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","role":"user"}' | jq '.'
echo ""

# Test Product Service
echo -e "${YELLOW}4. Testing Product Service - Get All Products${NC}"
curl -s ${ALB_URL}/api/products | jq '.'
echo ""

echo -e "${YELLOW}5. Testing Product Service - Get Product by ID${NC}"
curl -s ${ALB_URL}/api/products/1 | jq '.'
echo ""

echo -e "${YELLOW}6. Testing Product Service - Filter Products${NC}"
curl -s "${ALB_URL}/api/products?category=Electronics&minPrice=50" | jq '.'
echo ""

echo -e "${YELLOW}7. Testing Product Service - Create Product${NC}"
curl -s -X POST ${ALB_URL}/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","price":99.99,"category":"Test","stock":10}' | jq '.'
echo ""

echo -e "${GREEN}=========================${NC}"
echo -e "${GREEN}All tests completed!${NC}"