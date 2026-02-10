# Claude Status Line

A beautiful, real-time context window tracker for [Claude Code](https://claude.com/claude-code). Displays token usage, cache metrics, and model information right in your status bar.

## ✨ Features

- 📊 **Real-time context window tracking** - See your token usage update as you work
- 🎨 **Color-coded warnings** - Green (<50%), Yellow (50-80%), Red (>80%)
- 📈 **Detailed metrics** - Input, output, and cache token breakdowns
- 🚀 **Lightweight** - Pure bash, no dependencies (no jq required!)
- ⚡ **Fast** - Minimal overhead, updates instantly

## 📸 What it looks like

```
Context: 36% (33.2k/200.0k) | In: 7 | Out: 3 | Cache: 70.7k | S 4.5
```

Breaking it down:
- **Context: 36%** - Percentage of context window used (color-coded)
- **(33.2k/200.0k)** - Current tokens / Total context window
- **In: 7** - Input tokens for current turn
- **Out: 3** - Output tokens for current turn
- **Cache: 70.7k** - Cache read tokens (prompt caching)
- **S 4.5** - Model indicator (Sonnet 4.5)

## 🚀 Installation

### Quick Install

```bash
# Download the script
curl -o ~/.claude/hooks/status-line.sh https://raw.githubusercontent.com/YOUR_USERNAME/claude-status-line/main/status-line.sh

# Make it executable
chmod +x ~/.claude/hooks/status-line.sh
```

### Manual Install

1. Create the hooks directory if it doesn't exist:
   ```bash
   mkdir -p ~/.claude/hooks
   ```

2. Copy `status-line.sh` to `~/.claude/hooks/status-line.sh`

3. Make it executable:
   ```bash
   chmod +x ~/.claude/hooks/status-line.sh
   ```

### Verify Installation

Enable the status line in Claude Code:

```bash
claude config set statusline.hook ~/.claude/hooks/status-line.sh
```

Or manually add to `~/.claude/settings.json`:

```json
{
  "statusline": {
    "hook": "~/.claude/hooks/status-line.sh"
  }
}
```

## 🎨 Customization

### Color Thresholds

Edit the script to change when colors appear:

```bash
if [ "$used_pct_int" -lt 50 ]; then
    color="\033[32m"  # Green - change 50 to your preference
elif [ "$used_pct_int" -lt 80 ]; then
    color="\033[33m"  # Yellow - change 80 to your preference
else
    color="\033[31m"  # Red
fi
```

### Number Formatting

Change how numbers are abbreviated (k for thousands, M for millions):

```bash
format_num() {
    local n=$1
    if [ -z "$n" ] || [ "$n" -eq 0 ]; then
        echo "0"
    elif [ "$n" -ge 1000000 ]; then
        echo "$((n / 1000000)).$((n % 1000000 / 100000))M"
    elif [ "$n" -ge 1000 ]; then
        echo "$((n / 1000)).$((n % 1000 / 100))k"
    else
        echo "$n"
    fi
}
```

### Model Names

Customize how model names are displayed:

```bash
shorten_model() {
    local model="$1"
    case "$model" in
        *"Sonnet 4.5"*)
            echo "S 4.5"  # Change to your preference
            ;;
        # Add more cases...
    esac
}
```

## 🔧 Troubleshooting

### Status line not appearing?

1. Check that the hook is configured:
   ```bash
   cat ~/.claude/settings.json | grep statusline
   ```

2. Verify the script is executable:
   ```bash
   ls -l ~/.claude/hooks/status-line.sh
   ```

3. Test the script manually:
   ```bash
   echo '{"context_window":{"used_percentage":42,"context_window_size":200000,"total_input_tokens":50000,"total_output_tokens":34000,"current_usage":{"input_tokens":100,"output_tokens":50,"cache_read_input_tokens":5000}},"model":{"display_name":"Sonnet 4.5"}}' | ~/.claude/hooks/status-line.sh
   ```

### Getting zeros for token counts?

The script expects Claude Code v2.1.32+. Update Claude Code if needed:

```bash
claude update
```

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest features
- 🔧 Submit pull requests
- 📖 Improve documentation

## 📝 License

MIT License - feel free to use and modify!

## 🙏 Acknowledgments

Built for the [Claude Code](https://claude.com/claude-code) community.

## 📚 Related

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Claude Code Hooks Guide](https://docs.anthropic.com/claude/docs/hooks)

---

Made with ❤️ for the Claude Code community
