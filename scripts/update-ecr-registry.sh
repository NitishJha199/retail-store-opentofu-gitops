#!/bin/bash

# 🔧 Update ECR Registry Configuration
# This script updates all Helm charts to use your ECR registry

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Get AWS Account ID
print_status "Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Could not get AWS Account ID. Please configure AWS CLI first."
    echo "Run: aws configure"
    exit 1
fi

AWS_REGION=${AWS_REGION:-"us-west-2"}
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

print_success "AWS Account ID: $AWS_ACCOUNT_ID"
print_success "ECR Registry: $ECR_REGISTRY"

# Services to update
SERVICES=("ui" "catalog" "cart" "orders" "checkout")

# Update each service's values.yaml
for service in "${SERVICES[@]}"; do
    VALUES_FILE="src/${service}/chart/values.yaml"
    
    if [ -f "$VALUES_FILE" ]; then
        print_status "Updating $VALUES_FILE..."
        
        # Create backup
        cp "$VALUES_FILE" "${VALUES_FILE}.bak"
        
        # Update repository URL
        sed -i "s|repository: .*|repository: ${ECR_REGISTRY}/retail-store-${service}|g" "$VALUES_FILE"
        
        # Ensure tag is set to latest
        if ! grep -q "tag:" "$VALUES_FILE"; then
            # Add tag if it doesn't exist
            sed -i "/repository:/a\\  tag: \"latest\"" "$VALUES_FILE"
        fi
        
        print_success "✅ Updated $VALUES_FILE"
    else
        echo "⚠️  $VALUES_FILE not found, skipping..."
    fi
done

print_success "🎉 All Helm charts updated with ECR registry!"
print_status "Next steps:"
echo "1. Review the changes:"
echo "   git diff src/*/chart/values.yaml"
echo ""
echo "2. Commit the changes:"
echo "   git add src/*/chart/values.yaml"
echo "   git commit -m 'Configure ECR registry for all services'"
echo "   git push origin gitops"
echo ""
echo "3. The GitHub Actions workflow will handle building and pushing images to ECR"