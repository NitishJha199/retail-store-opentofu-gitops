# 🚀 Manual Module-by-Module Deployment Guide

## 📋 **Deployment Order**

Follow these steps to deploy each module individually for maximum control:

### **Step 1: 🌐 Deploy VPC and Networking**

```bash
cd open-tofu

# Deploy VPC module
tofu apply -target="module.vpc" -auto-approve

# Verify VPC creation
tofu show | grep vpc_id
```

**What this creates:**
- ✅ VPC with 10.0.0.0/16 CIDR
- ✅ 3 Public subnets (us-west-2a, us-west-2b, us-west-2c)
- ✅ 3 Private subnets (us-west-2a, us-west-2b, us-west-2c)
- ✅ Internet Gateway
- ✅ NAT Gateway (single for cost optimization)
- ✅ Route tables and associations

---

### **Step 2: 📦 Deploy ECR Repositories**

```bash
# Deploy ECR repositories
tofu apply -target="aws_ecr_repository.retail_store_services" -auto-approve

# Verify ECR repositories
aws ecr describe-repositories --region us-west-2
```

**What this creates:**
- ✅ retail-store-ui repository
- ✅ retail-store-catalog repository  
- ✅ retail-store-cart repository
- ✅ retail-store-orders repository
- ✅ retail-store-checkout repository
- ✅ Lifecycle policies for image cleanup
- ✅ Vulnerability scanning enabled

---

### **Step 3: 🎯 Deploy EKS Cluster Core**

```bash
# Deploy EKS cluster (this takes 10-15 minutes)
tofu apply -target="module.retail_app_eks" -auto-approve

# Check cluster status
aws eks describe-cluster --name $(tofu output -raw cluster_name) --region us-west-2
```

**What this creates:**
- ✅ EKS Cluster with Auto Mode
- ✅ KMS encryption key
- ✅ IAM roles and policies
- ✅ Security groups
- ✅ OIDC provider for service accounts

---

### **Step 4: 🔧 Deploy EKS Add-ons**

```bash
# Deploy add-ons (cert-manager, ingress-nginx)
tofu apply -target="module.eks_addons" -auto-approve

# Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name $(tofu output -raw cluster_name)

# Verify add-ons
kubectl get pods -n cert-manager
kubectl get pods -n ingress-nginx
```

**What this creates:**
- ✅ cert-manager for SSL certificates
- ✅ NGINX Ingress Controller
- ✅ Load Balancer for external access
- ✅ Service accounts with IRSA

---

### **Step 5: 🔄 Deploy ArgoCD**

```bash
# Deploy ArgoCD
tofu apply -target="helm_release.argocd" -auto-approve

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Verify ArgoCD
kubectl get pods -n argocd
```

**What this creates:**
- ✅ ArgoCD server and components
- ✅ ArgoCD UI accessible via port-forward
- ✅ GitOps controller ready for applications

---

### **Step 6: 🎯 Deploy Remaining Resources**

```bash
# Deploy any remaining resources
tofu apply -auto-approve

# Verify complete deployment
kubectl cluster-info
kubectl get nodes
```

---

## 🔍 **Verification Commands**

### **Check Infrastructure Status**
```bash
# Cluster info
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# All pods across namespaces
kubectl get pods -A

# Services and load balancers
kubectl get svc -A
```

### **Check ArgoCD**
```bash
# ArgoCD pods
kubectl get pods -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Access ArgoCD at: https://localhost:8080
# Username: admin
# Password: (from command above)
```

### **Check Load Balancer**
```bash
# Get load balancer URL
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Wait for external IP to be assigned
kubectl get svc -n ingress-nginx ingress-nginx-controller -w
```

---

## 🚨 **Troubleshooting**

### **If a module fails:**
```bash
# Check what went wrong
tofu show

# See detailed error
tofu apply -target="<failed-module>" -auto-approve

# Force refresh state
tofu refresh
```

### **If EKS cluster is not accessible:**
```bash
# Reconfigure kubectl
aws eks update-kubeconfig --region us-west-2 --name $(tofu output -raw cluster_name)

# Check AWS credentials
aws sts get-caller-identity

# Verify cluster exists
aws eks describe-cluster --name $(tofu output -raw cluster_name) --region us-west-2
```

### **If ArgoCD is not starting:**
```bash
# Check ArgoCD logs
kubectl logs -f deployment/argocd-server -n argocd

# Restart ArgoCD
kubectl rollout restart deployment/argocd-server -n argocd

# Check resources
kubectl describe deployment argocd-server -n argocd
```

---

## ⏱️ **Expected Timing**

| Step | Component | Time | Notes |
|------|-----------|------|-------|
| 1 | VPC | 2-3 min | Network infrastructure |
| 2 | ECR | 1-2 min | Container repositories |
| 3 | EKS | 10-15 min | Cluster creation (longest step) |
| 4 | Add-ons | 3-5 min | cert-manager, ingress-nginx |
| 5 | ArgoCD | 2-3 min | GitOps controller |
| 6 | Remaining | 1-2 min | Cleanup and finalization |

**Total: ~20-30 minutes**

---

## 🎯 **Next Steps After Deployment**

1. **Verify everything is working**
2. **Deploy applications via ArgoCD**
3. **Push code changes to Git to trigger GitOps pipeline**
4. **Monitor applications in ArgoCD UI**

Your infrastructure will be ready for the complete GitOps workflow! 🚀