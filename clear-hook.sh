#!/bin/bash

# Clear Hook - Resets status line baseline when /clear is run
# This ensures conversation-level tokens reset to zero

STATE_FILE="${HOME}/.claude/cache/status-line-state.json"
CHECKPOINT_STATE="${HOME}/.claude/cache/checkpoint-state.json"

# Read current session totals from state file
if [ -f "$STATE_FILE" ]; then
    session_input=$(grep -o '"last_session_input"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
    session_output=$(grep -o '"last_session_output"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
    session_cache=$(grep -o '"last_session_cache"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)

    session_input=${session_input:-0}
    session_output=${session_output:-0}
    session_cache=${session_cache:-0}

    # Reset baseline to current session totals (effectively zeroing conversation tokens)
    cat > "$STATE_FILE" << EOF
{
  "baseline_input": $session_input,
  "baseline_output": $session_output,
  "baseline_cache": $session_cache,
  "last_session_input": $session_input,
  "last_session_output": $session_output,
  "last_session_cache": $session_cache
}
EOF

    # Also reset checkpoint state
    cat > "$CHECKPOINT_STATE" << EOF
{
  "last_checkpoint_time": 0,
  "last_checkpoint_percentage": 0,
  "checkpoint_requested": false,
  "checkpoint_available": false,
  "checkpoint_file": "",
  "last_check_time": 0
}
EOF

    echo "✅ Status line reset - conversation tokens now at 0%"
fi
