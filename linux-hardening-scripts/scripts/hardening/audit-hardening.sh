#!/bin/bash

################################################################################
# Audit & Logging Hardening Script
# Purpose: Configure auditd for comprehensive system and application auditing
# CIS Controls: 4.1 (File integrity), 5.2 (Logging), 5.3 (Audit retention)
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
AUDIT_RULES="/etc/audit/rules.d/hardening.rules"

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
    log_info "=== AUDIT & LOGGING HARDENING (DRY RUN MODE) ==="
else
    log_info "=== AUDIT & LOGGING HARDENING ==="
fi

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# CIS 4.1.1: Ensure auditd is installed
install_auditd() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would ensure auditd is installed"
        ((CHANGES_PLANNED++))
    else
        if ! command -v auditd >/dev/null 2>&1; then
            log_info "Installing auditd and audit-libs..."
            apt-get update >/dev/null 2>&1 || true
            apt-get install -y auditd audit-libs audispd-plugins >/dev/null 2>&1
            log_success "auditd installed"
            ((CHANGES_MADE++))
        else
            log_info "auditd is already installed"
        fi
    fi
}

install_auditd

# CIS 4.1.2: Ensure audit service is enabled and running
enable_auditd() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would enable and start auditd service"
        ((CHANGES_PLANNED++))
    else
        systemctl enable auditd >/dev/null 2>&1 || true
        systemctl start auditd >/dev/null 2>&1 || true
        log_success "auditd service enabled and started"
        ((CHANGES_MADE++))
    fi
}

enable_auditd

# CIS 4.1.3: Ensure auditing for processes that start prior to auditd is enabled
configure_audit_rules() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure audit rules"
        ((CHANGES_PLANNED++))
    else
        # Create audit rules file
        cat > "$AUDIT_RULES" << 'EOF'
# Audit Rules Configuration for CIS Compliance
# Remove any existing rules
-D

# Buffer Size
-b 8192

# Failure Mode
-f 2

# Audit system configuration changes
-w /etc/audit/ -k auditconfig
-w /etc/libaudit.conf -p wa -k auditconfig
-w /etc/audisp/ -p wa -k audispconfig
-w /sbin/auditctl -p x -k audittools
-w /sbin/auditd -p x -k audittools

# Audit user/group changes
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity

# Audit session initiation information
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins

# Audit discretionary access control permission changes
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown,fchown,fchownat,lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown,fchown,fchownat,lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod

# Audit unauthorized access attempts
-a always,exit -F arch=b64 -S open,openat,openat2 -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S open,openat,openat2 -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S open,openat,openat2 -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S open,openat,openat2 -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access

# Audit successful file deletions
-a always,exit -F arch=b64 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink,unlinkat,rename,renameat -F auid>=1000 -F auid!=4294967295 -k delete

# Audit changes to system administration scope
-a always,exit -F path=/etc/sudoers -F perm=wa -F auid>=1000 -F auid!=4294967295 -k scope
-a always,exit -F path=/etc/sudoers.d/ -F perm=wa -F auid>=1000 -F auid!=4294967295 -k scope

# Audit system calls
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex,settimeofday,stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change

# Audit network modification
-a always,exit -F arch=b64 -S sethostname,setdomainname -k network_modifications
-a always,exit -F arch=b32 -S sethostname,setdomainname -k network_modifications
-w /etc/issue -p wa -k network_modifications
-w /etc/issue.net -p wa -k network_modifications
-w /etc/hosts -p wa -k network_modifications
-w /etc/network -p wa -k network_modifications

# Audit login/logout events
-w /var/log/faillog -p wa -k logins
-w /var/log/lastlog -p wa -k logins
-w /var/log/tallylog -p wa -k logins

# Audit session monitoring
-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k logins
-w /var/log/btmp -p wa -k logins

# Audit discretionary access control changes
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b32 -S execve -k exec

# Make configuration immutable (load rules at startup)
-e 2
EOF
        log_success "Audit rules configured"
        ((CHANGES_MADE++))
    fi
}

configure_audit_rules

# CIS 4.1.4: Ensure audit log storage size is configured
configure_audit_storage() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure audit log rotation"
        ((CHANGES_PLANNED++))
    else
        if [ -f /etc/audit/auditd.conf ]; then
            sed -i 's/^#max_log_file = .*/max_log_file = 100/' /etc/audit/auditd.conf
            sed -i 's/^#space_left = .*/space_left = 75/' /etc/audit/auditd.conf
            sed -i 's/^#space_left_action = .*/space_left_action = email/' /etc/audit/auditd.conf
            sed -i 's/^#admin_space_left = .*/admin_space_left = 50/' /etc/audit/auditd.conf
            sed -i 's/^#max_log_file_action = .*/max_log_file_action = keep_logs/' /etc/audit/auditd.conf
            log_success "Audit log storage configured"
            ((CHANGES_MADE++))
        fi
    fi
}

configure_audit_storage

# CIS 5.2.1: Ensure syslog is configured
configure_rsyslog() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would ensure rsyslog is installed and configured"
        ((CHANGES_PLANNED++))
    else
        if ! command -v rsyslogd >/dev/null 2>&1; then
            apt-get update >/dev/null 2>&1 || true
            apt-get install -y rsyslog >/dev/null 2>&1
            log_success "rsyslog installed"
        else
            log_info "rsyslog is already installed"
        fi
        
        # Enable and start rsyslog
        systemctl enable rsyslog >/dev/null 2>&1 || true
        systemctl start rsyslog >/dev/null 2>&1 || true
        log_success "rsyslog enabled and started"
        ((CHANGES_MADE++))
    fi
}

configure_rsyslog

# CIS 5.2.2: Ensure logging is configured
configure_logging() {
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure system logging"
        ((CHANGES_PLANNED++))
    else
        # Create logging configuration
        if [ ! -f /etc/rsyslog.d/hardening.conf ]; then
            cat > /etc/rsyslog.d/hardening.conf << 'EOF'
# CIS Hardening Logging Configuration

# Log authentication messages
auth,authpriv.*                 /var/log/auth.log

# Log kernel messages
kern.*                          /var/log/kern.log

# Log mail system
mail.*                          /var/log/mail.log
mail.err                        /var/log/mail.err

# Log cron messages
cron.*                          /var/log/cron.log

# Log emergency messages
*.emerg                         :omusrmsg:*

# Local rules
local0.*                        /var/log/local0.log
local1.*                        /var/log/local1.log
EOF
            log_success "System logging configured"
            ((CHANGES_MADE++))
        fi
    fi
}

configure_logging

# Reload auditd to apply new rules
if [ "$DRY_RUN" = false ]; then
    auditctl -R "$AUDIT_RULES" >/dev/null 2>&1 || true
    systemctl restart auditd >/dev/null 2>&1 || true
    log_info "Audit rules reloaded"
fi

# Summary
log_info "=== AUDIT & LOGGING SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_success "Audit and logging hardening completed: ${CHANGES_MADE} changes applied"
    log_info "Audit rules file: ${AUDIT_RULES}"
    log_warning "Audit logging is now enabled - monitor /var/log/audit/audit.log"
fi

exit 0
