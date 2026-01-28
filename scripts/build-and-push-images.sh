#!/bin/bash

# 🐳 Build and Push Initial Images to ECR
# This script builds and pushes initial container images to ECR

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
AWS_REGION=${AWS_REGION:-"us-west-2"}
SERVICES=("ui" "catalog" "cart" "orders" "checkout")

# Get AWS Account ID
print_status "Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

print_success "AWS Account ID: $AWS_ACCOUNT_ID"
print_success "ECR Registry: $ECR_REGISTRY"

# Login to ECR
print_status "Logging in to Amazon ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build and push images for each service
for service in "${SERVICES[@]}"; do
    print_status "Processing service: $service"
    
    # Create ECR repository if it doesn't exist
    print_status "Creating ECR repository for $service..."
    aws ecr describe-repositories --repository-names "retail-store-$service" --region $AWS_REGION 2>/dev/null || \
    aws ecr create-repository \
        --repository-name "retail-store-$service" \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    
    # Build and push image
    print_status "Building and pushing image for $service..."
    
    IMAGE_URI="$ECR_REGISTRY/retail-store-$service"
    
    # Build image
    docker build -t "$IMAGE_URI:latest" "./src/$service/"
    
    # Push image
    docker push "$IMAGE_URI:latest"
    
    print_success "Successfully pushed $IMAGE_URI:latest"
    
    # Update Helm values with correct ECR registry
    VALUES_FILE="src/$service/chart/values.yaml"
    if [ -f "$VALUES_FILE" ]; then
        print_status "Updating $VALUES_FILE with ECR registry..."
        
        # Update AWS Account ID in values.yaml
        sed -i.bak "s|accountId: \".*\"|accountId: \"$AWS_ACCOUNT_ID\"|g" "$VALUES_FILE"
        
        print_success "Updated $VALUES_FILE"
    fi
done

print_success "🎉 All images built and pushed successfully!"
print_status "Next steps:"
echo "1. Commit and push the updated Helm values:"
echo "   git add src/*/chart/values.yaml"
echo "   git commit -m 'Update ECR registry configuration'"
echo "   git push origin gitops"
echo ""
echo "2. Deploy infrastructure if not already done:"
echo "   cd open-tofu && tofu apply"
echo ""
echo "3. ArgoCD will automatically deploy the applications with the new images"