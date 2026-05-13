#!/usr/bin/env bash
# lib/utils.sh — Common utility functions
#
# Usage:
#   source lib/utils.sh
#   require_command "curl"
#   require_bash_version 4

# Prevent double-sourcing
[[ -n "${_UTILS_SH_LOADED:-}" ]] && return 0
readonly _UTILS_SH_LOADED=1

# Check that a command is available
require_command() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' is not installed" >&2
        if [[ -n "$install_hint" ]]; then
            echo "Install with: $install_hint" >&2
        fi
        return 1
    fi
}

# Check minimum bash version
require_bash_version() {
    local min_version="$1"
    local current_major="${BASH_VERSINFO[0]}"

    if [[ "$current_major" -lt "$min_version" ]]; then
        echo "Error: Bash $min_version+ required (current: $BASH_VERSION)" >&2
        return 1
    fi
}

# Validate a value is not empty
validate_not_empty() {
    local name="$1"
    local value="$2"

    if [[ -z "$value" ]]; then
        echo "Error: $name cannot be empty" >&2
        return 1
    fi
}

# Validate a value is a positive integer
validate_positive_int() {
    local name="$1"
    local value="$2"

    if ! [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: $name must be a positive integer (got: '$value')" >&2
        return 1
    fi
}

# Validate a file exists and is readable
validate_file_readable() {
    local path="$1"

    if [[ ! -f "$path" ]]; then
        echo "Error: File not found: $path" >&2
        return 1
    fi
    if [[ ! -r "$path" ]]; then
        echo "Error: File not readable: $path" >&2
        return 1
    fi
}

# Validate a directory exists and is writable
validate_dir_writable() {
    local path="$1"

    if [[ ! -d "$path" ]]; then
        echo "Error: Directory not found: $path" >&2
        return 1
    fi
    if [[ ! -w "$path" ]]; then
        echo "Error: Directory not writable: $path" >&2
        return 1
    fi
}

# Print a separator line
print_separator() {
    local char="${1:-=-}"
    local width="${2:-72}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# Confirm an action with the user (returns 0 for yes, 1 for no)
confirm() {
    local prompt="${1:-Are you sure?}"
    local reply

    read -r -p "$prompt [y/N] " reply
    case "$reply" in
        [yY][eE][sS] | [yY]) return 0 ;;
        *) return 1 ;;
    esac
}
