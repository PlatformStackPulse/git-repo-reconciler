#!/usr/bin/env bats
# test/unit/utils_test.bats — Tests for lib/utils.sh

setup() {
    PROJECT_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    unset _UTILS_SH_LOADED
    source "$PROJECT_ROOT/lib/utils.sh"
}

@test "require_command succeeds for existing command" {
    run require_command "bash"
    [ "$status" -eq 0 ]
}

@test "require_command fails for missing command" {
    run require_command "nonexistent_command_xyz"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not installed"* ]]
}

@test "require_command shows install hint" {
    run require_command "nonexistent_xyz" "apt install nonexistent_xyz"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Install with"* ]]
}

@test "require_bash_version succeeds for current version" {
    run require_bash_version 3
    [ "$status" -eq 0 ]
}

@test "require_bash_version fails for future version" {
    run require_bash_version 99
    [ "$status" -eq 1 ]
    [[ "$output" == *"required"* ]]
}

@test "validate_not_empty succeeds for non-empty" {
    run validate_not_empty "name" "value"
    [ "$status" -eq 0 ]
}

@test "validate_not_empty fails for empty" {
    run validate_not_empty "name" ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}

@test "validate_positive_int succeeds for valid int" {
    run validate_positive_int "count" "42"
    [ "$status" -eq 0 ]
}

@test "validate_positive_int fails for zero" {
    run validate_positive_int "count" "0"
    [ "$status" -eq 1 ]
}

@test "validate_positive_int fails for non-numeric" {
    run validate_positive_int "count" "abc"
    [ "$status" -eq 1 ]
    [[ "$output" == *"positive integer"* ]]
}

@test "validate_file_readable fails for missing file" {
    run validate_file_readable "/nonexistent/path/file.txt"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "validate_dir_writable fails for missing directory" {
    run validate_dir_writable "/nonexistent/path"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "print_separator outputs a line" {
    run print_separator "=" 40
    [ "$status" -eq 0 ]
    [ "${#output}" -eq 40 ]
}
