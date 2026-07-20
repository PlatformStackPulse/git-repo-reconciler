# GRR — Architecture & Design Guide

An overview of the design patterns, project structure, and conventions used in Git Repo Reconciler.

## Project Stats

- **Shell Files**: 11 (7 lib + 3 src commands + 1 entry point)
- **Test Files**: 10 (8 unit + 1 integration + 1 helper)
- **Test Framework**: BATS (Bash Automated Testing System)
- **Workflows**: 6 GitHub Actions workflows
- **Dependencies**: ShellCheck, shfmt, BATS (dev only)

## Project Structure

```
git-repo-reconciler/
├── src/
│   ├── main.sh                     # Entry point & command dispatcher
│   └── commands/
│       ├── clone.sh                # Batch-clone repositories from GitHub
│       ├── pull.sh                 # Bulk-pull reconciliation command
│       └── status.sh               # Repository status overview command
├── lib/
│   ├── logging.sh                  # Structured logging (colored, leveled)
│   ├── config.sh                   # Config loading (env vars + defaults)
│   ├── errors.sh                   # Error codes & handling
│   ├── utils.sh                    # Common utilities (validation, etc.)
│   ├── version.sh                  # Version info (injected at build)
│   ├── git.sh                      # Atomic git operations (fetch, pull, reset, etc.)
│   └── discovery.sh                # Repo discovery & skip patterns
├── test/
│   ├── unit/
│   │   ├── clone_test.bats
│   │   ├── commands_test.bats
│   │   ├── config_test.bats
│   │   ├── discovery_test.bats
│   │   ├── errors_test.bats
│   │   ├── git_test.bats
│   │   ├── logging_test.bats
│   │   └── utils_test.bats
│   ├── integration/
│   │   └── flow_test.bats
│   └── test_helper.bash
├── scripts/
│   ├── build.sh                    # Bundle into single portable script
│   ├── setup-hooks.sh              # Install git hooks
│   ├── pre-commit                  # Conventional commit + lint hook
│   ├── update-changelog.sh         # Changelog generation
│   └── apply-branch-protection.sh  # GitHub branch protection
├── .github/
│   ├── workflows/                  # 6 CI/CD workflows
│   ├── actions/                    # Composite actions
│   ├── ISSUE_TEMPLATE/             # Bug report & feature request
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── .chglog/                        # Changelog config
├── .devcontainer/                  # VS Code DevContainer
├── Makefile                        # Build automation (20+ targets)
├── Dockerfile                      # Container build
├── docker-compose.yml              # Local dev environment
├── .editorconfig                   # Editor settings
├── .gitconfig                      # Git settings
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── LICENSE                         # MIT
└── README.md
```

## Design Philosophy

**What's Included:**

- Clean project structure (lib/src/test separation)
- CLI framework (argument parsing, help, version, subcommands)
- Structured logging (colored, leveled, file logging)
- Configuration management (environment variables + defaults)
- Portable timeout wrapper (works on both Linux and macOS)
- Bash 3.2+ compatibility (no namerefs or Bash 4-only features)
- Comprehensive testing with BATS (72 tests)
- Enterprise CI/CD (GitHub Actions — Ubuntu + macOS)
- Docker support
- Static analysis (ShellCheck, shfmt)
- Git hooks & branch protection
- Conventional Commits & changelog

**What's NOT Included (Keep it Slim!):**

- No Python/Ruby/Node.js dependencies
- No bloated framework abstractions
- No unused utility functions

## Key Design Patterns

### 1. Library Pattern (Source, Don't Execute)

Libraries in `lib/` are **sourced**, not executed:

```bash
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/config.sh"
source "$LIB_DIR/git.sh"
source "$LIB_DIR/discovery.sh"
```

Each library has a **double-source guard**:

```bash
[[ -n "${_LOGGING_SH_LOADED:-}" ]] && return 0
readonly _LOGGING_SH_LOADED=1
```

### 2. Subcommand Pattern

Commands live in `src/commands/` and are dispatched from `main.sh`:

```bash
case "$command" in
    clone)  shift; source "$SRC_DIR/commands/clone.sh"; clone_run "$@" ;;
    pull)   shift; source "$SRC_DIR/commands/pull.sh"; pull_run "$@" ;;
    status) shift; source "$SRC_DIR/commands/status.sh"; status_run "$@" ;;
esac
```

### 3. Safe Bash Patterns

Following `set -euo pipefail` best practices:

- `if [[ test ]]; then action; fi` (not `[[ test ]] && action`)
- `var=$(( var + 1 ))` (not `((var++))`)
- `pushd/popd` (not `cd/cd -`)
- `find -print0` with `read -r -d ''`
- All variables quoted: `"$var"`
- Portable timeout wrapper (`_git_timeout`) for macOS compatibility
- `eval`-based array passing instead of `local -n` namerefs (Bash 3.2 compat)

### 4. Build System

`scripts/build.sh` bundles all libraries and commands into a single portable script:

```bash
make build
# Creates: bin/grr (self-contained, no dependencies)
```

### 5. Testing with BATS

```bash
make test              # All tests (72 tests)
make test-unit         # Unit tests only
make test-integration  # Integration tests
```
