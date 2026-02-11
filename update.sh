#!/bin/bash

# Claude Status Line Updater
# Pulls latest changes and reinstalls the status line hook

set -e

echo "🔄 Updating Claude Status Line..."
echo ""

# Pull latest changes
echo "📥 Pulling latest changes from GitHub..."
git pull origin main

# Reinstall the script
echo "📦 Reinstalling status line..."
./install.sh

echo ""
echo "✅ Update complete! Your status line is now using the latest code."
echo "   All Claude Code instances will use the updated version."
