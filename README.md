# GKE Management Workspace

This workspace is set up for managing Google Kubernetes Engine (GKE) clusters with comprehensive health monitoring and automation.

## 🎯 Quick Start

### Current Cluster Status
- **Cluster**: `smart-sales-test` (us-east1)
- **Project**: `smart-sales-464807`
- **Production App**: http://34.139.79.66
- **Testing App**: http://34.148.35.101

### Immediate Actions
```bash
# Connect to cluster
gcloud container clusters get-credentials smart-sales-test --region us-east1 --project smart-sales-464807

# Run health check
./scripts/daily-health-check.sh

# View real-time dashboard
./scripts/cluster-dashboard.sh --refresh=5

# Setup automated monitoring
./scripts/setup-health-monitoring.sh
```

## 🏥 Health Monitoring System

This workspace includes a comprehensive health monitoring system:

- **📊 Daily Health Checks** - Automated cluster health assessment
- **🖥 Real-time Dashboard** - Live cluster status and metrics
- **📧 Email Alerts** - Notifications for issues and status reports
- **⚙️ Easy Setup** - One-command automation configuration

**Quick Setup:**
```bash
cd scripts
./setup-health-monitoring.sh  # Interactive setup
```

**Manual Health Check:**
```bash
./scripts/daily-health-check.sh --verbose
```

**Live Dashboard:**
```bash
./scripts/cluster-dashboard.sh --refresh=30
```

## 🔧 Tools & Features

### Installed Tools
- **Google Cloud SDK** (`gcloud`) - Cluster management
- **Kubernetes CLI** (`kubectl`) - Pod and service management  
- **Helm** (optional) - Package management
- **Health Monitoring Scripts** - Automated cluster monitoring

### Key Features
- ✅ **Automated CI/CD** - GitHub Actions integration
- ✅ **Multi-environment** - Production and testing namespaces
- ✅ **Load Balancer Services** - External internet access
- ✅ **Health Monitoring** - Daily automated checks
- ✅ **Real-time Dashboard** - Live cluster visualization
- ✅ **Admin Access** - Team-based permissions
- ✅ **Documentation** - Comprehensive guides and setup

## 📁 Repository Structure

```
├── ADMIN-SETUP-GUIDE.md           # Admin user setup instructions
├── GKE-CLUSTER-GUIDE.md           # Comprehensive cluster management
├── HEALTH-MONITORING-SETUP.md     # Health monitoring guide
├── scripts/                       # Monitoring and automation scripts
│   ├── daily-health-check.sh      # Comprehensive health assessment
│   ├── cluster-dashboard.sh       # Real-time cluster dashboard
│   ├── setup-health-monitoring.sh # Automated setup and configuration
│   ├── health-check.conf          # Configuration settings
│   └── reports/                   # Generated health reports
├── gke-react-test-app/            # Production React application
└── .vscode/tasks.json             # VS Code integration tasks
```

## 🚀 VS Code Integration

Use **Ctrl+Shift+P → Tasks: Run Task** for quick access:

- `Cluster Health Check` - Run comprehensive health assessment
- `Cluster Dashboard` - Open real-time cluster dashboard  
- `Get GKE Credentials` - Connect to cluster
- `kubectl get pods` - View all pods across namespaces
- `Scale Production App` - Adjust production replica count
- `Restart Production App` - Rolling restart of production deployment

## 👥 Team Access

**Cluster Administrators:**
- rich@p-ai.net (Owner)
- jayson@p-ai.net (Container Admin) 
- zac@p-ai.net (Container Admin)

**Setup for Admins:** See [ADMIN-SETUP-GUIDE.md](ADMIN-SETUP-GUIDE.md)

## 🔄 CI/CD Integration

**Production Deployment:**
- Repository: `p-ai-smart-sales/gke-react-test-app`
- Trigger: Push to `main` branch
- Namespace: `default`
- External Access: http://34.139.79.66

**Testing Deployment:**
- Repository: `p-ai-smart-sales/React-CAF`
- Trigger: Push to `cicd-testing` branch  
- Namespace: `testing`
- External Access: http://34.148.35.101

## 📊 Monitoring & Alerts

### Automated Health Checks
- **Cluster status** and node health
- **Deployment health** and replica status
- **Service availability** and external IP status
- **HTTP connectivity** tests for all services
- **Resource usage** monitoring and alerts
- **Event analysis** for warnings and errors

### Real-time Dashboard  
- Live cluster status overview
- Deployment health visualization
- Service endpoints and external IPs
- Node resource utilization
- Recent events and alerts

### Email Notifications
Configure email alerts for:
- Daily health check reports
- Critical issue notifications
- Resource usage warnings
- Service availability alerts

## 🆘 Getting Help

1. **Health Issues**: Run `./scripts/daily-health-check.sh --verbose`
2. **Cluster Management**: See [GKE-CLUSTER-GUIDE.md](GKE-CLUSTER-GUIDE.md)
3. **Admin Setup**: See [ADMIN-SETUP-GUIDE.md](ADMIN-SETUP-GUIDE.md)
4. **Monitoring Setup**: See [HEALTH-MONITORING-SETUP.md](HEALTH-MONITORING-SETUP.md)

## 🔗 References
- [Google Cloud SDK Documentation](https://cloud.google.com/sdk/docs)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [Helm Documentation](https://helm.sh/docs/)

---

**🎉 Your GKE cluster is ready for production with comprehensive monitoring!**
- [Helm Documentation](https://helm.sh/docs/)
