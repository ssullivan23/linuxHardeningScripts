#!/bin/bash

# Main script for orchestrating Linux hardening measures

# Load utility functions
source ./utils/logger.sh
source ./utils/validation.sh
source ./utils/reporting.sh

# Default values
DRY_RUN=false
LOG_FILE="logs/hardening_summary.log"

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

# Start logging
log_start "$LOG_FILE"

# Execute hardening scripts
if $DRY_RUN; then
    log_message "Starting dry run mode..."
else
    log_message "Starting hardening process..."
fi

# Call each hardening script
for script in ./hardening/*.sh; do
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