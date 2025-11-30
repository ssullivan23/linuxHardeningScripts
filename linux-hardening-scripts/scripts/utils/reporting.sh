#!/bin/bash

# reporting.sh - Enhanced reporting with color-coded, formatted output

# Color codes for formatted output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'  # No Color

# Function to format and display colored summary report
generate_summary() {
    local log_file="${1:-.}"
    
    echo ""
    printf "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                    HARDENING AUDIT SUMMARY REPORT                         ║${NC}\n"
    printf "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo ""

    if [ -f "$log_file" ]; then
        # Extract and format different log entry types
        local total_lines=0
        local info_count=0
        local warning_count=0
        local error_count=0
        local success_count=0

        while IFS= read -r line; do
            ((total_lines++))
            
            if [[ "$line" =~ ERROR ]]; then
                ((error_count++))
                printf "${RED}✗ $(echo "$line" | sed 's/.*ERROR: //')${NC}\n"
            elif [[ "$line" =~ WARNING ]]; then
                ((warning_count++))
                printf "${YELLOW}⚠ $(echo "$line" | sed 's/.*WARNING: //')${NC}\n"
            elif [[ "$line" =~ SUCCESS|Completed|completed|applied ]]; then
                ((success_count++))
                printf "${GREEN}✓ $(echo "$line" | sed 's/.*SUCCESS: //')${NC}\n"
            elif [[ "$line" =~ INFO|Starting|Executing ]]; then
                ((info_count++))
                printf "${BLUE}ℹ $(echo "$line" | sed 's/.*INFO: //')${NC}\n"
            else
                printf "${WHITE}  $line${NC}\n"
            fi
        done < "$log_file"

        # Print statistics
        echo ""
        printf "${CYAN}─────────────────────────────────────────────────────────────────────────────${NC}\n"
        printf "${BLUE}Summary Statistics:${NC}\n"
        printf "  ${GREEN}Success Messages:${NC}  $success_count\n"
        printf "  ${BLUE}Info Messages:${NC}     $info_count\n"
        printf "  ${YELLOW}Warnings:${NC}           $warning_count\n"
        printf "  ${RED}Errors:${NC}             $error_count\n"
        printf "${CYAN}─────────────────────────────────────────────────────────────────────────────${NC}\n"
        echo ""
    else
        printf "${YELLOW}⚠ No actions were logged. Summary report is empty.${NC}\n"
        echo ""
    fi
}

# Function to generate a detailed formatted report
generate_report() {
    local log_file="${1:-.}"
    
    echo ""
    printf "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                   DETAILED HARDENING AUDIT REPORT                        ║${NC}\n"
    printf "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}\n"
    echo ""
    printf "${MAGENTA}Report Generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}\n"
    printf "${MAGENTA}Hostname: $(hostname)${NC}\n"
    echo ""

    if [ -f "$log_file" ]; then
        printf "${BLUE}Log File: ${WHITE}${log_file}${NC}\n"
        printf "${BLUE}File Size: ${WHITE}$(du -h "$log_file" | cut -f1)${NC}\n"
        echo ""
        
        printf "${CYAN}─ DETAILED LOG ENTRIES ─────────────────────────────────────────────────────${NC}\n"
        echo ""
        
        # Parse and color-code each line
        while IFS= read -r line; do
            if [[ "$line" =~ ERROR ]]; then
                printf "${RED}${line}${NC}\n"
            elif [[ "$line" =~ WARNING ]]; then
                printf "${YELLOW}${line}${NC}\n"
            elif [[ "$line" =~ SUCCESS|Completed|applied ]]; then
                printf "${GREEN}${line}${NC}\n"
            elif [[ "$line" =~ INFO|Executing|Starting ]]; then
                printf "${BLUE}${line}${NC}\n"
            elif [[ "$line" =~ DRY.RUN ]]; then
                printf "${CYAN}${line}${NC}\n"
            else
                printf "${WHITE}${line}${NC}\n"
            fi
        done < "$log_file"
        
        echo ""
        printf "${CYAN}─────────────────────────────────────────────────────────────────────────────${NC}\n"
    else
        printf "${YELLOW}⚠ No log file found at: ${WHITE}${log_file}${NC}\n"
        echo ""
    fi
}