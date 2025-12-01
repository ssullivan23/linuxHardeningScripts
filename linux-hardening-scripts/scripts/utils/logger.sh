#!/bin/bash

# Logger utility for hardening scripts
# Provides simple timestamped logging helpers used across modules with color support

LOG_FILE=""

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_message() {
    local message="$1"
    local color="${2:-$NC}"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    printf "${color}%s - %s${NC}\n" "$timestamp" "$message"
    if [ -n "${LOG_FILE}" ]; then
        printf "%s - %s\n" "$timestamp" "$message" >> "${LOG_FILE}"
    fi
}

log_start() {
    local logfile="$1"
    LOG_FILE="$logfile"
    log_message "Starting process" "$BLUE"
}

log_end() {
    log_message "Completed process" "$GREEN"
}

log_error() {
    log_message "ERROR: $1" "$RED"
}

log_warning() {
    log_message "WARNING: $1" "$YELLOW"
}

log_success() {
    log_message "SUCCESS: $1" "$GREEN"
}

log_info() {
    log_message "INFO: $1" "$CYAN"
}

log_warn() {
    log_message "WARN: $1" "$YELLOW"
}

log_summary() {
    log_message "Summary of actions taken:"
    if [ -n "${LOG_FILE}" ] && [ -f "${LOG_FILE}" ]; then
        cat "${LOG_FILE}"
    fi
}