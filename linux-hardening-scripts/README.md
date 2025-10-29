````markdown
# Linux Hardening Scripts

A comprehensive set of Bash scripts designed to help novice and experienced system administrators harden Linux systems against security vulnerabilities. These production-ready scripts implement industry best practices for SSH, firewall, user security, filesystem, kernel, and service hardening.

## ✨ Key Features

- **🔍 Dry Run Mode**: Preview all changes before applying them with the `--dry-run` flag
- **📊 Real-time Console Logging**: Monitor actions as they happen with timestamped output
- **📝 Summary Reports**: Detailed summary at completion showing all changes made
- **🔒 Safe Execution**: Automatic backups of configuration files before modification
- **✅ Validation**: Built-in syntax checking and verification before applying changes
- **👤 Beginner-Friendly**: Clear, descriptive logging with explanations for each action
- **🎯 Modular Design**: Run scripts individually or orchestrate all at once
- **📈 Change Tracking**: Counts and reports exactly what was modified

## 📦 What's Included

### Hardening Scripts

1. **ssh-hardening.sh** - Secure SSH configuration
   - Disables root login and password authentication
   - Enforces SSH key-based authentication
   - Configures strong ciphers, MACs, and key exchange algorithms
   - Sets connection timeouts and rate limits
   - Disables dangerous features (X11 forwarding, agent forwarding, etc.)

2. **firewall-setup.sh** - Firewall configuration
   - Auto-detects firewall type (firewalld, UFW, or iptables)
   - Implements default-deny policies
   - Configures SSH access while blocking unnecessary traffic
   - Enables packet logging and SYN flood protection
   - Handles both IPv4 and IPv6

3. **user-security.sh** - User account and password hardening
   - Enforces strong password policies (length, complexity)
   - Configures password aging and expiration
   - Implements account lockout after failed login attempts
   - Secures home directory permissions
   - Locks inactive accounts
   - Sets secure umask defaults

4. **filesystem-hardening.sh** - Filesystem security
   - Secures critical file permissions (/etc/passwd, /etc/shadow, etc.)
   - Disables unused/dangerous filesystems
   - Reviews partition mount options (/tmp, /var)
   - Disables core dumps
   - Restricts cron/at access to authorized users
   - Audits for world-writable and unowned files

5. **kernel-hardening.sh** - Kernel security parameters
   - Configures sysctl security parameters (60+ settings)
   - Enables ASLR and protects kernel pointers
   - Disables IP forwarding and source routing
   - Implements SYN cookie protection
   - Restricts kernel module loading
   - Disables unused network protocols (DCCP, SCTP, RDS, etc.)

6. **service-hardening.sh** - Service management
   - Identifies and disables unnecessary services
   - Verifies essential services are running
   - Audits network-listening services
   - Reviews services running as root
   - Checks legacy inet/xinetd configurations

### Utility Scripts

- **logger.sh** - Centralized logging with timestamps and log levels
- **validation.sh** - Permission and configuration validation
- **reporting.sh** - Summary report generation

## 📁 Directory Structure

```
linux-hardening-scripts/
├── scripts/
│   ├── hardening/           # Individual hardening scripts
│   │   ├── ssh-hardening.sh
│   │   ├── firewall-setup.sh
│   │   ├── user-security.sh
│   │   ├── filesystem-hardening.sh
│   │   ├── kernel-hardening.sh
│   │   └── service-hardening.sh
│   ├── utils/               # Utility scripts
│   │   ├── logger.sh
│   │   ├── validation.sh
│   │   └── reporting.sh
│   └── main.sh             # Orchestration script
├── config/                  # Configuration files
│   ├── hardening.conf
│   └── exclusions.conf
├── logs/                    # Log output directory
├── docs/                    # Documentation
│   ├── USAGE.md
│   └── HARDENING_STEPS.md
├── tests/                   # Test scripts
│   └── test-hardening.sh
├── LICENSE
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Linux system (Ubuntu, Debian, CentOS, RHEL, Fedora, etc.)
- Root or sudo access
- Bash 4.0 or higher

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/ssullivan23/linuxHardeningScripts.git
   cd linux-hardening-scripts/linux-hardening-scripts
   ```

2. Make scripts executable:
   ```bash
   chmod +x scripts/main.sh
   chmod +x scripts/hardening/*.sh
   ```

### Usage

#### Run All Hardening Scripts (Dry Run)

**Always start with a dry run to see what would change:**

```bash
sudo bash scripts/main.sh --dry-run
```

#### Apply All Hardening Measures

```bash
sudo bash scripts/main.sh
```

#### Run Individual Scripts

Each script can be run independently:

```bash
# SSH hardening (dry run)
sudo bash scripts/hardening/ssh-hardening.sh --dry-run

# Apply SSH hardening
sudo bash scripts/hardening/ssh-hardening.sh

# Firewall setup (dry run)
sudo bash scripts/hardening/firewall-setup.sh --dry-run

# User security hardening
sudo bash scripts/hardening/user-security.sh --dry-run

# Filesystem hardening
sudo bash scripts/hardening/filesystem-hardening.sh --dry-run

# Kernel hardening
sudo bash scripts/hardening/kernel-hardening.sh --dry-run

# Service hardening
sudo bash scripts/hardening/service-hardening.sh --dry-run
```

## ⚠️ Important Notes

### Before Running

1. **Test in a non-production environment first**
2. **Review the dry-run output carefully**
3. **Ensure you have console/physical access** (in case SSH gets misconfigured)
4. **Backup your system** before applying changes
5. **Have a recovery plan** ready

### After Running

1. **Test SSH access in a new session** before closing your current connection
2. **Restart affected services** or reboot as recommended
3. **Review the summary logs** in the `logs/` directory
4. **Verify system functionality** matches your requirements

### Configuration Backups

All scripts automatically create timestamped backups:
- `/etc/ssh/sshd_config.backup.YYYYMMDD_HHMMSS`
- `/etc/login.defs.backup.YYYYMMDD_HHMMSS`
- Other configuration files as modified

## 📚 Documentation

- **[USAGE.md](docs/USAGE.md)** - Detailed usage instructions and examples
- **[HARDENING_STEPS.md](docs/HARDENING_STEPS.md)** - Complete documentation of all hardening measures

## 🧪 Testing

Test scripts are provided to verify hardening:

```bash
bash tests/test-hardening.sh
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Test your changes thoroughly
4. Commit your changes (`git commit -am 'Add new feature'`)
5. Push to the branch (`git push origin feature/improvement`)
6. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚡ Security Note

These scripts implement security best practices but should be customized for your specific environment. Always:
- Review configurations for your compliance requirements
- Test thoroughly before production deployment
- Keep scripts updated with latest security recommendations
- Monitor system logs after hardening

## 🙋 Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Review existing documentation
- Check system logs in the `logs/` directory

---

**Made for system administrators who take security seriously** 🔒
````