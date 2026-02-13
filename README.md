# Claude Status Line

A beautiful, real-time context window tracker for [Claude Code](https://claude.com/claude-code). Displays token usage, cache metrics, and model information right in your status bar.

## ✨ Features

- 📊 **Conversation-level tracking** - Automatically resets when you run `/clear`
- ⚠️ **Smart checkpoint warnings** - Visual alerts when approaching context limits
  - 🟢 Green (<60%) - Safe zone
  - 🟡 Yellow (60-80%) - Monitor usage
  - 🔴 Red (80-90%) - Warning indicator
  - 🔴 Red (90-95%) - "Consider /checkpoint"
  - 🔴 **Bold Red (95%+)** - "CHECKPOINT NOW!"
- 📈 **Detailed metrics** - Input, output, and cache token breakdowns
- 🚀 **Lightweight** - Pure bash, no dependencies (no jq required!)
- ⚡ **Fast** - Minimal overhead, updates instantly

## 📸 What it looks like

```
Context: 36% (33.2k/200.0k) | In: 12.5k | Out: 8.2k | Cache: 70.7k | S 4.5
Context: 92% (184k/200.0k) | In: 98.5k | Out: 85.5k | Cache: 120k | S 4.5 ⚠️ Consider /checkpoint
```

Breaking it down:
- **Context: 36%** - Percentage of context window used (color-coded, conversation-level)
- **(33.2k/200.0k)** - Conversation tokens / Total context window
- **In: 12.5k** - Input tokens for this conversation
- **Out: 8.2k** - Output tokens for this conversation
- **Cache: 70.7k** - Cache read tokens (prompt caching)
- **S 4.5** - Model indicator (Sonnet 4.5)
- **⚠️ Consider /checkpoint** - Warning shown at 90%+ usage

## 🤖 Automatic Checkpoint System

The status line includes an intelligent checkpoint system that helps you manage context usage:

### How It Works

1. **85% Usage** - Status line automatically requests a checkpoint
2. **Checkpoint Created** - Shows "✅ Checkpoint saved at 87%"
3. **90%+ Usage** - Shows "Safe to /clear" when checkpoint is available
4. **95%+ Usage** - Bold "SAFE TO /clear" reminder

### Setup Automatic Checkpoints

```bash
cd /home/jbono/claude-status-line
./setup-auto-checkpoint.sh
```

This enables:
- ✅ Automatic checkpoint requests at thresholds
- ✅ Visual indicators showing when it's safe to clear
- ✅ Checkpoint status tracking

### Manual Checkpoint Trigger

When the status line shows "Consider /checkpoint", run:

```bash
~/.claude/hooks/checkpoint-executor.sh
```

This creates a checkpoint file with conversation context at `~/.claude/checkpoints/`.

## 🚀 Installation

### Quick Install

```bash
# Download the script
curl -o ~/.claude/hooks/status-line.sh https://raw.githubusercontent.com/Jbonomo38/claude-status-line/main/status-line.sh

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

### Color Thresholds and Warnings

Edit the script to change when colors and warnings appear:

```bash
if [ "$used_pct_int" -lt 60 ]; then
    color="\033[32m"  # Green - change 60 to your preference
    warning=""
elif [ "$used_pct_int" -lt 80 ]; then
    color="\033[33m"  # Yellow - change 80 to your preference
    warning=""
elif [ "$used_pct_int" -lt 90 ]; then
    color="\033[31m"  # Red
    warning=" ⚠️"
elif [ "$used_pct_int" -lt 95 ]; then
    color="\033[31m"  # Red
    warning=" ⚠️ Consider /checkpoint"
else
    color="\033[31m\033[1m"  # Bold Red
    warning=" 🔴 CHECKPOINT NOW!"
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

## 🎯 Usage Patterns

### Normal Workflow

1. Work normally - status shows green
2. At 85% - Checkpoint automatically requested
3. At 90% - "Safe to /clear" indicator appears
4. Run `/clear` - Start fresh conversation
5. Run `~/reset-tokens` - Reset counters to zero
6. Continue with fresh context window

### Warning Indicators

- 🟢 **<60%** - All clear
- 🟡 **60-80%** - Monitor usage
- 🔴 **80-85%** - ⚠️ Warning
- 🔴 **85-90%** - 💾 Creating checkpoint...
- 🔴 **90-95%** - ✅ Safe to /clear
- 🔴 **95%+** - 🟢 SAFE TO /clear (bold)

## 📚 Related

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Claude Code Hooks Guide](https://docs.anthropic.com/claude/docs/hooks)

---

Made with ❤️ for the Claude Code community
