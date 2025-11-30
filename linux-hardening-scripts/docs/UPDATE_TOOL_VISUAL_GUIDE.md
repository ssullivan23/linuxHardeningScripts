# Enhanced Update Tool - Visual Architecture & Flow

**Date:** November 30, 2025  
**Status:** ✅ Complete

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Linux Hardening Scripts                  │
│                  Enhanced Update Tool v2.0                  │
└─────────────────────────────────────────────────────────────┘

                              ┌──────────┐
                              │  User    │
                              └────┬─────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
         ┌──────────▼─────┐   ┌───▼────────┐   ┌─▼────────────┐
         │  Check Status  │   │   Preview  │   │   Apply      │
         │ --update-status│   │ --dry-run  │   │  --update    │
         └────────┬───────┘   └───┬────────┘   └─┬────────────┘
                  │               │              │
                  └───────────────┼──────────────┘
                                  │
                      ┌───────────▼───────────┐
                      │   scripts/main.sh     │
                      │ (Orchestrator)        │
                      └───────────┬───────────┘
                                  │
                    ┌─────────────▼──────────────┐
                    │  scripts/utils/updater.sh  │
                    │  (Enhancement Tool)        │
                    └──────────┬────────┬────────┘
                               │        │
                    ┌──────────▼───┐ ┌──▼──────────────┐
                    │  Git Ops:    │ │  File Operations:
                    │  - fetch     │ │  - backup
                    │  - merge     │ │  - restore
                    │  - stash     │ │  - detect changes
                    │  - diff      │ │  - display changes
                    └──────────────┘ └─────────────────┘
```

---

## Update Workflow (Normal Case)

```
START
  │
  ├─→ User runs: sudo ./main.sh --update
  │
  ├─→ scripts/main.sh receives --update flag
  │
  ├─→ Sources scripts/utils/updater.sh
  │
  ├─→ Call: update_from_remote()
  │     │
  │     ├─→ Check if HEAD exists
  │     │   (is this a fresh repo?)
  │     │
  │     ├─→ Check for local changes
  │     │
  │     ├─→ CREATE BACKUP ✓
  │     │   (Full repository with tar)
  │     │
  │     ├─→ DETECT FILEPATH CHANGES ✓
  │     │   (git diff origin/main --name-status)
  │     │
  │     ├─→ git stash (if local changes)
  │     │
  │     ├─→ git fetch origin main
  │     │
  │     ├─→ git merge origin/main
  │     │
  │     ├─→ git stash pop (reapply changes)
  │     │
  │     └─→ DISPLAY FILEPATH CHANGES ✓
  │         (Show what was added/deleted/renamed)
  │
  ├─→ Display success message
  │
  ├─→ Return to user
  │
  END ✓
```

---

## Dry-Run Workflow (Preview Case)

```
START
  │
  ├─→ User runs: sudo ./main.sh --update --dry-run
  │
  ├─→ Call: update_from_remote(dry_run=true)
  │     │
  │     ├─→ Check if HEAD exists
  │     │
  │     ├─→ Check for local changes
  │     │
  │     ├─→ CREATE BACKUP ✓
  │     │   (Yes, backup even in dry-run)
  │     │
  │     ├─→ git fetch origin main
  │     │
  │     ├─→ DETECT FILEPATH CHANGES ✓
  │     │   (git diff origin/main --name-status)
  │     │
  │     ├─→ DISPLAY PREVIEW ✓
  │     │   "[DRY RUN] The following would be performed:"
  │     │   1. Fetch updates
  │     │   2. Merge/fast-forward
  │     │   3. Apply filepath changes
  │     │
  │     ├─→ DISPLAY FILEPATH CHANGES PREVIEW ✓
  │     │   (What files would be added)
  │     │   (What files would be deleted)
  │     │   (What files would be renamed)
  │     │
  │     └─→ Return without making changes
  │
  ├─→ Display "[DRY RUN]" summary
  │
  ├─→ Return to user (no changes made!)
  │
  END ✓ (Safe - nothing modified)
```

---

## Backup & Restore Flow

```
UPDATE PROCESS:
  │
  ├─→ BACKUP CREATED
  │   backup_20251130_150000.tar.gz (2.3 MB)
  │   ├─ scripts/
  │   ├─ config/
  │   ├─ docs/
  │   ├─ tests/
  │   └─ other files
  │   (Excludes: .git, .backups, logs)
  │   │
  │   └─→ Backup stored in: .backups/
  │       ├─ backup_20251130_150000.tar.gz ✓ Latest
  │       ├─ backup_20251129_140000.tar.gz
  │       ├─ backup_20251128_130000.tar.gz
  │       ├─ backup_20251127_120000.tar.gz
  │       └─ backup_20251126_110000.tar.gz
  │           (5 backups kept, auto-delete older ones)
  │
  ├─→ UPDATE APPLIED
  │   (Files added/deleted/renamed)
  │
  ├─→ IF FAILURE:
  │   RESTORE AUTOMATICALLY TRIGGERED ✓
  │   tar -xzf backup_20251130_150000.tar.gz
  │   → System returned to known good state
  │
  └─→ IF SUCCESS:
      Backup retained for manual rollback
      (Available for 7+ days via rotation)
```

---

## Filepath Change Detection Flow

```
LOCAL REPOSITORY          REMOTE REPOSITORY
(origin/main on disk)     (GitHub)
       │                         │
       └──────────┬──────────────┘
                  │
          git fetch origin main
                  │
         ┌────────▼──────────┐
         │  Comparison       │
         │  git diff --name-status
         │  origin/main      │
         └────────┬──────────┘
                  │
        ┌─────────┼─────────┐
        │         │         │
   ┌────▼──┐ ┌───▼──┐ ┌───▼────┐
   │  ADD  │ │DELETE│ │RENAME  │
   │ (A)   │ │ (D)  │ │ (R)    │
   └────┬──┘ └───┬──┘ └───┬────┘
        │        │        │
   ┌────▼────┐   │   ┌────▼────────┐
   │ + file  │   │   │→ old → new  │
   │  name   │   │   │    file     │
   └────┬────┘   │   └────┬────────┘
        │        │        │
        └────────┼────────┘
                 │
          ┌──────▼──────┐
          │ Display to  │
          │ User with   │
          │ Colors      │
          └──────┬──────┘
                 │
        ┌────────┴────────┐
        │                 │
   ┌────▼─────┐      ┌───▼───────┐
   │ DRY-RUN   │      │ APPLY     │
   │ PREVIEW   │      │ CHANGES   │
   └──────────┘      └───────────┘
```

---

## Color Legend

```
┌─────────────┬─────────────────────┬──────────────────┐
│ Color       │ ANSI Code           │ Meaning          │
├─────────────┼─────────────────────┼──────────────────┤
│ 🟢 GREEN    │ \033[0;32m          │ Success / Added  │
│ 🟡 YELLOW   │ \033[1;33m          │ Warning / Remove │
│ 🔵 BLUE     │ \033[0;34m          │ Info / Rename    │
│ 🔴 RED      │ \033[0;31m          │ Error / Failed   │
│ 🔷 CYAN     │ \033[0;36m          │ Headers / Boxes  │
│ 🟣 MAGENTA  │ \033[0;35m          │ Metadata         │
└─────────────┴─────────────────────┴──────────────────┘

Example Output:
  🟢 ✓ Backup created
  🔵 ℹ Fetching updates...
  🟡 ⚠ Detected local changes
  🔴 ✗ Update failed
```

---

## Filepath Change Display

```
Update brings filepath changes:

┌─────────────────────────────────────┐
│ New files to be added:              │
├─────────────────────────────────────┤
│ 🟢 + docs/NEW_FEATURE.md            │
│ 🟢 + scripts/utils/new-tool.sh      │
│ 🟢 + tests/test-new-tool.sh         │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Files to be removed:                │
├─────────────────────────────────────┤
│ 🟡 - config/old-config.conf         │
│ 🟡 - scripts/deprecated-module.sh   │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Files to be renamed/moved:          │
├─────────────────────────────────────┤
│ 🔵 → scripts/old.sh → scripts/new.sh│
│ 🔵 → docs/setup.md → docs/install.md
└─────────────────────────────────────┘
```

---

## Directory Structure After Enhancement

```
linux-hardening-scripts/
│
├── scripts/
│   ├── main.sh                      (Calls updater.sh)
│   └── utils/
│       ├── updater.sh              ← ENHANCED ✓
│       ├── reporting.sh
│       ├── logger.sh
│       └── validation.sh
│
├── config/
│   └── modules.conf
│
├── docs/
│   ├── HARDENING_STEPS.md
│   └── ... other docs ...
│
├── tests/
│   └── test-hardening.sh
│
├── .backups/                        (New - automatic backups)
│   ├── backup_20251130_150000.tar.gz
│   ├── backup_20251129_140000.tar.gz
│   └── ...
│
├── UPDATE_TOOL_COMPLETE.md          ← NEW ✓
├── UPDATE_TOOL_QUICK_REF.md         ← NEW ✓
├── UPDATE_TOOL_ENHANCED.md          ← NEW ✓
├── UPDATE_TOOL_IMPLEMENTATION.md    ← NEW ✓
├── UPDATE_TOOL_CHANGES.md           ← NEW ✓
├── UPDATE_TOOL_DOCUMENTATION_INDEX.md ← NEW ✓
├── UPDATE_TOOL_AT_A_GLANCE.md       ← NEW ✓
├── UPDATE_TOOL_FINAL_STATUS.md      ← NEW ✓
├── UPDATE_TOOL_VISUAL_GUIDE.md      ← NEW ✓
│
└── README.md
```

---

## Command Flow Diagram

```
User Input
    │
    ├──→ --update-status
    │    └──→ show_update_status()
    │        └──→ Display: Branch, Commit, Local changes, Remote status
    │
    ├──→ --update --dry-run
    │    └──→ update_from_remote(dry_run=true)
    │        ├──→ detect_filepath_changes()
    │        ├──→ show_filepath_changes()
    │        └──→ Display: Preview (no changes made)
    │
    ├──→ --update
    │    └──→ update_from_remote(dry_run=false)
    │        ├──→ backup_repo()           (Create backup)
    │        ├──→ git fetch origin        (Get updates)
    │        ├──→ git merge/fast-forward  (Apply updates)
    │        ├──→ detect_filepath_changes() (Find changes)
    │        ├──→ show_filepath_changes() (Display changes)
    │        └──→ Display: Success message
    │
    ├──→ backup
    │    └──→ backup_repo()
    │        └──→ Create manual backup
    │
    ├──→ restore
    │    └──→ restore_backup()
    │        └──→ Restore from latest backup
    │
    ├──→ list-backups
    │    └──→ list_backups()
    │        └──→ Show all available backups
    │
    ├──→ help | -h | --help
    │    └──→ show_usage()
    │        └──→ Display help text
    │
    └──→ [Unknown]
         └──→ Error: Unknown command
```

---

## Key Functions Overview

```
detect_filepath_changes()
  Input:  repo_root
  Process: git diff origin/main --name-status
  Output: return 0 (changes found) or 1 (no changes)
  Speed: <1 second
  
show_filepath_changes()
  Input:  repo_root
  Process: Parse git status and format with colors
  Output: Display to terminal (green/yellow/blue)
  
backup_repo()
  Input:  repo_root
  Process: tar -czf entire repository
  Output: backup_TIMESTAMP.tar.gz (~2-3 MB)
  
restore_backup()
  Input:  backup_dir, repo_root
  Process: tar -xzf from latest backup
  Output: Full repository restored
  
update_from_remote()
  Input:  repo_root, dry_run flag
  Process: Complete update workflow
  Output: Updated repository or preview
```

---

## Integration Points

```
scripts/main.sh
    │
    ├── Sources: scripts/utils/updater.sh
    │
    ├── Calls: detect_filepath_changes()
    │
    ├── Calls: show_filepath_changes()
    │
    └── Calls: update_from_remote()
        │
        ├── Uses: git operations
        │
        ├── Uses: tar for backup/restore
        │
        ├── Uses: Color codes
        │
        └── Reports results via echo/echo -e
```

---

## Error Handling Flow

```
Error Detected During Update
    │
    ├─→ Display error message (RED)
    │
    ├─→ Call: restore_backup()
    │    └─→ Extract backup from tar
    │        └─→ Restore to previous state
    │
    ├─→ Display: Backup restored
    │
    ├─→ Display: Recovery instructions
    │
    └─→ Return with error code
```

---

## Summary Diagram

```
┌─────────────────────────────────────────────────────────┐
│         Enhanced Update Tool v2.0 Overview             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  INPUT (User Commands)                                 │
│  ├─ --update-status                                    │
│  ├─ --update --dry-run                                 │
│  ├─ --update                                           │
│  └─ Other operations                                   │
│         │                                              │
│         ├─→ DETECTION (Filepath Changes)               │
│         │   ├─ git diff origin/main --name-status     │
│         │   ├─ Identify: Added (A)                    │
│         │   ├─ Identify: Deleted (D)                  │
│         │   └─ Identify: Renamed (R)                  │
│         │         │                                    │
│         │         ├─→ DISPLAY (Color-Coded)           │
│         │         │   ├─ Green + for added            │
│         │         │   ├─ Yellow - for deleted         │
│         │         │   └─ Blue → for renamed           │
│         │         │         │                          │
│         │         │         ├─→ DRY-RUN (Preview)     │
│         │         │         │   └─ No changes made      │
│         │         │         │         │                │
│         │         │         ├─→ APPLY (Real Update)   │
│         │         │         │   ├─ Backup created      │
│         │         │         │   ├─ Changes applied     │
│         │         │         │   └─ Report shown        │
│         │         │         │         │                │
│         ┌─────────┴─────────┴─────────┤                │
│         │                             │                │
│    ✓ SUCCESS                    ✗ FAILURE             │
│    └─ Changes applied           └─ Restore backup     │
│       Report displayed             Recovery message   │
│                                                         │
│  OUTPUT (Updated Repository or Preview)               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

**Visual Guide Version:** 1.0  
**Date:** November 30, 2025  
**Status:** ✅ Complete
