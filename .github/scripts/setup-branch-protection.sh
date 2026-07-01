#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-HwangWoonChun/FishFreshness}"
BRANCH="${1:-main}"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required. Install: brew install gh" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Run: gh auth login" >&2
  exit 1
fi

echo "Applying branch protection to ${REPO}:${BRANCH}..."

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/branches/${BRANCH}/protection" \
  -f required_status_checks='null' \
  -F enforce_admins=true \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":false,"require_code_owner_reviews":false,"required_approving_review_count":0,"require_last_push_approval":false}' \
  -f restrictions='null' \
  -F required_linear_history=false \
  -F allow_force_pushes=false \
  -F allow_deletions=false \
  -F block_creations=false \
  -F required_conversation_resolution=true \
  -F lock_branch=false \
  -F allow_fork_syncing=true

gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}" \
  -f delete_branch_on_merge=true

echo "Done. Branch protection is active on ${BRANCH}."
