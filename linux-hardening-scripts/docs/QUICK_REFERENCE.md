# Quick Reference Guide: CIS Linux Hardening Tool

## One-Line Commands

### Preview All Changes (Safest First Step)
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

### Apply All Hardening
```bash
sudo ./linux-hardening-scripts/scripts/main.sh
```

### Skip Specific Modules
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules ssh-hardening
```

### Skip Multiple Modules
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --exclude-modules firewall-setup,network-hardening
```

### Run Single Module
```bash
sudo ./linux-hardening-scripts/scripts/hardening/account-security.sh --dry-run
```

### Test All Modules (Safe)
```bash
sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only
```

## Available Modules

| Command | Purpose |
|---------|---------|
| `account-security` | Password policies, sudo, SSH config security |
| `network-hardening` | IP forwarding, ICMP, TCP stack security |
| `ssh-hardening` | SSH daemon configuration |
| `bootloader-hardening` | GRUB security |
| `firewall-setup` | Firewall rules and policies |
| `filesystem-hardening` | Mount options and permissions |
| `kernel-hardening` | REMOVED (module removed from repository) |
| `service-hardening` | Service management |
| `user-security` | User permissions and umask |

## Common Workflows

### First-Time Deployment
```bash
# 1. Preview changes
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run

# 2. Review output and logs
tail -f logs/hardening_summary.log

# 3. Run actual hardening
sudo ./linux-hardening-scripts/scripts/main.sh

# 4. Verify SSH access in new session
ssh user@host  # DON'T close current session yet!

# 5. Review final logs
cat logs/hardening_summary.log
```

### Selective Hardening
```bash
# 1. Edit module configuration
nano config/modules.conf

# 2. Enable/disable specific modules
# Set ENABLE_ACCOUNT_SECURITY="no" to skip account security

# 3. Run with custom configuration
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run

# 4. Apply when satisfied
sudo ./linux-hardening-scripts/scripts/main.sh
```

### Development/Testing Environment
```bash
# 1. Test each module individually in dry-run
sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only

# 2. Run full tests
sudo ./linux-hardening-scripts/tests/test-hardening.sh

# 3. Review test results
cat logs/hardening_summary.log
```

### Compliance Verification
```bash
# 1. Run all hardening with dry-run
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run

# 2. Document what would change
tee compliance_report.txt < logs/hardening_summary.log

# 3. Apply hardening
sudo ./linux-hardening-scripts/scripts/main.sh

# 4. Document final state
cat logs/hardening_summary.log >> compliance_report.txt
```

## Configuration Tips

### Skip SSH (Preserve Current Configuration)
```bash
sudo ./linux-hardening-scripts/scripts/main.sh \
  --dry-run \
  --exclude-modules ssh-hardening
```

### Only Run Network Hardening
```bash
nano config/modules.conf
# Set all to "no" except ENABLE_NETWORK_HARDENING="yes"
sudo ./linux-hardening-scripts/scripts/main.sh
```

### Persistent Module Exclusion
```bash
# Edit config/modules.conf
ENABLE_FIREWALL="no"  # Don't run firewall module
ENABLE_SSH_HARDENING="no"  # Don't run SSH module

# Now main.sh respects these settings by default
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

## Troubleshooting

### Verify Script Paths Work
```bash
# Scripts should work from any directory
cd /tmp
sudo /full/path/to/linux-hardening-scripts/scripts/main.sh --dry-run
```

### Check Module Discovery
```bash
# Verify modules are found
ls -la ./linux-hardening-scripts/scripts/hardening/*.sh
```

### View Detailed Logs
```bash
# See what changes would be made
cat logs/hardening_summary.log

# Monitor live execution
tail -f logs/hardening_summary.log
```

### Dry-Run Before Any Change
```bash
# ALWAYS use --dry-run first
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run

# Review output carefully before running without --dry-run
```

## Important Reminders

⚠️ **Before Running**:
- Test in non-production first
- Review dry-run output
- Keep console/physical access available
- Backup system
- Have recovery plan

✅ **After Running**:
- Test SSH in new session
- Review logs
- Verify system functionality
- Test compliance requirements

## CIS Benchmark Mapping

- **CIS 1.5**: Bootloader hardening
- **CIS 3.1-3.3**: Network hardening
- **CIS 5.1-5.4**: Account security
- **CIS 5.2**: SSH hardening
- **CIS 2.x, 6.x, 4.x**: Service, file permissions, audit (existing modules)

See `README.md` for complete coverage details.

---

**For full documentation**, see `README.md` and `IMPLEMENTATION_SUMMARY.md`
