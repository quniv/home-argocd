#!/usr/bin/env bash
# setup.sh: wire this repository to use .githooks/ as the hooks directory.
# Idempotent — safe to run multiple times.
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

HOOKS_DIR=".githooks"

# Resolve repo root (run from anywhere inside the repo)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERROR: Not inside a git repository." >&2
  exit 1
}

current_path="$(git -C "${REPO_ROOT}" config --local core.hooksPath 2>/dev/null || true)"

if [[ "${current_path}" == "${HOOKS_DIR}" ]]; then
  echo -e "${YELLOW}[setup] core.hooksPath is already set to '${HOOKS_DIR}' — nothing to do.${NC}"
  exit 0
fi

git -C "${REPO_ROOT}" config core.hooksPath "${HOOKS_DIR}"

echo -e "${GREEN}[setup] core.hooksPath set to '${HOOKS_DIR}' for this repository.${NC}"
echo -e "${GREEN}[setup] Git will now use .githooks/ pre-commit and pre-push hooks.${NC}"
