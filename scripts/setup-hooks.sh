#!/usr/bin/env bash
# scripts/setup-hooks.sh — Install git hooks (pre-commit + commit-msg)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_HOOKS_DIR="$(git rev-parse --git-dir 2>/dev/null)/hooks"

if [[ ! -d "$GIT_HOOKS_DIR" ]]; then
    echo "Not a git repository. Skipping hook setup."
    exit 0
fi

# Install pre-commit hook (ShellCheck on staged files)
PRECOMMIT_SRC="$SCRIPT_DIR/pre-commit"
if [[ -f "$PRECOMMIT_SRC" ]]; then
    cp "$PRECOMMIT_SRC" "$GIT_HOOKS_DIR/pre-commit"
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    echo "Pre-commit hook installed"
else
    echo "Warning: pre-commit hook source not found at $PRECOMMIT_SRC"
fi

# Install commit-msg hook (Conventional Commits validation)
COMMITMSG_SRC="$SCRIPT_DIR/commit-msg"
if [[ -f "$COMMITMSG_SRC" ]]; then
    cp "$COMMITMSG_SRC" "$GIT_HOOKS_DIR/commit-msg"
    chmod +x "$GIT_HOOKS_DIR/commit-msg"
    echo "Commit-msg hook installed"
else
    echo "Warning: commit-msg hook source not found at $COMMITMSG_SRC"
fi
