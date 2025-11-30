# Testing the Self-Update Feature

## Pre-Test Requirements

```bash
# 1. Ensure you have git installed
git --version

# 2. Ensure you're in the correct directory
cd /path/to/linux-hardening-scripts

# 3. Verify the updater script exists
ls -la scripts/utils/updater.sh

# 4. Make sure you can run with sudo
sudo -l
```

## Test Sequence

### Test 1: Check Help Documentation

**Command:**
```bash
./linux-hardening-scripts/scripts/utils/updater.sh --help
```

**Expected Output:**
- Shows comprehensive help
- Lists all commands (status, update, backup, restore, list-backups)
- Shows examples
- Displays usage information

**✓ Status:** PASS if help displays without errors

---

### Test 2: Check Update Status (No Changes Required)

**Command:**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```

**Expected Output:**
```
═══════════════════════════════════════════════════════════
  Update Status - Linux Hardening Scripts
═══════════════════════════════════════════════════════════

Current Branch: main
Current Commit: [hash]
Local Changes: None (or: N files modified)
Checking for updates...
✓ Already up to date with remote
(or: ⚠ Updates available from remote)
```

**✓ Status:** PASS if status displays current branch and commit

---

### Test 3: Test Dry-Run Mode (Safe Preview)

**Command:**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run
```

**Expected Output:**
```
═══════════════════════════════════════════════════════════
  Updating from Remote Repository
═══════════════════════════════════════════════════════════

Creating backup...
✓ Backup created: backup_20251130_HHMMSS.tar.gz

[DRY RUN MODE] The following would be performed:
1. Fetch latest changes from origin/main
2. Merge or fast-forward to latest version
```

**✓ Status:** PASS if dry-run completes without making changes

---

### Test 4: Verify Backup Was Created

**Command:**
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups
```

**Expected Output:**
```
Available backups:
/path/linux-hardening-scripts/.backups/backup_20251130_HHMMSS.tar.gz (15M)
```

**✓ Status:** PASS if backup file exists and has size

---

### Test 5: Check Backup Contents

**Command:**
```bash
cd /path/to/linux-hardening-scripts/.backups
tar -tzf backup_*.tar.gz | head -20
```

**Expected Output:**
Should show contents like:
```
scripts/utils/logger.sh
scripts/utils/validation.sh
scripts/hardening/ssh-hardening.sh
config/modules.conf
docs/README.md
```

**✓ Status:** PASS if backup contains expected files

---

### Test 6: Test Full Update (If Updates Available)

**Prerequisites:**
- Only if `--update-status` shows "Updates available from remote"
- Ensure you have recent backup

**Command:**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

**Expected Output:**
```
Creating backup...
✓ Backup created: backup_20251130_HHMMSS.tar.gz

Fetching updates from remote...
✓ Updates fetched

Updating to latest version...
✓ Successfully updated to latest version

═══════════════════════════════════════════════════════════
✓ Update completed successfully!
New version: [new_hash]
═══════════════════════════════════════════════════════════
```

**✓ Status:** PASS if update completes and scripts still work

---

### Test 7: Verify Hardening After Update

**Command:**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

**Expected Output:**
Should show hardening modules executing without errors

**✓ Status:** PASS if hardening runs normally after update

---

### Test 8: Test Restore from Backup

**Prerequisites:**
- Update from Test 6 completed successfully

**Command:**
```bash
# View available backups
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups

# Restore (will restore latest backup, which is from Test 5 or earlier)
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

**Expected Output:**
```
Restoring from backup: backup_20251129_HHMMSS.tar.gz
✓ Backup restored successfully
```

**✓ Status:** PASS if restore completes and scripts are unchanged

---

### Test 9: Test Help from Main Script

**Command:**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
```

**Expected Output:**
Should include new sections:
- "--update" option documented
- "--update-status" option documented
- Examples with update commands

**✓ Status:** PASS if help text includes update options

---

### Test 10: Test Error Handling - Missing Git

**Command (on system without git):**
```bash
# Simulate by temporarily renaming git
sudo mv /usr/bin/git /usr/bin/git.bak
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
sudo mv /usr/bin/git.bak /usr/bin/git
```

**Expected Output:**
```
Error: Git is not installed
Install it with: sudo apt install git
```

**✓ Status:** PASS if error message is clear and helpful

---

## Integration Tests

### Test 11: Run Hardening with Update Modules Config

**Command:**
```bash
# Ensure module config exists
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

**Expected Output:**
Should show both:
- Module configuration loaded successfully
- All hardening modules executing

**✓ Status:** PASS if everything runs together

---

### Test 12: Combine Update with Hardening Exclusion

**Command:**
```bash
# Can't combine --update with --exclude-modules
# (update happens first and exits)
# But verify help mentions this:
sudo ./linux-hardening-scripts/scripts/main.sh --help | grep -A 5 "update"
```

**Expected Output:**
Should show update-related options and examples

**✓ Status:** PASS if help is clear

---

## Performance Tests

### Test 13: Backup Performance

**Command:**
```bash
# Measure backup creation time
time sudo ./linux-hardening-scripts/scripts/utils/updater.sh backup
```

**Expected:**
- Should complete in < 5 seconds
- Creates ~15MB backup file

**✓ Status:** PASS if backup creates quickly

---

### Test 14: Status Check Performance

**Command:**
```bash
# Measure status check time
time sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```

**Expected:**
- Should complete in < 10 seconds (if network available)
- May be slower on first run (git fetch)

**✓ Status:** PASS if completes in reasonable time

---

## Cleanup After Testing

### Clean Up Old Backups

```bash
# List backups
sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups

# Remove all but latest 2 (keep for safety)
cd /path/to/.backups
ls -t backup_*.tar.gz | tail -n +3 | xargs -r sudo rm
```

### Restore to Known Good State

```bash
# If needed
sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore
```

---

## Test Results Template

Copy this template and fill it out:

```
TEST RESULTS - Self-Update Feature
==================================

Test 1 - Help Documentation:     ✓ PASS / ✗ FAIL
Test 2 - Update Status:          ✓ PASS / ✗ FAIL
Test 3 - Dry-Run Mode:           ✓ PASS / ✗ FAIL
Test 4 - Backup Creation:        ✓ PASS / ✗ FAIL
Test 5 - Backup Contents:        ✓ PASS / ✗ FAIL
Test 6 - Full Update:            ✓ PASS / ✗ FAIL
Test 7 - Hardening After Update: ✓ PASS / ✗ FAIL
Test 8 - Restore from Backup:    ✓ PASS / ✗ FAIL
Test 9 - Help Integration:       ✓ PASS / ✗ FAIL
Test 10 - Error Handling:        ✓ PASS / ✗ FAIL
Test 11 - Integration:           ✓ PASS / ✗ FAIL
Test 12 - Combined Usage:        ✓ PASS / ✗ FAIL
Test 13 - Backup Performance:    ✓ PASS / ✗ FAIL
Test 14 - Status Performance:    ✓ PASS / ✗ FAIL

Overall Status: ✓ READY FOR PRODUCTION / ✗ NEEDS FIXES

Notes:
______________________________________________________________________
______________________________________________________________________
```

---

## Common Issues and Solutions

### Issue: "Command not found: updater.sh"
**Solution:** Use full path or ensure you're in correct directory
```bash
sudo ./linux-hardening-scripts/scripts/utils/updater.sh --help
```

### Issue: "Permission denied"
**Solution:** Use sudo for all commands
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```

### Issue: "Git repository not found"
**Solution:** First run initializes git, just retry
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
```

### Issue: "Cannot reach remote repository"
**Solution:** Check internet connection
```bash
ping github.com
```

### Issue: Backup takes too long
**Solution:** First backup creates full archive, subsequent backups are faster

---

## Sign-Off

When all tests pass:

**Date:** _____________
**Tester:** _____________
**System:** _____________
**Status:** ✓ APPROVED FOR PRODUCTION

---

**Testing Guide Version:** 1.0
**Last Updated:** November 30, 2025
