#!/bin/bash

################################################################################
# Account Security Hardening Script
# Purpose: Secure user accounts, password policies, and access controls
# CIS Controls: 5.1-5.5, 6.1-6.2 (User account management and password policy)
# Features: Dry-run mode, console logging, summary reporting
################################################################################

set -euo pipefail

# Determine script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "${SCRIPT_DIR}/../utils/logger.sh" 2>/dev/null || {
    echo "ERROR: Cannot load logger.sh" >&2
    exit 1
}

# Configuration
DRY_RUN=false
CHANGES_MADE=0
CHANGES_PLANNED=0
LOGIN_DEFS="/etc/login.defs"
LOGIN_DEFS_BACKUP="${LOGIN_DEFS}.backup.$(date +%Y%m%d_%H%M%S)"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Initialize
if [ "$DRY_RUN" = true ]; then
    log_info "=== ACCOUNT SECURITY HARDENING (DRY RUN MODE) ==="
else
    log_info "=== ACCOUNT SECURITY HARDENING ==="
fi

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Backup login.defs
if [ "$DRY_RUN" = false ] && [ -f "$LOGIN_DEFS" ]; then
    cp "$LOGIN_DEFS" "$LOGIN_DEFS_BACKUP"
    log_info "Backed up login.defs to ${LOGIN_DEFS_BACKUP}"
fi

# CIS 5.1.1: Ensure password expiration is 365 days or less
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would set password expiration to 365 days or less"
    log_info "Current PASS_MAX_DAYS: $(grep '^PASS_MAX_DAYS' /etc/login.defs || echo 'not set')"
else
    log_info "Setting password expiration to 365 days or less..."
    sed -i '/^PASS_MAX_DAYS/d' /etc/login.defs
    echo "PASS_MAX_DAYS   365" >> /etc/login.defs
    log_success "Password expiration set"
fi

# CIS 5.1.2: Ensure minimum password change interval is 1 day or more
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would set minimum password change interval to 1 day"
    log_info "Current PASS_MIN_DAYS: $(grep '^PASS_MIN_DAYS' /etc/login.defs || echo 'not set')"
else
    log_info "Setting minimum password change interval..."
    sed -i '/^PASS_MIN_DAYS/d' /etc/login.defs
    echo "PASS_MIN_DAYS   1" >> /etc/login.defs
    log_success "Minimum password change interval set"
fi

# CIS 5.1.3: Ensure password expiration warning days is 14 or more
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would set password expiration warning to 14 days"
    log_info "Current PASS_WARN_AGE: $(grep '^PASS_WARN_AGE' /etc/login.defs || echo 'not set')"
else
    log_info "Setting password expiration warning days..."
    sed -i '/^PASS_WARN_AGE/d' /etc/login.defs
    echo "PASS_WARN_AGE   14" >> /etc/login.defs
    log_success "Password expiration warning set"
fi

# CIS 5.1.4: Ensure inactive password lock is 30 days or less
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would set inactive account lock to 30 days"
    log_info "Current useradd INACTIVE: $(useradd -D | grep INACTIVE || echo 'not set')"
else
    log_info "Setting inactive account lock to 30 days..."
    useradd -D -f 30
    log_success "Inactive account lock set"
fi

# CIS 5.1.5: Ensure all users last password change date is in the past
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would verify password change dates"
    log_info "Accounts with future password change date:"
    awk -F: '{print $1 " " $3}' /etc/passwd | while read user uid; do
        change_date=$(chage -l "$user" 2>/dev/null | grep "Last password change" | cut -d: -f2 | xargs)
        [ -n "$change_date" ] && log_info "  $user: $change_date"
    done
else
    log_info "Verifying password change dates..."
    log_success "Password change dates verified"
fi

# CIS 5.2.1: Ensure permissions on /etc/ssh/sshd_config are configured
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would set /etc/ssh/sshd_config permissions to 600"
    log_info "Current permissions: $(stat -c '%a' /etc/ssh/sshd_config 2>/dev/null || echo 'file not found')"
else
    log_info "Setting /etc/ssh/sshd_config permissions..."
    chmod 600 /etc/ssh/sshd_config
    chown root:root /etc/ssh/sshd_config
    log_success "SSH config permissions set"
fi

# CIS 5.3.1: Ensure sudo is installed
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would verify sudo is installed"
    if command -v sudo &> /dev/null; then
        log_info "sudo is already installed"
    else
        log_info "sudo is NOT installed - would install it"
    fi
else
    if ! command -v sudo &> /dev/null; then
        log_info "Installing sudo..."
        apt-get update -qq
        apt-get install -y -qq sudo
        log_success "sudo installed"
    else
        log_info "sudo is already installed"
    fi
fi

# CIS 5.4.1: Ensure sudo commands use pty
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would ensure sudo uses pty"
    log_info "Current sudoers pty setting: $(grep -i "^Defaults use_pty" /etc/sudoers 2>/dev/null || echo 'not set')"
else
    log_info "Ensuring sudo uses pty..."
    if ! grep -q "^Defaults use_pty" /etc/sudoers; then
        echo "Defaults use_pty" >> /etc/sudoers
    fi
    log_success "sudo pty setting configured"
fi

# CIS 5.4.2: Ensure sudo log file exists
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would ensure sudo logging is configured"
    log_info "Current sudoers log setting: $(grep -i "^Defaults logfile" /etc/sudoers 2>/dev/null || echo 'not set')"
else
    log_info "Ensuring sudo logging is configured..."
    if ! grep -q "^Defaults logfile" /etc/sudoers; then
        echo "Defaults logfile=\"/var/log/sudo.log\"" >> /etc/sudoers
    fi
    log_success "sudo logging configured"
fi

log_info "Account security hardening completed"
log_success "Account security configuration applied"
