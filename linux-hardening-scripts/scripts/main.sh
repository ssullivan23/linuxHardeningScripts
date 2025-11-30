#!/bin/bash

# Main script for orchestrating Linux hardening measures based on CIS benchmarks
# Supports compartmentalized hardening with selective module execution

set -euo pipefail

# Determine script directory and repository root so paths work regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load utility functions from scripts/utils
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh"
source "$REPO_ROOT/scripts/utils/reporting.sh"

# Load module configuration
MODULES_CONFIG="$REPO_ROOT/config/modules.conf"
if [ -f "$MODULES_CONFIG" ]; then
    source "$MODULES_CONFIG"
fi

# Default values
DRY_RUN=false
LOG_FILE="$REPO_ROOT/logs/hardening_summary.log"
EXCLUDED_MODULES=""

# Function to display usage/help
usage() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║          CIS Ubuntu Linux 22.04 Hardening Tool - Main Orchestrator         ║
╚════════════════════════════════════════════════════════════════════════════╝

DESCRIPTION:
  Orchestrates Linux system hardening based on CIS Ubuntu Linux 22.04 LTS
  Benchmark v3.0.0. Supports compartmentalized module execution with dry-run
  capability and selective module inclusion/exclusion.

USAGE:
  sudo ./linux-hardening-scripts/scripts/main.sh [OPTIONS]

OPTIONS:
  -h, --help                    Display this help message and exit
  --update                      Update scripts from main repository and resync
  --update-status               Check for available updates
  --dry-run                     Preview all changes without making modifications
  --log-file <file>             Specify custom log file location
                                (default: logs/hardening_summary.log)
  --exclude-modules <list>      Comma-separated list of modules to skip
                                (no spaces between module names)

AVAILABLE MODULES:
  account-security              Password policies, sudo, SSH config security (CIS 5.1-5.4)
  bootloader-hardening          GRUB security and permissions (CIS 1.5)
  filesystem-hardening          Filesystem mounts and permissions (CIS 1.1-1.10)
  firewall-setup                Firewall and iptables configuration (CIS 3.4)
  kernel-hardening              Kernel parameters and core dumps (CIS 1.1, 4.3)
  network-hardening             Network stack hardening (CIS 3.1-3.3)
  service-hardening             Service management and removal (CIS 2.x)
  ssh-hardening                 SSH daemon configuration (CIS 5.2)
  user-security                 User/group permissions (CIS 5.1-5.5, 6.x)

QUICK START EXAMPLES:

  1. Check for updates:
     sudo ./linux-hardening-scripts/scripts/main.sh --update-status

  2. Update scripts from repository:
     sudo ./linux-hardening-scripts/scripts/main.sh --update

  3. Preview update changes (dry-run):
     sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run

  4. Preview all hardening changes (dry-run, always do this first):
     sudo ./linux-hardening-scripts/scripts/main.sh --dry-run

  5. Apply all hardening:
     sudo ./linux-hardening-scripts/scripts/main.sh

  6. Skip SSH hardening:
     sudo ./linux-hardening-scripts/scripts/main.sh --dry-run --exclude-modules ssh-hardening

  7. Skip multiple modules:
     sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules firewall-setup,network-hardening

  8. Use custom log file:
     sudo ./linux-hardening-scripts/scripts/main.sh --log-file /var/log/hardening.log

  9. Combine options:
     sudo ./linux-hardening-scripts/scripts/main.sh --dry-run --exclude-modules ssh-hardening --log-file /tmp/test.log

WORKFLOW:
  1. Run with --dry-run to preview changes
  2. Review the output carefully
  3. Run without --dry-run to apply changes
  4. Check logs directory for detailed reports

MODULE CONFIGURATION:
  To persistently enable/disable modules, edit:
    config/modules.conf

  Set module flags to "yes" or "no":
    ENABLE_SSH_HARDENING="no"      # Don't run SSH hardening
    ENABLE_FIREWALL="yes"          # Do run firewall setup

IMPORTANT NOTES:
  • Always run with --dry-run first to preview changes
  • Ensure you have console/physical access to the system
  • Test in non-production environments first
  • Backup your system before applying hardening
  • Review the CIS Benchmark documentation for complete coverage

FOR MORE INFORMATION:
  • See README.md for comprehensive documentation
  • See QUICK_REFERENCE.md for common usage patterns
  • See IMPLEMENTATION_SUMMARY.md for technical details
  • View logs in the logs/ directory for execution details

EOF
}

# Function to display short help (for errors)
usage_short() {
    echo "Usage: $0 [OPTIONS]"
    echo "Try '$0 --help' for more information."
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) 
            usage
            exit 0
            ;;
        --update)
            # Run updater script
            "$REPO_ROOT/scripts/utils/updater.sh" update
            exit $?
            ;;
        --update-status)
            # Check update status
            "$REPO_ROOT/scripts/utils/updater.sh" status
            exit $?
            ;;
        --dry-run) DRY_RUN=true ;;
        --log-file) 
            if [ -z "$2" ]; then
                echo "Error: --log-file requires an argument"
                usage_short
                exit 1
            fi
            LOG_FILE="$2"
            shift
            ;;
        --exclude-modules) 
            if [ -z "$2" ]; then
                echo "Error: --exclude-modules requires an argument"
                usage_short
                exit 1
            fi
            EXCLUDED_MODULES="$2"
            shift
            ;;
        *)
            echo "Error: Unknown option: $1"
            usage_short
            exit 1
            ;;
    esac
    shift
done

# Function to check if a module should be executed
should_run_module() {
    local module=$1
    
    # Check if module is explicitly excluded
    if [ -n "$EXCLUDED_MODULES" ]; then
        IFS=',' read -ra EXCLUDED <<< "$EXCLUDED_MODULES"
        for excluded in "${EXCLUDED[@]}"; do
            # Remove .sh extension and trim whitespace
            excluded=$(basename "$excluded" .sh | xargs)
            module_name=$(basename "$module" .sh)
            if [ "$excluded" = "$module_name" ]; then
                return 1
            fi
        done
    fi
    
    # Check if module is enabled in config
    module_name=$(basename "$module" .sh)
    case $module_name in
        account-security)
            [ "${ENABLE_ACCOUNT_SECURITY:-yes}" = "yes" ] && return 0 || return 1
            ;;
        filesystem-hardening)
            [ "${ENABLE_FILESYSTEM_HARDENING:-yes}" = "yes" ] && return 0 || return 1
            ;;
        firewall-setup)
            [ "${ENABLE_FIREWALL:-yes}" = "yes" ] && return 0 || return 1
            ;;
        kernel-hardening)
            [ "${ENABLE_KERNEL_HARDENING:-yes}" = "yes" ] && return 0 || return 1
            ;;
        service-hardening)
            [ "${ENABLE_SERVICE_HARDENING:-yes}" = "yes" ] && return 0 || return 1
            ;;
        ssh-hardening)
            [ "${ENABLE_SSH_HARDENING:-yes}" = "yes" ] && return 0 || return 1
            ;;
        user-security)
            [ "${ENABLE_AUTH_HARDENING:-yes}" = "yes" ] && return 0 || return 1
            ;;
        network-hardening)
            [ "${ENABLE_NETWORK_HARDENING:-yes}" = "yes" ] && return 0 || return 1
            ;;
        bootloader-hardening)
            [ "${ENABLE_BOOTLOADER_HARDENING:-yes}" = "yes" ] && return 0 || return 1
            ;;
        *)
            return 0  # Run unknown modules by default
            ;;
    esac
}

# Validate permissions
validate_permissions

# Ensure logs directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Start logging
log_start "$LOG_FILE"

# Display execution info
if [ "$DRY_RUN" = true ]; then
    log_message "Starting DRY RUN mode - no changes will be made"
else
    log_message "Starting hardening process - LIVE MODE"
fi

if [ -n "$EXCLUDED_MODULES" ]; then
    log_message "Excluded modules: $EXCLUDED_MODULES"
fi

# Execute hardening scripts
HARDENING_DIR="$REPO_ROOT/scripts/hardening"
TOTAL_SCRIPTS=0
EXECUTED_SCRIPTS=0
SKIPPED_SCRIPTS=0

# Discover and run each hardening script from scripts/hardening
for script in "$HARDENING_DIR"/*.sh; do
    [ -e "$script" ] || continue
    
    TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))
    script_name=$(basename "$script")
    
    if should_run_module "$script"; then
        log_message "Executing: $script_name"
        EXECUTED_SCRIPTS=$((EXECUTED_SCRIPTS + 1))
        if [ "$DRY_RUN" = true ]; then
            bash "$script" --dry-run
        else
            bash "$script"
        fi
    else
        log_message "Skipping: $script_name (module disabled)"
        SKIPPED_SCRIPTS=$((SKIPPED_SCRIPTS + 1))
    fi
done

log_message ""
log_message "Execution Summary:"
log_message "  Total scripts: $TOTAL_SCRIPTS"
log_message "  Executed: $EXECUTED_SCRIPTS"
log_message "  Skipped: $SKIPPED_SCRIPTS"

# Generate summary report
generate_summary "$LOG_FILE"

# End logging
log_end "$LOG_FILE"