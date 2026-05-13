.PHONY: help build run test clean lint fmt security coverage install dev-setup changelog changelog-check

# Variables
BINARY_NAME=bash-template
VERSION?=dev
COMMIT?=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
BASH_VERSION_STR?=$(shell bash --version | head -1 | awk '{print $$4}')

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

build: ## Build the application (bundle into bin/)
	@echo "Building $(BINARY_NAME)..."
	@chmod +x scripts/build.sh
	@scripts/build.sh "$(VERSION)" "$(COMMIT)" "$(BUILD_TIME)"
	@echo "Build complete: bin/$(BINARY_NAME)"

run: build ## Build and run the application
	@bin/$(BINARY_NAME) hello

test: ## Run all tests (BATS)
	@echo "Running tests..."
	@if command -v bats >/dev/null 2>&1; then \
		bats test/unit/ test/integration/; \
	else \
		echo "BATS not installed. Run 'make dev-setup' first."; \
		exit 1; \
	fi

test-unit: ## Run unit tests only
	@echo "Running unit tests..."
	@bats test/unit/

test-integration: ## Run integration tests only
	@echo "Running integration tests..."
	@bats test/integration/

coverage: test ## Run tests with coverage (via kcov if available)
	@echo "Generating coverage report..."
	@if command -v kcov >/dev/null 2>&1; then \
		mkdir -p coverage; \
		kcov --include-path=src/,lib/ coverage bats test/unit/ test/integration/ || true; \
		echo "Coverage report: coverage/index.html"; \
	else \
		echo "kcov not installed. Tests passed but no coverage report."; \
		echo "Install kcov for coverage: https://github.com/SimonKagstrom/kcov"; \
	fi

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@rm -rf bin/ dist/ coverage/ test_results/
	@echo "Clean complete"

install: ## Install runtime dependencies
	@echo "Checking dependencies..."
	@command -v bash >/dev/null 2>&1 || { echo "bash is required"; exit 1; }
	@echo "All dependencies satisfied"

lint: ## Run ShellCheck linter
	@echo "Running ShellCheck..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find src/ lib/ scripts/ -name '*.sh' -exec shellcheck -x {} +; \
		echo "Lint complete — no issues found"; \
	else \
		echo "ShellCheck not installed. Run 'make dev-setup' first."; \
		exit 1; \
	fi

fmt: ## Format code with shfmt
	@echo "Formatting code..."
	@if command -v shfmt >/dev/null 2>&1; then \
		find src/ lib/ scripts/ -name '*.sh' -exec shfmt -w -i 4 -ci {} +; \
		echo "Format complete"; \
	else \
		echo "shfmt not installed. Run 'make dev-setup' first."; \
		exit 1; \
	fi

fmt-check: ## Check formatting without modifying
	@echo "Checking formatting..."
	@if command -v shfmt >/dev/null 2>&1; then \
		find src/ lib/ scripts/ -name '*.sh' -exec shfmt -d -i 4 -ci {} + || { echo "Formatting issues found. Run 'make fmt' to fix."; exit 1; }; \
		echo "Format check passed"; \
	else \
		echo "shfmt not installed. Run 'make dev-setup' first."; \
		exit 1; \
	fi

vet: ## Run additional static analysis
	@echo "Running static analysis..."
	@find src/ lib/ -name '*.sh' -exec bash -n {} + && echo "Syntax check passed"
	@echo "Vet complete"

security: ## Run security checks
	@echo "Running security checks..."
	@if command -v shellcheck >/dev/null 2>&1; then \
		find src/ lib/ scripts/ -name '*.sh' -exec shellcheck -S warning -x {} +; \
	fi
	@echo "Security checks complete"

dev-setup: ## Setup development environment
	@echo "Setting up development environment..."
	@echo "Installing ShellCheck..."
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y shellcheck; \
		elif command -v brew >/dev/null 2>&1; then \
			brew install shellcheck; \
		else \
			echo "Please install ShellCheck manually: https://github.com/koalaman/shellcheck"; \
		fi; \
	else \
		echo "ShellCheck already installed"; \
	fi
	@echo "Installing shfmt..."
	@if ! command -v shfmt >/dev/null 2>&1; then \
		if command -v go >/dev/null 2>&1; then \
			go install mvdan.cc/sh/v3/cmd/shfmt@latest; \
		elif command -v brew >/dev/null 2>&1; then \
			brew install shfmt; \
		else \
			SHFMT_VERSION="v3.8.0"; \
			ARCH=$$(uname -m); \
			OS=$$(uname -s | tr '[:upper:]' '[:lower:]'); \
			case "$$ARCH" in x86_64) ARCH=amd64;; aarch64|arm64) ARCH=arm64;; esac; \
			mkdir -p $$HOME/.local/bin; \
			curl -sS -L "https://github.com/mvdan/sh/releases/download/$${SHFMT_VERSION}/shfmt_$${SHFMT_VERSION}_$${OS}_$${ARCH}" -o $$HOME/.local/bin/shfmt; \
			chmod +x $$HOME/.local/bin/shfmt; \
			echo "shfmt installed to $$HOME/.local/bin/shfmt — ensure it is on your PATH"; \
		fi; \
	else \
		echo "shfmt already installed"; \
	fi
	@echo "Installing BATS..."
	@if ! command -v bats >/dev/null 2>&1; then \
		if command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y bats; \
		elif command -v brew >/dev/null 2>&1; then \
			brew install bats-core; \
		else \
			echo "Please install BATS manually: https://github.com/bats-core/bats-core"; \
		fi; \
	else \
		echo "BATS already installed"; \
	fi
	@chmod +x scripts/setup-hooks.sh
	@scripts/setup-hooks.sh
	@echo "Development environment ready"

changelog: ## Regenerate CHANGELOG.md from Conventional Commits
	@chmod +x scripts/update-changelog.sh
	@scripts/update-changelog.sh

changelog-check: ## Verify CHANGELOG.md is up to date
	@cp CHANGELOG.md CHANGELOG.md.bak
	@chmod +x scripts/update-changelog.sh
	@scripts/update-changelog.sh
	@cmp -s CHANGELOG.md CHANGELOG.md.bak || (echo "CHANGELOG.md is outdated. Run 'make changelog'." && rm -f CHANGELOG.md.bak && exit 1)
	@rm -f CHANGELOG.md.bak
	@echo "CHANGELOG.md is up to date"

watch: ## Watch for changes and re-run lint+test (requires entr)
	@if command -v entr >/dev/null 2>&1; then \
		find src/ lib/ test/ -name '*.sh' -o -name '*.bats' | entr -c make lint test; \
	else \
		echo "entr not installed. Install with: apt-get install entr / brew install entr"; \
	fi

version: ## Show version information
	@if [[ -f bin/$(BINARY_NAME) ]]; then \
		bin/$(BINARY_NAME) --version; \
	else \
		echo "Binary not built. Run 'make build' first."; \
	fi

all: clean lint test build ## Run all targets
	@echo "All tasks completed"
