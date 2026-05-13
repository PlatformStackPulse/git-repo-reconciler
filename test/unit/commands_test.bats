#!/usr/bin/env bats
# test/unit/commands_test.bats — Tests for GRR commands (pull, status)

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export NO_COLOR=1
    export VERBOSE="false"
    export LOG_FILE=""
}

@test "main.sh --help shows GRR usage" {
    run bash "$PROJECT_ROOT/src/main.sh" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"GRR"* ]]
    [[ "$output" == *"pull"* ]]
    [[ "$output" == *"status"* ]]
}

@test "main.sh --version shows version" {
    run bash "$PROJECT_ROOT/src/main.sh" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Version:"* ]]
}

@test "main.sh with no command shows usage" {
    run bash "$PROJECT_ROOT/src/main.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"COMMANDS"* ]]
}

@test "unknown command shows error" {
    run bash "$PROJECT_ROOT/src/main.sh" nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "pull --help shows pull usage" {
    run bash "$PROJECT_ROOT/src/main.sh" pull --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--fetch"* ]]
    [[ "$output" == *"--stash"* ]]
    [[ "$output" == *"--parallel"* ]]
}

@test "status --help shows status usage" {
    run bash "$PROJECT_ROOT/src/main.sh" status --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"--skip"* ]]
}

@test "pull on empty directory shows warning" {
    local empty_dir
    empty_dir=$(mktemp -d)
    run bash "$PROJECT_ROOT/src/main.sh" pull "$empty_dir"
    [[ "$output" == *"No git repositories"* ]]
    rm -rf "$empty_dir"
}

@test "status on empty directory shows warning" {
    local empty_dir
    empty_dir=$(mktemp -d)
    run bash "$PROJECT_ROOT/src/main.sh" status "$empty_dir"
    [[ "$output" == *"No git repositories"* ]]
    rm -rf "$empty_dir"
}

@test "pull on nonexistent directory shows error" {
    run bash "$PROJECT_ROOT/src/main.sh" pull /nonexistent/path
    [ "$status" -ne 0 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "pull --dry-run previews operations" {
    # Create a temp repo
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/myrepo"
    cd "$test_dir/myrepo"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "x" > f.txt && git add . && git commit -q -m "init"
    cd -

    run bash "$PROJECT_ROOT/src/main.sh" pull -d --fetch "$test_dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY-RUN"* ]]
    [[ "$output" == *"myrepo"* ]]
    rm -rf "$test_dir"
}

@test "status shows repo table" {
    local test_dir
    test_dir=$(mktemp -d)
    mkdir -p "$test_dir/myrepo"
    cd "$test_dir/myrepo"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "x" > f.txt && git add . && git commit -q -m "init"
    cd -

    run bash "$PROJECT_ROOT/src/main.sh" status "$test_dir"
    [ "$status" -eq 0 ]
    [[ "$output" == *"REPOSITORY"* ]]
    [[ "$output" == *"myrepo"* ]]
    [[ "$output" == *"clean"* ]]
    rm -rf "$test_dir"
}
