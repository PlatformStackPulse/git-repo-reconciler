#!/usr/bin/env bash
# lib/git.sh — Atomic git operations for repository reconciliation
#
# Usage:
#   source lib/git.sh
#   git_fetch
#   git_pull_rebase
#   git_stash_changes

# Prevent double-sourcing
[[ -n "${_GIT_SH_LOADED:-}" ]] && return 0
readonly _GIT_SH_LOADED=1

# Portable timeout wrapper (macOS lacks GNU timeout)
_git_timeout() {
    local secs="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$secs" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$secs" "$@"
    else
        "$@"
    fi
}

# Check if a remote origin is configured
git_has_remote() {
    git remote get-url origin >/dev/null 2>&1
}

# Fetch all remotes with pruning
git_fetch() {
    if ! git_has_remote; then
        log_debug "No remote configured, skipping fetch"
        return 0
    fi
    log_debug "Running: git fetch --all --prune --tags"
    if ! _git_timeout "${TIMEOUT:-300}" git fetch --all --prune --tags >/dev/null 2>&1; then
        log_error "git fetch failed"
        return 1
    fi
}

# Pull with rebase
git_pull_rebase() {
    if ! git_has_remote; then
        log_debug "No remote configured, skipping pull"
        return 0
    fi
    log_debug "Running: git pull --rebase"
    if ! _git_timeout "${TIMEOUT:-300}" git pull --rebase >/dev/null 2>&1; then
        log_error "git pull --rebase failed"
        return 1
    fi
}

# Stash uncommitted changes (including untracked)
git_stash_changes() {
    log_debug "Stashing changes with: git stash -u"
    if ! git stash -u >/dev/null 2>&1; then
        log_warning "Failed to stash changes (continuing)"
    fi
}

# Hard reset to origin/<branch> with HEAD fallback
git_reset_hard() {
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

    if git_has_remote; then
        log_debug "Running: git reset --hard origin/$current_branch"
        if ! _git_timeout "${TIMEOUT:-300}" git reset --hard "origin/$current_branch" >/dev/null 2>&1; then
            log_debug "Falling back to: git reset --hard HEAD"
            if ! _git_timeout "${TIMEOUT:-300}" git reset --hard HEAD >/dev/null 2>&1; then
                log_error "git reset failed"
                return 1
            fi
        fi
    else
        log_debug "No remote, resetting to HEAD"
        if ! _git_timeout "${TIMEOUT:-300}" git reset --hard HEAD >/dev/null 2>&1; then
            log_error "git reset failed"
            return 1
        fi
    fi
}

# Clean untracked files and directories
git_clean_untracked() {
    log_debug "Running: git clean -fd"
    if ! _git_timeout "${TIMEOUT:-300}" git clean -fd >/dev/null 2>&1; then
        log_error "git clean -fd failed"
        return 1
    fi
}

# Checkout first available branch from a list
# Arguments: branch names (space-separated)
git_checkout_branch() {
    local branch
    for branch in "$@"; do
        log_debug "Trying to checkout branch: $branch"
        if git checkout "$branch" &>/dev/null; then
            log_debug "Checked out: $branch"
            return 0
        fi
    done
    log_error "Could not checkout any of: $*"
    return 1
}

# Check for uncommitted changes; returns 1 if dirty
git_check_dirty() {
    local status
    status=$(git status --porcelain 2>/dev/null || echo "")
    if [[ -n "$status" ]]; then
        echo "$status"
        return 1
    fi
    return 0
}

# Check if repository is a shallow clone
git_is_shallow() {
    local shallow
    shallow=$(git rev-parse --is-shallow-repository 2>/dev/null || echo "false")
    [[ "$shallow" == "true" ]]
}

# Convert shallow clone to full repository
git_unshallow() {
    log_debug "Converting shallow clone to full repository"
    if ! _git_timeout "${TIMEOUT:-300}" git fetch --unshallow >/dev/null 2>&1; then
        log_warning "Could not unshallow repository (continuing)"
    fi
}

# Update submodules recursively (silently skips if none exist)
git_update_submodules() {
    if ! git config --file .gitmodules --name-only --get-regexp path >/dev/null 2>&1; then
        log_debug "No submodules found"
        return 0
    fi
    log_debug "Running: git submodule update --init --recursive"
    if ! _git_timeout "${TIMEOUT:-300}" git submodule update --init --recursive >/dev/null 2>&1; then
        log_warning "Submodule update failed (continuing)"
    fi
}

# Run git garbage collection
git_garbage_collect() {
    log_debug "Running: git gc --auto"
    if ! _git_timeout "${TIMEOUT:-300}" git gc --auto >/dev/null 2>&1; then
        log_warning "Garbage collection failed (continuing)"
    fi
}

# Show recent commits (for verification)
git_show_recent_commits() {
    local count="${1:-3}"
    local log_output
    log_output=$(git log -"$count" --oneline 2>/dev/null || echo "")
    if [[ -n "$log_output" ]]; then
        log_magenta "  Recent commits:"
        echo "    ${log_output//$'\n'/$'\n'    }"
    fi
}

# Get the remote origin URL
git_remote_url() {
    git config --get remote.origin.url 2>/dev/null || echo "unknown"
}

# Get current branch name
git_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached"
}

# Get ahead/behind counts relative to upstream
git_ahead_behind() {
    local upstream
    upstream=$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null) || return 0
    local counts
    counts=$(git rev-list --left-right --count "$upstream"...HEAD 2>/dev/null) || return 0
    echo "$counts"
}
