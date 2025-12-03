#!/bin/bash

# Main script for orchestrating Linux hardening measures based on CIS benchmarks
# Supports compartmentalized hardening with selective module execution

set -euo pipefail

# Determine script directory and repository root so paths work regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to ensure all scripts have execute permissions
ensure_execute_permissions() {
    # Silently fix permissions on all scripts
    chmod +x "$SCRIPT_DIR/main.sh" 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/utils"/*.sh 2>/dev/null || true
    chmod +x "$SCRIPT_DIR/hardening"/*.sh 2>/dev/null || true
    chmod +x "$REPO_ROOT/tests"/*.sh 2>/dev/null || true
}

# Ensure permissions are set before loading utilities
ensure_execute_permissions

# Load utility functions from scripts/utils
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh"
source "$REPO_ROOT/scripts/utils/reporting.sh"

# Load module configuration
MODULES_CONFIG="$REPO_ROOT/config/modules.conf"
if [ -f "$MODULES_CONFIG" ]; then
    source "$MODULES_CONFIG"
fi

# Set default values for any missing module variables (all enabled by default)
ENABLE_ACCOUNT_SECURITY="${ENABLE_ACCOUNT_SECURITY:-yes}"
ENABLE_AUDIT_HARDENING="${ENABLE_AUDIT_HARDENING:-yes}"
ENABLE_BOOTLOADER_HARDENING="${ENABLE_BOOTLOADER_HARDENING:-yes}"
ENABLE_FILESYSTEM_HARDENING="${ENABLE_FILESYSTEM_HARDENING:-yes}"
ENABLE_FIREWALL="${ENABLE_FIREWALL:-yes}"
ENABLE_KERNEL_HARDENING="${ENABLE_KERNEL_HARDENING:-yes}"
ENABLE_NETWORK_HARDENING="${ENABLE_NETWORK_HARDENING:-yes}"
ENABLE_PERMISSIONS_HARDENING="${ENABLE_PERMISSIONS_HARDENING:-yes}"
ENABLE_SERVICE_HARDENING="${ENABLE_SERVICE_HARDENING:-yes}"
ENABLE_SSH_HARDENING="${ENABLE_SSH_HARDENING:-yes}"
ENABLE_AUTH_HARDENING="${ENABLE_AUTH_HARDENING:-yes}"

# Default values
DRY_RUN=false
QUIET_MODE=false
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
  sudo ./linux-hardening-scripts/scripts/main.sh [COMMAND]

═══════════════════════════════════════════════════════════════════════════════
                              HARDENING OPTIONS
═══════════════════════════════════════════════════════════════════════════════

  -h, --help                    Display this help message and exit
  --update                      Update scripts from main repository and resync
  --update-status               Check for available updates
  --dry-run                     Preview all changes without making modifications
  --quiet, -q                   Minimal output - only show warnings and changes
                                (suppresses informational messages for cleaner output)
  --log-file <file>             Specify custom log file location
                                (default: logs/hardening_summary.log)
  --exclude-modules <list>      Comma-separated list of modules to skip
                                (no spaces between module names)

═══════════════════════════════════════════════════════════════════════════════
                          SYSADMIN UTILITY COMMANDS
═══════════════════════════════════════════════════════════════════════════════

  --list-sudo-users             List all users with sudo/admin privileges
  --list-sudo-users --verbose   Show detailed user information
  --list-sudo-users --user <name>   Check a specific user's privileges
  --list-sudo-users --format <fmt>  Output as: text, json, or csv
  --list-sudo-users --output <file> Export results to file

  --remove-hacking-tools        Remove penetration testing tools & games
  --remove-hacking-tools --dry-run  Preview what would be removed
  --remove-hacking-tools --aggressive  Also remove dev tools (gcc, git, etc.)

═══════════════════════════════════════════════════════════════════════════════
                            AVAILABLE MODULES
═══════════════════════════════════════════════════════════════════════════════

  account-security              Password policies, sudo, SSH config security (CIS 5.1-5.5, 6.1-6.2)
  audit-hardening               Audit & logging configuration (CIS 4.1-4.4, 5.2-5.3)
  bootloader-hardening          GRUB security and permissions (CIS 1.5)
  filesystem-hardening          Filesystem mounts and permissions (CIS 1.1-1.10)
  firewall-setup                Firewall configuration (CIS 3.4-3.5)
  kernel-hardening              Kernel parameters & sysctl hardening (CIS 1.1, 1.3, 3.1-3.5)
  network-hardening             Network stack hardening (CIS 3.1-3.4)
  permissions-hardening         File/directory permissions security (CIS 6.1-6.2)
  service-hardening             Service management and removal (CIS 2.x)
  ssh-hardening                 SSH daemon configuration (CIS 5.2)
  user-security                 User/group permissions (CIS 5.1-5.5, 6.x)

═══════════════════════════════════════════════════════════════════════════════
                              QUICK START EXAMPLES
═══════════════════════════════════════════════════════════════════════════════

  HARDENING:

    # Preview all hardening changes (dry-run, always do this first)
    sudo ./main.sh --dry-run

    # Apply all hardening
    sudo ./main.sh

    # Apply hardening with minimal output (only warnings & changes)
    sudo ./main.sh --quiet

    # Combine quiet mode with dry-run for clean preview
    sudo ./main.sh --dry-run --quiet

    # Skip SSH hardening
    sudo ./main.sh --dry-run --exclude-modules ssh-hardening

    # Skip multiple modules
    sudo ./main.sh --exclude-modules firewall-setup,network-hardening

  UPDATES:

    # Check for updates
    sudo ./main.sh --update-status

    # Update scripts from repository
    sudo ./main.sh --update

  SYSADMIN UTILITIES:

    # List all users with admin privileges
    sudo ./main.sh --list-sudo-users

    # Detailed user audit with verbose output
    sudo ./main.sh --list-sudo-users --verbose

    # Check if specific user has sudo
    sudo ./main.sh --list-sudo-users --user john

    # Export user audit to CSV
    sudo ./main.sh --list-sudo-users --format csv --output /tmp/users.csv

    # Preview removal of hacking tools
    sudo ./main.sh --remove-hacking-tools --dry-run

    # Remove hacking tools (games, pentest tools)
    sudo ./main.sh --remove-hacking-tools

    # Aggressive removal (includes compilers, debuggers)
    sudo ./main.sh --remove-hacking-tools --aggressive

═══════════════════════════════════════════════════════════════════════════════
                              WORKFLOW
═══════════════════════════════════════════════════════════════════════════════

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

# Sysadmin utilities directory
SYSADMIN_UTILS_DIR="$REPO_ROOT/scripts/sysadmin-utils"

# Parse command-line arguments
# First, check for utility commands that need to pass through all remaining args
case "${1:-}" in
    --list-sudo-users)
        shift
        # Pass all remaining arguments to the utility script
        exec "$SYSADMIN_UTILS_DIR/list-users-with-sudo.sh" "$@"
        ;;
    --remove-hacking-tools)
        shift
        # Pass all remaining arguments to the utility script
        exec "$SYSADMIN_UTILS_DIR/remove-hacking-tools.sh" "$@"
        ;;
esac

# Standard argument parsing for hardening options
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
        --quiet|-q) QUIET_MODE=true ;;
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
        audit-hardening)
            [ "${ENABLE_AUDIT_HARDENING:-yes}" = "yes" ] && return 0 || return 1
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
        permissions-hardening)
            [ "${ENABLE_PERMISSIONS_HARDENING:-yes}" = "yes" ] && return 0 || return 1
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
if [ "$QUIET_MODE" != true ]; then
    if [ "$DRY_RUN" = true ]; then
        log_message "Starting DRY RUN mode - no changes will be made"
    else
        log_message "Starting hardening process - LIVE MODE"
    fi
    
    if [ -n "$EXCLUDED_MODULES" ]; then
        log_message "Excluded modules: $EXCLUDED_MODULES"
    fi
else
    echo "Running in quiet mode - showing only warnings and changes..."
    echo ""
fi

# Execute hardening scripts
HARDENING_DIR="$REPO_ROOT/scripts/hardening"
TOTAL_SCRIPTS=0
EXECUTED_SCRIPTS=0
SKIPPED_SCRIPTS=0

# Discover and run each hardening script from scripts/hardening
for script in "$HARDENING_DIR"/*.sh; do
    [ -e "$script" ] || continue
    
    script_name=$(basename "$script")
    
    TOTAL_SCRIPTS=$((TOTAL_SCRIPTS + 1))
    
    if should_run_module "$script"; then
        if [ "$QUIET_MODE" != true ]; then
            log_message "Executing: $script_name"
        fi
        EXECUTED_SCRIPTS=$((EXECUTED_SCRIPTS + 1))
        
        # Build command arguments
        SCRIPT_ARGS=""
        if [ "$DRY_RUN" = true ]; then
            SCRIPT_ARGS="--dry-run"
        fi
        if [ "$QUIET_MODE" = true ]; then
            SCRIPT_ARGS="$SCRIPT_ARGS --quiet"
        fi
        
        bash "$script" $SCRIPT_ARGS 2>&1 || true
    else
        if [ "$QUIET_MODE" != true ]; then
            log_message "Skipping: $script_name (module disabled)"
        fi
        SKIPPED_SCRIPTS=$((SKIPPED_SCRIPTS + 1))
    fi
done

if [ "$QUIET_MODE" != true ]; then
    log_message ""
    log_message "Execution Summary:"
    log_message "  Total scripts: $TOTAL_SCRIPTS"
    log_message "  Executed: $EXECUTED_SCRIPTS"
    log_message "  Skipped: $SKIPPED_SCRIPTS"
else
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  Completed: $EXECUTED_SCRIPTS modules executed, $SKIPPED_SCRIPTS skipped"
    echo "  Full details logged to: $LOG_FILE"
    echo "═══════════════════════════════════════════════════════════════════════"
fi

# Generate summary report
generate_summary "$LOG_FILE"

# End logging
log_end "$LOG_FILE"