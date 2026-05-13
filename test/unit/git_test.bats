#!/usr/bin/env bats
# test/unit/git_test.bats — Tests for lib/git.sh

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export NO_COLOR=1
    export VERBOSE="false"
    export LOG_FILE=""
    export TIMEOUT=10

    # Create a temp git repo for testing
    TEST_REPO=$(mktemp -d)
    cd "$TEST_REPO"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "init" > file.txt
    git add .
    git commit -q -m "initial"

    unset _GIT_SH_LOADED _LOGGING_SH_LOADED
    source "$PROJECT_ROOT/lib/logging.sh"
    source "$PROJECT_ROOT/lib/git.sh"
}

teardown() {
    rm -rf "$TEST_REPO"
}

@test "git_current_branch returns branch name" {
    cd "$TEST_REPO"
    run git_current_branch
    [ "$status" -eq 0 ]
    # Could be master or main depending on git config
    [[ "$output" == "master" || "$output" == "main" ]]
}

@test "git_check_dirty returns 0 for clean repo" {
    cd "$TEST_REPO"
    run git_check_dirty
    [ "$status" -eq 0 ]
}

@test "git_check_dirty returns 1 for dirty repo" {
    cd "$TEST_REPO"
    echo "change" >> file.txt
    run git_check_dirty
    [ "$status" -eq 1 ]
    [[ "$output" == *"file.txt"* ]]
}

@test "git_remote_url returns unknown for no remote" {
    cd "$TEST_REPO"
    run git_remote_url
    [ "$output" = "unknown" ]
}

@test "git_is_shallow returns false for normal repo" {
    cd "$TEST_REPO"
    run git_is_shallow
    [ "$status" -eq 1 ]  # not shallow
}

@test "git_show_recent_commits shows commits" {
    cd "$TEST_REPO"
    run git_show_recent_commits 1
    [ "$status" -eq 0 ]
    [[ "$output" == *"initial"* ]]
}

@test "git_stash_changes does not fail on clean repo" {
    cd "$TEST_REPO"
    run git_stash_changes
    [ "$status" -eq 0 ]
}

@test "git_clean_untracked removes untracked files" {
    cd "$TEST_REPO"
    echo "junk" > untracked.txt
    run git_clean_untracked
    [ "$status" -eq 0 ]
    [ ! -f "$TEST_REPO/untracked.txt" ]
}

@test "git_garbage_collect does not fail" {
    cd "$TEST_REPO"
    run git_garbage_collect
    [ "$status" -eq 0 ]
}
