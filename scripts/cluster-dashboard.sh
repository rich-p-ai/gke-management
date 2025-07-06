#!/bin/bash

# GKE Cluster Dashboard - Quick Health Overview
# Usage: ./cluster-dashboard.sh [--refresh=5]

set -e

# Configuration
PROJECT_ID="smart-sales-464807"
CLUSTER_NAME="smart-sales-test"
REGION="us-east1"
REFRESH_INTERVAL=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --refresh=*)
            REFRESH_INTERVAL="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--refresh=SECONDS]"
            echo "  --refresh=N    Refresh every N seconds (0 for single run)"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Clear screen function
clear_screen() {
    if [[ "$REFRESH_INTERVAL" -gt 0 ]]; then
        clear
    fi
}

# Status indicator
status_indicator() {
    local status=$1
    case $status in
        "RUNNING"|"Ready"|"Active")
            echo -e "${GREEN}●${NC}"
            ;;
        "PENDING"|"Pending")
            echo -e "${YELLOW}●${NC}"
            ;;
        "ERROR"|"Failed"|"CrashLoopBackOff")
            echo -e "${RED}●${NC}"
            ;;
        *)
            echo -e "${BLUE}●${NC}"
            ;;
    esac
}

# Display header
display_header() {
    echo -e "${BOLD}${CYAN}======================================================${NC}"
    echo -e "${BOLD}${CYAN}           GKE Cluster Dashboard${NC}"
    echo -e "${BOLD}${CYAN}======================================================${NC}"
    echo -e "${BOLD}Cluster:${NC} $CLUSTER_NAME (${REGION})"
    echo -e "${BOLD}Project:${NC} $PROJECT_ID"
    echo -e "${BOLD}Updated:${NC} $(date)"
    echo ""
}

# Display cluster overview
display_cluster_overview() {
    echo -e "${BOLD}${BLUE}🏗  CLUSTER OVERVIEW${NC}"
    echo "----------------------------------------"
    
    # Cluster status
    local cluster_status=$(gcloud container clusters describe "$CLUSTER_NAME" --region "$REGION" --format="value(status)" 2>/dev/null || echo "UNKNOWN")
    echo -e "Status: $(status_indicator "$cluster_status") $cluster_status"
    
    # Node information
    local node_info=$(kubectl get nodes --no-headers 2>/dev/null || echo "0 0")
    local total_nodes=$(echo "$node_info" | wc -l | tr -d ' ')
    local ready_nodes=$(echo "$node_info" | grep " Ready " | wc -l | tr -d ' ')
    
    if [[ "$total_nodes" -gt 0 ]]; then
        echo -e "Nodes: $(status_indicator "Ready") $ready_nodes/$total_nodes ready"
    else
        echo -e "Nodes: $(status_indicator "ERROR") Unable to retrieve"
    fi
    
    # Kubernetes version
    local k8s_version=$(kubectl version --short --client 2>/dev/null | grep "Client Version" | cut -d' ' -f3 || echo "Unknown")
    echo -e "Kubectl: $k8s_version"
    
    echo ""
}

# Display deployment status
display_deployments() {
    echo -e "${BOLD}${BLUE}🚀 DEPLOYMENTS${NC}"
    echo "----------------------------------------"
    
    # Production deployment
    if kubectl get deployment react-app -n default >/dev/null 2>&1; then
        local prod_ready=$(kubectl get deployment react-app -n default -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local prod_desired=$(kubectl get deployment react-app -n default -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        echo -e "Production:  $(status_indicator "Ready") react-app ($prod_ready/$prod_desired)"
    else
        echo -e "Production:  $(status_indicator "ERROR") react-app (not found)"
    fi
    
    # Testing deployment
    if kubectl get deployment react-caf-testing -n testing >/dev/null 2>&1; then
        local test_ready=$(kubectl get deployment react-caf-testing -n testing -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local test_desired=$(kubectl get deployment react-caf-testing -n testing -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        echo -e "Testing:     $(status_indicator "Ready") react-caf-testing ($test_ready/$test_desired)"
    else
        echo -e "Testing:     $(status_indicator "PENDING") react-caf-testing (not found)"
    fi
    
    echo ""
}

# Display service status
display_services() {
    echo -e "${BOLD}${BLUE}🌐 SERVICES${NC}"
    echo "----------------------------------------"
    
    # Production service
    local prod_ip=$(kubectl get service react-app-service -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [[ -n "$prod_ip" ]]; then
        echo -e "Production:  $(status_indicator "Ready") $prod_ip"
    else
        echo -e "Production:  $(status_indicator "PENDING") No external IP"
    fi
    
    # Testing service
    if kubectl get service react-caf-testing-service -n testing >/dev/null 2>&1; then
        local test_ip=$(kubectl get service react-caf-testing-service -n testing -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [[ -n "$test_ip" ]]; then
            echo -e "Testing:     $(status_indicator "Ready") $test_ip"
        else
            echo -e "Testing:     $(status_indicator "PENDING") No external IP"
        fi
    else
        echo -e "Testing:     $(status_indicator "PENDING") Service not found"
    fi
    
    echo ""
}

# Display resource usage
display_resource_usage() {
    echo -e "${BOLD}${BLUE}📊 RESOURCE USAGE${NC}"
    echo "----------------------------------------"
    
    if kubectl top nodes >/dev/null 2>&1; then
        echo "Node Resources:"
        kubectl top nodes --no-headers | while read line; do
            local node=$(echo "$line" | awk '{print $1}')
            local cpu=$(echo "$line" | awk '{print $2}')
            local memory=$(echo "$line" | awk '{print $4}')
            echo "  $node: CPU $cpu, Memory $memory"
        done
    else
        echo "Resource metrics not available"
    fi
    
    echo ""
}

# Display recent events
display_recent_events() {
    echo -e "${BOLD}${BLUE}📋 RECENT EVENTS${NC}"
    echo "----------------------------------------"
    
    local events=$(kubectl get events --all-namespaces --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -5 || echo "")
    
    if [[ -n "$events" ]]; then
        echo "$events" | while read line; do
            local age=$(echo "$line" | awk '{print $1}')
            local type=$(echo "$line" | awk '{print $3}')
            local reason=$(echo "$line" | awk '{print $4}')
            local message=$(echo "$line" | cut -d' ' -f6-)
            
            case $type in
                "Warning")
                    echo -e "  $(status_indicator "ERROR") $age - $reason: $message" | cut -c1-80
                    ;;
                "Normal")
                    echo -e "  $(status_indicator "Ready") $age - $reason: $message" | cut -c1-80
                    ;;
                *)
                    echo -e "  $(status_indicator "PENDING") $age - $reason: $message" | cut -c1-80
                    ;;
            esac
        done
    else
        echo "No recent events"
    fi
    
    echo ""
}

# Display footer
display_footer() {
    echo -e "${BOLD}${CYAN}======================================================${NC}"
    if [[ "$REFRESH_INTERVAL" -gt 0 ]]; then
        echo -e "${BOLD}Refreshing every ${REFRESH_INTERVAL}s... Press Ctrl+C to exit${NC}"
    else
        echo -e "${BOLD}Run with --refresh=N to auto-refresh every N seconds${NC}"
    fi
    echo ""
}

# Main dashboard display
display_dashboard() {
    clear_screen
    display_header
    display_cluster_overview
    display_deployments
    display_services
    display_resource_usage
    display_recent_events
    display_footer
}

# Check if authenticated
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}Error: Not connected to cluster${NC}"
    echo "Run: gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID"
    exit 1
fi

# Main execution
if [[ "$REFRESH_INTERVAL" -gt 0 ]]; then
    # Continuous refresh mode
    while true; do
        display_dashboard
        sleep "$REFRESH_INTERVAL"
    done
else
    # Single run
    display_dashboard
fi
