#!/bin/bash

################################################################################
# Network Hardening Script
# Purpose: Network configuration and protocol hardening
# Based on CIS Ubuntu Linux 22.04 LTS Benchmark v3.0.0
#
# CIS Controls Covered:
#   3.1 - Disable unused network protocols and devices
#   3.2 - Network parameters (Host only)
#   3.3 - Network parameters (Host and Router)
#
# Note: Firewall configuration (CIS 3.4-3.5) is handled by firewall-setup.sh
################################################################################

# Determine script directory and repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load utility functions
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh" 2>/dev/null || true

# Configuration
DRY_RUN=false
CHANGES_MADE=0
CHANGES_PLANNED=0
SYSCTL_CONF="/etc/sysctl.d/60-cis-network-hardening.conf"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: $0 [--dry-run]"
            echo "  --dry-run    Show what changes would be made without applying them"
            echo ""
            echo "This script implements CIS Ubuntu 22.04 LTS Benchmark Section 3:"
            echo "  3.1 - Disable unused network protocols and devices"
            echo "  3.2 - Network parameters (Host only)"
            echo "  3.3 - Network parameters (Host and Router)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    log_info "=== NETWORK HARDENING (DRY RUN MODE) ==="
else
    log_info "=== NETWORK HARDENING ==="
fi

log_info "Implementing CIS Ubuntu 22.04 LTS Benchmark Section 3"

################################################################################
# CIS 3.1 - Disable unused network protocols and devices
################################################################################

configure_network_protocols() {
    log_info ""
    log_info "CIS 3.1: Configuring network protocols and devices..."
    
    # CIS 3.1.1: Ensure IPv6 status is identified
    # Note: We don't disable IPv6 by default as it may be required
    # Organizations should make this decision based on their needs
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] IPv6 status check - current status:"
        if [ -f /proc/sys/net/ipv6/conf/all/disable_ipv6 ]; then
            local ipv6_status
            ipv6_status=$(cat /proc/sys/net/ipv6/conf/all/disable_ipv6)
            if [ "$ipv6_status" = "1" ]; then
                log_info "  IPv6 is DISABLED"
            else
                log_info "  IPv6 is ENABLED"
            fi
        fi
    else
        log_info "IPv6 status identified (not disabling by default - configure manually if needed)"
    fi
    
    # CIS 3.1.2: Ensure wireless interfaces are disabled
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would check and disable wireless interfaces"
        if command -v nmcli &>/dev/null; then
            local wifi_status
            wifi_status=$(nmcli radio wifi 2>/dev/null || echo "unknown")
            log_info "  Current WiFi status: $wifi_status"
        fi
        ((CHANGES_PLANNED++))
    else
        # Disable wireless if nmcli is available
        if command -v nmcli &>/dev/null; then
            nmcli radio wifi off 2>/dev/null && log_info "Disabled WiFi via nmcli" || true
        fi
        
        # Also try rfkill if available
        if command -v rfkill &>/dev/null; then
            rfkill block wifi 2>/dev/null && log_info "Blocked WiFi via rfkill" || true
            rfkill block bluetooth 2>/dev/null && log_info "Blocked Bluetooth via rfkill" || true
        fi
        
        log_success "Wireless interfaces disabled (if present)"
        ((CHANGES_MADE++))
    fi
    
    # CIS 3.1.3: Ensure bluetooth services are not in use
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would disable Bluetooth service"
        if systemctl is-active bluetooth &>/dev/null; then
            log_info "  Bluetooth service is currently ACTIVE"
        else
            log_info "  Bluetooth service is not active"
        fi
        ((CHANGES_PLANNED++))
    else
        if systemctl is-enabled bluetooth &>/dev/null 2>&1; then
            systemctl stop bluetooth 2>/dev/null || true
            systemctl disable bluetooth 2>/dev/null || true
            systemctl mask bluetooth 2>/dev/null || true
            log_success "Bluetooth service disabled and masked"
            ((CHANGES_MADE++))
        else
            log_info "Bluetooth service not present or already disabled"
        fi
    fi
}

################################################################################
# CIS 3.2 - Network Parameters (Host Only)
################################################################################

configure_host_network_params() {
    log_info ""
    log_info "CIS 3.2: Configuring host network parameters..."
    
    # These parameters apply to systems that are NOT acting as routers
    
    # CIS 3.2.1: Ensure IP forwarding is disabled
    # CIS 3.2.2: Ensure packet redirect sending is disabled
    
    # Parameters are written to sysctl config file in write_sysctl_config()
    log_info "Host-only network parameters will be applied via sysctl"
}

################################################################################
# CIS 3.3 - Network Parameters (Host and Router)
################################################################################

configure_network_params() {
    log_info ""
    log_info "CIS 3.3: Configuring network parameters (host and router)..."
    
    # CIS 3.3.1: Ensure source routed packets are not accepted
    # CIS 3.3.2: Ensure ICMP redirects are not accepted
    # CIS 3.3.3: Ensure secure ICMP redirects are not accepted
    # CIS 3.3.4: Ensure suspicious packets are logged
    # CIS 3.3.5: Ensure broadcast ICMP requests are ignored
    # CIS 3.3.6: Ensure bogus ICMP responses are ignored
    # CIS 3.3.7: Ensure Reverse Path Filtering is enabled
    # CIS 3.3.8: Ensure TCP SYN Cookies is enabled
    # CIS 3.3.9: Ensure IPv6 router advertisements are not accepted
    
    # Parameters are written to sysctl config file in write_sysctl_config()
    log_info "Network parameters will be applied via sysctl"
}

################################################################################
# Write sysctl configuration
################################################################################

write_sysctl_config() {
    log_info ""
    log_info "Writing sysctl configuration to $SYSCTL_CONF..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would create sysctl configuration file with the following settings:"
        cat << 'EOF'

# CIS 3.2.1: Ensure IP forwarding is disabled
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# CIS 3.2.2: Ensure packet redirect sending is disabled
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# CIS 3.3.1: Ensure source routed packets are not accepted
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# CIS 3.3.2: Ensure ICMP redirects are not accepted
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# CIS 3.3.3: Ensure secure ICMP redirects are not accepted
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

# CIS 3.3.4: Ensure suspicious packets are logged
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# CIS 3.3.5: Ensure broadcast ICMP requests are ignored
net.ipv4.icmp_echo_ignore_broadcasts = 1

# CIS 3.3.6: Ensure bogus ICMP responses are ignored
net.ipv4.icmp_ignore_bogus_error_responses = 1

# CIS 3.3.7: Ensure Reverse Path Filtering is enabled
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# CIS 3.3.8: Ensure TCP SYN Cookies is enabled
net.ipv4.tcp_syncookies = 1

# CIS 3.3.9: Ensure IPv6 router advertisements are not accepted
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
EOF
        ((CHANGES_PLANNED++))
        return
    fi
    
    # Backup existing file if present
    if [ -f "$SYSCTL_CONF" ]; then
        cp "$SYSCTL_CONF" "${SYSCTL_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing configuration"
    fi
    
    # Write the sysctl configuration file
    cat > "$SYSCTL_CONF" << 'EOF'
################################################################################
# CIS Ubuntu Linux 22.04 LTS Benchmark - Network Hardening
# Generated by network-hardening.sh
# 
# This file implements CIS Benchmark Section 3 network parameters
# Do not edit manually - changes will be overwritten on next run
################################################################################

#####################################################################
# CIS 3.2.1: Ensure IP forwarding is disabled
# Rationale: Setting IP forwarding allows the system to act as a router
#####################################################################
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

#####################################################################
# CIS 3.2.2: Ensure packet redirect sending is disabled
# Rationale: ICMP Redirects are used by routers to tell hosts about
# more efficient routes. This should be disabled on non-routers.
#####################################################################
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

#####################################################################
# CIS 3.3.1: Ensure source routed packets are not accepted
# Rationale: Source routed packets allow the sender to partially or
# fully specify the route, bypassing router security measures.
#####################################################################
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

#####################################################################
# CIS 3.3.2: Ensure ICMP redirects are not accepted
# Rationale: Attackers could use ICMP redirects to alter host routing
# tables, potentially to subvert traffic flows.
#####################################################################
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

#####################################################################
# CIS 3.3.3: Ensure secure ICMP redirects are not accepted
# Rationale: Secure ICMP redirects are the same as ICMP redirects,
# except they come from gateways listed in the default gateway list.
#####################################################################
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0

#####################################################################
# CIS 3.3.4: Ensure suspicious packets are logged
# Rationale: Logging suspicious packets allows administrators to
# investigate potential security issues.
#####################################################################
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

#####################################################################
# CIS 3.3.5: Ensure broadcast ICMP requests are ignored
# Rationale: Prevents the system from being used in Smurf attacks.
#####################################################################
net.ipv4.icmp_echo_ignore_broadcasts = 1

#####################################################################
# CIS 3.3.6: Ensure bogus ICMP responses are ignored
# Rationale: Some routers violate RFC1122 by sending bogus ICMP
# responses. Logging these fills up logs and wastes resources.
#####################################################################
net.ipv4.icmp_ignore_bogus_error_responses = 1

#####################################################################
# CIS 3.3.7: Ensure Reverse Path Filtering is enabled
# Rationale: Prevents IP spoofing by verifying the source IP address
# is reachable via the interface it was received on.
#####################################################################
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

#####################################################################
# CIS 3.3.8: Ensure TCP SYN Cookies is enabled
# Rationale: Protects against SYN flood attacks by sending SYN cookies
# when the SYN backlog queue fills up.
#####################################################################
net.ipv4.tcp_syncookies = 1

#####################################################################
# CIS 3.3.9: Ensure IPv6 router advertisements are not accepted
# Rationale: Prevents malicious router advertisements from modifying
# the host's routing table.
#####################################################################
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0

################################################################################
# End of CIS Network Hardening Configuration
################################################################################
EOF

    # Verify file was written
    if [ ! -f "$SYSCTL_CONF" ]; then
        log_error "Failed to create $SYSCTL_CONF"
        return 1
    fi
    
    local file_size
    file_size=$(stat -c%s "$SYSCTL_CONF" 2>/dev/null || stat -f%z "$SYSCTL_CONF" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 100 ]; then
        log_error "Configuration file appears empty"
        return 1
    fi
    
    log_success "Created sysctl configuration file ($file_size bytes)"
    ((CHANGES_MADE++))
}

################################################################################
# Apply sysctl settings
################################################################################

apply_sysctl_settings() {
    log_info ""
    log_info "Applying sysctl settings..."
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would apply sysctl settings from $SYSCTL_CONF"
        return
    fi
    
    # Apply settings from our configuration file
    local apply_errors=0
    
    if sysctl -p "$SYSCTL_CONF" 2>&1 | while read -r line; do
        if echo "$line" | grep -qi "error\|cannot\|invalid"; then
            log_warning "  $line"
            ((apply_errors++))
        else
            log_info "  $line"
        fi
    done; then
        log_success "Applied settings from $SYSCTL_CONF"
    else
        log_warning "Some settings may not have been applied"
    fi
    
    # Reload sysctl to ensure all configs are loaded
    if command -v systemctl &>/dev/null; then
        systemctl restart systemd-sysctl.service 2>/dev/null || true
        log_info "Restarted systemd-sysctl service"
    fi
    
    ((CHANGES_MADE++))
}

################################################################################
# Verify settings
################################################################################

verify_settings() {
    log_info ""
    log_info "Verifying applied settings..."
    
    local checks_passed=0
    local checks_failed=0
    
    # Define expected values
    declare -A expected_values=(
        ["net.ipv4.ip_forward"]="0"
        ["net.ipv4.conf.all.send_redirects"]="0"
        ["net.ipv4.conf.all.accept_redirects"]="0"
        ["net.ipv4.conf.all.secure_redirects"]="0"
        ["net.ipv4.conf.all.accept_source_route"]="0"
        ["net.ipv4.conf.all.log_martians"]="1"
        ["net.ipv4.icmp_echo_ignore_broadcasts"]="1"
        ["net.ipv4.icmp_ignore_bogus_error_responses"]="1"
        ["net.ipv4.conf.all.rp_filter"]="1"
        ["net.ipv4.tcp_syncookies"]="1"
    )
    
    for param in "${!expected_values[@]}"; do
        local expected="${expected_values[$param]}"
        local actual
        actual=$(sysctl -n "$param" 2>/dev/null || echo "ERROR")
        
        if [ "$actual" = "$expected" ]; then
            ((checks_passed++))
            if [ "$DRY_RUN" = false ]; then
                log_info "  ✓ $param = $actual"
            fi
        else
            ((checks_failed++))
            log_warning "  ✗ $param = $actual (expected: $expected)"
        fi
    done
    
    log_info ""
    if [ "$checks_failed" -eq 0 ]; then
        log_success "All $checks_passed settings verified successfully"
    else
        log_warning "$checks_passed passed, $checks_failed failed verification"
    fi
}

################################################################################
# Main execution
################################################################################

# Execute configuration functions
configure_network_protocols
configure_host_network_params
configure_network_params
write_sysctl_config

if [ "$DRY_RUN" = false ]; then
    apply_sysctl_settings
fi

verify_settings

################################################################################
# Summary
################################################################################

log_info ""
log_info "═══════════════════════════════════════════════════════════"
log_info "  NETWORK HARDENING SUMMARY"
log_info "═══════════════════════════════════════════════════════════"

if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_success "Network hardening completed: ${CHANGES_MADE} changes applied"
    log_info ""
    log_info "Configuration saved to: $SYSCTL_CONF"
    log_info ""
    log_info "CIS Controls Implemented:"
    log_info "  • 3.1.1 - IPv6 status identified"
    log_info "  • 3.1.2 - Wireless interfaces disabled"
    log_info "  • 3.1.3 - Bluetooth services disabled"
    log_info "  • 3.2.1 - IP forwarding disabled"
    log_info "  • 3.2.2 - Packet redirect sending disabled"
    log_info "  • 3.3.1 - Source routed packets not accepted"
    log_info "  • 3.3.2 - ICMP redirects not accepted"
    log_info "  • 3.3.3 - Secure ICMP redirects not accepted"
    log_info "  • 3.3.4 - Suspicious packets logged"
    log_info "  • 3.3.5 - Broadcast ICMP requests ignored"
    log_info "  • 3.3.6 - Bogus ICMP responses ignored"
    log_info "  • 3.3.7 - Reverse Path Filtering enabled"
    log_info "  • 3.3.8 - TCP SYN Cookies enabled"
    log_info "  • 3.3.9 - IPv6 router advertisements not accepted"
    log_info ""
    log_info "Note: Firewall configuration (CIS 3.4-3.5) is handled by firewall-setup.sh"
    log_info ""
    log_warning "Settings persist across reboots via $SYSCTL_CONF"
    log_warning "Verify network connectivity after applying changes"
fi

log_info "═══════════════════════════════════════════════════════════"

exit 0
