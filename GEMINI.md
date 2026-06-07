# Project Instructions: Git Repo Reconciler (GRR)

This file serves as the foundational guide for AI agents working on the GRR project, capturing the architectural patterns and standards established during development.

## 🏛️ Architecture & Learned Context

GRR is a high-performance, modular Bash CLI tool designed for large-scale git repository management.

- **Modular Design:** Learned that reusable logic must live in `lib/*.sh` (sourced with guards), while CLI entry points are in `src/commands/*.sh`.
- **Subcommand Dispatch:** The entry point `src/main.sh` uses a clean dispatch pattern to route commands, ensuring the tool remains extensible.
- **Single-Binary Build:** The project uses an inlining build process (`scripts/build.sh`) to produce a self-contained binary in `bin/grr`, eliminating runtime dependency issues.

## 🛠️ Development Standards

- **Bash 3.2 Compatibility:** Strictly adhere to Bash 3.2+ features to ensure portability across macOS and Linux. Avoid modern features like namerefs (`local -n`) or associative arrays.
- **Strict Safety:** Every script MUST start with `set -euo pipefail`.
- **Defensive Coding:** Quote all variables `"$VAR"` and prefer `[[ ... ]]` over `[ ... ]`. Use the `_git_timeout` wrapper for portable command timeouts.

## 🔄 Verified Workflows

- **Makefile-Driven Quality:** All verification (linting, testing, formatting) is centralized in the `Makefile`.
- **CI/CD Consistency:** The CI pipeline (`.github/workflows/ci.yml`) is refactored to use these same `Makefile` targets, ensuring that local success guarantees CI success.
- **Conventional Commits:** Enforced via `commit-lint` in CI and recommended for all changes.

## 🤖 AI Operation Guidance

1.  **Always Verify Locally:** Run `make lint test security vet` before proposing changes.
2.  **Follow the Library Pattern:** Do not add logic directly to commands if it can be abstracted into `lib/`.
3.  **Respect Portability:** Test changes in the provided `docker-compose` environment or on macOS to ensure cross-platform compatibility.
4.  **Maintain Documentation:** Update `SKILL.md` and this `GEMINI.md` when new architectural patterns or standards are introduced.
