#!/bin/bash

# 🚀 Retail Store GitOps - Quick Start Script
# This script automates the complete deployment process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🛍️  Retail Store GitOps                      ║"
    echo "║            Quick Start Deployment Script                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
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

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_tools=()
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    # Check OpenTofu
    if ! command -v tofu &> /dev/null; then
        missing_tools+=("opentofu")
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        missing_tools+=("docker")
    fi
    
    # Check Git
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install the missing tools and run this script again."
        print_info "Installation guides: https://github.com/NitishJha199/retail-store-opentofu-gitops#prerequisites"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured or invalid"
        print_info "Run 'aws configure' to set up your credentials"
        exit 1
    fi
    
    print_success "All prerequisites satisfied!"
}

display_info() {
    local aws_account=$(aws sts get-caller-identity --query Account --output text)
    local aws_region=$(aws configure get region || echo "us-west-2")
    local aws_user=$(aws sts get-caller-identity --query Arn --output text)
    
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Deployment Information                    ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║ AWS Account: $aws_account                              ║"
    echo "║ AWS Region:  $aws_region                                    ║"
    echo "║ AWS User:    $(echo $aws_user | cut -d'/' -f2)                                      ║"
    echo "║ Cluster:     retail-store-$(date +%s | tail -c 5)                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

confirm_deployment() {
    echo -e "${YELLOW}"
    echo "⚠️  This script will:"
    echo "   • Create AWS resources (EKS cluster, VPC, ECR repositories)"
    echo "   • Deploy ArgoCD and application services"
    echo "   • Build and push Docker images to ECR"
    echo "   • Estimated cost: $50-100/month"
    echo "   • Deployment time: 15-20 minutes"
    echo -e "${NC}"
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Deployment cancelled by user"
        exit 0
    fi
}

deploy_infrastructure() {
    print_step "Deploying infrastructure (this may take 10-15 minutes)..."
    
    # Make scripts executable
    chmod +x deploy-modules.sh
    chmod +x scripts/build-and-push-images.sh
    chmod +x test-deployment.sh
    
    # Deploy infrastructure
    if ./deploy-modules.sh; then
        print_success "Infrastructure deployed successfully!"
    else
        print_error "Infrastructure deployment failed"
        exit 1
    fi
}

build_and_push_images() {
    print_step "Building and pushing container images (this may take 10-15 minutes)..."
    
    if ./scripts/build-and-push-images.sh; then
        print_success "All images built and pushed successfully!"
    else
        print_error "Image build/push failed"
        exit 1
    fi
}

wait_for_pods() {
    print_step "Waiting for all pods to be ready..."
    
    local timeout=300
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        local pending_pods=$(kubectl get pods -n retail-store --no-headers | grep -v Running | wc -l)
        
        if [ $pending_pods -eq 0 ]; then
            print_success "All pods are running!"
            return 0
        fi
        
        print_info "Waiting for $pending_pods pods to be ready... (${elapsed}s/${timeout}s)"
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    print_warning "Some pods may still be starting. Check with: kubectl get pods -n retail-store"
}

display_access_info() {
    print_step "Gathering access information..."
    
    # Get ArgoCD password
    local argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Not available")
    
    # Get load balancer URL
    local lb_url=$(kubectl get ingress retail-store-ui-direct -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Not available yet")
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🎉 Deployment Successful! 🎉                 ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║ 🛍️  Retail Store Application:                               ║"
    echo "║     URL: http://$lb_url"
    echo "║                                                              ║"
    echo "║ 🔄 ArgoCD Dashboard:                                         ║"
    echo "║     URL: https://localhost:8080 (after port-forward)        ║"
    echo "║     Username: admin                                          ║"
    echo "║     Password: $argocd_password"
    echo "║                                                              ║"
    echo "║ 📋 Useful Commands:                                          ║"
    echo "║     kubectl get pods -n retail-store                        ║"
    echo "║     kubectl get applications -n argocd                      ║"
    echo "║     kubectl port-forward svc/argocd-server -n argocd 8080:443 ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

run_tests() {
    print_step "Running deployment tests..."
    
    if ./test-deployment.sh; then
        print_success "All tests passed!"
    else
        print_warning "Some tests failed, but deployment may still be functional"
    fi
}

cleanup_on_error() {
    print_error "Deployment failed. Would you like to clean up resources? (y/N)"
    read -p "> " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_step "Cleaning up resources..."
        cd open-tofu && tofu destroy -auto-approve
        print_success "Resources cleaned up"
    fi
}

main() {
    # Set up error handling
    trap cleanup_on_error ERR
    
    print_header
    check_prerequisites
    display_info
    confirm_deployment
    
    echo -e "${BLUE}"
    echo "🚀 Starting deployment process..."
    echo -e "${NC}"
    
    deploy_infrastructure
    build_and_push_images
    wait_for_pods
    run_tests
    display_access_info
    
    print_info "For troubleshooting, see: docs/TROUBLESHOOTING.md"
    print_info "For detailed documentation, see: docs/DEPLOYMENT-GUIDE.md"
    print_info "To contribute, see: CONTRIBUTING.md"
    
    echo -e "${GREEN}"
    echo "🎉 Deployment completed successfully!"
    echo "🌟 Don't forget to star the repository if this helped you!"
    echo -e "${NC}"
}

# Run main function
main "$@"