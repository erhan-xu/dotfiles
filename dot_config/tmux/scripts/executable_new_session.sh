#!/bin/bash
# Create a new tmux session with auto-numbered name.
LABEL="${1:-shell}"
INDEX=$(python3 ~/.config/tmux/scripts/session_manager.py next-index)
tmux new-session -d -s "${INDEX}-${LABEL}"
tmux switch-client -t "${INDEX}-${LABEL}"
