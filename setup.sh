#!/bin/bash

# 🚀 OpenTofu GitOps Platform Setup Script
# This script automates the basic setup process

set -e

echo "�� Starting OpenTofu GitOps Platform Setup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v tofu &> /dev/null; then
        missing_tools+=("opentofu")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v helm &> /dev/null; then
        missing_tools+=("helm")
    fi
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_status "Please install missing tools and run this script again."
        print_status "See README.md for installation instructions."
        exit 1
    fi
    
    print_success "All required tools are installed!"
}

# Check AWS configuration
check_aws_config() {
    print_status "Checking AWS configuration..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI not configured or credentials invalid"
        print_status "Run 'aws configure' to set up your credentials"
        exit 1
    fi
    
    local account_id=$(aws sts get-caller-identity --query Account --output text)
    local region=$(aws configure get region)
    
    print_success "AWS configured - Account: $account_id, Region: $region"
}

# Check if we're on the gitops branch
check_git_branch() {
    print_status "Checking Git branch..."
    
    local current_branch=$(git branch --show-current)
    
    if [ "$current_branch" != "gitops" ]; then
        print_warning "Not on gitops branch (currently on: $current_branch)"
        read -p "Switch to gitops branch? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git checkout gitops
            print_success "Switched to gitops branch"
        else
            print_error "Please switch to gitops branch manually: git checkout gitops"
            exit 1
        fi
    else
        print_success "On gitops branch"
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure with OpenTofu..."
    
    cd terraform
    
    # Initialize OpenTofu
    print_status "Initializing OpenTofu..."
    tofu init
    
    # Plan deployment
    print_status "Planning infrastructure deployment..."
    tofu plan -out=tfplan
    
    # Ask for confirmation
    echo
    print_warning "This will create AWS resources that may incur charges."
    read -p "Continue with deployment? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Applying OpenTofu configuration..."
        tofu apply tfplan
        
        # Configure kubectl
        local cluster_name=$(tofu output -raw cluster_name)
        local region=$(tofu output -raw aws_region || aws configure get region)
        
        print_status "Configuring kubectl..."
        aws eks update-kubeconfig --region $region --name $cluster_name
        
        print_success "Infrastructure deployed successfully!"
        
        # Display important information
        echo
        print_status "=== IMPORTANT INFORMATION ==="
        echo "Cluster Name: $cluster_name"
        echo "Region: $region"
        echo "ArgoCD Password Command: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
        echo "Load Balancer Command: kubectl get svc -n ingress-nginx ingress-nginx-controller"
        echo
        
    else
        print_status "Deployment cancelled"
        exit 0
    fi
    
    cd ..
}

# Deploy ArgoCD applications
deploy_argocd_apps() {
    print_status "Deploying ArgoCD applications..."
    
    # Wait for ArgoCD to be ready
    print_status "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
    
    # Apply ArgoCD configurations
    kubectl apply -f argocd/projects/ -n argocd
    kubectl apply -f argocd/applications/ -n argocd
    
    print_success "ArgoCD applications deployed!"
}

# Display final instructions
show_final_instructions() {
    echo
    print_success "🎉 OpenTofu GitOps Platform Setup completed successfully!"
    echo
    print_status "=== NEXT STEPS ==="
    echo "1. Get ArgoCD admin password:"
    echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
    echo
    echo "2. Access ArgoCD UI:"
    echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
    echo "   Open: https://localhost:8080 (admin / password-from-step-1)"
    echo
    echo "3. Get website URL:"
    echo "   kubectl get svc -n ingress-nginx ingress-nginx-controller"
    echo "   Open the EXTERNAL-IP in your browser"
    echo
    echo "4. Test GitOps pipeline:"
    echo "   Edit any file in src/ directory, commit, and push to gitops branch"
    echo
    print_status "See README.md for detailed instructions and troubleshooting"
}

# Main execution
main() {
    echo "🚀 OpenTofu GitOps Platform Automated Setup"
    echo "==========================================="
    echo
    
    check_prerequisites
    check_aws_config
    check_git_branch
    
    echo
    print_warning "This script will:"
    print_warning "1. Deploy AWS infrastructure (EKS, VPC, etc.) using OpenTofu"
    print_warning "2. Install ArgoCD and applications"
    print_warning "3. Configure kubectl access"
    echo
    print_warning "Estimated time: 15-20 minutes"
    print_warning "Estimated cost: $50-100/month"
    echo
    
    read -p "Continue with automated setup? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        deploy_infrastructure
        deploy_argocd_apps
        show_final_instructions
    else
        print_status "Setup cancelled. Run this script again when ready."
        exit 0
    fi
}

# Run main function
main "$@"
