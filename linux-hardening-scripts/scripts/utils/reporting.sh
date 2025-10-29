#!/bin/bash

# reporting.sh - Utility script to generate a summary report of hardening actions

LOG_FILE="hardening_summary.log"

# Function to log messages to the console and to the log file
log_message() {
    local message="$1"
    echo "$message"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Function to generate a summary report
generate_report() {
    log_message "Generating summary report..."

    # Check if the log file exists
    if [[ -f "$LOG_FILE" ]]; then
        log_message "Summary report generated successfully. Contents:"
        cat "$LOG_FILE"
    else
        log_message "No actions were logged. Summary report is empty."
    fi
}

# Main execution
if [[ "$1" == "--dry-run" ]]; then
    log_message "Dry run mode activated. No changes will be made."
fi

generate_report