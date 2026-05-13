#!/usr/bin/env bats
# test/unit/discovery_test.bats — Tests for lib/discovery.sh

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export NO_COLOR=1
    export VERBOSE="false"
    export LOG_FILE=""

    unset _DISCOVERY_SH_LOADED _LOGGING_SH_LOADED _ERRORS_SH_LOADED
    source "$PROJECT_ROOT/lib/logging.sh"
    source "$PROJECT_ROOT/lib/errors.sh"
    source "$PROJECT_ROOT/lib/discovery.sh"

    # Create temp directory with fake git repos
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/repo-a/.git"
    mkdir -p "$TEST_DIR/repo-b/.git"
    mkdir -p "$TEST_DIR/not-a-repo"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "discover_repos finds git repositories" {
    local repos=()
    discover_repos "$TEST_DIR" repos
    [ "${#repos[@]}" -eq 2 ]
}

@test "discover_repos returns empty for no repos" {
    local empty_dir
    empty_dir=$(mktemp -d)
    local repos=()
    discover_repos "$empty_dir" repos
    [ "${#repos[@]}" -eq 0 ]
    rm -rf "$empty_dir"
}

@test "should_skip_repo matches pattern" {
    run should_skip_repo "/path/to/test-repo" "*test*"
    [ "$status" -eq 0 ]
}

@test "should_skip_repo does not match non-matching pattern" {
    run should_skip_repo "/path/to/myrepo" "*test*"
    [ "$status" -eq 1 ]
}

@test "validate_target_dir fails for missing directory" {
    run validate_target_dir "/nonexistent/path"
    [ "$status" -eq 1 ]
    [[ "$output" == *"does not exist"* ]]
}

@test "validate_target_dir succeeds for existing directory" {
    run validate_target_dir "$TEST_DIR"
    [ "$status" -eq 0 ]
}
