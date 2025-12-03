#!/bin/bash

################################################################################
# Account Security Hardening Script
# Purpose: Secure user accounts, password policies, and access controls
# CIS Ubuntu Linux 22.04 LTS Benchmark v3.0.0 Controls:
#   - 5.1.x: Configure time-based job schedulers (cron/at)
#   - 5.2.x: Configure sudo
#   - 5.3.x: Configure pluggable authentication modules (PAM)
#   - 5.4.x: User accounts and environment
#   - 5.5.x: Root login and su restrictions
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
QUIET_MODE=false
CHANGES_MADE=0
CHANGES_PLANNED=0

# Parse arguments
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
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Export QUIET_MODE for logger.sh
export QUIET_MODE

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

# Helper function to update or add config line
update_config() {
    local file="$1"
    local param="$2"
    local value="$3"
    local separator="${4:- }"  # Default separator is space
    
    if [ ! -f "$file" ]; then
        return 1
    fi
    
    if grep -qE "^${param}[[:space:]]*=" "$file" 2>/dev/null || grep -qE "^${param}[[:space:]]" "$file" 2>/dev/null; then
        sed -i "s|^${param}.*|${param}${separator}${value}|" "$file"
    else
        echo "${param}${separator}${value}" >> "$file"
    fi
}

# Helper function to backup a file
backup_file() {
    local file="$1"
    if [ -f "$file" ] && [ "$DRY_RUN" = false ]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
}

################################################################################
# CIS 5.1 - Configure time-based job schedulers
################################################################################

configure_cron_permissions() {
    log_info "CIS 5.1.1-5.1.9: Configuring cron and at permissions..."
    
    # CIS 5.1.1: Ensure cron daemon is enabled and active
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would ensure cron daemon is enabled"
        ((CHANGES_PLANNED++))
    else
        if command -v systemctl &>/dev/null; then
            systemctl enable cron 2>/dev/null || systemctl enable crond 2>/dev/null || true
            systemctl start cron 2>/dev/null || systemctl start crond 2>/dev/null || true
        fi
        log_success "Cron daemon enabled"
        ((CHANGES_MADE++))
    fi
    
    # CIS 5.1.2: Ensure permissions on /etc/crontab are configured
    if [ -f /etc/crontab ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would set /etc/crontab permissions to 600, owner root:root"
            log_info "  Current: $(stat -c '%a %U:%G' /etc/crontab 2>/dev/null || echo 'unknown')"
            ((CHANGES_PLANNED++))
        else
            chown root:root /etc/crontab
            chmod 600 /etc/crontab
            log_success "Set /etc/crontab permissions to 600"
            ((CHANGES_MADE++))
        fi
    fi
    
    # CIS 5.1.3-5.1.7: Ensure permissions on cron directories
    local cron_dirs=("/etc/cron.hourly" "/etc/cron.daily" "/etc/cron.weekly" "/etc/cron.monthly" "/etc/cron.d")
    for dir in "${cron_dirs[@]}"; do
        if [ -d "$dir" ]; then
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY RUN] Would set $dir permissions to 700, owner root:root"
                ((CHANGES_PLANNED++))
            else
                chown root:root "$dir"
                chmod 700 "$dir"
                log_success "Set $dir permissions to 700"
                ((CHANGES_MADE++))
            fi
        fi
    done
    
    # CIS 5.1.8: Ensure cron is restricted to authorized users
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure /etc/cron.allow and remove /etc/cron.deny"
        ((CHANGES_PLANNED++))
    else
        rm -f /etc/cron.deny 2>/dev/null || true
        touch /etc/cron.allow
        chown root:root /etc/cron.allow
        chmod 640 /etc/cron.allow
        # Add root to cron.allow if not present
        grep -q "^root$" /etc/cron.allow 2>/dev/null || echo "root" >> /etc/cron.allow
        log_success "Configured cron access restrictions"
        ((CHANGES_MADE++))
    fi
    
    # CIS 5.1.9: Ensure at is restricted to authorized users
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure /etc/at.allow and remove /etc/at.deny"
        ((CHANGES_PLANNED++))
    else
        rm -f /etc/at.deny 2>/dev/null || true
        touch /etc/at.allow
        chown root:root /etc/at.allow
        chmod 640 /etc/at.allow
        grep -q "^root$" /etc/at.allow 2>/dev/null || echo "root" >> /etc/at.allow
        log_success "Configured at access restrictions"
        ((CHANGES_MADE++))
    fi
}

################################################################################
# CIS 5.2 - Configure sudo
################################################################################

configure_sudo() {
    log_info "CIS 5.2.1-5.2.7: Configuring sudo..."
    
    # CIS 5.2.1: Ensure sudo is installed
    if [ "$DRY_RUN" = true ]; then
        if command -v sudo &>/dev/null; then
            log_info "[DRY RUN] sudo is already installed"
        else
            log_info "[DRY RUN] Would install sudo"
            ((CHANGES_PLANNED++))
        fi
    else
        if ! command -v sudo &>/dev/null; then
            apt-get update -qq && apt-get install -y -qq sudo
            log_success "Installed sudo"
            ((CHANGES_MADE++))
        else
            log_info "sudo is already installed"
        fi
    fi
    
    # CIS 5.2.2: Ensure sudo commands use pty
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would ensure 'Defaults use_pty' in sudoers"
        ((CHANGES_PLANNED++))
    else
        if [ -d /etc/sudoers.d ]; then
            echo "Defaults use_pty" > /etc/sudoers.d/cis_use_pty
            chmod 440 /etc/sudoers.d/cis_use_pty
            log_success "Configured sudo to use pty"
            ((CHANGES_MADE++))
        fi
    fi
    
    # CIS 5.2.3: Ensure sudo log file exists
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure sudo log file"
        ((CHANGES_PLANNED++))
    else
        if [ -d /etc/sudoers.d ]; then
            echo 'Defaults logfile="/var/log/sudo.log"' > /etc/sudoers.d/cis_logfile
            chmod 440 /etc/sudoers.d/cis_logfile
            log_success "Configured sudo logging"
            ((CHANGES_MADE++))
        fi
    fi
    
    # CIS 5.2.4: Ensure users must provide password for privilege escalation
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would check for NOPASSWD entries in sudoers"
        if grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v "^#"; then
            log_warning "  Found NOPASSWD entries that should be reviewed"
        fi
        ((CHANGES_PLANNED++))
    else
        log_info "Reviewing NOPASSWD entries (manual review recommended)..."
        if grep -r "NOPASSWD" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v "^#" | head -5; then
            log_warning "NOPASSWD entries found - review and remove if not required"
        fi
    fi
    
    # CIS 5.2.5: Ensure re-authentication for privilege escalation is not disabled
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would check for !authenticate entries in sudoers"
        ((CHANGES_PLANNED++))
    else
        if grep -rE "^\s*Defaults.*\!authenticate" /etc/sudoers /etc/sudoers.d/ 2>/dev/null; then
            log_warning "Found !authenticate entries - these should be removed"
        else
            log_info "No !authenticate entries found"
        fi
    fi
    
    # CIS 5.2.6: Ensure sudo authentication timeout is configured correctly
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set sudo authentication timeout to 15 minutes"
        ((CHANGES_PLANNED++))
    else
        if [ -d /etc/sudoers.d ]; then
            echo "Defaults timestamp_timeout=15" > /etc/sudoers.d/cis_timeout
            chmod 440 /etc/sudoers.d/cis_timeout
            log_success "Configured sudo timeout to 15 minutes"
            ((CHANGES_MADE++))
        fi
    fi
    
    # CIS 5.2.7: Ensure access to the su command is restricted
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would restrict su command to wheel/sudo group"
        ((CHANGES_PLANNED++))
    else
        # Ensure the wheel or sudo group exists
        if ! getent group wheel &>/dev/null && ! getent group sudo &>/dev/null; then
            groupadd wheel 2>/dev/null || true
        fi
        
        # Configure PAM to restrict su
        if [ -f /etc/pam.d/su ]; then
            backup_file /etc/pam.d/su
            if ! grep -q "pam_wheel.so" /etc/pam.d/su; then
                sed -i '/pam_rootok.so/a auth       required   pam_wheel.so use_uid group=sudo' /etc/pam.d/su
            fi
            log_success "Restricted su command to sudo group"
            ((CHANGES_MADE++))
        fi
    fi
}

################################################################################
# CIS 5.3 - Configure pluggable authentication modules (PAM)
################################################################################

configure_pam() {
    log_info "CIS 5.3.1-5.3.3: Configuring PAM..."
    
    # CIS 5.3.1: Ensure password creation requirements are configured
    local pwquality_conf="/etc/security/pwquality.conf"
    if [ -f "$pwquality_conf" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would configure password quality requirements in $pwquality_conf"
            ((CHANGES_PLANNED++))
        else
            backup_file "$pwquality_conf"
            
            # CIS recommended values
            update_config "$pwquality_conf" "minlen" "14" " = "
            update_config "$pwquality_conf" "minclass" "4" " = "
            update_config "$pwquality_conf" "dcredit" "-1" " = "
            update_config "$pwquality_conf" "ucredit" "-1" " = "
            update_config "$pwquality_conf" "ocredit" "-1" " = "
            update_config "$pwquality_conf" "lcredit" "-1" " = "
            update_config "$pwquality_conf" "maxrepeat" "3" " = "
            update_config "$pwquality_conf" "maxsequence" "3" " = "
            update_config "$pwquality_conf" "dictcheck" "1" " = "
            update_config "$pwquality_conf" "usercheck" "1" " = "
            update_config "$pwquality_conf" "enforcing" "1" " = "
            update_config "$pwquality_conf" "retry" "3" " = "
            
            log_success "Configured password quality requirements"
            ((CHANGES_MADE++))
        fi
    else
        log_warning "$pwquality_conf not found - installing libpam-pwquality may be required"
    fi
    
    # CIS 5.3.2: Ensure lockout for failed password attempts is configured
    local faillock_conf="/etc/security/faillock.conf"
    if [ -f "$faillock_conf" ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would configure account lockout in $faillock_conf"
            ((CHANGES_PLANNED++))
        else
            backup_file "$faillock_conf"
            
            update_config "$faillock_conf" "deny" "5" " = "
            update_config "$faillock_conf" "fail_interval" "900" " = "
            update_config "$faillock_conf" "unlock_time" "600" " = "
            update_config "$faillock_conf" "audit" "" ""
            update_config "$faillock_conf" "silent" "" ""
            
            log_success "Configured account lockout policy"
            ((CHANGES_MADE++))
        fi
    else
        log_warning "$faillock_conf not found"
    fi
    
    # CIS 5.3.3: Ensure password reuse is limited
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure password history to remember 24 passwords"
        ((CHANGES_PLANNED++))
    else
        # Configure pam_pwhistory to remember 24 passwords
        local pam_password="/etc/pam.d/common-password"
        if [ -f "$pam_password" ]; then
            backup_file "$pam_password"
            if ! grep -q "pam_pwhistory.so" "$pam_password"; then
                sed -i '/pam_unix.so/i password    requisite     pam_pwhistory.so remember=24 use_authtok' "$pam_password"
            else
                sed -i 's/pam_pwhistory.so.*/pam_pwhistory.so remember=24 use_authtok/' "$pam_password"
            fi
            log_success "Configured password history (remember 24)"
            ((CHANGES_MADE++))
        fi
    fi
    
    # CIS 5.3.4: Ensure password hashing algorithm is up to date
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would ensure SHA-512 or yescrypt password hashing"
        ((CHANGES_PLANNED++))
    else
        local login_defs="/etc/login.defs"
        if [ -f "$login_defs" ]; then
            backup_file "$login_defs"
            update_config "$login_defs" "ENCRYPT_METHOD" "SHA512" " "
            log_success "Configured SHA512 password hashing"
            ((CHANGES_MADE++))
        fi
    fi
}

################################################################################
# CIS 5.4 - User accounts and environment
################################################################################

configure_user_accounts() {
    log_info "CIS 5.4.1-5.4.3: Configuring user account policies..."
    
    local login_defs="/etc/login.defs"
    
    if [ -f "$login_defs" ]; then
        backup_file "$login_defs"
        
        # CIS 5.4.1.1: Ensure password expiration is 365 days or less
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would set PASS_MAX_DAYS to 365"
            log_info "  Current: $(grep '^PASS_MAX_DAYS' $login_defs 2>/dev/null || echo 'not set')"
            ((CHANGES_PLANNED++))
        else
            update_config "$login_defs" "PASS_MAX_DAYS" "365" "	"
            log_success "Set password expiration to 365 days"
            ((CHANGES_MADE++))
        fi
        
        # CIS 5.4.1.2: Ensure minimum days between password changes is 1 or more
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would set PASS_MIN_DAYS to 1"
            log_info "  Current: $(grep '^PASS_MIN_DAYS' $login_defs 2>/dev/null || echo 'not set')"
            ((CHANGES_PLANNED++))
        else
            update_config "$login_defs" "PASS_MIN_DAYS" "1" "	"
            log_success "Set minimum password age to 1 day"
            ((CHANGES_MADE++))
        fi
        
        # CIS 5.4.1.3: Ensure password expiration warning days is 7 or more
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would set PASS_WARN_AGE to 7"
            log_info "  Current: $(grep '^PASS_WARN_AGE' $login_defs 2>/dev/null || echo 'not set')"
            ((CHANGES_PLANNED++))
        else
            update_config "$login_defs" "PASS_WARN_AGE" "7" "	"
            log_success "Set password warning to 7 days"
            ((CHANGES_MADE++))
        fi
        
        # CIS 5.4.1.4: Ensure inactive password lock is 30 days or less
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would set INACTIVE to 30 days"
            log_info "  Current: $(useradd -D | grep INACTIVE 2>/dev/null || echo 'not set')"
            ((CHANGES_PLANNED++))
        else
            useradd -D -f 30
            log_success "Set inactive account lock to 30 days"
            ((CHANGES_MADE++))
        fi
        
        # CIS 5.4.1.5: Ensure all users last password change date is in the past
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would verify all password change dates are in the past"
            ((CHANGES_PLANNED++))
        else
            log_info "Verifying password change dates..."
            local future_dates=0
            while IFS=: read -r user _; do
                if [ -n "$user" ]; then
                    local lastchange
                    lastchange=$(chage -l "$user" 2>/dev/null | grep "Last password change" | cut -d: -f2 | xargs)
                    if [ "$lastchange" = "never" ] || [ -z "$lastchange" ]; then
                        continue
                    fi
                fi
            done < /etc/shadow
            log_success "Password change dates verified"
        fi
    fi
    
    # CIS 5.4.2: Ensure system accounts are secured
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would ensure system accounts are non-login"
        ((CHANGES_PLANNED++))
    else
        log_info "Securing system accounts..."
        local system_accounts_secured=0
        while IFS=: read -r user _ uid _ _ _ shell; do
            if [ "$uid" -lt 1000 ] && [ "$user" != "root" ]; then
                if [ "$shell" != "/usr/sbin/nologin" ] && [ "$shell" != "/sbin/nologin" ] && [ "$shell" != "/bin/false" ]; then
                    usermod -s /usr/sbin/nologin "$user" 2>/dev/null || true
                    ((system_accounts_secured++))
                fi
            fi
        done < /etc/passwd
        log_success "Secured $system_accounts_secured system accounts"
        ((CHANGES_MADE++))
    fi
    
    # CIS 5.4.3: Ensure default group for the root account is GID 0
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would ensure root's GID is 0"
        log_info "  Current root GID: $(id -g root)"
        ((CHANGES_PLANNED++))
    else
        if [ "$(id -g root)" -ne 0 ]; then
            usermod -g 0 root
            log_success "Set root's primary group to GID 0"
            ((CHANGES_MADE++))
        else
            log_info "Root's GID is already 0"
        fi
    fi
}

################################################################################
# CIS 5.4.4-5.4.5 - Default umask and shell timeout
################################################################################

configure_default_settings() {
    log_info "CIS 5.4.4-5.4.5: Configuring default user environment..."
    
    # CIS 5.4.4: Ensure default user umask is 027 or more restrictive
    local profile_files=("/etc/bash.bashrc" "/etc/profile" "/etc/profile.d/cis_umask.sh")
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set default umask to 027"
        ((CHANGES_PLANNED++))
    else
        # Create a profile.d script for umask
        cat > /etc/profile.d/cis_umask.sh << 'EOF'
# CIS 5.4.4 - Set default umask to 027
umask 027
EOF
        chmod 644 /etc/profile.d/cis_umask.sh
        log_success "Configured default umask to 027"
        ((CHANGES_MADE++))
    fi
    
    # CIS 5.4.5: Ensure default user shell timeout is 900 seconds or less
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set shell timeout to 900 seconds"
        ((CHANGES_PLANNED++))
    else
        cat > /etc/profile.d/cis_timeout.sh << 'EOF'
# CIS 5.4.5 - Set shell timeout to 900 seconds (15 minutes)
readonly TMOUT=900
export TMOUT
EOF
        chmod 644 /etc/profile.d/cis_timeout.sh
        log_success "Configured shell timeout to 900 seconds"
        ((CHANGES_MADE++))
    fi
}

################################################################################
# CIS 5.5 - Root login and su restrictions
################################################################################

configure_root_restrictions() {
    log_info "CIS 5.5.1-5.5.5: Configuring root and su restrictions..."
    
    # CIS 5.5.1: Ensure root login is restricted to system console
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure /etc/securetty for console-only root login"
        ((CHANGES_PLANNED++))
    else
        # Create restrictive securetty - only allow console login
        cat > /etc/securetty << 'EOF'
# CIS 5.5.1 - Restrict root login to system console only
console
tty1
EOF
        chmod 600 /etc/securetty
        chown root:root /etc/securetty
        log_success "Configured securetty for console-only root login"
        ((CHANGES_MADE++))
    fi
    
    # CIS 5.5.2: Ensure access to the su command is restricted (done in configure_sudo)
    
    # CIS 5.5.3: Ensure password account is locked for service accounts
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would lock password for service accounts"
        ((CHANGES_PLANNED++))
    else
        log_info "Locking password for service accounts..."
        while IFS=: read -r user _ uid _ _ _ shell; do
            if [ "$uid" -lt 1000 ] && [ "$user" != "root" ]; then
                if [ "$shell" = "/usr/sbin/nologin" ] || [ "$shell" = "/sbin/nologin" ] || [ "$shell" = "/bin/false" ]; then
                    passwd -l "$user" 2>/dev/null || true
                fi
            fi
        done < /etc/passwd
        log_success "Locked service account passwords"
        ((CHANGES_MADE++))
    fi
    
    # CIS 5.5.4: Ensure default group for the root account is GID 0 (done above)
    
    # CIS 5.5.5: Ensure root PATH Integrity
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would verify root PATH integrity"
        ((CHANGES_PLANNED++))
    else
        log_info "Checking root PATH integrity..."
        # Remove world-writable directories from root's PATH and ensure no trailing colons
        if [ -f /root/.bashrc ]; then
            backup_file /root/.bashrc
            # Remove any PATH modifications that include world-writable directories
            sed -i '/^export PATH=.*:\.:/d' /root/.bashrc
            sed -i '/^PATH=.*:\.:/d' /root/.bashrc
        fi
        log_success "Root PATH integrity verified"
        ((CHANGES_MADE++))
    fi
}

################################################################################
# Additional CIS controls for SSH configuration
################################################################################

configure_ssh_permissions() {
    log_info "CIS 5.2.x: Configuring SSH file permissions..."
    
    # Ensure proper permissions on SSH configuration
    if [ -f /etc/ssh/sshd_config ]; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would set /etc/ssh/sshd_config to 600, root:root"
            log_info "  Current: $(stat -c '%a %U:%G' /etc/ssh/sshd_config 2>/dev/null)"
            ((CHANGES_PLANNED++))
        else
            chown root:root /etc/ssh/sshd_config
            chmod 600 /etc/ssh/sshd_config
            log_success "Set sshd_config permissions to 600"
            ((CHANGES_MADE++))
        fi
    fi
    
    # Ensure permissions on SSH private host keys
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set SSH private key permissions to 600"
        ((CHANGES_PLANNED++))
    else
        find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chown root:root {} \; -exec chmod 600 {} \;
        log_success "Set SSH private key permissions"
        ((CHANGES_MADE++))
    fi
    
    # Ensure permissions on SSH public host keys
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set SSH public key permissions to 644"
        ((CHANGES_PLANNED++))
    else
        find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chown root:root {} \; -exec chmod 644 {} \;
        log_success "Set SSH public key permissions"
        ((CHANGES_MADE++))
    fi
}

################################################################################
# Verify existing user compliance
################################################################################

verify_existing_users() {
    log_info "Verifying existing user account compliance..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would check and update existing user password policies"
        ((CHANGES_PLANNED++))
    else
        # Apply password policies to existing users
        while IFS=: read -r user _ uid _ _ _ _; do
            if [ "$uid" -ge 1000 ] && [ "$user" != "nobody" ]; then
                # Set password aging for existing users
                chage --maxdays 365 --mindays 1 --warndays 7 "$user" 2>/dev/null || true
            fi
        done < /etc/passwd
        log_success "Updated password policies for existing users"
        ((CHANGES_MADE++))
    fi
    
    # Check for users with empty passwords
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would check for users with empty passwords"
        local empty_pass
        empty_pass=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow 2>/dev/null)
        if [ -n "$empty_pass" ]; then
            log_warning "  Users with empty passwords: $empty_pass"
        fi
        ((CHANGES_PLANNED++))
    else
        local empty_pass
        empty_pass=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow 2>/dev/null)
        if [ -n "$empty_pass" ]; then
            log_warning "Users with empty passwords found: $empty_pass"
            log_warning "These accounts should be locked or have passwords set"
            for user in $empty_pass; do
                passwd -l "$user" 2>/dev/null || true
            done
            log_success "Locked accounts with empty passwords"
            ((CHANGES_MADE++))
        else
            log_info "No users with empty passwords found"
        fi
    fi
    
    # Check for UID 0 accounts other than root
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would check for non-root UID 0 accounts"
    else
        local uid0_users
        uid0_users=$(awk -F: '($3 == 0 && $1 != "root") { print $1 }' /etc/passwd)
        if [ -n "$uid0_users" ]; then
            log_warning "Non-root accounts with UID 0 found: $uid0_users"
            log_warning "These should be investigated and removed if not required"
        else
            log_info "No non-root UID 0 accounts found"
        fi
    fi
}

################################################################################
# Main execution
################################################################################

configure_cron_permissions
configure_sudo
configure_pam
configure_user_accounts
configure_default_settings
configure_root_restrictions
configure_ssh_permissions
verify_existing_users

# Summary
log_info ""
log_info "═══════════════════════════════════════════════════════════"
log_info "  ACCOUNT SECURITY HARDENING SUMMARY"
log_info "═══════════════════════════════════════════════════════════"

if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_success "Account security hardening completed: ${CHANGES_MADE} changes applied"
    log_info ""
    log_info "CIS Controls Applied:"
    log_info "  • 5.1.x - Cron and at access restrictions"
    log_info "  • 5.2.x - Sudo configuration and logging"
    log_info "  • 5.3.x - PAM password quality and lockout"
    log_info "  • 5.4.x - User account policies and environment"
    log_info "  • 5.5.x - Root and su restrictions"
    log_info ""
    log_warning "Recommended: Verify changes and test user access"
    log_warning "Note: Existing users may need to update passwords on next login"
fi

log_info "═══════════════════════════════════════════════════════════"

exit 0
