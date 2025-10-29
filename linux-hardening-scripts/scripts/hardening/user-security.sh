#!/bin/bash#!/bin/bash



################################################################################# user-security.sh - Manage user security settings

# User Security Hardening Script

# Purpose: Enforce password policies and user account securityLOG_FILE="user-security.log"

# Features: Dry-run mode, console logging, summary reportingDRY_RUN=false

################################################################################

# Function to log messages

# Source utilitieslog_message() {

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE

source "${SCRIPT_DIR}/../utils/logger.sh" 2>/dev/null || {}

    echo "ERROR: Cannot load logger.sh"

    exit 1# Function to enforce password policies

}enforce_password_policy() {

    log_message "Enforcing password policy..."

# Configuration    # Example: Set password expiration to 90 days

DRY_RUN=false    if [ "$DRY_RUN" = false ]; then

CHANGES_MADE=0        chage --maxdays 90 $(getent passwd | cut -d: -f1)

CHANGES_PLANNED=0        log_message "Password policy enforced."

    else

# Parse arguments        log_message "DRY RUN: Password policy would be enforced."

while [[ "$#" -gt 0 ]]; do    fi

    case $1 in}

        --dry-run) DRY_RUN=true ;;

        *) echo "Unknown parameter: $1"; exit 1 ;;# Function to lock inactive accounts

    esaclock_inactive_accounts() {

    shift    log_message "Locking inactive accounts..."

done    # Example: Lock accounts that have been inactive for 90 days

    if [ "$DRY_RUN" = false ]; then

# Initialize        for user in $(awk -F: '($3 >= 1000) {print $1}' /etc/passwd); do

if [ "$DRY_RUN" = true ]; then            if [ $(chage -l $user | grep "Last activity" | awk '{print $3}') -gt 90 ]; then

    log_info "=== USER SECURITY HARDENING (DRY RUN MODE) ==="                usermod -L $user

else                log_message "Locked account: $user"

    log_info "=== USER SECURITY HARDENING ==="            fi

fi        done

    else

# Check if running as root        log_message "DRY RUN: Inactive accounts would be locked."

if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then    fi

    log_error "This script must be run as root (use sudo)"}

    exit 1

fi# Parse command-line arguments

while getopts ":d" opt; do

# Function to update or add config line    case $opt in

update_config() {        d)

    local file="$1"            DRY_RUN=true

    local param="$2"            log_message "Running in DRY RUN mode."

    local value="$3"            ;;

    local description="$4"        \?)

                log_message "Invalid option: -$OPTARG" >&2

    if [ ! -f "$file" ]; then            exit 1

        log_warning "File $file does not exist, skipping"            ;;

        return    esac

    fidone

    

    if grep -q "^${param}" "$file"; then# Execute functions

        if [ "$DRY_RUN" = true ]; thenenforce_password_policy

            log_info "[DRY RUN] Would update ${param} in ${file} - ${description}"lock_inactive_accounts

            ((CHANGES_PLANNED++))

        elselog_message "User security settings management completed."
            sed -i "s|^${param}.*|${param} ${value}|" "$file"
            log_info "Updated ${param} in ${file} - ${description}"
            ((CHANGES_MADE++))
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would add ${param} to ${file} - ${description}"
            ((CHANGES_PLANNED++))
        else
            echo "${param} ${value}" >> "$file"
            log_info "Added ${param} to ${file} - ${description}"
            ((CHANGES_MADE++))
        fi
    fi
}

# Configure password aging in /etc/login.defs
configure_password_aging() {
    log_info "Configuring password aging policies..."
    
    local LOGIN_DEFS="/etc/login.defs"
    
    if [ -f "$LOGIN_DEFS" ]; then
        # Backup
        if [ "$DRY_RUN" = false ]; then
            cp "$LOGIN_DEFS" "${LOGIN_DEFS}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        update_config "$LOGIN_DEFS" "PASS_MAX_DAYS" "90" "Maximum password age"
        update_config "$LOGIN_DEFS" "PASS_MIN_DAYS" "1" "Minimum password age"
        update_config "$LOGIN_DEFS" "PASS_WARN_AGE" "7" "Password expiration warning"
        update_config "$LOGIN_DEFS" "PASS_MIN_LEN" "14" "Minimum password length"
    else
        log_warning "/etc/login.defs not found"
    fi
}

# Configure PAM password quality requirements
configure_pam_password_quality() {
    log_info "Configuring PAM password quality requirements..."
    
    local PAM_PWQUALITY="/etc/security/pwquality.conf"
    
    if [ -f "$PAM_PWQUALITY" ]; then
        # Backup
        if [ "$DRY_RUN" = false ]; then
            cp "$PAM_PWQUALITY" "${PAM_PWQUALITY}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Password quality settings
        update_config "$PAM_PWQUALITY" "minlen" "=" "14" "Minimum password length"
        update_config "$PAM_PWQUALITY" "dcredit" "=" "-1" "Require at least 1 digit"
        update_config "$PAM_PWQUALITY" "ucredit" "=" "-1" "Require at least 1 uppercase"
        update_config "$PAM_PWQUALITY" "lcredit" "=" "-1" "Require at least 1 lowercase"
        update_config "$PAM_PWQUALITY" "ocredit" "=" "-1" "Require at least 1 special char"
        update_config "$PAM_PWQUALITY" "minclass" "=" "4" "Require 4 character classes"
        update_config "$PAM_PWQUALITY" "maxrepeat" "=" "3" "Max repeated characters"
        update_config "$PAM_PWQUALITY" "maxsequence" "=" "3" "Max sequential characters"
        update_config "$PAM_PWQUALITY" "dictcheck" "=" "1" "Enable dictionary check"
        update_config "$PAM_PWQUALITY" "usercheck" "=" "1" "Check against username"
        update_config "$PAM_PWQUALITY" "enforcing" "=" "1" "Enforce for root too"
    else
        log_warning "/etc/security/pwquality.conf not found - PAM password quality may not be available"
    fi
}

# Lock inactive user accounts
lock_inactive_accounts() {
    log_info "Checking for inactive user accounts..."
    
    local INACTIVE_DAYS=90
    local inactive_users=0
    
    # Get list of users with login shells
    while IFS=: read -r username _ uid _ _ _ shell; do
        # Skip system accounts and users without login shell
        if [ "$uid" -ge 1000 ] && [ "$shell" != "/sbin/nologin" ] && [ "$shell" != "/bin/false" ]; then
            # Check last login
            last_login=$(lastlog -u "$username" 2>/dev/null | tail -n1 | awk '{print $4,$5,$6,$7,$8,$9}')
            
            if [ "$last_login" = "**Never logged in**" ]; then
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would lock account $username (never logged in)"
                    ((CHANGES_PLANNED++))
                    ((inactive_users++))
                else
                    passwd -l "$username" &>/dev/null
                    log_info "Locked account $username (never logged in)"
                    ((CHANGES_MADE++))
                    ((inactive_users++))
                fi
            fi
        fi
    done < /etc/passwd
    
    if [ $inactive_users -eq 0 ]; then
        log_info "No inactive accounts found to lock"
    fi
}

# Set account lockout policy
configure_account_lockout() {
    log_info "Configuring account lockout policy..."
    
    local PAM_FAILLOCK="/etc/security/faillock.conf"
    
    if [ -f "$PAM_FAILLOCK" ]; then
        # Backup
        if [ "$DRY_RUN" = false ]; then
            cp "$PAM_FAILLOCK" "${PAM_FAILLOCK}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        update_config "$PAM_FAILLOCK" "deny" "=" "5" "Lock after 5 failed attempts"
        update_config "$PAM_FAILLOCK" "fail_interval" "=" "900" "15 minute failure window"
        update_config "$PAM_FAILLOCK" "unlock_time" "=" "600" "Unlock after 10 minutes"
        update_config "$PAM_FAILLOCK" "audit" "" "" "Enable audit logging"
    else
        log_warning "/etc/security/faillock.conf not found - account lockout may not be available"
    fi
}

# Secure user home directories
secure_home_directories() {
    log_info "Checking home directory permissions..."
    
    local insecure_homes=0
    
    while IFS=: read -r username _ uid _ _ homedir shell; do
        # Check regular user accounts
        if [ "$uid" -ge 1000 ] && [ -d "$homedir" ]; then
            perms=$(stat -c %a "$homedir" 2>/dev/null)
            
            # Check if permissions are too open (should be 700 or 750)
            if [ "$perms" != "700" ] && [ "$perms" != "750" ]; then
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would change permissions of $homedir from $perms to 750"
                    ((CHANGES_PLANNED++))
                    ((insecure_homes++))
                else
                    chmod 750 "$homedir"
                    log_info "Changed permissions of $homedir from $perms to 750"
                    ((CHANGES_MADE++))
                    ((insecure_homes++))
                fi
            fi
        fi
    done < /etc/passwd
    
    if [ $insecure_homes -eq 0 ]; then
        log_info "All home directories have appropriate permissions"
    fi
}

# Disable unused user accounts
disable_system_accounts() {
    log_info "Ensuring system accounts have no login shell..."
    
    local SYSTEM_ACCOUNTS=("bin" "daemon" "adm" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "systemd-network" "systemd-resolve")
    
    for account in "${SYSTEM_ACCOUNTS[@]}"; do
        if id "$account" &>/dev/null; then
            current_shell=$(getent passwd "$account" | cut -d: -f7)
            if [ "$current_shell" != "/usr/sbin/nologin" ] && [ "$current_shell" != "/sbin/nologin" ] && [ "$current_shell" != "/bin/false" ]; then
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would set shell for $account to /usr/sbin/nologin"
                    ((CHANGES_PLANNED++))
                else
                    usermod -s /usr/sbin/nologin "$account" 2>/dev/null || usermod -s /sbin/nologin "$account" 2>/dev/null
                    log_info "Set shell for $account to nologin"
                    ((CHANGES_MADE++))
                fi
            fi
        fi
    done
}

# Set umask
configure_umask() {
    log_info "Configuring default umask..."
    
    local files=("/etc/bashrc" "/etc/profile" "/etc/bash.bashrc")
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            if ! grep -q "umask 027" "$file"; then
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would set umask to 027 in $file"
                    ((CHANGES_PLANNED++))
                else
                    echo "umask 027" >> "$file"
                    log_info "Set umask to 027 in $file"
                    ((CHANGES_MADE++))
                fi
            fi
        fi
    done
}

# Main execution
configure_password_aging
configure_pam_password_quality
configure_account_lockout
lock_inactive_accounts
secure_home_directories
disable_system_accounts
configure_umask

# Summary
log_info "=== USER SECURITY HARDENING SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_info "User security hardening completed: ${CHANGES_MADE} changes applied"
    log_warning "Users will be prompted to change passwords on next login if policy violations exist"
fi

exit 0
