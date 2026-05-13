#!/usr/bin/env bats
# test/integration/flow_test.bats — End-to-end integration tests

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export NO_COLOR=1
    export VERBOSE="false"
    export LOG_FILE=""
}

@test "full flow: build and run hello" {
    # Build
    run bash "$PROJECT_ROOT/scripts/build.sh" "test" "abc1234" "2026-01-01"
    [ "$status" -eq 0 ]
    [ -f "$PROJECT_ROOT/bin/bash-template" ]

    # Run built binary
    run "$PROJECT_ROOT/bin/bash-template" hello --name "Integration"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Hello, Integration!"* ]]
}

@test "full flow: version output after build" {
    run "$PROJECT_ROOT/bin/bash-template" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version:"* ]]
}

@test "full flow: help output" {
    run "$PROJECT_ROOT/bin/bash-template" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"COMMANDS"* ]]
}

@test "full flow: verbose mode" {
    run bash "$PROJECT_ROOT/src/main.sh" -V hello --name "Debug"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Hello, Debug!"* ]]
}

@test "full flow: file logging" {
    local tmplog
    tmplog=$(mktemp)
    run bash "$PROJECT_ROOT/src/main.sh" --log "$tmplog" hello --name "Logged"
    [ "$status" -eq 0 ]
    grep -q "Logged" "$tmplog"
    rm -f "$tmplog"
}
