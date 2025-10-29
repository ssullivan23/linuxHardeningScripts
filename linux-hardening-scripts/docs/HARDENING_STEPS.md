```markdown
# Hardening Steps - Technical Documentation

This document provides comprehensive technical details about each hardening measure implemented by the Linux Hardening Scripts, including the rationale, specific changes made, and security benefits.

## Table of Contents

1. [SSH Hardening](#1-ssh-hardening)
2. [Firewall Setup](#2-firewall-setup)
3. [User Security](#3-user-security)
4. [Filesystem Hardening](#4-filesystem-hardening)
5. [Kernel Hardening](#5-kernel-hardening)
6. [Service Hardening](#6-service-hardening)

---

## 1. SSH Hardening

**Script:** `ssh-hardening.sh`  
**Configuration File:** `/etc/ssh/sshd_config`  
**Backup Location:** `/etc/ssh/sshd_config.backup.YYYYMMDD_HHMMSS`

### Changes Implemented

#### Authentication Security

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `PermitRootLogin` | `no` | Prevents direct root SSH access, forcing use of sudo for privilege escalation (auditable) |
| `PasswordAuthentication` | `no` | Enforces SSH key-based authentication, eliminating password brute-force attacks |
| `PermitEmptyPasswords` | `no` | Prevents accounts with empty passwords from authenticating |
| `ChallengeResponseAuthentication` | `no` | Disables keyboard-interactive authentication methods |
| `KerberosAuthentication` | `no` | Disables Kerberos unless specifically required |
| `GSSAPIAuthentication` | `no` | Disables GSSAPI unless specifically required |

#### Connection Security

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `Protocol` | `2` | Forces SSH protocol 2 only (protocol 1 has known vulnerabilities) |
| `LoginGraceTime` | `60` | Limits time to complete authentication (DoS mitigation) |
| `MaxAuthTries` | `3` | Limits failed authentication attempts per connection |
| `MaxSessions` | `2` | Limits concurrent sessions per TCP connection |
| `ClientAliveInterval` | `300` | Sends keep-alive every 5 minutes to detect dead connections |
| `ClientAliveCountMax` | `2` | Disconnects after 2 failed keep-alive responses (10 minutes idle) |

#### Cryptographic Hardening

| Setting | Value |
|---------|-------|
| **Ciphers** | `aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr` |
| **MACs** | `hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256` |
| **KexAlgorithms** | `curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256` |

**Security Benefits:**
- Removes weak/deprecated algorithms (3DES, RC4, MD5)
- Prioritizes AEAD ciphers (AES-GCM) for authenticated encryption
- Uses modern key exchange (Curve25519, DH group exchange)
- Implements Encrypt-then-MAC (ETM) for MAC algorithms

#### Feature Restrictions

| Parameter | Value | Security Benefit |
|-----------|-------|------------------|
| `X11Forwarding` | `no` | Prevents X11 session hijacking |
| `AllowTcpForwarding` | `no` | Prevents SSH tunneling abuse |
| `AllowAgentForwarding` | `no` | Prevents SSH agent hijacking |
| `PermitUserEnvironment` | `no` | Prevents environment variable injection |
| `PermitTunnel` | `no` | Prevents VPN tunneling via SSH |

#### Additional Hardening

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `StrictModes` | `yes` | Checks home directory and key file permissions before login |
| `HostbasedAuthentication` | `no` | Disables host-based authentication (insecure) |
| `IgnoreRhosts` | `yes` | Ignores legacy .rhosts files |
| `Banner` | `/etc/ssh/banner` | Displays legal warning before authentication |

### Post-Hardening Requirements

**Users must:**
1. Have SSH key pairs configured
2. Add public key to `~/.ssh/authorized_keys`
3. Test access before closing current session

**Restart Required:**
```bash
sudo systemctl restart sshd
```

---

## 2. Firewall Setup

**Script:** `firewall-setup.sh`  
**Supported:** firewalld, UFW, iptables

### Auto-Detection

The script automatically detects and configures the available firewall system:
- **firewalld** - RHEL/CentOS/Fedora default
- **UFW** - Ubuntu/Debian default
- **iptables** - Traditional Linux firewall

### Firewall Configuration by Type

#### firewalld Configuration

```bash
# Default zone
firewall-cmd --set-default-zone=public

# Allow services
firewall-cmd --permanent --add-service=ssh

# Logging
firewall-cmd --set-log-denied=all

# Reload
firewall-cmd --reload
```

**Security Benefits:**
- Default-deny incoming traffic
- Stateful connection tracking
- Zone-based policy management
- Packet logging for security monitoring

#### UFW Configuration

```bash
# Default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH
ufw allow 22/tcp

# Enable logging
ufw logging on

# Enable firewall
ufw enable
```

**Security Benefits:**
- Simple default-deny policy
- Connection state tracking
- Easy rule management
- Logging for audit trails

#### iptables Configuration

```bash
# Flush existing rules
iptables -F
iptables -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# Drop invalid packets
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

# SYN flood protection
iptables -A INPUT -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT

# Logging
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables_INPUT_denied: " --log-level 7

# Save rules
iptables-save > /etc/iptables/rules.v4
```

**Security Benefits:**
- Granular packet filtering
- Connection state tracking
- SYN flood protection (rate limiting)
- Invalid packet dropping
- Comprehensive logging

### Network Security Features

1. **Default-Deny Policy** - All incoming traffic blocked unless explicitly allowed
2. **Stateful Inspection** - Tracks connection state (NEW, ESTABLISHED, RELATED, INVALID)
3. **SSH Access Only** - Only SSH (port 22) allowed by default
4. **Logging** - Denied packets logged for security analysis
5. **DoS Protection** - SYN flood rate limiting (iptables)

---

## 3. User Security

**Script:** `user-security.sh`  
**Configuration Files:** Multiple

### Password Aging Policy

**File:** `/etc/login.defs`

| Parameter | Value | Description |
|-----------|-------|-------------|
| `PASS_MAX_DAYS` | `90` | Password expires after 90 days |
| `PASS_MIN_DAYS` | `1` | Minimum 1 day between password changes |
| `PASS_WARN_AGE` | `7` | Warn users 7 days before expiration |
| `PASS_MIN_LEN` | `14` | Minimum password length of 14 characters |

**Security Benefits:**
- Regular password rotation
- Prevents immediate password reuse
- Advance warning for password changes
- Enforces strong password length

### Password Quality Requirements

**File:** `/etc/security/pwquality.conf`

| Parameter | Value | Requirement |
|-----------|-------|-------------|
| `minlen` | `14` | Minimum 14 characters |
| `dcredit` | `-1` | At least 1 digit required |
| `ucredit` | `-1` | At least 1 uppercase letter required |
| `lcredit` | `-1` | At least 1 lowercase letter required |
| `ocredit` | `-1` | At least 1 special character required |
| `minclass` | `4` | All 4 character classes required |
| `maxrepeat` | `3` | Maximum 3 repeated characters |
| `maxsequence` | `3` | Maximum 3 sequential characters (abc, 123) |
| `dictcheck` | `1` | Reject dictionary words |
| `usercheck` | `1` | Reject passwords containing username |
| `enforcing` | `1` | Enforce for root user too |

**Example Strong Password:** `MyS3cure!Pass2025`

### Account Lockout Policy

**File:** `/etc/security/faillock.conf`

| Parameter | Value | Description |
|-----------|-------|-------------|
| `deny` | `5` | Lock account after 5 failed attempts |
| `fail_interval` | `900` | 15-minute failure window |
| `unlock_time` | `600` | Auto-unlock after 10 minutes |
| `audit` | enabled | Log to audit system |

**Security Benefits:**
- Prevents brute-force password attacks
- Time-based lockout with automatic recovery
- Audit trail for failed login attempts

### Home Directory Security

**Action:** Set permissions to `750` (rwxr-x---)

| Permission | Owner | Group | Others |
|------------|-------|-------|--------|
| Read | ✓ | ✓ | ✗ |
| Write | ✓ | ✗ | ✗ |
| Execute | ✓ | ✓ | ✗ |

**Security Benefit:** Prevents unauthorized users from accessing home directories

### System Account Hardening

**Action:** Set shell to `/usr/sbin/nologin` or `/sbin/nologin`

**Accounts affected:**
- bin, daemon, adm, lp, mail, news, uucp
- proxy, www-data, backup, list, irc, gnats, nobody
- systemd-network, systemd-resolve

**Security Benefit:** Prevents interactive login to service accounts

### Default umask

**Files:** `/etc/bashrc`, `/etc/profile`, `/etc/bash.bashrc`

**Setting:** `umask 027`

**Results in:**
- Files created with `640` (rw-r-----)
- Directories created with `750` (rwxr-x---)

**Security Benefit:** Files not world-readable by default

---

## 4. Filesystem Hardening

**Script:** `filesystem-hardening.sh`

### Critical File Permissions

| File | Permissions | Owner:Group | Rationale |
|------|-------------|-------------|-----------|
| `/etc/passwd` | `644` | root:root | World-readable user database |
| `/etc/shadow` | `000` | root:root | Password hashes must be secret |
| `/etc/group` | `644` | root:root | World-readable group database |
| `/etc/gshadow` | `000` | root:root | Group passwords must be secret |
| `/etc/ssh/sshd_config` | `600` | root:root | SSH configuration is sensitive |
| `/boot/grub/grub.cfg` | `600` | root:root | Prevents boot parameter tampering |
| `/boot/grub2/grub.cfg` | `600` | root:root | Prevents boot parameter tampering |
| `/etc/crontab` | `600` | root:root | Prevents unauthorized cron jobs |

### Disabled Filesystems

**File:** `/etc/modprobe.d/hardening.conf`

**Disabled:**
- `cramfs` - Compressed ROM filesystem (rarely used)
- `freevxfs` - Legacy Unix filesystem
- `jffs2` - Flash filesystem (embedded systems)
- `hfs` / `hfsplus` - Apple filesystems
- `udf` - Universal Disk Format (optical media)
- `vfat` - FAT32 filesystem (USB typically)

**Method:** `install <fs> /bin/true`

**Security Benefit:** Reduces attack surface by preventing mounting of unnecessary filesystems

### Partition Mount Options

#### /tmp Partition

**Recommended Options:** `nodev,nosuid,noexec`

| Option | Security Benefit |
|--------|------------------|
| `nodev` | Prevents device file creation in /tmp |
| `nosuid` | Prevents SUID bit execution in /tmp |
| `noexec` | Prevents binary execution in /tmp |

**Example /etc/fstab entry:**
```
/dev/sda5  /tmp  ext4  defaults,nodev,nosuid,noexec  0  0
```

#### /var/tmp Partition

**Recommended Options:** `nodev,nosuid,noexec` (same as /tmp)

### Core Dump Security

**File:** `/etc/security/limits.conf`
```
* hard core 0
```

**File:** `/etc/sysctl.d/99-hardening.conf`
```
fs.suid_dumpable = 0
```

**Security Benefit:**
- Prevents core dumps from SUID programs
- Avoids potential information disclosure
- Reduces disk space usage

### Cron/At Access Control

**Files:**
- `/etc/cron.allow` - Only listed users can use cron
- `/etc/at.allow` - Only listed users can use at
- `/etc/cron.deny` - Removed (allow-list approach)
- `/etc/at.deny` - Removed (allow-list approach)

**Cron Directory Permissions:** `700` (rwx------)
- `/etc/cron.d`
- `/etc/cron.daily`
- `/etc/cron.hourly`
- `/etc/cron.monthly`
- `/etc/cron.weekly`

**Security Benefit:** Prevents unauthorized task scheduling

### File Auditing

**World-Writable Files:**
```bash
find / -xdev -type f -perm -002
```

**Unowned Files:**
```bash
find / -xdev \( -nouser -o -nogroup \)
```

**Security Benefit:** Identifies potential security risks requiring manual review

---

## 5. Kernel Hardening

**Script:** `kernel-hardening.sh`  
**Configuration File:** `/etc/sysctl.d/99-hardening.conf`

### Network Security Parameters

#### IP Forwarding

```bash
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0
```

**Security Benefit:** Prevents server from acting as a router (unless required)

#### Source Routing

```bash
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0
```

**Security Benefit:** Prevents IP source routing attacks

#### ICMP Redirects

```bash
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
```

**Security Benefit:** Prevents routing table manipulation via ICMP redirects

#### Send Redirects

```bash
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
```

**Security Benefit:** Prevents server from sending ICMP redirects

#### Reverse Path Filtering

```bash
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
```

**Security Benefit:** Validates source IP addresses (anti-spoofing)

#### Martian Packet Logging

```bash
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
```

**Security Benefit:** Logs packets with impossible source addresses

#### ICMP Protection

```bash
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
```

**Security Benefit:** Prevents ICMP-based DoS attacks (Smurf attack)

#### TCP SYN Cookies

```bash
net.ipv4.tcp_syncookies = 1
```

**Security Benefit:** Protects against SYN flood DoS attacks

#### IPv6 Router Advertisements

```bash
net.ipv6.conf.all.accept_ra = 0
net.ipv6.conf.default.accept_ra = 0
```

**Security Benefit:** Prevents rogue router advertisements

### Kernel Security Parameters

#### Address Space Layout Randomization (ASLR)

```bash
kernel.randomize_va_space = 2
```

**Values:**
- `0` - Disabled
- `1` - Randomize stack and libraries
- `2` - Full randomization (including heap)

**Security Benefit:** Makes buffer overflow exploitation significantly harder

#### Restrict dmesg

```bash
kernel.dmesg_restrict = 1
```

**Security Benefit:** Prevents non-root users from reading kernel ring buffer (may contain sensitive info)

#### Hide Kernel Pointers

```bash
kernel.kptr_restrict = 2
```

**Values:**
- `0` - No restrictions
- `1` - Hide from non-privileged users
- `2` - Hide from all users (except root with CAP_SYSLOG)

**Security Benefit:** Prevents kernel pointer leaks useful for exploits

#### Restrict Performance Events

```bash
kernel.perf_event_paranoid = 3
```

**Values:**
- `-1` - No restrictions
- `0` - Disallow raw tracepoint access
- `1` - Disallow CPU event access
- `2` - Disallow kernel profiling
- `3` - Disallow all perf events

**Security Benefit:** Prevents performance counter side-channel attacks

#### Kernel Log Levels

```bash
kernel.printk = 3 3 3 3
```

**Format:** `console_loglevel default_message_loglevel minimum_console_loglevel default_console_loglevel`

**Security Benefit:** Reduces kernel information disclosure

#### BPF JIT Hardening

```bash
net.core.bpf_jit_harden = 2
```

**Security Benefit:** Hardens BPF JIT compiler against exploitation

#### Disable kexec

```bash
kernel.kexec_load_disabled = 1
```

**Security Benefit:** Prevents loading new kernels (prevents certain rootkits)

#### ptrace Restrictions

```bash
kernel.yama.ptrace_scope = 1
```

**Values:**
- `0` - Classic ptrace (any process can debug another)
- `1` - Restricted (only parents can ptrace children)
- `2` - Admin-only (requires CAP_SYS_PTRACE)
- `3` - No ptrace allowed

**Security Benefit:** Prevents process debugging/injection attacks

### Filesystem Security Parameters

#### Protected Links

```bash
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
```

**Security Benefit:** Prevents hardlink/symlink-based privilege escalation

#### Protected FIFOs and Regular Files

```bash
fs.protected_fifos = 2
fs.protected_regular = 2
```

**Security Benefit:** Prevents FIFO and regular file attacks in world-writable sticky directories

#### SUID Core Dumps

```bash
fs.suid_dumpable = 0
```

**Security Benefit:** Prevents core dumps from SUID programs

### Disabled Kernel Modules

**File:** `/etc/modprobe.d/hardening-modules.conf`

**Network Protocols Disabled:**
- `dccp` - Datagram Congestion Control Protocol
- `sctp` - Stream Control Transmission Protocol
- `rds` - Reliable Datagram Sockets
- `tipc` - Transparent Inter-Process Communication
- `n-hdlc` - High-level Data Link Control
- `ax25` - Amateur Radio X.25
- `netrom` - NET/ROM packet radio
- `x25` - X.25
- `rose` - ROSE packet radio
- `decnet` - DECnet
- `econet` - Econet
- `af_802154` - IEEE 802.15.4
- `ipx` - IPX
- `appletalk` - AppleTalk
- `psnap`, `p8023`, `p8022` - Ethernet protocols
- `can` - Controller Area Network
- `atm` - ATM

**Security Benefit:** Reduces kernel attack surface by disabling unused protocols

---

## 6. Service Hardening

**Script:** `service-hardening.sh`

### Services Typically Disabled

| Service | Description | Reason for Disabling |
|---------|-------------|---------------------|
| `avahi-daemon` | Zero-configuration networking | Rarely needed on servers; potential information disclosure |
| `cups` | Printing service | Not needed on servers without printers |
| `isc-dhcp-server` | DHCP server | Only needed on network infrastructure devices |
| `nfs-server` | Network File System server | Only needed if specifically sharing files |
| `rpcbind` | RPC port mapper | Required by NFS; disable if not using NFS |
| `rsync` | Rsync daemon | Use SSH-based rsync instead |
| `snmpd` | SNMP daemon | Often misconfigured; use alternatives if possible |
| `telnet` | Telnet server | Insecure; use SSH instead |
| `tftp` | TFTP server | Insecure; rarely needed |
| `vsftpd` | FTP server | Insecure; use SFTP/SCP instead |
| `xinetd` | Internet super-server | Legacy service; modern systems use systemd |
| `ypserv` | NIS server | Insecure; use LDAP instead |
| `rsh.socket` | Remote shell | Insecure; use SSH instead |
| `rlogin.socket` | Remote login | Insecure; use SSH instead |
| `rexec.socket` | Remote execution | Insecure; use SSH instead |
| `ntalk` | Talk daemon | Legacy chat; rarely used |
| `autofs` | Automount service | Only needed for specific use cases |

### Essential Services Preserved

| Service | Purpose |
|---------|---------|
| `sshd` / `ssh` | Secure remote access |
| `cron` / `crond` | Scheduled task execution |
| `rsyslog` / `syslog` | System logging |
| `systemd-timesyncd` | Time synchronization |

### Service Management Commands

**Disable and stop service:**
```bash
systemctl stop service-name
systemctl disable service-name
```

**Verify service status:**
```bash
systemctl status service-name
systemctl is-enabled service-name
systemctl is-active service-name
```

### Service Auditing

**List running services:**
```bash
systemctl list-units --type=service --state=running
```

**List network-listening services:**
```bash
ss -tulpn  # modern
netstat -tulpn  # legacy
```

**Identify services running as root:**
```bash
ss -tulpn | grep root
```

### Security Benefits

1. **Reduced Attack Surface** - Fewer services means fewer potential vulnerabilities
2. **Lower Resource Usage** - Disabled services don't consume CPU/memory
3. **Simplified Security Auditing** - Easier to monitor fewer services
4. **Compliance** - Many standards require disabling unnecessary services

### Legacy Service Configuration

**xinetd services:**
- Location: `/etc/xinetd.d/`
- Action: Review and disable unnecessary services

**inetd services:**
- Location: `/etc/inetd.conf`
- Action: Comment out or remove unnecessary services

---

## Summary of Security Improvements

### Attack Surface Reduction

- **Network Services:** Only SSH listening by default
- **Authentication:** Key-based only (no passwords)
- **Filesystem:** Unused filesystems disabled
- **Kernel Modules:** 20+ unused protocols disabled
- **System Services:** 10-15 unnecessary services disabled

### Defense in Depth

1. **Network Layer:** Firewall with default-deny
2. **Transport Layer:** Strong SSH cryptography
3. **Application Layer:** Service hardening
4. **Kernel Layer:** Sysctl hardening (60+ parameters)
5. **Filesystem Layer:** Proper permissions and mount options
6. **User Layer:** Strong authentication and password policies

### Compliance Support

These hardening measures help meet requirements from:
- **CIS Benchmarks** - Center for Internet Security
- **NIST SP 800-53** - Security and Privacy Controls
- **PCI DSS** - Payment Card Industry Data Security Standard
- **HIPAA** - Health Insurance Portability and Accountability Act
- **ISO 27001** - Information Security Management

### Ongoing Security

Remember:
1. **Regular Updates:** Keep system packages up to date
2. **Log Monitoring:** Review logs regularly for suspicious activity
3. **Periodic Auditing:** Re-run scripts in dry-run mode to verify compliance
4. **Adapt Standards:** Security requirements evolve; update scripts accordingly

---

**For support and updates, see the main README.md and USAGE.md documentation.**
```