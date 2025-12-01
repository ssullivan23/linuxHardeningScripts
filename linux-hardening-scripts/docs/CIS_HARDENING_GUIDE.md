# CIS Ubuntu Linux 22.04 LTS Hardening - Complete Implementation

This document provides a comprehensive overview of the CIS Ubuntu Linux 22.04 LTS Benchmark hardening implementation in this repository.

## 📋 CIS Benchmark Coverage

The hardening scripts implement controls from the **CIS Ubuntu Linux 22.04 LTS Benchmark v3.0.0**.

### ✅ Fully Automated Controls

#### Section 1: Initial Setup
- **1.1: Filesystem Hardening**
  - Module: `filesystem-hardening.sh`
  - Controls: 1.1.1 - 1.1.24
  - Implements: Kernel modules disabling, filesystem mount options, permissions

- **1.2: Filesystem Integrity Checking**
  - Module: `audit-hardening.sh`
  - Control: 1.2.1
  - Implements: aide/tripwire installation and configuration

- **1.3: Kernel Parameters**
  - Module: `kernel-hardening.sh`
  - Controls: 1.3.1 - 1.3.24
  - Implements: sysctl parameters for kernel hardening

- **1.5: Bootloader**
  - Module: `bootloader-hardening.sh`
  - Control: 1.5.1 - 1.5.4
  - Implements: GRUB permissions, superuser password protection

#### Section 2: Services
- **2.1-2.4: Unnecessary Services**
  - Module: `service-hardening.sh`
  - Implements: Disable unnecessary services and protocols

#### Section 3: Network Hardening
- **3.1: Network Parameters**
  - Module: `network-hardening.sh` & `kernel-hardening.sh`
  - Controls: 3.1.1 - 3.1.2
  - Implements: IP forwarding controls, IPv6 configuration

- **3.2: ICMP Configuration**
  - Module: `kernel-hardening.sh`
  - Controls: 3.2.1 - 3.2.8
  - Implements: ICMP redirects, suspicious packet logging

- **3.3: TCP/IP Stack Hardening**
  - Module: `kernel-hardening.sh`
  - Controls: 3.3.1 - 3.3.10
  - Implements: Source routing, reverse path filtering, SYN cookies

- **3.4: TCP Wrappers**
  - Module: `network-hardening.sh`
  - Implements: TCP wrapper configuration

- **3.5: Firewall**
  - Module: `firewall-setup.sh`
  - Control: 3.5.1 - 3.5.3
  - Implements: Auto-detect and configure firewall (firewalld/UFW/iptables)

#### Section 4: Logging and Auditing
- **4.1: File Integrity Monitoring**
  - Module: `audit-hardening.sh`
  - Control: 4.1.1 - 4.1.4
  - Implements: auditd installation and configuration

- **4.2: Configure auditd Features**
  - Module: `audit-hardening.sh`
  - Controls: 4.2.1 - 4.2.4
  - Implements: auditd rules for system calls, file changes, etc.

- **4.3: Logging**
  - Module: `audit-hardening.sh`
  - Controls: 4.3.1 - 4.4.1
  - Implements: rsyslog installation and configuration

#### Section 5: Access, Authentication and Authorization
- **5.1: Configure SSH Key-based Authentication**
  - Module: `ssh-hardening.sh` & `account-security.sh`
  - Control: 5.1.1 - 5.1.5
  - Implements: SSH key authentication, password policies

- **5.2: SSH Server Configuration**
  - Module: `ssh-hardening.sh`
  - Controls: 5.2.1 - 5.2.20
  - Implements: SSH hardening parameters, ciphers, MACs, etc.

- **5.3: Configure sudo**
  - Module: `account-security.sh`
  - Controls: 5.3.1 - 5.3.6
  - Implements: sudo installation, logging, TTY requirements

- **5.4: Configure PAM**
  - Module: `account-security.sh`
  - Controls: 5.4.1 - 5.4.5
  - Implements: Password quality, password history, account lockout

- **5.5: User Accounts and Environment**
  - Module: `account-security.sh` & `user-security.sh`
  - Controls: 5.5.1 - 5.5.5
  - Implements: Password aging, login timeout, reserved UID/GID

#### Section 6: System Maintenance
- **6.1: File Permissions**
  - Module: `permissions-hardening.sh`
  - Controls: 6.1.1 - 6.1.14
  - Implements: System file permissions, umask settings

- **6.2: User and Group File Ownership**
  - Module: `permissions-hardening.sh` & `account-security.sh`
  - Controls: 6.2.1 - 6.2.13
  - Implements: Home directory ownership, SUID/SGID audit

- **6.3: User and Group Administration**
  - Module: `account-security.sh`
  - Controls: 6.3.1 - 6.3.3
  - Implements: Shadow file checks, group ownership

---

## 🔧 Hardening Modules

### 1. **account-security.sh**
Manages user accounts, password policies, and sudo configuration.

**Key Controls:**
- CIS 5.1-5.5, 6.1-6.2
- Password expiration: 365 days
- Minimum password age: 7 days
- Password warning: 14 days
- Inactive lockout: 30 days
- Password length: 14 characters
- Account lockout: 5 attempts, 900-second timeout
- Sudo logging and PTY allocation

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/account-security.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/account-security.sh
```

### 2. **audit-hardening.sh**
Configures auditd and system logging for comprehensive auditing.

**Key Controls:**
- CIS 4.1-4.4, 5.2-5.3
- auditd installation and startup
- Audit rules for system calls, file changes, access
- rsyslog configuration
- Log retention and rotation

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/audit-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/audit-hardening.sh
```

### 3. **kernel-hardening.sh**
Hardens kernel parameters and network stack.

**Key Controls:**
- CIS 1.1, 1.3, 3.1-3.5, 4.1
- IP forwarding disabled
- ICMP redirects disabled
- Reverse path filtering enabled
- TCP SYN cookies enabled
- Kernel module loading restricted
- Kernel pointer exposure restricted
- ExecShield enabled
- Magic SysRq disabled

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/kernel-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/kernel-hardening.sh
```

### 4. **permissions-hardening.sh**
Secures file and directory permissions across the system.

**Key Controls:**
- CIS 6.1-6.2
- System file permissions (passwd, shadow, group, gshadow)
- SSH configuration file permissions
- PAM directory permissions
- Cron job directory permissions
- User home directory ownership and permissions
- SUID/SGID file audit

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/permissions-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/permissions-hardening.sh
```

### 5. **ssh-hardening.sh**
Configures SSH for secure remote access.

**Key Controls:**
- CIS 5.2.1-5.2.20
- Root login disabled
- Password authentication disabled
- Empty passwords disabled
- X11 forwarding disabled
- SSH protocol version 2 only
- Login grace time: 60 seconds
- Max authentication attempts: 3
- Host-based authentication disabled
- Strong ciphers (AES-GCM)
- Strong MACs (HMAC-SHA2)
- Strong key exchange (Curve25519)
- TCP forwarding disabled
- Agent forwarding disabled
- Login banner configured

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/ssh-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/ssh-hardening.sh
```

### 6. **network-hardening.sh**
Hardens network stack and protocols.

**Key Controls:**
- CIS 3.1-3.4
- IPv4/IPv6 forwarding disabled
- ICMP redirects disabled
- Reverse path filtering
- Source routing protection
- Suspicious packet logging
- TCP wrappers configuration

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/network-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/network-hardening.sh
```

### 7. **firewall-setup.sh**
Configures firewall based on detected type.

**Key Controls:**
- CIS 3.4-3.5
- Auto-detects firewall type (firewalld, UFW, iptables)
- Implements default-deny policy
- Opens SSH port with restrictions
- Blocks unnecessary traffic
- Enables packet logging
- Handles IPv4 and IPv6

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/firewall-setup.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/firewall-setup.sh
```

### 8. **filesystem-hardening.sh**
Secures filesystem mount options and permissions.

**Key Controls:**
- CIS 1.1.1-1.1.24
- Filesystem mount options (/tmp, /var, /home)
- Disables unnecessary filesystems (cramfs, freevxfs, jffs2, hfs, hfsplus, udf, vfat)
- File permissions for system files
- Core dump restrictions
- Cron/at access restrictions
- AIDE file integrity monitoring

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/filesystem-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/filesystem-hardening.sh
```

### 9. **bootloader-hardening.sh**
Secures GRUB bootloader configuration.

**Key Controls:**
- CIS 1.5.1-1.5.4
- GRUB file permissions
- Superuser password protection
- Single-user mode authentication
- Boot parameter validation

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/bootloader-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/bootloader-hardening.sh
```

### 10. **service-hardening.sh**
Disables unnecessary services and features.

**Key Controls:**
- CIS 2.1-2.4, 5.1.x
- Disables unnecessary network services
- Disables X11 if not needed
- Disables Avahi, DHCP, LDAP, NFS, CUPS
- Ensures essential services are running
- Audits service configurations

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/service-hardening.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/service-hardening.sh
```

### 11. **user-security.sh**
Additional user and group security controls.

**Key Controls:**
- CIS 6.x
- Strong password requirements
- Home directory security
- Login timeout settings
- Account lockout policies
- User umask configuration

**Usage:**
```bash
sudo ./linux-hardening-scripts/scripts/hardening/user-security.sh --dry-run
sudo ./linux-hardening-scripts/scripts/hardening/user-security.sh
```

---

## 🚀 Running Complete Hardening

### Recommended Workflow

1. **Preview all changes (ALWAYS DO THIS FIRST):**
   ```bash
   sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
   ```

2. **Review the output** carefully to understand what will change

3. **Apply hardening:**
   ```bash
   sudo ./linux-hardening-scripts/scripts/main.sh
   ```

4. **Check logs** for any issues:
   ```bash
   cat ./logs/hardening_summary.log
   ```

5. **Test critical functionality:**
   - SSH access (in new session before closing current)
   - User login
   - Sudo commands
   - Service availability

### Selective Module Execution

Skip specific modules:
```bash
# Skip SSH hardening
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run --exclude-modules ssh-hardening

# Skip multiple modules
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules firewall-setup,network-hardening
```

### Custom Configuration

Edit `config/modules.conf` to persistently enable/disable modules:

```bash
nano ./linux-hardening-scripts/config/modules.conf

# Set to "no" to disable specific modules
ENABLE_KERNEL_HARDENING="yes"
ENABLE_SSH_HARDENING="yes"
ENABLE_FIREWALL="yes"
```

---

## ⚠️ Important Pre-Hardening Steps

1. **Test in non-production environment first**
2. **Backup your system** before running hardening
3. **Ensure console/physical access** to the system
4. **Review dry-run output** before applying changes
5. **Have a recovery plan** ready
6. **Disable services carefully** - verify you don't need them
7. **SSH changes are critical** - test in new session before closing current

---

## 📊 CIS Control Mapping Summary

| CIS Section | Controls | Modules | Status |
|-------------|----------|---------|--------|
| 1: Initial Setup | 1.1-1.10 | filesystem, kernel, audit | ✅ Automated |
| 2: Services | 2.1-2.4 | service | ✅ Automated |
| 3: Network | 3.1-3.5 | network, kernel, firewall | ✅ Automated |
| 4: Logging | 4.1-4.4 | audit | ✅ Automated |
| 5: Access/Auth | 5.1-5.5 | account, ssh, user | ✅ Automated |
| 6: System Admin | 6.1-6.3 | permissions, account | ✅ Automated |

---

## 🔍 Verification Steps

After hardening, verify controls are in place:

```bash
# Check SSH hardening
sudo sshd -T | grep -E "permitrootlogin|passwordauthentication"

# Check sysctl parameters
sudo sysctl -a | grep "net.ipv4.ip_forward"
sudo sysctl -a | grep "net.ipv6.conf.all.forwarding"

# Check file permissions
ls -la /etc/passwd /etc/shadow /etc/group /etc/gshadow

# Check audit status
sudo systemctl status auditd
sudo auditctl -l

# Check firewall status
sudo systemctl status firewalld  # or ufw or iptables
```

---

## 📚 Additional Resources

- **CIS Ubuntu Linux 22.04 LTS Benchmark v3.0.0** - Official benchmark document
- **README.md** - Quick start guide
- **USAGE.md** - Detailed usage instructions
- **Module documentation** in each script header

---

## 🤝 Contributing

To improve the hardening implementation:

1. Review the CIS Benchmark for new controls
2. Test changes in non-production environments
3. Update corresponding module scripts
4. Document changes with CIS control references
5. Submit improvements via pull request

---

**Last Updated:** December 2025
**Benchmark Version:** CIS Ubuntu Linux 22.04 LTS v3.0.0
**Repository:** Linux Hardening Scripts
