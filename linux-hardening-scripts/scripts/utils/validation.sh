#!/bin/bash

# validation.sh - Utility script for input validation and permission checks

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root." | tee -a /var/log/linux-hardening.log
        exit 1
    fi
}

# Function to validate input parameters
validate_input() {
    if [ -z "$1" ]; then
        echo "Error: No input provided. Please specify a valid parameter." | tee -a /var/log/linux-hardening.log
        exit 1
    fi
}

# Function to check if necessary commands are available
check_commands() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' is not installed." | tee -a /var/log/linux-hardening.log
            exit 1
        fi
    done
}

# Main execution
check_root
validate_input "$1"
check_commands ssh iptables useradd

echo "Validation completed successfully." | tee -a /var/log/linux-hardening.log