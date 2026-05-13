#!/usr/bin/env bash
# scripts/update-changelog.sh — Regenerate CHANGELOG.md from Conventional Commits

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

if ! command -v git-chglog >/dev/null 2>&1; then
    echo "git-chglog is not installed."
    echo "Install with: go install github.com/git-chglog/git-chglog/cmd/git-chglog@latest"
    exit 1
fi

if git tag --list | grep -q .; then
    git-chglog --config .chglog/config.yml --template .chglog/CHANGELOG.tpl.md --output CHANGELOG.md
else
    git-chglog --config .chglog/config.yml --template .chglog/CHANGELOG.tpl.md --next-tag v0.1.0 --output CHANGELOG.md
fi

echo "CHANGELOG.md updated"
