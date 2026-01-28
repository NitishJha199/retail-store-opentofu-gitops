# 🔧 Troubleshooting Guide

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with the Retail Store GitOps deployment.

## 🚨 Quick Diagnostic Commands

### Essential Health Checks

```bash
# Cluster status
kubectl cluster-info
kubectl get nodes -o wide

# Application status
kubectl get pods -n retail-store -o wide
kubectl get services -n retail-store
kubectl get ingress -n retail-store

# ArgoCD status
kubectl get applications -n argocd
kubectl get pods -n argocd

# Resource usage
kubectl top nodes
kubectl top pods -n retail-store
```

### Log Collection

```bash
# Application logs
kubectl logs -f deployment/retail-store-ui -n retail-store
kubectl logs -f deployment/retail-store-catalog -n retail-store
kubectl logs -f deployment/retail-store-cart-carts -n retail-store
kubectl logs -f deployment/retail-store-orders -n retail-store
kubectl logs -f deployment/retail-store-checkout -n retail-store

# System logs
kubectl logs -f deployment/argocd-server -n argocd
kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx
```

## 🐛 Common Issues and Solutions

### 1. Pods Stuck in Pending State

#### Symptoms
```bash
$ kubectl get pods -n retail-store
NAME                                      READY   STATUS    RESTARTS   AGE
retail-store-ui-7d7dfbcf76-xxxxx          0/1     Pending   0          5m
```

#### Diagnosis
```bash
# Check pod events
kubectl describe pod <pod-name> -n retail-store

# Check node capacity
kubectl describe nodes

# Check for taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

#### Common Causes and Solutions

**Cause 1: Node Taints**
```bash
# Check for disruption taint
kubectl describe node <node-name> | grep Taints

# Solution: Remove taint
kubectl taint node <node-name> karpenter.sh/disrupted:NoSchedule-
```

**Cause 2: Resource Constraints**
```bash
# Check resource requests vs available
kubectl describe node <node-name>

# Solution: Scale cluster or reduce resource requests
# Edit deployment resource requests
kubectl edit deployment retail-store-ui -n retail-store
```

**Cause 3: Image Pull Secrets**
```bash
# Check if image pull secret exists
kubectl get secrets -n retail-store | grep regcred

# Solution: Create or update image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=<ecr-registry> \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-west-2) \
  -n retail-store
```

### 2. Image Pull Errors

#### Symptoms
```bash
$ kubectl get pods -n retail-store
NAME                                      READY   STATUS             RESTARTS   AGE
retail-store-ui-7d7dfbcf76-xxxxx          0/1     ImagePullBackOff   0          5m
```

#### Diagnosis
```bash
# Check pod events
kubectl describe pod <pod-name> -n retail-store

# Check image exists in ECR
aws ecr list-images --repository-name retail-store-ui --region us-west-2
```

#### Solutions

**Solution 1: Rebuild and Push Images**
```bash
# Rebuild all images
./scripts/build-and-push-images.sh

# Or rebuild specific service
docker build -t $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-2.amazonaws.com/retail-store-ui:latest ./src/ui/
docker push $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-2.amazonaws.com/retail-store-ui:latest
```

**Solution 2: Update Image Tag**
```bash
# Check current image tag in deployment
kubectl get deployment retail-store-ui -n retail-store -o yaml | grep image:

# Update to correct tag
kubectl patch deployment retail-store-ui -n retail-store -p '{"spec":{"template":{"spec":{"containers":[{"name":"ui","image":"759553606952.dkr.ecr.us-west-2.amazonaws.com/retail-store-ui:latest"}]}}}}'
```

**Solution 3: Fix ECR Authentication**
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-2.amazonaws.com

# Update image pull secret
kubectl delete secret regcred -n retail-store
kubectl create secret docker-registry regcred \
  --docker-server=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-west-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-west-2) \
  -n retail-store
```

### 3. ArgoCD Sync Issues

#### Symptoms
```bash
$ kubectl get applications -n argocd
NAME                    SYNC STATUS   HEALTH STATUS
retail-store-ui         OutOfSync     Degraded
```

#### Diagnosis
```bash
# Check application details
kubectl describe application retail-store-ui -n argocd

# Check ArgoCD server logs
kubectl logs deployment/argocd-server -n argocd

# Check repository access
kubectl logs deployment/argocd-repo-server -n argocd
```

#### Solutions

**Solution 1: Force Refresh and Sync**
```bash
# Hard refresh application
kubectl patch application retail-store-ui -n argocd -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' --type merge

# Force sync
kubectl patch application retail-store-ui -n argocd -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}' --type merge
```

**Solution 2: Fix Repository URL**
```bash
# Check current repository URL
kubectl get application retail-store-ui -n argocd -o yaml | grep repoURL

# Update to correct repository
kubectl patch application retail-store-ui -n argocd -p '{"spec":{"source":{"repoURL":"https://github.com/YOUR_USERNAME/retail-store-opentofu-gitops"}}}' --type merge
```

**Solution 3: Repository Access Issues**
```bash
# Check if repository is accessible
git ls-remote https://github.com/YOUR_USERNAME/retail-store-opentofu-gitops

# For private repositories, add SSH key or token to ArgoCD
kubectl create secret generic repo-secret \
  --from-literal=type=git \
  --from-literal=url=https://github.com/YOUR_USERNAME/retail-store-opentofu-gitops \
  --from-literal=password=<github-token> \
  --from-literal=username=<github-username> \
  -n argocd
```

### 4. Load Balancer Not Accessible

#### Symptoms
```bash
$ curl http://<load-balancer-url>
curl: (7) Failed to connect to <load-balancer-url> port 80: Connection refused
```

#### Diagnosis
```bash
# Check ingress status
kubectl get ingress -n retail-store -o wide

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check service endpoints
kubectl get endpoints -n retail-store
```

#### Solutions

**Solution 1: Check Ingress Controller**
```bash
# Restart ingress controller
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx

# Check ingress controller logs
kubectl logs deployment/ingress-nginx-controller -n ingress-nginx
```

**Solution 2: Verify Service Configuration**
```bash
# Check service selectors match pod labels
kubectl get service retail-store-ui -n retail-store -o yaml
kubectl get pods -n retail-store --show-labels

# Test service connectivity
kubectl exec -it deployment/retail-store-ui -n retail-store -- curl http://retail-store-ui:80
```

**Solution 3: Check Security Groups**
```bash
# Get load balancer security group
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-ingressn`)].SecurityGroups[]' --output text

# Check security group rules
aws ec2 describe-security-groups --group-ids <security-group-id>
```

### 5. Application Health Check Failures

#### Symptoms
```bash
$ kubectl get pods -n retail-store
NAME                                      READY   STATUS    RESTARTS   AGE
retail-store-ui-7d7dfbcf76-xxxxx          0/1     Running   5          10m
```

#### Diagnosis
```bash
# Check readiness probe
kubectl describe pod <pod-name> -n retail-store

# Test health endpoint manually
kubectl exec -it <pod-name> -n retail-store -- curl http://localhost:8080/actuator/health/readiness
```

#### Solutions

**Solution 1: Adjust Health Check Configuration**
```bash
# Edit deployment to increase probe timeouts
kubectl edit deployment retail-store-ui -n retail-store

# Example configuration:
# readinessProbe:
#   httpGet:
#     path: /actuator/health/readiness
#     port: 8080
#   initialDelaySeconds: 30
#   periodSeconds: 10
#   timeoutSeconds: 5
#   failureThreshold: 3
```

**Solution 2: Check Application Logs**
```bash
# Check for application startup errors
kubectl logs <pod-name> -n retail-store

# Common issues: database connections, missing environment variables
```

### 6. Resource Exhaustion

#### Symptoms
```bash
$ kubectl top nodes
NAME                  CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
i-xxxxxxxxxxxxxxxxx   1950m        97%    3500Mi          90%
```

#### Solutions

**Solution 1: Scale Cluster**
```bash
# Karpenter will automatically scale, but you can force it
kubectl scale deployment retail-store-ui -n retail-store --replicas=0
kubectl scale deployment retail-store-ui -n retail-store --replicas=1
```

**Solution 2: Optimize Resource Requests**
```bash
# Reduce resource requests
kubectl patch deployment retail-store-ui -n retail-store -p '{"spec":{"template":{"spec":{"containers":[{"name":"ui","resources":{"requests":{"cpu":"50m","memory":"256Mi"}}}]}}}}'
```

### 7. DNS Resolution Issues

#### Symptoms
```bash
# Services can't communicate with each other
kubectl exec -it deployment/retail-store-ui -n retail-store -- nslookup retail-store-catalog
```

#### Solutions

**Solution 1: Check CoreDNS**
```bash
# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system
```

**Solution 2: Verify Service Names**
```bash
# Check service names and namespaces
kubectl get services -n retail-store

# Use fully qualified domain names
# Format: <service-name>.<namespace>.svc.cluster.local
```

## 🔍 Advanced Debugging

### Network Debugging

```bash
# Install network debugging tools
kubectl run netshoot --rm -i --tty --image nicolaka/netshoot -- /bin/bash

# Test connectivity from within cluster
nslookup retail-store-ui.retail-store.svc.cluster.local
curl http://retail-store-ui.retail-store.svc.cluster.local:80

# Test external connectivity
curl http://google.com
```

### Performance Debugging

```bash
# Check resource usage over time
kubectl top pods -n retail-store --sort-by=cpu
kubectl top pods -n retail-store --sort-by=memory

# Get detailed resource metrics
kubectl describe node <node-name>

# Check for resource limits
kubectl get limitrange -n retail-store
kubectl get resourcequota -n retail-store
```

### Storage Debugging

```bash
# Check persistent volumes
kubectl get pv
kubectl get pvc -n retail-store

# Check storage classes
kubectl get storageclass

# Check volume mounts
kubectl describe pod <pod-name> -n retail-store
```

## 🛠️ Diagnostic Scripts

### Health Check Script

```bash
#!/bin/bash
# health-check.sh

echo "=== Cluster Health Check ==="
kubectl get nodes
echo ""

echo "=== Namespace Status ==="
kubectl get namespaces
echo ""

echo "=== Pod Status ==="
kubectl get pods -n retail-store -o wide
echo ""

echo "=== Service Status ==="
kubectl get services -n retail-store
echo ""

echo "=== Ingress Status ==="
kubectl get ingress -n retail-store
echo ""

echo "=== ArgoCD Applications ==="
kubectl get applications -n argocd
echo ""

echo "=== Resource Usage ==="
kubectl top nodes 2>/dev/null || echo "Metrics server not available"
kubectl top pods -n retail-store 2>/dev/null || echo "Metrics server not available"
echo ""

echo "=== Recent Events ==="
kubectl get events -n retail-store --sort-by='.lastTimestamp' | tail -10
```

### Log Collection Script

```bash
#!/bin/bash
# collect-logs.sh

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_DIR="logs-$TIMESTAMP"
mkdir -p $LOG_DIR

echo "Collecting logs to $LOG_DIR..."

# Cluster info
kubectl cluster-info > $LOG_DIR/cluster-info.txt
kubectl get nodes -o wide > $LOG_DIR/nodes.txt

# Application logs
for deployment in retail-store-ui retail-store-catalog retail-store-cart-carts retail-store-orders retail-store-checkout; do
  kubectl logs deployment/$deployment -n retail-store > $LOG_DIR/$deployment.log 2>&1
done

# System logs
kubectl logs deployment/argocd-server -n argocd > $LOG_DIR/argocd-server.log 2>&1
kubectl logs deployment/ingress-nginx-controller -n ingress-nginx > $LOG_DIR/ingress-nginx.log 2>&1

# Resource status
kubectl get all -n retail-store -o wide > $LOG_DIR/resources.txt
kubectl describe pods -n retail-store > $LOG_DIR/pod-descriptions.txt

# Events
kubectl get events -n retail-store --sort-by='.lastTimestamp' > $LOG_DIR/events.txt

echo "Logs collected in $LOG_DIR/"
```

## 📞 Getting Help

### Before Seeking Help

1. **Check this troubleshooting guide** for common issues
2. **Collect relevant logs** using the diagnostic scripts
3. **Document the exact error messages** and steps to reproduce
4. **Check the GitHub issues** for similar problems

### Information to Include

When reporting issues, include:

- **Environment details**: AWS region, cluster version, node types
- **Error messages**: Exact error text and stack traces
- **Steps to reproduce**: What you were doing when the issue occurred
- **Logs**: Relevant application and system logs
- **Configuration**: Any custom configurations or modifications

### Community Resources

- **GitHub Issues**: [Report bugs and feature requests](https://github.com/NitishJha199/retail-store-opentofu-gitops/issues)
- **Discussions**: [Ask questions and share experiences](https://github.com/NitishJha199/retail-store-opentofu-gitops/discussions)
- **Kubernetes Community**: [Kubernetes Slack](https://slack.k8s.io/)
- **ArgoCD Community**: [ArgoCD Slack](https://argoproj.github.io/community/join-slack/)

## 🔄 Recovery Procedures

### Complete Environment Recovery

```bash
# 1. Backup current state
kubectl get all -n retail-store -o yaml > backup-retail-store.yaml
kubectl get applications -n argocd -o yaml > backup-argocd-apps.yaml

# 2. Destroy and recreate infrastructure
cd open-tofu
tofu destroy -auto-approve
tofu apply -auto-approve

# 3. Rebuild and push images
./scripts/build-and-push-images.sh

# 4. Wait for ArgoCD to sync applications
kubectl wait --for=condition=Synced application/retail-store-ui -n argocd --timeout=300s
```

### Application-Only Recovery

```bash
# 1. Delete problematic applications
kubectl delete -f argocd/applications/

# 2. Recreate applications
kubectl apply -f argocd/applications/

# 3. Force sync
for app in retail-store-ui retail-store-catalog retail-store-cart retail-store-orders retail-store-checkout; do
  kubectl patch application $app -n argocd -p '{"operation":{"sync":{"syncStrategy":{"force":true}}}}' --type merge
done
```

Remember: Most issues can be resolved by understanding the root cause and applying the appropriate solution. Take time to diagnose properly before attempting fixes. 🔧