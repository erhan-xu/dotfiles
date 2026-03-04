#!/bin/bash
# Watch a pane — set @unread on its window when the running command finishes.
# Usage: watch_pane.sh <pane_id> <window_id>
PANE_ID="$1"
WINDOW_ID="$2"

# Mark as watching
tmux set -w -t "$WINDOW_ID" @watching 1
tmux refresh-client -S

# Poll until the pane's foreground process returns to shell
while true; do
    sleep 2
    CMD=$(tmux display-message -t "$PANE_ID" -p '#{pane_current_command}' 2>/dev/null)
    # If pane is gone, stop
    if [ -z "$CMD" ]; then
        break
    fi
    # If back to shell, command finished
    if [ "$CMD" = "zsh" ] || [ "$CMD" = "bash" ] || [ "$CMD" = "fish" ]; then
        tmux set -w -t "$WINDOW_ID" @unread 1
        break
    fi
done

# Clear watching flag
tmux set -wu -t "$WINDOW_ID" @watching 2>/dev/null
tmux refresh-client -S
