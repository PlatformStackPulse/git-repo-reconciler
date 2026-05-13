#!/usr/bin/env bats
# test/unit/config_test.bats — Tests for lib/config.sh

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    unset _CONFIG_SH_LOADED
    unset APP_NAME DEBUG VERSION LOG_FILE TIMEOUT VERBOSE
    source "$PROJECT_ROOT/lib/config.sh"
}

@test "config_load sets defaults" {
    config_load
    [ "$APP_NAME" = "bash-template" ]
    [ "$DEBUG" = "false" ]
    [ "$VERSION" = "dev" ]
    [ "$LOG_FILE" = "" ]
    [ "$TIMEOUT" = "300" ]
}

@test "config_load reads from environment" {
    export APP_NAME="my-tool"
    export DEBUG="true"
    config_load
    [ "$APP_NAME" = "my-tool" ]
    [ "$DEBUG" = "true" ]
    [ "$VERBOSE" = "true" ]
}

@test "config_load rejects invalid DEBUG value" {
    export DEBUG="banana"
    run config_load
    [ "$status" -eq 0 ]
    [[ "$output" == *"Invalid DEBUG"* ]]
}

@test "config_load rejects invalid TIMEOUT value" {
    export TIMEOUT="abc"
    run config_load
    [ "$status" -eq 0 ]
    [[ "$output" == *"Invalid TIMEOUT"* ]]
}

@test "config_get returns value or default" {
    export MY_VAR="hello"
    run config_get "MY_VAR" "fallback"
    [ "$output" = "hello" ]
}

@test "config_get returns default for unset var" {
    unset UNSET_VAR 2>/dev/null || true
    run config_get "UNSET_VAR" "fallback"
    [ "$output" = "fallback" ]
}

@test "config_require fails for missing var" {
    unset MISSING_VAR 2>/dev/null || true
    run config_require "MISSING_VAR"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Required configuration"* ]]
}

@test "config_require returns value when set" {
    export PRESENT_VAR="exists"
    run config_require "PRESENT_VAR"
    [ "$status" -eq 0 ]
    [ "$output" = "exists" ]
}
