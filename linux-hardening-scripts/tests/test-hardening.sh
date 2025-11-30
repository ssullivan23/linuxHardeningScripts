#!/bin/bash

# test-hardening.sh - Test script for verifying the functionality of hardening scripts
# Tests all available hardening modules in dry-run mode first, then actual mode

set -euo pipefail

# Determine script dir and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Function to ensure all scripts have execute permissions
ensure_execute_permissions() {
    # Silently fix permissions on all scripts
    chmod +x "$REPO_ROOT/scripts/main.sh" 2>/dev/null || true
    chmod +x "$REPO_ROOT/scripts/utils"/*.sh 2>/dev/null || true
    chmod +x "$REPO_ROOT/scripts/hardening"/*.sh 2>/dev/null || true
    chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
}

# Ensure permissions are set before loading utilities
ensure_execute_permissions

# Load utility functions from scripts/utils
source "$REPO_ROOT/scripts/utils/logger.sh"
source "$REPO_ROOT/scripts/utils/validation.sh"

# Parse arguments
DRY_RUN_ONLY=false
EXCLUDED_MODULES=""

# Function to display help
show_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║              CIS Linux Hardening Tool - Test Suite                         ║
╚════════════════════════════════════════════════════════════════════════════╝

DESCRIPTION:
  Comprehensive testing suite for hardening modules. Runs all modules in
  dry-run mode first for safety, then optionally executes actual tests.

USAGE:
  sudo ./linux-hardening-scripts/tests/test-hardening.sh [OPTIONS]

OPTIONS:
  -h, --help                    Display this help message and exit
  --dry-run-only                Run only dry-run tests (no actual changes)
  --exclude-modules <list>      Comma-separated list of modules to skip

AVAILABLE TEST MODES:

  1. Full test (dry-run + actual):
     sudo ./linux-hardening-scripts/tests/test-hardening.sh

  2. Safe testing (dry-run only):
     sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only

  3. Test with excluded modules:
     sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only --exclude-modules ssh-hardening

TEST WORKFLOW:
  Phase 1: Dry-run all modules (safe preview)
  Phase 2: Actual test execution (if --dry-run-only not set)
  Phase 3: Generate detailed reports

EXAMPLES:
  • Test all modules in dry-run mode only (safest):
    sudo ./linux-hardening-scripts/tests/test-hardening.sh --dry-run-only

  • Test everything:
    sudo ./linux-hardening-scripts/tests/test-hardening.sh

  • Skip firewall and network tests:
    sudo ./linux-hardening-scripts/tests/test-hardening.sh --exclude-modules firewall-setup,network-hardening

FOR MORE INFORMATION:
  See README.md for full documentation
  See QUICK_REFERENCE.md for common usage patterns

EOF
}

show_help_short() {
    echo "Usage: $0 [OPTIONS]"
    echo "Try '$0 --help' for more information."
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --dry-run-only) DRY_RUN_ONLY=true ;;
        --exclude-modules)
            if [ -z "$2" ]; then
                echo "Error: --exclude-modules requires an argument"
                show_help_short
                exit 1
            fi
            EXCLUDED_MODULES="$2"
            shift
            ;;
        *)
            echo "Error: Unknown option: $1"
            show_help_short
            exit 1
            ;;
    esac
    shift
done

# Function to run a test
run_test() {
    local script=$1
    local dry_run=$2

    if [ "$dry_run" == "true" ]; then
        log_info "DRY RUN TEST: $(basename "$script")"
        bash "$script" --dry-run
    else
        log_info "LIVE TEST: $(basename "$script")"
        bash "$script"
    fi
}

# Function to check if a module should be tested
should_test_module() {
    local module=$1
    
    # Skip removed/obsolete modules
    module_name=$(basename "$module" .sh)
    if [ "$module_name" = "kernel-hardening" ]; then
        return 1
    fi
    
    if [ -n "$EXCLUDED_MODULES" ]; then
        IFS=',' read -ra EXCLUDED <<< "$EXCLUDED_MODULES"
        for excluded in "${EXCLUDED[@]}"; do
            excluded=$(basename "$excluded" .sh | xargs)
            module_name=$(basename "$module" .sh)
            if [ "$excluded" = "$module_name" ]; then
                return 1
            fi
        done
    fi
    return 0
}

# Main execution
log_info "Starting hardening module tests..."

# Discover hardening scripts from scripts/hardening
HARDENING_DIR="$REPO_ROOT/scripts/hardening"
scripts=()
for s in "$HARDENING_DIR"/*.sh; do
    [ -e "$s" ] || continue
    if should_test_module "$s"; then
        scripts+=("$s")
    fi
done

if [ ${#scripts[@]} -eq 0 ]; then
    log_warn "No scripts to test (all modules excluded)"
    exit 0
fi

log_info "Found ${#scripts[@]} modules to test"
log_info ""

# Run tests in dry run mode first
log_info "=== PHASE 1: DRY RUN TESTS ==="
for script in "${scripts[@]}"; do
    run_test "$script" true
    log_info ""
done

# Only run actual tests if not in dry-run-only mode
if [ "$DRY_RUN_ONLY" = false ]; then
    log_info "=== PHASE 2: LIVE TESTS ==="
    for script in "${scripts[@]}"; do
        run_test "$script" false
        log_info ""
    done
else
    log_info "Skipping live tests (--dry-run-only flag set)"
fi

log_info "Hardening module tests completed"