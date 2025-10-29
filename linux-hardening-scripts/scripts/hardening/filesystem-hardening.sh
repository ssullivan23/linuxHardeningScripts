#!/bin/bash#!/bin/bash



################################################################################# File: filesystem-hardening.sh

# Filesystem Hardening Script

# Purpose: Secure filesystem permissions and mount options# Load logger utility

# Features: Dry-run mode, console logging, summary reportingsource ../utils/logger.sh

################################################################################

# Function to display usage

# Source utilitiesusage() {

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    echo "Usage: $0 [--dry-run]"

source "${SCRIPT_DIR}/../utils/logger.sh" 2>/dev/null || {    echo "  --dry-run    Show what changes would be made without applying them."

    echo "ERROR: Cannot load logger.sh"    exit 1

    exit 1}

}

# Check for dry run option

# ConfigurationDRY_RUN=false

DRY_RUN=falseif [[ "$1" == "--dry-run" ]]; then

CHANGES_MADE=0    DRY_RUN=true

CHANGES_PLANNED=0fi



# Parse arguments# Start logging

while [[ "$#" -gt 0 ]]; dolog_info "Starting filesystem hardening script."

    case $1 in

        --dry-run) DRY_RUN=true ;;# Define hardening actions

        *) echo "Unknown parameter: $1"; exit 1 ;;actions=(

    esac    "Setting permissions for /etc/passwd"

    shift    "Setting permissions for /etc/shadow"

done    "Disabling unnecessary filesystems"

)

# Initialize

if [ "$DRY_RUN" = true ]; then# Execute hardening actions

    log_info "=== FILESYSTEM HARDENING (DRY RUN MODE) ==="for action in "${actions[@]}"; do

else    if [ "$DRY_RUN" = true ]; then

    log_info "=== FILESYSTEM HARDENING ==="        log_info "DRY RUN: $action (no changes will be made)"

fi    else

        # Here you would implement the actual command to perform the action

# Check if running as root        log_info "Executing: $action"

if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then        # Example command (uncomment to use):

    log_error "This script must be run as root (use sudo)"        # chmod 640 /etc/passwd

    exit 1        # chmod 640 /etc/shadow

fi    fi

done

# Secure critical file permissions

secure_file_permissions() {# Summary log

    log_info "Securing critical file permissions..."if [ "$DRY_RUN" = true ]; then

        log_info "Dry run completed. No changes were made."

    # Define files and their desired permissionselse

    declare -A file_perms=(    log_info "Filesystem hardening completed successfully."

        ["/etc/passwd"]="644"fi

        ["/etc/shadow"]="000"

        ["/etc/group"]="644"# End logging

        ["/etc/gshadow"]="000"log_info "Filesystem hardening script finished."
        ["/etc/ssh/sshd_config"]="600"
        ["/boot/grub/grub.cfg"]="600"
        ["/boot/grub2/grub.cfg"]="600"
        ["/etc/crontab"]="600"
        ["/etc/cron.deny"]="600"
        ["/etc/at.deny"]="600"
    )
    
    for file in "${!file_perms[@]}"; do
        if [ -f "$file" ]; then
            current_perms=$(stat -c %a "$file" 2>/dev/null)
            desired_perms="${file_perms[$file]}"
            
            if [ "$current_perms" != "$desired_perms" ]; then
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would change $file permissions from $current_perms to $desired_perms"
                    ((CHANGES_PLANNED++))
                else
                    chmod "$desired_perms" "$file"
                    log_info "Changed $file permissions from $current_perms to $desired_perms"
                    ((CHANGES_MADE++))
                fi
            else
                log_info "$file already has correct permissions ($desired_perms)"
            fi
        fi
    done
}

# Disable unused filesystems
disable_unused_filesystems() {
    log_info "Disabling unused filesystems..."
    
    local MODPROBE_FILE="/etc/modprobe.d/hardening.conf"
    local FILESYSTEMS=("cramfs" "freevxfs" "jffs2" "hfs" "hfsplus" "udf" "vfat")
    
    if [ "$DRY_RUN" = false ]; then
        if [ ! -f "$MODPROBE_FILE" ]; then
            touch "$MODPROBE_FILE"
        fi
    fi
    
    for fs in "${FILESYSTEMS[@]}"; do
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would disable $fs filesystem"
            ((CHANGES_PLANNED++))
        else
            if ! grep -q "install $fs /bin/true" "$MODPROBE_FILE" 2>/dev/null; then
                echo "install $fs /bin/true" >> "$MODPROBE_FILE"
                log_info "Disabled $fs filesystem"
                ((CHANGES_MADE++))
            else
                log_info "$fs filesystem already disabled"
            fi
        fi
    done
}

# Secure /tmp with proper mount options
secure_tmp_partition() {
    log_info "Checking /tmp partition security..."
    
    # Check if /tmp is a separate partition
    if mount | grep -q "on /tmp "; then
        current_options=$(mount | grep "on /tmp " | sed 's/.*(\(.*\)).*/\1/')
        
        required_options=("nodev" "nosuid" "noexec")
        missing_options=()
        
        for opt in "${required_options[@]}"; do
            if ! echo "$current_options" | grep -q "$opt"; then
                missing_options+=("$opt")
            fi
        done
        
        if [ ${#missing_options[@]} -gt 0 ]; then
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] /tmp is missing options: ${missing_options[*]}"
                log_info "[DRY RUN] Would add to /etc/fstab and remount"
                ((CHANGES_PLANNED++))
            else
                log_warning "/tmp is missing security options: ${missing_options[*]}"
                log_warning "Manual intervention required: Add 'nodev,nosuid,noexec' to /tmp in /etc/fstab"
                log_warning "Then run: sudo mount -o remount /tmp"
            fi
        else
            log_info "/tmp partition has secure mount options"
        fi
    else
        log_warning "/tmp is not a separate partition - consider creating one"
    fi
}

# Secure /var and /var/tmp
secure_var_partitions() {
    log_info "Checking /var partition security..."
    
    # Check /var/tmp
    if mount | grep -q "on /var/tmp "; then
        current_options=$(mount | grep "on /var/tmp " | sed 's/.*(\(.*\)).*/\1/')
        
        required_options=("nodev" "nosuid" "noexec")
        missing_options=()
        
        for opt in "${required_options[@]}"; do
            if ! echo "$current_options" | grep -q "$opt"; then
                missing_options+=("$opt")
            fi
        done
        
        if [ ${#missing_options[@]} -gt 0 ]; then
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] /var/tmp is missing options: ${missing_options[*]}"
                ((CHANGES_PLANNED++))
            else
                log_warning "/var/tmp is missing security options: ${missing_options[*]}"
                log_warning "Manual intervention required: Add 'nodev,nosuid,noexec' to /var/tmp in /etc/fstab"
            fi
        else
            log_info "/var/tmp partition has secure mount options"
        fi
    fi
}

# Disable core dumps
disable_core_dumps() {
    log_info "Disabling core dumps..."
    
    local LIMITS_FILE="/etc/security/limits.conf"
    local SYSCTL_FILE="/etc/sysctl.d/99-hardening.conf"
    
    # Disable core dumps in limits.conf
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would disable core dumps in $LIMITS_FILE"
        ((CHANGES_PLANNED++))
    else
        if ! grep -q "^\* hard core 0" "$LIMITS_FILE"; then
            echo "* hard core 0" >> "$LIMITS_FILE"
            log_info "Disabled core dumps in $LIMITS_FILE"
            ((CHANGES_MADE++))
        else
            log_info "Core dumps already disabled in $LIMITS_FILE"
        fi
    fi
    
    # Disable core dumps via sysctl
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would set fs.suid_dumpable=0 in sysctl"
        ((CHANGES_PLANNED++))
    else
        if [ ! -f "$SYSCTL_FILE" ]; then
            touch "$SYSCTL_FILE"
        fi
        
        if ! grep -q "^fs.suid_dumpable" "$SYSCTL_FILE"; then
            echo "fs.suid_dumpable = 0" >> "$SYSCTL_FILE"
            sysctl -w fs.suid_dumpable=0 &>/dev/null
            log_info "Set fs.suid_dumpable=0"
            ((CHANGES_MADE++))
        else
            log_info "fs.suid_dumpable already configured"
        fi
    fi
}

# Restrict access to cron
restrict_cron_access() {
    log_info "Restricting cron and at access..."
    
    # Create /etc/cron.allow and /etc/at.allow
    for file in /etc/cron.allow /etc/at.allow; do
        if [ ! -f "$file" ]; then
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY RUN] Would create $file with root access only"
                ((CHANGES_PLANNED++))
            else
                echo "root" > "$file"
                chmod 600 "$file"
                log_info "Created $file with root access only"
                ((CHANGES_MADE++))
            fi
        fi
    done
    
    # Remove cron.deny and at.deny if they exist
    for file in /etc/cron.deny /etc/at.deny; do
        if [ -f "$file" ]; then
            if [ "$DRY_RUN" = true ]; then
                log_info "[DRY RUN] Would remove $file"
                ((CHANGES_PLANNED++))
            else
                rm -f "$file"
                log_info "Removed $file"
                ((CHANGES_MADE++))
            fi
        fi
    done
    
    # Secure cron directories
    local CRON_DIRS=("/etc/cron.d" "/etc/cron.daily" "/etc/cron.hourly" "/etc/cron.monthly" "/etc/cron.weekly")
    
    for dir in "${CRON_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            current_perms=$(stat -c %a "$dir" 2>/dev/null)
            if [ "$current_perms" != "700" ]; then
                if [ "$DRY_RUN" = true ]; then
                    log_info "[DRY RUN] Would set permissions on $dir to 700"
                    ((CHANGES_PLANNED++))
                else
                    chmod 700 "$dir"
                    log_info "Set permissions on $dir to 700"
                    ((CHANGES_MADE++))
                fi
            fi
        fi
    done
}

# Check for world-writable files
check_world_writable_files() {
    log_info "Checking for world-writable files..."
    
    # This is informational only - too dangerous to auto-fix
    local world_writable=$(find / -xdev -type f -perm -002 2>/dev/null | wc -l)
    
    if [ "$world_writable" -gt 0 ]; then
        log_warning "Found $world_writable world-writable files"
        log_warning "Review with: find / -xdev -type f -perm -002 2>/dev/null"
    else
        log_info "No world-writable files found"
    fi
}

# Check for files with no owner
check_unowned_files() {
    log_info "Checking for unowned files..."
    
    local unowned=$(find / -xdev -nouser -o -nogroup 2>/dev/null | wc -l)
    
    if [ "$unowned" -gt 0 ]; then
        log_warning "Found $unowned unowned files"
        log_warning "Review with: find / -xdev \\( -nouser -o -nogroup \\) 2>/dev/null"
    else
        log_info "No unowned files found"
    fi
}

# Main execution
secure_file_permissions
disable_unused_filesystems
secure_tmp_partition
secure_var_partitions
disable_core_dumps
restrict_cron_access
check_world_writable_files
check_unowned_files

# Summary
log_info "=== FILESYSTEM HARDENING SUMMARY ==="
if [ "$DRY_RUN" = true ]; then
    log_info "Dry run completed: ${CHANGES_PLANNED} changes would be made"
    log_warning "Run without --dry-run to apply changes"
else
    log_info "Filesystem hardening completed: ${CHANGES_MADE} changes applied"
    log_warning "Some changes may require a system reboot to take effect"
fi

exit 0
