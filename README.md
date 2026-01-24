
# Retail Store Sample App - OpenTofu GitOps Edition

![Banner](./docs/images/banner.png)

<div align="center">

[![OpenTofu](https://img.shields.io/badge/OpenTofu-1.6+-blue)](https://opentofu.org/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-green)](https://argo-cd.readthedocs.io/)

<strong>
<h2>Enterprise GitOps CI/CD Platform with OpenTofu</h2>
</strong>

**Modern microservices architecture deployed on AWS EKS using OpenTofu and GitOps principles**

</div>

## 🌟 What Makes This Special

This is the **OpenTofu version** of the retail store GitOps platform, showcasing:

- ✅ **OpenTofu** instead of Terraform for infrastructure as code
- ✅ **Open Source Governance** - No vendor lock-in
- ✅ **Community-Driven Development** 
- ✅ **Enhanced Performance** and security features
- ✅ **100% Terraform Compatibility** with better governance

## 🚀 Quick Start

**Deploy the complete retail store application with OpenTofu!**

- **UI Service**: Java-based frontend
- **Catalog Service**: Go-based product catalog API  
- **Cart Service**: Java-based shopping cart API
- **Orders Service**: Java-based order management API
- **Checkout Service**: Node.js-based checkout orchestration API

## 📋 Prerequisites

### Required Tools

| Tool          | Version | Installation                                                                         |
| ------------- | ------- | ------------------------------------------------------------------------------------ |
| **AWS CLI**   | v2+     | [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| **OpenTofu**  | 1.6+    | [Install Guide](https://opentofu.org/docs/intro/install/)                           |
| **kubectl**   | 1.33+   | [Install Guide](https://kubernetes.io/docs/tasks/tools/)                             |
| **Docker**    | 20.0+   | [Install Guide](https://docs.docker.com/get-docker/)                                 |
| **Helm**      | 3.0+    | [Install Guide](https://helm.sh/docs/intro/install/)                                 |
| **Git**       | 2.0+    | [Install Guide](https://git-scm.com/downloads)                                       |

## 🔧 Deployment Guide

### Step 1: Repository Setup

```bash
git clone https://github.com/YOUR_USERNAME/retail-store-opentofu-gitops.git
cd retail-store-opentofu-gitops
git checkout gitops
aws configure
# Enter your AWS credentials and region (e.g., us-west-2)

# Verify access
aws sts get-caller-identity
AWS_ACCESS_KEY_ID: Your AWS access key
AWS_SECRET_ACCESS_KEY: Your AWS secret key
AWS_REGION: us-west-2
AWS_ACCOUNT_ID: Your 12-digit AWS account ID
# Option 1: Use automated setup script
./setup.sh

# Option 2: Manual deployment
cd terraform
tofu init
tofu apply -auto-approve
aws eks update-kubeconfig --region us-west-2 --name $(tofu output -raw cluster_name)
cd ..
kubectl apply -f argocd/projects/ -n argocd
kubectl apply -f argocd/applications/ -n argocd
# Get website URL
kubectl get svc -n ingress-nginx ingress-nginx-controller

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
# Open: https://localhost:8080

