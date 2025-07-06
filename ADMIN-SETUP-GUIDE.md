# GKE Cluster Admin Setup Guide

This guide is for the cluster administrators: **rich@p-ai.net**, **jayson@p-ai.net**, and **zac@p-ai.net**.

## 🎯 **Admin Access Summary**

You have been granted **full administrative access** to the GKE cluster with the following roles:
- **Container Admin** - Full GKE management capabilities
- **Container Cluster Admin** - Complete cluster administration rights

## 🔐 **Initial Setup Instructions**

### 1. Install Required Tools

```bash
# Install gcloud CLI
brew install google-cloud-sdk

# Install kubectl
brew install kubectl

# Install helm (optional, for package management)
brew install helm
```

### 2. Authenticate with Google Cloud

```bash
# Login with your Google account
gcloud auth login

# Follow the browser authentication flow
# Use your @p-ai.net email address
```

### 3. Set Default Project

```bash
# Set the project as default
gcloud config set project smart-sales-464807

# Verify your configuration
gcloud config list
```

### 4. Get Cluster Credentials

```bash
# Connect to the GKE cluster
gcloud container clusters get-credentials smart-sales-test --region us-east1 --project smart-sales-464807
```

### 5. Verify Access

```bash
# Test cluster access
kubectl get nodes
kubectl get pods --all-namespaces
kubectl get services --all-namespaces
```

## 🏗 **What You Can Do as Admin**

### Cluster Management
- **View all resources**: pods, services, deployments, nodes
- **Scale deployments**: Increase/decrease replica counts
- **Update applications**: Deploy new versions
- **Manage namespaces**: Create, delete, modify namespaces
- **Configure networking**: Services, ingress, load balancers
- **Monitor cluster health**: Logs, metrics, events

### Production Environment (default namespace)
- **Access**: `kubectl get all`
- **Application**: React app (production)
- **External Access**: `kubectl get service react-app-service`

### Testing Environment (testing namespace)
- **Access**: `kubectl get all -n testing`
- **Application**: React-CAF (testing)
- **External Access**: `kubectl get service react-caf-testing-service -n testing`

## 🚀 **Common Admin Tasks**

### Check Cluster Status
```bash
# View cluster info
kubectl cluster-info

# Check node health
kubectl get nodes -o wide

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

### Application Management
```bash
# Scale production app
kubectl scale deployment react-app --replicas=3

# Scale testing app
kubectl scale deployment react-caf-testing --replicas=2 -n testing

# Restart deployments
kubectl rollout restart deployment react-app
kubectl rollout restart deployment react-caf-testing -n testing
```

### Troubleshooting
```bash
# Check pod issues
kubectl describe pod <pod-name> -n <namespace>

# View application logs
kubectl logs -f deployment/react-app
kubectl logs -f deployment/react-caf-testing -n testing

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### External Access
```bash
# Get external IPs for applications
kubectl get services --all-namespaces -o wide

# Specifically for production
kubectl get service react-app-service

# Specifically for testing
kubectl get service react-caf-testing-service -n testing
```

## 🔧 **VS Code Integration** (Optional)

If you use VS Code, you can install the Kubernetes extension:
1. Install "Kubernetes" extension by Microsoft
2. Open Command Palette (Cmd+Shift+P)
3. Run "Kubernetes: Set Kubeconfig"
4. Select your cluster context

## 📊 **Monitoring & Dashboards**

### Google Cloud Console
- **GKE Dashboard**: [View Cluster](https://console.cloud.google.com/kubernetes/clusters?project=smart-sales-464807)
- **Workloads**: Monitor applications and pods
- **Services & Ingress**: Check external access and networking
- **Storage**: Persistent volumes and claims

### Command Line Monitoring
```bash
# Watch pods in real-time
kubectl get pods --watch

# Monitor resource usage
kubectl top pods --all-namespaces --containers

# Check cluster metrics
kubectl get --raw /metrics
```

## 🚨 **Emergency Procedures**

### Application is Down
1. **Check pods**: `kubectl get pods -n <namespace>`
2. **Check service**: `kubectl get service <service-name> -n <namespace>`
3. **Check events**: `kubectl get events -n <namespace>`
4. **Check logs**: `kubectl logs -f deployment/<deployment-name> -n <namespace>`
5. **Restart if needed**: `kubectl rollout restart deployment/<deployment-name> -n <namespace>`

### Scale for High Traffic
```bash
# Scale production app for increased load
kubectl scale deployment react-app --replicas=5

# Scale testing app
kubectl scale deployment react-caf-testing --replicas=3 -n testing
```

## 🔄 **CI/CD Integration**

The cluster has automated deployments:
- **Production**: Triggered by pushes to `main` branch in `p-ai-smart-sales/gke-react-test-app`
- **Testing**: Triggered by pushes to `cicd-testing` branch in `p-ai-smart-sales/React-CAF`

You can monitor these deployments through:
- GitHub Actions (in respective repositories)
- Kubernetes dashboard
- Command line: `kubectl rollout status deployment/<deployment-name>`

## 📋 **Best Practices**

### Security
- Always use your @p-ai.net email for authentication
- Don't share your authentication credentials
- Regularly review cluster access and permissions

### Operations
- Test changes in the testing namespace first
- Monitor resource usage to avoid overprovisioning
- Use descriptive names for any resources you create
- Document any manual changes or configurations

### Cost Management
- Monitor cluster resource usage
- Scale down non-critical workloads when not needed
- Review and clean up unused resources regularly

## 🆘 **Getting Help**

1. **Documentation**: Refer to the main GKE-CLUSTER-GUIDE.md
2. **Team Support**: Contact other cluster admins
3. **Google Cloud Support**: For infrastructure issues
4. **Kubernetes Docs**: [kubernetes.io](https://kubernetes.io/docs/)

## 📞 **Contact Information**

**Cluster Administrators:**
- rich@p-ai.net
- jayson@p-ai.net  
- zac@p-ai.net

**Project Details:**
- **Project ID**: smart-sales-464807
- **Cluster Name**: smart-sales-test
- **Region**: us-east1

---

**Welcome to the team! You now have full administrative access to the GKE cluster.** 🎉
