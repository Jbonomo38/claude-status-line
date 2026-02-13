#!/bin/bash

# Helper script to push to GitHub
# Run this after creating your GitHub repo

echo "🚀 Claude Status Line - GitHub Push Helper"
echo ""

# Get GitHub username
read -p "Enter your GitHub username: " github_user

if [ -z "$github_user" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

echo ""
echo "📝 Setting up remote..."

# Check if remote already exists
if git remote get-url origin &> /dev/null; then
    echo "⚠️  Remote 'origin' already exists. Updating..."
    git remote set-url origin "git@github.com:${github_user}/claude-status-line.git"
else
    git remote add origin "git@github.com:${github_user}/claude-status-line.git"
fi

echo "🔄 Pushing to GitHub..."
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Successfully pushed to GitHub!"
    echo ""
    echo "🎉 Your repo is live at:"
    echo "   https://github.com/${github_user}/claude-status-line"
    echo ""
    echo "📝 Don't forget to:"
    echo "   1. Add topics/tags to your repo (bash, claude-code, status-line)"
    echo "   2. Consider adding a screenshot to the README"
    echo "   3. Share it with the community!"
else
    echo ""
    echo "❌ Push failed. Make sure:"
    echo "   1. You've created the repo on GitHub"
    echo "   2. Your SSH key is set up (or use HTTPS)"
    echo "   3. The repo name matches: claude-status-line"
fi
