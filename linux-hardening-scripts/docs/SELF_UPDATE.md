# Self-Update Feature - Linux Hardening Scripts

## Overview

The Linux hardening scripts now include a self-update feature that allows you to automatically sync your local installation with the latest changes from the main GitHub repository. This feature includes:

- **Automatic Backups**: Creates backups before each update
- **Local Change Preservation**: Stashes and reapplies your custom modifications
- **Dry-Run Mode**: Preview changes before applying them
- **Automatic Restoration**: Rollback capability on failure
- **Backup Rotation**: Keeps the last 5 backups for easy recovery

## Quick Start

### Check for Updates
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```

### Preview Update Changes
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run
```

### Apply Latest Updates
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

### View Available Backups
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups
```

### Restore from Backup
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

## Complete Usage Guide

### Main Script Integration (Recommended)

You can access the updater directly from `main.sh`:

```bash
# Check update status
sudo ./linux-hardening-scripts/scripts/main.sh --update-status

# Update with dry-run preview
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run

# Apply update
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

### Direct Updater Script Usage

You can also use the updater script directly:

```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh [COMMAND] [OPTIONS]
```

#### Available Commands

| Command | Description |
|---------|-------------|
| `status` | Check current version and available updates |
| `update` | Update to latest version from repository |
| `backup` | Create manual backup of current installation |
| `restore` | Restore from latest backup |
| `list-backups` | List all available backups |
| `-h, --help` | Display help information |

#### Command Examples

```bash
# Check status
sudo ./linux-hardening-scripts/scripts/utils/updater.sh status

# Dry-run preview
sudo ./linux-hardening-scripts/scripts/utils/updater.sh update --dry-run

# Apply update
sudo ./linux-hardening-scripts/scripts/utils/updater.sh update

# Manual backup
sudo ./linux-hardening-scripts/scripts/utils/updater.sh backup

# List all backups
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups

# Restore latest backup
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

## Update Process Flow

### Normal Update Workflow

```
1. User runs: sudo ./main.sh --update
2. System checks Git installation
3. Repository is initialized if needed
4. Current status is displayed
5. Automatic backup is created ✓
6. Local changes are stashed
7. Latest changes are fetched from remote
8. Repository is updated (fast-forward)
9. Stashed changes are reapplied
10. Success report is displayed
```

### Update with Dry-Run

```
1. User runs: sudo ./main.sh --update --dry-run
2. System checks Git installation
3. Repository is initialized if needed
4. Current status is displayed
5. Automatic backup is created ✓
6. Preview of actions is shown (no actual update)
7. System exits without making changes
```

### Failed Update with Automatic Rollback

```
1. User runs: sudo ./main.sh --update
2. ... (steps 1-5 complete successfully)
3. Fetch fails → ERROR
4. System automatically restores from backup
5. Original state is recovered
6. User is notified of failure
```

## Backup Management

### Automatic Backups

- **When Created**: Before every update
- **Location**: `.backups/` directory in repository root
- **Format**: `backup_YYYYMMDD_HHMMSS.tar.gz`
- **Contents**: Scripts, config files, docs (excludes `.git`, logs, `.backups`)
- **Rotation**: Automatically keeps last 5 backups

### Backup Contents

Files included in backups:
- ✓ `scripts/` - All hardening modules
- ✓ `config/` - Configuration files (modules.conf, hardening.conf, exclusions.conf)
- ✓ `docs/` - Documentation files

Files excluded from backups:
- ✗ `.git/` - Git repository history
- ✗ `.backups/` - Previous backups
- ✗ `logs/` - Execution logs

### Manual Backups

Create a manual backup anytime:
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh backup
```

### Viewing Backups

List all available backups:
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups
```

Example output:
```
Available backups:
/path/linux-hardening-scripts/.backups/backup_20251130_145032.tar.gz (15M)
/path/linux-hardening-scripts/.backups/backup_20251129_093015.tar.gz (15M)
/path/linux-hardening-scripts/.backups/backup_20251128_161200.tar.gz (15M)
```

### Restoring from Backup

Restore from the latest backup:
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

## Update Status Information

The `status` command shows:

```
═══════════════════════════════════════════════════════════
  Update Status - Linux Hardening Scripts
═══════════════════════════════════════════════════════════

Current Branch: main
Current Commit: a1b2c3d4e5f6

Local Changes: None
(or: 3 files modified)

Checking for updates...
✓ Already up to date with remote
(or: ⚠ Updates available from remote)
```

## Requirements

### System Requirements

- **Operating System**: Ubuntu 22.04 LTS (or compatible Linux)
- **User Permissions**: Must run with `sudo` (root access required)
- **Disk Space**: Approximately 20MB for backup storage

### Software Requirements

- **Git**: Must be installed
  ```bash
  # Check if Git is installed
  which git
  
  # Install Git if needed
  sudo apt install git
  ```

### Network Requirements

- **Internet Access**: Required for fetching updates from GitHub
- **GitHub Access**: Must be able to reach `https://github.com`
- **Firewall**: Ensure ports 80/443 are open (or configure proxy)

## Handling Local Modifications

If you've made local changes to the scripts:

### During Update

1. Your changes are automatically **stashed** (saved)
2. Repository updates are applied
3. Your changes are automatically **reapplied** (if possible)
4. If conflicts occur, git will notify you

### Viewing Stashed Changes

```bash
cd /path/to/linux-hardening-scripts
git stash list
```

### Manually Recovering Stashed Changes

```bash
cd /path/to/linux-hardening-scripts
git stash pop
```

### Resolving Conflicts

If conflicts occur during reapplication:

```bash
cd /path/to/linux-hardening-scripts
git status
# Fix conflicting files
git add .
git stash drop
```

## Troubleshooting

### Error: "Git is not installed"

**Solution**: Install Git
```bash
sudo apt install git
```

### Error: "Cannot reach remote repository"

**Possible Causes**:
- No internet connection
- Firewall blocking GitHub access
- GitHub is temporarily unavailable

**Solutions**:
1. Check internet connection: `ping github.com`
2. Check firewall rules
3. Try again later
4. Use `restore` to rollback if needed

### Error: "Permission denied"

**Solution**: Use `sudo`
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

### Merge Conflicts During Update

**What Happened**: Your local changes conflict with remote changes

**Solution**:
```bash
# Option 1: Restore from backup
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore

# Option 2: Manually resolve and complete
cd /path/to/linux-hardening-scripts
git status  # See conflicting files
# Edit conflicting files to resolve
git add .
git commit -m "Resolved conflicts"
```

### Update Fails with Rollback

**What Happened**: Update encountered an error and was rolled back

**Solution**:
1. Check the error message
2. Resolve the underlying issue
3. Try update again

### Out of Disk Space

**Solution**:
1. Delete old backups: `rm .backups/backup_*.tar.gz` (keep newer ones)
2. Clear logs: `rm logs/*`
3. Try update again

## Update History

To see what changed in each update:

```bash
cd /path/to/linux-hardening-scripts

# View commit history
git log --oneline -10

# View specific changes
git diff HEAD~1 HEAD

# View detailed changes in a file
git log -p scripts/main.sh | head -100
```

## Security Considerations

### Before Updating

- [x] Create manual backup
- [x] Review what will change: `--update --dry-run`
- [x] Test in non-production environment first

### During Update

- [x] Automatic backups are created
- [x] Local changes are preserved
- [x] Failed updates rollback automatically

### After Update

- [x] Verify hardening still works: `--dry-run`
- [x] Check logs for any issues
- [x] Keep old backups for quick recovery

## FAQ

### Q: What if I don't want automatic updates?
**A**: You can always skip the `--update` flag. Updates are only applied when explicitly requested.

### Q: Can I schedule automatic updates?
**A**: Yes, using cron:
```bash
# Add to crontab with: sudo crontab -e
0 2 * * * /path/to/scripts/utils/updater.sh update >/dev/null 2>&1
```

### Q: Will updating affect my hardening configuration?
**A**: No, your `config/modules.conf` and other config files are preserved and included in the update process.

### Q: How much disk space do backups use?
**A**: Each backup is approximately 15MB compressed. With 5 backups retained, you'll use about 75MB.

### Q: Can I manually merge changes instead of using the updater?
**A**: Yes, you can use standard git commands:
```bash
cd /path/to/linux-hardening-scripts
git pull origin main
```

### Q: What if the main branch is not available?
**A**: The updater assumes `origin/main` is the main branch. For other branches:
```bash
# Manually fetch and checkout
cd /path/to/linux-hardening-scripts
git fetch origin
git checkout <branch-name>
```

## Support and Issues

If you encounter issues with the update feature:

1. **Check the error message** - It usually indicates the problem
2. **Try restore** - Rollback to previous version
3. **Check GitHub** - See if there are known issues
4. **Report a bug** - Open an issue on GitHub with:
   - Error message
   - Output of `updater.sh status`
   - Steps to reproduce

---

**Last Updated**: November 30, 2025
**Feature**: Self-Update Utility v1.0
**Status**: ✅ Production Ready
