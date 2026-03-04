# Research workflow shell functions
# Source: ~/Downloads/tracker/CLAUDE.md

# Quick task creation
rtask() {
    local slug="$(date +%H%M)-$(echo "$1" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 50)"
    local type="${2:-general}"
    local priority="${3:-medium}"
    local file="tasks/${slug}.yaml"
    mkdir -p tasks
    cat > "$file" << EOF
id: ${slug}
type: ${type}
status: pending
priority: ${priority}
description: |
  $1
context: []
depends_on: []
created: $(date -Iseconds)
EOF
    echo "Created $file"
    ${EDITOR:-nvim} "$file"
}

# Quick idea capture
idea() {
    local slug="$(date +%Y-%m-%d)-$(echo "$*" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | head -c 50)"
    local file="$HOME/research/ideas/${slug}.md"
    mkdir -p "$HOME/research/ideas"
    cat > "$file" << EOF
---
id: ${slug}
status: raw
created: $(date +%Y-%m-%d)
project: null
tags: []
---

# $*

## Intuition


## Minimum Viable Question


## References

EOF
    ${EDITOR:-nvim} "$file"
}

# Browse ideas by status
ideas() {
    find ~/research/ideas -name "*.md" -exec grep -l "status: ${1:-raw}" {} \; | \
        while read f; do
            title=$(grep "^# " "$f" | head -1 | sed 's/^# //')
            status=$(grep "^status:" "$f" | head -1 | awk '{print $2}')
            printf "%s\t%s\t%s\n" "$status" "$title" "$f"
        done | \
        fzf --delimiter='\t' --with-nth=1,2 --preview 'cat {3}' | \
        cut -f3 | xargs -r ${EDITOR:-nvim}
}

# Claude Code launcher — auto-injects CLAUDE.md + PROGRESS.md
cl() {
    local extra_args=(--dangerously-skip-permissions)
    if [ -f "CLAUDE.md" ]; then
        extra_args+=(--append-system-prompt "$(cat CLAUDE.md)")
    fi
    if [ -f "PROGRESS.md" ]; then
        extra_args+=(--append-system-prompt "## Current PROGRESS.md
$(tail -100 PROGRESS.md)")
    fi
    claude "$@" "${extra_args[@]}"
}
