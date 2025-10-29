# System Administrator Utility Scripts

A collection of helpful utility scripts for Linux system administrators to perform common administrative tasks, audits, and system analysis.

## 📋 Available Scripts

### 1. list-users-with-sudo.sh

**Purpose:** List all users on the system and identify those with sudo/administrative privileges.

**Features:**
- 🔍 Identifies users with sudo access via group membership (sudo, wheel, admin)
- 📄 Checks for direct entries in /etc/sudoers and /etc/sudoers.d/
- 👥 Categorizes users into Admin, Regular, and System accounts
- 🎨 Color-coded output for easy reading
- 📊 Provides summary statistics
- 🔐 Shows security recommendations
- 📝 Optional verbose mode with detailed user information

**Usage:**

```bash
# Basic usage
sudo bash list-users-with-sudo.sh

# Verbose mode (shows last login, groups, home directories, etc.)
sudo bash list-users-with-sudo.sh --verbose

# Get help
bash list-users-with-sudo.sh --help
```

**Output Categories:**

- **Admin Users** (Red) - Users with sudo/administrative privileges
  - Via sudo/wheel/admin group membership
  - Via direct sudoers file entries
  
- **Regular Users** (Green) - Normal user accounts (UID >= 1000)
  - Standard login accounts without elevated privileges
  
- **System Users** (Blue, verbose only) - Service/system accounts
  - Accounts with UID < 1000
  - Accounts with disabled shells

**Example Output:**

```
═══════════════════════════════════════════════════════════════════════
                     USER PRIVILEGE AUDIT REPORT
═══════════════════════════════════════════════════════════════════════

Generated: 2025-10-28 14:30:00
Hostname: webserver01

╔═════════════════════════════════════════════════════════════════════╗
║                    USERS WITH ADMIN PRIVILEGES                      ║
╚═════════════════════════════════════════════════════════════════════╝

  ● alice (UID: 1000)
    ├─ Via Group: alice sudo
    └─ Status: Active

  ● bob (UID: 1001)
    ├─ Via Group: bob wheel admin
    ├─ Via Sudoers: Direct entry in sudoers file
    └─ Status: Active

╔═════════════════════════════════════════════════════════════════════╗
║                         REGULAR USERS                               ║
╚═════════════════════════════════════════════════════════════════════╝

  ○ charlie (UID: 1002)

  ○ diana (UID: 1003)

═══════════════════════════════════════════════════════════════════════
                              SUMMARY
═══════════════════════════════════════════════════════════════════════

  Admin Users:    2
  Regular Users:  2
```

**Verbose Mode Information:**
- Last login timestamp
- User groups
- Home directory path
- Account status (Active/Locked)

**Security Recommendations:**
- Alerts if more than 3 users have admin privileges
- Warns about unusual root configurations

**Requirements:**
- Must be run as root (sudo) for complete information
- Works on most Linux distributions (Ubuntu, Debian, CentOS, RHEL, Fedora)
- Requires standard tools: groups, lastlog, passwd, getent

**Notes:**
- The script checks multiple sources for sudo access:
  - Group membership (sudo, wheel, admin, root)
  - Direct /etc/sudoers entries
  - Entries in /etc/sudoers.d/ directory
- Accounts with disabled shells (/sbin/nologin, /bin/false) are excluded by default
- Minimum UID for regular users is 1000 (configurable in script)

### 2. remove-hacking-tools.sh

**Purpose:** Detect and remove common hacking/penetration testing tools and unwanted software from the system.

**Features:**
- 🔍 Detects and removes 100+ hacking/pentesting tools
- 🎯 Categorized removal (network tools, password crackers, exploit frameworks, etc.)
- 🎨 Color-coded output for easy tracking
- 🔒 Two modes: Standard and Aggressive
- 🧪 Dry-run mode to preview before removal
- 📊 Detailed summary with statistics
- 🧹 Automatic cleanup of unused dependencies
- 💡 Post-removal security recommendations

**Usage:**

```bash
# Dry run (recommended first step)
sudo bash remove-hacking-tools.sh --dry-run

# Remove tools (standard mode)
sudo bash remove-hacking-tools.sh

# Aggressive mode (also removes dev tools)
sudo bash remove-hacking-tools.sh --aggressive

# Get help
bash remove-hacking-tools.sh --help
```

**Tool Categories:**

1. **Network Analysis Tools**
   - Wireshark, tcpdump, nmap, netcat, ettercap, dsniff

2. **Password Cracking Tools**
   - John the Ripper, Hashcat, Ophcrack, Hydra, Medusa

3. **Exploitation Frameworks**
   - Metasploit, BeEF, Social Engineer Toolkit, SQLMap

4. **Wireless Tools**
   - Aircrack-ng, Reaver, Kismet, Wifite, Pixiewps

5. **Vulnerability Scanners**
   - Nikto, OpenVAS, Nessus, Lynis, WPScan

6. **Forensics & Reverse Engineering**
   - Binwalk, Autopsy, Volatility, Radare2, Ghidra

7. **Web Application Testing**
   - Burp Suite, OWASP ZAP, W3AF, DirBuster

8. **Remote Access & Backdoors**
   - Weevely, Veil, PowerSploit

9. **Unwanted Services & Games**
   - Apache2, Nginx, Aisleriot, GNOME games

10. **Development Tools (Aggressive Mode Only)**
    - GCC, GDB, Make, Git, Strace, Ltrace

**Example Output:**

```
═══════════════════════════════════════════════════════════════════════
              HACKING TOOLS & UNWANTED SOFTWARE REMOVAL
═══════════════════════════════════════════════════════════════════════

Date: 2025-10-28 15:00:00
Hostname: webserver01
Package Manager: apt
Mode: LIVE REMOVAL

╔═════════════════════════════════════════════════════════════════════╗
║                    NETWORK ANALYSIS TOOLS                           ║
╚═════════════════════════════════════════════════════════════════════╝

  Removing: wireshark - Network protocol analyzer
    ✓ Successfully removed
  Removing: nmap - Network exploration and security scanner
    ✓ Successfully removed

═══════════════════════════════════════════════════════════════════════
                              SUMMARY
═══════════════════════════════════════════════════════════════════════

  Tools Found:        8
  Successfully Removed: 8

✓ Successfully removed 8 potentially unwanted packages
```

**Modes:**

- **Standard Mode**: Removes penetration testing tools, games, and unnecessary services
- **Aggressive Mode**: Additionally removes development tools (compilers, debuggers, version control)

**Safety Features:**
- Always run with `--dry-run` first to preview changes
- Color-coded warnings for aggressive removals
- Automatic dependency cleanup
- Post-removal security checklist

**Supported Package Managers:**
- APT (Debian/Ubuntu)
- YUM (CentOS/RHEL)
- DNF (Fedora)
- Zypper (openSUSE)
- Pacman (Arch Linux)

**Post-Removal Recommendations:**
1. Review system logs for suspicious activity
2. Check for unauthorized user accounts
3. Scan for web shells: `find /var/www -name '*.php' -type f`
4. Review cron jobs for backdoors
5. Check unusual processes and network connections

**⚠️ Important Warnings:**
- **Always backup** before running
- **Test in development** environment first
- **Aggressive mode** may break functionality that relies on compilers/dev tools
- Some packages may be **dependencies** for legitimate software
- Review **dry-run output** carefully before proceeding

**Use Cases:**
- Competition/CTF environment cleanup
- Post-compromise recovery
- Securing production servers
- Compliance requirements (remove unauthorized tools)
- Student lab environment resets

---

## 🚀 Coming Soon

Additional utility scripts planned:
- Disk usage analyzer by user/directory
- Service status checker
- Port and network connection auditor
- Log file analyzer
- Failed login attempt reporter
- File permission auditor
- Package update checker

---

## 📝 Usage Best Practices

1. **Always run with sudo** for complete information
2. **Review output regularly** as part of security audits
3. **Use verbose mode** when investigating specific accounts
4. **Document findings** for compliance/audit trails
5. **Act on recommendations** to maintain security posture

---

## 🤝 Contributing

To add new utility scripts to this collection:

1. Follow the existing script structure
2. Include comprehensive help/usage information
3. Add color-coded output for readability
4. Provide both basic and verbose output modes
5. Include error handling and validation
6. Update this README with script documentation

---

**Location:** `scripts/sysadmin-utils/`

**Part of:** Linux Hardening Scripts Project
