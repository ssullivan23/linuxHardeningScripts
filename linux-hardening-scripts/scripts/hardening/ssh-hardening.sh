#!/bin/bash

################################################################################
# SSH Hardening Script
# Purpose: Secure SSH configuration to prevent unauthorized access
# Features: Dry-run mode, console logging, summary reporting
################################################################################

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../utils/logger.sh" 2>/dev/null || {
    echo "ERROR: Cannot load logger.sh"
    exit 1
}

# Configuration
DRY_RUN=false
SSH_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG_BACKUP="${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
CHANGES_MADE=0
CHANGES_PLANNED=0

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Initialize
if [ "$DRY_RUN" = true ]; then
    log_info "=== SSH HARDENING (DRY RUN MODE) ==="
else
    log_info "=== SSH HARDENING ==="
fi

# Function to update SSH config parameter
update_ssh_config() {
    local param="$1"
    local value="$2"
    local description="$3"
    
    if grep -q "^${param}" "$SSH_CONFIG" 2>/dev/null; then
        current_value=$(grep "^${param}" "$SSH_CONFIG" | awk '{print $2}')
        if [ "$current_value" != "$value" ]; then
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY RUN] Would change ${param} from '${current_value}' to '${value}' - ${description}"
                ((CHANGES_PLANNED++))
            else
                sed -i "s/^${param}.*/${param} ${value}/" "$SSH_CONFIG"
                log_info "Changed ${param} from '${current_value}' to '${value}' - ${description}"
                ((CHANGES_MADE++))
            fi
        else
            log_info "${param} already set to '${value}' - ${description}"
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would add ${param} ${value} - ${description}"
            ((CHANGES_PLANNED++))
        else
            echo "${param} ${value}" >> "$SSH_CONFIG"
            log_info "Added ${param} ${value} - ${description}"
            ((CHANGES_MADE++))
        fi
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Backup SSH config
if [ "$DRY_RUN" = false ]; then
    if [ -f "$SSH_CONFIG" ]; then
        cp "$SSH_CONFIG" "$SSH_CONFIG_BACKUP"
        log_info "Backed up SSH config to ${SSH_CONFIG_BACKUP}"
    fi
fi

# Apply SSH hardening measures
log_info "Applying SSH security hardening..."

# Disable root login
update_ssh_config "PermitRootLogin" "no" "Prevents direct root SSH access"

# Disable password authentication (use keys only)
update_ssh_config "PasswordAuthentication" "no" "Forces SSH key authentication"

# Disable empty passwords
update_ssh_config "PermitEmptyPasswords" "no" "Prevents login with empty passwords"

# Disable X11 forwarding
update_ssh_config "X11Forwarding" "no" "Reduces attack surface"

# Use protocol 2 only
update_ssh_config "Protocol" "2" "Uses more secure SSH protocol version"

# Set login grace time
update_ssh_config "LoginGraceTime" "60" "Limits time to authenticate"

# Maximum authentication attempts
update_ssh_config "MaxAuthTries" "3" "Limits brute force attempts"

# Maximum sessions
update_ssh_config "MaxSessions" "2" "Limits concurrent sessions per connection"

# Disable host-based authentication
update_ssh_config "HostbasedAuthentication" "no" "Prevents host-based auth"

# Ignore rhosts
update_ssh_config "IgnoreRhosts" "yes" "Ignores legacy rhosts files"

# Enable strict mode
update_ssh_config "StrictModes" "yes" "Checks file permissions before login"

# Disable challenge-response auth
update_ssh_config "ChallengeResponseAuthentication" "no" "Disables keyboard-interactive auth"

# Disable unused authentication methods
update_ssh_config "KerberosAuthentication" "no" "Disables Kerberos if not used"
update_ssh_config "GSSAPIAuthentication" "no" "Disables GSSAPI if not used"

# Set strong ciphers
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would configure strong cipher suites"
    ((CHANGES_PLANNED++))
else
    if ! grep -q "^Ciphers" "$SSH_CONFIG"; then
        echo "Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr" >> "$SSH_CONFIG"
        log_info "Configured strong cipher suites"
        ((CHANGES_MADE++))
    fi
fi

# Set strong MACs
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would configure strong MAC algorithms"
    ((CHANGES_PLANNED++))
else
    if ! grep -q "^MACs" "$SSH_CONFIG"; then
        echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256" >> "$SSH_CONFIG"
        log_info "Configured strong MAC algorithms"
        ((CHANGES_MADE++))
    fi
fi

# Set strong key exchange algorithms
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would configure strong key exchange algorithms"
    ((CHANGES_PLANNED++))
else
    if ! grep -q "^KexAlgorithms" "$SSH_CONFIG"; then
        echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256" >> "$SSH_CONFIG"
        log_info "Configured strong key exchange algorithms"
        ((CHANGES_MADE++))
    fi
fi

# Set client alive interval (prevents idle disconnection attacks)
update_ssh_config "ClientAliveInterval" "300" "Sets keep-alive interval to 5 minutes"
update_ssh_config "ClientAliveCountMax" "2" "Disconnects after 2 failed keep-alives"

# Disable TCP forwarding if not needed
update_ssh_config "AllowTcpForwarding" "no" "Disables TCP port forwarding"

# Disable agent forwarding
update_ssh_config "AllowAgentForwarding" "no" "Disables SSH agent forwarding"

# Set banner
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would set login banner"
else
    if [ ! -f "/etc/ssh/banner" ]; then
        cat > /etc/ssh/banner << 'EOF'
***************************************************************************
                            AUTHORIZED ACCESS ONLY
***************************************************************************
Unauthorized access to this system is forbidden and will be prosecuted.
All connections are monitored and recorded.
***************************************************************************
EOF
        update_ssh_config "Banner" "/etc/ssh/banner" "Sets warning banner"
    fi
fi

# Validate SSH config
if [ "$DRY_RUN" = false ]; then
    log_info "Validating SSH configuration..."
    validation_output=$(sshd -t 2>&1)
    validation_result=$?
    
    if [ $validation_result -eq 0 ]; then
        log_success "SSH configuration syntax is valid"
    else
        log_error "SSH configuration syntax error detected!"
        log_error "Error details: $validation_output"
        log_warning "Restoring backup..."
        cp "$SSH_CONFIG_BACKUP" "$SSH_CONFIG"
        exit 1
    fi
fi

# Summary
log_info "=== SSH HARDENING SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_info "Hardening completed: ${CHANGES_MADE} changes applied"
    log_info "Backup saved to: ${SSH_CONFIG_BACKUP}"
    log_warning "Remember to restart SSH service: sudo systemctl restart sshd"
    log_warning "IMPORTANT: Test SSH access in a new session before closing current connection!"
fi

exit 0