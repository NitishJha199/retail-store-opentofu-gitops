#!/bin/bash

# 🔍 Setup Verification Script
# This script verifies that the deployment was successful

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
    echo "║              🔍 Deployment Verification                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✅ PASS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠️  WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[❌ FAIL]${NC} $1"
}

check_cluster_connection() {
    print_check "Checking cluster connection..."
    
    if kubectl cluster-info &> /dev/null; then
        local cluster_name=$(kubectl config current-context)
        print_success "Connected to cluster: $cluster_name"
        return 0
    else
        print_error "Cannot connect to Kubernetes cluster"
        return 1
    fi
}

check_nodes() {
    print_check "Checking cluster nodes..."
    
    local node_count=$(kubectl get nodes --no-headers | wc -l)
    local ready_nodes=$(kubectl get nodes --no-headers | grep " Ready " | wc -l)
    
    if [ $ready_nodes -gt 0 ]; then
        print_success "$ready_nodes/$node_count nodes are ready"
        kubectl get nodes -o wide
        return 0
    else
        print_error "No ready nodes found"
        return 1
    fi
}

check_namespaces() {
    print_check "Checking required namespaces..."
    
    local required_namespaces=("retail-store" "argocd" "ingress-nginx" "cert-manager")
    local all_good=true
    
    for ns in "${required_namespaces[@]}"; do
        if kubectl get namespace $ns &> /dev/null; then
            print_success "Namespace '$ns' exists"
        else
            print_error "Namespace '$ns' not found"
            all_good=false
        fi
    done
    
    return $all_good
}

check_application_pods() {
    print_check "Checking application pods..."
    
    local services=("retail-store-ui" "retail-store-catalog" "retail-store-cart-carts" "retail-store-orders" "retail-store-checkout")
    local all_running=true
    
    echo -e "\n${CYAN}Application Pod Status:${NC}"
    kubectl get pods -n retail-store -o wide
    echo
    
    for service in "${services[@]}"; do
        local pod_status=$(kubectl get pods -n retail-store -l app.kubernetes.io/name=${service#retail-store-} --no-headers 2>/dev/null | awk '{print $3}' | head -1)
        
        if [ "$pod_status" = "Running" ]; then
            print_success "$service is running"
        else
            print_error "$service is not running (status: $pod_status)"
            all_running=false
        fi
    done
    
    if $all_running; then
        return 0
    else
        return 1
    fi
}

check_argocd_applications() {
    print_check "Checking ArgoCD applications..."
    
    echo -e "\n${CYAN}ArgoCD Application Status:${NC}"
    kubectl get applications -n argocd
    echo
    
    local apps=$(kubectl get applications -n argocd --no-headers | wc -l)
    local healthy_apps=$(kubectl get applications -n argocd --no-headers | grep "Healthy" | wc -l)
    
    if [ $healthy_apps -eq $apps ] && [ $apps -gt 0 ]; then
        print_success "All $apps ArgoCD applications are healthy"
        return 0
    else
        print_warning "$healthy_apps/$apps ArgoCD applications are healthy"
        return 1
    fi
}

check_ingress() {
    print_check "Checking ingress configuration..."
    
    echo -e "\n${CYAN}Ingress Status:${NC}"
    kubectl get ingress -n retail-store
    echo
    
    local lb_url=$(kubectl get ingress retail-store-ui-direct -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -n "$lb_url" ]; then
        print_success "Load balancer URL: http://$lb_url"
        
        # Test application response
        print_check "Testing application response..."
        local response_code=$(curl -s -o /dev/null -w "%{http_code}" http://$lb_url --max-time 10 2>/dev/null || echo "000")
        
        if [ "$response_code" = "200" ]; then
            print_success "Application is responding (HTTP $response_code)"
        else
            print_warning "Application response: HTTP $response_code"
        fi
        
        return 0
    else
        print_error "Load balancer URL not available"
        return 1
    fi
}

check_ecr_images() {
    print_check "Checking ECR images..."
    
    local aws_account=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    local region=$(aws configure get region 2>/dev/null || echo "us-west-2")
    
    if [ -n "$aws_account" ]; then
        local services=("ui" "catalog" "cart" "orders" "checkout")
        local all_images_exist=true
        
        for service in "${services[@]}"; do
            local image_count=$(aws ecr list-images --repository-name retail-store-$service --region $region --query 'imageIds' --output text 2>/dev/null | wc -w)
            
            if [ $image_count -gt 0 ]; then
                print_success "retail-store-$service has $image_count image(s)"
            else
                print_error "retail-store-$service has no images"
                all_images_exist=false
            fi
        done
        
        if $all_images_exist; then
            return 0
        else
            return 1
        fi
    else
        print_warning "Cannot check ECR images (AWS CLI not configured)"
        return 1
    fi
}

get_access_info() {
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🎯 Access Information                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝${NC}"
    
    # Application URL
    local lb_url=$(kubectl get ingress retail-store-ui-direct -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$lb_url" ]; then
        echo -e "${GREEN}🛍️  Retail Store Application:${NC}"
        echo -e "   URL: ${CYAN}http://$lb_url${NC}"
        echo
    fi
    
    # ArgoCD Info
    local argocd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null)
    if [ -n "$argocd_password" ]; then
        echo -e "${GREEN}🔄 ArgoCD Dashboard:${NC}"
        echo -e "   URL: ${CYAN}https://localhost:8080${NC} (after port-forward)"
        echo -e "   Username: ${CYAN}admin${NC}"
        echo -e "   Password: ${CYAN}$argocd_password${NC}"
        echo -e "   Port-forward: ${YELLOW}kubectl port-forward svc/argocd-server -n argocd 8080:443${NC}"
        echo
    fi
    
    # Useful commands
    echo -e "${GREEN}📋 Useful Commands:${NC}"
    echo -e "   ${YELLOW}kubectl get pods -n retail-store${NC}              # Check application pods"
    echo -e "   ${YELLOW}kubectl get applications -n argocd${NC}            # Check ArgoCD apps"
    echo -e "   ${YELLOW}kubectl logs -f deployment/retail-store-ui -n retail-store${NC}  # View logs"
    echo -e "   ${YELLOW}./test-deployment.sh${NC}                         # Run tests"
}

main() {
    print_header
    
    local overall_status=0
    
    check_cluster_connection || overall_status=1
    echo
    
    check_nodes || overall_status=1
    echo
    
    check_namespaces || overall_status=1
    echo
    
    check_application_pods || overall_status=1
    echo
    
    check_argocd_applications || overall_status=1
    echo
    
    check_ingress || overall_status=1
    echo
    
    check_ecr_images || overall_status=1
    echo
    
    get_access_info
    
    if [ $overall_status -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All checks passed! Your deployment is ready to use.${NC}"
    else
        echo -e "\n${YELLOW}⚠️  Some checks failed. See troubleshooting guide: docs/TROUBLESHOOTING.md${NC}"
    fi
    
    return $overall_status
}

# Run main function
main "$@"