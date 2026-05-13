#!/usr/bin/env bash
# lib/discovery.sh — Repository discovery and filtering
#
# Usage:
#   source lib/discovery.sh
#   discover_repos "/path/to/dir" repos_array
#   should_skip_repo "/path/to/repo" patterns_array

# Prevent double-sourcing
[[ -n "${_DISCOVERY_SH_LOADED:-}" ]] && return 0
readonly _DISCOVERY_SH_LOADED=1

# Find all git repositories under a directory.
# Populates the named array variable with repo paths.
# Arguments:
#   $1 — target directory
#   $2 — name of array variable to populate
discover_repos() {
    local target_dir="$1"
    local _var_name="$2"
    local _tmp=()

    while IFS= read -r -d '' git_dir; do
        _tmp+=("$(dirname "$git_dir")")
    done < <(find "$target_dir" -name ".git" -type d -print0 2>/dev/null)

    eval "$_var_name=()"
    local _i
    for _i in "${_tmp[@]}"; do
        eval "$_var_name+=(\"\$_i\")"
    done
}

# Check if a repo path matches any skip pattern.
# Returns 0 (should skip) or 1 (should not skip).
# Arguments:
#   $1 — repo path
#   remaining args — patterns to match against
# shellcheck disable=SC2053
should_skip_repo() {
    local repo_path="$1"
    shift

    local pattern
    for pattern in "$@"; do
        if [[ "$repo_path" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Validate that a target directory is usable for repo discovery.
validate_target_dir() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        log_error "Directory does not exist: $dir"
        return 1
    fi
    if [[ ! -r "$dir" ]]; then
        log_error "No read permission for directory: $dir"
        return 1
    fi
}
