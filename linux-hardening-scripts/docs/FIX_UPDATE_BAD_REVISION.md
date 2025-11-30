# Fixed: Update Feature - "bad revision 'HEAD'" Error

## Problem

When running `--update`, the script failed with:

```
fatal: bad revision 'HEAD'
Error: Failed to stash changes
```

## Root Cause

The error occurred because:

1. Git repository was newly initialized with no commits
2. The script tried to check for local changes using `git diff-index --quiet HEAD --`
3. Since HEAD didn't exist yet, git failed with "bad revision 'HEAD'"
4. The script couldn't stash changes, so it rolled back

## Solution Applied

Updated `updater.sh` with intelligent handling for repositories without commits:

### Key Changes

1. **Check if commits exist first**
   ```bash
   # Check if HEAD exists (repository has commits)
   if git rev-parse HEAD &>/dev/null; then
       has_commits=true
   fi
   ```

2. **Only check for changes if commits exist**
   ```bash
   if [ "$has_commits" = true ]; then
       if ! git diff-index --quiet HEAD --; then
           has_changes=true
       fi
   fi
   ```

3. **Different handling for fresh vs existing repositories**
   ```bash
   if [ "$has_commits" = false ]; then
       # Fresh repo: checkout main branch
       git checkout -b main origin/main
   else
       # Existing repo: merge or fast-forward
       git merge --ff-only origin/main
   fi
   ```

4. **Better error handling**
   ```bash
   git merge --abort 2>/dev/null || true  # Suppress error if abort fails
   ```

## What Now Happens

### Scenario 1: Fresh Repository (No Commits)
```
✓ Fetch updates
✓ Initialize main branch (checkout -b main origin/main)
✓ Complete
```

### Scenario 2: Existing Repository
```
✓ Check for local changes
✓ Stash local changes (if any)
✓ Fetch updates
✓ Merge or fast-forward
✓ Reapply changes
✓ Complete
```

## Testing

Try the update again:

```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update-status
sudo ./linux-hardening-scripts/scripts/main.sh --update --dry-run
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

## Benefits

✅ Works with newly initialized repositories  
✅ Properly handles repositories with no commits  
✅ Still supports existing repositories  
✅ Better error handling  
✅ More robust stash/merge handling  

---

**Status**: ✅ Fixed and Ready
**Date**: November 30, 2025
