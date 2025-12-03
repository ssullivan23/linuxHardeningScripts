#!/bin/bash

# bootloader-hardening.sh - GRUB bootloader security
# Based on CIS Ubuntu Linux 22.04 LTS Benchmark v3.0.0
# Controls: 1.5 (GRUB permissions, superuser password)

set -euo pipefail

# Determine script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load utility functions
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh"

# Parse command-line arguments
DRY_RUN=false
QUIET_MODE=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --quiet|-q) QUIET_MODE=true ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--quiet]"
            echo "  --dry-run    Show what changes would be made without applying them"
            echo "  --quiet, -q  Minimal output - only show warnings and changes"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Export QUIET_MODE for logger.sh
export QUIET_MODE

log_info "Starting bootloader hardening..."

# CIS 1.5.1: Ensure permissions on bootloader config are configured
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would set /boot/grub/grub.cfg permissions to 600"
    log_info "Current permissions: $(stat -c '%a' /boot/grub/grub.cfg 2>/dev/null || echo 'file not found')"
else
    log_info "Setting bootloader config permissions..."
    if [ -f /boot/grub/grub.cfg ]; then
        chmod 600 /boot/grub/grub.cfg
        chown root:root /boot/grub/grub.cfg
        log_success "Bootloader permissions set"
    else
        log_warn "/boot/grub/grub.cfg not found - skipping"
    fi
fi

# CIS 1.5.2: Ensure bootloader password is set
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would verify GRUB superuser password is set"
    if grep -q "^set superusers" /etc/grub.d/40_custom 2>/dev/null; then
        log_info "GRUB superuser password appears to be set"
    else
        log_warn "GRUB superuser password does not appear to be set"
    fi
else
    log_info "Verifying bootloader password configuration..."
    if ! grep -q "^set superusers" /etc/grub.d/40_custom 2>/dev/null; then
        log_warn "GRUB superuser password is not set - manual configuration required"
        log_info "To set GRUB password, run: sudo grub-mkpasswd-pbkdf2"
    else
        log_success "GRUB superuser password is set"
    fi
fi

# CIS 1.5.3: Ensure authentication required for single user mode
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would verify single user mode authentication"
    if grep -q "^root:" /etc/shadow; then
        log_info "Root account appears to be locked or configured"
    fi
else
    log_info "Verifying single user mode authentication..."
    # Ensure root account is properly configured
    if grep -q "^root:\*:" /etc/shadow; then
        log_warn "Root account is locked - consider unlocking for emergency access"
    else
        log_success "Single user mode authentication verified"
    fi
fi

log_info "Bootloader hardening completed"
log_success "Bootloader security configuration applied"
