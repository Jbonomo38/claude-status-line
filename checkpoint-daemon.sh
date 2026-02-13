#!/bin/bash

# Checkpoint Daemon for Claude Status Line
# Automatically creates checkpoints when context usage reaches thresholds
# Runs in the background and monitors the status line state

STATE_FILE="${HOME}/.claude/cache/status-line-state.json"
CHECKPOINT_STATE="${HOME}/.claude/cache/checkpoint-state.json"
DAEMON_PID_FILE="${HOME}/.claude/cache/checkpoint-daemon.pid"

# Checkpoint thresholds
CHECKPOINT_THRESHOLD=85  # Create checkpoint at 85%
CLEAR_SUGGESTION_THRESHOLD=90  # Suggest /clear at 90%

# Debounce interval (seconds) - avoid creating checkpoints too frequently
DEBOUNCE_INTERVAL=300  # 5 minutes

# Initialize checkpoint state if needed
initialize_state() {
    if [ ! -f "$CHECKPOINT_STATE" ]; then
        cat > "$CHECKPOINT_STATE" << EOF
{
  "last_checkpoint_time": 0,
  "last_checkpoint_percentage": 0,
  "checkpoint_available": false,
  "checkpoint_file": "",
  "last_check_time": 0
}
EOF
    fi
}

# Parse status line state to get current usage percentage
get_current_usage() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "0"
        return
    fi

    # Read session totals and baseline
    session_input=$(grep -o '"last_session_input"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
    session_output=$(grep -o '"last_session_output"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
    baseline_input=$(grep -o '"baseline_input"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
    baseline_output=$(grep -o '"baseline_output"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)

    session_input=${session_input:-0}
    session_output=${session_output:-0}
    baseline_input=${baseline_input:-0}
    baseline_output=${baseline_output:-0}

    # Calculate conversation tokens
    conv_tokens=$((session_input - baseline_input + session_output - baseline_output))

    # Calculate percentage (assume 200k context window)
    if [ "$conv_tokens" -gt 0 ]; then
        pct=$(awk "BEGIN {printf \"%.0f\", ($conv_tokens / 200000) * 100}")
        echo "$pct"
    else
        echo "0"
    fi
}

# Create checkpoint using Claude Code skill
create_checkpoint() {
    local usage_pct=$1
    local timestamp=$(date +%s)
    local checkpoint_file="${HOME}/.claude/checkpoints/auto-checkpoint-${timestamp}.md"

    echo "[$(date)] Creating automatic checkpoint at ${usage_pct}% usage..."

    # Use the checkpoint skill via claude command
    # Note: This requires the session to be active
    # For now, we just mark that a checkpoint should be created
    # The actual checkpoint will be created by the status line hook

    cat > "$CHECKPOINT_STATE" << EOF
{
  "last_checkpoint_time": $timestamp,
  "last_checkpoint_percentage": $usage_pct,
  "checkpoint_requested": true,
  "checkpoint_available": false,
  "checkpoint_file": "$checkpoint_file",
  "last_check_time": $timestamp
}
EOF

    echo "[$(date)] Checkpoint requested at ${usage_pct}%"
}

# Update checkpoint state after successful checkpoint
mark_checkpoint_complete() {
    local timestamp=$(date +%s)
    local pct=$1

    # Read current state
    if [ -f "$CHECKPOINT_STATE" ]; then
        checkpoint_file=$(grep -o '"checkpoint_file"[[:space:]]*:[[:space:]]*"[^"]*"' "$CHECKPOINT_STATE" | sed 's/.*:\s*"\([^"]*\)".*/\1/')
    fi

    cat > "$CHECKPOINT_STATE" << EOF
{
  "last_checkpoint_time": $timestamp,
  "last_checkpoint_percentage": $pct,
  "checkpoint_requested": false,
  "checkpoint_available": true,
  "checkpoint_file": "$checkpoint_file",
  "last_check_time": $timestamp
}
EOF
}

# Main daemon loop
run_daemon() {
    echo "[$(date)] Checkpoint daemon starting..."
    echo $$ > "$DAEMON_PID_FILE"

    initialize_state

    while true; do
        # Get current usage
        usage_pct=$(get_current_usage)
        current_time=$(date +%s)

        # Read checkpoint state
        if [ -f "$CHECKPOINT_STATE" ]; then
            last_checkpoint_time=$(grep -o '"last_checkpoint_time"[[:space:]]*:[[:space:]]*[0-9]*' "$CHECKPOINT_STATE" | grep -o '[0-9]*' | head -1)
            checkpoint_requested=$(grep -o '"checkpoint_requested"[[:space:]]*:[[:space:]]*[a-z]*' "$CHECKPOINT_STATE" | grep -o '[a-z]*' | head -1)
            last_checkpoint_time=${last_checkpoint_time:-0}
            checkpoint_requested=${checkpoint_requested:-false}
        else
            last_checkpoint_time=0
            checkpoint_requested=false
        fi

        # Calculate time since last checkpoint
        time_since_checkpoint=$((current_time - last_checkpoint_time))

        # Check if we should create a checkpoint
        if [ "$usage_pct" -ge "$CHECKPOINT_THRESHOLD" ] && \
           [ "$checkpoint_requested" = "false" ] && \
           [ "$time_since_checkpoint" -ge "$DEBOUNCE_INTERVAL" ]; then
            create_checkpoint "$usage_pct"
        fi

        # Sleep for 10 seconds before next check
        sleep 10
    done
}

# Handle signals for graceful shutdown
cleanup() {
    echo "[$(date)] Checkpoint daemon stopping..."
    rm -f "$DAEMON_PID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Run the daemon
run_daemon
