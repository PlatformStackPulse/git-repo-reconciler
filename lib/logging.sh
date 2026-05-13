#!/usr/bin/env bash
# lib/logging.sh — Structured logging with color support and file logging
#
# Usage:
#   source lib/logging.sh
#   log_info "Starting process"
#   log_success "Done"
#   log_warning "Check this"
#   log_error "Something broke"
#   log_debug "Verbose detail"   # Only shown when VERBOSE=true
#
# Environment:
#   VERBOSE   — Set to "true" to enable debug logging
#   LOG_FILE  — Set to a file path to enable file logging
#   NO_COLOR  — Set to "1" to disable colored output

# Prevent double-sourcing
[[ -n "${_LOGGING_SH_LOADED:-}" ]] && return 0
readonly _LOGGING_SH_LOADED=1

# Color codes (respect NO_COLOR convention: https://no-color.org/)
if [[ -t 1 && "${NO_COLOR:-}" != "1" ]]; then
    readonly LOG_RED='\033[0;31m'
    readonly LOG_GREEN='\033[0;32m'
    readonly LOG_YELLOW='\033[1;33m'
    readonly LOG_BLUE='\033[0;34m'
    readonly LOG_MAGENTA='\033[0;35m'
    readonly LOG_NC='\033[0m'
else
    readonly LOG_RED=''
    readonly LOG_GREEN=''
    readonly LOG_YELLOW=''
    readonly LOG_BLUE=''
    readonly LOG_MAGENTA=''
    readonly LOG_NC=''
fi

_log_to_file() {
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') $*" >>"$LOG_FILE"
    fi
}

log_info() {
    echo -e "${LOG_BLUE}[INFO]${LOG_NC} $*"
    _log_to_file "[INFO] $*"
}

log_success() {
    echo -e "${LOG_GREEN}[✓]${LOG_NC} $*"
    _log_to_file "[SUCCESS] $*"
}

log_warning() {
    echo -e "${LOG_YELLOW}[!]${LOG_NC} $*" >&2
    _log_to_file "[WARNING] $*"
}

log_error() {
    echo -e "${LOG_RED}[✗]${LOG_NC} $*" >&2
    _log_to_file "[ERROR] $*"
}

log_debug() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo -e "${LOG_BLUE}[DEBUG]${LOG_NC} $*"
        _log_to_file "[DEBUG] $*"
    fi
}

log_magenta() {
    echo -e "${LOG_MAGENTA}$*${LOG_NC}"
    _log_to_file "$*"
}
