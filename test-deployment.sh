#!/bin/bash

# 🧪 Test Deployment Script
# This script tests all components before pushing to Git

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "🧪 Testing Deployment Configuration"
echo "=================================="

# Test 1: AWS Configuration
print_status "Testing AWS configuration..."
if aws sts get-caller-identity > /dev/null 2>&1; then
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_success "AWS configured - Account ID: $AWS_ACCOUNT_ID"
else
    print_error "AWS CLI not configured"
    exit 1
fi

# Test 2: OpenTofu Configuration
print_status "Testing OpenTofu configuration..."
cd open-tofu
if tofu validate > /dev/null 2>&1; then
    print_success "OpenTofu configuration is valid"
else
    print_error "OpenTofu configuration has errors"
    exit 1
fi
cd ..

# Test 3: Helm Charts Validation
print_status "Testing Helm charts..."
SERVICES=("ui" "catalog" "cart" "orders" "checkout")
for service in "${SERVICES[@]}"; do
    if helm lint "src/${service}/chart" > /dev/null 2>&1; then
        print_success "Helm chart for $service is valid"
    else
        print_error "Helm chart for $service has errors"
        exit 1
    fi
done

# Test 4: Docker Build Test
print_status "Testing Docker build (UI service)..."
if docker build -t test-ui:latest src/ui > /dev/null 2>&1; then
    print_success "Docker build successful"
    docker rmi test-ui:latest > /dev/null 2>&1
else
    print_error "Docker build failed"
    exit 1
fi

# Test 5: ECR Access
print_status "Testing ECR access..."
if aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com > /dev/null 2>&1; then
    print_success "ECR login successful"
else
    print_error "ECR login failed"
    exit 1
fi

# Test 6: Helm Values Validation
print_status "Validating Helm values configuration..."
for service in "${SERVICES[@]}"; do
    VALUES_FILE="src/${service}/chart/values.yaml"
    if grep -q "${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/retail-store-${service}" "$VALUES_FILE"; then
        print_success "ECR repository URL correct for $service"
    else
        print_error "ECR repository URL incorrect for $service"
        exit 1
    fi
done

# Test 7: GitHub Actions Workflow Validation
print_status "Validating GitHub Actions workflow..."
if [ -f ".github/workflows/deploy.yml" ]; then
    print_success "GitHub Actions workflow exists"
else
    print_error "GitHub Actions workflow missing"
    exit 1
fi

echo ""
print_success "🎉 All tests passed! Ready for deployment."
echo ""
echo "📋 Next Steps:"
echo "1. Deploy infrastructure: cd open-tofu && tofu apply"
echo "2. Configure kubectl: aws eks update-kubeconfig --region us-west-2 --name <cluster-name>"
echo "3. Push to Git: git add . && git commit -m 'Setup GitOps deployment' && git push origin gitops"
echo ""
echo "💡 The GitHub Actions workflow will automatically:"
echo "   - Build container images"
echo "   - Push to ECR"
echo "   - Update Helm charts"
echo "   - Trigger ArgoCD deployment"