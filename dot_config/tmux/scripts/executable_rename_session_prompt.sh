#!/bin/bash
# Rename current session, preserving its index prefix.
NEW_LABEL="$1"
if [ -n "$NEW_LABEL" ]; then
    python3 ~/.config/tmux/scripts/session_manager.py rename "$NEW_LABEL"
fi
