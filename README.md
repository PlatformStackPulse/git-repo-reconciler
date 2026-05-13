# Bash Template

![Bash Version](https://img.shields.io/badge/Bash-4.0+-blue?style=flat-square&logo=gnubash)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)
![CI Status](https://github.com/PlatformStackPulse/bash-template/actions/workflows/ci.yml/badge.svg)
![ShellCheck](https://img.shields.io/badge/ShellCheck-Passing-green?style=flat-square)
![DevContainer](https://img.shields.io/static/v1?label=DevContainer&message=Ready&color=blue&style=flat-square&logo=visual-studio-code)

<p align="center">
  <strong>Slim, Production-Ready Bash Template</strong><br>
  Enterprise CI/CD, DevSecOps, clean structure. Optimized for CLI tools and automation scripts.
</p>

---

## Overview

A **minimal, reusable GitHub template** for building production-ready Bash scripts and CLI tools. Supports both **single-script projects** and **multi-script toolkits** with zero bloat.

**What you get:**
- Clean project structure (lib/src/test separation)
- CLI foundation (argument parsing, help, version)
- Structured logging (colored, leveled, file logging)
- Configuration management (env vars, config files)
- Comprehensive testing (unit tests with BATS)
- DevSecOps (ShellCheck, static analysis)
- GitHub Actions CI/CD (linting, testing, releases)
- Docker support for portable execution
- DevContainer with pre-configured tools
- Conventional Commits & changelog automation

**What you don't get (keep it slim!):**
- No bloated framework dependencies
- No unused utility functions (add only if needed)
- No over-engineered abstractions
- No Python/Ruby/Node.js wrappers

---

## Quick Start

### Using as GitHub Template

```bash
# Create a new repo from this template
gh repo create my-tool --template PlatformStackPulse/bash-template

# Setup
cd my-tool
make dev-setup

# Build & run
make build
./bin/my-tool --help
./bin/my-tool hello --name "World"
```

### Example: Add Your First Command

The template includes an example command in `src/commands/hello.sh`. Replace it with your own:

**1. Create your command:**
```bash
# src/commands/mycommand.sh
#!/usr/bin/env bash
# Command: mycommand — What my command does

mycommand_usage() {
    cat << EOF
Usage: $(basename "$0") mycommand [OPTIONS]

What my command does in detail.

OPTIONS:
    -n, --name NAME    Name to use
    -h, --help         Show this help
EOF
}

mycommand_run() {
    local name="World"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name) name="$2"; shift 2 ;;
            -h|--help) mycommand_usage; return 0 ;;
            *) log_error "Unknown option: $1"; return 1 ;;
        esac
    done
    log_info "Running mycommand for $name"
}
```

**2. Register in main script:**
```bash
# In src/main.sh, add to the command dispatch:
mycommand) shift; source "$SRC_DIR/commands/mycommand.sh"; mycommand_run "$@" ;;
```

**3. Remove the example command:**
```bash
rm src/commands/hello.sh
# Update src/main.sh — remove the hello command case
```

---

## Lean Project Structure

```
bash-template/
├── src/                        # Source scripts
│   ├── main.sh                 # Entry point & command dispatcher (~50 lines)
│   └── commands/               # Subcommand scripts
│       └── hello.sh            # Example command (remove/rename)
├── lib/                        # Shared libraries
│   ├── logging.sh              # Structured logging (colored, leveled)
│   ├── config.sh               # Configuration loading (env + file)
│   ├── errors.sh               # Error codes & handling
│   ├── utils.sh                # Common utilities (validation, etc.)
│   └── version.sh              # Version info (injected at build)
├── test/
│   ├── unit/                   # Unit tests (BATS)
│   │   ├── logging_test.bats
│   │   ├── config_test.bats
│   │   ├── errors_test.bats
│   │   └── commands_test.bats
│   ├── integration/            # Integration tests
│   │   └── flow_test.bats
│   └── test_helper.bash        # Shared test utilities
├── Makefile                    # Core build targets
├── Dockerfile                  # Container build
├── docker-compose.yml          # Local dev environment
├── .github/workflows/          # GitHub Actions (6 workflows)
├── scripts/                    # Setup & utility scripts
└── README.md
```

---

## Two Modes: Single Script vs Toolkit

### Mode 1: Single Script

For simple single-purpose tools, your main.sh stays slim:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/config.sh"

config_load
log_info "Starting my-tool"
# Your logic here
```

### Mode 2: Multi-Command Toolkit

For tools with subcommands (like git, docker):

```bash
case "${1:-}" in
    hello)    shift; source "$SRC_DIR/commands/hello.sh"; hello_run "$@" ;;
    deploy)   shift; source "$SRC_DIR/commands/deploy.sh"; deploy_run "$@" ;;
    *)        main_usage; exit 1 ;;
esac
```

---

## Features

### Structured Logging

```bash
source lib/logging.sh

log_info "Starting process"       # [INFO] Starting process
log_success "Task completed"      # [✓] Task completed
log_warning "Check this"          # [!] Check this
log_error "Something broke"       # [✗] Something broke
log_debug "Verbose detail"        # [DEBUG] Verbose detail (only with -V)
```

Supports file logging with `--log FILE` and colored/plain output.

### Configuration Management

```bash
source lib/config.sh

# Load from environment variables with defaults
config_load
echo "$APP_NAME"    # from APP_NAME env or default
echo "$DEBUG"       # from DEBUG env or default "false"
```

### Error Handling

```bash
source lib/errors.sh

# Predefined error codes
exit $ERR_INVALID_INPUT     # 10
exit $ERR_NOT_FOUND         # 11
exit $ERR_PERMISSION        # 12
exit $ERR_TIMEOUT           # 13
exit $ERR_CONFIGURATION     # 14
exit $ERR_DEPENDENCY        # 15
```

### Testing with BATS

```bash
# test/unit/logging_test.bats
@test "log_info outputs INFO prefix" {
    source lib/logging.sh
    run log_info "test message"
    [[ "$output" == *"[INFO]"* ]]
}
```

---

## Makefile Targets

```bash
make help          # Show all targets
make build         # Build the application (bundle into bin/)
make run           # Build and run
make test          # Run all tests (BATS)
make test-unit     # Run unit tests only
make lint          # Run ShellCheck linter
make fmt           # Format with shfmt
make security      # Run security checks
make coverage      # Generate test coverage
make clean         # Clean build artifacts
make install       # Check runtime dependencies
make dev-setup     # Full development environment setup
make changelog     # Regenerate CHANGELOG.md
make version       # Show version
make all           # Run all targets
```

---

## CI/CD Pipeline

6 GitHub Actions workflows (matching go-template conventions):

1. **CI Pipeline** (`ci.yml`) — Lint, test, security, build on every PR
2. **Changelog** (`changelog.yml`) — Auto-update CHANGELOG.md on main
3. **CodeQL** (`codeql.yml`) — Weekly security analysis
4. **Dependencies** (`dependencies.yml`) — Weekly dependency checks
5. **Release** (`release.yml`) — Multi-platform packaging on tags
6. **Version Bump** (`version-bump.yml`) — Manual version bumping

---

## Security & DevSecOps

- **ShellCheck** — Static analysis for shell scripts
- **shfmt** — Consistent formatting
- **CodeQL** — SAST (Static Application Security Testing)
- **Dependabot** — Automated dependency alerts

```bash
make lint       # Run ShellCheck
make fmt        # Format with shfmt
make security   # Run security checks
```

---

## Docker

```bash
# Build image
docker build -t my-tool .

# Run
docker run --rm my-tool hello --name "Docker"

# Development with docker-compose
docker-compose run dev
docker-compose run test
docker-compose run lint
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow, commit conventions, and testing guidelines.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting and security scanning.

## License

[MIT License](LICENSE) — Copyright (c) 2026 PE Stack Pulse
