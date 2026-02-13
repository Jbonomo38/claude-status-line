#!/bin/bash

# Checkpoint Daemon Control Script
# Start, stop, or check status of the checkpoint daemon

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_SCRIPT="$SCRIPT_DIR/checkpoint-daemon.sh"
PID_FILE="${HOME}/.claude/cache/checkpoint-daemon.pid"
LOG_FILE="${HOME}/.claude/cache/checkpoint-daemon.log"

start_daemon() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "⚠️  Checkpoint daemon is already running (PID: $pid)"
            return 1
        else
            echo "🧹 Cleaning up stale PID file..."
            rm -f "$PID_FILE"
        fi
    fi

    echo "🚀 Starting checkpoint daemon..."
    nohup "$DAEMON_SCRIPT" > "$LOG_FILE" 2>&1 &
    sleep 1

    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        echo "✅ Checkpoint daemon started (PID: $pid)"
        echo "📝 Logs: $LOG_FILE"
    else
        echo "❌ Failed to start checkpoint daemon"
        return 1
    fi
}

stop_daemon() {
    if [ ! -f "$PID_FILE" ]; then
        echo "⚠️  Checkpoint daemon is not running"
        return 1
    fi

    pid=$(cat "$PID_FILE")
    if ps -p "$pid" > /dev/null 2>&1; then
        echo "🛑 Stopping checkpoint daemon (PID: $pid)..."
        kill "$pid"
        sleep 1

        if ps -p "$pid" > /dev/null 2>&1; then
            echo "⚠️  Process still running, forcing stop..."
            kill -9 "$pid"
        fi

        rm -f "$PID_FILE"
        echo "✅ Checkpoint daemon stopped"
    else
        echo "⚠️  Process not found, cleaning up PID file..."
        rm -f "$PID_FILE"
    fi
}

status_daemon() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo "✅ Checkpoint daemon is running (PID: $pid)"
            echo ""
            echo "Recent logs:"
            tail -n 5 "$LOG_FILE" 2>/dev/null || echo "No logs available"
            return 0
        else
            echo "❌ Checkpoint daemon is not running (stale PID file)"
            return 1
        fi
    else
        echo "❌ Checkpoint daemon is not running"
        return 1
    fi
}

case "${1:-}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 1
        start_daemon
        ;;
    status)
        status_daemon
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the checkpoint daemon"
        echo "  stop    - Stop the checkpoint daemon"
        echo "  restart - Restart the checkpoint daemon"
        echo "  status  - Check daemon status"
        exit 1
        ;;
esac
