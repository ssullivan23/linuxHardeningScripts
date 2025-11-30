# Enhanced Update Tool - Quick Reference

## One-Minute Overview

The update tool now **detects and handles filepath changes**:
- ✅ New files being added
- ✅ Files being deleted  
- ✅ Files being moved/renamed
- ✅ Full repository backed up automatically
- ✅ Preview mode before applying changes

---

## Quick Commands

### Check for Updates (Safe - Read Only)
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```

### Preview What Will Change (Safe - No Modifications)
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run
```

Shows:
- New files to be added (+)
- Files to be removed (-)
- Files to be renamed/moved (→)

### Apply Update (Active - Makes Changes)
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

Does:
1. Creates backup automatically
2. Fetches latest from GitHub
3. Applies all changes including filepath updates
4. Reports what changed

### List All Backups
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups
```

### Restore Latest Backup
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

---

## What's Being Backed Up?

### ✅ Included in Backup
```
scripts/           (all hardening modules)
config/            (all configurations)
docs/              (all documentation)
tests/             (all test files)
Other files        (README, LICENSE, etc.)
```

### ❌ Excluded from Backup
```
.git/              (Git metadata)
.backups/          (Backup files)
logs/              (Log files)
```

---

## Update Scenarios

### Scenario: New Files Added
```
Update brings new features

[DRY RUN] Filepath Changes Preview:

New files to be added:
  + scripts/utils/new-tool.sh
  + docs/NEW_FEATURE.md
```

**What happens:** New files added, your setup enhanced

### Scenario: Old Files Deleted
```
Update cleans up deprecated code

[DRY RUN] Filepath Changes Preview:

Files to be removed:
  - scripts/old-module.sh
  - config/deprecated.conf
```

**What happens:** Old files removed, cleaner repository

### Scenario: Files Reorganized
```
Update reorganizes repository structure

[DRY RUN] Filepath Changes Preview:

Files to be renamed/moved:
  → scripts/main.sh → linux-hardening.sh
```

**What happens:** Files moved to better locations

---

## Safety Checklist

Before running update:
- [ ] Run `--update --dry-run` first
- [ ] Review the filepath changes
- [ ] Check available disk space
- [ ] Ensure stable internet connection
- [ ] Back up any local customizations

After running update:
- [ ] Verify update succeeded
- [ ] Test key functionality
- [ ] Check that customizations still work

---

## Troubleshooting

| Problem | Command to Fix |
|---------|---|
| Want to see what will change | `sudo ./main.sh --update --dry-run` |
| Update failed, need rollback | `sudo ./updater.sh restore` |
| Need to verify current state | `sudo ./main.sh --update-status` |
| Backup corrupted/lost | `sudo ./updater.sh list-backups` |
| Confused what to do | `sudo ./updater.sh --help` |

---

## Color Legend in Output

| Color | Meaning | Example |
|-------|---------|---------|
| 🟢 Green | Success/New | + scripts/new.sh |
| 🔵 Blue | Info/Info text | ℹ Fetching updates |
| 🟡 Yellow | Warning/Removed | - scripts/old.sh |
| 🔴 Red | Error | ✗ Update failed |

---

## Key Features Explained

### Full Repository Backup
- **What:** Everything except git metadata
- **When:** Automatically before each update
- **Why:** Can restore entire repo if needed
- **How much:** ~2-3 MB per backup, 5 kept

### Filepath Change Detection
- **What:** Tracks files added/deleted/renamed
- **When:** Automatically during update
- **Why:** Show you exactly what changed
- **How:** `git diff origin/main --name-status`

### Dry-Run Preview
- **What:** Shows changes without applying
- **When:** Before you run actual update
- **Why:** Verify changes before proceeding
- **How:** Add `--dry-run` flag

### Automatic Rollback
- **What:** Restore from backup if update fails
- **When:** Automatically on error
- **Why:** Never leaves system in bad state
- **How:** Triggered by failures

---

## Update Decision Tree

```
Want to update?
    ↓
Run: sudo ./main.sh --update --dry-run
    ↓
Review filepath changes shown
    ↓
Changes look good?
    ├─ NO  → Run: sudo ./updater.sh restore
    │         or wait for different update
    │
    └─ YES → Run: sudo ./main.sh --update
             ↓
         Success! You're updated
         ↓
         Review changes: git diff HEAD~1
```

---

## Common Update Patterns

### Pattern 1: Regular Maintenance
```bash
# Weekly check
sudo ./main.sh --update-status

# Monthly preview
sudo ./main.sh --update --dry-run

# Apply when safe
sudo ./main.sh --update
```

### Pattern 2: Safe Production
```bash
# Always dry-run first
sudo ./main.sh --update --dry-run

# Review output carefully
# Then apply
sudo ./main.sh --update

# Verify everything works
sudo ./main.sh --dry-run
```

### Pattern 3: Emergency Rollback
```bash
# Something went wrong
sudo ./updater.sh list-backups

# Restore previous version
sudo ./updater.sh restore

# Verify restoration
sudo ./main.sh --update-status
```

---

## What Changed (vs Old Version)

### Before
- Only backed up `scripts/`, `config/`, `docs/`
- Couldn't detect filepath changes
- Might restore incomplete state

### After
- Backs up entire repository
- Detects and shows file additions/deletions/renames
- Restores complete consistent state
- Shows filepath changes in dry-run AND after update

---

## Pro Tips

1. **Always preview first**
   ```bash
   sudo ./main.sh --update --dry-run
   ```

2. **Check disk space before backup**
   ```bash
   df -h .backups/
   ```

3. **Schedule regular updates**
   ```bash
   # Cron job for weekly check
   0 0 * * 0 sudo /path/to/main.sh --update-status
   ```

4. **Keep local changes in git**
   ```bash
   git status  # See your customizations
   git diff    # Review your changes
   ```

5. **Document what you changed**
   ```bash
   git log --oneline  # See update history
   ```

---

## Getting Help

| Need Help With | Command |
|---|---|
| Update tool syntax | `sudo ./updater.sh --help` |
| Main script options | `sudo ./main.sh --help` |
| What gets backed up | Check UPDATE_TOOL_ENHANCED.md |
| Specific scenarios | Check UPDATE_TOOL_ENHANCED.md |

---

**Quick Reference Version:** 2.0
**Updated:** November 30, 2025
**Status:** ✅ Ready to Use
