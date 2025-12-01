# CIS Hardening - Quick Reference Card

## 🚀 Quick Start

```bash
# Always do this first - preview changes
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run

# Apply hardening
sudo ./linux-hardening-scripts/scripts/main.sh

# View logs
cat ./logs/hardening_summary.log
```

---

## 📋 All Available Hardening Modules

### 1️⃣ account-security.sh
**Purpose:** User accounts, passwords, sudo
**CIS:** 5.1-5.5, 6.1-6.2
```bash
sudo ./scripts/hardening/account-security.sh --dry-run
```

### 2️⃣ audit-hardening.sh
**Purpose:** Auditing and logging
**CIS:** 4.1-4.4, 5.2-5.3
```bash
sudo ./scripts/hardening/audit-hardening.sh --dry-run
```

### 3️⃣ bootloader-hardening.sh
**Purpose:** GRUB bootloader security
**CIS:** 1.5
```bash
sudo ./scripts/hardening/bootloader-hardening.sh --dry-run
```

### 4️⃣ filesystem-hardening.sh
**Purpose:** Filesystem mounts and permissions
**CIS:** 1.1-1.10
```bash
sudo ./scripts/hardening/filesystem-hardening.sh --dry-run
```

### 5️⃣ firewall-setup.sh
**Purpose:** Firewall configuration
**CIS:** 3.4-3.5
```bash
sudo ./scripts/hardening/firewall-setup.sh --dry-run
```

### 6️⃣ kernel-hardening.sh
**Purpose:** Kernel parameters and sysctl
**CIS:** 1.1, 1.3, 3.1-3.5, 4.1
```bash
sudo ./scripts/hardening/kernel-hardening.sh --dry-run
```

### 7️⃣ network-hardening.sh
**Purpose:** Network stack hardening
**CIS:** 3.1-3.4
```bash
sudo ./scripts/hardening/network-hardening.sh --dry-run
```

### 8️⃣ permissions-hardening.sh
**Purpose:** File and directory permissions
**CIS:** 6.1-6.2
```bash
sudo ./scripts/hardening/permissions-hardening.sh --dry-run
```

### 9️⃣ service-hardening.sh
**Purpose:** Disable unnecessary services
**CIS:** 2.1-2.4
```bash
sudo ./scripts/hardening/service-hardening.sh --dry-run
```

### 🔟 ssh-hardening.sh
**Purpose:** SSH daemon configuration
**CIS:** 5.2
```bash
sudo ./scripts/hardening/ssh-hardening.sh --dry-run
```

### 1️⃣1️⃣ user-security.sh
**Purpose:** User and group security
**CIS:** 5.1-5.5, 6.x
```bash
sudo ./scripts/hardening/user-security.sh --dry-run
```

---

## 🎯 Common Commands

### Run all modules
```bash
sudo ./linux-hardening-scripts/scripts/main.sh
```

### Run in dry-run mode
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

### Skip specific modules
```bash
# Skip SSH hardening
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules ssh-hardening

# Skip multiple modules
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules ssh-hardening,firewall-setup
```

### Use custom log file
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --log-file /var/log/hardening.log
```

### Get help
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
```

---

## 🔍 Verification Commands

```bash
# SSH hardening
sudo sshd -T | grep -i permit  # Should show 'no' values

# Kernel parameters
sudo sysctl net.ipv4.ip_forward  # Should be 0
sudo sysctl net.ipv4.tcp_syncookies  # Should be 1
sudo sysctl kernel.panic_on_oops  # Should be 1

# File permissions
stat -c '%a %U:%G %n' /etc/passwd  # Should be 644 root:root
stat -c '%a %U:%G %n' /etc/shadow  # Should be 640 root:shadow

# Audit status
sudo systemctl status auditd  # Should be active/running
sudo auditctl -l  # Should show audit rules

# Firewall
sudo systemctl status firewalld  # Or ufw/iptables
sudo firewall-cmd --list-all  # View firewall rules

# Sudo logging
sudo cat /var/log/sudo.log  # Should have entries

# Password policies
sudo grep -E "PASS_MAX_DAYS|PASS_MIN_DAYS|PASS_WARN_AGE|INACTIVE" /etc/login.defs
```

---

## ⚠️ Pre-Hardening Checklist

- [ ] Test in non-production environment first
- [ ] Full system backup created
- [ ] Console/physical access available
- [ ] Run with `--dry-run` to preview changes
- [ ] SSH key setup before running
- [ ] Review dry-run output carefully
- [ ] Notify users of changes
- [ ] Plan for service restarts

---

## 📊 CIS Controls Quick Lookup

| CIS | Module(s) | Feature |
|-----|-----------|---------|
| 1.1-1.10 | filesystem, kernel | Filesystem hardening |
| 1.5 | bootloader | GRUB security |
| 2.1-2.4 | service | Service hardening |
| 3.1-3.5 | network, kernel, firewall | Network hardening |
| 4.1-4.4 | audit | Logging & audit |
| 5.1-5.5 | account, ssh, user | Access & auth |
| 6.1-6.3 | permissions, account | System admin |

---

## 🔄 Post-Hardening Steps

1. **Verify SSH Access** (critical!)
   ```bash
   # Test in NEW session before closing current
   ssh -i /path/to/key user@system
   ```

2. **Check Service Status**
   ```bash
   sudo systemctl status auditd
   sudo systemctl status firewalld  # or ufw
   ```

3. **Review Logs**
   ```bash
   cat ./logs/hardening_summary.log
   sudo tail -50 /var/log/audit/audit.log
   ```

4. **Test Critical Applications**
   - Web servers, databases, etc.
   - Ensure functionality is maintained

5. **Monitor System**
   - Watch for errors in logs
   - Monitor performance impact
   - Adjust if needed

---

## 📚 Documentation Files

| File | Purpose |
|------|---------|
| `CIS_HARDENING_GUIDE.md` | Comprehensive CIS mapping and details |
| `COMPLETE_CIS_HARDENING.md` | Project completion summary |
| `README.md` | Main documentation |
| `USAGE.md` | Usage instructions |
| `HARDENING_STEPS.md` | Step-by-step guide |

---

## 💡 Tips & Tricks

### Run multiple modules selectively
```bash
sudo ./scripts/main.sh --exclude-modules ssh-hardening,firewall-setup
```

### Dry-run specific module only
```bash
sudo ./scripts/hardening/ssh-hardening.sh --dry-run
```

### Check what changed after hardening
```bash
diff <(grep "DRY RUN" logs/hardening_summary.log) <(cat logs/hardening_summary.log)
```

### View module configuration
```bash
cat config/modules.conf
```

### Edit module settings
```bash
nano config/modules.conf  # Enable/disable modules
```

---

**Status:** ✅ Complete - All 11 modules implemented
**Last Updated:** December 2025
**Benchmark:** CIS Ubuntu Linux 22.04 LTS v3.0.0
