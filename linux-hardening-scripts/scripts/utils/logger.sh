#!/bin/bash

# Logger utility for hardening scripts

# Function to log messages to console and log file
log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "${timestamp} - ${message}"
    if [ -n "${LOG_FILE:-}" ]; then
        echo "${timestamp} - ${message}" >> "${LOG_FILE}"
    fi
}

# Function to log the start of a process
log_start() {
    local log_file="$1"
    LOG_FILE="$log_file"
    log_message "Starting process"
}

# Function to log the end of a process
log_end() {
    local log_file="$1"
    LOG_FILE="$log_file"
    log_message "Completed process"
}

# Function to log errors
log_error() {
    log_message "ERROR: $1"
}

# Function to log warnings
log_warning() {
    log_message "WARNING: $1"
}

# Function to log success
log_success() {
    log_message "SUCCESS: $1"
}

# Function to log info
log_info() {
    log_message "INFO: $1"
}

# Function to log a warning
log_warn() {
    log_message "WARN: $1"
}

# Function to log a summary of actions taken
log_summary() {
    log_message "Summary of actions taken:"
    if [ -n "${LOG_FILE:-}" ] && [ -f "${LOG_FILE}" ]; then
        cat "${LOG_FILE}"
    fi
}