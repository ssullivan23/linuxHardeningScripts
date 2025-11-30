# Self-Update Feature - Visual Guide

## 🎬 How It Works (Visual Flow)

### Scenario 1: Checking for Updates

```
┌─────────────────────────────────────────────────────────┐
│  User runs: sudo ./main.sh --update-status              │
└──────────────────────┬──────────────────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  Git Repository Status   │
        └──────────────┬───────────┘
                       ↓
     ┌─────────────────────────────────────┐
     │ Check Current Branch & Commit       │
     │ Check Local Changes Count           │
     │ Fetch From Remote (GitHub)          │
     │ Compare Versions                    │
     └─────────────────┬───────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  Display Status Report   │
        │                          │
        │ ✓ Already up to date     │
        │ (or) ⚠ Updates available │
        └──────────────────────────┘
```

### Scenario 2: Previewing Changes (Dry-Run)

```
┌─────────────────────────────────────────────────────────┐
│  User runs: sudo ./main.sh --update --dry-run           │
└──────────────────────┬──────────────────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  Create Backup (✓)       │
        │  (Saved, not rolled back)│
        └──────────────┬───────────┘
                       ↓
     ┌──────────────────────────────────────┐
     │  PREVIEW MODE: Show what would be:   │
     │                                      │
     │ 1. Stash local changes               │
     │ 2. Fetch latest from origin/main     │
     │ 3. Merge or fast-forward             │
     │ 4. Apply stashed changes             │
     │                                      │
     │ ⚠️ NO ACTUAL CHANGES MADE!           │
     └──────────────┬──────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  Exit (No Update)        │
        │  Backup remains for      │
        │  future restore if needed│
        └──────────────────────────┘
```

### Scenario 3: Applying Updates

```
┌─────────────────────────────────────────────────────────┐
│  User runs: sudo ./main.sh --update                     │
└──────────────────────┬──────────────────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  Step 1: Create Backup   │
        │                          │
        │ ✓ backup_20251130...gz  │
        │   (Saved in .backups/)   │
        │   ≈ 15MB compressed      │
        └──────────────┬───────────┘
                       ↓
     ┌─────────────────────────────────────┐
     │ Step 2: Handle Local Changes        │
     │                                     │
     │ ✓ Stash any local modifications    │
     │   (Saved in git stash)              │
     └─────────────────┬───────────────────┘
                       ↓
     ┌─────────────────────────────────────┐
     │ Step 3: Fetch Updates               │
     │                                     │
     │ ✓ Get latest from origin/main       │
     │   (From GitHub)                     │
     └─────────────────┬───────────────────┘
                       ↓
     ┌─────────────────────────────────────┐
     │ Step 4: Apply Updates               │
     │                                     │
     │ ✓ Merge or fast-forward             │
     │   (Update to new version)           │
     └─────────────────┬───────────────────┘
                       ↓
     ┌─────────────────────────────────────┐
     │ Step 5: Restore Local Changes       │
     │                                     │
     │ ✓ Reapply stashed modifications    │
     │   (Your custom changes merged in)   │
     └─────────────────┬───────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  ✓ SUCCESS!              │
        │                          │
        │ Update completed         │
        │ New version: a1b2c3d     │
        └──────────────────────────┘
```

### Scenario 4: Update Fails (Auto Rollback)

```
┌─────────────────────────────────────────────────────────┐
│  Update Process Encounters Error                        │
└──────────────────────┬──────────────────────────────────┘
                       ↓
     ┌──────────────────────────────────────┐
     │ Steps 1-4 Complete Successfully      │
     │ (Backup created, stash done, fetched)│
     │                                      │
     │ Then... ERROR!                       │
     │ (Network fail, merge conflict, etc)  │
     └──────────────┬───────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  ❌ DETECTED!            │
        │  Update failed           │
        └──────────────┬───────────┘
                       ↓
     ┌──────────────────────────────────────┐
     │ AUTOMATIC RECOVERY:                  │
     │                                      │
     │ ✓ Restore from backup that was      │
     │   created in Step 1                  │
     │                                      │
     │ ✓ System returned to original state  │
     │   before failed update               │
     └──────────────┬───────────────────────┘
                       ↓
        ┌──────────────────────────┐
        │  🛡️ SAFE!               │
        │                          │
        │ System is back to        │
        │ pre-update state         │
        │                          │
        │ Error message displayed  │
        │ Try again or check issue │
        └──────────────────────────┘
```

## 📊 Command Decision Tree

```
                    User wants to...
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   Check for        Preview what        Apply
   Updates          would change        Updates
        │                  │                  │
        ↓                  ↓                  ↓
  --update-status  --update --dry-run   --update
        │                  │                  │
        ↓                  ↓                  ↓
  Status report    Preview (no changes)  Full update
  (read-only)      (read-only)          (makes changes)
        │                  │                  │
        ↓                  ↓                  ↓
  ✓ Already up      ✓ See exactly    ✓ Backup created
    to date         what will        ✓ Update applied
  (or)              change           ✓ Success
  ⚠ Updates         (safe to                 (or)
    available       review)          ✗ Error → rollback
                                      ✓ Auto-recovered
```

## 🗂️ File Organization

```
linux-hardening-scripts/
│
├── scripts/
│   └── utils/
│       ├── logger.sh            ← Existing
│       ├── validation.sh         ← Existing
│       ├── reporting.sh          ← Existing
│       └── updater.sh            ✨ NEW - Self-update utility
│
├── config/
│   └── modules.conf             ← Existing
│
├── docs/
│   ├── SELF_UPDATE.md           ✨ NEW - Complete guide
│   ├── UPDATE_QUICK_REFERENCE.md ✨ NEW - Quick lookup
│   ├── IMPLEMENTATION_SELF_UPDATE.md ✨ NEW - Technical details
│   └── TESTING_SELF_UPDATE.md   ✨ NEW - Testing procedures
│
├── .backups/                    ✨ NEW (auto-created)
│   ├── backup_20251130_145032.tar.gz
│   ├── backup_20251129_093015.tar.gz
│   └── ... (up to 5 backups)
│
├── SELF_UPDATE_SUMMARY.md       ✨ NEW - This overview
├── README.md                    ← UPDATED - Added update info
└── scripts/main.sh              ← UPDATED - Added --update flags
```

## 🎯 Command Flowchart

```
Main Entry Point
      │
      └─► sudo ./main.sh
          │
          ├─► --help
          │   └─► Show help (updated with update commands)
          │
          ├─► --update-status
          │   └─► Call updater.sh status
          │       └─► Show current version & branch
          │       └─► Check remote for updates
          │       └─► Display status report
          │
          ├─► --update --dry-run
          │   └─► Call updater.sh update --dry-run
          │       └─► Create backup
          │       └─► Show what would happen
          │       └─► Exit (no changes)
          │
          ├─► --update
          │   └─► Call updater.sh update
          │       ├─► Create backup
          │       ├─► Stash local changes
          │       ├─► Fetch updates
          │       ├─► Merge/fast-forward
          │       ├─► Reapply changes
          │       └─► Report success (or rollback on failure)
          │
          └─► (hardening operations)
              └─► Standard hardening as before
```

## 🔄 State Transitions

```
Initial State
    │
    ├─→ Check Status ────────────────┐ No changes
    │                                │
    ├─→ Dry-Run Preview ─────────────┤ Still no changes
    │   (Review output)              │
    │   ↓                            │ Proceed to update
    │   All looks good? → YES        │
    │                                ↓
    ├─→ Apply Update ────────────────┘
    │   │
    │   ├─→ Success! ──→ Updated State ✓
    │   │   New version active
    │   │
    │   └─→ Error ──→ Rollback ──→ Back to Initial State ✓
    │                (Automatic)
    │
    └─→ Restore from Backup
        └─→ Back to Previous State ✓
```

## 📈 Backup Timeline

```
Day 1:  backup_20251130_145032.tar.gz ← Most recent
        (Created just now)
            │
Day 2:  backup_20251129_093015.tar.gz
            │
Day 3:  backup_20251128_161200.tar.gz
            │
Day 4:  backup_20251127_142045.tar.gz
            │
Day 5:  backup_20251126_080301.tar.gz
            │
Older:  ❌ Automatically deleted

Each backup:
- Size: ~15MB (compressed)
- Time to restore: < 5 seconds
- Format: tar.gz
```

## 🎓 Documentation Organization

```
                    Self-Update Documentation
                              │
                ┌─────────────┼─────────────┐
                │             │             │
            Quick Ref     Complete      Implementation
            (5 min)       (15 min)      (20 min)
                │             │             │
                ↓             ↓             ↓
        Start here!    For detailed    For developers
        Busy admins    understanding   & technical info
                │             │             │
                ├─→ Most common commands
                ├─→ Three main scenarios
                ├─→ FAQ
                ├─→ Troubleshooting
                └─→ See full docs if needed

            + Built-in --help for immediate reference
```

## ✅ Success Indicators

When you see these, everything is working:

### ✓ Status Check Success
```
═══════════════════════════════════════════════════════════
  Update Status - Linux Hardening Scripts
═══════════════════════════════════════════════════════════

Current Branch: main
Current Commit: a1b2c3d4e5f6
Local Changes: None
Checking for updates...
✓ Already up to date with remote
```

### ✓ Dry-Run Success
```
Creating backup...
✓ Backup created: backup_20251130_145032.tar.gz

[DRY RUN MODE] The following would be performed:
1. Stash local changes
2. Fetch latest changes from origin/main
3. Merge or fast-forward to latest version
4. Apply stashed changes
```

### ✓ Update Success
```
═══════════════════════════════════════════════════════════
✓ Update completed successfully!
New version: a1b2c3d
═══════════════════════════════════════════════════════════
```

## ❌ Error Indicators

If you see these, something needs attention:

```
❌ Git is not installed
   → Solution: sudo apt install git

❌ Cannot reach remote repository
   → Solution: Check internet or firewall

❌ Permission denied
   → Solution: Use sudo: sudo ./main.sh --update

❌ Merge conflicts
   → Solution: Restore backup, then retry
```

---

**Visual Guide Version:** 1.0
**Created:** November 30, 2025
**Status:** Ready for Reference ✓
