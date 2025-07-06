# GKE Health Monitoring Scripts

This directory contains scripts for monitoring and maintaining your GKE cluster health.

## 📁 Scripts Overview

### 🏥 Daily Health Check (`daily-health-check.sh`)
Comprehensive health monitoring script that checks:
- Cluster status and node health
- Deployment status and pod health
- Service availability and external IPs
- Resource usage and metrics
- Recent events and warnings
- HTTP connectivity tests

**Usage:**
```bash
# Basic health check
./daily-health-check.sh

# Verbose output
./daily-health-check.sh --verbose

# Email report
./daily-health-check.sh --email=your@email.com
```

**Features:**
- ✅ Automated cluster authentication
- ✅ Comprehensive health checks
- ✅ Detailed HTML and text reports
- ✅ Email notifications
- ✅ Resource usage monitoring
- ✅ Event analysis

### 📊 Cluster Dashboard (`cluster-dashboard.sh`)
Real-time dashboard for quick cluster overview.

**Usage:**
```bash
# Single view
./cluster-dashboard.sh

# Auto-refresh every 5 seconds
./cluster-dashboard.sh --refresh=5

# Auto-refresh every 30 seconds
./cluster-dashboard.sh --refresh=30
```

**Features:**
- ✅ Real-time cluster status
- ✅ Deployment health overview
- ✅ Service status and IPs
- ✅ Resource usage summary
- ✅ Recent events
- ✅ Color-coded status indicators

### ⚙️ Setup & Automation (`setup-health-monitoring.sh`)
Interactive setup script for automating health checks.

**Usage:**
```bash
# Interactive setup
./setup-health-monitoring.sh

# Quick install (daily at 9 AM)
./setup-health-monitoring.sh install

# Install with custom schedule
./setup-health-monitoring.sh install "0 6 * * *"

# Install with email notifications
./setup-health-monitoring.sh install "0 9 * * *" your@email.com

# Remove automation
./setup-health-monitoring.sh uninstall

# Test prerequisites
./setup-health-monitoring.sh test
```

**Features:**
- ✅ Automated cron job setup
- ✅ Prerequisite checking
- ✅ Log rotation configuration
- ✅ Email notification setup
- ✅ Interactive configuration

## 📋 Configuration

### Configuration File (`health-check.conf`)
Customize monitoring settings:

```bash
# Edit configuration
nano health-check.conf

# Key settings:
PROJECT_ID="smart-sales-464807"
CLUSTER_NAME="smart-sales-test"
REGION="us-east1"
EMAIL_ENABLED=false
SLACK_ENABLED=false
CPU_THRESHOLD_PERCENT=80
MEMORY_THRESHOLD_PERCENT=80
```

## 🚀 Quick Start

### 1. Initial Setup
```bash
# Run interactive setup
./setup-health-monitoring.sh

# Or quick automated setup
./setup-health-monitoring.sh install "0 9 * * *" your@email.com
```

### 2. Manual Health Check
```bash
# Run health check now
./daily-health-check.sh --verbose

# View dashboard
./cluster-dashboard.sh
```

### 3. View Reports
```bash
# View latest report
ls -la reports/
cat reports/health-check-*.txt

# Monitor logs
tail -f /tmp/gke-health-check.log
```

## 📊 Monitoring Schedules

Common cron schedules:

| Schedule | Description |
|----------|-------------|
| `0 9 * * *` | Daily at 9:00 AM |
| `0 6 * * *` | Daily at 6:00 AM |
| `0 */12 * * *` | Every 12 hours |
| `0 */6 * * *` | Every 6 hours |
| `*/30 * * * *` | Every 30 minutes |
| `0 9 * * 1` | Every Monday at 9:00 AM |

## 📧 Email Configuration

To enable email notifications:

1. **Install mail command:**
   ```bash
   # macOS
   brew install mailutils
   
   # Configure SMTP settings in system preferences
   ```

2. **Update configuration:**
   ```bash
   # Edit health-check.conf
   EMAIL_ENABLED=true
   EMAIL_RECIPIENT="your@email.com"
   ```

3. **Test email:**
   ```bash
   ./daily-health-check.sh --email=your@email.com
   ```

## 🔧 Troubleshooting

### Common Issues

**Authentication Issues:**
```bash
# Re-authenticate
gcloud auth login
gcloud container clusters get-credentials smart-sales-test --region us-east1
```

**Permission Issues:**
```bash
# Check permissions
gcloud projects get-iam-policy smart-sales-464807
kubectl auth can-i "*" "*" --all-namespaces
```

**Script Permissions:**
```bash
# Make scripts executable
chmod +x *.sh
```

**Missing Dependencies:**
```bash
# Install jq for JSON parsing
brew install jq

# Check kubectl installation
kubectl version --client
```

### Debug Mode

Run scripts with debug output:
```bash
# Enable bash debug mode
bash -x ./daily-health-check.sh

# Verbose health check
./daily-health-check.sh --verbose
```

## 📁 File Structure

```
scripts/
├── daily-health-check.sh      # Main health check script
├── cluster-dashboard.sh       # Real-time dashboard
├── setup-health-monitoring.sh # Setup automation
├── health-check.conf          # Configuration file
├── reports/                   # Generated reports
│   ├── health-check-*.txt     # Text reports
│   └── health-check-*.html    # HTML reports (future)
└── README.md                  # This file
```

## 🔄 Integration with CI/CD

The health check scripts can be integrated with your CI/CD pipeline:

```yaml
# GitHub Actions example
- name: Health Check
  run: |
    cd scripts
    ./daily-health-check.sh --verbose
    
- name: Upload Report
  uses: actions/upload-artifact@v3
  with:
    name: health-report
    path: scripts/reports/
```

## 📈 Advanced Features

### Custom Health Checks
Add custom health checks by modifying `daily-health-check.sh`:

```bash
# Add custom function
check_custom_service() {
    # Your custom health check logic
}

# Call in main function
check_custom_service
```

### Slack Integration
Configure Slack notifications in `health-check.conf`:

```bash
SLACK_ENABLED=true
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
SLACK_CHANNEL="#devops"
```

### Metrics Export
Export metrics to monitoring systems:

```bash
# Export to Prometheus format
./daily-health-check.sh --format=prometheus > metrics.txt

# Export to JSON
./daily-health-check.sh --format=json > metrics.json
```

## 🆘 Support

For issues or questions:

1. Check the main GKE-CLUSTER-GUIDE.md
2. Review ADMIN-SETUP-GUIDE.md
3. Check script logs: `tail -f /tmp/gke-health-check.log`
4. Run test mode: `./setup-health-monitoring.sh test`

---

**Last Updated:** $(date)
**Maintained By:** DevOps Team
