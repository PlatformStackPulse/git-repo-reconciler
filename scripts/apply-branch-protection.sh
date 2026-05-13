#!/usr/bin/env bash
# scripts/apply-branch-protection.sh — Apply branch protection via GitHub REST API
#
# Requirements:
#   - curl, jq
#   - GITHUB_TOKEN env var with repo admin permissions
# Optional:
#   - GITHUB_OWNER (default: PlatformStackPulse)
#   - GITHUB_REPO (default: bash-template)
#   - BRANCH (default: main)

set -euo pipefail

if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required"
    exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "GITHUB_TOKEN is required"
    echo "Example: export GITHUB_TOKEN=ghp_xxx"
    exit 1
fi

GITHUB_OWNER="${GITHUB_OWNER:-PlatformStackPulse}"
GITHUB_REPO="${GITHUB_REPO:-bash-template}"
BRANCH="${BRANCH:-main}"

API_URL="https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/branches/${BRANCH}/protection"

echo "Applying branch protection to ${GITHUB_OWNER}/${GITHUB_REPO}:${BRANCH}"

PAYLOAD='{
  "required_status_checks": {
    "strict": true,
    "contexts": [
      "CI Pipeline / ShellCheck Lint",
      "CI Pipeline / Format Check",
      "CI Pipeline / Test (ubuntu-latest)",
      "CI Pipeline / Test (macos-latest)",
      "CI Pipeline / Security Scans",
      "CI Pipeline / Commit Lint",
      "CI Pipeline / Build"
    ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}'

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$PAYLOAD" \
    "$API_URL")

if [[ "$HTTP_CODE" == "200" ]]; then
    echo "Branch protection applied successfully"
else
    echo "Failed to apply branch protection (HTTP $HTTP_CODE)"
    exit 1
fi
