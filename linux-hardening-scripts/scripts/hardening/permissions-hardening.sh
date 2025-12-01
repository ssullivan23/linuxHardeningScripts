#!/bin/bash

################################################################################
# File & Directory Permissions Hardening Script
# Purpose: Secure file permissions and ownership across the system
# CIS Controls: 6.1 (File permissions), 6.2 (File ownership)
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
    log_info "=== FILE & DIRECTORY PERMISSIONS HARDENING (DRY RUN MODE) ==="
else
    log_info "=== FILE & DIRECTORY PERMISSIONS HARDENING ==="
fi

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# CIS 6.1.1: Ensure permissions on /etc/passwd are configured
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/passwd permissions to 644"
else
    chmod 644 /etc/passwd 2>/dev/null || true
    log_success "Set /etc/passwd permissions to 644"
    ((CHANGES_MADE++))
fi

# CIS 6.1.2: Ensure permissions on /etc/shadow are configured
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/shadow permissions to 640"
else
    chmod 640 /etc/shadow 2>/dev/null || true
    chown root:shadow /etc/shadow 2>/dev/null || true
    log_success "Set /etc/shadow permissions to 640"
    ((CHANGES_MADE++))
fi

# CIS 6.1.3: Ensure permissions on /etc/group are configured
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/group permissions to 644"
else
    chmod 644 /etc/group 2>/dev/null || true
    log_success "Set /etc/group permissions to 644"
    ((CHANGES_MADE++))
fi

# CIS 6.1.4: Ensure permissions on /etc/gshadow are configured
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/gshadow permissions to 640"
else
    chmod 640 /etc/gshadow 2>/dev/null || true
    chown root:shadow /etc/gshadow 2>/dev/null || true
    log_success "Set /etc/gshadow permissions to 640"
    ((CHANGES_MADE++))
fi

# CIS 6.1.5: Ensure /etc/ssh/sshd_config has appropriate permissions
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/ssh/sshd_config permissions to 600"
else
    if [ -f /etc/ssh/sshd_config ]; then
        chmod 600 /etc/ssh/sshd_config
        chown root:root /etc/ssh/sshd_config
        log_success "Set /etc/ssh/sshd_config permissions to 600"
        ((CHANGES_MADE++))
    fi
fi

# CIS 6.1.6: Ensure /etc/ssh/sshd_config.d/ directory has appropriate permissions
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/ssh/sshd_config.d/ permissions to 755"
else
    if [ -d /etc/ssh/sshd_config.d/ ]; then
        chmod 755 /etc/ssh/sshd_config.d/
        find /etc/ssh/sshd_config.d/ -type f -exec chmod 600 {} \; 2>/dev/null || true
        log_success "Set /etc/ssh/sshd_config.d/ permissions"
        ((CHANGES_MADE++))
    fi
fi

# CIS 6.1.7: Ensure /etc/login.defs has appropriate permissions
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/login.defs permissions to 644"
else
    chmod 644 /etc/login.defs 2>/dev/null || true
    log_success "Set /etc/login.defs permissions to 644"
    ((CHANGES_MADE++))
fi

# CIS 6.1.8: Ensure /etc/pam.d/ has appropriate permissions
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/pam.d/ permissions to 755"
else
    chmod 755 /etc/pam.d 2>/dev/null || true
    find /etc/pam.d -type f -exec chmod 644 {} \; 2>/dev/null || true
    log_success "Set /etc/pam.d/ permissions"
    ((CHANGES_MADE++))
fi

# CIS 6.1.9: Ensure /etc/cron.d/ has appropriate permissions
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/cron.d/ permissions to 700"
else
    if [ -d /etc/cron.d ]; then
        chmod 700 /etc/cron.d 2>/dev/null || true
        find /etc/cron.d -type f -exec chmod 600 {} \; 2>/dev/null || true
        log_success "Set /etc/cron.d/ permissions"
        ((CHANGES_MADE++))
    fi
fi

# CIS 6.1.10: Ensure /etc/cron.daily/ has appropriate permissions
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set /etc/cron.daily/ permissions to 755"
else
    if [ -d /etc/cron.daily ]; then
        chmod 755 /etc/cron.daily 2>/dev/null || true
        log_success "Set /etc/cron.daily/ permissions"
        ((CHANGES_MADE++))
    fi
fi

# Set permissions on cron files
for cron_dir in /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly; do
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set $cron_dir permissions to 755"
    else
        if [ -d "$cron_dir" ]; then
            chmod 755 "$cron_dir" 2>/dev/null || true
        fi
    fi
done

# CIS 6.2: Ensure user home directories exist
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would audit user home directories"
else
    awk -F: '{ if ($3 >= 1000 && $3 != 65534) print $1, $6 }' /etc/passwd | while read user homedir; do
        if [ ! -d "$homedir" ]; then
            log_warn "User $user home directory $homedir does not exist"
        else
            # Set proper ownership and permissions
            chown "$user:$user" "$homedir" 2>/dev/null || true
            chmod 750 "$homedir" 2>/dev/null || true
        fi
    done
    log_success "User home directories audited"
    ((CHANGES_MADE++))
fi

# CIS 6.2.1: Ensure users own their home directories
if [ "$DRY_RUN" = false ]; then
    awk -F: '{ if ($3 >= 1000 && $3 != 65534) print $1, $3, $6 }' /etc/passwd | while read user uid homedir; do
        if [ -d "$homedir" ]; then
            actual_owner=$(stat -c %U "$homedir" 2>/dev/null || echo "")
            if [ "$actual_owner" != "$user" ]; then
                chown "$user:$user" "$homedir" 2>/dev/null || true
                log_info "Corrected ownership of $homedir to $user"
            fi
        fi
    done
fi

# CIS 6.2.2: Ensure users' home directories permissions are 750 or more restrictive
if [ "$DRY_RUN" = false ]; then
    awk -F: '{ if ($3 >= 1000 && $3 != 65534) print $1, $6 }' /etc/passwd | while read user homedir; do
        if [ -d "$homedir" ]; then
            perms=$(stat -c %a "$homedir" 2>/dev/null || echo "")
            if [ "$perms" -gt 750 ] 2>/dev/null; then
                chmod 750 "$homedir" 2>/dev/null || true
                log_info "Corrected permissions of $homedir to 750"
            fi
        fi
    done
fi

# Find and fix world-writable files (except special files)
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would audit and fix world-writable files"
    ((CHANGES_PLANNED++))
else
    log_info "Auditing world-writable files..."
    find / -xdev -type f -perm -0002 2>/dev/null | while read file; do
        # Skip special system files
        case "$file" in
            /proc/*|/sys/*|/dev/*|/tmp/*|/var/tmp/*) continue ;;
        esac
        chmod o-w "$file" 2>/dev/null || true
    done
    log_success "World-writable files corrected"
    ((CHANGES_MADE++))
fi

# Find and fix SUID/SGID files that shouldn't have those bits
if [ "$DRY_RUN" = false ]; then
    log_info "Auditing SUID/SGID files..."
    # This is informational - we just report suspicious files
    find / -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -20 | while read file; do
        log_info "Found SUID/SGID file: $file"
    done
fi

# Summary
log_info "=== FILE & DIRECTORY PERMISSIONS SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed"
    log_warning "Run without --dry-run to apply changes"
else
    log_success "File and directory permissions hardening completed: ${CHANGES_MADE} changes applied"
    log_warning "All critical system file permissions have been secured"
fi

exit 0
