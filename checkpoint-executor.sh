#!/bin/bash

# Checkpoint Executor Hook
# Called by status line when checkpoint is requested
# Creates a checkpoint using the /checkpoint skill

CHECKPOINT_STATE="${HOME}/.claude/cache/checkpoint-state.json"
CHECKPOINT_DIR="${HOME}/.claude/checkpoints"

# Ensure checkpoint directory exists
mkdir -p "$CHECKPOINT_DIR"

# Check if checkpoint is requested
if [ ! -f "$CHECKPOINT_STATE" ]; then
    exit 0
fi

checkpoint_requested=$(grep -o '"checkpoint_requested"[[:space:]]*:[[:space:]]*[a-z]*' "$CHECKPOINT_STATE" | grep -o '[a-z]*' | tail -1)

if [ "$checkpoint_requested" = "true" ]; then
    timestamp=$(date +%s)
    checkpoint_file="$CHECKPOINT_DIR/auto-checkpoint-${timestamp}.md"

    # Get current usage percentage
    usage_pct=$(grep -o '"last_checkpoint_percentage"[[:space:]]*:[[:space:]]*[0-9]*' "$CHECKPOINT_STATE" | grep -o '[0-9]*' | head -1)
    usage_pct=${usage_pct:-0}

    # Calculate actual usage from state file
    STATE_FILE="${HOME}/.claude/cache/status-line-state.json"
    if [ -f "$STATE_FILE" ]; then
        session_input=$(grep -o '"last_session_input"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
        session_output=$(grep -o '"last_session_output"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
        baseline_input=$(grep -o '"baseline_input"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
        baseline_output=$(grep -o '"baseline_output"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)

        session_input=${session_input:-0}
        session_output=${session_output:-0}
        baseline_input=${baseline_input:-0}
        baseline_output=${baseline_output:-0}

        conv_tokens=$((session_input - baseline_input + session_output - baseline_output))
        usage_pct=$(awk "BEGIN {printf \"%.0f\", ($conv_tokens / 200000) * 100}")
    fi

    # Create checkpoint file
    cat > "$checkpoint_file" << EOF
# Automatic Checkpoint - $(date)

**Context Usage:** ${usage_pct}%
**Conversation Tokens:** ${conv_tokens:-unknown}
**Created:** $(date '+%Y-%m-%d %H:%M:%S')

---

## Conversation Summary

This checkpoint was automatically created when context usage reached ${usage_pct}%.

Key decisions and progress will be captured here by the checkpoint skill.

---

**Note:** This is an automatic checkpoint. You can now safely run \`/clear\` to start a fresh conversation while preserving this context.
EOF

    # Mark checkpoint as complete
    cat > "$CHECKPOINT_STATE" << EOF
{
  "last_checkpoint_time": $timestamp,
  "last_checkpoint_percentage": $usage_pct,
  "checkpoint_requested": false,
  "checkpoint_available": true,
  "checkpoint_file": "$checkpoint_file",
  "last_check_time": $timestamp
}
EOF

    echo "✅ Automatic checkpoint created at ${usage_pct}%: $checkpoint_file"
fi
