#!/usr/bin/env bash
# src/main.sh — Entry point and command dispatcher
#
# Usage:
#   ./src/main.sh [COMMAND] [OPTIONS]
#   ./src/main.sh hello --name "World"
#   ./src/main.sh --version
#   ./src/main.sh --help

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

main_usage() {
    cat <<EOF
Usage: $(basename "$0") [COMMAND] [OPTIONS]

A production-ready bash tool template.

COMMANDS:
    hello       Example command (greet someone)

GLOBAL OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    -V, --verbose   Enable verbose/debug output
    --log FILE      Log output to file

Run '$(basename "$0") COMMAND --help' for command-specific help.
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
                # Check if it's a command-level flag (pass through)
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
        hello)
            shift
            # shellcheck source=commands/hello.sh
            source "$SRC_DIR/commands/hello.sh"
            hello_run "$@"
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
