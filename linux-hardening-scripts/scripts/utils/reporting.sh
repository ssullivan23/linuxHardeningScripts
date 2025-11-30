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
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    HARDENING AUDIT SUMMARY REPORT                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
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
                echo -e "${RED}✗ $(echo "$line" | sed 's/.*ERROR: //')${NC}"
            elif [[ "$line" =~ WARNING ]]; then
                ((warning_count++))
                echo -e "${YELLOW}⚠ $(echo "$line" | sed 's/.*WARNING: //')${NC}"
            elif [[ "$line" =~ SUCCESS|Completed|completed|applied ]]; then
                ((success_count++))
                echo -e "${GREEN}✓ $(echo "$line" | sed 's/.*SUCCESS: //')${NC}"
            elif [[ "$line" =~ INFO|Starting|Executing ]]; then
                ((info_count++))
                echo -e "${BLUE}ℹ $(echo "$line" | sed 's/.*INFO: //')${NC}"
            else
                echo -e "${WHITE}  $line${NC}"
            fi
        done < "$log_file"

        # Print statistics
        echo ""
        echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────────${NC}"
        echo -e "${BLUE}Summary Statistics:${NC}"
        echo -e "  ${GREEN}Success Messages:${NC}  $success_count"
        echo -e "  ${BLUE}Info Messages:${NC}     $info_count"
        echo -e "  ${YELLOW}Warnings:${NC}           $warning_count"
        echo -e "  ${RED}Errors:${NC}             $error_count"
        echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────────${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠ No actions were logged. Summary report is empty.${NC}"
        echo ""
    fi
}

# Function to generate a detailed formatted report
generate_report() {
    local log_file="${1:-.}"
    
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   DETAILED HARDENING AUDIT REPORT                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${MAGENTA}Report Generated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${MAGENTA}Hostname: $(hostname)${NC}"
    echo ""

    if [ -f "$log_file" ]; then
        echo -e "${BLUE}Log File: ${WHITE}${log_file}${NC}"
        echo -e "${BLUE}File Size: ${WHITE}$(du -h "$log_file" | cut -f1)${NC}"
        echo ""
        
        echo -e "${CYAN}─ DETAILED LOG ENTRIES ─────────────────────────────────────────────────────${NC}"
        echo ""
        
        # Parse and color-code each line
        while IFS= read -r line; do
            if [[ "$line" =~ ERROR ]]; then
                echo -e "${RED}${line}${NC}"
            elif [[ "$line" =~ WARNING ]]; then
                echo -e "${YELLOW}${line}${NC}"
            elif [[ "$line" =~ SUCCESS|Completed|applied ]]; then
                echo -e "${GREEN}${line}${NC}"
            elif [[ "$line" =~ INFO|Executing|Starting ]]; then
                echo -e "${BLUE}${line}${NC}"
            elif [[ "$line" =~ DRY.RUN ]]; then
                echo -e "${CYAN}${line}${NC}"
            else
                echo -e "${WHITE}${line}${NC}"
            fi
        done < "$log_file"
        
        echo ""
        echo -e "${CYAN}─────────────────────────────────────────────────────────────────────────────${NC}"
    else
        echo -e "${YELLOW}⚠ No log file found at: ${WHITE}${log_file}${NC}"
        echo ""
    fi
}