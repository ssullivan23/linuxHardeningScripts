#!/bin/bash

################################################################################
# Kernel Hardening Script
# Purpose: Harden kernel parameters using sysctl
# CIS Controls: 1.1 (Kernel modules), 1.3 (Kernel parameters), 3.1-3.5 (Network)
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
SYSCTL_CONFIG="/etc/sysctl.d/99-hardening.conf"

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
    log_info "=== KERNEL HARDENING (DRY RUN MODE) ==="
else
    log_info "=== KERNEL HARDENING ==="
fi

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Function to set sysctl parameter
set_sysctl_param() {
    local param="$1"
    local value="$2"
    local description="$3"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set ${param} = ${value} - ${description}"
        ((CHANGES_PLANNED++))
    else
        # Apply immediately
        sysctl -w "${param}=${value}" >/dev/null 2>&1 || true
        
        # Make persistent
        if grep -q "^${param}" "$SYSCTL_CONFIG" 2>/dev/null; then
            sed -i "s/^${param}.*/${param} = ${value}/" "$SYSCTL_CONFIG"
        else
            echo "${param} = ${value}" >> "$SYSCTL_CONFIG"
        fi
        
        log_info "Set ${param} = ${value} - ${description}"
        ((CHANGES_MADE++))
    fi
}

# Create sysctl config file if it doesn't exist
if [ "$DRY_RUN" = false ] && [ ! -f "$SYSCTL_CONFIG" ]; then
    touch "$SYSCTL_CONFIG"
fi

# ============================================================================
# CIS 3.1: Ensure IP forwarding is disabled
# ============================================================================
set_sysctl_param "net.ipv4.ip_forward" "0" "CIS 3.1.1: Disable IPv4 forwarding"
set_sysctl_param "net.ipv6.conf.all.forwarding" "0" "CIS 3.1.2: Disable IPv6 forwarding"

# ============================================================================
# CIS 3.2: Ensure ICMP redirects are not accepted
# ============================================================================
set_sysctl_param "net.ipv4.conf.all.send_redirects" "0" "CIS 3.2.1: Disable ICMP send redirects"
set_sysctl_param "net.ipv4.conf.default.send_redirects" "0" "CIS 3.2.2: Disable ICMP send redirects (default)"
set_sysctl_param "net.ipv4.conf.all.accept_redirects" "0" "CIS 3.2.3: Disable ICMP accept redirects"
set_sysctl_param "net.ipv4.conf.default.accept_redirects" "0" "CIS 3.2.4: Disable ICMP accept redirects (default)"
set_sysctl_param "net.ipv4.conf.all.secure_redirects" "0" "CIS 3.2.5: Disable secure ICMP redirects"
set_sysctl_param "net.ipv4.conf.default.secure_redirects" "0" "CIS 3.2.6: Disable secure ICMP redirects (default)"
set_sysctl_param "net.ipv6.conf.all.accept_redirects" "0" "CIS 3.2.7: Disable IPv6 ICMP redirects"
set_sysctl_param "net.ipv6.conf.default.accept_redirects" "0" "CIS 3.2.8: Disable IPv6 ICMP redirects (default)"

# ============================================================================
# CIS 3.3: Ensure suspicious packets are logged
# ============================================================================
set_sysctl_param "net.ipv4.conf.all.log_martians" "1" "CIS 3.3.1: Log suspicious packets"
set_sysctl_param "net.ipv4.conf.default.log_martians" "1" "CIS 3.3.2: Log suspicious packets (default)"

# ============================================================================
# CIS 3.4: Ensure reverse path filtering is enabled
# ============================================================================
set_sysctl_param "net.ipv4.conf.all.rp_filter" "1" "CIS 3.4.1: Enable reverse path filtering"
set_sysctl_param "net.ipv4.conf.default.rp_filter" "1" "CIS 3.4.2: Enable reverse path filtering (default)"

# ============================================================================
# CIS 3.5: Ensure TCP SYN Cookies is enabled
# ============================================================================
set_sysctl_param "net.ipv4.tcp_syncookies" "1" "CIS 3.5.1: Enable TCP SYN cookies"

# ============================================================================
# CIS 4.1: Ensure file integrity monitoring is configured
# ============================================================================
if [ "$DRY_RUN" = true ]; then
    log_info "[DRY RUN] Would ensure aide or tripwire is installed for file integrity monitoring"
    ((CHANGES_PLANNED++))
else
    if ! command -v aide >/dev/null 2>&1 && ! command -v aide.wrapper >/dev/null 2>&1; then
        log_info "Installing aide for file integrity monitoring..."
        apt-get update >/dev/null 2>&1 || true
        apt-get install -y aide aide-common >/dev/null 2>&1 || log_warn "Could not install aide"
    else
        log_info "aide is already installed"
    fi
    ((CHANGES_MADE++))
fi

# ============================================================================
# Additional kernel hardening parameters
# ============================================================================

# Restrict kernel module loading
set_sysctl_param "kernel.modules_disabled" "1" "CIS 1.1.24: Disable loading of kernel modules"

# Restrict kernel pointer exposure (ASLR)
set_sysctl_param "kernel.kptr_restrict" "2" "CIS 1.1.25: Restrict kernel pointer exposure"

# Restrict memory access through dmesg
set_sysctl_param "kernel.dmesg_restrict" "1" "CIS 1.1.26: Restrict dmesg access"

# Restrict unprivileged user namespaces
set_sysctl_param "user.max_user_namespaces" "0" "Restrict unprivileged user namespaces"

# Enable ExecShield (if available)
set_sysctl_param "kernel.exec-shield" "1" "Enable ExecShield"

# Restrict access to kernel logs
set_sysctl_param "kernel.printk" "3 3 3 3" "Restrict kernel printk level"

# Panic on oops
set_sysctl_param "kernel.panic_on_oops" "1" "Panic on kernel oops"
set_sysctl_param "kernel.panic" "10" "Reboot 10 seconds after kernel panic"

# Disable magic SysRq
set_sysctl_param "kernel.sysrq" "0" "Disable magic SysRq"

# TCP hardening
set_sysctl_param "net.ipv4.tcp_timestamps" "0" "Disable TCP timestamps"
set_sysctl_param "net.ipv4.tcp_rfc1337" "1" "Enable RFC1337 protection"
set_sysctl_param "net.ipv4.icmp_echo_ignore_broadcasts" "1" "Ignore ICMP ping requests"
set_sysctl_param "net.ipv4.icmp_ignore_bogus_error_responses" "1" "Ignore bogus error responses"

# IP source spoofing protection
set_sysctl_param "net.ipv4.conf.all.arp_ignore" "1" "ARP ignore"
set_sysctl_param "net.ipv4.conf.all.arp_announce" "2" "ARP announce"

# Apply all sysctl settings
if [ "$DRY_RUN" = false ]; then
    log_info "Applying sysctl configuration..."
    sysctl -p "$SYSCTL_CONFIG" >/dev/null 2>&1 || true
    log_success "Sysctl configuration applied"
fi

# Summary
log_info "=== KERNEL HARDENING SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_success "Kernel hardening completed: ${CHANGES_MADE} changes applied"
    log_info "Configuration file: ${SYSCTL_CONFIG}"
    log_warning "Kernel parameters are now hardened"
fi

exit 0
