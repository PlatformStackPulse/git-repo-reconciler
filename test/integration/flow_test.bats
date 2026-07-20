#!/usr/bin/env bats
# test/integration/flow_test.bats — End-to-end integration tests

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export NO_COLOR=1
    export VERBOSE="false"
    export LOG_FILE=""

    # Create a temp directory with a real git repo for integration tests
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/repo-alpha"
    cd "$TEST_DIR/repo-alpha"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "alpha" > file.txt
    git add .
    git commit -q -m "initial commit"
    cd "$PROJECT_ROOT"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "full flow: build and run pull --help" {
    run bash "$PROJECT_ROOT/scripts/build.sh" "test" "abc1234" "2026-01-01"
    [ "$status" -eq 0 ]
    [ -f "$PROJECT_ROOT/bin/grr" ]

    run "$PROJECT_ROOT/bin/grr" pull --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--fetch"* ]]
}

@test "full flow: build and run status" {
    run bash "$PROJECT_ROOT/scripts/build.sh" "test" "abc1234" "2026-01-01"
    [ "$status" -eq 0 ]

    run "$PROJECT_ROOT/bin/grr" status "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"repo-alpha"* ]]
}

@test "full flow: version output after build" {
    run "$PROJECT_ROOT/bin/grr" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version:"* ]]
}

@test "full flow: help output" {
    run "$PROJECT_ROOT/bin/grr" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"GRR"* ]]
    [[ "$output" == *"pull"* ]]
    [[ "$output" == *"status"* ]]
}

@test "full flow: dry-run pull" {
    run bash "$PROJECT_ROOT/src/main.sh" pull -d --fetch "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY-RUN"* ]]
    [[ "$output" == *"repo-alpha"* ]]
}

@test "full flow: pull with local repo" {
    run bash "$PROJECT_ROOT/src/main.sh" pull "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"repo-alpha"* ]]
}

@test "full flow: parallel pull with local repositories" {
    mkdir -p "$TEST_DIR/repo-beta"
    cd "$TEST_DIR/repo-beta"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "beta" > file.txt
    git add .
    git commit -q -m "initial commit"
    cd "$PROJECT_ROOT"

    run bash "$PROJECT_ROOT/src/main.sh" pull --parallel 2 "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"repo-alpha"* ]]
    [[ "$output" == *"repo-beta"* ]]
}

@test "full flow: status with local repo" {
    run bash "$PROJECT_ROOT/src/main.sh" status "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"repo-alpha"* ]]
    [[ "$output" == *"clean"* ]]
}

@test "full flow: file logging" {
    local tmplog
    tmplog=$(mktemp)
    run bash "$PROJECT_ROOT/src/main.sh" --log "$tmplog" pull "$TEST_DIR"
    [ "$status" -eq 0 ]
    grep -q "repo-alpha" "$tmplog"
    rm -f "$tmplog"
}

@test "full flow: verbose mode" {
    run bash "$PROJECT_ROOT/src/main.sh" -V pull "$TEST_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Configuration"* ]]
}
