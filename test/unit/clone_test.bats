#!/usr/bin/env bats
# test/unit/clone_test.bats — Tests for grr clone command

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export NO_COLOR=1
    export VERBOSE="false"
    export LOG_FILE=""
}

@test "clone --help shows usage" {
    run bash "$PROJECT_ROOT/src/main.sh" clone --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--parallel"* ]]
}

@test "clone with no account shows error" {
    run bash "$PROJECT_ROOT/src/main.sh" clone
    [ "$status" -eq 10 ] # ERR_INVALID_INPUT
    [[ "$output" == *"Account name"* ]]
}

@test "clone --dry-run handles missing account gracefully" {
    # Mocks for curl/jq are harder in pure bats without a mocking library, 
    # but we can test the pre-API logic.
    run bash "$PROJECT_ROOT/src/main.sh" clone -d
    [ "$status" -eq 10 ]
}

@test "clone rejects invalid parallel count" {
    run bash "$PROJECT_ROOT/src/main.sh" clone myaccount -p 0
    [ "$status" -eq 10 ]
    [[ "$output" == *"positive integer"* ]]
}

@test "clone handles invalid directory permission" {
    # This might fail if run as root, but usually /root is protected
    run bash "$PROJECT_ROOT/src/main.sh" clone myaccount /root/no-access
    [[ "$status" -eq 12 ]] # ERR_PERMISSION
}
