# Audit Report Quick Reference

## Color Legend

| Symbol | Color | Meaning |
|--------|-------|---------|
| `✓` | 🟢 Green | Success - action completed |
| `✗` | 🔴 Red | Error - action failed |
| `⚠` | 🟡 Yellow | Warning - caution needed |
| `ℹ` | 🔵 Blue | Info - informational message |

## Report Types

### Summary Report
**Shows**: High-level overview of all actions taken
**When**: Displayed at end of hardening execution
**Contains**: Success count, warning count, error count

### Detailed Report
**Shows**: Complete log with timestamps and full details
**When**: Available in log file after execution
**Contains**: Every action, system info, timestamps

## Reading the Reports

### Quick Status Check
Look at the statistics block:
- 0 Errors = Everything OK ✅
- >0 Errors = Issues to review ⚠️
- >0 Warnings = Check warnings ⚡

### Finding Issues
Search for:
- **Red (✗)** = Problems that need attention
- **Yellow (⚠)** = Cautions and notices

### Finding Successes
Look for:
- **Green (✓)** = Completed actions
- Count in statistics for total

## Usage Commands

```bash
# View colored summary (dry-run)
sudo ./scripts/main.sh --dry-run

# View colored summary (live)
sudo ./scripts/main.sh

# Save to file
sudo ./scripts/main.sh > audit.log 2>&1

# View with colors in pager
sudo ./scripts/main.sh | less -R

# Email report
sudo ./scripts/main.sh | mail -s "Audit" admin@example.com
```

## Sample Output Interpretation

```
✓ SSH hardening completed: 8 changes applied
  → Successful action completed

ℹ Configuring network parameters...
  → Work in progress / informational

⚠ USB storage module not available
  → Warning but not critical

✗ Failed to apply firewall rules
  → ERROR - requires investigation
```

## Statistics Meaning

```
Summary Statistics:
  Success Messages:  12    ← How many actions succeeded
  Info Messages:     8     ← How many info entries logged
  Warnings:          2     ← How many warnings issued
  Errors:            0     ← How many errors occurred
```

**Ideal**: Low errors, few warnings, many successes

## Next Steps

✅ **If Errors = 0 and Warnings are few:**
- Review warnings (they're usually safe)
- Hardening is complete

⚠️ **If Errors > 0:**
1. Look for red (✗) lines
2. Read error messages carefully
3. Check logs for details
4. Fix the issue
5. Re-run hardening

## Tips

- **Use fullscreen terminal** for best readability
- **Copy output** before closing terminal (right-click → select all → copy)
- **Save important audits** for compliance records
- **Run weekly** to catch any issues early

---

For more details, see [AUDIT_REPORT_FORMATTING.md](AUDIT_REPORT_FORMATTING.md)
