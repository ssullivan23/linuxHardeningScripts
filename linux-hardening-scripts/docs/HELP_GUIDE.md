# Command-Line Help & Usage Guide

## Main Script Help

### Display Help
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
# or
sudo ./linux-hardening-scripts/scripts/main.sh -h
```

### Help Output Shows

The help display includes:
- **Description**: What the tool does and what benchmark it follows
- **Usage**: Basic command syntax
- **Options**: All available command-line flags
- **Available Modules**: List of all hardening modules with CIS control mappings
- **Quick Start Examples**: Common usage scenarios
- **Workflow**: Best practices for using the tool
- **Module Configuration**: How to edit config/modules.conf
- **Important Notes**: Safety and compliance reminders
- **Documentation References**: Links to more detailed docs

## Test Script Help

### Display Help
```bash
sudo ./linux-hardening-scripts/tests/test-hardening.sh --help
# or
sudo ./linux-hardening-scripts/tests/test-hardening.sh -h
```

### Help Output Shows

The help display includes:
- **Description**: What the test suite does
- **Usage**: Basic command syntax
- **Options**: All available test flags
- **Available Test Modes**: Different ways to run tests
- **Test Workflow**: Three-phase testing process
- **Examples**: Common test scenarios
- **Documentation References**: Additional resources

## Quick Command Reference

### Get Help Anytime
```bash
# Main script help
sudo ./linux-hardening-scripts/scripts/main.sh -h
sudo ./linux-hardening-scripts/scripts/main.sh --help

# Test script help
sudo ./linux-hardening-scripts/tests/test-hardening.sh -h
sudo ./linux-hardening-scripts/tests/test-hardening.sh --help
```

### Common Command Patterns

#### Dry-Run (Preview Only)
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

#### Full Hardening
```bash
sudo ./linux-hardening-scripts/scripts/main.sh
```

#### Skip Modules
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules ssh-hardening
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules firewall-setup,network-hardening
```

#### Custom Log File
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --log-file /var/log/hardening.log
```

#### Combine Options
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run --exclude-modules ssh-hardening --log-file /tmp/test.log
```

#### Test Only (Dry-Run)
```bash
sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only
```

#### Full Testing
```bash
sudo ./linux-hardening-scripts/tests/test-hardening.sh
```

## Error Handling

### Invalid Option
If you use an invalid option, the tool will show:
```
Error: Unknown option: --invalid
Usage: ./main.sh [OPTIONS]
Try './main.sh --help' for more information.
```

### Missing Argument
If an option requires an argument but doesn't get one:
```
Error: --log-file requires an argument
Usage: ./main.sh [OPTIONS]
Try './main.sh --help' for more information.
```

## Help Content Organization

### Main Script Help Sections

1. **Header**: ASCII art banner with tool name
2. **Description**: High-level overview and benchmark reference
3. **Usage**: Basic command syntax
4. **Options**: All flags with descriptions
5. **Available Modules**: All 9 modules with CIS control mapping
6. **Quick Start Examples**: 6 common usage patterns
7. **Workflow**: Best practice steps
8. **Module Configuration**: How to edit config files
9. **Important Notes**: Safety and compliance info
10. **Documentation Links**: References to other docs

### Test Script Help Sections

1. **Header**: ASCII art banner
2. **Description**: What the test suite does
3. **Usage**: Basic command syntax
4. **Options**: Available test flags
5. **Available Test Modes**: Testing options
6. **Test Workflow**: Three-phase process
7. **Examples**: Common test patterns
8. **Documentation References**: More info

## Module List (from --help)

All modules are listed with their purposes and CIS control mappings:

- `account-security` - Password policies, sudo, SSH config security (CIS 5.1-5.4)
- `bootloader-hardening` - GRUB security and permissions (CIS 1.5)
- `filesystem-hardening` - Filesystem mounts and permissions (CIS 1.1-1.10)
- `firewall-setup` - Firewall and iptables configuration (CIS 3.4)
- `kernel-hardening` - REMOVED (module removed from repository)
- `network-hardening` - Network stack hardening (CIS 3.1-3.3)
- `service-hardening` - Service management and removal (CIS 2.x)
- `ssh-hardening` - SSH daemon configuration (CIS 5.2)
- `user-security` - User/group permissions (CIS 5.1-5.5, 6.x)

## Exit Codes

### Success
- **0**: Help displayed (`-h`, `--help`)
- **0**: Command executed successfully

### Failure
- **1**: Invalid option provided
- **1**: Missing required argument
- **1**: Other execution errors

## Tips for Using Help

1. **Always check help first**: `--help` is your best friend
2. **Run help before complex commands**: Verify your command syntax
3. **Reference help for module names**: Get exact module names from help
4. **Use help for troubleshooting**: Help includes important notes

## Viewing Help on Different Systems

### Ubuntu/Debian
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help | less
```

### CentOS/RHEL
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help | more
```

### Save Help to File
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help > /tmp/hardening_help.txt
cat /tmp/hardening_help.txt
```

## Best Practices

✅ **Do This**:
- Run `--help` when unsure about syntax
- Review help output before running commands
- Use `--dry-run` to preview changes
- Combine multiple options for precise control

❌ **Don't Do This**:
- Ignore error messages
- Run hardening without reading help first
- Use invalid module names
- Skip the dry-run phase

## Getting Additional Help

If `--help` doesn't answer your questions:
1. Check `README.md` for full documentation
2. See `QUICK_REFERENCE.md` for common patterns
3. Review `IMPLEMENTATION_SUMMARY.md` for technical details
4. Check `logs/hardening_summary.log` for execution details
5. Review individual module scripts for specific functionality

---

**Remember**: When in doubt, use `--help`! 🆘
