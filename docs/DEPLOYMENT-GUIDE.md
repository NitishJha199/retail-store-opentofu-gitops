# 🚀 Complete Deployment Guide

This guide provides detailed step-by-step instructions for deploying the Retail Store application using GitOps with OpenTofu and ArgoCD.

## 📋 Pre-Deployment Checklist

### ✅ Prerequisites Verification

Before starting the deployment, ensure you have completed all prerequisites:

```bash
# 1. Verify AWS CLI installation and configuration
aws --version
aws sts get-caller-identity

# 2. Verify OpenTofu installation
tofu --version

# 3. Verify kubectl installation
kubectl version --client

# 4. Verify Docker installation
docker --version

# 5. Verify Git configuration
git config --global user.name
git config --global user.email
```

### 🔑 AWS Permissions

Ensure your AWS user/role has the following permissions:
- EKS full access
- ECR full access
- VPC full access
- IAM permissions for creating roles and policies
- EC2 permissions for managing instances and security groups

## 🏗️ Phase 1: Infrastructure Deployment

### Step 1: Clone and Prepare Repository

```bash
# Clone the repository
git clone https://github.com/NitishJha199/retail-store-opentofu-gitops.git
cd retail-store-opentofu-gitops

# Make scripts executable
chmod +x deploy-modules.sh
chmod +x scripts/build-and-push-images.sh
chmod +x test-deployment.sh
```

### Step 2: Configure Variables (Optional)

Edit the variables file to customize your deployment:

```bash
# Edit infrastructure variables
nano open-tofu/variables.tf
```

Key variables you might want to modify:
```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "retail-store"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["c7i-flex.large"]
}
```

### Step 3: Deploy Infrastructure

#### Option A: Automated Deployment (Recommended)
```bash
# Run the automated deployment script
./deploy-modules.sh
```

#### Option B: Manual Step-by-Step Deployment

```bash
cd open-tofu

# Initialize OpenTofu
tofu init

# Phase 1: VPC and Networking
echo "🏠 Deploying VPC and networking..."
tofu plan -target="module.vpc"
tofu apply -target="module.vpc" -auto-approve

# Phase 2: ECR Repositories
echo "📦 Creating ECR repositories..."
tofu plan -target="aws_ecr_repository.retail_store_services"
tofu apply -target="aws_ecr_repository.retail_store_services" -auto-approve

# Phase 3: EKS Cluster
echo "☸️ Creating EKS cluster..."
tofu plan -target="module.eks"
tofu apply -target="module.eks" -auto-approve

# Phase 4: EKS Add-ons
echo "🔧 Installing EKS add-ons..."
tofu plan -target="module.eks_addons"
tofu apply -target="module.eks_addons" -auto-approve

# Phase 5: ArgoCD and Applications
echo "🔄 Deploying ArgoCD..."
tofu apply -auto-approve

cd ..
```

### Step 4: Configure kubectl

```bash
# Update kubeconfig to connect to the new cluster
aws eks update-kubeconfig --region us-west-2 --name $(cd open-tofu && tofu output -raw cluster_name)

# Verify connection
kubectl get nodes
kubectl get namespaces
```

Expected output:
```
NAME                  STATUS   ROLES    AGE   VERSION
i-xxxxxxxxxxxxxxxxx   Ready    <none>   5m    v1.33.7-eks-3c60543

NAME              STATUS   AGE
default           Active   10m
kube-system       Active   10m
kube-public       Active   10m
kube-node-lease   Active   10m
argocd            Active   5m
cert-manager      Active   5m
ingress-nginx     Active   5m
retail-store      Active   5m
```

## 📦 Phase 2: Container Images

### Step 1: Build and Push Images

#### Option A: Automated Build (Recommended)
```bash
# Build and push all images automatically
./scripts/build-and-push-images.sh
```

#### Option B: Manual Build Process

```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build UI Service
echo "🛍️ Building UI service..."
docker build -t $ECR_REGISTRY/retail-store-ui:latest ./src/ui/
docker push $ECR_REGISTRY/retail-store-ui:latest

# Build Catalog Service
echo "📦 Building Catalog service..."
docker build -t $ECR_REGISTRY/retail-store-catalog:latest ./src/catalog/
docker push $ECR_REGISTRY/retail-store-catalog:latest

# Build Cart Service
echo "🛒 Building Cart service..."
docker build -t $ECR_REGISTRY/retail-store-cart:latest ./src/cart/
docker push $ECR_REGISTRY/retail-store-cart:latest

# Build Orders Service
echo "📋 Building Orders service..."
docker build -t $ECR_REGISTRY/retail-store-orders:latest ./src/orders/
docker push $ECR_REGISTRY/retail-store-orders:latest

# Build Checkout Service
echo "💳 Building Checkout service..."
docker build -t $ECR_REGISTRY/retail-store-checkout:latest ./src/checkout/
docker push $ECR_REGISTRY/retail-store-checkout:latest
```

### Step 2: Verify Images in ECR

```bash
# List all ECR repositories
aws ecr describe-repositories --region us-west-2

# Check images in each repository
for repo in ui catalog cart orders checkout; do
  echo "Images in retail-store-$repo:"
  aws ecr list-images --repository-name retail-store-$repo --region us-west-2
done
```

## 🔄 Phase 3: ArgoCD Configuration

### Step 1: Access ArgoCD

```bash
# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"

# Port forward to access ArgoCD UI (run in separate terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access ArgoCD at https://localhost:8080
# Username: admin
# Password: (from above command)
```

### Step 2: Verify ArgoCD Applications

```bash
# Check ArgoCD applications status
kubectl get applications -n argocd

# Get detailed application status
kubectl describe application retail-store-ui -n argocd
```

Expected output:
```
NAME                    SYNC STATUS   HEALTH STATUS
retail-store-cart       Synced        Healthy
retail-store-catalog    Synced        Healthy
retail-store-checkout   Synced        Healthy
retail-store-orders     Synced        Healthy
retail-store-ui         Synced        Healthy
```

### Step 3: Troubleshoot Node Taints (if needed)

If pods are stuck in "Pending" state due to node taints:

```bash
# Check for node taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

# Remove disruption taint if present
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')
kubectl taint node $NODE_NAME karpenter.sh/disrupted:NoSchedule- || echo "No taint to remove"
```

## 🌐 Phase 4: Application Access

### Step 1: Get Load Balancer URL

```bash
# Get ingress information
kubectl get ingress -n retail-store

# Get load balancer URL
LB_URL=$(kubectl get ingress retail-store-ui-direct -n retail-store -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$LB_URL"
```

### Step 2: Test Application

```bash
# Test application health
curl -s -o /dev/null -w "%{http_code}" http://$LB_URL
# Expected: 200

# Test specific endpoints
curl http://$LB_URL/catalogue
curl http://$LB_URL/cart
curl http://$LB_URL/orders
```

### Step 3: Access Application in Browser

Open your browser and navigate to the load balancer URL. You should see the retail store application interface.

## 🧪 Phase 5: Testing and Validation

### Step 1: Run Automated Tests

```bash
# Run the comprehensive test suite
./test-deployment.sh
```

### Step 2: Manual Validation

#### Check Pod Status
```bash
# Verify all pods are running
kubectl get pods -n retail-store

# Check pod logs for any errors
kubectl logs -l app.kubernetes.io/name=ui -n retail-store
kubectl logs -l app.kubernetes.io/name=catalog -n retail-store
kubectl logs -l app.kubernetes.io/name=carts -n retail-store
kubectl logs -l app.kubernetes.io/name=orders -n retail-store
kubectl logs -l app.kubernetes.io/name=checkout -n retail-store
```

#### Check Service Connectivity
```bash
# Test internal service connectivity
kubectl exec -it deployment/retail-store-ui -n retail-store -- curl http://retail-store-catalog:80/catalogue
kubectl exec -it deployment/retail-store-ui -n retail-store -- curl http://retail-store-cart-carts:80/carts
```

#### Check Resource Usage
```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods -n retail-store
```

### Step 3: Load Testing (Optional)

```bash
# Install hey for load testing
go install github.com/rakyll/hey@latest

# Run load test
hey -n 1000 -c 10 http://$LB_URL/

# Monitor during load test
watch kubectl top pods -n retail-store
```

## 🔧 Phase 6: Configuration and Customization

### Step 1: Configure Custom Domain (Optional)

If you have a custom domain:

```bash
# Update ingress configuration
kubectl patch ingress retail-store-ui-domain -n retail-store -p '{"spec":{"rules":[{"host":"your-domain.com","http":{"paths":[{"path":"/","pathType":"Prefix","backend":{"service":{"name":"retail-store-ui","port":{"number":80}}}}]}}]}}'

# Update DNS to point to load balancer
# Create A record: your-domain.com -> $LB_URL
```

### Step 2: Enable SSL/TLS (Optional)

```bash
# Verify cert-manager is working
kubectl get clusterissuer -n cert-manager

# Check certificate status
kubectl get certificates -n retail-store
```

### Step 3: Configure Monitoring (Optional)

```bash
# Deploy Prometheus and Grafana (if desired)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
```

## 🚀 Phase 7: GitOps Workflow Setup

### Step 1: Fork Repository

1. Fork the repository to your GitHub account
2. Update ArgoCD applications to point to your fork:

```bash
# Update repository URLs in ArgoCD applications
sed -i 's|NitishJha199/retail-store-opentofu-gitops|YOUR_USERNAME/retail-store-opentofu-gitops|g' argocd/applications/*.yaml
sed -i 's|NitishJha199/retail-store-opentofu-gitops|YOUR_USERNAME/retail-store-opentofu-gitops|g' argocd/projects/retail-store-project.yaml

# Apply updated configurations
kubectl apply -f argocd/applications/
kubectl apply -f argocd/projects/
```

### Step 2: Configure GitHub Actions

1. Add the following secrets to your GitHub repository:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (us-west-2)

2. Push changes to trigger the workflow:

```bash
git add .
git commit -m "Configure GitOps workflow"
git push origin main
```

### Step 3: Test GitOps Workflow

1. Make a change to application code
2. Commit and push changes
3. Watch GitHub Actions build and push new images
4. Observe ArgoCD automatically deploy changes

## 🔍 Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Pods stuck in Pending state
```bash
# Check node capacity
kubectl describe nodes

# Check for resource constraints
kubectl describe pod <pod-name> -n retail-store

# Solution: Remove node taints or scale cluster
kubectl taint node <node-name> karpenter.sh/disrupted:NoSchedule-
```

#### Issue: Image pull errors
```bash
# Check ECR repositories
aws ecr describe-repositories --region us-west-2

# Verify images exist
aws ecr list-images --repository-name retail-store-ui --region us-west-2

# Solution: Rebuild and push images
./scripts/build-and-push-images.sh
```

#### Issue: ArgoCD sync failures
```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# View detailed error
kubectl describe application retail-store-ui -n argocd

# Force refresh
kubectl patch application retail-store-ui -n argocd -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' --type merge
```

#### Issue: Load balancer not accessible
```bash
# Check ingress status
kubectl get ingress -n retail-store

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check service endpoints
kubectl get endpoints -n retail-store
```

### Debugging Commands

```bash
# Get cluster information
kubectl cluster-info

# Check all resources in retail-store namespace
kubectl get all -n retail-store

# View events
kubectl get events -n retail-store --sort-by='.lastTimestamp'

# Check logs
kubectl logs -f deployment/retail-store-ui -n retail-store

# Describe problematic resources
kubectl describe pod <pod-name> -n retail-store
kubectl describe service <service-name> -n retail-store
```

## 🧹 Cleanup

### Complete Infrastructure Cleanup

```bash
# Destroy all infrastructure
cd open-tofu
tofu destroy -auto-approve

# Clean up local Docker images
docker system prune -a

# Remove kubeconfig context
kubectl config delete-context $(kubectl config current-context)
```

### Partial Cleanup (Keep Infrastructure)

```bash
# Delete applications only
kubectl delete -f argocd/applications/

# Delete ArgoCD
kubectl delete namespace argocd

# Delete application namespace
kubectl delete namespace retail-store
```

## 📊 Monitoring and Maintenance

### Regular Maintenance Tasks

1. **Update Dependencies**: Regularly update Helm charts and container images
2. **Security Patches**: Apply security updates to base images
3. **Resource Monitoring**: Monitor resource usage and adjust limits
4. **Cost Optimization**: Review and optimize resource allocation
5. **Backup Verification**: Test backup and restore procedures

### Health Monitoring

```bash
# Daily health check script
#!/bin/bash
echo "=== Cluster Health Check ==="
kubectl get nodes
kubectl get pods -n retail-store
kubectl top nodes
kubectl top pods -n retail-store

echo "=== Application Health ==="
curl -s -o /dev/null -w "%{http_code}" http://$LB_URL

echo "=== ArgoCD Status ==="
kubectl get applications -n argocd
```

## 🎯 Next Steps

After successful deployment:

1. **Explore ArgoCD UI**: Familiarize yourself with GitOps workflows
2. **Test CI/CD**: Make code changes and observe automated deployments
3. **Add Monitoring**: Implement comprehensive monitoring with Prometheus/Grafana
4. **Implement Security**: Add network policies and security scanning
5. **Scale Applications**: Test horizontal pod autoscaling
6. **Add Persistence**: Implement persistent storage for databases
7. **Multi-Environment**: Set up staging and production environments

Congratulations! You have successfully deployed a production-ready microservices application using GitOps principles with OpenTofu and ArgoCD. 🎉