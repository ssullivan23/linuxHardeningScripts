````markdown
# Linux Hardening Scripts - Usage Guide

This comprehensive guide provides detailed instructions on how to use the Linux hardening scripts for securing your Linux systems.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Getting Started](#getting-started)
3. [Running Scripts](#running-scripts)
4. [Individual Script Usage](#individual-script-usage)
5. [Understanding Output](#understanding-output)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Linux (Ubuntu, Debian, CentOS, RHEL, Fedora, or similar)
- **Shell**: Bash 4.0 or higher
- **Permissions**: Root or sudo access
- **Disk Space**: Minimal (< 10MB for logs and backups)

### Before You Begin

1. **Backup your system** - Create a full system backup or snapshot
2. **Console access** - Ensure you have physical or alternative remote access (not just SSH)
3. **Test environment** - Always test in a non-production environment first
4. **Read the docs** - Review HARDENING_STEPS.md to understand what will change

## Getting Started

### Installation

```bash
# Clone the repository
git clone https://github.com/ssullivan23/linuxHardeningScripts.git

# Navigate to the scripts directory
cd linux-hardening-scripts/linux-hardening-scripts

# Make scripts executable
chmod +x scripts/main.sh
chmod +x scripts/hardening/*.sh
chmod +x scripts/utils/*.sh
```

### Configuration

Review and customize configuration files in the `config/` directory:

```bash
# Edit hardening configuration
nano config/hardening.conf

# Edit exclusions (services/checks to skip)
nano config/exclusions.conf
```

## Running Scripts

### Orchestrated Execution (All Scripts)

The `main.sh` script runs all hardening scripts in sequence.

#### Dry Run (Recommended First Step)

**Always perform a dry run first to preview changes:**

```bash
sudo bash scripts/main.sh --dry-run
```

**Output Example:**
```
2025-10-28 10:15:23 - INFO: Starting dry run mode...
2025-10-28 10:15:23 - INFO: === SSH HARDENING (DRY RUN MODE) ===
2025-10-28 10:15:24 - INFO: [DRY RUN] Would change PermitRootLogin from 'yes' to 'no'
...
2025-10-28 10:15:45 - INFO: Dry run completed: 47 changes would be made
```

#### Apply All Hardening

**After reviewing dry-run output, apply changes:**

```bash
sudo bash scripts/main.sh
```

#### Custom Log File

```bash
sudo bash scripts/main.sh --log-file /custom/path/hardening.log
```

## Individual Script Usage

Each hardening script can be run independently for targeted hardening.

### 1. SSH Hardening

**What it does:** Secures SSH configuration to prevent unauthorized access.

```bash
# Preview changes
sudo bash scripts/hardening/ssh-hardening.sh --dry-run

# Apply changes
sudo bash scripts/hardening/ssh-hardening.sh
```

**Key Actions:**
- Disables root login via SSH
- Enforces key-based authentication only
- Sets strong cryptographic algorithms
- Configures connection timeouts
- Disables dangerous features (X11/agent forwarding)

**After Running:**
```bash
# Test SSH in a NEW session (keep current one open!)
ssh user@your-server

# If successful, restart SSH service
sudo systemctl restart sshd
```

### 2. Firewall Setup

**What it does:** Configures firewall rules using available firewall system.

```bash
# Preview changes
sudo bash scripts/hardening/firewall-setup.sh --dry-run

# Apply changes
sudo bash scripts/hardening/firewall-setup.sh
```

**Supported Firewalls:**
- firewalld (RHEL/CentOS/Fedora)
- UFW (Ubuntu/Debian)
- iptables (Traditional)

**Key Actions:**
- Sets default-deny policies
- Allows SSH access
- Drops invalid packets
- Enables connection state tracking
- Implements SYN flood protection

### 3. User Security

**What it does:** Enforces password policies and user account security.

```bash
# Preview changes
sudo bash scripts/hardening/user-security.sh --dry-run

# Apply changes
sudo bash scripts/hardening/user-security.sh
```

**Key Actions:**
- Sets password complexity requirements (14+ chars, mixed case, numbers, symbols)
- Configures password aging (90 day max, 7 day warning)
- Implements account lockout (5 failed attempts)
- Secures home directory permissions (750)
- Locks inactive/never-used accounts
- Disables system account shells

**Password Requirements After Hardening:**
- Minimum length: 14 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 digit
- At least 1 special character
- No dictionary words
- Different from username

### 4. Filesystem Hardening

**What it does:** Secures filesystem permissions and mount options.

```bash
# Preview changes
sudo bash scripts/hardening/filesystem-hardening.sh --dry-run

# Apply changes
sudo bash scripts/hardening/filesystem-hardening.sh
```

**Key Actions:**
- Secures critical files (/etc/passwd: 644, /etc/shadow: 000)
- Disables unused filesystems (cramfs, freevxfs, jffs2, hfs, udf, vfat)
- Reviews /tmp and /var partition security
- Disables core dumps
- Restricts cron/at access to root only
- Audits world-writable and unowned files

**Manual Review Required:**
- World-writable files: `find / -xdev -type f -perm -002`
- Unowned files: `find / -xdev \( -nouser -o -nogroup \)`

### 5. Kernel Hardening

**What it does:** Configures kernel security parameters via sysctl.

```bash
# Preview changes
sudo bash scripts/hardening/kernel-hardening.sh --dry-run

# Apply changes
sudo bash scripts/hardening/kernel-hardening.sh
```

**Key Actions:**
- Enables ASLR (Address Space Layout Randomization)
- Disables IP forwarding and source routing
- Enables reverse path filtering
- Configures SYN cookies for DDoS protection
- Restricts kernel pointer exposure
- Disables unused network protocols (60+ disabled)
- Protects hardlinks and symlinks

**Configuration saved to:** `/etc/sysctl.d/99-hardening.conf`

**View current kernel parameters:**
```bash
sysctl -a | grep -E 'net.ipv4|kernel|fs.protected'
```

### 6. Service Hardening

**What it does:** Disables unnecessary services and audits running services.

```bash
# Preview changes
sudo bash scripts/hardening/service-hardening.sh --dry-run

# Apply changes
sudo bash scripts/hardening/service-hardening.sh
```

**Key Actions:**
- Disables unnecessary services (cups, avahi, nfs, telnet, ftp, etc.)
- Verifies essential services are running (sshd, cron, rsyslog)
- Audits network-listening services
- Identifies services running as root
- Reviews legacy inet/xinetd configurations

**Services Typically Disabled:**
- avahi-daemon (Zero-config networking)
- cups (Printing)
- nfs-server (NFS)
- rpcbind (RPC)
- telnet, ftp, tftp (Insecure protocols)
- snmpd (SNMP)

**Services Preserved:**
- sshd/ssh (Remote access)
- cron/crond (Scheduled tasks)
- rsyslog/syslog (Logging)
- systemd-timesyncd (Time sync)

## Understanding Output

### Log Levels

Scripts use standardized log levels:

```
INFO:    Normal operation messages
WARNING: Potential issues requiring attention
ERROR:   Critical problems preventing execution
```

### Dry Run Output

```
[DRY RUN] Would change X from 'Y' to 'Z' - Description
```

Indicates what **would** change without `--dry-run` flag.

### Applied Changes

```
Changed X from 'Y' to 'Z' - Description
```

Indicates actual changes made to the system.

### Summary Output

```
=== SCRIPT NAME SUMMARY ===
Dry run completed: 23 changes would be made
Run without --dry-run to apply changes
```

Or after applying:

```
=== SCRIPT NAME SUMMARY ===
Hardening completed: 23 changes applied
Backup saved to: /etc/config.backup.20251028_101523
```

## Best Practices

### 1. Always Start with Dry Run

```bash
# GOOD: Preview changes first
sudo bash scripts/hardening/ssh-hardening.sh --dry-run
sudo bash scripts/hardening/ssh-hardening.sh

# BAD: Applying blindly
sudo bash scripts/hardening/ssh-hardening.sh  # Don't do this first!
```

### 2. Test SSH Before Closing Connection

```bash
# Keep current SSH session open
# Open a NEW terminal and test
ssh user@your-server

# If new connection works, close old session
# If new connection fails, fix issues in old session
```

### 3. Run Scripts in Logical Order

Recommended sequence:
1. `filesystem-hardening.sh` (foundational)
2. `kernel-hardening.sh` (low-level)
3. `user-security.sh` (authentication)
4. `ssh-hardening.sh` (remote access)
5. `firewall-setup.sh` (network)
6. `service-hardening.sh` (services)

### 4. Review Logs After Execution

```bash
# View latest log
cat logs/hardening_summary.log

# View with timestamps
tail -f logs/hardening_summary.log
```

### 5. Reboot After Major Changes

```bash
# After kernel/filesystem hardening
sudo reboot

# Verify changes persisted
sudo bash scripts/hardening/kernel-hardening.sh --dry-run
```

### 6. Document Your Customizations

Keep notes on:
- Which scripts you ran
- Any custom modifications
- Services you intentionally kept enabled
- Compliance requirements met

## Troubleshooting

### SSH Access Lost

**Prevention:**
- Always test in a new SSH session before closing current one
- Keep console/physical access available

**Recovery:**
1. Access via console/physical access
2. Restore SSH config backup:
   ```bash
   sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
   sudo systemctl restart sshd
   ```

### Firewall Locked You Out

**Recovery:**
1. Access via console/physical access
2. Flush firewall rules:
   ```bash
   # For iptables
   sudo iptables -F
   sudo iptables -P INPUT ACCEPT
   
   # For firewalld
   sudo firewall-cmd --panic-mode
   
   # For UFW
   sudo ufw disable
   ```

### Service Won't Start

**Diagnosis:**
```bash
# Check service status
sudo systemctl status service-name

# View detailed logs
sudo journalctl -u service-name -n 50

# Check configuration syntax
sudo service-name -t  # (for services that support it)
```

### Changes Not Persisting

**For sysctl parameters:**
```bash
# Verify configuration file
cat /etc/sysctl.d/99-hardening.conf

# Reload manually
sudo sysctl -p /etc/sysctl.d/99-hardening.conf
```

**For service changes:**
```bash
# Reload systemd
sudo systemctl daemon-reload

# Re-enable service
sudo systemctl enable service-name
```

### Script Errors

**Common issues:**

1. **Permission denied**
   ```bash
   # Solution: Run with sudo
   sudo bash scripts/hardening/script-name.sh
   ```

2. **Logger not found**
   ```bash
   # Solution: Run from correct directory
   cd linux-hardening-scripts/linux-hardening-scripts
   sudo bash scripts/hardening/script-name.sh
   ```

3. **Configuration file missing**
   ```bash
   # Solution: Check file exists
   ls -la /etc/ssh/sshd_config
   ls -la /etc/security/pwquality.conf
   ```

## Advanced Usage

### Selective Execution

Run only specific hardening aspects:

```bash
# Only SSH and firewall
sudo bash scripts/hardening/ssh-hardening.sh
sudo bash scripts/hardening/firewall-setup.sh

# Only user and filesystem
sudo bash scripts/hardening/user-security.sh
sudo bash scripts/hardening/filesystem-hardening.sh
```

### Scheduled Auditing

Run in dry-run mode periodically to audit compliance:

```bash
# Add to crontab for weekly audit
0 2 * * 0 /path/to/scripts/main.sh --dry-run >> /var/log/security-audit.log 2>&1
```

### Custom Wrapper Script

Create a custom script for your environment:

```bash
#!/bin/bash
# custom-hardening.sh

# Run specific scripts for your environment
bash scripts/hardening/ssh-hardening.sh
bash scripts/hardening/firewall-setup.sh
# Skip user-security if managed by LDAP
# bash scripts/hardening/user-security.sh
bash scripts/hardening/kernel-hardening.sh
```

## Support and Resources

- **Documentation**: See HARDENING_STEPS.md for detailed technical information
- **Issues**: Report bugs on GitHub
- **Logs**: Check `logs/hardening_summary.log` for execution details
- **Backups**: All backups stored with timestamp: `*.backup.YYYYMMDD_HHMMSS`

---

**Remember: Security is a process, not a destination. Regularly review and update your hardening measures!** 🔒
````