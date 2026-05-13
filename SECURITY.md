# Security Policy

## Reporting Security Vulnerabilities

If you discover a security vulnerability, please use GitHub Security Advisories for this repository instead of opening a public issue.

Please include:

- Description of the vulnerability
- Steps to reproduce (if applicable)
- Potential impact
- Suggested fix (if any)

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest  | ✅ Yes    |
| N-1     | ✅ Yes    |
| Older   | ❌ No     |

## Security Scanning

This project uses the following security scanning tools:

- **ShellCheck** — Static analysis for shell scripts (detects unsafe patterns)
- **CodeQL** — SAST (Static Application Security Testing) and vulnerability detection

### Running Locally

```bash
# ShellCheck lint (includes security warnings)
make lint

# Security-level ShellCheck scan
make security

# Syntax check
make vet

# All security + dev setup
make dev-setup     # Installs all tools
make security      # Run security scan
```

### CI/CD Integration

Security scans run automatically on:
- Every pull request
- Before merge to main
- Weekly scheduled scan
- On push to main

## Common Shell Script Vulnerabilities

This template is designed to prevent common shell script issues:

- **Command injection** — All variables are quoted
- **Path traversal** — Paths are validated before use
- **Uninitialized variables** — `set -u` catches these
- **Silent failures** — `set -e` and `set -o pipefail` catch these
- **Unsafe temporary files** — Use `mktemp` instead of predictable paths

## Disclosure Timeline

- Notify maintainers
- Wait for acknowledgment (within 48 hours)
- Provide reasonable time for fix (typically 30-90 days)
- Coordinated disclosure

## Compliance

- Follows responsible disclosure practices
- Reports processed with urgency
- Security patches released as soon as possible
