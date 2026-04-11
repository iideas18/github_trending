#!/bin/bash
# GitHub Trending Daily Report Generator
# Invokes Copilot CLI with the prompt to fetch trending repos,
# generate AI introductions, create HTML report, and push to GitHub.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROMPT=$(cat prompt.md)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting GitHub Trending report generation..."
copilot -p "$PROMPT" --allow-all --autopilot
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done."
