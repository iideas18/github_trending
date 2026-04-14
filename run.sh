#!/bin/bash
# GitHub Trending Daily Report Generator
# Invokes Copilot CLI with the prompt to fetch trending repos,
# generate AI introductions, create HTML report, and push to GitHub.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure proxy is set (needed for cron which has no inherited env)
export http_proxy="${http_proxy:-http://proxy.ims.intel.com:911}"
export https_proxy="${https_proxy:-http://proxy.ims.intel.com:911}"
export no_proxy="${no_proxy:-localhost,*.intel.com,127.0.0.1,intel.com}"

# Ensure copilot CLI is on PATH
export PATH="$HOME/.vscode-server/data/User/globalStorage/github.copilot-chat/copilotCli:$PATH"

PROMPT=$(cat prompt.md)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting GitHub Trending report generation..."
copilot -p "$PROMPT" --allow-all --autopilot
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done."
