# GKE Cluster Management Guide

This guide covers everything you need to know about accessing, maintaining, and managing your Google Kubernetes Engine (GKE) cluster.

## 📋 Cluster Information

- **Cluster Name**: `smart-sales-test`
- **Region**: `us-east1`
- **Project ID**: `smart-sales-464807`
- **Node Pool**: `default-pool` (3 nodes minimum)
- **Machine Type**: Standard GKE configuration
- **Kubernetes Version**: Auto-updated by Google

## 🔐 Authentication & Access

### Initial Setup

1. **Install Required Tools**:
   ```bash
   # Install gcloud CLI (if not installed)
   brew install google-cloud-sdk
   
   # Install kubectl (if not installed)
   brew install kubectl
   
   # Install helm (if not installed)
   brew install helm
   ```

2. **Authenticate with Google Cloud**:
   ```bash
   gcloud auth login
   ```

3. **Set Default Project**:
   ```bash
   gcloud config set project smart-sales-464807
   ```

4. **Get Cluster Credentials**:
   ```bash
   gcloud container clusters get-credentials smart-sales-test --region us-east1 --project smart-sales-464807
   ```

### Daily Access

```bash
# Quick cluster access (if already authenticated)
gcloud container clusters get-credentials smart-sales-test --region us-east1

# Verify connection
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🏗 Cluster Architecture

### Namespaces
- `default` - Production applications
- `testing` - Testing environment (isolated)
- `kube-system` - Kubernetes system components
- `gke-system` - GKE-specific components

### Current Deployments
- **react-app** (default namespace) - Production React app
- **react-caf-testing** (testing namespace) - Testing environment

### Services
- **react-app-service** - Production LoadBalancer
- **react-caf-testing-service** - Testing LoadBalancer

## 🔧 Common Operations

### Viewing Resources

```bash
# Get all pods
kubectl get pods --all-namespaces

# Get services and external IPs
kubectl get services --all-namespaces

# Get deployments
kubectl get deployments --all-namespaces

# Describe a specific pod
kubectl describe pod <pod-name> -n <namespace>

# View logs
kubectl logs -f deployment/<deployment-name> -n <namespace>
```

### Managing Deployments

```bash
# Scale a deployment
kubectl scale deployment <deployment-name> --replicas=3 -n <namespace>

# Restart a deployment
kubectl rollout restart deployment/<deployment-name> -n <namespace>

# Check rollout status
kubectl rollout status deployment/<deployment-name> -n <namespace>

# Update image
kubectl set image deployment/<deployment-name> <container-name>=<new-image> -n <namespace>
```

### Troubleshooting

```bash
# Check pod status and events
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>

# Check service endpoints
kubectl get endpoints -n <namespace>

# View cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Check node status
kubectl get nodes -o wide
kubectl describe node <node-name>
```

## 🚀 Application Deployment

### Production Deployment (default namespace)
- **Trigger**: Push to `main` branch in `p-ai-smart-sales/gke-react-test-app`
- **Registry**: `us-central1-docker.pkg.dev/smart-sales-464807/gke-react-test-app`
- **Access**: Check external IP: `kubectl get service react-app-service`

### Testing Deployment (testing namespace)
- **Trigger**: Push to `cicd-testing` branch in `p-ai-smart-sales/React-CAF`
- **Registry**: `us-central1-docker.pkg.dev/smart-sales-464807/react-caf`
- **Access**: Check external IP: `kubectl get service react-caf-testing-service -n testing`

## 🛡 Security & Permissions

### Cluster Administrators
- **rich@p-ai.net** - Owner, Container Admin, Container Cluster Admin
- **jayson@p-ai.net** - Container Admin, Container Cluster Admin  
- **zac@p-ai.net** - Container Admin, Container Cluster Admin

### Service Accounts
- **github-actions@smart-sales-464807.iam.gserviceaccount.com**
  - Roles: Container Admin, Storage Admin, Artifact Registry Admin
  - Used for: CI/CD deployments

### Admin User Access
Each admin user can access the cluster by:
1. Authenticating with their Google account: `gcloud auth login`
2. Setting the project: `gcloud config set project smart-sales-464807`
3. Getting cluster credentials: `gcloud container clusters get-credentials smart-sales-test --region us-east1`

### IAM Best Practices
- Use least privilege principle
- Regular audit of service account permissions
- Rotate service account keys periodically

### Network Security
- LoadBalancer services expose applications to the internet
- Consider using Ingress controllers for advanced routing
- Network policies can be implemented for pod-to-pod communication

## 📊 Monitoring & Logging

### Google Cloud Console
- **GKE Dashboard**: [View Cluster](https://console.cloud.google.com/kubernetes/clusters?project=smart-sales-464807)
- **Workloads**: Monitor pod health and resource usage
- **Services**: Check LoadBalancer status and external IPs

### Command Line Monitoring
```bash
# Check cluster status
kubectl cluster-info

# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# View cluster metrics
kubectl get --raw /metrics

# Check cluster autoscaler logs
kubectl logs -n kube-system deployment/cluster-autoscaler
```

### Application Logs
```bash
# Follow logs for a deployment
kubectl logs -f deployment/react-app

# Get logs from specific time
kubectl logs deployment/react-app --since=1h

# Get logs from all containers in a namespace
kubectl logs -n testing --all-containers=true
```

## 💰 Cost Management

### Resource Optimization
```bash
# Check resource requests and limits
kubectl describe pods --all-namespaces | grep -A 5 -B 5 "Requests\|Limits"

# Monitor node utilization
kubectl top nodes
```

### Cost-Saving Practices
- **Right-size your nodes**: Monitor CPU/memory usage
- **Use preemptible instances**: For non-critical workloads
- **Implement horizontal pod autoscaling**: Scale based on demand
- **Set resource requests and limits**: Prevent resource waste
- **Use node auto-scaling**: Scale cluster based on demand

## 🔄 Maintenance & Updates

### Regular Maintenance Tasks

1. **Weekly**:
   ```bash
   # Check cluster health
   kubectl get nodes
   kubectl get pods --all-namespaces
   
   # Review resource usage
   kubectl top nodes
   kubectl top pods --all-namespaces
   ```

2. **Monthly**:
   ```bash
   # Check for available cluster updates
   gcloud container clusters list --format="table(name,status,currentMasterVersion,currentNodeVersion)"
   
   # Review and clean up unused images
   gcloud artifacts docker images list us-central1-docker.pkg.dev/smart-sales-464807/gke-react-test-app
   ```

3. **Quarterly**:
   - Review and rotate service account keys
   - Audit IAM permissions
   - Review cost reports
   - Update node pool configurations if needed

### Updating the Cluster

```bash
# Check available versions
gcloud container get-server-config --region=us-east1

# Update master (Google manages this automatically in most cases)
gcloud container clusters upgrade smart-sales-test --region=us-east1

# Update node pool
gcloud container clusters upgrade smart-sales-test --node-pool=default-pool --region=us-east1
```

## 🚨 Emergency Procedures

### Application Down
1. Check pod status: `kubectl get pods -n <namespace>`
2. Check service status: `kubectl get service <service-name> -n <namespace>`
3. Check recent events: `kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp`
4. Check logs: `kubectl logs -f deployment/<deployment-name> -n <namespace>`
5. Restart if needed: `kubectl rollout restart deployment/<deployment-name> -n <namespace>`

### Cluster Issues
1. Check node status: `kubectl get nodes`
2. Check cluster events: `kubectl get events --all-namespaces`
3. Contact Google Cloud Support if needed
4. Escalate to team leads

### Data Backup
- **Container Images**: Stored in Artifact Registry (automatically replicated)
- **Application Data**: Ensure your applications handle data persistence appropriately
- **Kubernetes Configs**: All configs are in Git repositories

## 📚 Useful Commands Reference

### Quick Actions
```bash
# Get external IPs for all services
kubectl get services --all-namespaces -o wide

# Get all resources in a namespace
kubectl get all -n <namespace>

# Port forward to access a pod locally
kubectl port-forward pod/<pod-name> 8080:80 -n <namespace>

# Execute commands in a pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Copy files to/from pods
kubectl cp <local-file> <namespace>/<pod-name>:<pod-path>
```

### VS Code Tasks
Use the configured VS Code tasks for common operations:
- **gcloud auth login**: Authenticate with Google Cloud
- **Get GKE Credentials**: Connect to the cluster
- **kubectl get pods**: View all pods

## 🔗 Useful Links

- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [GCP Console - Kubernetes Engine](https://console.cloud.google.com/kubernetes/clusters?project=smart-sales-464807)
- [Artifact Registry](https://console.cloud.google.com/artifacts/browse/smart-sales-464807?project=smart-sales-464807)

## 🆘 Support & Escalation

1. **Documentation**: Check this guide and official GKE docs
2. **Team**: Reach out to team leads for application-specific issues
3. **Google Cloud Support**: For infrastructure issues
4. **Emergency**: Follow your organization's incident response procedures

---

**Last Updated**: July 2025
**Maintained By**: DevOps Team
