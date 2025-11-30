# Help Command Quick Card

## 🆘 Get Help Anytime

```bash
# Display full help with all options and examples
sudo ./linux-hardening-scripts/scripts/main.sh --help

# Or use the short form
sudo ./linux-hardening-scripts/scripts/main.sh -h

# For test script help
sudo ./linux-hardening-scripts/tests/test-hardening.sh --help
```

## 📋 What You'll See

When you run `--help`, you get:

✅ **All available command options**
```
--dry-run                     # Preview changes
--log-file <file>             # Custom log location
--exclude-modules <list>      # Skip specific modules
```

✅ **All hardening modules** (with CIS controls)
```
account-security              # Password & sudo (CIS 5.1-5.4)
bootloader-hardening          # GRUB security (CIS 1.5)
filesystem-hardening          # Mount & permissions (CIS 1.1-1.10)
...and 6 more modules
```

✅ **6 practical usage examples**
```
sudo ./main.sh --dry-run
sudo ./main.sh --exclude-modules ssh-hardening
...and more
```

✅ **Recommended workflow**
```
1. Run with --dry-run to preview
2. Review output carefully
3. Run without --dry-run to apply
4. Check logs for details
```

## 🎯 Quick Help for Common Questions

**"How do I preview changes?"**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
# Look for "QUICK START EXAMPLES" section
```

**"What modules are available?"**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
# Look for "AVAILABLE MODULES" section
```

**"How do I skip SSH hardening?"**
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
# Look for "EXAMPLES" section - shows --exclude-modules
```

**"How do I run tests?"**
```bash
sudo ./linux-hardening-scripts/tests/test-hardening.sh --help
# Shows test options and examples
```

## 💡 Pro Tips

### Save Help to File
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help > hardening_help.txt
cat hardening_help.txt
```

### Search Help
```bash
# Find specific module in help
sudo ./linux-hardening-scripts/scripts/main.sh --help | grep ssh

# Find examples in help
sudo ./linux-hardening-scripts/scripts/main.sh --help | grep EXAMPLE -A 3
```

### View with Pager
```bash
# For long help output
sudo ./linux-hardening-scripts/scripts/main.sh --help | less
```

### Quick Syntax Check
```bash
# If you try invalid option, you get:
sudo ./linux-hardening-scripts/scripts/main.sh --invalid
# Error: Unknown option: --invalid
# Usage: ./main.sh [OPTIONS]
# Try './main.sh --help' for more information.
```

## 📚 Help Files Documentation

| File | Purpose | Read When |
|------|---------|-----------|
| `--help` output | Quick reference | You need to see all options |
| `HELP_GUIDE.md` | Detailed help guide | You want comprehensive help info |
| `HELP_SYSTEM.md` | Implementation details | You want technical details |
| `QUICK_REFERENCE.md` | Common commands | You want one-liner examples |
| `README.md` | Full documentation | You want complete information |

## 🚦 Help Exit Codes

- **Exit 0** (success): When you use `--help` or `-h`
- **Exit 1** (error): When you use invalid option

This means scripts don't run when showing help - they just show help and exit.

## 🔗 Flow: When Help Gets Shown

```
User runs script
    ↓
Has --help or -h flag?
    ↓ Yes
    → Shows help → Exits with code 0
    ↓ No
Invalid/missing arguments?
    ↓ Yes
    → Shows error + usage_short
    → Suggests: Try './main.sh --help'
    → Exits with code 1
    ↓ No
Continue with execution
```

## ✨ What Makes This Help Great

✅ Works with `-h` (short) or `--help` (long)
✅ Shows ALL options in one place
✅ Includes practical examples
✅ Lists all modules with CIS mappings
✅ Shows recommended workflow
✅ Provides error guidance
✅ Cross-references other docs
✅ Professional formatting
✅ Easy to scan
✅ Covers safety concerns

## 🎓 Learning Path

**Step 1**: Display help
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
```

**Step 2**: Read through the sections
- Description (what it does)
- Options (what flags available)
- Modules (what it can harden)
- Examples (how to use it)

**Step 3**: Try a command
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

**Step 4**: Check other documentation if needed
- README.md for full details
- QUICK_REFERENCE.md for more examples
- HELP_GUIDE.md for comprehensive help info

## 🆘 When Help Isn't Enough

If `--help` doesn't answer your question:
1. Check `QUICK_REFERENCE.md` for examples
2. Read `README.md` for comprehensive docs
3. See `HELP_GUIDE.md` for help system details
4. Review logs in `logs/` directory
5. Check module script files for specifics

---

**Remember**: When in doubt, use `--help`! 🤔
