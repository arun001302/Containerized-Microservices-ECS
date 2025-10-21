# Containerized Microservices with AWS ECS Fargate

A production-ready microservices architecture demonstrating modern cloud-native development practices using Docker, AWS ECS Fargate, and Infrastructure as Code.

![Architecture](https://img.shields.io/badge/AWS-ECS_Fargate-orange) ![Docker](https://img.shields.io/badge/Docker-Container-blue) ![Node.js](https://img.shields.io/badge/Node.js-18-green) ![CloudFormation](https://img.shields.io/badge/IaC-CloudFormation-yellow)

## 🚀 Live Demo

**API Base URL**: `http://microservices-alb-1563767057.us-east-1.elb.amazonaws.com`

### Endpoints

**User Service:**
- `GET /api/users` - List all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

**Product Service:**
- `GET /api/products` - List all products
- `GET /api/products/:id` - Get product by ID
- `GET /api/products?category=Electronics` - Filter by category
- `POST /api/products` - Create new product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

**Try it:**
```bash
curl http://microservices-alb-1563767057.us-east-1.elb.amazonaws.com/api/users
curl http://microservices-alb-1563767057.us-east-1.elb.amazonaws.com/api/products
```

---

## 📋 Table of Contents

- [Architecture](#architecture)
- [Features](#features)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Deployment Guide](#deployment-guide)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Cost Optimization](#cost-optimization)
- [Cleanup](#cleanup)
- [What I Learned](#what-i-learned)

---

## 🏗️ Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
              ┌──────────────────────┐
              │ Application Load     │
              │ Balancer (ALB)       │
              │ Port 80              │
              │ Path-based Routing   │
              └──────────┬───────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────┐            ┌─────────────────┐
│ Target Group    │            │ Target Group    │
│ (User Service)  │            │ (Product Svc)   │
│ Blue/Green      │            │ Blue/Green      │
│ Port 3000       │            │ Port 3001       │
└────────┬────────┘            └────────┬────────┘
         │                               │
         ▼                               ▼
┌─────────────────────────────────────────────────┐
│         VPC - Private Subnets (Multi-AZ)        │
│  ┌─────────────────┐  ┌─────────────────┐      │
│  │  ECS Fargate    │  │  ECS Fargate    │      │
│  │  User Service   │  │  Product Service│      │
│  │  Container      │  │  Container      │      │
│  │  (Auto-scaling) │  │  (Auto-scaling) │      │
│  └─────────────────┘  └─────────────────┘      │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
              ┌──────────────┐
              │ NAT Gateway  │
              └──────┬───────┘
                     │
        ┌────────────┴────────────┐
        ▼                         ▼
┌──────────────┐          ┌──────────────┐
│   Amazon     │          │  CloudWatch  │
│     ECR      │          │ Logs/Metrics │
│  (Images)    │          └──────────────┘
└──────────────┘
```

### Key Components

**Networking Layer:**
- VPC with public and private subnets across 2 Availability Zones
- Internet Gateway for public subnet connectivity
- NAT Gateway for private subnet internet access
- Route tables for traffic management

**Compute Layer:**
- ECS Fargate for serverless container orchestration
- Auto-scaling policies based on CPU utilization
- Health checks for automatic container replacement

**Load Balancing:**
- Application Load Balancer with path-based routing
- Blue/Green target groups for zero-downtime deployments
- Health checks for target registration

**Container Registry:**
- Amazon ECR for Docker image storage
- Automated vulnerability scanning
- Lifecycle policies for image management

**Monitoring & Logging:**
- CloudWatch Logs for centralized logging
- CloudWatch Metrics for performance monitoring
- Container Insights enabled

---

## ✨ Features

### Production-Ready Architecture
- ✅ **High Availability**: Multi-AZ deployment across 2 availability zones
- ✅ **Auto-Scaling**: Automatic scaling based on CPU/memory metrics
- ✅ **Zero-Downtime Deployments**: Blue/green deployment strategy
- ✅ **Health Monitoring**: Automatic health checks and container restart
- ✅ **Centralized Logging**: CloudWatch integration for all services

### Security Best Practices
- ✅ **Network Isolation**: Private subnets for containers
- ✅ **Least Privilege**: IAM roles with minimal permissions
- ✅ **Security Groups**: Strict firewall rules
- ✅ **Non-root Containers**: Containers run as non-privileged users
- ✅ **Image Scanning**: Automated vulnerability scanning

### Infrastructure as Code
- ✅ **5 CloudFormation Stacks**: Complete infrastructure automation
- ✅ **Modular Design**: Easy to update and maintain
- ✅ **Version Controlled**: All infrastructure code in Git
- ✅ **Reproducible**: Deploy to any AWS account/region

### Microservices Design
- ✅ **Service Independence**: Each service can scale and deploy independently
- ✅ **RESTful APIs**: Standard HTTP methods and JSON responses
- ✅ **Health Endpoints**: Monitoring and load balancer integration
- ✅ **Containerized**: Consistent environments across dev/prod

---

## 🛠️ Technologies Used

### AWS Services
- **Amazon ECS Fargate** - Serverless container orchestration
- **Amazon ECR** - Container registry
- **Application Load Balancer** - Layer 7 load balancing
- **Amazon VPC** - Network isolation
- **CloudWatch** - Logging and monitoring
- **IAM** - Identity and access management
- **CloudFormation** - Infrastructure as Code

### Development Stack
- **Node.js 18** - Runtime environment
- **Express.js** - Web framework
- **Docker** - Containerization
- **Git** - Version control

### DevOps Tools
- **AWS CLI** - AWS resource management
- **Docker CLI** - Container management
- **Bash Scripts** - Deployment automation

---

## 📁 Project Structure
```
containerized-microservices-ecs/
├── services/
│   ├── user-service/
│   │   ├── Dockerfile
│   │   ├── package.json
│   │   ├── index.js
│   │   └── .dockerignore
│   └── product-service/
│       ├── Dockerfile
│       ├── package.json
│       ├── index.js
│       └── .dockerignore
├── infrastructure/
│   ├── cloudformation/
│   │   ├── 01-vpc-network.yaml
│   │   ├── 02-ecr-repositories.yaml
│   │   ├── 03-ecs-cluster.yaml
│   │   ├── 04-alb.yaml
│   │   └── 05-ecs-services.yaml
│   └── scripts/
│       ├── deploy-infrastructure.sh
│       ├── push-images.sh
│       └── cleanup.sh
├── buildspec.yml
├── .gitignore
└── README.md
```

---

## 📦 Prerequisites

Before deploying this project, ensure you have:

1. **AWS Account** with administrative access
2. **AWS CLI** installed and configured
```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and default region (us-east-1)
```
3. **Docker Desktop** installed and running
4. **Git** installed
5. **Basic knowledge** of AWS, Docker, and command line

---

## 🚀 Deployment Guide

### Step 1: Clone the Repository
```bash
git clone https://github.com/arun001302/Containerized-Microservices-ECS.git
cd Containerized-Microservices-ECS
```

### Step 2: Deploy AWS Infrastructure

Deploy all CloudFormation stacks:
```bash
cd infrastructure/scripts
chmod +x *.sh
./deploy-infrastructure.sh
```

This will create (in order):
1. VPC and networking (3-4 minutes)
2. ECR repositories (1 minute)
3. ECS cluster and IAM roles (2-3 minutes)
4. Application Load Balancer (3-4 minutes)
5. ECS services (3-5 minutes)

**Total deployment time: ~15 minutes**

### Step 3: Build and Push Docker Images
```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build and push images
./push-images.sh
```

This will:
- Build Docker images for both services
- Tag images with `latest` and commit hash
- Push images to ECR
- Trigger ECS service updates

### Step 4: Get Your ALB URL
```bash
aws cloudformation describe-stacks \
  --stack-name microservices-alb \
  --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerDNS'].OutputValue" \
  --output text
```

### Step 5: Test Your Services

Wait 2-3 minutes for containers to start, then test:
```bash
# Save ALB URL
export ALB_URL="http://<your-alb-dns>"

# Test endpoints
curl $ALB_URL/api/users
curl $ALB_URL/api/products
```

---

## 🧪 Testing

### Manual Testing

**Test User Service:**
```bash
# List all users
curl http://<alb-url>/api/users

# Get specific user
curl http://<alb-url>/api/users/1

# Create new user
curl -X POST http://<alb-url>/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","role":"user"}'

# Update user
curl -X PUT http://<alb-url>/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Name"}'

# Delete user
curl -X DELETE http://<alb-url>/api/users/1
```

**Test Product Service:**
```bash
# List all products
curl http://<alb-url>/api/products

# Filter by category
curl "http://<alb-url>/api/products?category=Electronics"

# Filter by price range
curl "http://<alb-url>/api/products?minPrice=50&maxPrice=500"

# Get specific product
curl http://<alb-url>/api/products/1
```

### Health Checks
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Check ECS service status
aws ecs describe-services \
  --cluster microservices-cluster \
  --services microservices-user-service microservices-product-service
```

---

## 📊 Monitoring

### View Logs

**CloudWatch Logs:**
```bash
# User service logs
aws logs tail /ecs/microservices/user-service --follow

# Product service logs
aws logs tail /ecs/microservices/product-service --follow
```

**AWS Console:**
1. Navigate to CloudWatch → Log groups
2. Select `/ecs/microservices/user-service` or `/ecs/microservices/product-service`
3. View log streams

### View Metrics

**CloudWatch Metrics:**
1. Navigate to CloudWatch → Metrics → ECS
2. Select your cluster: `microservices-cluster`
3. View CPU, Memory, Request Count, Response Time

### Set Up Alarms
```bash
# High CPU alarm
aws cloudwatch put-metric-alarm \
  --alarm-name user-service-high-cpu \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

---

## 💰 Cost Optimization

### Monthly Cost Breakdown

| Resource | Monthly Cost | Optimization |
|----------|-------------|--------------|
| NAT Gateway | ~$32 | Use single NAT (done) |
| ALB | ~$16 | Required for production |
| ECS Fargate (2 tasks) | ~$15 | Use Fargate Spot for non-prod |
| Data Transfer | ~$5 | Minimize cross-AZ traffic |
| CloudWatch Logs | ~$2 | 7-day retention (done) |
| ECR Storage | <$1 | Lifecycle policies (done) |
| **Total** | **~$70/month** | |

### Cost Optimization Tips

1. **Use Fargate Spot** (70% savings for non-critical workloads)
2. **Scale to zero** during off-hours for dev/test environments
3. **Use single NAT Gateway** (already implemented)
4. **Short log retention** (7 days - already implemented)
5. **Clean up old ECR images** (lifecycle policy - already implemented)

---

## 🧹 Cleanup

To avoid ongoing charges, delete all resources:

### Automated Cleanup
```bash
cd infrastructure/scripts
./cleanup.sh
```

### Manual Cleanup

Delete stacks in reverse order:
```bash
aws cloudformation delete-stack --stack-name microservices-ecs-services
aws cloudformation delete-stack --stack-name microservices-alb
aws cloudformation delete-stack --stack-name microservices-ecs-cluster
aws cloudformation delete-stack --stack-name microservices-ecr
aws cloudformation delete-stack --stack-name microservices-vpc
```

**Note:** Wait for each stack to delete before proceeding to the next.

---

## 📚 What I Learned

Building this project taught me:

### Cloud Architecture
- Designing multi-tier applications in AWS
- Understanding VPC networking (public vs private subnets, NAT gateways)
- Implementing load balancing and traffic routing
- Multi-AZ deployment for high availability

### Containerization
- Dockerizing Node.js applications
- Container security best practices
- Managing container images with ECR
- Container orchestration with ECS Fargate

### Infrastructure as Code
- Writing CloudFormation templates
- Managing infrastructure dependencies
- Creating modular, reusable infrastructure code
- Automated deployments with scripts

### DevOps Practices
- CI/CD pipeline concepts
- Blue/green deployment strategies
- Automated health checks and monitoring
- Centralized logging strategies

### AWS Services Deep Dive
- ECS Fargate vs EKS trade-offs
- Application Load Balancer configuration
- IAM roles and policies
- CloudWatch monitoring and alerting

---

## 🔮 Future Enhancements

Potential improvements for this project:

- [ ] **Add API Gateway** for rate limiting, caching, and API key management
- [ ] **Implement CI/CD** with GitHub Actions or AWS CodePipeline
- [ ] **Add RDS Database** for persistent data storage
- [ ] **Add Redis Cache** with ElastiCache for session management
- [ ] **Implement X-Ray** for distributed tracing
- [ ] **Add WAF** for web application firewall
- [ ] **Custom Domain** with Route 53 and SSL certificate
- [ ] **Add Authentication** with Cognito or JWT
- [ ] **Automated Testing** with Jest or Mocha
- [ ] **Add Swagger/OpenAPI** documentation

--- 

## 📝 License

This project is licensed under the MIT License 


