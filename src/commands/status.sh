#!/usr/bin/env bash
# src/commands/status.sh — Show status of all git repos in a directory
#
# Usage:
#   grr status [OPTIONS] [DIRECTORY]
#   grr status /repos

status_usage() {
    cat <<EOF
Usage: $(basename "$0") status [OPTIONS] [DIRECTORY]

Show the status of all git repositories under DIRECTORY.
Default directory is the current working directory.

OPTIONS:
    -s, --skip PATTERN    Skip repos matching PATTERN (repeatable)
    -h, --help            Show this help
EOF
}

status_run() {
    local target_dir="${PWD}"
    local skip_patterns=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                status_usage
                return 0
                ;;
            -s | --skip)
                if [[ $# -lt 2 ]]; then
                    log_error "--skip requires a pattern"
                    return "$ERR_INVALID_INPUT"
                fi
                skip_patterns+=("$2")
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                status_usage
                return "$ERR_INVALID_INPUT"
                ;;
            *)
                target_dir="$1"
                shift
                ;;
        esac
    done

    if ! validate_target_dir "$target_dir"; then
        return "$ERR_NOT_FOUND"
    fi

    local repos=()
    discover_repos "$target_dir" repos

    if [[ ${#repos[@]} -eq 0 ]]; then
        log_warning "No git repositories found in $target_dir"
        return 1
    fi

    log_info "Status of ${#repos[@]} repositories in $target_dir"
    echo ""
    printf "  %-30s %-15s %-12s %s\n" "REPOSITORY" "BRANCH" "STATE" "REMOTE"
    print_separator "-" 80

    for repo in "${repos[@]}"; do
        local name
        name="$(basename "$repo")"

        # Skip check
        if [[ ${#skip_patterns[@]} -gt 0 ]]; then
            if should_skip_repo "$repo" "${skip_patterns[@]}"; then
                printf "  %-30s %-15s %-12s %s\n" "$name" "-" "skipped" "-"
                continue
            fi
        fi

        if ! pushd "$repo" >/dev/null 2>&1; then
            printf "  %-30s %-15s %-12s %s\n" "$name" "?" "error" "?"
            continue
        fi

        local branch state remote ahead_behind
        branch=$(git_current_branch)
        remote=$(git_remote_url)

        if git_check_dirty >/dev/null 2>&1; then
            state="clean"
        else
            state="dirty"
        fi

        # Append ahead/behind if available
        ahead_behind=$(git_ahead_behind)
        if [[ -n "$ahead_behind" ]]; then
            local behind ahead
            behind=$(echo "$ahead_behind" | awk '{print $1}')
            ahead=$(echo "$ahead_behind" | awk '{print $2}')
            if [[ "$behind" -gt 0 || "$ahead" -gt 0 ]]; then
                state="${state} ↓${behind}↑${ahead}"
            fi
        fi

        # Truncate remote for display
        if [[ ${#remote} -gt 40 ]]; then
            remote="…${remote: -39}"
        fi

        printf "  %-30s %-15s %-12s %s\n" "$name" "$branch" "$state" "$remote"
        popd >/dev/null 2>&1 || true
    done
}
