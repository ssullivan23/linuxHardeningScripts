#!/bin/bash

# Logger utility for hardening scripts
# Provides simple timestamped logging helpers used across modules with color support
# Supports quiet mode for minimal output (only warnings, errors, and changes)

LOG_FILE=""
QUIET_MODE="${QUIET_MODE:-false}"

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
    if [ "$QUIET_MODE" != true ]; then
        log_message "Starting process" "$BLUE"
    fi
}

log_end() {
    if [ "$QUIET_MODE" != true ]; then
        log_message "Completed process" "$GREEN"
    fi
}

log_error() {
    # Errors always shown
    log_message "ERROR: $1" "$RED"
}

log_warning() {
    # Warnings always shown
    log_message "WARNING: $1" "$YELLOW"
}

log_success() {
    # Success messages (changes made) always shown
    log_message "SUCCESS: $1" "$GREEN"
}

log_info() {
    # Info messages suppressed in quiet mode
    if [ "$QUIET_MODE" != true ]; then
        log_message "INFO: $1" "$CYAN"
    else
        # Still log to file even in quiet mode
        if [ -n "${LOG_FILE}" ]; then
            local timestamp
            timestamp=$(date +"%Y-%m-%d %H:%M:%S")
            printf "%s - INFO: %s\n" "$timestamp" "$1" >> "${LOG_FILE}"
        fi
    fi
}

log_warn() {
    # Warnings always shown
    log_message "WARN: $1" "$YELLOW"
}

# Log a change (always shown, even in quiet mode)
log_change() {
    log_message "CHANGE: $1" "$GREEN"
}

# Log a planned change for dry-run (always shown)
log_planned() {
    log_message "PLANNED: $1" "$BLUE"
}

log_summary() {
    log_message "Summary of actions taken:"
    if [ -n "${LOG_FILE}" ] && [ -f "${LOG_FILE}" ]; then
        cat "${LOG_FILE}"
    fi
}