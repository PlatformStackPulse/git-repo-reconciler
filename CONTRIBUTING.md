# Contributing to Bash Template

Thank you for your interest in contributing! This project follows a set of guidelines to ensure code quality and consistency.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork:**
   ```bash
   git clone https://github.com/PlatformStackPulse/bash-template.git
   cd bash-template
   ```

3. **Setup development environment:**
   ```bash
   make dev-setup
   ```

4. **Create a feature branch:**
   ```bash
   git checkout -b feature/my-awesome-feature
   ```

## Development Workflow

### Before You Start

- Review existing issues and PRs to avoid duplicates
- Open an issue first for significant changes
- Discuss your approach with maintainers

### Making Changes

1. **Ensure tests pass:**
   ```bash
   make test
   ```

2. **Follow code style:**
   ```bash
   make fmt lint
   ```

3. **Run security checks:**
   ```bash
   make security
   ```

4. **Commit with conventional format:**
   ```bash
   git commit -m "feat: add new feature"
   git commit -m "fix: resolve issue"
   ```

### Conventional Commits

All commits must follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

**Format:**
```
<type>(<scope>): <description>

<optional body>

<optional footer>
```

**Types:**
- `feat` — A new feature
- `fix` — A bug fix
- `docs` — Documentation only changes
- `style` — Changes that don't affect code meaning (formatting, etc.)
- `refactor` — Code change that neither fixes bugs nor adds features
- `perf` — Code change that improves performance
- `test` — Adding missing tests or correcting existing tests
- `chore` — Changes to build process, dependencies, etc.
- `ci` — Changes to CI configuration
- `build` — Changes to build system

**Examples:**
```
feat: add support for parallel processing
feat(cli): add deploy command
fix: resolve timeout handling
fix(logger): fix log rotation
docs: update README with examples
chore: upgrade ShellCheck to latest
```

## Testing

### Write Tests

- Add tests for new features
- Update tests for bug fixes
- Use BATS (Bash Automated Testing System)

```bash
# test/unit/myfeature_test.bats
@test "my feature works correctly" {
    source lib/myfeature.sh
    run my_function "input"
    [ "$status" -eq 0 ]
    [[ "$output" == *"expected"* ]]
}
```

### Run Tests Before Submitting

```bash
make test           # Run all tests
make test-unit      # Unit tests only
make test-integration # Integration tests only
make coverage       # Generate coverage report (requires kcov)
```

## Code Style

### Shell Scripts

- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use `shfmt` for formatting (4-space indent, case indent)
- Run `shellcheck` for linting

```bash
make fmt    # Auto-format
make lint   # Run linter
```

### Best Practices

- Use `set -euo pipefail` at the top of every script
- Quote all variables: `"$var"` not `$var`
- Use `[[ ]]` instead of `[ ]` for tests
- Use `$(command)` instead of backticks
- Use `if [[ test ]]; then action; fi` not `[[ test ]] && action` (avoids `set -e` pitfalls)
- Use `var=$(( var + 1 ))` not `((var++))` (post-increment returns 1 when var=0)
- Use `pushd/popd` instead of `cd/cd -`
- Use `find -print0` with `read -r -d ''` for safe file iteration

### File Organization

```
lib/                # Shared libraries (sourced, not executed)
├── logging.sh      # Structured logging
├── config.sh       # Configuration management
├── errors.sh       # Error codes and handling
├── utils.sh        # Common utilities
└── version.sh      # Version info

src/                # Executable scripts
├── main.sh         # Entry point & dispatcher
└── commands/       # Subcommand scripts
    └── hello.sh    # Example command

test/               # BATS tests
├── unit/           # Unit tests (mirrors lib/ and src/)
├── integration/    # End-to-end tests
└── test_helper.bash # Shared test utilities
```

### Testing Guidelines

**Unit Tests:**
```bash
@test "function handles edge case" {
    source lib/utils.sh
    run validate_not_empty "field" ""
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot be empty"* ]]
}
```

**Integration Tests:**
```bash
@test "full CLI flow works" {
    run bash src/main.sh hello --name "Test"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Hello, Test!"* ]]
}
```

## Pull Request Process

1. Create a feature branch from `develop` or `main`
2. Make your changes with tests
3. Run `make all` to verify everything passes
4. Push and create a PR
5. Wait for CI checks to pass
6. Request review from maintainers
7. Address feedback
8. Merge after approval

## Code of Conduct

Be respectful, constructive, and collaborative.
