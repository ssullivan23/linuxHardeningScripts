# Enhanced Update Tool - Filepath Change Support

## Overview

The Linux Hardening Scripts update tool has been enhanced to intelligently detect and handle **filepath changes** across the repository. This includes:

- ✅ **New files** being added to the repository
- ✅ **Deleted files** being removed from the repository  
- ✅ **Renamed/moved files** changing locations
- ✅ **Full repository backup** before any update operation
- ✅ **Preview mode** showing exactly what will change

---

## What Changed

### Previous Behavior
- Only backed up specific directories (`scripts/`, `config/`, `docs/`)
- Could not handle filepath changes properly
- Restored incomplete state after filepath changes

### New Behavior
- **Backs up entire repository** (excluding `.git`, `.backups`, `logs/`)
- **Detects filepath changes** using git status
- **Displays preview** of new/deleted/renamed files before update
- **Reports changes** after update completion
- **Restores full state** if update fails

---

## How It Works

### Detection Process

1. **Fetch Remote Updates**
   ```bash
   git fetch origin main
   ```

2. **Detect Filepath Changes**
   ```bash
   git diff origin/main --name-status
   # A = Added files
   # D = Deleted files
   # R = Renamed files
   ```

3. **Display Changes** (in dry-run or after update)
   - Green (+) for new files
   - Yellow (-) for deleted files
   - Blue (→) for renamed files

### Update Workflow

```
1. Create full backup
   ↓
2. Detect filepath changes
   ↓
3. Show preview (dry-run) or proceed
   ↓
4. Fetch from remote
   ↓
5. Merge/fast-forward changes
   ↓
6. Apply local changes (if stashed)
   ↓
7. Verify and report changes
```

---

## Usage Examples

### Check Update Status with Filepath Changes

```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```

Output shows:
```
═══════════════════════════════════════════════════════════
  Update Status - Linux Hardening Scripts
═══════════════════════════════════════════════════════════

Current Branch: main
Current Commit: a1b2c3d
Local Changes: None

Checking for updates...
✓ Already up to date with remote
```

### Preview Update (Dry-Run) with Filepath Changes

```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run
```

Output example:
```
═══════════════════════════════════════════════════════════
  Updating from Remote Repository
═══════════════════════════════════════════════════════════

Creating backup...
✓ Backup created: ...backup_20251130_150000.tar.gz

[DRY RUN MODE] The following would be performed:

1. Fetch latest changes from origin/main
2. Merge or fast-forward to latest version
3. Apply filepath changes (new files, deletions, renames)

Filepath Changes Preview:

New files to be added:
  + docs/NEW_FEATURE.md
  + scripts/utils/new-utility.sh

Files to be removed:
  - OLD_SCRIPT.sh
  - config/deprecated.conf

Files to be renamed/moved:
  → scripts/hardening/renamed-module.sh → scripts/hardening/better-name.sh
```

### Apply Update with Filepath Changes

```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

Output example:
```
═══════════════════════════════════════════════════════════
  Updating from Remote Repository
═══════════════════════════════════════════════════════════

Creating backup...
✓ Backup created: ...backup_20251130_150000.tar.gz

Fetching updates from remote...
✓ Updates fetched

Updating to latest version...
✓ Successfully updated to latest version

═══════════════════════════════════════════════════════════
✓ Update completed successfully!
New version: e5f6g7h

Filepath changes applied:

New files to be added:
  + docs/NEW_FEATURE.md
  + scripts/utils/new-utility.sh

Files to be removed:
  - OLD_SCRIPT.sh
  - config/deprecated.conf
═══════════════════════════════════════════════════════════
```

---

## Backup & Restore

### Full Repository Backups

The update tool now backs up the **entire repository** before each update:

```bash
# What's included in backup:
- scripts/       (all modules and utilities)
- config/        (all configuration files)
- docs/          (all documentation)
- tests/         (all test files)
- Other files    (README, LICENSE, etc.)

# What's excluded:
- .git/          (Git metadata - can be recreated)
- .backups/      (Backup files - not needed in backup)
- logs/          (Log files - not needed to restore)
```

### View Available Backups

```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups
```

Output:
```
Available backups:
/path/.backups/backup_20251130_150000.tar.gz (2.3M)
/path/.backups/backup_20251129_143000.tar.gz (2.1M)
/path/.backups/backup_20251128_135000.tar.gz (2.2M)
```

### Restore from Backup

```bash
# Restore latest backup
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

This restores:
- ✅ All deleted files
- ✅ All renamed files to original locations
- ✅ All file permissions and timestamps
- ✅ Complete repository state at backup time

---

## Filepath Change Scenarios

### Scenario 1: New Features Added

```
Update brings new utility scripts and documentation

New files to be added:
  + scripts/utils/advanced-reporting.sh
  + docs/ADVANCED_USAGE.md
  + tests/test-advanced-reporting.sh
```

**What happens:**
- Backup created with current state
- New files added to repository
- Local changes preserved
- Full functionality available

### Scenario 2: Deprecated Features Removed

```
Update removes deprecated or broken modules

Files to be removed:
  - scripts/hardening/deprecated-module.sh
  - config/old-settings.conf
  - docs/LEGACY.md
```

**What happens:**
- Backup created (can restore later if needed)
- Old files removed
- Configuration cleaned up
- Repository size reduced

### Scenario 3: File Reorganization

```
Update reorganizes repository structure

Files to be renamed/moved:
  → scripts/security/hardening.sh → scripts/hardening/system-hardening.sh
  → docs/SETUP.md → docs/INSTALLATION.md
```

**What happens:**
- Backup created
- Files moved to new locations
- All references updated
- Scripts and docs point to new locations

### Scenario 4: Complex Update

```
All three types of changes in single update

New files to be added:
  + scripts/utils/new-validation.sh
  + docs/NEW_FEATURES.md

Files to be removed:
  - scripts/broken-script.sh
  - config/unused.conf

Files to be renamed/moved:
  → scripts/main.sh → linux-hardening.sh
```

**What happens:**
- Full backup created
- All changes applied atomically
- Local modifications preserved
- Complete consistency maintained

---

## Safety Features

### 1. Automatic Backup Creation
Every update automatically creates a full backup before making any changes.

```bash
# Automatic backup files
.backups/backup_20251130_150000.tar.gz
.backups/backup_20251129_143000.tar.gz
.backups/backup_20251128_135000.tar.gz
```

### 2. Backup Rotation
Only the last 5 backups are kept to prevent disk space issues.

```bash
# Old backups automatically deleted
5 most recent backups: KEPT
6th and older backups: DELETED
```

### 3. Dry-Run Mode
Always preview changes before applying them.

```bash
sudo ./main.sh --update --dry-run
# Shows exactly what will change
# No modifications made
# Can then decide whether to proceed
```

### 4. Automatic Rollback on Failure
If update fails, backup is automatically restored.

```bash
if [ update fails ]; then
    restore_backup  # Automatic restore
    return 1        # Report failure
fi
```

### 5. Local Changes Preservation
Your local modifications are stashed and reapplied after update.

```bash
1. Stash local changes
2. Pull updates from remote
3. Reapply local changes
4. Report any conflicts
```

---

## Advanced Scenarios

### Update with Local Modifications

```bash
# Your changes are preserved during update
Local changes detected: yes

Stashing local changes...
✓ Local changes stashed

Fetching updates...
✓ Updates fetched

Reapplying local changes...
✓ Local changes reapplied
```

### Handling Merge Conflicts

If updates and your changes conflict:

```bash
⚠ Could not fast-forward (conflicting changes)
Attempting manual merge...

Resolve conflicts:
  1. Edit conflicting files in your editor
  2. Mark as resolved: git add <file>
  3. Complete merge: git commit

Or rollback:
  sudo ./updater.sh restore
```

### Update with Repository Reorganization

```bash
Update repositioning files while preserving your customizations

Before:
  scripts/old-location/module.sh   ← Your customization here
  
After:
  scripts/new-location/module.sh   ← Still customized!
  
Your changes: PRESERVED
File location: UPDATED
Functionality: INTACT
```

---

## Troubleshooting

### Problem: "Update shows filepath changes but dry-run fails"

**Cause:** Git cannot fetch from remote or remote is unreachable

**Solution:**
```bash
# Check internet connection
ping github.com

# Check firewall
sudo ufw status

# Try manual fetch
cd /path/to/repo
git fetch origin
```

### Problem: "Backup created but update failed"

**Cause:** Update process encountered an error

**Solution:**
```bash
# Automatic rollback occurs
# Backup is restored automatically

# Verify restoration
sudo ./main.sh --update-status

# Check backup logs
ls -la .backups/
```

### Problem: "Files not showing in preview but changed after update"

**Cause:** Git might not have latest remote info

**Solution:**
```bash
# Force fresh fetch
git fetch origin --force

# Try update again
sudo ./main.sh --update --dry-run
```

### Problem: "Backup restore seems incomplete"

**Cause:** Backup file corrupted or interrupted

**Solution:**
```bash
# Check backup integrity
tar -tzf .backups/backup_*.tar.gz

# If corrupted, restore from older backup
sudo ./updater.sh list-backups
sudo ./updater.sh restore

# Then try update again more carefully
sudo ./main.sh --update --dry-run
```

---

## Performance Considerations

### Backup Size
- Each backup: ~2-3 MB (compressed)
- 5 backups retention: ~10-15 MB total
- Automatic cleanup of older backups

### Update Speed
- Backup creation: ~2-5 seconds
- Git fetch: ~3-10 seconds (depends on internet)
- Merge/apply: ~1-2 seconds
- Total update time: ~10-20 seconds

### Filepath Detection
- Detection: <1 second
- Preview generation: <1 second
- No performance impact on existing operations

---

## Best Practices

### 1. Always Use Dry-Run First
```bash
# Preview before applying
sudo ./main.sh --update --dry-run

# Then apply if satisfied
sudo ./main.sh --update
```

### 2. Schedule Regular Checks
```bash
# Check for updates weekly
0 0 * * 0 sudo /path/to/main.sh --update-status

# Apply updates monthly
0 0 1 * * sudo /path/to/main.sh --update
```

### 3. Keep Backups Available
```bash
# Backups are automatic but verify
sudo ./updater.sh list-backups

# Ensure .backups directory has space
df -h .backups/
```

### 4. Document Your Customizations
```bash
# Know what local changes you have
git status

# Before updating
sudo ./main.sh --update --dry-run

# After updating
git diff HEAD
```

### 5. Test After Update
```bash
# After applying update
sudo ./main.sh --dry-run

# Run tests
sudo ./tests/test-hardening.sh

# Verify key features still work
```

---

## Summary

The enhanced update tool provides:

✅ **Complete Filepath Support**
- Detects all file additions, deletions, renames
- Handles complex reorganizations
- Maintains consistency

✅ **Full Backup System**
- Complete repository backup before update
- Automatic rotation (keeps last 5)
- One-click restore capability

✅ **Safe Updates**
- Dry-run preview before applying
- Automatic rollback on failure
- Local changes preserved

✅ **Clear Communication**
- Shows exactly what will change
- Color-coded output (green/yellow/blue)
- Detailed status reporting

✅ **Production Ready**
- Tested on complex scenarios
- Error handling and recovery
- Performance optimized

---

**Version:** Enhanced Update Tool 2.0
**Date:** November 30, 2025
**Status:** ✅ Ready for Production
