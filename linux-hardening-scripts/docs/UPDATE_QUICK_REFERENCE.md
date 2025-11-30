# Self-Update Quick Reference

## The Three Scenarios

### Scenario 1: "I Want to Check if Updates Are Available"
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```
Shows:
- Current version and branch
- Whether updates are available
- Number of local modifications

### Scenario 2: "I Want to Preview What Will Change"
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run
```
Shows what would be done WITHOUT making changes:
- What files would be stashed
- What would be fetched
- What would be merged
- What would be reapplied

### Scenario 3: "I Want to Update Now"
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update
```
Performs the full update:
1. ✓ Creates backup automatically
2. ✓ Stashes your changes
3. ✓ Fetches latest from GitHub
4. ✓ Applies updates
5. ✓ Reapplies your changes

## What If Something Goes Wrong?

### "The update failed!"
```bash
# Restore from backup
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```
Your system is restored to the state before the failed update.

### "I want to see what backups I have"
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups
```

### "I want to restore an older version"
```bash
# Restore latest (most recent) backup
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore

# Or manually restore an older one
cd /path/to/.backups
tar -xzf backup_20251129_093015.tar.gz -C ..
```

## Requirements

| Requirement | Check | Fix |
|------------|-------|-----|
| Root access | Run with `sudo` | `sudo ./main.sh --update` |
| Git installed | `which git` | `sudo apt install git` |
| Internet access | `ping github.com` | Check firewall/network |
| Disk space (~20MB) | `df -h` | Clean up old backups |

## Most Common Commands

```bash
# Quick check (safe, read-only)
sudo ./linux-hardening-scripts/scripts/main.sh --update-status

# Safe preview (no changes made)
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run

# Do the update
sudo ./linux-hardening-scripts/scripts/main.sh --update

# List backups
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups

# Restore if needed
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

## Understanding the Update Process

```
Your Local System
        ↓
    Backup Created ← (Automatic, safe point)
        ↓
    Stash Changes ← (Your modifications saved)
        ↓
    Fetch Updates ← (From GitHub)
        ↓
    Merge Changes ← (Apply new version)
        ↓
    Reapply Changes ← (Your modifications restored)
        ↓
    Success! ✓
```

## Timeline: Before vs After

### Before Update
```bash
$ git status
On branch main
Changes not staged for commit:
  modified: config/custom.conf
```

### During Update (with --dry-run)
```
[DRY RUN MODE] The following would be performed:
1. Stash local changes
2. Fetch latest changes from origin/main
3. Merge or fast-forward to latest version
4. Apply stashed changes
```

### After Update
```bash
$ git status
On branch main
nothing to commit, working tree clean
(Your custom changes are now part of the updated version)
```

## Backup Storage Location

Backups are stored automatically in:
```
linux-hardening-scripts/
  .backups/
    backup_20251130_145032.tar.gz  ← Latest (Day 1)
    backup_20251129_093015.tar.gz  ← Day 2 ago
    backup_20251128_161200.tar.gz  ← Day 3 ago
    backup_20251127_142045.tar.gz  ← Day 4 ago
    backup_20251126_080301.tar.gz  ← Day 5 ago
    (older backups automatically deleted)
```

Each backup is ~15MB and compressed (tar.gz).

## FAQ

**Q: Is the update automatic?**
A: No, you must explicitly run `--update` command.

**Q: What if I have custom scripts in the directory?**
A: Custom files in `.backups` are excluded from backups. Store custom scripts outside the repo directory or in a separate folder.

**Q: Can I schedule automatic updates?**
A: Yes, with cron:
```bash
sudo crontab -e
# Add this line to run update daily at 2 AM
0 2 * * * /path/to/scripts/utils/updater.sh update >> /var/log/hardening-update.log 2>&1
```

**Q: What happens to my configuration files?**
A: Config files are included in backups and updated automatically with your values preserved.

**Q: Is there a way to see what changed?**
A: Yes, after update:
```bash
cd /path/to/linux-hardening-scripts
git log --oneline -5  # Last 5 changes
git diff HEAD~1 HEAD  # What changed in last update
```

**Q: Can I revert to an older version?**
A: Yes, restore a backup:
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

---

**Quick Tip**: Always run `--update-status` and `--update --dry-run` before actually updating in production!
