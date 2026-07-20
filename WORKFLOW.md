# Repository Branch Protection & Workflow Guide

## GitHub Actions Status Checks

Configure the following status checks on your main branch:

### Required Status Checks

1. **CI Pipeline Checks:**
   - `CI Pipeline / ShellCheck Lint`
   - `CI Pipeline / Format Check`
   - `CI Pipeline / Test (ubuntu-latest)`
   - `CI Pipeline / Test (macos-latest)`
   - `CI Pipeline / Security Scans`
   - `CI Pipeline / Commit Lint`
   - `CI Pipeline / Build`

2. **Code scanning check:**
   - `CodeQL Analysis / Analyze`

## Branch Protection Rules

### For `main` branch:

```yaml
# Require pull request reviews before merging
Require reviews: 1

# Dismiss stale pull request approvals
Dismiss stale PR approvals: true

# Require status checks to pass before merging
Require status checks:
  - CI Pipeline / ShellCheck Lint
  - CI Pipeline / Format Check
  - CI Pipeline / Test (ubuntu-latest)
  - CI Pipeline / Test (macos-latest)
  - CI Pipeline / Security Scans
  - CI Pipeline / Commit Lint
  - CI Pipeline / Build
  - CodeQL Analysis / Analyze

# Require branches to be up to date before merging
Require branches up to date: true

# Include administrators
Include administrators: true

# Allow force pushes
Allow force pushes: false

# Allow deletions
Allow deletions: false
```

### For other branches:

- Allow direct commits to `develop` for minor updates
- Require PRs for feature branches

## Setup Instructions

1. **Go to Repository Settings** → **Branches**
2. **Click "Add rule"**
3. **Configure for `main` branch:**
   - Apply to administrators: ✅
   - Require pull request reviews: 1 review ✅
   - Dismiss stale reviews: ✅
   - Require status checks: all checks listed above ✅
   - Require branches up to date: ✅

## Quick Apply via API (Script)

Apply the `main` branch protection policy in one command:

1. Export token with admin access:
```bash
export GITHUB_TOKEN=ghp_xxx
```

2. Run script:
```bash
chmod +x scripts/apply-branch-protection.sh
scripts/apply-branch-protection.sh
```

Optional overrides:
```bash
GITHUB_OWNER=PlatformStackPulse GITHUB_REPO=git-repo-reconciler BRANCH=main scripts/apply-branch-protection.sh
```

## Quick Apply Checklist (GitHub UI)

Required status checks for branch protection on `main`:

1. CI Pipeline / ShellCheck Lint
2. CI Pipeline / Format Check
3. CI Pipeline / Test (ubuntu-latest)
4. CI Pipeline / Test (macos-latest)
5. CI Pipeline / Security Scans
6. CI Pipeline / Commit Lint
7. CI Pipeline / Build
8. CodeQL Analysis / Analyze

Recommended additional protection toggles:

1. Require a pull request before merging
2. Require approvals: 1
3. Dismiss stale pull request approvals when new commits are pushed
4. Require conversation resolution before merging
5. Require branches to be up to date before merging
6. Include administrators
7. Block force pushes
8. Block branch deletion

## Automatic Remediation Workflows

### 1. Check Tool Versions
- **Trigger:** Weekly
- **Action:** Verify ShellCheck and BATS versions; fail on ShellCheck warnings
- **Config:** `.github/workflows/dependencies.yml`

### 2. Auto-Fix Formatting
- **Trigger:** PR submission
- **Action:** Suggest formatting fixes (not auto-commit)
- **Config:** CI Pipeline

### 3. Version Bumping
- **Trigger:** Manual (workflow_dispatch)
- **Action:** Create an annotated semantic-version tag and dispatch the Release workflow for that exact tag
- **Config:** `.github/workflows/version-bump.yml`

## Recommended Workflow

```
main (protected)
└── develop (semi-protected)
    ├── feature/* (unprotected)
    ├── bugfix/* (unprotected)
    └── hotfix/* (unprotected)

PR Flow:
1. feature/* → PR → develop
2. develop → PR → main (requires approval + checks)
3. hotfix/* → PR → main (direct to main for urgent fixes)
```

## Deployment Considerations

### Pre-Deployment Checklist

- [ ] All tests pass (`make test`)
- [ ] ShellCheck clean (`make lint`)
- [ ] Formatting correct (`make fmt-check`)
- [ ] GitHub Actions syntax clean (`make workflow-lint`)
- [ ] Full local quality gate passes (`make check`)
- [ ] Coverage maintained
- [ ] Commits follow Conventional Commits
- [ ] PR has approval
- [ ] Branch is up to date with main

### Release Process

1. Create PR to main
2. Await reviews and checks
3. Merge to main
4. Run the **Update Version** workflow for the required semantic version bump
5. The workflow creates and pushes an annotated tag, then dispatches Release for that exact tag
6. Release workflow creates the GitHub Release + Docker image
