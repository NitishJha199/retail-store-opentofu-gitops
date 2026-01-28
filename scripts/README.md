# 🐳 Container Image Management Scripts

This directory contains scripts to help manage container images for the retail store application.

## 📋 Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed and running
- ECR repositories created (done automatically by script)

## 🚀 Build and Push Initial Images

To build and push initial images to ECR:

```bash
# Make script executable
chmod +x scripts/build-and-push-images.sh

# Run the script
./scripts/build-and-push-images.sh
```

This script will:
1. ✅ Login to Amazon ECR
2. ✅ Create ECR repositories for each service
3. ✅ Build Docker images for all services
4. ✅ Push images to ECR with `latest` tag
5. ✅ Update Helm values with correct ECR registry URLs

## 🔄 Automated CI/CD Process

Once the initial setup is complete, the GitHub Actions workflow will:

1. **Detect Changes** - Monitor changes to service code
2. **Run Tests** - Execute unit tests for changed services
3. **Build Images** - Build new Docker images for changed services
4. **Push to ECR** - Push images with commit SHA tags
5. **Update Helm** - Update Helm values with new image tags
6. **Deploy via ArgoCD** - ArgoCD automatically deploys updated applications

## 📊 Image Tagging Strategy

- **`latest`** - Always points to the most recent build
- **`{commit-sha}`** - Specific commit version for rollbacks
- **Lifecycle Policy** - Automatically removes old images (keeps last 10 tagged images)

## 🛡️ Security Features

- **Image Scanning** - Automatic vulnerability scanning on push
- **Encryption** - Images encrypted at rest with AES256
- **Access Control** - IAM-based access control for ECR repositories

## 🔧 Manual Commands

### Login to ECR
```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin {account-id}.dkr.ecr.us-west-2.amazonaws.com
```

### Build Single Service
```bash
# Example for UI service
docker build -t {account-id}.dkr.ecr.us-west-2.amazonaws.com/retail-store-ui:latest ./src/ui/
docker push {account-id}.dkr.ecr.us-west-2.amazonaws.com/retail-store-ui:latest
```

### List ECR Repositories
```bash
aws ecr describe-repositories --region us-west-2
```

### View Image Scan Results
```bash
aws ecr describe-image-scan-findings --repository-name retail-store-ui --image-id imageTag=latest --region us-west-2
```