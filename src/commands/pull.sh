#!/usr/bin/env bash
# src/commands/pull.sh — Bulk-pull (reconcile) all git repos in a directory
#
# Usage:
#   grr pull [OPTIONS] [DIRECTORY]
#   grr pull --fetch --stash -V /repos
#   grr pull -d --fetch /repos

pull_usage() {
    cat <<EOF
Usage: $(basename "$0") pull [OPTIONS] [DIRECTORY]

Reconcile (pull) all git repositories found under DIRECTORY.
Default directory is the current working directory.

OPTIONS:
    -d, --dry-run           Show what would be done without making changes
    -p, --parallel N        Run N parallel operations (default: 1)
    -b, --branches B1,B2    Comma-separated branches to try (default: master,main,develop)
    -s, --skip PATTERN      Skip repos matching PATTERN (repeatable)
    -t, --timeout SECS      Timeout for git operations (default: 300)
    -h, --help              Show this help

PULL OPTIONS:
    --fetch                 Fetch from remotes first (recommended)
    --stash                 Stash uncommitted changes before pulling
    --submodules            Update submodules recursively
    --check-status          Warn about uncommitted changes
    --verify                Show last commits after pull
    --handle-shallow        Convert shallow clones to full repos
    --gc                    Run garbage collection after pull

SAFETY:
    --strict                Exit on first error (default: continue)
    --max-log N             Commits to show with --verify (default: 3)

EXAMPLES:
    # Safe pull with full features
    $(basename "$0") pull --fetch --check-status --stash -V /repos

    # Fast parallel pull with logging
    $(basename "$0") pull --fetch -p 4 --log pull.log /repos

    # Preview before running
    $(basename "$0") pull -d --fetch /repos
EOF
}

# ── Per-repo pipeline ────────────────────────────────────────────────────────

_pull_process_repo() {
    local repo_dir="$1"
    local repo_name
    repo_name="$(basename "$repo_dir")"

    log_debug "Processing: $repo_dir"

    # Skip check
    if [[ ${#_PULL_SKIP[@]} -gt 0 ]]; then
        if should_skip_repo "$repo_dir" "${_PULL_SKIP[@]}"; then
            log_warning "Skipping (matched pattern): $repo_name"
            return 2 # special code: skipped
        fi
    fi

    if ! pushd "$repo_dir" >/dev/null 2>&1; then
        log_error "Cannot enter directory: $repo_dir"
        return 1
    fi

    local remote_url
    remote_url=$(git_remote_url)

    # ── Dry-run ──────────────────────────────────────────────────────────
    if [[ "${_PULL_DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would process: $repo_name"
        echo "  Remote: $remote_url"
        echo "  Operations:"
        if [[ "${_PULL_FETCH}" == "true" ]]; then echo "    - git fetch --all --prune --tags"; fi
        if [[ "${_PULL_CHECK_STATUS}" == "true" ]]; then echo "    - git status check"; fi
        if [[ "${_PULL_HANDLE_SHALLOW}" == "true" ]]; then echo "    - check/unshallow if needed"; fi
        if [[ "${_PULL_STASH}" == "true" ]]; then echo "    - git stash -u"; fi
        echo "    - git checkout ${_PULL_BRANCHES[0]}"
        echo "    - git reset --hard origin/${_PULL_BRANCHES[0]}"
        echo "    - git clean -fd"
        if [[ "${_PULL_SUBMODULES}" == "true" ]]; then echo "    - git submodule update --recursive"; fi
        echo "    - git pull --rebase"
        if [[ "${_PULL_VERIFY}" == "true" ]]; then echo "    - show last ${_PULL_MAX_LOG} commits"; fi
        if [[ "${_PULL_GC}" == "true" ]]; then echo "    - git gc --auto"; fi
        popd >/dev/null 2>&1 || true
        return 0
    fi

    # ── Live execution pipeline ──────────────────────────────────────────
    local rc=0

    # 1. Fetch
    if [[ $rc -eq 0 && "${_PULL_FETCH}" == "true" ]]; then
        if ! git_fetch; then rc=1; fi
    fi

    # 2. Status check
    if [[ $rc -eq 0 && "${_PULL_CHECK_STATUS}" == "true" ]]; then
        local dirty
        if dirty=$(git_check_dirty); then
            : # clean
        else
            log_warning "Uncommitted changes in $repo_name:"
            echo "  ${dirty//$'\n'/$'\n'  }"
            if [[ "${_PULL_STASH}" != "true" ]]; then
                log_error "Cannot pull with uncommitted changes (use --stash)"
                rc=1
            fi
        fi
    fi

    # 3. Handle shallow repos
    if [[ $rc -eq 0 && "${_PULL_HANDLE_SHALLOW}" == "true" ]]; then
        if git_is_shallow; then
            log_warning "Shallow clone detected, unshallowing..."
            git_unshallow
        fi
    fi

    # 4. Stash
    if [[ $rc -eq 0 && "${_PULL_STASH}" == "true" ]]; then
        git_stash_changes
    fi

    # 5. Checkout branch
    if [[ $rc -eq 0 ]]; then
        if ! git_checkout_branch "${_PULL_BRANCHES[@]}"; then rc=1; fi
    fi

    # 6. Reset
    if [[ $rc -eq 0 ]]; then
        if ! git_reset_hard; then rc=1; fi
    fi

    # 7. Clean
    if [[ $rc -eq 0 ]]; then
        if ! git_clean_untracked; then rc=1; fi
    fi

    # 8. Submodules
    if [[ $rc -eq 0 && "${_PULL_SUBMODULES}" == "true" ]]; then
        git_update_submodules
    fi

    # 9. Pull
    if [[ $rc -eq 0 ]]; then
        if ! git_pull_rebase; then rc=1; fi
    fi

    # 10. Verify
    if [[ $rc -eq 0 && "${_PULL_VERIFY}" == "true" ]]; then
        git_show_recent_commits "${_PULL_MAX_LOG}"
    fi

    # 11. GC
    if [[ $rc -eq 0 && "${_PULL_GC}" == "true" ]]; then
        git_garbage_collect
    fi

    popd >/dev/null 2>&1 || true

    if [[ $rc -eq 0 ]]; then
        log_success "$repo_name updated"
    else
        log_error "$repo_name failed to update"
    fi
    return $rc
}

# ── Print summary ────────────────────────────────────────────────────────────

_pull_print_summary() {
    local total="$1" success="$2" failed="$3" skipped="$4"

    echo ""
    print_separator "="
    echo "  Total repositories found: $total"
    echo "  Successfully updated:     $success"
    echo "  Failed updates:           $failed"
    echo "  Skipped:                  $skipped"
    print_separator "="

    if [[ $failed -eq 0 && $total -gt 0 ]]; then
        log_success "All repositories reconciled successfully!"
        return 0
    elif [[ $total -eq 0 ]]; then
        log_warning "No git repositories found"
        return 1
    else
        log_error "Some repositories failed (see errors above)"
        return 1
    fi
}

# ── Entry point ──────────────────────────────────────────────────────────────

pull_run() {
    # Command-local defaults
    local target_dir="${PWD}"
    _PULL_DRY_RUN="false"
    _PULL_FETCH="false"
    _PULL_STASH="false"
    _PULL_CHECK_STATUS="false"
    _PULL_SUBMODULES="false"
    _PULL_VERIFY="false"
    _PULL_HANDLE_SHALLOW="false"
    _PULL_GC="false"
    _PULL_MAX_LOG=3
    _PULL_BRANCHES=(master main develop)
    _PULL_SKIP=()
    local parallel=1
    local strict="false"

    # Parse command options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                pull_usage
                return 0
                ;;
            -d | --dry-run)
                _PULL_DRY_RUN="true"
                shift
                ;;
            --fetch)
                _PULL_FETCH="true"
                shift
                ;;
            --stash)
                _PULL_STASH="true"
                shift
                ;;
            --check-status)
                _PULL_CHECK_STATUS="true"
                shift
                ;;
            --submodules)
                _PULL_SUBMODULES="true"
                shift
                ;;
            --verify)
                _PULL_VERIFY="true"
                shift
                ;;
            --handle-shallow)
                _PULL_HANDLE_SHALLOW="true"
                shift
                ;;
            --gc)
                _PULL_GC="true"
                shift
                ;;
            --strict)
                strict="true"
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
            -b | --branches)
                if [[ $# -lt 2 ]]; then
                    log_error "--branches requires a comma-separated list"
                    return "$ERR_INVALID_INPUT"
                fi
                IFS=',' read -ra _PULL_BRANCHES <<<"$2"
                shift 2
                ;;
            -s | --skip)
                if [[ $# -lt 2 ]]; then
                    log_error "--skip requires a pattern"
                    return "$ERR_INVALID_INPUT"
                fi
                _PULL_SKIP+=("$2")
                shift 2
                ;;
            -t | --timeout)
                if [[ $# -lt 2 ]]; then
                    log_error "--timeout requires seconds"
                    return "$ERR_INVALID_INPUT"
                fi
                TIMEOUT="$2"
                export TIMEOUT
                shift 2
                ;;
            --max-log)
                if [[ $# -lt 2 ]]; then
                    log_error "--max-log requires a number"
                    return "$ERR_INVALID_INPUT"
                fi
                _PULL_MAX_LOG="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                pull_usage
                return "$ERR_INVALID_INPUT"
                ;;
            *)
                target_dir="$1"
                shift
                ;;
        esac
    done

    # Validate
    if ! validate_target_dir "$target_dir"; then
        return "$ERR_NOT_FOUND"
    fi
    if ! [[ "$parallel" =~ ^[1-9][0-9]*$ ]]; then
        log_error "Parallel count must be a positive integer (got: '$parallel')"
        return "$ERR_INVALID_INPUT"
    fi

    # Discover repos
    local repos=()
    discover_repos "$target_dir" repos
    local total=${#repos[@]}

    if [[ $total -eq 0 ]]; then
        log_warning "No git repositories found in $target_dir"
        _pull_print_summary 0 0 0 0
        return 1
    fi

    log_info "Starting reconciliation from: $target_dir"
    if [[ "${_PULL_DRY_RUN}" == "true" ]]; then
        log_warning "DRY-RUN MODE: No changes will be made"
    fi
    log_info "Found $total repository/repositories"

    # Show config in verbose mode
    log_debug "Configuration:"
    log_debug "  Parallel: $parallel"
    log_debug "  Timeout: ${TIMEOUT}s"
    log_debug "  Branches: ${_PULL_BRANCHES[*]}"
    if [[ "${_PULL_FETCH}" == "true" ]]; then log_debug "  Fetch first: yes"; fi
    if [[ "${_PULL_CHECK_STATUS}" == "true" ]]; then log_debug "  Check status: yes"; fi
    if [[ "${_PULL_STASH}" == "true" ]]; then log_debug "  Stash changes: yes"; fi
    if [[ "${_PULL_SUBMODULES}" == "true" ]]; then log_debug "  Update submodules: yes"; fi
    if [[ "${_PULL_VERIFY}" == "true" ]]; then log_debug "  Verify pull: yes"; fi
    if [[ "${_PULL_HANDLE_SHALLOW}" == "true" ]]; then log_debug "  Handle shallow: yes"; fi
    if [[ "${_PULL_GC}" == "true" ]]; then log_debug "  Garbage collect: yes"; fi

    # ── Execute ──────────────────────────────────────────────────────────
    local success=0 failed=0 skipped=0

    if [[ $parallel -gt 1 ]]; then
        log_info "Processing with $parallel parallel jobs"
        log_warning "Parallel mode — output may interleave"

        local tmpdir
        tmpdir=$(mktemp -d)
        # shellcheck disable=SC2064
        trap "rm -rf '$tmpdir'" EXIT

        local job_id=0
        for repo in "${repos[@]}"; do
            wait_for_job_slot "$parallel"

            job_id=$((job_id + 1))
            (
                local result
                if _pull_process_repo "$repo"; then
                    result="success"
                else
                    local rc=$?
                    if [[ $rc -eq 2 ]]; then
                        result="skipped"
                    else
                        result="failed"
                    fi
                fi
                echo "$result" >"$tmpdir/job_${job_id}"
            ) &
        done
        wait

        # Tally results from temp files
        for f in "$tmpdir"/job_*; do
            [[ -f "$f" ]] || continue
            case "$(cat "$f")" in
                success) success=$((success + 1)) ;;
                skipped) skipped=$((skipped + 1)) ;;
                *) failed=$((failed + 1)) ;;
            esac
        done
        rm -rf "$tmpdir"
    else
        for repo in "${repos[@]}"; do
            if _pull_process_repo "$repo"; then
                success=$((success + 1))
            else
                local rc=$?
                if [[ $rc -eq 2 ]]; then
                    skipped=$((skipped + 1))
                else
                    failed=$((failed + 1))
                    if [[ "$strict" == "true" ]]; then
                        _pull_print_summary "$total" "$success" "$failed" "$skipped"
                        return 1
                    fi
                fi
            fi
        done
    fi

    _pull_print_summary "$total" "$success" "$failed" "$skipped"
}
