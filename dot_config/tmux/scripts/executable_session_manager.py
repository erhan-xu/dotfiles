#!/usr/bin/env python3
"""tmux session manager — auto-number sessions as {index}-{label}.

Usage:
    session_manager.py renumber          Renumber all sessions sequentially
    session_manager.py next-index        Print next available index
    session_manager.py rename <label>    Rename current session, preserve index
    session_manager.py swap <direction>  Swap current session left/right
"""

import subprocess
import sys


def tmux(*args: str) -> str:
    result = subprocess.run(
        ["tmux", *args], capture_output=True, text=True
    )
    return result.stdout.strip()


def list_sessions() -> list[tuple[str, str]]:
    """Return list of (full_name, id) for all sessions."""
    raw = tmux("list-sessions", "-F", "#{session_name}\t#{session_id}")
    if not raw:
        return []
    pairs = []
    for line in raw.splitlines():
        parts = line.split("\t")
        if len(parts) == 2:
            pairs.append((parts[0], parts[1]))
    return pairs


def parse_session_name(name: str) -> tuple[int | None, str]:
    """Parse '3-reader' into (3, 'reader'). Plain 'reader' returns (None, 'reader')."""
    if "-" in name:
        prefix, rest = name.split("-", 1)
        if prefix.isdigit():
            return int(prefix), rest
    return None, name


def renumber() -> None:
    """Renumber all sessions sequentially starting from 1."""
    sessions = list_sessions()
    if not sessions:
        return

    # Sort by existing index (indexed first), then alphabetically
    def sort_key(item: tuple[str, str]) -> tuple[int, int, str]:
        idx, label = parse_session_name(item[0])
        if idx is not None:
            return (0, idx, label)
        return (1, 0, item[0])

    sessions.sort(key=sort_key)

    for i, (name, sid) in enumerate(sessions, 1):
        _, label = parse_session_name(name)
        new_name = f"{i}-{label}"
        if name != new_name:
            tmux("rename-session", "-t", sid, new_name)


def next_index() -> int:
    """Return the next available session index."""
    sessions = list_sessions()
    if not sessions:
        return 1
    max_idx = 0
    for name, _ in sessions:
        idx, _ = parse_session_name(name)
        if idx is not None and idx > max_idx:
            max_idx = idx
    return max_idx + 1


def rename(new_label: str) -> None:
    """Rename current session, preserving its index."""
    current = tmux("display-message", "-p", "#{session_name}")
    idx, _ = parse_session_name(current)
    if idx is not None:
        tmux("rename-session", f"{idx}-{new_label}")
    else:
        tmux("rename-session", new_label)
    renumber()


def swap(direction: str) -> None:
    """Swap current session with neighbor in given direction (left/right)."""
    sessions = list_sessions()
    current = tmux("display-message", "-p", "#{session_name}")

    indexed = []
    for name, sid in sessions:
        idx, label = parse_session_name(name)
        if idx is not None:
            indexed.append((idx, label, sid))
    indexed.sort(key=lambda x: x[0])

    current_pos = None
    for i, (idx, label, sid) in enumerate(indexed):
        if f"{idx}-{label}" == current:
            current_pos = i
            break

    if current_pos is None:
        return

    if direction == "left" and current_pos > 0:
        swap_pos = current_pos - 1
    elif direction == "right" and current_pos < len(indexed) - 1:
        swap_pos = current_pos + 1
    else:
        return

    # Swap by renaming
    a_idx, a_label, a_sid = indexed[current_pos]
    b_idx, b_label, b_sid = indexed[swap_pos]
    tmux("rename-session", "-t", a_sid, f"{b_idx}-{a_label}")
    tmux("rename-session", "-t", b_sid, f"{a_idx}-{b_label}")


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "renumber":
        renumber()
    elif cmd == "next-index":
        print(next_index())
    elif cmd == "rename" and len(sys.argv) >= 3:
        rename(sys.argv[2])
    elif cmd == "swap" and len(sys.argv) >= 3:
        swap(sys.argv[2])
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
