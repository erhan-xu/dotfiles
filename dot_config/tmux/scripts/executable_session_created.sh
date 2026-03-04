#!/bin/bash
# Called by tmux session-created hook. Renumbers all sessions.
python3 ~/.config/tmux/scripts/session_manager.py renumber
