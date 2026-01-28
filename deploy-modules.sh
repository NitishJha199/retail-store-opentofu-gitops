#!/bin/bash

# 🚀 Module-by-Module Deployment Script
# This script deploys OpenTofu modules step by step

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[DEPLOY]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to deploy a specific module
deploy_module() {
    local module_name=$1
    local description=$2
    
    echo ""
    print_status "Deploying: $description"
    echo "Module: $module_name"
    echo "----------------------------------------"
    
    if tofu apply -target="$module_name" -auto-approve; then
        print_success "$description deployed successfully!"
    else
        print_error "Failed to deploy $description"
        exit 1
    fi
    
    echo ""
    read -p "Press Enter to continue to next module..."
}

# Function to show module status
show_status() {
    echo ""
    print_status "Current deployment status:"
    tofu show -json | jq -r '.values.root_module.resources[]? | select(.type != "data") | "\(.address) - \(.values.id // "pending")"' 2>/dev/null || echo "No resources deployed yet"
    echo ""
}

echo "🚀 OpenTofu Module-by-Module Deployment"
echo "======================================="
echo ""
print_warning "This will deploy infrastructure step by step."
print_warning "Each module will be deployed individually for better control."
echo ""

# Change to terraform directory
cd open-tofu

# Step 1: Deploy VPC and Networking
deploy_module "module.vpc" "VPC and Networking Infrastructure"

# Step 2: Deploy ECR Repositories
deploy_module "aws_ecr_repository.retail_store_services" "ECR Container Repositories"

# Step 3: Deploy EKS Cluster (without addons)
deploy_module "module.retail_app_eks" "EKS Cluster and Core Components"

# Step 4: Deploy EKS Addons (cert-manager, ingress-nginx)
deploy_module "module.eks_addons" "EKS Add-ons (cert-manager, ingress-nginx)"

# Step 5: Deploy ArgoCD
deploy_module "helm_release.argocd" "ArgoCD GitOps Controller"

# Step 6: Deploy remaining resources
print_status "Deploying remaining resources..."
if tofu apply -auto-approve; then
    print_success "All modules deployed successfully!"
else
    print_error "Failed to deploy remaining resources"
    exit 1
fi

echo ""
print_success "🎉 Complete deployment finished!"
echo ""
print_status "Getting cluster information..."

# Get cluster info
CLUSTER_NAME=$(tofu output -raw cluster_name)
AWS_REGION=$(tofu output -raw aws_region)

echo "Cluster Name: $CLUSTER_NAME"
echo "AWS Region: $AWS_REGION"
echo ""

print_status "Configuring kubectl..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

print_success "kubectl configured successfully!"
echo ""

print_status "Useful commands:"
echo "# Check cluster status"
echo "kubectl cluster-info"
echo ""
echo "# Check nodes"
echo "kubectl get nodes"
echo ""
echo "# Check ArgoCD"
echo "kubectl get pods -n argocd"
echo ""
echo "# Get ArgoCD password"
echo "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""
echo "# Port-forward ArgoCD"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"