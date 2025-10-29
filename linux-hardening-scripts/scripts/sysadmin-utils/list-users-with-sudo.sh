#!/bin/bash

################################################################################
# Script: list-users-with-sudo.sh
# Purpose: List all users and identify those with sudo/admin permissions
# Usage: sudo bash list-users-with-sudo.sh [--verbose]
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

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --verbose|-v) VERBOSE=true ;;
        --help|-h) 
            echo "Usage: $0 [--verbose|-v] [--help|-h]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v    Show detailed information about each user"
            echo "  --help, -h       Display this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
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
        if [ "$VERBOSE" = true ] && [ "$uid" -ge "$MIN_UID" ]; then
            SYSTEM_USERS+=("$username")
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
        if [ "$VERBOSE" = true ]; then
            SYSTEM_USERS+=("$username:$uid")
        fi
    fi
done < /etc/passwd

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

# Display System Users (only in verbose mode)
if [ "$VERBOSE" = true ] && [ ${#SYSTEM_USERS[@]} -gt 0 ]; then
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
if [ "$VERBOSE" = true ]; then
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
