# Fix Permission Denied Error for updater.sh

## Problem
When running:
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --update
```

You get:
```
./linux-hardening-scripts/scripts/main.sh: line 138: /home/mittromney/linuxHardeningScripts/linux-hardening-scripts/scripts/utils/updater.sh: Permission denied
```

## Root Cause
The `updater.sh` script doesn't have execute permissions set.

## Solution

### On Linux/Ubuntu System

Run this command to make the script executable:

```bash
chmod +x ~/linuxHardeningScripts/linux-hardening-scripts/scripts/utils/updater.sh
```

Or with full path:

```bash
chmod +x /home/mittromney/linuxHardeningScripts/linux-hardening-scripts/scripts/utils/updater.sh
```

### Verify Permissions

Check that the file now has execute permissions:

```bash
ls -la ~/linuxHardeningScripts/linux-hardening-scripts/scripts/utils/updater.sh
```

You should see output like:
```
-rwxr-xr-x 1 mittromney mittromney 12345 Nov 30 12:34 updater.sh
```

The `x` in `rwxr-xr-x` indicates execute permissions ✓

### Fix All Scripts at Once

Make all scripts executable in the utils directory:

```bash
chmod +x ~/linuxHardeningScripts/linux-hardening-scripts/scripts/utils/*.sh
```

Or all hardening scripts:

```bash
chmod +x ~/linuxHardeningScripts/linux-hardening-scripts/scripts/hardening/*.sh
chmod +x ~/linuxHardeningScripts/linux-hardening-scripts/scripts/utils/*.sh
chmod +x ~/linuxHardeningScripts/linux-hardening-scripts/scripts/main.sh
chmod +x ~/linuxHardeningScripts/linux-hardening-scripts/tests/test-hardening.sh
```

## After Fixing

Now retry the update command:

```bash
sudo ~/linuxHardeningScripts/linux-hardening-scripts/scripts/main.sh --update-status
```

Or:

```bash
sudo ~/linuxHardeningScripts/linux-hardening-scripts/scripts/main.sh --update --dry-run
```

---

## Prevention

To prevent this issue in the future:

### Option 1: When Cloning Repository
```bash
git clone https://github.com/ssullivan23/linuxHardeningScripts.git
cd linuxHardeningScripts/linux-hardening-scripts
chmod +x scripts/*.sh scripts/utils/*.sh scripts/hardening/*.sh tests/*.sh
```

### Option 2: Create .gitattributes File

Add this to `.gitattributes` in repository root to auto-set permissions:

```
*.sh text eol=lf
scripts/main.sh export-ignore
scripts/**/*.sh export-ignore
tests/**/*.sh export-ignore
```

Then Git will preserve execute permissions when cloning.

### Option 3: Use Setup Script

Create a setup script that runs on first use:

```bash
#!/bin/bash
chmod +x scripts/*.sh
chmod +x scripts/utils/*.sh
chmod +x scripts/hardening/*.sh
chmod +x tests/*.sh
echo "✓ All scripts are now executable"
```

---

## Why This Happens

When files are created or transferred:
- ✓ Files have read/write permissions by default
- ✗ Files don't have execute permissions by default
- ✓ Must be explicitly set with `chmod +x`

The updater.sh script needs execute permissions to run.

---

## Quick Fix Command

**Copy and paste this into your Linux terminal:**

```bash
chmod +x /home/mittromney/linuxHardeningScripts/linux-hardening-scripts/scripts/utils/updater.sh && echo "✓ updater.sh is now executable"
```

Then test:

```bash
sudo /home/mittromney/linuxHardeningScripts/linux-hardening-scripts/scripts/main.sh --update-status
```

Should work now! ✓
