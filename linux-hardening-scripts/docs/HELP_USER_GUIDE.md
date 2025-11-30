# Help System - User Quick Start

## 🎯 What You Can Now Do

### Get Help Instantly

```bash
# Display comprehensive help
sudo ./linux-hardening-scripts/scripts/main.sh --help

# Or use short form
sudo ./linux-hardening-scripts/scripts/main.sh -h

# For test script help
sudo ./linux-hardening-scripts/tests/test-hardening.sh --help
```

## 📺 Help Output Preview

When you run `--help`, you see:

```
╔════════════════════════════════════════════════════════════════════════════╗
║          CIS Ubuntu Linux 22.04 Hardening Tool - Main Orchestrator         ║
╚════════════════════════════════════════════════════════════════════════════╝

DESCRIPTION:
  Orchestrates Linux system hardening based on CIS Ubuntu Linux 22.04 LTS
  Benchmark v3.0.0. Supports compartmentalized module execution with dry-run
  capability and selective module inclusion/exclusion.

OPTIONS:
  -h, --help                    Display this help message and exit
  --dry-run                     Preview all changes without making modifications
  --log-file <file>             Specify custom log file location
  --exclude-modules <list>      Comma-separated list of modules to skip

AVAILABLE MODULES:
  account-security              Password policies, sudo (CIS 5.1-5.4)
  bootloader-hardening          GRUB security (CIS 1.5)
  filesystem-hardening          Mount options and permissions (CIS 1.1-1.10)
  firewall-setup                Firewall configuration (CIS 3.4)
   kernel-hardening              REMOVED (module removed from repository)
  network-hardening             Network stack (CIS 3.1-3.3)
  service-hardening             Service management (CIS 2.x)
  ssh-hardening                 SSH configuration (CIS 5.2)
  user-security                 User permissions (CIS 5.1-5.5, 6.x)

QUICK START EXAMPLES:

  1. Preview all changes (dry-run, always do this first):
     sudo ./linux-hardening-scripts/scripts/main.sh --dry-run

  2. Apply all hardening:
     sudo ./linux-hardening-scripts/scripts/main.sh

  3. Skip SSH hardening:
     sudo ./linux-hardening-scripts/scripts/main.sh --dry-run --exclude-modules ssh-hardening

  [... more examples and workflow info ...]
```

## ✨ What This Gives You

✅ **All Options Listed**
- See what flags you can use
- Understand what each does
- Know required arguments

✅ **All Modules Documented**
- See all 9 available modules
- Know which CIS controls each covers
- Pick which ones you need

✅ **Practical Examples**
- 6 ready-to-use command examples
- Common scenarios covered
- Copy-paste friendly

✅ **Workflow Guidance**
- Best practices explained
- Safety recommendations
- Recommended steps

✅ **Important Safety Notes**
- Backup reminders
- Testing recommendations
- Access requirements

✅ **Documentation Links**
- References to detailed docs
- Where to find more info
- Cross-references

## 🚀 Typical User Journey

### Step 1: Get Help
```bash
$ sudo ./linux-hardening-scripts/scripts/main.sh --help
```

### Step 2: Review Options
- See all available flags
- Understand module list
- Review examples

### Step 3: Try Dry-Run
```bash
$ sudo ./linux-hardening-scripts/scripts/main.sh --dry-run
```

### Step 4: Review Output
- Check what would change
- Read recommendations
- Make sure it's what you want

### Step 5: Apply Hardening
```bash
$ sudo ./linux-hardening-scripts/scripts/main.sh
```

### Step 6: Verify Results
- Check logs directory
- Test affected services
- Verify compliance

## 💡 Common Help Commands

### See Help for Main Script
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help
```

### See Help for Tests
```bash
sudo ./linux-hardening-scripts/tests/test-hardening.sh -h
```

### Find a Specific Module
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help | grep ssh
```

### Save Help to File
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help > help.txt
cat help.txt
```

### View with Scrolling
```bash
sudo ./linux-hardening-scripts/scripts/main.sh --help | less
```

## 🎓 What You'll Learn from Help

### Options Section
Learn all 4 available command-line flags:
- `-h` / `--help` - Get help
- `--dry-run` - Preview mode
- `--log-file` - Custom logging
- `--exclude-modules` - Skip modules

### Modules Section
See all 9 hardening modules:
- Their purpose (one line)
- What CIS controls they cover
- Examples in quick start section

### Examples Section
Get 6 ready-to-use command examples:
1. Preview everything (safest start)
2. Apply all hardening
3. Skip one module
4. Skip multiple modules
5. Use custom log file
6. Combine multiple options

### Workflow Section
Learn recommended 4-step process:
1. Dry-run preview
2. Review output
3. Apply changes
4. Check logs

## 🆘 Error Help

### If You See This Error
```bash
Error: Unknown option: --invalid
Usage: ./main.sh [OPTIONS]
Try './main.sh --help' for more information.
```

**What to do**: Run the suggested command!
```bash
./main.sh --help
```

### If You Forget an Argument
```bash
Error: --log-file requires an argument
Usage: ./main.sh [OPTIONS]
Try './main.sh --help' for more information.
```

**What to do**: See examples in help
```bash
./main.sh --help | grep "log-file" -A 2
```

## 📚 Related Documentation

After viewing help, explore:
- **QUICK_REFERENCE.md** - More usage examples
- **README.md** - Full documentation
- **HELP_GUIDE.md** - Detailed help system guide
- **QUICK_REFERENCE.md** - Common patterns

## 🎯 Key Features of Help System

✅ **Easy Access**
- `-h` (short) or `--help` (long)
- Works with both scripts

✅ **Comprehensive**
- Shows all options
- Lists all modules
- Provides examples
- Includes workflow

✅ **Professional**
- ASCII art headers
- Clean formatting
- Organized sections
- Proper spacing

✅ **Helpful**
- Clear descriptions
- Practical examples
- Safety warnings
- Documentation links

✅ **Safe**
- Proper exit codes
- Clear error messages
- Dry-run examples
- Safety reminders

## 🚦 Exit Codes Explained

| Action | Exit Code | Meaning |
|--------|-----------|---------|
| `--help` displayed | 0 | Success (help shown, no execution) |
| Normal execution | 0 | Success (command completed) |
| Invalid option | 1 | Error (fix syntax and retry) |
| Missing argument | 1 | Error (add required argument) |

## 📝 Quick Reference

```bash
# MAIN SCRIPT HELP
sudo ./linux-hardening-scripts/scripts/main.sh -h          # Short form
sudo ./linux-hardening-scripts/scripts/main.sh --help      # Long form

# TEST SCRIPT HELP
sudo ./linux-hardening-scripts/tests/test-hardening.sh -h  # Short form
sudo ./linux-hardening-scripts/tests/test-hardening.sh --help # Long form

# SAVE TO FILE
sudo ./linux-hardening-scripts/scripts/main.sh --help > main_help.txt

# SEARCH IN HELP
sudo ./linux-hardening-scripts/scripts/main.sh --help | grep OPTIONS

# VIEW WITH PAGER
sudo ./linux-hardening-scripts/scripts/main.sh --help | less
```

## 🎓 Learning Tips

1. **First Time?**
   - Start with: `--help`
   - Read all sections
   - Try example #1 (dry-run)

2. **Need Specific Info?**
   - Use grep to search help
   - `--help | grep module-name`
   - `--help | grep EXAMPLE`

3. **Want More Details?**
   - Read QUICK_REFERENCE.md
   - Read README.md
   - Read HELP_GUIDE.md

4. **Forgotten Syntax?**
   - Run with --help
   - Copy an example
   - Modify as needed

## ✨ Summary

The help system makes it easy to:
- **Discover** all available options
- **Understand** what each does
- **Learn** recommended workflows
- **Find** usage examples
- **Remember** command syntax
- **Make informed decisions** about hardening

Just use: `--help` or `-h` 🆘

---

**Remember**: Help is always one flag away!
