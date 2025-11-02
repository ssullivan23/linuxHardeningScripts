#!/bin/bash

# Main script for orchestrating Linux hardening measures

set -euo pipefail

# Determine script directory and repository root so paths work regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load utility functions from scripts/utils
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh"
source "$REPO_ROOT/scripts/utils/reporting.sh"

# Default values
DRY_RUN=false
LOG_FILE="$REPO_ROOT/logs/hardening_summary.log"

# Function to display usage
usage() {
    echo "Usage: $0 [--dry-run] [--log-file <file>]"
    echo "  --dry-run       Perform a dry run without making changes"
    echo "  --log-file      Specify a log file for summary (default: $LOG_FILE)"
    exit 1
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --log-file) LOG_FILE="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Validate permissions
validate_permissions

# Ensure logs directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Start logging
log_start "$LOG_FILE"

# Execute hardening scripts
if $DRY_RUN; then
    log_message "Starting dry run mode..."
else
    log_message "Starting hardening process..."
fi

# Discover and run each hardening script from scripts/hardening
HARDENING_DIR="$REPO_ROOT/scripts/hardening"
for script in "$HARDENING_DIR"/*.sh; do
    [ -e "$script" ] || continue
    if $DRY_RUN; then
        bash "$script" --dry-run
    else
        bash "$script"
    fi
done

# Generate summary report
generate_summary "$LOG_FILE"

# End logging
log_end "$LOG_FILE"