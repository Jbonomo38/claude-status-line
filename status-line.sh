#!/bin/bash

# Status line script for Claude Code
# Displays real-time context window usage with detailed token breakdown
# Tracks conversation-level tokens (resets on /clear)

# State file to track conversation baseline
STATE_FILE="${HOME}/.claude/cache/status-line-state.json"
mkdir -p "$(dirname "$STATE_FILE")"

# Read JSON input from stdin
status_input=$(cat)

# Parse JSON fields using grep/sed (no jq dependency)
total_tokens=$(echo "$status_input" | grep -o '"context_window_size"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)
model_name=$(echo "$status_input" | grep -o '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:\s*"\([^"]*\)".*/\1/')

# Parse session totals (accumulated across all conversations in this session)
session_input=$(echo "$status_input" | grep -o '"total_input_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)
session_output=$(echo "$status_input" | grep -o '"total_output_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)
session_cache=$(echo "$status_input" | grep -o '"total_cache_read_input_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)

# Set defaults
session_input=${session_input:-0}
session_output=${session_output:-0}
session_cache=${session_cache:-0}
total_tokens=${total_tokens:-200000}
model_name=${model_name:-"Claude"}

# Load or initialize baseline (conversation start point)
if [ -f "$STATE_FILE" ]; then
    baseline_input=$(grep -o '"baseline_input"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
    baseline_output=$(grep -o '"baseline_output"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)
    baseline_cache=$(grep -o '"baseline_cache"[[:space:]]*:[[:space:]]*[0-9]*' "$STATE_FILE" | grep -o '[0-9]*' | head -1)

    baseline_input=${baseline_input:-0}
    baseline_output=${baseline_output:-0}
    baseline_cache=${baseline_cache:-0}

    # Detect if /clear was run (session totals decreased or reset to zero)
    if [ "$session_input" -lt "$baseline_input" ] || [ "$session_output" -lt "$baseline_output" ] || [ "$session_cache" -lt "$baseline_cache" ]; then
        # Reset baseline to current session totals
        baseline_input=$session_input
        baseline_output=$session_output
        baseline_cache=$session_cache
    fi
else
    # First run - set baseline to current session totals
    baseline_input=$session_input
    baseline_output=$session_output
    baseline_cache=$session_cache
fi

# Save current baseline for next invocation
cat > "$STATE_FILE" << EOF
{
  "baseline_input": $baseline_input,
  "baseline_output": $baseline_output,
  "baseline_cache": $baseline_cache,
  "last_session_input": $session_input,
  "last_session_output": $session_output,
  "last_session_cache": $session_cache
}
EOF

# Calculate conversation-level tokens (current session minus baseline)
input_tokens=$((session_input - baseline_input))
output_tokens=$((session_output - baseline_output))
cache_tokens=$((session_cache - baseline_cache))
used_tokens=$((input_tokens + output_tokens))

# Calculate percentage manually (handles overflow beyond 100%)
if [ "$total_tokens" -gt 0 ]; then
    used_pct=$(awk "BEGIN {printf \"%.1f\", ($used_tokens / $total_tokens) * 100}")
else
    used_pct="0.0"
fi

# Function to format numbers (e.g., 84678 → 84.7k)
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

# Shorten model names (e.g., "Claude Sonnet 4.5" → "S 4.5")
shorten_model() {
    local model="$1"
    case "$model" in
        *"Sonnet 4.5"*)
            echo "S 4.5"
            ;;
        *"Opus 4.5"*)
            echo "O 4.5"
            ;;
        *"Haiku 4"*)
            echo "H 4"
            ;;
        *"Sonnet"*)
            echo "Sonnet"
            ;;
        *"Opus"*)
            echo "Opus"
            ;;
        *"Haiku"*)
            echo "Haiku"
            ;;
        *)
            echo "$model"
            ;;
    esac
}

# Format all numbers
formatted_used=$(format_num "$used_tokens")
formatted_total=$(format_num "$total_tokens")
formatted_input=$(format_num "$input_tokens")
formatted_output=$(format_num "$output_tokens")
formatted_cache=$(format_num "$cache_tokens")
short_model=$(shorten_model "$model_name")

# Load checkpoint state if available
CHECKPOINT_STATE="${HOME}/.claude/cache/checkpoint-state.json"
checkpoint_available=false
checkpoint_requested=false
checkpoint_pct=0

if [ -f "$CHECKPOINT_STATE" ]; then
    checkpoint_available=$(grep -o '"checkpoint_available"[[:space:]]*:[[:space:]]*[a-z]*' "$CHECKPOINT_STATE" | grep -o '[a-z]*' | tail -1)
    checkpoint_requested=$(grep -o '"checkpoint_requested"[[:space:]]*:[[:space:]]*[a-z]*' "$CHECKPOINT_STATE" | grep -o '[a-z]*' | tail -1)
    checkpoint_pct=$(grep -o '"last_checkpoint_percentage"[[:space:]]*:[[:space:]]*[0-9]*' "$CHECKPOINT_STATE" | grep -o '[0-9]*' | head -1)

    checkpoint_available=${checkpoint_available:-false}
    checkpoint_requested=${checkpoint_requested:-false}
    checkpoint_pct=${checkpoint_pct:-0}
fi

# Apply color coding and warnings based on usage percentage
used_pct_int=${used_pct%.*}
used_pct_int=${used_pct_int:-0}

# Determine status message based on usage and checkpoint state
if [ "$used_pct_int" -lt 60 ]; then
    color="\033[32m"  # Green
    warning=""
elif [ "$used_pct_int" -lt 80 ]; then
    color="\033[33m"  # Yellow
    warning=""
elif [ "$used_pct_int" -lt 85 ]; then
    color="\033[31m"  # Red
    warning=" ⚠️"
elif [ "$used_pct_int" -lt 90 ]; then
    # Between 85-90%: Request checkpoint if not already done
    color="\033[31m"  # Red
    if [ "$checkpoint_requested" = "true" ]; then
        warning=" 💾 Creating checkpoint..."
    elif [ "$checkpoint_available" = "true" ] && [ "$checkpoint_pct" -ge 80 ]; then
        warning=" ✅ Checkpoint saved at ${checkpoint_pct}%"
    else
        warning=" ⚠️ Checkpoint recommended"
        # Request checkpoint by updating state
        cat > "$CHECKPOINT_STATE" << EOF
{
  "last_checkpoint_time": 0,
  "last_checkpoint_percentage": 0,
  "checkpoint_requested": true,
  "checkpoint_available": false,
  "checkpoint_file": "",
  "last_check_time": $(date +%s)
}
EOF
    fi
elif [ "$used_pct_int" -lt 95 ]; then
    # Between 90-95%: Suggest /clear if checkpoint available
    color="\033[31m"  # Red
    if [ "$checkpoint_available" = "true" ] && [ "$checkpoint_pct" -ge 80 ]; then
        warning=" ✅ Checkpoint at ${checkpoint_pct}% - Safe to /clear"
    elif [ "$checkpoint_requested" = "true" ]; then
        warning=" 💾 Creating checkpoint... Consider /clear after"
    else
        warning=" 🔴 Checkpoint & /clear recommended"
    fi
else
    # 95%+: Urgent
    color="\033[31m\033[1m"  # Bold Red
    if [ "$checkpoint_available" = "true" ] && [ "$checkpoint_pct" -ge 80 ]; then
        warning=" 🟢 SAFE TO /clear (Checkpoint at ${checkpoint_pct}%)"
    else
        warning=" 🔴 CLEAR NOW!"
    fi
fi
reset="\033[0m"

# Output formatted status line with warnings
# Format: Context: 42.3% (84.7k/200k) | In: 12.5k | Out: 8.2k | Cache: 64.0k | S 4.5 [WARNING]
echo -e "${color}Context: ${used_pct}% (${formatted_used}/${formatted_total})${reset} | In: ${formatted_input} | Out: ${formatted_output} | Cache: ${formatted_cache} | ${short_model}${color}${warning}${reset}"
