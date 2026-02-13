# Quick Start Guide

## 🚀 5-Minute Setup

### 1. Install the System

```bash
cd ~/claude-status-line
./setup-auto-checkpoint.sh
```

### 2. Verify Status Line is Enabled

Check your `~/.claude/settings.json` contains:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/hooks/status-line.sh",
    "padding": 0
  }
}
```

### 3. Start Using Claude Code

That's it! The status line is now active with automatic checkpoint support.

## 🎯 What You'll See

### Normal Usage
```
Context: 42% (84.0k/200.0k) | In: 12.5k | Out: 8.2k | Cache: 64.0k | S 4.5
```

### When Checkpoint is Created
```
Context: 87% (174.0k/200.0k) | In: 89.5k | Out: 84.5k | Cache: 0 | S 4.5 ✅ Checkpoint saved at 87%
```

### When You Should Clear
```
Context: 93% (186.0k/200.0k) | In: 95.2k | Out: 90.8k | Cache: 0 | S 4.5 ✅ Safe to /clear
```

## 📊 Understanding the Metrics

| Metric | Description |
|--------|-------------|
| **Context: 42%** | Percentage of context window used (conversation-level) |
| **(84.0k/200.0k)** | Current conversation tokens / Total window |
| **In: 12.5k** | Input tokens this conversation |
| **Out: 8.2k** | Output tokens this conversation |
| **Cache: 64.0k** | Cache read tokens (good for performance!) |
| **S 4.5** | Model (Sonnet 4.5) |

## 🚦 Warning Levels

| % | Color | Message | Action |
|---|-------|---------|--------|
| <60% | 🟢 Green | None | Keep working |
| 60-80% | 🟡 Yellow | None | Monitor usage |
| 80-85% | 🔴 Red | ⚠️ | Warning |
| 85-90% | 🔴 Red | 💾 Creating checkpoint... | Automatic |
| 90-95% | 🔴 Red | ✅ Safe to /clear | Consider clearing |
| 95%+ | 🔴 **Bold** | 🟢 SAFE TO /clear | Clear now! |

## 💡 Pro Tips

1. **Let it auto-checkpoint** - At 85%, a checkpoint is automatically requested
2. **Wait for green light** - Look for "Safe to /clear" before clearing
3. **Monitor yellow zone** - At 60%, start thinking about wrapping up
4. **Check your checkpoints** - They're saved in `~/.claude/checkpoints/`

## 🔧 Manual Control

### Create Checkpoint Manually
```bash
~/.claude/hooks/checkpoint-executor.sh
```

### Check Checkpoint Status
```bash
cat ~/.claude/cache/checkpoint-state.json
```

### Reset Conversation (after checkpoint)
Just run `/clear` in Claude Code!

## 🆘 Troubleshooting

### Status line not showing?
1. Check settings: `cat ~/.claude/settings.json | grep statusLine`
2. Test script: `echo '{"context_window_size":200000,"display_name":"Sonnet 4.5","total_input_tokens":50000,"total_output_tokens":34000}' | ~/.claude/hooks/status-line.sh`

### Checkpoints not creating?
1. Check permissions: `ls -l ~/.claude/hooks/checkpoint-executor.sh`
2. Check state: `cat ~/.claude/cache/checkpoint-state.json`

### Need help?
- Check the full README.md
- Review EXAMPLES.md for visual examples
- Open an issue on GitHub
