#!/usr/bin/env bash
# lib/version.sh — Version information (injected at build time)
#
# Usage:
#   source lib/version.sh
#   version_print
#   version_print_full

# Prevent double-sourcing
[[ -n "${_VERSION_SH_LOADED:-}" ]] && return 0
readonly _VERSION_SH_LOADED=1

# These values are replaced by scripts/build.sh during build
readonly APP_VERSION="${APP_VERSION:-dev}"
readonly APP_COMMIT="${APP_COMMIT:-unknown}"
readonly APP_BUILD_TIME="${APP_BUILD_TIME:-unknown}"
readonly APP_BASH_VERSION="${APP_BASH_VERSION:-$BASH_VERSION}"

version_print() {
    echo "$APP_VERSION"
}

version_print_full() {
    echo "Version:    $APP_VERSION"
    echo "Commit:     $APP_COMMIT"
    echo "Built:      $APP_BUILD_TIME"
    echo "Bash:       $APP_BASH_VERSION"
}
