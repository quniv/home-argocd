#!/usr/bin/env bash
# install-global-hooks.sh: install gitleaks git hooks globally for all repos
# on this machine. Run once per user account. Idempotent.
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

GLOBAL_HOOKS_DIR="${HOME}/.config/git/hooks"

# Resolve the script's own directory so it works regardless of cwd
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_HOOKS_DIR="${SCRIPT_DIR}/../.githooks"

# ── Verify source hooks exist ────────────────────────────────────────────────
for hook in pre-commit pre-push; do
  if [[ ! -f "${REPO_HOOKS_DIR}/${hook}" ]]; then
    echo -e "${RED}ERROR: Source hook not found: ${REPO_HOOKS_DIR}/${hook}${NC}"
    echo "Run this script from inside the home-argocd repository."
    exit 1
  fi
done

# ── Create global hooks directory ────────────────────────────────────────────
if [[ ! -d "${GLOBAL_HOOKS_DIR}" ]]; then
  mkdir -p "${GLOBAL_HOOKS_DIR}"
  echo -e "${YELLOW}[install] Created ${GLOBAL_HOOKS_DIR}${NC}"
fi

# ── Configure git globally ───────────────────────────────────────────────────
current_global="$(git config --global core.hooksPath 2>/dev/null || true)"
if [[ "${current_global}" != "${GLOBAL_HOOKS_DIR}" ]]; then
  git config --global core.hooksPath "${GLOBAL_HOOKS_DIR}"
  echo -e "${YELLOW}[install] Set git global core.hooksPath to ${GLOBAL_HOOKS_DIR}${NC}"
else
  echo -e "${YELLOW}[install] git global core.hooksPath already points to ${GLOBAL_HOOKS_DIR}${NC}"
fi

# ── Copy hooks and make them executable ──────────────────────────────────────
for hook in pre-commit pre-push; do
  src="${REPO_HOOKS_DIR}/${hook}"
  dst="${GLOBAL_HOOKS_DIR}/${hook}"

  cp "${src}" "${dst}"
  chmod +x "${dst}"
  echo -e "${GREEN}[install] Installed ${hook} → ${dst}${NC}"
done

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Global gitleaks hooks installed successfully.               ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║  All git repositories on this machine will now run           ║${NC}"
echo -e "${GREEN}║  gitleaks on every commit and push.                          ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  Make sure gitleaks is installed:                            ║${NC}"
echo -e "${GREEN}║    brew install gitleaks                                     ║${NC}"
echo -e "${GREEN}║    https://github.com/gitleaks/gitleaks#installing           ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
