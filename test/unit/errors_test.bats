#!/usr/bin/env bats
# test/unit/errors_test.bats — Tests for lib/errors.sh

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    unset _ERRORS_SH_LOADED
    source "$PROJECT_ROOT/lib/errors.sh"
}

@test "error codes are defined" {
    [ "$ERR_INVALID_INPUT" -eq 10 ]
    [ "$ERR_NOT_FOUND" -eq 11 ]
    [ "$ERR_PERMISSION" -eq 12 ]
    [ "$ERR_TIMEOUT" -eq 13 ]
    [ "$ERR_CONFIGURATION" -eq 14 ]
    [ "$ERR_DEPENDENCY" -eq 15 ]
    [ "$ERR_CONFLICT" -eq 16 ]
    [ "$ERR_INTEGRATION" -eq 17 ]
}

@test "error_message returns correct message for each code" {
    run error_message 10
    [ "$output" = "Invalid input" ]

    run error_message 11
    [ "$output" = "Not found" ]

    run error_message 12
    [ "$output" = "Permission denied" ]

    run error_message 13
    [ "$output" = "Operation timed out" ]

    run error_message 14
    [ "$output" = "Configuration error" ]

    run error_message 15
    [ "$output" = "Missing dependency" ]
}

@test "error_message returns unknown for unrecognized code" {
    run error_message 99
    [[ "$output" == *"Unknown error"* ]]
    [[ "$output" == *"99"* ]]
}
