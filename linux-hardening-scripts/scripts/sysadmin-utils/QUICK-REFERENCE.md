# System Admin Utilities - Quick Reference

Quick reference card for the Linux system administrator utility scripts.

## 🔍 list-users-with-sudo.sh

**One-liner:** Audit user privileges and identify admin accounts

```bash
# Quick audit
sudo bash list-users-with-sudo.sh

# Detailed audit
sudo bash list-users-with-sudo.sh --verbose
```

**What you get:**
- ✅ List of users with sudo access
- ✅ How they got admin rights (group vs sudoers file)
- ✅ Regular users without admin rights
- ✅ Security warnings if too many admins

---

## 🗑️ remove-hacking-tools.sh

**One-liner:** Remove penetration testing tools and games

```bash
# ALWAYS preview first!
sudo bash remove-hacking-tools.sh --dry-run

# Remove tools
sudo bash remove-hacking-tools.sh

# Nuclear option (removes dev tools too)
sudo bash remove-hacking-tools.sh --aggressive --dry-run
sudo bash remove-hacking-tools.sh --aggressive
```

**What gets removed:**
- 🔴 Wireshark, nmap, tcpdump, netcat
- 🔴 John, Hashcat, Ophcrack, Hydra
- 🔴 Metasploit, BeEF, SET
- 🔴 Aircrack-ng, Reaver, Kismet
- 🔴 Apache2, Nginx
- 🔴 Games (Aisleriot, etc.)
- 🔴 **Aggressive:** gcc, gdb, make, git, python-pip

---

## 💡 Common Workflows

### Security Audit Workflow
```bash
# 1. Check who has admin access
sudo bash list-users-with-sudo.sh --verbose > user-audit.txt

# 2. Check for hacking tools
sudo bash remove-hacking-tools.sh --dry-run > tools-found.txt

# 3. Review the reports
less user-audit.txt tools-found.txt

# 4. Remove tools if needed
sudo bash remove-hacking-tools.sh
```

### Post-Compromise Cleanup
```bash
# 1. Remove all hacking tools
sudo bash remove-hacking-tools.sh --dry-run
sudo bash remove-hacking-tools.sh

# 2. Audit user accounts
sudo bash list-users-with-sudo.sh --verbose

# 3. Check for backdoors
sudo find /var/www -name "*.php" -type f -exec grep -l "eval\|base64_decode\|system\|exec" {} \;

# 4. Review cron jobs
sudo crontab -l
sudo ls -la /etc/cron.*

# 5. Check network connections
sudo netstat -tulpn
```

### Competition Environment Reset
```bash
# Remove tools and games
sudo bash remove-hacking-tools.sh

# Lock down admin accounts
sudo bash list-users-with-sudo.sh --verbose
# (manually review and remove unnecessary sudo access)
```

### Production Server Hardening
```bash
# Audit users
sudo bash list-users-with-sudo.sh > /var/log/user-audit-$(date +%Y%m%d).log

# Check for unauthorized tools
sudo bash remove-hacking-tools.sh --dry-run > /var/log/tools-scan-$(date +%Y%m%d).log

# Review and remove if necessary
sudo bash remove-hacking-tools.sh
```

---

## ⚠️ Safety Reminders

1. **ALWAYS** run with `--dry-run` first
2. **BACKUP** your system before removing packages
3. **TEST** in development/staging first
4. **VERIFY** the tool doesn't remove legitimate software
5. **DOCUMENT** what you removed and why

---

## 🚨 Emergency Recovery

If you accidentally removed something important:

```bash
# Check what was removed (if logged)
cat /var/log/apt/history.log  # Debian/Ubuntu
cat /var/log/yum.log           # CentOS/RHEL

# Reinstall a package
sudo apt-get install <package-name>  # Debian/Ubuntu
sudo yum install <package-name>      # CentOS/RHEL
```

---

## 📝 Output to File

```bash
# Save reports for documentation
sudo bash list-users-with-sudo.sh --verbose > user-report-$(date +%Y%m%d).txt
sudo bash remove-hacking-tools.sh --dry-run > tools-report-$(date +%Y%m%d).txt

# Email reports (if mail is configured)
sudo bash list-users-with-sudo.sh --verbose | mail -s "User Audit $(hostname)" admin@example.com
```

---

## 🔗 Script Locations

```
scripts/sysadmin-utils/
├── list-users-with-sudo.sh      # User privilege auditing
├── remove-hacking-tools.sh      # Tool removal utility
└── README.md                     # Full documentation
```

---

**Need Help?** See full documentation in `README.md` or run any script with `--help`
