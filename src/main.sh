#!/usr/bin/env bash
# src/main.sh — GRR (Git Repo Reconciler) entry point and command dispatcher
#
# Usage:
#   grr [COMMAND] [OPTIONS]
#   grr pull --fetch --stash /repos
#   grr status /repos
#   grr --version

set -euo pipefail

# Resolve script and project directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$SCRIPT_DIR"
LIB_DIR="$PROJECT_ROOT/lib"

# Source libraries
# shellcheck source=../lib/logging.sh
source "$LIB_DIR/logging.sh"
# shellcheck source=../lib/config.sh
source "$LIB_DIR/config.sh"
# shellcheck source=../lib/errors.sh
source "$LIB_DIR/errors.sh"
# shellcheck source=../lib/utils.sh
source "$LIB_DIR/utils.sh"
# shellcheck source=../lib/version.sh
source "$LIB_DIR/version.sh"
# shellcheck source=../lib/git.sh
source "$LIB_DIR/git.sh"
# shellcheck source=../lib/discovery.sh
source "$LIB_DIR/discovery.sh"

main_usage() {
    cat <<EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

GRR — Git Repo Reconciler
Bulk-update, inspect, and reconcile git repositories at scale.

COMMANDS:
    clone       Batch clone repositories from a GitHub account
    pull        Reconcile (pull) all repos in a directory
    status      Show status of all repos in a directory

GLOBAL OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    -V, --verbose   Enable verbose/debug output
    --log FILE      Log output to file

Run '$(basename "$0") COMMAND --help' for command-specific help.

EXAMPLES:
    $(basename "$0") clone PlatformStackPulse ./my-repos -p 4
    $(basename "$0") pull --fetch --stash -V /repos
    $(basename "$0") pull -d --fetch /repos
    $(basename "$0") status /repos
EOF
}

main() {
    # Parse global options before command dispatch
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                main_usage
                exit 0
                ;;
            -v | --version)
                version_print_full
                exit 0
                ;;
            -V | --verbose)
                VERBOSE="true"
                export VERBOSE
                shift
                ;;
            --log)
                if [[ $# -lt 2 ]]; then
                    log_error "--log requires a filename"
                    exit 1
                fi
                LOG_FILE="$2"
                export LOG_FILE
                shift 2
                ;;
            -*)
                # Command-level flag — pass through
                break
                ;;
            *)
                # First non-flag argument is the command
                break
                ;;
        esac
    done

    # Load configuration
    config_load

    # Command dispatch
    local command="${1:-}"
    case "$command" in
        clone)
            shift
            # shellcheck source=commands/clone.sh
            source "$SRC_DIR/commands/clone.sh"
            clone_run "$@"
            ;;
        pull)
            shift
            # shellcheck source=commands/pull.sh
            source "$SRC_DIR/commands/pull.sh"
            pull_run "$@"
            ;;
        status)
            shift
            # shellcheck source=commands/status.sh
            source "$SRC_DIR/commands/status.sh"
            status_run "$@"
            ;;
        "")
            main_usage
            exit 1
            ;;
        *)
            log_error "Unknown command: $command"
            main_usage
            exit 1
            ;;
    esac
}

main "$@"
