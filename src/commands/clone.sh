#!/usr/bin/env bash
# src/commands/clone.sh — Batch clone all repositories from a GitHub account
#
# Usage:
#   grr clone [OPTIONS] <ACCOUNT> [DIRECTORY]
#   grr clone PlatformStackPulse /repos -p 4

clone_usage() {
    cat <<EOF
Usage: $(basename "$0") clone [OPTIONS] <ACCOUNT> [DIRECTORY]

Batch clone all public repositories from a GitHub User or Organization.
Default directory is the current working directory.

OPTIONS:
    -d, --dry-run           Show what would be cloned without making changes
    -p, --parallel N        Run N parallel clone operations (default: 1)
    -t, --token TOKEN       GitHub Personal Access Token (or set GITHUB_TOKEN env)
    -h, --help              Show this help

EXAMPLES:
    # Clone all repos from a user/org
    $(basename "$0") clone PlatformStackPulse ./my-repos

    # Fast parallel clone with 4 jobs
    $(basename "$0") clone PlatformStackPulse -p 4
EOF
}

# ── Per-repo clone logic ──────────────────────────────────────────────────────

_clone_process_repo() {
    local name="$1"
    local url="$2"
    local target_dir="$3"
    local repo_path="$target_dir/$name"

    if [[ -d "$repo_path" ]]; then
        log_warning "Skipping (already exists): $name"
        return 2 # special code: skipped
    fi

    if [[ "${_CLONE_DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would clone: $name ($url)"
        return 0
    fi

    log_info "Cloning: $name..."
    if ! git clone "$url" "$repo_path" >/dev/null 2>&1; then
        log_error "Failed to clone: $name"
        return 1
    fi

    log_success "Cloned: $name"
    return 0
}

# ── Summary ──────────────────────────────────────────────────────────────────

_clone_print_summary() {
    local total="$1" success="$2" failed="$3" skipped="$4"

    echo ""
    print_separator "="
    echo "  Total repositories found: $total"
    echo "  Successfully cloned:      $success"
    echo "  Failed:                   $failed"
    echo "  Skipped (exists):         $skipped"
    print_separator "="

    if [[ $failed -eq 0 && $total -gt 0 ]]; then
        log_success "Batch clone completed successfully!"
        return 0
    elif [[ $total -eq 0 ]]; then
        log_warning "No repositories found for account"
        return 1
    else
        log_error "Some clones failed (see errors above)"
        return 1
    fi
}

# ── Entry point ──────────────────────────────────────────────────────────────

clone_run() {
    local account=""
    local target_dir="${PWD}"
    _CLONE_DRY_RUN="false"
    local parallel=1
    local token="${GITHUB_TOKEN:-}"

    # Parse command options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                clone_usage
                return 0
                ;;
            -d | --dry-run)
                _CLONE_DRY_RUN="true"
                shift
                ;;
            -p | --parallel)
                if [[ $# -lt 2 ]]; then
                    log_error "--parallel requires a number"
                    return "$ERR_INVALID_INPUT"
                fi
                parallel="$2"
                shift 2
                ;;
            -t | --token)
                if [[ $# -lt 2 ]]; then
                    log_error "--token requires a value"
                    return "$ERR_INVALID_INPUT"
                fi
                token="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                clone_usage
                return "$ERR_INVALID_INPUT"
                ;;
            *)
                if [[ -z "$account" ]]; then
                    account="$1"
                else
                    target_dir="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate input
    if [[ -z "$account" ]]; then
        log_error "Account name (User or Org) is required"
        clone_usage
        return "$ERR_INVALID_INPUT"
    fi

    require_command "curl" "sudo apt install curl" || return "$ERR_DEPENDENCY"
    require_command "jq" "sudo apt install jq" || return "$ERR_DEPENDENCY"

    if ! [[ "$parallel" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Parallel count must be a positive integer (got: '$parallel')"
        return "$ERR_INVALID_INPUT"
    fi

    mkdir -p "$target_dir" || {
        log_error "Cannot create/access directory: $target_dir"
        return "$ERR_PERMISSION"
    }

    # ── Fetch repository list from GitHub API ────────────────────────────────

    log_info "Fetching repository list for: $account"

    local headers=()
    headers+=("-H" "Accept: application/vnd.github.v3+json")
    if [[ -n "$token" ]]; then
        headers+=("-H" "Authorization: token $token")
    fi

    # 1. Determine account type (User or Org)
    local account_data
    account_data=$(curl -s "${headers[@]}" "https://api.github.com/users/$account")
    local account_type
    account_type=$(echo "$account_data" | jq -r '.type // empty')

    if [[ -z "$account_type" ]]; then
        log_error "Could not find account: $account"
        return "$ERR_NOT_FOUND"
    fi

    local type_path="users"
    if [[ "$account_type" == "Organization" ]]; then
        type_path="orgs"
        log_debug "Account is an Organization"
    else
        log_debug "Account is a User"
    fi

    # 2. Fetch all repositories (paginated)
    local page=1
    local repo_names=()
    local repo_urls=()

    while true; do
        log_debug "Fetching page $page..."
        local res
        res=$(curl -s "${headers[@]}" "https://api.github.com/$type_path/$account/repos?per_page=100&page=$page")

        # Check for errors in API response
        if echo "$res" | jq -e 'type == "object" and .message != null' >/dev/null; then
            local message
            message=$(echo "$res" | jq -r '.message')
            if [[ "$message" != "Not Found" ]]; then
                log_error "GitHub API error: $message"
                return "$ERR_INTEGRATION"
            fi
        fi

        local count
        count=$(echo "$res" | jq '. | length')
        if [[ -z "$count" || "$count" == "0" || "$res" == "[]" ]]; then
            break
        fi

        # Extract names and clone URLs
        while IFS= read -r line; do repo_names+=("$line"); done < <(echo "$res" | jq -r '.[].name')
        while IFS= read -r line; do repo_urls+=("$line"); done < <(echo "$res" | jq -r '.[].clone_url')

        if [[ "$count" -lt 100 ]]; then
            break
        fi
        page=$((page + 1))
    done

    local total=${#repo_names[@]}
    if [[ $total -eq 0 ]]; then
        log_warning "No public repositories found for $account"
        _clone_print_summary 0 0 0 0
        return 0
    fi

    log_info "Found $total repository/repositories"

    # ── Execute Cloning ──────────────────────────────────────────────────────
    local success=0 failed=0 skipped=0

    if [[ $parallel -gt 1 ]]; then
        log_info "Cloning with $parallel parallel jobs"
        local tmpdir
        tmpdir=$(mktemp -d)
        trap 'rm -rf "$tmpdir"' EXIT

        local i=0
        for ((i = 0; i < total; i++)); do
            wait_for_job_slot "$parallel"

            (
                local result
                if _clone_process_repo "${repo_names[$i]}" "${repo_urls[$i]}" "$target_dir"; then
                    result="success"
                else
                    [[ $? -eq 2 ]] && result="skipped" || result="failed"
                fi
                echo "$result" >"$tmpdir/job_$i"
            ) &
        done
        wait

        for f in "$tmpdir"/job_*; do
            [[ -f "$f" ]] || continue
            case "$(cat "$f")" in
                success) success=$((success + 1)) ;;
                skipped) skipped=$((skipped + 1)) ;;
                *) failed=$((failed + 1)) ;;
            esac
        done
    else
        local i=0
        for ((i = 0; i < total; i++)); do
            if _clone_process_repo "${repo_names[$i]}" "${repo_urls[$i]}" "$target_dir"; then
                success=$((success + 1))
            else
                [[ $? -eq 2 ]] && skipped=$((skipped + 1)) || failed=$((failed + 1))
            fi
        done
    fi

    _clone_print_summary "$total" "$success" "$failed" "$skipped"
}
