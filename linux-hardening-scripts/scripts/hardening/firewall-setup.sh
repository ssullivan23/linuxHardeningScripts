#!/bin/bash

################################################################################
# Firewall Setup Script
# Purpose: Configure firewall rules using iptables/firewalld
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
QUIET_MODE=false
CHANGES_MADE=0
CHANGES_PLANNED=0
FIREWALL_TYPE=""

# Function to display usage
usage() {
    echo "Usage: $0 [--dry-run] [--quiet]"
    echo "  --dry-run    Show what changes would be made without applying them"
    echo "  --quiet, -q  Minimal output - only show warnings and changes"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --quiet|-q) QUIET_MODE=true ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter: $1"; usage; exit 1 ;;
    esac
    shift
done

# Export QUIET_MODE for logger.sh
export QUIET_MODE

# Initialize
if [ "$DRY_RUN" = true ]; then
    log_info "=== FIREWALL SETUP (DRY RUN MODE) ==="
else
    log_info "=== FIREWALL SETUP ==="
fi

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Detect firewall type
detect_firewall() {
    if command -v firewall-cmd &> /dev/null; then
        FIREWALL_TYPE="firewalld"
        log_info "Detected firewalld"
    elif command -v ufw &> /dev/null; then
        FIREWALL_TYPE="ufw"
        log_info "Detected UFW"
    elif command -v iptables &> /dev/null; then
        FIREWALL_TYPE="iptables"
        log_info "Detected iptables"
    else
        log_error "No supported firewall found (firewalld, ufw, or iptables)"
        exit 1
    fi
}

# Setup firewalld
setup_firewalld() {
    log_info "Configuring firewalld..."

    # Start firewalld service
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would enable and start firewalld service"
        ((CHANGES_PLANNED++))
    else
        systemctl enable firewalld &>/dev/null
        systemctl start firewalld &>/dev/null
        log_info "Enabled and started firewalld"
        ((CHANGES_MADE++))
    fi

    # Set default zone to public
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set default zone to public"
        ((CHANGES_PLANNED++))
    else
        firewall-cmd --set-default-zone=public &>/dev/null
        log_info "Set default zone to public"
        ((CHANGES_MADE++))
    fi

    # Allow SSH
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would allow SSH (port 22)"
        ((CHANGES_PLANNED++))
    else
        firewall-cmd --permanent --add-service=ssh &>/dev/null
        log_info "Allowed SSH service"
        ((CHANGES_MADE++))
    fi

    # Drop invalid packets
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would configure to drop invalid packets"
        ((CHANGES_PLANNED++))
    else
        firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="0.0.0.0/0" drop' &>/dev/null 2>&1
        log_info "Configured invalid packet dropping"
        ((CHANGES_MADE++))
    fi

    # Enable logging for dropped packets
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would enable logging for denied packets"
        ((CHANGES_PLANNED++))
    else
        firewall-cmd --set-log-denied=all &>/dev/null
        log_info "Enabled logging for denied packets"
        ((CHANGES_MADE++))
    fi

    # Reload firewall
    if [ "$DRY_RUN" = false ]; then
        firewall-cmd --reload &>/dev/null
        log_info "Reloaded firewall configuration"
    fi
}

# Setup UFW
setup_ufw() {
    log_info "Configuring UFW..."

    # Set default policies
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set default deny incoming"
        log_info "[DRY RUN] Would set default allow outgoing"
        ((CHANGES_PLANNED+=2))
    else
        ufw default deny incoming &>/dev/null
        ufw default allow outgoing &>/dev/null
        log_info "Set default policies: deny incoming, allow outgoing"
        ((CHANGES_MADE+=2))
    fi

    # Allow SSH
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would allow SSH (port 22)"
        ((CHANGES_PLANNED++))
    else
        ufw allow 22/tcp &>/dev/null
        log_info "Allowed SSH on port 22/tcp"
        ((CHANGES_MADE++))
    fi

    # Enable logging
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would enable firewall logging"
        ((CHANGES_PLANNED++))
    else
        ufw logging on &>/dev/null
        log_info "Enabled UFW logging"
        ((CHANGES_MADE++))
    fi

    # Enable UFW
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would enable UFW"
        ((CHANGES_PLANNED++))
    else
        echo "y" | ufw enable &>/dev/null
        log_info "Enabled UFW"
        ((CHANGES_MADE++))
    fi
}

# Setup iptables
setup_iptables() {
    log_info "Configuring iptables..."

    # Flush existing rules
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would flush existing iptables rules"
        ((CHANGES_PLANNED++))
    else
        iptables -F
        iptables -X
        log_info "Flushed existing rules"
        ((CHANGES_MADE++))
    fi

    # Set default policies
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set default policies to DROP"
        ((CHANGES_PLANNED++))
    else
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -P OUTPUT ACCEPT
        log_info "Set default policies: INPUT DROP, FORWARD DROP, OUTPUT ACCEPT"
        ((CHANGES_MADE++))
    fi

    # Allow loopback
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would allow loopback traffic"
        ((CHANGES_PLANNED++))
    else
        iptables -A INPUT -i lo -j ACCEPT
        log_info "Allowed loopback traffic"
        ((CHANGES_MADE++))
    fi

    # Allow established connections
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would allow established and related connections"
        ((CHANGES_PLANNED++))
    else
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        log_info "Allowed established and related connections"
        ((CHANGES_MADE++))
    fi

    # Allow SSH
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would allow SSH (port 22)"
        ((CHANGES_PLANNED++))
    else
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
        log_info "Allowed SSH on port 22"
        ((CHANGES_MADE++))
    fi

    # Drop invalid packets
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would drop invalid packets"
        ((CHANGES_PLANNED++))
    else
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
        log_info "Configured to drop invalid packets"
        ((CHANGES_MADE++))
    fi

    # Protection against SYN flood
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would enable SYN flood protection"
        ((CHANGES_PLANNED++))
    else
        iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT
        log_info "Enabled SYN flood protection"
        ((CHANGES_MADE++))
    fi

    # Log dropped packets
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would enable logging for dropped packets"
        ((CHANGES_PLANNED++))
    else
        iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables_INPUT_denied: " --log-level 7
        log_info "Enabled logging for dropped packets"
        ((CHANGES_MADE++))
    fi

    # Save rules
    if [ "$DRY_RUN" = false ]; then
        if command -v iptables-save &> /dev/null; then
            if [ -d /etc/iptables ]; then
                iptables-save > /etc/iptables/rules.v4
                log_info "Saved iptables rules to /etc/iptables/rules.v4"
            elif [ -d /etc/sysconfig ]; then
                iptables-save > /etc/sysconfig/iptables
                log_info "Saved iptables rules to /etc/sysconfig/iptables"
            fi
            ((CHANGES_MADE++))
        fi
    else
        log_info "[DRY RUN] Would save iptables rules"
        ((CHANGES_PLANNED++))
    fi
}

# Main execution
detect_firewall

case $FIREWALL_TYPE in
    firewalld)
        setup_firewalld
        ;;
    ufw)
        setup_ufw
        ;;
    iptables)
        setup_iptables
        ;;
esac

# Summary
log_info "=== FIREWALL SETUP SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_info "Firewall setup completed: ${CHANGES_MADE} changes applied"
    log_info "Firewall type: ${FIREWALL_TYPE}"
    log_warning "Verify firewall rules and ensure you can still access the system!"
fi

exit 0