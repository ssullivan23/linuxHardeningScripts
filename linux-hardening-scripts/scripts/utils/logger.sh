#!/bin/bash

# Logger utility for hardening scripts
# Provides simple timestamped logging helpers used across modules

LOG_FILE=""

log_message() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    printf "%s - %s\n" "$timestamp" "$message"
    if [ -n "${LOG_FILE}" ]; then
        printf "%s - %s\n" "$timestamp" "$message" >> "${LOG_FILE}"
    fi
}

log_start() {
    local logfile="$1"
    LOG_FILE="$logfile"
    log_message "Starting process"
}

log_end() {
    log_message "Completed process"
}

log_error() {
    log_message "ERROR: $1"
}

log_warning() {
    log_message "WARNING: $1"
}

log_success() {
    log_message "SUCCESS: $1"
}

log_info() {
    log_message "INFO: $1"
}

log_warn() {
    log_message "WARN: $1"
}

log_summary() {
    log_message "Summary of actions taken:"
    if [ -n "${LOG_FILE}" ] && [ -f "${LOG_FILE}" ]; then
        cat "${LOG_FILE}"
    fi
}