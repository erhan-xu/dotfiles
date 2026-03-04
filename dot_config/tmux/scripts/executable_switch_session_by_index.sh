#!/bin/bash
# Switch to the tmux session whose name starts with the given index.
TARGET="$1"
SESSION=$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep "^${TARGET}-" | head -1)
if [ -n "$SESSION" ]; then
    tmux switch-client -t "$SESSION"
fi
