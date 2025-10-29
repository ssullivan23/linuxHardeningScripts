#!/bin/bash

################################################################################
# Script: remove-hacking-tools.sh
# Purpose: Detect and remove common hacking/penetration testing tools
# Usage: sudo bash remove-hacking-tools.sh [--dry-run] [--aggressive]
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
DRY_RUN=false
AGGRESSIVE=false
REMOVED_COUNT=0
FOUND_COUNT=0

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --dry-run|-d) 
            DRY_RUN=true 
            ;;
        --aggressive|-a) 
            AGGRESSIVE=true 
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Remove common hacking/penetration testing tools from the system."
            echo ""
            echo "Options:"
            echo "  --dry-run, -d      Show what would be removed without actually removing"
            echo "  --aggressive, -a   Also remove development tools that could be misused"
            echo "  --help, -h         Display this help message"
            echo ""
            echo "Tools Removed (Standard Mode):"
            echo "  - Network analyzers: Wireshark, tcpdump, nmap, netcat"
            echo "  - Password crackers: John the Ripper, Hashcat, Ophcrack, Hydra"
            echo "  - Exploitation frameworks: Metasploit, BeEF, Social Engineer Toolkit"
            echo "  - Wireless tools: Aircrack-ng, Reaver, Kismet, Wifite"
            echo "  - Vulnerability scanners: Nikto, OpenVAS, Nessus"
            echo "  - Games: Aisleriot, games packages"
            echo ""
            echo "Additional Tools Removed (Aggressive Mode):"
            echo "  - Compilers: gcc, g++, make"
            echo "  - Debuggers: gdb, strace, ltrace"
            echo "  - Development tools: git, subversion"
            echo ""
            echo "WARNING: This script will remove packages. Always run with --dry-run first!"
            exit 0
            ;;
        *) 
            echo "Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1 
            ;;
    esac
    shift
done

# Check if running as root
if [ "$EUID" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    echo -e "${RED}ERROR: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=$(detect_package_manager)

if [ "$PKG_MANAGER" = "unknown" ]; then
    echo -e "${RED}ERROR: Could not detect package manager${NC}"
    exit 1
fi

# Function to check if package is installed
is_package_installed() {
    local package="$1"
    
    case $PKG_MANAGER in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        yum|dnf)
            rpm -q "$package" &>/dev/null
            ;;
        zypper)
            zypper se -i "$package" 2>/dev/null | grep -q "^i"
            ;;
        pacman)
            pacman -Q "$package" &>/dev/null
            ;;
    esac
}

# Function to remove package
remove_package() {
    local package="$1"
    local description="$2"
    
    if is_package_installed "$package"; then
        ((FOUND_COUNT++))
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "  ${YELLOW}[DRY RUN]${NC} Would remove: ${RED}$package${NC} - $description"
        else
            echo -e "  ${RED}Removing:${NC} $package - $description"
            
            case $PKG_MANAGER in
                apt)
                    apt-get remove --purge -y "$package" &>/dev/null
                    apt-get autoremove -y &>/dev/null
                    ;;
                yum)
                    yum remove -y "$package" &>/dev/null
                    ;;
                dnf)
                    dnf remove -y "$package" &>/dev/null
                    ;;
                zypper)
                    zypper remove -y "$package" &>/dev/null
                    ;;
                pacman)
                    pacman -R --noconfirm "$package" &>/dev/null
                    ;;
            esac
            
            if [ $? -eq 0 ]; then
                echo -e "    ${GREEN}✓ Successfully removed${NC}"
                ((REMOVED_COUNT++))
            else
                echo -e "    ${YELLOW}⚠ Failed to remove${NC}"
            fi
        fi
    fi
}

# Header
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}              HACKING TOOLS & UNWANTED SOFTWARE REMOVAL${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Hostname: $(hostname)"
echo -e "Package Manager: $PKG_MANAGER"
if [ "$DRY_RUN" = true ]; then
    echo -e "Mode: ${YELLOW}DRY RUN${NC} (no changes will be made)"
else
    echo -e "Mode: ${RED}LIVE REMOVAL${NC}"
fi
if [ "$AGGRESSIVE" = true ]; then
    echo -e "Level: ${RED}AGGRESSIVE${NC} (includes development tools)"
else
    echo -e "Level: ${GREEN}STANDARD${NC}"
fi
echo ""

# Network Analysis Tools
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    NETWORK ANALYSIS TOOLS                           ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "wireshark" "Network protocol analyzer"
remove_package "wireshark-qt" "Wireshark GUI"
remove_package "wireshark-gtk" "Wireshark GTK GUI"
remove_package "wireshark-common" "Wireshark common files"
remove_package "tshark" "Wireshark command-line tool"
remove_package "tcpdump" "Command-line packet analyzer"
remove_package "libpcap0.8" "Packet capture library"
remove_package "libpcap-dev" "Packet capture library (dev)"
remove_package "nmap" "Network exploration and security scanner"
remove_package "zenmap" "Nmap GUI"
remove_package "netcat" "TCP/IP swiss army knife"
remove_package "netcat-traditional" "Netcat traditional"
remove_package "netcat-openbsd" "OpenBSD netcat"
remove_package "nc" "Netcat"
remove_package "socat" "Multipurpose relay"
remove_package "ettercap" "Network sniffer/interceptor"
remove_package "ettercap-graphical" "Ettercap GUI"
remove_package "dsniff" "Network auditing tool"
remove_package "snort" "Network intrusion detection system"

# Password Cracking Tools
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    PASSWORD CRACKING TOOLS                          ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "john" "John the Ripper password cracker"
remove_package "john-data" "John the Ripper data files"
remove_package "ophcrack" "Windows password cracker"
remove_package "ophcrack-cli" "Ophcrack CLI"
remove_package "hashcat" "Advanced password recovery"
remove_package "hydra" "Network login cracker"
remove_package "hydra-gtk" "Hydra GUI"
remove_package "medusa" "Parallel password cracker"
remove_package "crunch" "Wordlist generator"
remove_package "cewl" "Custom wordlist generator"
remove_package "rainbowcrack" "Rainbow table password cracker"
remove_package "truecrack" "TrueCrypt password cracker"

# Exploitation Frameworks
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    EXPLOITATION FRAMEWORKS                          ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "metasploit-framework" "Penetration testing framework"
remove_package "beef-xss" "Browser exploitation framework"
remove_package "armitage" "Metasploit GUI"
remove_package "set" "Social Engineering Toolkit"
remove_package "social-engineer-toolkit" "Social Engineering Toolkit"
remove_package "exploitdb" "Exploit database"
remove_package "sqlmap" "SQL injection tool"
remove_package "commix" "Command injection exploiter"

# Wireless Tools
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                       WIRELESS TOOLS                                ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "aircrack-ng" "Wireless network security tools"
remove_package "reaver" "WPS brute force attack tool"
remove_package "pixiewps" "WPS pixie dust attack tool"
remove_package "wifite" "Automated wireless attack tool"
remove_package "kismet" "Wireless network detector"
remove_package "fern-wifi-cracker" "Wireless security auditing tool"
remove_package "wifiphisher" "WiFi phishing tool"
remove_package "mdk3" "Wireless testing tool"
remove_package "cowpatty" "WPA-PSK dictionary attack"

# Vulnerability Scanners
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    VULNERABILITY SCANNERS                           ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "nikto" "Web server scanner"
remove_package "openvas" "Vulnerability scanner"
remove_package "openvas-scanner" "OpenVAS scanner"
remove_package "nessus" "Vulnerability scanner (commercial)"
remove_package "lynis" "Security auditing tool"
remove_package "skipfish" "Web application security scanner"
remove_package "wpscan" "WordPress security scanner"
remove_package "golismero" "Web application security scanner"
remove_package "uniscan" "Web vulnerability scanner"

# Forensics & Reverse Engineering
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                 FORENSICS & REVERSE ENGINEERING                     ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "binwalk" "Firmware analysis tool"
remove_package "foremost" "File carving tool"
remove_package "autopsy" "Digital forensics platform"
remove_package "sleuthkit" "Forensics toolkit"
remove_package "volatility" "Memory forensics framework"
remove_package "radare2" "Reverse engineering framework"
remove_package "ghidra" "Software reverse engineering suite"

# Web Application Testing
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                   WEB APPLICATION TESTING                           ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "burpsuite" "Web application security testing"
remove_package "zaproxy" "OWASP ZAP web app scanner"
remove_package "webscarab" "Web application security framework"
remove_package "w3af" "Web application attack framework"
remove_package "whatweb" "Web scanner"
remove_package "dirb" "Web content scanner"
remove_package "dirbuster" "Directory brute forcing"
remove_package "gobuster" "Directory/file brute forcing"

# Remote Access & Backdoors
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  REMOTE ACCESS & BACKDOORS                          ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "weevely" "Web shell"
remove_package "laudanum" "Web shell collection"
remove_package "powersploit" "PowerShell exploitation"
remove_package "veil" "Payload generator"
remove_package "veil-evasion" "AV evasion framework"

# Unwanted Services & Applications
echo ""
echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              UNWANTED SERVICES & APPLICATIONS                       ║${NC}"
echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

remove_package "apache2" "Apache web server"
remove_package "httpd" "Apache web server (RHEL)"
remove_package "nginx" "Nginx web server"
remove_package "aisleriot" "Solitaire card game"
remove_package "gnome-games" "GNOME games collection"
remove_package "gnome-games-extra-data" "GNOME games data"
remove_package "kdegames" "KDE games collection"
remove_package "mahjongg" "Mahjong game"
remove_package "gnome-mahjongg" "GNOME Mahjong"
remove_package "mines" "Minesweeper game"
remove_package "gnome-mines" "GNOME Minesweeper"
remove_package "quadrapassel" "Tetris-like game"
remove_package "gnome-sudoku" "Sudoku game"
remove_package "swell-foop" "Puzzle game"
remove_package "five-or-more" "Puzzle game"
remove_package "four-in-a-row" "Strategy game"
remove_package "gnome-tetravex" "Puzzle game"
remove_package "iagno" "Reversi game"
remove_package "lightsoff" "Puzzle game"
remove_package "tali" "Yahtzee-like game"

# Aggressive Mode - Development Tools
if [ "$AGGRESSIVE" = true ]; then
    echo ""
    echo -e "${RED}╔═════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║        DEVELOPMENT TOOLS (AGGRESSIVE MODE)                          ║${NC}"
    echo -e "${RED}╚═════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}WARNING: Removing development tools may impact system functionality!${NC}"
    echo ""
    
    remove_package "gcc" "GNU C compiler"
    remove_package "g++" "GNU C++ compiler"
    remove_package "make" "Build automation tool"
    remove_package "cmake" "Cross-platform build system"
    remove_package "gdb" "GNU debugger"
    remove_package "lldb" "LLVM debugger"
    remove_package "strace" "System call tracer"
    remove_package "ltrace" "Library call tracer"
    remove_package "valgrind" "Memory debugger"
    remove_package "git" "Version control system"
    remove_package "subversion" "Version control system"
    remove_package "mercurial" "Version control system"
    remove_package "perl" "Perl programming language"
    remove_package "python3-pip" "Python package installer"
    remove_package "ruby" "Ruby programming language"
    remove_package "golang" "Go programming language"
fi

# Summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                              SUMMARY${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo -e "  ${YELLOW}Tools Found:${NC}        $FOUND_COUNT"
    echo -e "  ${YELLOW}Would Remove:${NC}       $FOUND_COUNT"
    echo ""
    echo -e "${YELLOW}This was a DRY RUN. No packages were actually removed.${NC}"
    echo -e "${YELLOW}Run without --dry-run to actually remove these packages.${NC}"
else
    echo -e "  ${RED}Tools Found:${NC}        $FOUND_COUNT"
    echo -e "  ${GREEN}Successfully Removed:${NC} $REMOVED_COUNT"
    
    if [ $REMOVED_COUNT -lt $FOUND_COUNT ]; then
        echo -e "  ${YELLOW}Failed to Remove:${NC}   $((FOUND_COUNT - REMOVED_COUNT))"
    fi
    
    echo ""
    
    if [ $REMOVED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓ Successfully removed $REMOVED_COUNT potentially unwanted packages${NC}"
        
        # Cleanup
        echo ""
        echo -e "${CYAN}Cleaning up...${NC}"
        case $PKG_MANAGER in
            apt)
                apt-get autoremove -y &>/dev/null
                apt-get autoclean -y &>/dev/null
                echo -e "  ${GREEN}✓ Cleaned up unused dependencies${NC}"
                ;;
            yum)
                yum autoremove -y &>/dev/null
                echo -e "  ${GREEN}✓ Cleaned up unused dependencies${NC}"
                ;;
            dnf)
                dnf autoremove -y &>/dev/null
                echo -e "  ${GREEN}✓ Cleaned up unused dependencies${NC}"
                ;;
        esac
    else
        echo -e "${GREEN}✓ No unwanted packages found on this system${NC}"
    fi
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

# Security recommendations
if [ "$REMOVED_COUNT" -gt 0 ] && [ "$DRY_RUN" = false ]; then
    echo -e "${CYAN}SECURITY RECOMMENDATIONS:${NC}"
    echo ""
    echo -e "  1. Review system logs for any suspicious activity"
    echo -e "  2. Check for unauthorized user accounts"
    echo -e "  3. Verify no backdoors or web shells remain: find /var/www -name '*.php' -type f"
    echo -e "  4. Review cron jobs: crontab -l && ls /etc/cron.*"
    echo -e "  5. Check for unusual processes: ps aux | grep -v root"
    echo -e "  6. Review network connections: netstat -tulpn or ss -tulpn"
    echo ""
fi

exit 0
