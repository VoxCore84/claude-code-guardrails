#!/usr/bin/env bash
# Install Claude Code Guardrails into the current project.
#
# Usage: curl -sL https://raw.githubusercontent.com/VoxCore84/claude-code-guardrails/master/install.sh | bash
#
# What it does:
#   1. Creates .claude/hooks/ if it doesn't exist
#   2. Downloads edit-verifier.py and sql-safety.py
#   3. Creates settings.local.json with hook wiring (won't overwrite existing)

set -euo pipefail

REPO="https://raw.githubusercontent.com/VoxCore84/claude-code-guardrails/master"
HOOKS_DIR=".claude/hooks"

echo "Installing Claude Code Guardrails..."
echo ""

# Check we're in a project directory
if [ ! -d ".claude" ] && [ ! -f "CLAUDE.md" ]; then
    echo "Creating .claude directory..."
    mkdir -p .claude
fi

mkdir -p "$HOOKS_DIR"

# Download hooks
echo "Downloading edit-verifier.py..."
curl -sL "$REPO/hooks/edit-verifier.py" -o "$HOOKS_DIR/edit-verifier.py"

echo "Downloading sql-safety.py..."
curl -sL "$REPO/hooks/sql-safety.py" -o "$HOOKS_DIR/sql-safety.py"

echo "Downloading config.json..."
curl -sL "$REPO/hooks/config.json" -o "$HOOKS_DIR/config.json"

# Create settings.local.json if it doesn't exist
SETTINGS=".claude/settings.local.json"
if [ -f "$SETTINGS" ]; then
    echo ""
    echo "Found existing $SETTINGS -- not overwriting."
    echo "Add the hook config manually. See: $REPO/hooks/settings.json.example"
else
    echo "Creating $SETTINGS with hook wiring..."
    curl -sL "$REPO/hooks/settings.json.example" -o "$SETTINGS"
fi

echo ""
echo "Done. Two hooks installed:"
echo "  - $HOOKS_DIR/edit-verifier.py  (PostToolUse: verifies every edit)"
echo "  - $HOOKS_DIR/sql-safety.py     (PreToolUse: blocks destructive SQL)"
echo ""
echo "Start a new Claude Code session to activate."
