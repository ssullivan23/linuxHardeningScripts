#!/bin/bash

# reporting.sh - Utility script to generate a summary report of hardening actions

# Function to generate a summary report
generate_summary() {
    local log_file="${1:-.}"
    log_message "Generating summary report..."

    # Check if the log file exists
    if [ -f "$log_file" ]; then
        log_message "Summary report generated successfully. Contents:"
        cat "$log_file"
    else
        log_message "No actions were logged. Summary report is empty."
    fi
}

# Function to generate a report with details
generate_report() {
    local log_file="${1:-.}"
    log_message "Generating detailed report..."

    if [ -f "$log_file" ]; then
        log_message "Detailed report generated. File: $log_file"
        cat "$log_file"
    else
        log_message "No log file found for report."
    fi
}