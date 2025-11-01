# ==== Config ====
POETRY := poetry
PRECOMMIT_PROJECT := .

# ==== Service Specific Config ====
SERVICE_DIRS := services/agent-engine


# ==== Bootstrap ====
.PHONY: help setup resync precommit-install hooks-update install install-ci

## Show available make targets
help:
	@echo "Available targets:"
	@echo ""
	@awk '/^## /{comment=substr($$0,4)} /^[a-zA-Z_-]+:/{if(comment)printf "  %-20s %s\n",substr($$1,1,length($$1)-1),comment; comment=""}' $(MAKEFILE_LIST) | sort

## Initialize project (setup + precommit + service deps) - RUN THIS FIRST
init: setup precommit-install install

## Setup pre-commit environment
setup:
	$(POETRY) -C $(PRECOMMIT_PROJECT) install --with dev --no-root --sync --no-interaction
	@echo "Root env ready: $$($(POETRY) -C $(PRECOMMIT_PROJECT) env info --path)"

## Resync root environment (run after changing Python version)
resync:
	$(POETRY) -C $(PRECOMMIT_PROJECT) sync --with dev --no-interaction
	@echo "Root environment resynced"

## Install pre-commit hooks into git
precommit-install:
	$(POETRY) -C $(PRECOMMIT_PROJECT) run pre-commit install -t pre-commit -t commit-msg
	@echo "Pre-commit hooks installed"

## Update pre-commit hooks to latest versions
hooks-update:
	$(POETRY) -C $(PRECOMMIT_PROJECT) run pre-commit autoupdate
	@echo "Pre-commit hooks updated"

## Install all dependencies (including dev) for all services
install:
	@set -e; for d in $(SERVICE_DIRS); do \
		echo "==> $(POETRY) -C $$d install --with dev"; \
		$(POETRY) -C $$d install --with dev; \
	done
	@echo "All services installed"

## Install all dependencies (CI only) for all services (installs in Virtual env in project)
install-ci:
	@set -e; for d in $(SERVICE_DIRS); do \
		echo "==> Setting up CI for $$d"; \
		$(POETRY) -C $$d config virtualenvs.in-project true; \
		$(POETRY) -C $$d install --with dev; \
	done


# ==== Quality ====
.PHONY: lint

## Run all hooks once for the entire repository
lint:
	@echo "Linting all services..."
	$(POETRY) -C $(PRECOMMIT_PROJECT) run pre-commit run --all-files --color always --verbose
	@echo "All services linted"


# ==== Maintenance ====
.PHONY: clean

## Remove caches & build artifacts
clean:
	rm -rf .mypy_cache .ruff_cache .pytest_cache **/__pycache__ build dist
