#!/usr/bin/env bash
# lib/config.sh — Configuration loading from environment variables with defaults
#
# Usage:
#   source lib/config.sh
#   config_load
#   echo "$APP_NAME"
#   echo "$DEBUG"
#
# Environment variables (all optional, with defaults):
#   APP_NAME  — Application name (default: "bash-template")
#   DEBUG     — Enable debug mode (default: "false")
#   VERSION   — Application version (default: "dev")
#   LOG_FILE  — Log file path (default: empty/disabled)
#   TIMEOUT   — Default operation timeout in seconds (default: 300)

# Prevent double-sourcing
[[ -n "${_CONFIG_SH_LOADED:-}" ]] && return 0
readonly _CONFIG_SH_LOADED=1

config_load() {
    # Application settings
    APP_NAME="${APP_NAME:-bash-template}"
    DEBUG="${DEBUG:-false}"
    VERSION="${VERSION:-dev}"
    LOG_FILE="${LOG_FILE:-}"
    TIMEOUT="${TIMEOUT:-300}"

    # Validate boolean
    case "$DEBUG" in
        true | false) ;;
        *)
            echo "Warning: Invalid DEBUG value '$DEBUG', falling back to 'false'" >&2
            DEBUG="false"
            ;;
    esac

    # Validate timeout is numeric
    if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]]; then
        echo "Warning: Invalid TIMEOUT value '$TIMEOUT', falling back to 300" >&2
        TIMEOUT=300
    fi

    # Set verbose from debug
    if [[ "$DEBUG" == "true" ]]; then
        VERBOSE="true"
    fi

    export APP_NAME DEBUG VERSION LOG_FILE TIMEOUT VERBOSE
}

config_get() {
    local key="$1"
    local default="${2:-}"
    local value

    value="${!key:-$default}"
    echo "$value"
}

config_require() {
    local key="$1"
    local value="${!key:-}"

    if [[ -z "$value" ]]; then
        echo "Error: Required configuration '$key' is not set" >&2
        return 1
    fi
    echo "$value"
}
