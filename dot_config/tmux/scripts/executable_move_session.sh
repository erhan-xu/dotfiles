#!/bin/bash
# Move current session left or right in the ordering.
DIRECTION="${1:-right}"
python3 ~/.config/tmux/scripts/session_manager.py swap "$DIRECTION"
