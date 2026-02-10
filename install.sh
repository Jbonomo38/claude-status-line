#!/bin/bash

# Claude Status Line Installer
# Installs the status line hook for Claude Code

set -e

HOOKS_DIR="$HOME/.claude/hooks"
SCRIPT_NAME="status-line.sh"
INSTALL_PATH="$HOOKS_DIR/$SCRIPT_NAME"

echo "🚀 Installing Claude Status Line..."
echo ""

# Create hooks directory if it doesn't exist
if [ ! -d "$HOOKS_DIR" ]; then
    echo "📁 Creating hooks directory: $HOOKS_DIR"
    mkdir -p "$HOOKS_DIR"
fi

# Check if script already exists
if [ -f "$INSTALL_PATH" ]; then
    echo "⚠️  Status line script already exists at $INSTALL_PATH"
    read -p "   Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Installation cancelled"
        exit 0
    fi
fi

# Copy the script
echo "📦 Installing $SCRIPT_NAME..."
cp "$SCRIPT_NAME" "$INSTALL_PATH"

# Make it executable
chmod +x "$INSTALL_PATH"

echo "✅ Installation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Enable in Claude Code:"
echo "      claude config set statusline.hook ~/.claude/hooks/status-line.sh"
echo ""
echo "   2. Or manually add to ~/.claude/settings.json:"
echo '      "statusline": {"hook": "~/.claude/hooks/status-line.sh"}'
echo ""
echo "   3. Restart Claude Code to see your new status line!"
echo ""
echo "🎉 Enjoy your real-time context tracking!"
