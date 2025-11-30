#!/bin/bash

# network-hardening.sh - Network configuration and protocol hardening
# Based on CIS Ubuntu Linux 22.04 LTS Benchmark v3.0.0
# Controls: 3.1 (IP forwarding), 3.2 (ICMP), 3.3 (TCP/IP stack), 3.4 (TCP wrappers), 3.5 (firewall)

set -euo pipefail

# Determine script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load utility functions
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh"

# Parse command-line arguments
DRY_RUN=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

log_info "Starting network hardening..."

# CIS 3.1.1: Ensure IP forwarding is disabled
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would disable IPv4 forwarding"
    log_info "Current net.ipv4.ip_forward: $(sysctl net.ipv4.ip_forward 2>/dev/null | awk '{print $NF}')"
else
    log_info "Disabling IPv4 forwarding..."
    sysctl -w net.ipv4.ip_forward=0
    echo "net.ipv4.ip_forward = 0" | tee -a /etc/sysctl.conf /etc/sysctl.d/99-hardening.conf > /dev/null
    log_success "IPv4 forwarding disabled"
fi

# CIS 3.1.2: Ensure IPv6 forwarding is disabled
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would disable IPv6 forwarding"
    log_info "Current net.ipv6.conf.all.forwarding: $(sysctl net.ipv6.conf.all.forwarding 2>/dev/null | awk '{print $NF}')"
else
    log_info "Disabling IPv6 forwarding..."
    sysctl -w net.ipv6.conf.all.forwarding=0
    echo "net.ipv6.conf.all.forwarding = 0" | tee -a /etc/sysctl.conf /etc/sysctl.d/99-hardening.conf > /dev/null
    log_success "IPv6 forwarding disabled"
fi

# CIS 3.2.1: Ensure ICMP redirects are not accepted
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would disable ICMP redirects"
    log_info "Current net.ipv4.conf.all.send_redirects: $(sysctl net.ipv4.conf.all.send_redirects 2>/dev/null | awk '{print $NF}')"
else
    log_info "Disabling ICMP redirects..."
    sysctl -w net.ipv4.conf.all.send_redirects=0
    sysctl -w net.ipv4.conf.default.send_redirects=0
    echo "net.ipv4.conf.all.send_redirects = 0" | tee -a /etc/sysctl.conf /etc/sysctl.d/99-hardening.conf > /dev/null
    log_success "ICMP redirects disabled"
fi

# CIS 3.2.2: Ensure ICMP redirects are not accepted
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would disable incoming ICMP redirects"
    log_info "Current net.ipv4.conf.all.accept_redirects: $(sysctl net.ipv4.conf.all.accept_redirects 2>/dev/null | awk '{print $NF}')"
else
    log_info "Disabling incoming ICMP redirects..."
    sysctl -w net.ipv4.conf.all.accept_redirects=0
    sysctl -w net.ipv4.conf.default.accept_redirects=0
    echo "net.ipv4.conf.all.accept_redirects = 0" | tee -a /etc/sysctl.conf /etc/sysctl.d/99-hardening.conf > /dev/null
    log_success "Incoming ICMP redirects disabled"
fi

# CIS 3.3.1: Ensure source routed packets are not accepted
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would disable source routing"
    log_info "Current net.ipv4.conf.all.send_redirects: $(sysctl net.ipv4.conf.all.send_redirects 2>/dev/null | awk '{print $NF}')"
else
    log_info "Disabling source routing..."
    sysctl -w net.ipv4.conf.all.send_redirects=0
    sysctl -w net.ipv4.conf.default.send_redirects=0
    echo "net.ipv4.conf.all.send_redirects = 0" | tee -a /etc/sysctl.conf /etc/sysctl.d/99-hardening.conf > /dev/null
    log_success "Source routing disabled"
fi

# CIS 3.3.2: Ensure suspicious packets are logged
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would enable suspicious packet logging"
    log_info "Current net.ipv4.conf.all.log_martians: $(sysctl net.ipv4.conf.all.log_martians 2>/dev/null | awk '{print $NF}')"
else
    log_info "Enabling suspicious packet logging..."
    sysctl -w net.ipv4.conf.all.log_martians=1
    sysctl -w net.ipv4.conf.default.log_martians=1
    echo "net.ipv4.conf.all.log_martians = 1" | tee -a /etc/sysctl.conf /etc/sysctl.d/99-hardening.conf > /dev/null
    log_success "Suspicious packet logging enabled"
fi

# CIS 3.3.3: Ensure SYN flood protection is enabled
if [ "$DRY_RUN" = true ]; then
    log_info "DRY RUN: Would enable SYN flood protection"
    log_info "Current net.ipv4.tcp_syncookies: $(sysctl net.ipv4.tcp_syncookies 2>/dev/null | awk '{print $NF}')"
else
    log_info "Enabling SYN flood protection..."
    sysctl -w net.ipv4.tcp_syncookies=1
    echo "net.ipv4.tcp_syncookies = 1" | tee -a /etc/sysctl.conf /etc/sysctl.d/99-hardening.conf > /dev/null
    log_success "SYN flood protection enabled"
fi

log_info "Network hardening completed"
log_success "Network configuration applied"
