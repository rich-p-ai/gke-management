#!/bin/bash

# GKE Cluster Daily Health Check Script
# This script checks the health of the GKE cluster and all deployments
# Usage: ./daily-health-check.sh [--verbose] [--email=your@email.com]

set -e

# Configuration
PROJECT_ID="smart-sales-464807"
CLUSTER_NAME="smart-sales-test"
REGION="us-east1"
REPORT_DIR="./reports"
DATE=$(date '+%Y-%m-%d_%H-%M-%S')
REPORT_FILE="$REPORT_DIR/health-check-$DATE.txt"
VERBOSE=false
EMAIL=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        --email=*)
            EMAIL="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--verbose] [--email=your@email.com]"
            echo "  --verbose    Show detailed output"
            echo "  --email      Send report to email address"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$REPORT_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$REPORT_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$REPORT_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$REPORT_FILE"
}

# Create reports directory
mkdir -p "$REPORT_DIR"

# Initialize report
echo "========================================" > "$REPORT_FILE"
echo "GKE Cluster Health Check Report" >> "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "Cluster: $CLUSTER_NAME ($REGION)" >> "$REPORT_FILE"
echo "Project: $PROJECT_ID" >> "$REPORT_FILE"
echo "========================================" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

log_info "Starting GKE cluster health check..."

# Check if authenticated and connected to cluster
check_authentication() {
    log_info "Checking authentication and cluster connection..."
    
    # Check gcloud auth
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
        log_error "Not authenticated with Google Cloud. Run 'gcloud auth login'"
        return 1
    fi
    
    # Check cluster connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_warning "Not connected to cluster. Attempting to connect..."
        if ! gcloud container clusters get-credentials "$CLUSTER_NAME" --region "$REGION" --project "$PROJECT_ID" >/dev/null 2>&1; then
            log_error "Failed to connect to cluster"
            return 1
        fi
    fi
    
    log_success "Authentication and cluster connection verified"
    return 0
}

# Check cluster status
check_cluster_status() {
    log_info "Checking cluster status..."
    
    # Get cluster info
    local cluster_status=$(gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --format="value(status)")
    
    if [[ "$cluster_status" == "RUNNING" ]]; then
        log_success "Cluster status: RUNNING"
    else
        log_error "Cluster status: $cluster_status"
        return 1
    fi
    
    # Check nodes
    local node_count=$(kubectl get nodes --no-headers | wc -l | tr -d ' ')
    local ready_nodes=$(kubectl get nodes --no-headers | grep " Ready " | wc -l | tr -d ' ')
    
    if [[ "$node_count" -eq "$ready_nodes" ]]; then
        log_success "All nodes ready: $ready_nodes/$node_count"
    else
        log_warning "Some nodes not ready: $ready_nodes/$node_count"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Node Details:" >> "$REPORT_FILE"
        kubectl get nodes -o wide >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    return 0
}

# Check deployment health
check_deployment_health() {
    local namespace=$1
    local deployment=$2
    
    log_info "Checking deployment: $deployment (namespace: $namespace)"
    
    # Check if deployment exists
    if ! kubectl get deployment "$deployment" -n "$namespace" >/dev/null 2>&1; then
        log_error "Deployment $deployment not found in namespace $namespace"
        return 1
    fi
    
    # Get deployment status
    local desired=$(kubectl get deployment "$deployment" -n "$namespace" -o jsonpath='{.spec.replicas}')
    local ready=$(kubectl get deployment "$deployment" -n "$namespace" -o jsonpath='{.status.readyReplicas}')
    local available=$(kubectl get deployment "$deployment" -n "$namespace" -o jsonpath='{.status.availableReplicas}')
    
    # Handle null values
    ready=${ready:-0}
    available=${available:-0}
    
    if [[ "$ready" -eq "$desired" ]] && [[ "$available" -eq "$desired" ]]; then
        log_success "Deployment $deployment: $ready/$desired replicas ready"
    else
        log_warning "Deployment $deployment: $ready/$desired replicas ready, $available available"
    fi
    
    # Check pod status
    local pods_status=$(kubectl get pods -n "$namespace" -l app="$deployment" --no-headers)
    local total_pods=$(echo "$pods_status" | wc -l | tr -d ' ')
    local running_pods=$(echo "$pods_status" | grep "Running" | wc -l | tr -d ' ')
    
    if [[ "$total_pods" -eq "$running_pods" ]]; then
        log_success "All pods running: $running_pods/$total_pods"
    else
        log_warning "Pods status: $running_pods/$total_pods running"
        
        # Show problematic pods
        echo "Problematic pods:" >> "$REPORT_FILE"
        kubectl get pods -n "$namespace" -l app="$deployment" | grep -v "Running" >> "$REPORT_FILE" 2>&1 || true
        echo "" >> "$REPORT_FILE"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Pod Details for $deployment:" >> "$REPORT_FILE"
        kubectl get pods -n "$namespace" -l app="$deployment" -o wide >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    return 0
}

# Check service status
check_service_status() {
    local namespace=$1
    local service=$2
    
    log_info "Checking service: $service (namespace: $namespace)"
    
    # Check if service exists
    if ! kubectl get service "$service" -n "$namespace" >/dev/null 2>&1; then
        log_error "Service $service not found in namespace $namespace"
        return 1
    fi
    
    # Get service details
    local service_type=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.spec.type}')
    local external_ip=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    
    if [[ "$service_type" == "LoadBalancer" ]]; then
        if [[ -n "$external_ip" ]] && [[ "$external_ip" != "null" ]]; then
            log_success "Service $service: External IP $external_ip"
            
            # Test HTTP connectivity
            if curl -s --max-time 10 "http://$external_ip" >/dev/null 2>&1; then
                log_success "HTTP connectivity test passed for $external_ip"
            else
                log_warning "HTTP connectivity test failed for $external_ip"
            fi
        else
            log_warning "Service $service: LoadBalancer IP not assigned"
        fi
    else
        log_info "Service $service: Type $service_type"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Service Details for $service:" >> "$REPORT_FILE"
        kubectl describe service "$service" -n "$namespace" >> "$REPORT_FILE" 2>&1
        echo "" >> "$REPORT_FILE"
    fi
    
    return 0
}

# Check resource usage
check_resource_usage() {
    log_info "Checking resource usage..."
    
    # Node resource usage
    echo "Node Resource Usage:" >> "$REPORT_FILE"
    if kubectl top nodes >/dev/null 2>&1; then
        kubectl top nodes >> "$REPORT_FILE" 2>&1
    else
        echo "Metrics server not available" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Pod resource usage
    echo "Pod Resource Usage (Top 10):" >> "$REPORT_FILE"
    if kubectl top pods --all-namespaces >/dev/null 2>&1; then
        kubectl top pods --all-namespaces --sort-by=cpu | head -11 >> "$REPORT_FILE" 2>&1
    else
        echo "Metrics server not available" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    # Check for resource-constrained pods
    log_info "Checking for resource-constrained pods..."
    local constrained_pods=$(kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.status.containerStatuses[]?.state.waiting?.reason == "CrashLoopBackOff" or .status.containerStatuses[]?.state.waiting?.reason == "ImagePullBackOff" or .status.phase == "Pending") | "\(.metadata.namespace)/\(.metadata.name)"' 2>/dev/null || true)
    
    if [[ -n "$constrained_pods" ]]; then
        log_warning "Found resource-constrained pods:"
        echo "$constrained_pods" >> "$REPORT_FILE"
    else
        log_success "No resource-constrained pods found"
    fi
}

# Check recent events
check_recent_events() {
    log_info "Checking recent cluster events..."
    
    echo "Recent Events (Last 2 hours):" >> "$REPORT_FILE"
    kubectl get events --all-namespaces --sort-by='.lastTimestamp' | awk 'NR==1 || $1 ~ /^[0-9]+[smh]$/ {print}' | tail -20 >> "$REPORT_FILE" 2>&1 || true
    echo "" >> "$REPORT_FILE"
    
    # Check for warning/error events
    local warning_events=$(kubectl get events --all-namespaces --field-selector type=Warning --sort-by='.lastTimestamp' | tail -10)
    
    if [[ -n "$warning_events" ]] && [[ "$warning_events" != *"No resources found"* ]]; then
        log_warning "Recent warning events found"
        echo "Warning Events:" >> "$REPORT_FILE"
        echo "$warning_events" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    else
        log_success "No recent warning events"
    fi
}

# Generate summary
generate_summary() {
    log_info "Generating health check summary..."
    
    echo "" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    echo "HEALTH CHECK SUMMARY" >> "$REPORT_FILE"
    echo "========================================" >> "$REPORT_FILE"
    
    # Count issues from report
    local errors=$(grep -c "\[ERROR\]" "$REPORT_FILE" 2>/dev/null | tr -d '\n' || echo "0")
    local warnings=$(grep -c "\[WARNING\]" "$REPORT_FILE" 2>/dev/null | tr -d '\n' || echo "0")
    local successes=$(grep -c "\[SUCCESS\]" "$REPORT_FILE" 2>/dev/null | tr -d '\n' || echo "0")
    
    # Ensure we have numeric values
    errors=${errors:-0}
    warnings=${warnings:-0}
    successes=${successes:-0}
    
    echo "Errors: $errors" >> "$REPORT_FILE"
    echo "Warnings: $warnings" >> "$REPORT_FILE"
    echo "Successes: $successes" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    if [[ "$errors" -eq 0 ]] && [[ "$warnings" -eq 0 ]]; then
        echo "OVERALL STATUS: HEALTHY ✅" >> "$REPORT_FILE"
        log_success "Cluster health check completed - All systems healthy"
    elif [[ "$errors" -eq 0 ]]; then
        echo "OVERALL STATUS: MOSTLY HEALTHY ⚠️" >> "$REPORT_FILE"
        log_warning "Cluster health check completed - Minor issues detected"
    else
        echo "OVERALL STATUS: ISSUES DETECTED ❌" >> "$REPORT_FILE"
        log_error "Cluster health check completed - Critical issues detected"
    fi
    
    echo "Report saved to: $REPORT_FILE" >> "$REPORT_FILE"
}

# Send email report (if email provided)
send_email_report() {
    if [[ -n "$EMAIL" ]]; then
        log_info "Sending report to $EMAIL..."
        
        # Simple mail command (requires mail to be configured)
        if command -v mail >/dev/null 2>&1; then
            mail -s "GKE Cluster Health Report - $(date '+%Y-%m-%d')" "$EMAIL" < "$REPORT_FILE"
            log_success "Report sent to $EMAIL"
        else
            log_warning "Mail command not available. Install and configure mail to send reports."
        fi
    fi
}

# Main execution
main() {
    # Check prerequisites
    if ! check_authentication; then
        exit 1
    fi
    
    # Run health checks
    check_cluster_status
    
    # Check production deployment
    check_deployment_health "default" "react-app"
    check_service_status "default" "react-app-service"
    
    # Check testing deployment (if exists)
    if kubectl get namespace testing >/dev/null 2>&1; then
        check_deployment_health "testing" "react-caf-testing"
        check_service_status "testing" "react-caf-testing-service"
    else
        log_info "Testing namespace not found - skipping testing environment checks"
    fi
    
    # Resource and event checks
    check_resource_usage
    check_recent_events
    
    # Generate summary
    generate_summary
    
    # Send email if requested
    send_email_report
    
    echo ""
    log_info "Health check complete. Report saved to: $REPORT_FILE"
    
    # Display report location
    echo ""
    echo "📊 View the full report:"
    echo "   cat $REPORT_FILE"
    echo ""
    echo "🔄 To run with verbose output:"
    echo "   $0 --verbose"
    echo ""
    echo "📧 To email the report:"
    echo "   $0 --email=your@email.com"
}

# Run main function
main "$@"
