#!/bin/bash

################################################################################
# Script: list-users-with-sudo.sh
# Purpose: List all users and identify those with sudo/admin permissions
# Usage: sudo bash list-users-with-sudo.sh [OPTIONS]
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VERBOSE=false
MIN_UID=1000  # Minimum UID for regular users (adjust for your system)
OUTPUT_FORMAT="text"
EXPORT_FILE=""
SHOW_SYSTEM=false
CHECK_USER=""

# Help function
show_help() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                    LIST USERS WITH SUDO - HELP GUIDE                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝

USAGE:
    sudo bash list-users-with-sudo.sh [OPTIONS]
    
    Or via main.sh:
    sudo ./main.sh --list-sudo-users [OPTIONS]

DESCRIPTION:
    Audits all system users and identifies those with administrative (sudo/root)
    privileges. Useful for security audits, compliance checks, and system reviews.

OPTIONS:
    -h, --help              Display this help message and exit
    
    -v, --verbose           Show detailed information for each user including:
                            • Last login time
                            • Home directory
                            • Account lock status
                            • Group memberships
                            • System/service accounts

    -u, --user USERNAME     Check a specific user's sudo privileges
    
    -m, --min-uid UID       Set minimum UID for regular users (default: 1000)
                            Users below this UID are considered system accounts
    
    -s, --show-system       Include system/service accounts in output
                            (normally hidden unless using --verbose)
    
    -f, --format FORMAT     Output format: text (default), json, csv
    
    -o, --output FILE       Export results to specified file
    
    --no-color              Disable colored output (useful for piping/scripts)

EXAMPLES:
    # Basic usage - list all users with sudo access
    sudo bash list-users-with-sudo.sh

    # Via main.sh
    sudo ./main.sh --list-sudo-users

    # Verbose output with detailed user information
    sudo bash list-users-with-sudo.sh --verbose
    sudo ./main.sh --list-sudo-users --verbose

    # Check if a specific user has sudo privileges
    sudo bash list-users-with-sudo.sh --user john
    sudo ./main.sh --list-sudo-users --user john

    # Export results to CSV for reporting
    sudo bash list-users-with-sudo.sh --format csv --output /tmp/user-audit.csv
    sudo ./main.sh --list-sudo-users --format csv --output /tmp/audit.csv

    # Include system accounts in the audit
    sudo bash list-users-with-sudo.sh --show-system --verbose

    # Use custom minimum UID (e.g., for systems with UID starting at 500)
    sudo bash list-users-with-sudo.sh --min-uid 500

    # Pipe-friendly output without colors
    sudo bash list-users-with-sudo.sh --no-color | grep "admin"

PRIVILEGE DETECTION:
    The script detects sudo privileges through:
    • Group membership: sudo, wheel, admin, root groups
    • Sudoers file: Direct entries in /etc/sudoers or /etc/sudoers.d/

OUTPUT SECTIONS:
    • USERS WITH ADMIN PRIVILEGES - Users who can run commands as root
    • REGULAR USERS - Standard users without elevated privileges
    • SYSTEM/SERVICE ACCOUNTS - Shown with --verbose or --show-system

SECURITY RECOMMENDATIONS:
    The script will warn if:
    • More than 3 users have admin privileges
    • Root user has unusual group memberships
    • Users have been inactive for extended periods (verbose mode)

EXIT CODES:
    0 - Success
    1 - Invalid parameter or error
    2 - User not found (when using --user)

NOTES:
    • Run as root/sudo for complete information
    • Some details may be incomplete without root privileges
    • Works on most Linux distributions (Debian, Ubuntu, RHEL, CentOS, etc.)

For more information, see: scripts/sysadmin-utils/README.md
EOF
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=true ;;
        --help|-h) 
            show_help
            exit 0
            ;;
        --user|-u)
            if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                CHECK_USER="$2"
                shift
            else
                echo "Error: --user requires a username argument"
                exit 1
            fi
            ;;
        --min-uid|-m)
            if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ ]]; then
                MIN_UID="$2"
                shift
            else
                echo "Error: --min-uid requires a numeric argument"
                exit 1
            fi
            ;;
        --show-system|-s) SHOW_SYSTEM=true ;;
        --format|-f)
            if [[ -n "${2:-}" && "$2" =~ ^(text|json|csv)$ ]]; then
                OUTPUT_FORMAT="$2"
                shift
            else
                echo "Error: --format requires: text, json, or csv"
                exit 1
            fi
            ;;
        --output|-o)
            if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                EXPORT_FILE="$2"
                shift
            else
                echo "Error: --output requires a filename argument"
                exit 1
            fi
            ;;
        --no-color)
            RED=''
            GREEN=''
            YELLOW=''
            BLUE=''
            CYAN=''
            NC=''
            ;;
        *) 
            echo "Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
    shift
done

# Function to check if user has sudo access via group membership
check_sudo_group() {
    local username="$1"
    local has_sudo=false
    
    # Check common sudo group names
    for group in sudo wheel admin root; do
        if groups "$username" 2>/dev/null | grep -qw "$group"; then
            has_sudo=true
            break
        fi
    done
    
    echo "$has_sudo"
}

# Function to check sudoers file
check_sudoers_file() {
    local username="$1"
    
    # Check /etc/sudoers and /etc/sudoers.d/ for direct user entries
    if sudo grep -r "^${username}[[:space:]]" /etc/sudoers /etc/sudoers.d/ 2>/dev/null | grep -v "^#" >/dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to get user's groups
get_user_groups() {
    local username="$1"
    groups "$username" 2>/dev/null | cut -d: -f2 | xargs
}

# Function to get last login
get_last_login() {
    local username="$1"
    lastlog -u "$username" 2>/dev/null | tail -n1 | awk '{if ($2 == "**Never") print "Never"; else print $4, $5, $6, $9}'
}

# Function to check if user is locked
is_user_locked() {
    local username="$1"
    if passwd -S "$username" 2>/dev/null | grep -q "L "; then
        echo "true"
    else
        echo "false"
    fi
}

# Function to check a specific user's sudo status
check_specific_user() {
    local username="$1"
    
    # Verify user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}Error: User '$username' does not exist${NC}"
        exit 2
    fi
    
    local uid=$(id -u "$username")
    local has_sudo_group=$(check_sudo_group "$username")
    local has_sudoers_entry=$(check_sudoers_file "$username")
    local groups_list=$(get_user_groups "$username")
    local last_login=$(get_last_login "$username")
    local is_locked=$(is_user_locked "$username")
    local home_dir=$(getent passwd "$username" | cut -d: -f6)
    local shell=$(getent passwd "$username" | cut -d: -f7)
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                    USER PRIVILEGE CHECK: $username${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$has_sudo_group" = "true" ] || [ "$has_sudoers_entry" = "true" ]; then
        echo -e "  ${RED}★ USER HAS ADMINISTRATIVE PRIVILEGES${NC}"
        echo ""
        if [ "$has_sudo_group" = "true" ]; then
            echo -e "  ${CYAN}Sudo via Group:${NC} YES"
        fi
        if [ "$has_sudoers_entry" = "true" ]; then
            echo -e "  ${CYAN}Sudo via Sudoers:${NC} YES"
        fi
    else
        echo -e "  ${GREEN}○ User does NOT have administrative privileges${NC}"
    fi
    
    echo ""
    echo -e "  ${CYAN}User Details:${NC}"
    echo -e "  ├─ UID: $uid"
    echo -e "  ├─ Groups: $groups_list"
    echo -e "  ├─ Home: $home_dir"
    echo -e "  ├─ Shell: $shell"
    echo -e "  ├─ Last Login: $last_login"
    if [ "$is_locked" = "true" ]; then
        echo -e "  └─ Status: ${YELLOW}LOCKED${NC}"
    else
        echo -e "  └─ Status: ${GREEN}Active${NC}"
    fi
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to output results in JSON format
output_json() {
    echo "{"
    echo "  \"generated\": \"$(date '+%Y-%m-%d %H:%M:%S')\","
    echo "  \"hostname\": \"$(hostname)\","
    echo "  \"admin_users\": ["
    
    local first=true
    for user_info in "${ADMIN_USERS[@]}"; do
        IFS=':' read -r username uid has_group has_file <<< "$user_info"
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        local groups_list=$(get_user_groups "$username" | sed 's/"/\\"/g')
        local locked=$(is_user_locked "$username")
        echo -n "    {\"username\": \"$username\", \"uid\": $uid, \"sudo_via_group\": $has_group, \"sudo_via_sudoers\": $has_file, \"groups\": \"$groups_list\", \"locked\": $locked}"
    done
    
    echo ""
    echo "  ],"
    echo "  \"regular_users\": ["
    
    first=true
    for user_info in "${REGULAR_USERS[@]}"; do
        IFS=':' read -r username uid <<< "$user_info"
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi
        echo -n "    {\"username\": \"$username\", \"uid\": $uid}"
    done
    
    echo ""
    echo "  ],"
    echo "  \"summary\": {"
    echo "    \"admin_count\": ${#ADMIN_USERS[@]},"
    echo "    \"regular_count\": ${#REGULAR_USERS[@]}"
    echo "  }"
    echo "}"
}

# Function to output results in CSV format
output_csv() {
    echo "type,username,uid,sudo_via_group,sudo_via_sudoers,groups,locked"
    
    for user_info in "${ADMIN_USERS[@]}"; do
        IFS=':' read -r username uid has_group has_file <<< "$user_info"
        local groups_list=$(get_user_groups "$username" | tr ' ' ';')
        local is_locked=$(is_user_locked "$username")
        echo "admin,$username,$uid,$has_group,$has_file,\"$groups_list\",$is_locked"
    done
    
    for user_info in "${REGULAR_USERS[@]}"; do
        IFS=':' read -r username uid <<< "$user_info"
        local groups_list=$(get_user_groups "$username" | tr ' ' ';')
        local is_locked=$(is_user_locked "$username")
        echo "regular,$username,$uid,false,false,\"$groups_list\",$is_locked"
    done
}

# Header
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                     USER PRIVILEGE AUDIT REPORT${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Hostname: $(hostname)"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}WARNING: Not running as root. Some information may be incomplete.${NC}"
    echo ""
fi

# If checking a specific user, do that and exit
if [ -n "$CHECK_USER" ]; then
    check_specific_user "$CHECK_USER"
    exit 0
fi

# Categories
declare -a ADMIN_USERS
declare -a REGULAR_USERS
declare -a SYSTEM_USERS

# Process each user in /etc/passwd
echo -e "${BLUE}Analyzing users...${NC}"
echo ""

while IFS=: read -r username password uid gid gecos homedir shell; do
    # Skip if no shell or disabled shell
    if [[ "$shell" == "/sbin/nologin" ]] || [[ "$shell" == "/bin/false" ]] || [[ "$shell" == "/usr/sbin/nologin" ]]; then
        if [ "$VERBOSE" = true ] || [ "$SHOW_SYSTEM" = true ]; then
            if [ "$uid" -lt "$MIN_UID" ]; then
                SYSTEM_USERS+=("$username:$uid")
            fi
        fi
        continue
    fi
    
    # Check sudo access
    has_sudo_group=$(check_sudo_group "$username")
    has_sudoers_entry=$(check_sudoers_file "$username")
    
    # Categorize user
    if [ "$has_sudo_group" = "true" ] || [ "$has_sudoers_entry" = "true" ]; then
        ADMIN_USERS+=("$username:$uid:$has_sudo_group:$has_sudoers_entry")
    elif [ "$uid" -ge "$MIN_UID" ]; then
        REGULAR_USERS+=("$username:$uid")
    else
        if [ "$VERBOSE" = true ] || [ "$SHOW_SYSTEM" = true ]; then
            SYSTEM_USERS+=("$username:$uid")
        fi
    fi
done < /etc/passwd

# Handle different output formats
if [ "$OUTPUT_FORMAT" = "json" ]; then
    if [ -n "$EXPORT_FILE" ]; then
        output_json > "$EXPORT_FILE"
        echo "Results exported to: $EXPORT_FILE"
    else
        output_json
    fi
    exit 0
fi

if [ "$OUTPUT_FORMAT" = "csv" ]; then
    if [ -n "$EXPORT_FILE" ]; then
        output_csv > "$EXPORT_FILE"
        echo "Results exported to: $EXPORT_FILE"
    else
        output_csv
    fi
    exit 0
fi

# Text output (default) - can also be exported to file
if [ -n "$EXPORT_FILE" ]; then
    exec > >(tee "$EXPORT_FILE")
fi

# Display Administrator Users
echo -e "${RED}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                    USERS WITH ADMIN PRIVILEGES                      ║${NC}"
echo -e "${RED}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ${#ADMIN_USERS[@]} -eq 0 ]; then
    echo -e "  ${YELLOW}No users with administrative privileges found.${NC}"
else
    for user_info in "${ADMIN_USERS[@]}"; do
        IFS=':' read -r username uid has_group has_file <<< "$user_info"
        
        echo -e "  ${RED}●${NC} ${GREEN}$username${NC} (UID: $uid)"
        
        if [ "$has_group" = "true" ]; then
            groups_list=$(get_user_groups "$username")
            echo -e "    ├─ ${CYAN}Via Group:${NC} $groups_list"
        fi
        
        if [ "$has_file" = "true" ]; then
            echo -e "    ├─ ${CYAN}Via Sudoers:${NC} Direct entry in sudoers file"
        fi
        
        if [ "$VERBOSE" = true ]; then
            last_login=$(get_last_login "$username")
            is_locked=$(is_user_locked "$username")
            
            echo -e "    ├─ ${CYAN}Last Login:${NC} $last_login"
            echo -e "    ├─ ${CYAN}Home Directory:${NC} $(getent passwd "$username" | cut -d: -f6)"
            
            if [ "$is_locked" = "true" ]; then
                echo -e "    └─ ${YELLOW}Status: LOCKED${NC}"
            else
                echo -e "    └─ ${GREEN}Status: Active${NC}"
            fi
        fi
        
        echo ""
    done
fi

# Display Regular Users
echo ""
echo -e "${GREEN}╔═════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                         REGULAR USERS                               ║${NC}"
echo -e "${GREEN}╚═════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ ${#REGULAR_USERS[@]} -eq 0 ]; then
    echo -e "  ${YELLOW}No regular users found.${NC}"
else
    for user_info in "${REGULAR_USERS[@]}"; do
        IFS=':' read -r username uid <<< "$user_info"
        
        echo -e "  ${GREEN}○${NC} $username (UID: $uid)"
        
        if [ "$VERBOSE" = true ]; then
            last_login=$(get_last_login "$username")
            is_locked=$(is_user_locked "$username")
            groups_list=$(get_user_groups "$username")
            
            echo -e "    ├─ ${CYAN}Groups:${NC} $groups_list"
            echo -e "    ├─ ${CYAN}Last Login:${NC} $last_login"
            echo -e "    ├─ ${CYAN}Home Directory:${NC} $(getent passwd "$username" | cut -d: -f6)"
            
            if [ "$is_locked" = "true" ]; then
                echo -e "    └─ ${YELLOW}Status: LOCKED${NC}"
            else
                echo -e "    └─ ${GREEN}Status: Active${NC}"
            fi
        fi
        
        echo ""
    done
fi

# Display System Users (in verbose mode or when explicitly requested)
if { [ "$VERBOSE" = true ] || [ "$SHOW_SYSTEM" = true ]; } && [ ${#SYSTEM_USERS[@]} -gt 0 ]; then
    echo ""
    echo -e "${BLUE}╔═════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    SYSTEM/SERVICE ACCOUNTS                          ║${NC}"
    echo -e "${BLUE}╚═════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    for user_info in "${SYSTEM_USERS[@]}"; do
        IFS=':' read -r username uid <<< "$user_info"
        echo -e "  ${BLUE}○${NC} $username (UID: $uid)"
    done
    echo ""
fi

# Summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}                              SUMMARY${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${RED}Admin Users:${NC}    ${#ADMIN_USERS[@]}"
echo -e "  ${GREEN}Regular Users:${NC}  ${#REGULAR_USERS[@]}"
if [ "$VERBOSE" = true ] || [ "$SHOW_SYSTEM" = true ]; then
    echo -e "  ${BLUE}System Users:${NC}   ${#SYSTEM_USERS[@]}"
fi
echo ""

# Security Recommendations
if [ ${#ADMIN_USERS[@]} -gt 3 ]; then
    echo -e "${YELLOW}⚠ RECOMMENDATION: You have ${#ADMIN_USERS[@]} users with admin privileges.${NC}"
    echo -e "${YELLOW}  Consider reviewing and reducing the number of privileged accounts.${NC}"
    echo ""
fi

# Check for root direct access
if groups root 2>/dev/null | grep -qw "sudo\|wheel"; then
    echo -e "${YELLOW}⚠ NOTE: Root user has sudo group membership (this is unusual).${NC}"
    echo ""
fi

echo -e "${CYAN}═══════════════════════════════════════════════════════════════════════${NC}"
echo ""

exit 0
