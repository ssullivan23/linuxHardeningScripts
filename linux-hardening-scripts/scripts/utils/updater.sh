#!/bin/bash

# Self-update utility for Linux hardening scripts
# Syncs repository with main branch and updates all local changes

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Get repository root
get_repo_root() {
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
    
    # Backup only important directories
    tar -czf "$backup_dir/$backup_name.tar.gz" \
        -C "$repo_root" \
        --exclude='.git' \
        --exclude='.backups' \
        --exclude='logs' \
        scripts/ config/ docs/ 2>/dev/null || {
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

# Update from remote (with stash of local changes)
update_from_remote() {
    local repo_root="$1"
    local dry_run="${2:-false}"
    
    cd "$repo_root"
    
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Updating from Remote Repository${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check if HEAD exists (repository has commits)
    local has_commits=false
    if git rev-parse HEAD &>/dev/null; then
        has_commits=true
    fi
    
    # Check for local changes only if repository has commits
    local has_changes=false
    if [ "$has_commits" = true ]; then
        if ! git diff-index --quiet HEAD --; then
            echo -e "${YELLOW}⚠ Detected local changes${NC}"
            has_changes=true
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
        
        if [ "$has_changes" = true ]; then
            echo -e "${YELLOW}4. Apply stashed changes${NC}"
        fi
        
        echo ""
        return 0
    fi
    
    # Stash local changes if any
    if [ "$has_changes" = true ]; then
        echo -e "${BLUE}Stashing local changes...${NC}"
        git stash push -m "Pre-update stash $(date +%Y%m%d_%H%M%S)" || {
            echo -e "${RED}Error: Failed to stash changes${NC}" >&2
            restore_backup "$repo_root/.backups" "$repo_root"
            return 1
        }
        echo -e "${GREEN}✓ Local changes stashed${NC}"
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
        if git checkout -b main origin/main 2>/dev/null || git checkout main 2>/dev/null; then
            echo -e "${GREEN}✓ Successfully initialized main branch${NC}"
        else
            echo -e "${RED}Error: Failed to checkout main branch${NC}" >&2
            echo -e "${YELLOW}Restoring from backup...${NC}"
            restore_backup "$repo_root/.backups" "$repo_root"
            return 1
        fi
    else
        # Merge or fast-forward if repository already has commits
        echo -e "${BLUE}Updating to latest version...${NC}"
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
    fi
    echo ""
    
    # Restore stashed changes if any
    if [ "$has_changes" = true ]; then
        echo -e "${BLUE}Reapplying local changes...${NC}"
        if git stash pop; then
            echo -e "${GREEN}✓ Local changes reapplied${NC}"
        else
            echo -e "${YELLOW}⚠ Could not automatically reapply local changes${NC}"
            echo -e "${YELLOW}Your stashed changes are in: git stash${NC}"
        fi
        echo ""
    fi
    
    # Verify update
    local new_commit
    new_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ Update completed successfully!${NC}"
    echo -e "${GREEN}New version: $new_commit${NC}"
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

FEATURES:
  • Automatic backup creation before updates
  • Backup rotation (keeps last 5 backups)
  • Local change preservation (stashed and reapplied)
  • Dry-run mode to preview changes
  • Automatic restoration on failure
  • Remote repository synchronization
  • Conflict detection and handling

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
