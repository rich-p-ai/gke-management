#!/bin/bash

# Setup script for GKE Daily Health Check automation
# This script sets up cron jobs and necessary dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HEALTH_CHECK_SCRIPT="$SCRIPT_DIR/daily-health-check.sh"
CONFIG_FILE="$SCRIPT_DIR/health-check.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if gcloud is installed
    if ! command -v gcloud >/dev/null 2>&1; then
        log_error "gcloud CLI not found. Please install Google Cloud SDK."
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    # Check if jq is installed (for JSON parsing)
    if ! command -v jq >/dev/null 2>&1; then
        log_warning "jq not found. Installing jq for JSON parsing..."
        if command -v brew >/dev/null 2>&1; then
            brew install jq
        else
            log_error "Please install jq manually: https://stedolan.github.io/jq/"
            exit 1
        fi
    fi
    
    log_success "Prerequisites check completed"
}

# Test the health check script
test_health_check() {
    log_info "Testing health check script..."
    
    if [[ ! -x "$HEALTH_CHECK_SCRIPT" ]]; then
        log_error "Health check script not executable: $HEALTH_CHECK_SCRIPT"
        exit 1
    fi
    
    # Run a quick test
    log_info "Running test health check..."
    if "$HEALTH_CHECK_SCRIPT" --help >/dev/null 2>&1; then
        log_success "Health check script test passed"
    else
        log_error "Health check script test failed"
        exit 1
    fi
}

# Setup cron job
setup_cron_job() {
    local schedule="$1"
    local email="$2"
    
    log_info "Setting up cron job..."
    
    # Backup existing crontab
    crontab -l > /tmp/crontab_backup 2>/dev/null || touch /tmp/crontab_backup
    
    # Remove existing health check cron jobs
    grep -v "daily-health-check.sh" /tmp/crontab_backup > /tmp/new_crontab || touch /tmp/new_crontab
    
    # Add new cron job
    local cron_command="$HEALTH_CHECK_SCRIPT"
    if [[ -n "$email" ]]; then
        cron_command="$cron_command --email=$email"
    fi
    
    echo "$schedule $cron_command >> /tmp/gke-health-check.log 2>&1" >> /tmp/new_crontab
    
    # Install new crontab
    crontab /tmp/new_crontab
    
    log_success "Cron job installed: $schedule"
    log_info "Logs will be written to: /tmp/gke-health-check.log"
    
    # Cleanup
    rm -f /tmp/crontab_backup /tmp/new_crontab
}

# Create log rotation script
setup_log_rotation() {
    log_info "Setting up log rotation..."
    
    cat > "$SCRIPT_DIR/rotate-logs.sh" << 'EOF'
#!/bin/bash
# Log rotation script for GKE health check reports

REPORTS_DIR="$(dirname "$0")/reports"
DAYS_TO_KEEP=30

if [[ -d "$REPORTS_DIR" ]]; then
    find "$REPORTS_DIR" -name "health-check-*.txt" -type f -mtime +$DAYS_TO_KEEP -delete
    echo "Log rotation completed: Removed reports older than $DAYS_TO_KEEP days"
fi
EOF
    
    chmod +x "$SCRIPT_DIR/rotate-logs.sh"
    log_success "Log rotation script created"
}

# Interactive setup
interactive_setup() {
    echo "========================================="
    echo "GKE Daily Health Check Setup"
    echo "========================================="
    echo ""
    
    # Get schedule preference
    echo "Choose monitoring frequency:"
    echo "1) Daily at 9:00 AM"
    echo "2) Daily at 6:00 AM"
    echo "3) Every 12 hours"
    echo "4) Every 6 hours"
    echo "5) Custom schedule"
    echo ""
    read -p "Enter your choice (1-5): " schedule_choice
    
    case $schedule_choice in
        1) schedule="0 9 * * *" ;;
        2) schedule="0 6 * * *" ;;
        3) schedule="0 */12 * * *" ;;
        4) schedule="0 */6 * * *" ;;
        5) 
            echo ""
            echo "Enter cron schedule (format: minute hour day month weekday)"
            echo "Examples:"
            echo "  0 9 * * *    - Daily at 9:00 AM"
            echo "  */30 * * * * - Every 30 minutes"
            echo "  0 9 * * 1    - Every Monday at 9:00 AM"
            echo ""
            read -p "Enter schedule: " schedule
            ;;
        *) 
            log_error "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    read -p "Enter email address for reports (optional): " email
    
    echo ""
    read -p "Enable verbose logging? (y/n): " verbose
    
    # Setup
    check_prerequisites
    test_health_check
    setup_cron_job "$schedule" "$email"
    setup_log_rotation
    
    echo ""
    log_success "Setup completed successfully!"
    echo ""
    echo "📋 Configuration:"
    echo "   Schedule: $schedule"
    if [[ -n "$email" ]]; then
        echo "   Email: $email"
    fi
    echo "   Script: $HEALTH_CHECK_SCRIPT"
    echo "   Config: $CONFIG_FILE"
    echo ""
    echo "🔧 Management commands:"
    echo "   View cron jobs: crontab -l"
    echo "   Edit cron jobs: crontab -e"
    echo "   View logs: tail -f /tmp/gke-health-check.log"
    echo "   Manual run: $HEALTH_CHECK_SCRIPT"
    echo ""
    echo "📊 Next steps:"
    echo "   1. Customize settings in: $CONFIG_FILE"
    echo "   2. Test manual run: $HEALTH_CHECK_SCRIPT --verbose"
    echo "   3. Monitor first automated run in logs"
}

# Command line options
case "${1:-interactive}" in
    "interactive")
        interactive_setup
        ;;
    "install")
        schedule="${2:-0 9 * * *}"
        email="$3"
        check_prerequisites
        test_health_check
        setup_cron_job "$schedule" "$email"
        setup_log_rotation
        log_success "Automated setup completed"
        ;;
    "uninstall")
        log_info "Removing cron jobs..."
        crontab -l | grep -v "daily-health-check.sh" | crontab -
        log_success "Cron jobs removed"
        ;;
    "test")
        check_prerequisites
        test_health_check
        log_success "All tests passed"
        ;;
    *)
        echo "Usage: $0 [interactive|install|uninstall|test]"
        echo ""
        echo "Commands:"
        echo "  interactive  - Interactive setup (default)"
        echo "  install      - Install with default daily schedule"
        echo "  uninstall    - Remove cron jobs"
        echo "  test         - Test prerequisites and script"
        echo ""
        echo "Examples:"
        echo "  $0 install                          # Daily at 9 AM"
        echo "  $0 install '0 6 * * *'             # Daily at 6 AM"
        echo "  $0 install '0 9 * * *' user@email  # With email notifications"
        ;;
esac
