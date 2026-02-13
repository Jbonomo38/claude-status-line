#!/bin/bash

# Setup script for automatic checkpoint system
# Installs all components and configures Claude Code

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="${HOME}/.claude/hooks"
CACHE_DIR="${HOME}/.claude/cache"
CHECKPOINT_DIR="${HOME}/.claude/checkpoints"

echo "🚀 Setting up automatic checkpoint system..."
echo ""

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$HOOKS_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$CHECKPOINT_DIR"

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x "$SCRIPT_DIR/status-line.sh"
chmod +x "$SCRIPT_DIR/checkpoint-daemon.sh"
chmod +x "$SCRIPT_DIR/checkpoint-executor.sh"

# Copy scripts to hooks directory
echo "📋 Installing scripts..."
cp "$SCRIPT_DIR/status-line.sh" "$HOOKS_DIR/status-line.sh"
cp "$SCRIPT_DIR/checkpoint-executor.sh" "$HOOKS_DIR/checkpoint-executor.sh"

# Initialize state files
echo "💾 Initializing state files..."
if [ ! -f "$CACHE_DIR/status-line-state.json" ]; then
    cat > "$CACHE_DIR/status-line-state.json" << EOF
{
  "baseline_input": 0,
  "baseline_output": 0,
  "baseline_cache": 0,
  "last_session_input": 0,
  "last_session_output": 0,
  "last_session_cache": 0
}
EOF
fi

if [ ! -f "$CACHE_DIR/checkpoint-state.json" ]; then
    cat > "$CACHE_DIR/checkpoint-state.json" << EOF
{
  "last_checkpoint_time": 0,
  "last_checkpoint_percentage": 0,
  "checkpoint_requested": false,
  "checkpoint_available": false,
  "checkpoint_file": "",
  "last_check_time": 0
}
EOF
fi

# Check if status line is configured
echo ""
echo "✅ Installation complete!"
echo ""
echo "📝 Next steps:"
echo ""
echo "1. Ensure status line is enabled in ~/.claude/settings.json:"
echo "   {\"statusLine\": {\"type\": \"command\", \"command\": \"~/.claude/hooks/status-line.sh\", \"padding\": 0}}"
echo ""
echo "2. (Optional) Start the checkpoint daemon for automatic checkpoints:"
echo "   $SCRIPT_DIR/checkpoint-daemon.sh &"
echo ""
echo "3. Or run checkpoint executor hook manually when needed:"
echo "   ~/.claude/hooks/checkpoint-executor.sh"
echo ""
echo "🎯 Features enabled:"
echo "  ✓ Conversation-level token tracking (resets on /clear)"
echo "  ✓ Smart warnings at 60%, 80%, 85%, 90%, 95%"
echo "  ✓ Automatic checkpoint requests at 85%"
echo "  ✓ Safe to /clear indicators after checkpoints"
echo ""
echo "💡 Tip: The status line will automatically request checkpoints when"
echo "   you reach 85% usage. After a checkpoint is created, you'll see"
echo "   'Safe to /clear' messages to help manage your context window."
echo ""
