#!/bin/bash

# test-hardening.sh - Test script for verifying the functionality of hardening scripts

# Load utility functions
source ../utils/logger.sh
source ../utils/validation.sh

# Function to run a test
run_test() {
    local script=$1
    local dry_run=$2

    if [ "$dry_run" == "true" ]; then
        log_info "Dry run mode: Testing $script without making changes."
        bash "$script" --dry-run
    else
        log_info "Running test on $script."
        bash "$script"
    fi
}

# Main execution
log_info "Starting hardening tests..."

# List of scripts to test
scripts=(
    "../hardening/ssh-hardening.sh"
    "../hardening/firewall-setup.sh"
    "../hardening/user-security.sh"
    "../hardening/filesystem-hardening.sh"
    "../hardening/kernel-hardening.sh"
    "../hardening/service-hardening.sh"
)

# Run tests in dry run mode
for script in "${scripts[@]}"; do
    run_test "$script" true
done

# Run tests in actual mode
for script in "${scripts[@]}"; do
    run_test "$script" false
done

log_info "Hardening tests completed."