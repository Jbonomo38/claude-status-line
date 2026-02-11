#!/bin/bash

# Status line script for Claude Code
# Displays real-time context window usage with detailed token breakdown

# Read JSON input from stdin
status_input=$(cat)

# Parse JSON fields using grep/sed (no jq dependency)
total_tokens=$(echo "$status_input" | grep -o '"context_window_size"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)
model_name=$(echo "$status_input" | grep -o '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*:\s*"\([^"]*\)".*/\1/')

# Parse session totals (total_input_tokens and total_output_tokens)
total_input=$(echo "$status_input" | grep -o '"total_input_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)
total_output=$(echo "$status_input" | grep -o '"total_output_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)

# Calculate used tokens from session totals
total_input=${total_input:-0}
total_output=${total_output:-0}
used_tokens=$((total_input + total_output))

# Parse cache tokens (session total)
cache_tokens=$(echo "$status_input" | grep -o '"total_cache_read_input_tokens"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*' | head -1)

# Set default values if parsing fails
used_tokens=${used_tokens:-0}
total_tokens=${total_tokens:-200000}
model_name=${model_name:-"Claude"}
cache_tokens=${cache_tokens:-0}

# Use session totals for display (these match the percentage calculation)
input_tokens=$total_input
output_tokens=$total_output

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

# Apply color coding based on usage percentage
# Green: < 50%, Yellow: 50-80%, Red: > 80%
used_pct_int=${used_pct%.*}
used_pct_int=${used_pct_int:-0}

if [ "$used_pct_int" -lt 50 ]; then
    color="\033[32m"  # Green
elif [ "$used_pct_int" -lt 80 ]; then
    color="\033[33m"  # Yellow
else
    color="\033[31m"  # Red
fi
reset="\033[0m"

# Output formatted status line
# Format: Context: 42.3% (84.7k/200k) | In: 12.5k | Out: 8.2k | Cache: 64.0k | S 4.5
echo -e "${color}Context: ${used_pct}% (${formatted_used}/${formatted_total})${reset} | In: ${formatted_input} | Out: ${formatted_output} | Cache: ${formatted_cache} | ${short_model}"
