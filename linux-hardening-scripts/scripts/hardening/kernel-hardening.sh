#!/bin/bash#!/bin/bash



################################################################################# kernel-hardening.sh - Script to implement kernel hardening measures

# Kernel Hardening Script

# Purpose: Configure kernel parameters for enhanced security# Load logger utility

# Features: Dry-run mode, console logging, summary reportingsource ../utils/logger.sh

################################################################################

# Function to display usage

# Source utilitiesusage() {

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    echo "Usage: $0 [--dry-run]"

source "${SCRIPT_DIR}/../utils/logger.sh" 2>/dev/null || {    echo "  --dry-run    Show what changes would be made without applying them"

    echo "ERROR: Cannot load logger.sh"    exit 1

    exit 1}

}

# Check for dry run flag

# ConfigurationDRY_RUN=false

DRY_RUN=falseif [[ "$1" == "--dry-run" ]]; then

CHANGES_MADE=0    DRY_RUN=true

CHANGES_PLANNED=0fi

SYSCTL_CONF="/etc/sysctl.d/99-hardening.conf"

# Log start of the script

# Parse argumentslog_info "Starting kernel hardening script..."

while [[ "$#" -gt 0 ]]; do

    case $1 in# Function to disable unused kernel modules

        --dry-run) DRY_RUN=true ;;disable_unused_modules() {

        *) echo "Unknown parameter: $1"; exit 1 ;;    log_info "Disabling unused kernel modules..."

    esac    # Example of modules to disable

    shift    local modules=("module1" "module2")

done    

    for module in "${modules[@]}"; do

# Initialize        if $DRY_RUN; then

if [ "$DRY_RUN" = true ]; then            log_info "Dry run: Would disable $module"

    log_info "=== KERNEL HARDENING (DRY RUN MODE) ==="        else

else            modprobe -r "$module" && log_info "Disabled $module"

    log_info "=== KERNEL HARDENING ==="        fi

fi    done

}

# Check if running as root

if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then# Function to configure sysctl parameters

    log_error "This script must be run as root (use sudo)"configure_sysctl() {

    exit 1    log_info "Configuring sysctl parameters..."

fi    # Example sysctl parameters

    local params=("kernel.randomize_va_space=2" "net.ipv4.conf.all.rp_filter=1")

# Function to set sysctl parameter    

set_sysctl() {    for param in "${params[@]}"; do

    local param="$1"        if $DRY_RUN; then

    local value="$2"            log_info "Dry run: Would set $param"

    local description="$3"        else

                sysctl -w "$param" && log_info "Set $param"

    current_value=$(sysctl -n "$param" 2>/dev/null)        fi

        done

    if [ "$current_value" != "$value" ]; then}

        if [ "$DRY_RUN" = true ]; then

            log_info "[DRY RUN] Would set $param = $value - $description"# Execute functions

            ((CHANGES_PLANNED++))disable_unused_modules

        elseconfigure_sysctl

            # Set immediately

            sysctl -w "$param=$value" &>/dev/null# Log end of the script

            log_info "Kernel hardening script completed."

            # Make persistent

            if ! grep -q "^$param" "$SYSCTL_CONF" 2>/dev/null; then# Summary log

                echo "$param = $value" >> "$SYSCTL_CONF"log_summary "Kernel hardening measures applied."
            else
                sed -i "s|^$param.*|$param = $value|" "$SYSCTL_CONF"
            fi
            
            log_info "Set $param = $value - $description"
            ((CHANGES_MADE++))
        fi
    else
        log_info "$param already set to $value"
    fi
}

# Create sysctl config file if it doesn't exist
if [ "$DRY_RUN" = false ]; then
    if [ ! -f "$SYSCTL_CONF" ]; then
        touch "$SYSCTL_CONF"
        log_info "Created $SYSCTL_CONF"
    fi
fi

# Network security parameters
configure_network_security() {
    log_info "Configuring network security parameters..."
    
    # IP forwarding
    set_sysctl "net.ipv4.ip_forward" "0" "Disable IP forwarding"
    set_sysctl "net.ipv6.conf.all.forwarding" "0" "Disable IPv6 forwarding"
    
    # Source packet routing
    set_sysctl "net.ipv4.conf.all.send_redirects" "0" "Disable send redirects"
    set_sysctl "net.ipv4.conf.default.send_redirects" "0" "Disable send redirects (default)"
    
    # Accept source routing
    set_sysctl "net.ipv4.conf.all.accept_source_route" "0" "Disable source routing"
    set_sysctl "net.ipv4.conf.default.accept_source_route" "0" "Disable source routing (default)"
    set_sysctl "net.ipv6.conf.all.accept_source_route" "0" "Disable IPv6 source routing"
    set_sysctl "net.ipv6.conf.default.accept_source_route" "0" "Disable IPv6 source routing (default)"
    
    # Accept ICMP redirects
    set_sysctl "net.ipv4.conf.all.accept_redirects" "0" "Disable ICMP redirects"
    set_sysctl "net.ipv4.conf.default.accept_redirects" "0" "Disable ICMP redirects (default)"
    set_sysctl "net.ipv6.conf.all.accept_redirects" "0" "Disable IPv6 ICMP redirects"
    set_sysctl "net.ipv6.conf.default.accept_redirects" "0" "Disable IPv6 ICMP redirects (default)"
    
    # Secure ICMP redirects
    set_sysctl "net.ipv4.conf.all.secure_redirects" "0" "Disable secure ICMP redirects"
    set_sysctl "net.ipv4.conf.default.secure_redirects" "0" "Disable secure ICMP redirects (default)"
    
    # Log martians
    set_sysctl "net.ipv4.conf.all.log_martians" "1" "Log martian packets"
    set_sysctl "net.ipv4.conf.default.log_martians" "1" "Log martian packets (default)"
    
    # Ignore broadcast requests
    set_sysctl "net.ipv4.icmp_echo_ignore_broadcasts" "1" "Ignore ICMP broadcast"
    
    # Ignore bogus error responses
    set_sysctl "net.ipv4.icmp_ignore_bogus_error_responses" "1" "Ignore bogus ICMP errors"
    
    # Reverse path filtering
    set_sysctl "net.ipv4.conf.all.rp_filter" "1" "Enable reverse path filtering"
    set_sysctl "net.ipv4.conf.default.rp_filter" "1" "Enable reverse path filtering (default)"
    
    # TCP SYN cookies
    set_sysctl "net.ipv4.tcp_syncookies" "1" "Enable TCP SYN cookies (SYN flood protection)"
    
    # IPv6 router advertisements
    set_sysctl "net.ipv6.conf.all.accept_ra" "0" "Disable IPv6 router advertisements"
    set_sysctl "net.ipv6.conf.default.accept_ra" "0" "Disable IPv6 router advertisements (default)"
}

# Kernel security parameters
configure_kernel_security() {
    log_info "Configuring kernel security parameters..."
    
    # Address space layout randomization
    set_sysctl "kernel.randomize_va_space" "2" "Enable full ASLR"
    
    # Restrict dmesg
    set_sysctl "kernel.dmesg_restrict" "1" "Restrict dmesg to root"
    
    # Restrict kernel pointers
    set_sysctl "kernel.kptr_restrict" "2" "Hide kernel pointers"
    
    # Restrict performance events
    set_sysctl "kernel.perf_event_paranoid" "3" "Restrict performance events"
    
    # Restrict kernel logs
    set_sysctl "kernel.printk" "3 3 3 3" "Restrict kernel log levels"
    
    # Restrict BPF JIT compiler
    if sysctl -a 2>/dev/null | grep -q "net.core.bpf_jit_harden"; then
        set_sysctl "net.core.bpf_jit_harden" "2" "Harden BPF JIT compiler"
    fi
    
    # Disable kexec
    if sysctl -a 2>/dev/null | grep -q "kernel.kexec_load_disabled"; then
        set_sysctl "kernel.kexec_load_disabled" "1" "Disable kexec"
    fi
    
    # Restrict module loading
    if sysctl -a 2>/dev/null | grep -q "kernel.modules_disabled"; then
        log_warning "kernel.modules_disabled can only be set once until reboot"
        log_warning "Manual intervention: Set 'kernel.modules_disabled = 1' after boot is complete"
    fi
    
    # Yama ptrace scope
    if sysctl -a 2>/dev/null | grep -q "kernel.yama.ptrace_scope"; then
        set_sysctl "kernel.yama.ptrace_scope" "1" "Restrict ptrace to parent processes"
    fi
}

# Filesystem security parameters
configure_filesystem_security() {
    log_info "Configuring filesystem security parameters..."
    
    # Protected hardlinks
    set_sysctl "fs.protected_hardlinks" "1" "Enable protected hardlinks"
    
    # Protected symlinks
    set_sysctl "fs.protected_symlinks" "1" "Enable protected symlinks"
    
    # Protected FIFOs
    if sysctl -a 2>/dev/null | grep -q "fs.protected_fifos"; then
        set_sysctl "fs.protected_fifos" "2" "Enable protected FIFOs"
    fi
    
    # Protected regular files
    if sysctl -a 2>/dev/null | grep -q "fs.protected_regular"; then
        set_sysctl "fs.protected_regular" "2" "Enable protected regular files"
    fi
    
    # SUID core dumps
    set_sysctl "fs.suid_dumpable" "0" "Disable SUID core dumps"
}

# Disable unused kernel modules
disable_unused_modules() {
    log_info "Disabling unused kernel modules..."
    
    local MODPROBE_FILE="/etc/modprobe.d/hardening-modules.conf"
    local MODULES=(
        "dccp"      # Datagram Congestion Control Protocol
        "sctp"      # Stream Control Transmission Protocol
        "rds"       # Reliable Datagram Sockets
        "tipc"      # Transparent Inter-Process Communication
        "n-hdlc"    # High-level Data Link Control
        "ax25"      # Amateur Radio X.25
        "netrom"    # NET/ROM
        "x25"       # X.25
        "rose"      # ROSE packet radio
        "decnet"    # DECnet
        "econet"    # Econet
        "af_802154" # IEEE 802.15.4
        "ipx"       # IPX
        "appletalk" # AppleTalk
        "psnap"     # PSNAP
        "p8023"     # Ethernet protocol
        "p8022"     # IEEE 802.2
        "can"       # Controller Area Network
        "atm"       # ATM
    )
    
    if [ "$DRY_RUN" = false ]; then
        if [ ! -f "$MODPROBE_FILE" ]; then
            touch "$MODPROBE_FILE"
        fi
    fi
    
    for module in "${MODULES[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would disable $module module"
            ((CHANGES_PLANNED++))
        else
            if ! grep -q "install $module /bin/true" "$MODPROBE_FILE" 2>/dev/null; then
                echo "install $module /bin/true" >> "$MODPROBE_FILE"
                log_info "Disabled $module module"
                ((CHANGES_MADE++))
            fi
        fi
    done
}

# Disable USB storage
disable_usb_storage() {
    log_info "Checking USB storage configuration..."
    
    local MODPROBE_FILE="/etc/modprobe.d/hardening-usb.conf"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would disable USB storage (optional)"
        log_warning "[DRY RUN] Uncomment in script to enable USB storage disabling"
    else
        log_warning "USB storage disabling is commented out by default"
        log_warning "Uncomment in script if you want to disable USB storage"
        # Uncomment below to disable USB storage
        # if [ ! -f "$MODPROBE_FILE" ]; then
        #     touch "$MODPROBE_FILE"
        # fi
        # if ! grep -q "install usb-storage /bin/true" "$MODPROBE_FILE" 2>/dev/null; then
        #     echo "install usb-storage /bin/true" >> "$MODPROBE_FILE"
        #     log_info "Disabled USB storage"
        #     ((CHANGES_MADE++))
        # fi
    fi
}

# Main execution
configure_network_security
configure_kernel_security
configure_filesystem_security
disable_unused_modules
disable_usb_storage

# Apply sysctl changes
if [ "$DRY_RUN" = false ]; then
    sysctl -p "$SYSCTL_CONF" &>/dev/null
    log_info "Applied sysctl configuration"
fi

# Summary
log_info "=== KERNEL HARDENING SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_info "Kernel hardening completed: ${CHANGES_MADE} changes applied"
    log_info "Configuration saved to: $SYSCTL_CONF"
    log_warning "Some changes may require a system reboot to take full effect"
fi

exit 0
