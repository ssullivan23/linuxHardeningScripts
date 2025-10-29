#!/bin/bash

# Logger utility for hardening scripts

LOG_FILE="../logs/hardening_summary.log"

# Function to log messages to console and log file
log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${timestamp} - ${message}"
    echo "${timestamp} - ${message}" >> "${LOG_FILE}"
}

# Function to log the start of a process
log_start() {
    log_message "Starting process: $1"
}

# Function to log the end of a process
log_end() {
    log_message "Completed process: $1"
}

# Function to log errors
log_error() {
    log_message "ERROR: $1"
}

# Function to log warnings
log_warning() {
    log_message "WARNING: $1"
}

# Function to log info
log_info() {
    log_message "INFO: $1"
}

# Function to log a summary of actions taken
log_summary() {
    log_message "Summary of actions taken:"
    cat "${LOG_FILE}"
}

# Export functions for use in other scripts
export -f log_message
export -f log_start
export -f log_end
export -f log_error
export -f log_warning
export -f log_info
export -f log_summary