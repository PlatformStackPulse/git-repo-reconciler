# GRR — Git Repo Reconciler

![Bash Version](https://img.shields.io/badge/Bash-3.2+-blue?style=flat-square&logo=gnubash)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)
![CI Status](https://github.com/PlatformStackPulse/git-repo-reconciler/actions/workflows/ci.yml/badge.svg)
![ShellCheck](https://img.shields.io/badge/ShellCheck-Passing-green?style=flat-square)

<p align="center">
  <strong>Bulk-update, inspect, and reconcile git repositories at scale.</strong><br>
  Fast parallel pulls, status checks, and safe git operations across directory trees.
</p>

---

## Overview

**GRR** is a CLI tool that finds all git repositories under a directory and reconciles them — fetching, pulling, stashing, resetting, and cleaning — in a single command. Built for developers and platform engineers managing many repos locally.

**Features:**
- Batch-clone all repositories from a GitHub User or Organization
- Discover and pull all git repos in a directory tree
- Parallel execution for speed (`-p N`)
- Safe pipeline: fetch → status-check → stash → checkout → reset → clean → pull
- Dry-run mode to preview changes
- Shallow clone handling, submodule updates, garbage collection
- Status overview across all repos (branch, dirty state, ahead/behind)
- Structured logging (colored, leveled, file output)
- Skip patterns to exclude repos
- Configurable branch priority and timeouts
- Strict mode (fail-fast) or continue-on-error (default)

---

## Quick Start

```bash
# Clone
git clone https://github.com/PlatformStackPulse/git-repo-reconciler.git
cd git-repo-reconciler

# Setup dev tools
make dev-setup

# Build
make build

# Run
./bin/grr pull --fetch --check-status ~/projects
./bin/grr status ~/projects
```

## Installation

Build and install `grr` so it's available system-wide from any terminal:

```bash
# Build the binary
make build

# Copy to ~/.local/bin (create it if it doesn't exist)
mkdir -p ~/.local/bin
cp bin/grr ~/.local/bin/grr
chmod +x ~/.local/bin/grr
```

If `~/.local/bin` is not already in your `PATH`, add it to your shell profile:

```bash
# For zsh (~/.zshrc)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# For bash (~/.bashrc)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify the installation:

```bash
grr --version
```

---

## Commands

### \`grr clone\` — Batch clone repositories

\`\`\`bash
# Clone all repositories from an account (User or Org)
grr clone PlatformStackPulse ./my-repos

# Fast parallel clone with 4 jobs
grr clone PlatformStackPulse -p 4

# Preview what would be cloned
grr clone PlatformStackPulse --dry-run
\`\`\`

### \`grr pull\` — Reconcile repositories

```bash
# Recommended: safe pull with full features
grr pull --fetch --check-status --stash -V /repos

# Fast parallel pull with logging
grr pull --fetch -p 4 --log pull.log /repos

# Preview before running
grr pull -d --fetch /repos

# With custom branches and skip patterns
grr pull --fetch -b "main,develop" -s "*test*" /repos

# Full pipeline
grr pull --fetch --stash --submodules --verify --gc /repos
```

**Pipeline steps (in order):**
1. `--fetch` — Fetch all remotes with pruning and tags
2. `--check-status` — Warn about uncommitted changes
3. `--handle-shallow` — Convert shallow clones to full repos
4. `--stash` — Stash uncommitted changes before pulling
5. Checkout branch (tries `master`, `main`, `develop` or custom `-b`)
6. Hard reset to `origin/<branch>`
7. Clean untracked files
8. `--submodules` — Update submodules recursively
9. Pull with rebase
10. `--verify` — Show recent commits
11. `--gc` — Run garbage collection

### `grr status` — Inspect repositories

```bash
# Show status of all repos
grr status /repos

# Skip certain repos
grr status -s "*vendor*" /repos
```

Outputs a table with repository name, branch, state (clean/dirty), and remote URL.

---

## Options

### Global Options

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help |
| `-v, --version` | Show version |
| `-V, --verbose` | Enable debug output |
| `--log FILE` | Log to file |

### Pull Options

| Flag | Description |
|------|-------------|
| `-d, --dry-run` | Preview without changes |
| `-p, --parallel N` | Run N parallel jobs (default: 1) |
| `-b, --branches B1,B2` | Branches to try (default: master,main,develop) |
| `-s, --skip PATTERN` | Skip repos matching pattern (repeatable) |
| `-t, --timeout SECS` | Git operation timeout (default: 300) |
| `--fetch` | Fetch remotes first |
| `--stash` | Stash changes before pulling |
| `--check-status` | Warn about uncommitted changes |
| `--submodules` | Update submodules recursively |
| `--verify` | Show recent commits after pull |
| `--handle-shallow` | Convert shallow clones |
| `--gc` | Garbage collect after pull |
| `--strict` | Fail on first error |
| `--max-log N` | Commits to show with --verify (default: 3) |

---

## Documentation

For more detailed information, see the following documentation:

- [CHANGELOG.md](CHANGELOG.md) — Project change history and release notes.
- [CONTRIBUTING.md](CONTRIBUTING.md) — Guidelines for contributing, coding standards, and development workflow.
- [SECURITY.md](SECURITY.md) — Security policy, vulnerability reporting, and scanning procedures.
- [SKILL.md](SKILL.md) — AI-specific implementation patterns and project-specific skills.
- [TEMPLATE_GUIDE.md](TEMPLATE_GUIDE.md) — Deep dive into the architecture, design patterns, and project structure.
- [WORKFLOW.md](WORKFLOW.md) — Detailed CI/CD workflow and branch protection configuration.
- [GEMINI.md](GEMINI.md) — Foundational instructions and learned context for AI agents.

---

## Project Structure

```
git-repo-reconciler/
├── src/
│   ├── main.sh                  # Entry point & command dispatcher
│   └── commands/
│       ├── pull.sh              # Bulk-pull reconciliation command
│       └── status.sh            # Status overview command
├── lib/
│   ├── git.sh                   # Atomic git operations
│   ├── discovery.sh             # Repo discovery & skip patterns
│   ├── logging.sh               # Structured logging (colored, leveled)
│   ├── config.sh                # Configuration (env vars + defaults)
│   ├── errors.sh                # Error codes & handling
│   ├── utils.sh                 # Validation utilities
│   └── version.sh               # Version info (injected at build)
├── test/
│   ├── unit/                    # Unit tests (BATS)
│   └── integration/             # Integration tests
├── Makefile                     # Build targets
├── Dockerfile                   # Container build
└── .github/workflows/           # CI/CD
```

---

## Makefile Targets

```bash
make help          # Show all targets
make build         # Build portable binary into bin/grr
make run           # Build and show help
make test          # Run all tests
make lint          # Run ShellCheck
make fmt           # Format with shfmt
make security      # Security checks
make workflow-lint # Lint GitHub Actions workflows
make check         # Run the complete non-destructive quality gate
make clean         # Clean build artifacts
make dev-setup     # Install dev tools + git hooks
```

---

## Releasing New Versions

Releases are automated via GitHub Actions. To publish a new version:

1.  **Bump Version:** Go to the **Actions** tab in GitHub and select the **Update Version** workflow.
2.  **Run Workflow:** Click **Run workflow**, choose the version bump type (patch, minor, or major), and run it on the `main` branch.
3.  **Automated Release:** This creates an annotated git tag and explicitly dispatches the **Release** workflow, which will:
    *   Build the single portable binary.
    *   Generate a GitHub Release with the binary attached as an artifact.
    *   Publish a new Docker image to GitHub Container Registry (GHCR).

---

## Docker

```bash
docker build -t grr .
docker run --rm -v /your/repos:/repos grr pull --fetch /repos
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for workflow, commit conventions, and testing guidelines.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting and security scanning.

## License

[MIT License](LICENSE)
