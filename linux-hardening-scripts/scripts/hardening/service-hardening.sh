#!/bin/bash#!/bin/bash



################################################################################# Load utility functions

# Service Hardening Scriptsource ../utils/logger.sh

# Purpose: Disable unnecessary services and secure running servicessource ../utils/validation.sh

# Features: Dry-run mode, console logging, summary reporting

################################################################################# Function to display usage

usage() {

# Source utilities    echo "Usage: $0 [--dry-run]"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    echo "  --dry-run    Preview changes without applying them"

source "${SCRIPT_DIR}/../utils/logger.sh" 2>/dev/null || {    exit 1

    echo "ERROR: Cannot load logger.sh"}

    exit 1

}# Check for arguments

DRY_RUN=false

# Configurationwhile [[ "$1" != "" ]]; do

DRY_RUN=false    case $1 in

CHANGES_MADE=0        --dry-run )    DRY_RUN=true

CHANGES_PLANNED=0                       ;;

        * )            usage

# Parse arguments                       ;;

while [[ "$#" -gt 0 ]]; do    esac

    case $1 in    shift

        --dry-run) DRY_RUN=true ;;done

        *) echo "Unknown parameter: $1"; exit 1 ;;

    esac# Start logging

    shiftlog_info "Starting service hardening script..."

done

# List of services to disable (example)

# InitializeSERVICES_TO_DISABLE=("telnet" "ftp" "rsh")

if [ "$DRY_RUN" = true ]; then

    log_info "=== SERVICE HARDENING (DRY RUN MODE) ==="# Function to disable services

elsedisable_service() {

    log_info "=== SERVICE HARDENING ==="    local service=$1

fi    if $DRY_RUN; then

        log_info "Dry run: Would disable service $service"

# Check if running as root    else

if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then        systemctl stop $service

    log_error "This script must be run as root (use sudo)"        systemctl disable $service

    exit 1        log_info "Disabled service $service"

fi    fi

}

# List of potentially unnecessary services to disable

SERVICES_TO_DISABLE=(# Disable unnecessary services

    "avahi-daemon"      # Zero-configuration networkingfor service in "${SERVICES_TO_DISABLE[@]}"; do

    "cups"              # Printing service    disable_service $service

    "isc-dhcp-server"   # DHCP serverdone

    "isc-dhcp-server6"  # DHCPv6 server

    "nfs-server"        # NFS server# Log completion

    "rpcbind"           # RPC bind servicelog_info "Service hardening completed."

    "rsync"             # Rsync daemon

    "snmpd"             # SNMP daemon# Summary log

    "telnet"            # Telnet serverif ! $DRY_RUN; then

    "tftp"              # TFTP server    log_summary "Service hardening completed successfully."

    "vsftpd"            # FTP serverfi
    "xinetd"            # Internet super-server
    "ypserv"            # NIS server
    "rsh.socket"        # Remote shell
    "rlogin.socket"     # Remote login
    "rexec.socket"      # Remote execution
    "ntalk"             # Talk daemon
    "autofs"            # Automount service
)

# Essential services that should typically remain enabled
ESSENTIAL_SERVICES=(
    "sshd"
    "ssh"
    "systemd-timesyncd"
    "cron"
    "crond"
    "rsyslog"
    "syslog"
)

# Function to check if service exists
service_exists() {
    local service="$1"
    systemctl list-unit-files | grep -q "^${service}" 2>/dev/null
    return $?
}

# Function to check if service is enabled
service_is_enabled() {
    local service="$1"
    systemctl is-enabled "$service" &>/dev/null
    return $?
}

# Function to check if service is active
service_is_active() {
    local service="$1"
    systemctl is-active "$service" &>/dev/null
    return $?
}

# Function to disable and stop service
disable_service() {
    local service="$1"
    
    if ! service_exists "$service"; then
        return
    fi
    
    if service_is_enabled "$service" || service_is_active "$service"; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would disable and stop service: $service"
            ((CHANGES_PLANNED++))
        else
            systemctl stop "$service" &>/dev/null
            systemctl disable "$service" &>/dev/null
            log_info "Disabled and stopped service: $service"
            ((CHANGES_MADE++))
        fi
    fi
}

# Disable unnecessary services
disable_unnecessary_services() {
    log_info "Checking for unnecessary services to disable..."
    
    local services_found=0
    
    for service in "${SERVICES_TO_DISABLE[@]}"; do
        if service_exists "$service"; then
            ((services_found++))
            disable_service "$service"
        fi
    done
    
    if [ $services_found -eq 0 ]; then
        log_info "No unnecessary services found to disable"
    fi
}

# Verify essential services are running
verify_essential_services() {
    log_info "Verifying essential services..."
    
    for service in "${ESSENTIAL_SERVICES[@]}"; do
        if service_exists "$service"; then
            if service_is_active "$service"; then
                log_info "Essential service $service is running"
            else
                log_warning "Essential service $service is NOT running"
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would attempt to start $service"
                else
                    log_warning "Consider starting $service: sudo systemctl start $service"
                fi
            fi
        fi
    done
}

# Disable IPv6 if not needed
disable_ipv6() {
    log_info "Checking IPv6 configuration..."
    
    local GRUB_FILE="/etc/default/grub"
    
    # This is commented out by default - uncomment if you want to disable IPv6
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] IPv6 disabling is optional (currently disabled in script)"
    else
        log_info "IPv6 disabling is commented out by default"
        log_warning "Edit this script to enable IPv6 disabling if needed"
    fi
    
    # Uncomment below to disable IPv6
    # if [ -f "$GRUB_FILE" ]; then
    #     if ! grep -q "ipv6.disable=1" "$GRUB_FILE"; then
    #         if [ "$DRY_RUN" = true ]; then
    #             log_info "[DRY RUN] Would disable IPv6 in GRUB config"
    #             ((CHANGES_PLANNED++))
    #         else
    #             sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="ipv6.disable=1 /' "$GRUB_FILE"
    #             update-grub 2>/dev/null || grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null
    #             log_info "Disabled IPv6 in GRUB config"
    #             ((CHANGES_MADE++))
    #         fi
    #     fi
    # fi
}

# Audit running services
audit_running_services() {
    log_info "Auditing currently running services..."
    
    local running_services=$(systemctl list-units --type=service --state=running --no-pager --no-legend | wc -l)
    log_info "Total running services: $running_services"
    
    # List network-listening services
    log_info "Services listening on network ports:"
    if command -v ss &> /dev/null; then
        ss -tulpn 2>/dev/null | grep LISTEN | awk '{print $7}' | sort -u | while read -r line; do
            if [ -n "$line" ]; then
                log_info "  - $line"
            fi
        done
    elif command -v netstat &> /dev/null; then
        netstat -tulpn 2>/dev/null | grep LISTEN | awk '{print $7}' | sort -u | while read -r line; do
            if [ -n "$line" ]; then
                log_info "  - $line"
            fi
        done
    else
        log_warning "Neither ss nor netstat available for network audit"
    fi
}

# Secure service configurations
secure_service_configs() {
    log_info "Checking service configuration security..."
    
    # Ensure systemd services run with minimal privileges
    # This is informational - manual review required
    log_info "Consider reviewing systemd service files for:"
    log_info "  - PrivateTmp=yes"
    log_info "  - NoNewPrivileges=yes"
    log_info "  - ProtectSystem=strict"
    log_info "  - ProtectHome=yes"
    log_info "  - ReadOnlyPaths=/"
}

# Check for services running as root
check_root_services() {
    log_info "Checking for services running as root..."
    
    local root_services=0
    
    # Get processes running as root with a listening port
    if command -v ss &> /dev/null; then
        root_services=$(ss -tulpn 2>/dev/null | grep -i "root" | wc -l)
    elif command -v netstat &> /dev/null; then
        root_services=$(netstat -tulpn 2>/dev/null | grep -i "root" | wc -l)
    fi
    
    if [ "$root_services" -gt 0 ]; then
        log_warning "Found $root_services network services running as root"
        log_warning "Review these services and consider running them with lower privileges"
    else
        log_info "No network services running as root detected"
    fi
}

# Disable legacy services via xinetd/inetd
disable_legacy_services() {
    log_info "Checking for legacy inet services..."
    
    local XINETD_DIR="/etc/xinetd.d"
    local INETD_CONF="/etc/inetd.conf"
    
    if [ -d "$XINETD_DIR" ]; then
        local xinetd_services=$(find "$XINETD_DIR" -type f | wc -l)
        if [ "$xinetd_services" -gt 0 ]; then
            log_warning "Found $xinetd_services xinetd service configurations"
            log_warning "Review and disable unnecessary services in $XINETD_DIR"
        fi
    fi
    
    if [ -f "$INETD_CONF" ]; then
        local enabled_inetd=$(grep -v "^#" "$INETD_CONF" | grep -v "^$" | wc -l)
        if [ "$enabled_inetd" -gt 0 ]; then
            log_warning "Found $enabled_inetd enabled inetd services"
            log_warning "Review and disable unnecessary services in $INETD_CONF"
        fi
    fi
}

# Main execution
disable_unnecessary_services
verify_essential_services
disable_ipv6
audit_running_services
secure_service_configs
check_root_services
disable_legacy_services

# Summary
log_info "=== SERVICE HARDENING SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_info "Service hardening completed: ${CHANGES_MADE} changes applied"
    log_warning "Review the audit information above for additional manual hardening"
    log_warning "Restart affected services or reboot system for changes to take effect"
fi

exit 0
