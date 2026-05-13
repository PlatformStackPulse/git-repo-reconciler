#!/usr/bin/env bash
# src/commands/hello.sh — Example command (remove/rename for your project)
#
# Usage:
#   ./src/main.sh hello [OPTIONS]
#   ./src/main.sh hello --name "Alice"

hello_usage() {
    cat <<EOF
Usage: $(basename "$0") hello [OPTIONS]

Greet someone. This is an example command — replace it with your own.

OPTIONS:
    -n, --name NAME    Name to greet (default: "World")
    -h, --help         Show this help
EOF
}

hello_run() {
    local name="World"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n | --name)
                if [[ $# -lt 2 ]]; then
                    log_error "--name requires a value"
                    return "$ERR_INVALID_INPUT"
                fi
                name="$2"
                shift 2
                ;;
            -h | --help)
                hello_usage
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                hello_usage
                return "$ERR_INVALID_INPUT"
                ;;
        esac
    done

    log_debug "hello_run called with name=$name"

    if [[ -z "$name" ]]; then
        name="World"
    fi

    local greeting
    greeting="Hello, ${name}!"

    log_info "$greeting"
    log_success "Greeting delivered"
}
