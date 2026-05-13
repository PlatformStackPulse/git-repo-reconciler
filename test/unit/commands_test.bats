#!/usr/bin/env bats
# test/unit/commands_test.bats — Tests for src/commands/hello.sh

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export NO_COLOR=1
    export VERBOSE="false"
    export LOG_FILE=""
}

@test "main.sh --help shows usage" {
    run bash "$PROJECT_ROOT/src/main.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"COMMANDS"* ]]
    [[ "$output" == *"hello"* ]]
}

@test "main.sh --version shows version" {
    run bash "$PROJECT_ROOT/src/main.sh" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version:"* ]]
}

@test "hello command runs with default name" {
    run bash "$PROJECT_ROOT/src/main.sh" hello
    [ "$status" -eq 0 ]
    [[ "$output" == *"Hello, World!"* ]]
}

@test "hello command accepts --name flag" {
    run bash "$PROJECT_ROOT/src/main.sh" hello --name "Alice"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Hello, Alice!"* ]]
}

@test "hello --help shows command help" {
    run bash "$PROJECT_ROOT/src/main.sh" hello --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--name"* ]]
}

@test "unknown command shows error" {
    run bash "$PROJECT_ROOT/src/main.sh" nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "no command shows usage" {
    run bash "$PROJECT_ROOT/src/main.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"COMMANDS"* ]]
}
