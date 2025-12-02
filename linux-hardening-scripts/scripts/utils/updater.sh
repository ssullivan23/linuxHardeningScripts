#!/bin/bash

# Self-update utility for Linux hardening scripts
# Syncs repository with main branch and updates all local changes

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Get repository root (the actual git root, not the linux-hardening-scripts subfolder)
get_repo_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local app_dir
    app_dir=$(cd "$script_dir/../.." && pwd)
    
    # Check if we're inside a git repository already
    local git_root
    git_root=$(cd "$app_dir" && git rev-parse --show-toplevel 2>/dev/null)
    
    if [ -n "$git_root" ]; then
        # Return the actual git root
        echo "$git_root"
    else
        # If not in a git repo, check if app_dir is named linux-hardening-scripts
        # and has a parent that could be the repo root
        local parent_dir
        parent_dir=$(dirname "$app_dir")
        local dir_name
        dir_name=$(basename "$app_dir")
        
        if [ "$dir_name" = "linux-hardening-scripts" ] && [ -d "$parent_dir/.git" ]; then
            # Parent is the git root
            echo "$parent_dir"
        else
            # Assume app_dir is the repo root (standalone installation)
            echo "$app_dir"
        fi
    fi
}

# Get the application directory (linux-hardening-scripts folder)
get_app_dir() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$script_dir/../.." && pwd
}

# Initialize git if needed
init_git() {
    local repo_root="$1"
    
    if [ ! -d "$repo_root/.git" ]; then
        echo -e "${YELLOW}Git repository not found. Initializing...${NC}"
        cd "$repo_root"
        git init || {
            echo -e "${RED}Error: Failed to initialize git repository${NC}" >&2
            return 1
        }
        git remote add origin "https://github.com/ssullivan23/linuxHardeningScripts.git" || {
            echo -e "${YELLOW}Remote 'origin' may already exist${NC}"
        }
        
        # Configure sparse checkout if the repo structure includes linux-hardening-scripts subfolder
        # This prevents creating nested directories during update
        git config core.sparseCheckout false
    fi
}

# Check if git is installed
check_git_installed() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: Git is not installed${NC}" >&2
        echo "Install it with: sudo apt install git (Debian/Ubuntu)"
        return 1
    fi
}

# Display update status
show_update_status() {
    local repo_root="$1"
    local dry_run="${2:-false}"
    
    cd "$repo_root"
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Update Status - Linux Hardening Scripts${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Current branch
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo -e "${BLUE}Current Branch:${NC} $current_branch"
    
    # Current commit
    local current_commit
    current_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo -e "${BLUE}Current Commit:${NC} $current_commit"
    
    # Local changes
    local local_changes
    local_changes=$(git status --short | wc -l)
    if [ "$local_changes" -gt 0 ]; then
        echo -e "${YELLOW}Local Changes:${NC} $local_changes files modified"
    else
        echo -e "${GREEN}Local Changes:${NC} None"
    fi
    
    # Check if remote is reachable
    echo ""
    echo -e "${BLUE}Checking for updates...${NC}"
    
    if ! git fetch origin &>/dev/null; then
        echo -e "${YELLOW}Warning: Cannot reach remote repository${NC}"
        return 1
    fi
    
    # Compare with remote
    local local_hash
    local remote_hash
    local_hash=$(git rev-parse "@" 2>/dev/null)
    remote_hash=$(git rev-parse "origin/main" 2>/dev/null)
    
    if [ "$local_hash" = "$remote_hash" ]; then
        echo -e "${GREEN}✓ Already up to date with remote${NC}"
    else
        echo -e "${YELLOW}⚠ Updates available from remote${NC}"
    fi
    
    echo ""
}

# Perform backup before update
backup_repo() {
    local repo_root="$1"
    local backup_dir="$repo_root/.backups"
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="backup_${timestamp}"
    
    mkdir -p "$backup_dir"
    
    echo -e "${BLUE}Creating backup...${NC}"
    
    # Backup entire repository (excluding git metadata and logs)
    # This ensures filepath changes are properly captured
    tar -czf "$backup_dir/$backup_name.tar.gz" \
        -C "$repo_root" \
        --exclude='.git' \
        --exclude='.backups' \
        --exclude='logs' \
        . 2>/dev/null || {
        echo -e "${RED}Error: Failed to create backup${NC}" >&2
        return 1
    }
    
    echo -e "${GREEN}✓ Backup created: $backup_dir/$backup_name.tar.gz${NC}"
    
    # Keep only last 5 backups
    ls -t "$backup_dir"/backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm
    
    return 0
}

# Restore from backup
restore_backup() {
    local backup_dir="$1"
    local repo_root="$2"
    
    # Find latest backup
    local latest_backup
    latest_backup=$(ls -t "$backup_dir"/backup_*.tar.gz 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        echo -e "${RED}Error: No backup found to restore${NC}" >&2
        return 1
    fi
    
    echo -e "${YELLOW}Restoring from backup: $(basename "$latest_backup")${NC}"
    
    tar -xzf "$latest_backup" -C "$repo_root" || {
        echo -e "${RED}Error: Failed to restore backup${NC}" >&2
        return 1
    }
    
    echo -e "${GREEN}✓ Backup restored successfully${NC}"
    return 0
}

# Detect filepath changes (renames, deletes, new files)
detect_filepath_changes() {
    local repo_root="$1"
    
    cd "$repo_root"
    
    # Get list of files that will be added/deleted/renamed
    local added_files
    local deleted_files
    local renamed_files
    
    added_files=$(git diff origin/main --name-status 2>/dev/null | grep "^A" | cut -f2-)
    deleted_files=$(git diff origin/main --name-status 2>/dev/null | grep "^D" | cut -f2-)
    renamed_files=$(git diff origin/main --name-status 2>/dev/null | grep "^R" | cut -f2-)
    
    if [ -n "$added_files" ] || [ -n "$deleted_files" ] || [ -n "$renamed_files" ]; then
        return 0  # Changes detected
    else
        return 1  # No changes
    fi
}

# Clean up nested linux-hardening-scripts directories
# This prevents the issue where syncing creates linux-hardening-scripts/linux-hardening-scripts
cleanup_nested_directories() {
    local app_dir="$1"
    local dir_name
    dir_name=$(basename "$app_dir")
    
    # Check if we're in a linux-hardening-scripts directory with a nested one
    if [ "$dir_name" = "linux-hardening-scripts" ] && [ -d "$app_dir/linux-hardening-scripts" ]; then
        echo -e "${YELLOW}⚠ Found nested linux-hardening-scripts directory${NC}"
        
        local nested_dir="$app_dir/linux-hardening-scripts"
        
        # Check if nested directory has actual content
        if [ -d "$nested_dir/scripts" ] || [ -d "$nested_dir/config" ] || [ -d "$nested_dir/docs" ]; then
            echo -e "${BLUE}Merging nested directory contents...${NC}"
            
            # Copy contents from nested to parent (don't overwrite existing)
            for item in "$nested_dir"/*; do
                if [ -e "$item" ]; then
                    local item_name
                    item_name=$(basename "$item")
                    if [ ! -e "$app_dir/$item_name" ]; then
                        cp -r "$item" "$app_dir/"
                    fi
                fi
            done
            
            # Remove the nested directory
            rm -rf "$nested_dir"
            echo -e "${GREEN}✓ Nested directory cleaned up${NC}"
            return 0
        fi
    fi
    
    return 1  # No cleanup needed
}

# Display filepath changes that will occur during update
show_filepath_changes() {
    local repo_root="$1"
    
    cd "$repo_root"
    
    local added_files
    local deleted_files
    local renamed_files
    
    added_files=$(git diff origin/main --name-status 2>/dev/null | grep "^A" | cut -f2-)
    deleted_files=$(git diff origin/main --name-status 2>/dev/null | grep "^D" | cut -f2-)
    renamed_files=$(git diff origin/main --name-status 2>/dev/null | grep "^R" | cut -f2-)
    
    if [ -n "$added_files" ]; then
        echo -e "${GREEN}New files to be added:${NC}"
        echo "$added_files" | sed 's/^/  + /'
        echo ""
    fi
    
    if [ -n "$deleted_files" ]; then
        echo -e "${YELLOW}Files to be removed:${NC}"
        echo "$deleted_files" | sed 's/^/  - /'
        echo ""
    fi
    
    if [ -n "$renamed_files" ]; then
        echo -e "${BLUE}Files to be renamed/moved:${NC}"
        echo "$renamed_files" | sed 's/^/  → /'
        echo ""
    fi
}

# Update from remote (with stash of local changes)
update_from_remote() {
    local repo_root="$1"
    local dry_run="${2:-false}"
    local app_dir
    app_dir=$(get_app_dir)
    
    cd "$repo_root"
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Updating from Remote Repository${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Detect if the remote has a linux-hardening-scripts subfolder structure
    # to prevent nested directories
    local remote_has_subfolder=false
    if git ls-remote --exit-code origin &>/dev/null; then
        # Check if remote main branch has linux-hardening-scripts as a top-level dir
        if git ls-tree -d origin/main linux-hardening-scripts &>/dev/null 2>&1; then
            remote_has_subfolder=true
            echo -e "${BLUE}Info: Remote repository contains linux-hardening-scripts subfolder${NC}"
        fi
    fi
    
    # Check if HEAD exists (repository has commits)
    local has_commits=false
    if git rev-parse HEAD &>/dev/null; then
        has_commits=true
    fi
    
    # Check for local changes only if repository has commits
    local has_changes=false
    local has_untracked=false
    if [ "$has_commits" = true ]; then
        # Check for staged/unstaged changes
        if ! git diff-index --quiet HEAD -- 2>/dev/null; then
            echo -e "${YELLOW}⚠ Detected local modifications${NC}"
            has_changes=true
        fi
        # Check for untracked files
        if [ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]; then
            echo -e "${YELLOW}⚠ Detected untracked files${NC}"
            has_untracked=true
            has_changes=true
        fi
    fi
    
    # Check for filepath changes (new files, deletions, renames)
    local has_filepath_changes=false
    if git fetch origin &>/dev/null; then
        if detect_filepath_changes "$repo_root"; then
            echo -e "${YELLOW}⚠ Detected filepath changes in update${NC}"
            has_filepath_changes=true
        fi
    fi
    
    # Create backup before update
    backup_repo "$repo_root" || {
        echo -e "${RED}Aborting update due to backup failure${NC}" >&2
        return 1
    }
    
    echo ""
    
    if [ "$dry_run" = true ]; then
        echo -e "${YELLOW}[DRY RUN MODE] The following would be performed:${NC}"
        echo ""
        
        if [ "$has_changes" = true ]; then
            echo -e "${YELLOW}1. Stash local changes${NC}"
        fi
        
        echo -e "${YELLOW}2. Fetch latest changes from origin/main${NC}"
        
        if [ "$has_commits" = true ]; then
            echo -e "${YELLOW}3. Merge or fast-forward to latest version${NC}"
        else
            echo -e "${YELLOW}3. Initialize repository with latest version${NC}"
        fi
        
        if [ "$has_filepath_changes" = true ]; then
            echo -e "${YELLOW}4. Apply filepath changes (new files, deletions, renames)${NC}"
        fi
        
        if [ "$has_changes" = true ]; then
            local step=5
            [ "$has_filepath_changes" = true ] && step=5 || step=4
            echo -e "${YELLOW}$step. Apply stashed changes${NC}"
        fi
        
        echo ""
        echo -e "${BLUE}Filepath Changes Preview:${NC}"
        show_filepath_changes "$repo_root"
        echo ""
        return 0
    fi
    
    # Stash local changes if any
    if [ "$has_changes" = true ]; then
        echo -e "${BLUE}Stashing local changes...${NC}"
        
        # Ensure git has a user configured (required for stash)
        if ! git config user.email &>/dev/null || [ -z "$(git config user.email)" ]; then
            echo -e "${YELLOW}Configuring temporary git user for stash operation...${NC}"
            git config user.email "updater@localhost"
            git config user.name "Updater Script"
        fi
        
        # Try to stash changes - use --include-untracked if we have untracked files
        local stash_result=0
        local stash_cmd="git stash push -m \"Pre-update stash $(date +%Y%m%d_%H%M%S)\""
        
        if [ "$has_untracked" = true ]; then
            # Include untracked files in stash
            git stash push --include-untracked -m "Pre-update stash $(date +%Y%m%d_%H%M%S)" 2>/dev/null || stash_result=$?
        else
            git stash push -m "Pre-update stash $(date +%Y%m%d_%H%M%S)" 2>/dev/null || stash_result=$?
        fi
        
        if [ "$stash_result" -ne 0 ]; then
            echo -e "${YELLOW}Standard stash failed, trying alternative methods...${NC}"
            
            # Try stashing with all files included
            if git stash push --all -m "Pre-update stash $(date +%Y%m%d_%H%M%S)" 2>/dev/null; then
                echo -e "${GREEN}✓ Local changes stashed (all files)${NC}"
            else
                # If stash still fails, try resetting and using backup instead
                echo -e "${YELLOW}⚠ Could not stash changes - will preserve via backup${NC}"
                echo -e "${YELLOW}Your changes are saved in the backup archive${NC}"
                
                # Reset to clean state for update (backup already created)
                git checkout -- . 2>/dev/null || true
                git clean -fd 2>/dev/null || true
                has_changes=false  # Mark as no changes since we reset
            fi
        else
            echo -e "${GREEN}✓ Local changes stashed${NC}"
        fi
        echo ""
    fi
    
    # Fetch from remote
    echo -e "${BLUE}Fetching updates from remote...${NC}"
    if ! git fetch origin; then
        echo -e "${RED}Error: Failed to fetch from remote${NC}" >&2
        echo -e "${YELLOW}Attempting to restore from backup...${NC}"
        restore_backup "$repo_root/.backups" "$repo_root"
        return 1
    fi
    echo -e "${GREEN}✓ Updates fetched${NC}"
    echo ""
    
    # If this is the first time, just checkout the remote main branch
    if [ "$has_commits" = false ]; then
        echo -e "${BLUE}Initializing repository with main branch...${NC}"
        
        # Handle repositories where remote has linux-hardening-scripts as subfolder
        if [ "$remote_has_subfolder" = true ]; then
            echo -e "${BLUE}Configuring to sync only the application directory...${NC}"
            
            # Use subtree or sparse-checkout to avoid nested directories
            git config core.sparseCheckout true
            mkdir -p .git/info
            echo "linux-hardening-scripts/*" > .git/info/sparse-checkout
            
            if git checkout -b main origin/main 2>/dev/null || git checkout main 2>/dev/null; then
                # Move files from linux-hardening-scripts subfolder to root if needed
                if [ -d "$repo_root/linux-hardening-scripts" ] && [ "$repo_root" != "$app_dir" ]; then
                    echo -e "${BLUE}Reorganizing directory structure...${NC}"
                    # Files are already in the right place due to sparse checkout
                fi
                echo -e "${GREEN}✓ Successfully initialized main branch${NC}"
            else
                echo -e "${RED}Error: Failed to checkout main branch${NC}" >&2
                echo -e "${YELLOW}Restoring from backup...${NC}"
                restore_backup "$repo_root/.backups" "$repo_root"
                return 1
            fi
        else
            if git checkout -b main origin/main 2>/dev/null || git checkout main 2>/dev/null; then
                echo -e "${GREEN}✓ Successfully initialized main branch${NC}"
            else
                echo -e "${RED}Error: Failed to checkout main branch${NC}" >&2
                echo -e "${YELLOW}Restoring from backup...${NC}"
                restore_backup "$repo_root/.backups" "$repo_root"
                return 1
            fi
        fi
    else
        # Merge or fast-forward if repository already has commits
        echo -e "${BLUE}Updating to latest version...${NC}"
        
        # Check for and remove any nested linux-hardening-scripts directories that shouldn't exist
        if [ -d "$app_dir/linux-hardening-scripts" ] && [ "$(basename "$app_dir")" = "linux-hardening-scripts" ]; then
            echo -e "${YELLOW}⚠ Detected nested linux-hardening-scripts directory${NC}"
            echo -e "${BLUE}This will be cleaned up during update...${NC}"
        fi
        
        if git merge --ff-only origin/main; then
            echo -e "${GREEN}✓ Successfully updated to latest version${NC}"
        else
            echo -e "${YELLOW}⚠ Could not fast-forward (might have conflicting changes)${NC}"
            echo -e "${YELLOW}Attempting manual merge...${NC}"
            
            if git merge origin/main; then
                echo -e "${GREEN}✓ Merge completed (may require manual conflict resolution)${NC}"
            else
                echo -e "${RED}Error: Merge failed with conflicts${NC}" >&2
                echo -e "${YELLOW}Restoring from backup...${NC}"
                restore_backup "$repo_root/.backups" "$repo_root"
                git merge --abort 2>/dev/null || true
                return 1
            fi
        fi
        
        # Clean up nested directories if they were created
        if [ -d "$app_dir/linux-hardening-scripts" ] && [ "$(basename "$app_dir")" = "linux-hardening-scripts" ]; then
            echo -e "${BLUE}Cleaning up nested directory structure...${NC}"
            # Move contents up and remove nested folder
            if [ -d "$app_dir/linux-hardening-scripts/scripts" ]; then
                cp -rn "$app_dir/linux-hardening-scripts/"* "$app_dir/" 2>/dev/null || true
                rm -rf "$app_dir/linux-hardening-scripts"
                echo -e "${GREEN}✓ Directory structure corrected${NC}"
            fi
        fi
    fi
    echo ""
    
    # Restore stashed changes if any
    if [ "$has_changes" = true ]; then
        # Check if there's actually something in the stash before trying to pop
        if git stash list | grep -q "Pre-update stash"; then
            echo -e "${BLUE}Reapplying local changes...${NC}"
            if git stash pop; then
                echo -e "${GREEN}✓ Local changes reapplied${NC}"
            else
                echo -e "${YELLOW}⚠ Could not automatically reapply local changes${NC}"
                echo -e "${YELLOW}Your stashed changes are in: git stash list${NC}"
                echo -e "${YELLOW}To manually apply: git stash pop${NC}"
            fi
        else
            echo -e "${YELLOW}Note: Local changes were preserved in backup (stash was not used)${NC}"
            echo -e "${YELLOW}Backup location: $repo_root/.backups/${NC}"
        fi
        echo ""
    fi
    
    # Verify update
    local new_commit
    new_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    
    # Final cleanup: ensure no nested directories exist
    cleanup_nested_directories "$app_dir"
    
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Update completed successfully!${NC}"
    echo -e "${GREEN}New version: $new_commit${NC}"
    echo -e "${GREEN}App location: $app_dir${NC}"
    
    if [ "$has_filepath_changes" = true ]; then
        echo ""
        echo -e "${BLUE}Filepath changes applied:${NC}"
        show_filepath_changes "$repo_root"
    fi
    
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
}

# Show list of available backups
list_backups() {
    local backup_dir="$1"
    
    if [ ! -d "$backup_dir" ]; then
        echo -e "${YELLOW}No backups found${NC}"
        return 0
    fi
    
    local backups
    backups=$(ls -lh "$backup_dir"/backup_*.tar.gz 2>/dev/null)
    
    if [ -z "$backups" ]; then
        echo -e "${YELLOW}No backups found${NC}"
        return 0
    fi
    
    echo -e "${BLUE}Available backups:${NC}"
    echo "$backups" | awk '{print $9, "(" $5 ")"}'
}

# Show usage
show_usage() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║              Self-Update Utility - Linux Hardening Scripts                 ║
╚════════════════════════════════════════════════════════════════════════════╝

DESCRIPTION:
  Updates the Linux hardening scripts repository with the latest changes from
  the main GitHub repository. Includes backup/restore functionality and support
  for dry-run mode to preview changes.

USAGE:
  sudo ./linux-hardening-scripts/scripts/utils/updater.sh [COMMAND] [OPTIONS]

COMMANDS:
  status [--dry-run]            Check update status and available updates
  update [--dry-run]            Update to latest version from main repository
  backup                        Create a manual backup before update
  restore                       Restore from latest backup
  list-backups                  List all available backups
  fix-nested                    Fix nested directory issues (linux-hardening-scripts/linux-hardening-scripts)
  -h, --help                    Display this help message

OPTIONS:
  --dry-run                     Preview changes without applying them

QUICK START EXAMPLES:

  1. Check update status:
     sudo ./linux-hardening-scripts/scripts/utils/updater.sh status

  2. Preview what will be updated:
     sudo ./linux-hardening-scripts/scripts/utils/updater.sh update --dry-run

  3. Apply latest updates:
     sudo ./linux-hardening-scripts/scripts/utils/updater.sh update

  4. Create manual backup before update:
     sudo ./linux-hardening-scripts/scripts/utils/updater.sh backup

  5. View available backups:
     sudo ./linux-hardening-scripts/scripts/utils/updater.sh list-backups

  6. Restore from latest backup:
     sudo ./linux-hardening-scripts/scripts/utils/updater.sh restore

  7. Fix nested directory structure:
     sudo ./linux-hardening-scripts/scripts/utils/updater.sh fix-nested

FEATURES:
  • Automatic backup creation before updates (full repository)
  • Backup rotation (keeps last 5 backups)
  • Local change preservation (stashed and reapplied)
  • Filepath change detection (new files, deletions, renames)
  • Dry-run mode to preview changes including filepath updates
  • Automatic restoration on failure
  • Remote repository synchronization
  • Conflict detection and handling
  • Complete repository structure management
  • Automatic nested directory cleanup (prevents linux-hardening-scripts/linux-hardening-scripts)

WORKFLOW:
  1. Check status: sudo ./scripts/utils/updater.sh status
  2. Preview: sudo ./scripts/utils/updater.sh update --dry-run
  3. Update: sudo ./scripts/utils/updater.sh update
  4. Verify: sudo ./scripts/utils/updater.sh status

REPOSITORY INFO:
  Main Repository: https://github.com/ssullivan23/linuxHardeningScripts
  Default Branch: main

IMPORTANT NOTES:
  • Requires Git to be installed
  • Must be run as root (use sudo)
  • Local changes are preserved during updates
  • Automatic backups are created before each update
  • Failed updates can be rolled back with restore command
  • Backups are stored in .backups directory (auto-rotated)
  • Nested directories are automatically cleaned up during updates

EOF
}

# Main function
main() {
    local command="${1:-help}"
    local option="${2:-}"
    
    # Check if running as root for anything except help
    if [ "$command" != "help" ] && [ "$command" != "-h" ] && [ "$command" != "--help" ]; then
        if [ "$(id -u)" -ne 0 ]; then
            echo -e "${RED}Error: This command must be run as root (use sudo)${NC}" >&2
            return 1
        fi
    fi
    
    # Check if git is installed
    check_git_installed || return 1
    
    local repo_root
    repo_root=$(get_repo_root)
    
    # Initialize git repository if needed
    init_git "$repo_root" || return 1
    
    case "$command" in
        status)
            show_update_status "$repo_root" "$([[ "$option" == "--dry-run" ]] && echo true || echo false)"
            ;;
        update)
            update_from_remote "$repo_root" "$([[ "$option" == "--dry-run" ]] && echo true || echo false)"
            ;;
        backup)
            backup_repo "$repo_root"
            ;;
        restore)
            restore_backup "$repo_root/.backups" "$repo_root"
            ;;
        list-backups)
            list_backups "$repo_root/.backups"
            ;;
        fix-nested)
            local app_dir
            app_dir=$(get_app_dir)
            echo -e "${BLUE}Checking for nested directory issues...${NC}"
            if cleanup_nested_directories "$app_dir"; then
                echo -e "${GREEN}✓ Nested directories fixed${NC}"
            else
                echo -e "${GREEN}✓ No nested directory issues found${NC}"
            fi
            ;;
        help|-h|--help)
            show_usage
            ;;
        *)
            echo -e "${RED}Unknown command: $command${NC}" >&2
            echo ""
            show_usage
            return 1
            ;;
    esac
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
