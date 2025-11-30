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
- **🛡️ Path-Safe**: Scripts work correctly from any directory and maintain proper paths
- **🧩 Compartmentalized Modules**: Enable/disable specific hardening controls selectively
- **📋 CIS Benchmark Aligned**: Implements CIS Ubuntu Linux 22.04 LTS hardening controls
- **❓ Built-in Help**: Use `-h` or `--help` to display comprehensive usage information
- **🔄 Self-Update Feature**: Automatically sync with main repository and resync changes

## 🆘 Getting Help

All scripts include comprehensive help messages:

```bash
# View main script help with all options and examples
sudo ./linux-hardening-scripts/scripts/main.sh --help

# View test script help
sudo ./linux-hardening-scripts/tests/test-hardening.sh -h

# Quick syntax reminder (without detailed help)
./linux-hardening-scripts/scripts/main.sh --invalid  # Shows usage_short
```

The help displays:
- All available command-line options
- Complete list of hardening modules with CIS control mappings
- Quick start examples for common use cases
- Recommended workflow and best practices
- References to detailed documentation

For comprehensive help documentation, see **[HELP_GUIDE.md](docs/HELP_GUIDE.md)** and **[HELP_SYSTEM.md](HELP_SYSTEM.md)**.

## 📦 What's Included

### Hardening Modules (CIS Ubuntu 22.04 Benchmark Based)

1. **account-security.sh** - User account and access control hardening
   - Password expiration and aging policies (CIS 5.1)
   - Sudo configuration and logging (CIS 5.3-5.4)
   - SSH configuration security (CIS 5.2)
   - Account lockout policies

2. **ssh-hardening.sh** - Secure SSH configuration
   - Disables root login and password authentication
   - Enforces SSH key-based authentication
   - Configures strong ciphers, MACs, and key exchange algorithms
   - Sets connection timeouts and rate limits
   - Disables dangerous features (X11 forwarding, agent forwarding, etc.)

3. **network-hardening.sh** - Network stack and protocol hardening
   - IP forwarding controls (CIS 3.1)
   - ICMP redirect protection (CIS 3.2)
   - Source route protection (CIS 3.3)
   - SYN flood protection (CIS 3.3)
   - Suspicious packet logging

4. **firewall-setup.sh** - Firewall configuration
   - Auto-detects firewall type (firewalld, UFW, or iptables)
   - Implements default-deny policies
   - Configures SSH access while blocking unnecessary traffic
   - Enables packet logging and SYN flood protection
   - Handles both IPv4 and IPv6

5. **bootloader-hardening.sh** - GRUB bootloader security
   - Bootloader permissions (CIS 1.5)
   - Superuser password protection
   - Single user mode authentication

6. **user-security.sh** - User account and password hardening
   - Enforces strong password policies (length, complexity)
   - Configures password aging and expiration
   - Implements account lockout after failed login attempts
   - Secures home directory permissions
   - Locks inactive accounts
   - Sets secure umask defaults

7. **filesystem-hardening.sh** - Filesystem security
   - Secures critical file permissions (/etc/passwd, /etc/shadow, etc.)
   - Disables unused/dangerous filesystems
   - Reviews partition mount options (/tmp, /var)
   - Disables core dumps
   - Restricts cron/at access to authorized users
   - Audits for world-writable and unowned files

8. **kernel-hardening.sh** - REMOVED
   - NOTE: The kernel hardening module has been removed from this distribution.
     Kernel/sysctl tuning is highly environment-specific; if you require
     equivalent functionality, add your own sysctl rules under /etc/sysctl.d/
     or maintain a separate kernel-hardening script tailored for your systems.

9. **service-hardening.sh** - Service management
   - Identifies and disables unnecessary services
   - Verifies essential services are running
   - Audits network-listening services
   - Reviews services running as root
   - Checks legacy inet/xinetd configurations

### Utility Scripts

- **logger.sh** - Centralized logging with timestamps and log levels
- **validation.sh** - Permission and configuration validation
- **reporting.sh** - Summary report generation

### Configuration Files

- **modules.conf** - Enable/disable individual hardening modules
- **hardening.conf** - System-wide hardening parameters
- **exclusions.conf** - Services and packages to exclude from hardening

## 📁 Directory Structure

```
linux-hardening-scripts/
├── scripts/
│   ├── hardening/           # Individual hardening scripts
│   │   ├── ssh-hardening.sh
│   │   ├── firewall-setup.sh
│   │   ├── user-security.sh
│   │   ├── filesystem-hardening.sh
│   │   ├── (kernel-hardening removed)
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
   ```

2. Make scripts executable:
   ```bash
   chmod +x linux-hardening-scripts/scripts/main.sh
   chmod +x linux-hardening-scripts/scripts/hardening/*.sh
   ```

### Usage

#### Run All Hardening Modules (Dry Run - Recommended First Step)

**Always start with a dry run to see what would change:**

```bash
# Preview all hardening changes without modification
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

#### Apply All Hardening Measures

```bash
# Execute all enabled hardening modules
sudo ./linux-hardening-scripts/scripts/main.sh
```

#### Selective Module Execution (Compartmentalization)

Skip specific modules while running others:

```bash
# Skip SSH hardening
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules ssh-hardening

# Skip multiple modules
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules firewall-setup,network-hardening

# Dry run excluding certain modules
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run --exclude-modules service-hardening
```

#### Module Configuration

Enable or disable modules by editing `config/modules.conf`:

```bash
# Edit the modules configuration
nano ./linux-hardening-scripts/config/modules.conf

# Available modules:
# ENABLE_ACCOUNT_SECURITY="yes"
# ENABLE_FILESYSTEM_HARDENING="yes"
# ENABLE_NETWORK_HARDENING="yes"
# ENABLE_SSH_HARDENING="yes"
# ENABLE_FIREWALL="yes"
# ENABLE_BOOTLOADER_HARDENING="yes"
# ... and more

# Then run with your custom configuration
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

#### Self-Update Feature

Keep your scripts synchronized with the main repository:

```bash
# Check for available updates
sudo ./linux-hardening-scripts/scripts/main.sh --update-status

# Preview what will be updated (dry-run)
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run

# Apply latest updates from repository
sudo ./linux-hardening-scripts/scripts/main.sh --update

# View all available backups
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups

# Restore from latest backup if needed
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

**Key Features:**
- ✅ Automatic backups before each update
- ✅ Preserves your local configuration and changes
- ✅ Dry-run mode to preview changes
- ✅ Automatic rollback on failure
- ✅ Backup rotation (keeps last 5 backups)

For comprehensive update documentation, see **[SELF_UPDATE.md](docs/SELF_UPDATE.md)**.

#### Run Individual Modules

Each module can be run independently:

```bash
# Account security hardening (dry run)
sudo ./linux-hardening-scripts/scripts/hardening/account-security.sh --dry-run

# Apply account security hardening
sudo ./linux-hardening-scripts/scripts/hardening/account-security.sh

# Network hardening (dry run)
sudo ./linux-hardening-scripts/scripts/hardening/network-hardening.sh --dry-run

# Bootloader hardening
sudo ./linux-hardening-scripts/scripts/hardening/bootloader-hardening.sh --dry-run

# Firewall setup
sudo ./linux-hardening-scripts/scripts/hardening/firewall-setup.sh --dry-run

# SSH hardening
sudo ./linux-hardening-scripts/scripts/hardening/ssh-hardening.sh --dry-run

# Kernel hardening (removed)
# The kernel-hardening module has been removed from this distribution.

# Service hardening
sudo ./linux-hardening-scripts/scripts/hardening/service-hardening.sh --dry-run

# Filesystem hardening
sudo ./linux-hardening-scripts/scripts/hardening/filesystem-hardening.sh --dry-run

# User security hardening
sudo ./linux-hardening-scripts/scripts/hardening/user-security.sh --dry-run
```

#### Customizing Log Location

By default, logs are written to the `logs/` directory in the repository. You can specify a different location:

```bash
sudo ./linux-hardening-scripts/scripts/main.sh --log-file /var/log/hardening.log
```

## 🧩 Compartmentalization & Module Control

This tool is designed with compartmentalization in mind, allowing you to customize exactly which hardening controls are applied to your system.

### Controlling Module Execution

**Three ways to control which modules run:**

1. **Command-line Exclusion** (temporary):
   ```bash
   sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules module1,module2
   ```

2. **Configuration File** (persistent):
   Edit `config/modules.conf` to enable/disable modules for your deployment.

3. **Individual Module Run**:
   Run individual hardening modules independently.

### Available Modules

| Module | Purpose | CIS Controls |
|--------|---------|-------------|
| `account-security` | Password aging, sudo config | 5.1-5.4, 6.x |
| `network-hardening` | IP forwarding, ICMP redirects, SYN protection | 3.1-3.3 |
| `ssh-hardening` | SSH daemon security | 5.2.x |
| `firewall-setup` | Firewall rules and policies | 3.4 |
| `bootloader-hardening` | GRUB security and permissions | 1.5 |
| `filesystem-hardening` | Mount options and permissions | 1.1-1.10 |
| `kernel-hardening` | REMOVED (module removed from repository) | 1.1, 4.3 |
| `service-hardening` | Service management | 2.x |
| `user-security` | User permissions and umask | 5.1-5.5, 6.x |

## 📋 CIS Ubuntu Linux 22.04 LTS Benchmark Coverage

This tool implements controls from the **CIS Ubuntu Linux 22.04 LTS Benchmark v3.0.0**. The mapping includes:

### Level 1 Controls (Essential)
- Account security and password policies
- SSH hardening
- Filesystem permissions and mounts
- Firewall configuration
- Kernel hardening parameters

### Level 2 Controls (Recommended)
- Advanced kernel parameters
- Audit and logging configuration
- Service hardening
- Network stack optimization

**Note:** Not all CIS controls can be automated. Some require manual intervention or are environment-specific. Review the CIS benchmark documentation for complete coverage.

## ⚠️ Important Notes

### Before Running

1. **Test in a non-production environment first**
2. **Review the dry-run output carefully**
3. **Ensure you have console/physical access** (in case SSH gets misconfigured)
4. **Backup your system** before applying changes
5. **Have a recovery plan** ready
6. **Consider your compliance requirements** and which modules you need

### After Running

1. **Test SSH access in a new session** before closing your current connection
2. **Restart affected services** or reboot as recommended
3. **Review the summary logs** in the `logs/` directory
4. **Verify system functionality** matches your requirements
5. **Verify CIS compliance** with benchmark assessment tools

### Configuration Backups

All scripts automatically create timestamped backups:
- `/etc/ssh/sshd_config.backup.YYYYMMDD_HHMMSS`
- `/etc/login.defs.backup.YYYYMMDD_HHMMSS`
- Other configuration files as modified

## 📚 Documentation

- **[USAGE.md](docs/USAGE.md)** - Detailed usage instructions and examples
- **[HARDENING_STEPS.md](docs/HARDENING_STEPS.md)** - Complete documentation of all hardening measures

## 🧪 Testing

Test scripts can be run from any directory to validate all hardening modules:

```bash
# Run all module tests (dry-run first, then actual)
sudo ./linux-hardening-scripts/tests/test-hardening.sh

# Run only dry-run tests (no actual changes)
sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only

# Test specific modules, excluding others
sudo ./linux-hardening-scripts/tests/test-hardening.sh --exclude-modules firewall-setup,network-hardening
```

### Test Execution Flow

The test script:
1. **Phase 1**: Runs all modules in dry-run mode for safety verification
2. **Phase 2**: Executes actual tests (unless `--dry-run-only` is specified)
3. **Reporting**: Generates detailed test reports in the `logs/` directory

### Recommended Testing Workflow

```bash
# 1. Start with dry-run-only testing
sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only

# 2. Review logs and output
cat logs/hardening_summary.log

# 3. Run full tests in staging/test environment
sudo ./linux-hardening-scripts/tests/test-hardening.sh

# 4. Review detailed results
tail -n 100 logs/hardening_summary.log
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