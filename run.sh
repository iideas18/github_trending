#!/bin/bash
# GitHub Trending Daily Report Generator
# Invokes Copilot CLI with the prompt to fetch trending repos,
# generate AI introductions, create HTML report, and push to GitHub.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Preflight checks ---
if ! command -v copilot >/dev/null 2>&1; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: copilot CLI not found on PATH" >&2
  exit 1
fi

if ! curl -fsS --max-time 10 https://github.com >/dev/null 2>&1; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: cannot reach github.com" >&2
  exit 1
fi

# Allowed paths for generated artifacts
ALLOWED_PATHS='^\?\? \.generation-complete$|^.. index\.html$|^.. data/seen_repos\.json$|^.. reports/'

# Fail fast: abort before generation if the worktree has unrelated changes
UNRELATED_PRE=$(git status --porcelain | grep -cvE "$ALLOWED_PATHS" || true)
if [ "$UNRELATED_PRE" -gt 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: unrelated uncommitted changes detected; refusing to start generation" >&2
  git status --short >&2
  exit 1
fi

# Push any unpushed daily-report commits from a previous failed run
if git rev-parse --verify '@{u}' >/dev/null 2>&1; then
  AHEAD=$(git rev-list '@{u}..HEAD' --count 2>/dev/null || echo 0)
  if [ "$AHEAD" -gt 0 ]; then
    # Only auto-push if every ahead commit matches the daily-report pattern
    NON_REPORT=$(git log '@{u}..HEAD' --format='%s' | grep -cvE '^📊 Daily trending report [0-9]{4}-[0-9]{2}-[0-9]{2}$' || true)
    if [ "$NON_REPORT" -gt 0 ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: branch is $AHEAD commit(s) ahead with non-report commits; aborting to avoid publishing unintended changes" >&2
      exit 1
    fi
    # Verify ahead commits only touch expected generated files
    UNEXPECTED_FILES=$(git diff --name-only '@{u}..HEAD' | grep -cvE '^index\.html$|^data/seen_repos\.json$|^reports/' || true)
    if [ "$UNEXPECTED_FILES" -gt 0 ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: ahead commits touch unexpected files; aborting auto-push" >&2
      git diff --name-only '@{u}..HEAD' >&2
      exit 1
    fi
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $AHEAD unpushed report commit(s), pushing before starting..."
    git push origin main || { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: failed to push stale commits" >&2; exit 1; }
  fi
fi

# Clean up any stale sentinel from a prior run
rm -f .generation-complete

PROMPT=$(cat prompt.md)

# NOTE: --allow-all is required because the prompt needs web_fetch, file I/O,
# and shell access. The prompt contains explicit content-isolation rules to
# mitigate injection from untrusted repo descriptions and README content.
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting GitHub Trending report generation..."
copilot -p "$PROMPT" --allow-all --autopilot

# Check if the agent signaled successful generation
if [ ! -f .generation-complete ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] No new report generated (or generation failed). Skipping commit."
  exit 0
fi
rm -f .generation-complete

TODAY=$(date '+%Y-%m-%d')

# Post-generation: verify the worktree is still clean of unrelated changes
UNRELATED=$(git status --porcelain | grep -cvE "$ALLOWED_PATHS" || true)
if [ "$UNRELATED" -gt 0 ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: unrelated uncommitted changes detected; aborting to avoid staging unintended files" >&2
  git status --short >&2
  exit 1
fi

# Stage all generated artifacts (not just today's report — ensures index.html
# references are consistent with committed report files)
git add index.html data/seen_repos.json
shopt -s nullglob
for f in reports/*.html; do
  git add "$f"
done
shopt -u nullglob

git commit -m "📊 Daily trending report ${TODAY}"
git push origin main || { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: git push failed" >&2; exit 1; }

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done."
