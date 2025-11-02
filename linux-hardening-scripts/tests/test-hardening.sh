#!/bin/bash

# test-hardening.sh - Test script for verifying the functionality of hardening scripts

set -euo pipefail

# Determine script dir and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load utility functions from scripts/utils
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh"

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

# Discover hardening scripts from scripts/hardening
HARDENING_DIR="$REPO_ROOT/scripts/hardening"
scripts=()
for s in "$HARDENING_DIR"/*.sh; do
    [ -e "$s" ] || continue
    scripts+=("$s")
done

# Run tests in dry run mode
for script in "${scripts[@]}"; do
    run_test "$script" true
done

# Run tests in actual mode
for script in "${scripts[@]}"; do
    run_test "$script" false
done

log_info "Hardening tests completed."