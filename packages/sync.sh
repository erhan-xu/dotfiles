#!/bin/bash
# Sync package lists with currently installed packages
# This helps identify new packages to categorize or removed packages to clean up

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get currently installed packages
CURRENT_NATIVE=$(pacman -Qqen | sort)
CURRENT_AUR=$(pacman -Qqem | sort)

# Get tracked packages from category files (excluding aur.txt)
get_tracked_native() {
    for f in "$SCRIPT_DIR"/*.txt; do
        [[ "$(basename "$f")" == "aur.txt" ]] && continue
        grep -v '^#' "$f" 2>/dev/null | grep -v '^$'
    done | sort -u
}

get_tracked_aur() {
    grep -v '^#' "$SCRIPT_DIR/aur.txt" 2>/dev/null | grep -v '^$' | sort -u
}

TRACKED_NATIVE=$(get_tracked_native)
TRACKED_AUR=$(get_tracked_aur)

echo -e "${BLUE}=== Package Sync Report ===${NC}"
echo ""

# Find new packages (installed but not tracked)
echo -e "${GREEN}New native packages (not yet categorized):${NC}"
NEW_NATIVE=$(comm -23 <(echo "$CURRENT_NATIVE") <(echo "$TRACKED_NATIVE"))
if [[ -n "$NEW_NATIVE" ]]; then
    echo "$NEW_NATIVE" | while read pkg; do
        desc=$(pacman -Qi "$pkg" 2>/dev/null | grep "Description" | cut -d: -f2 | xargs)
        echo "  $pkg - $desc"
    done
else
    echo "  (none)"
fi
echo ""

echo -e "${GREEN}New AUR packages (not yet tracked):${NC}"
NEW_AUR=$(comm -23 <(echo "$CURRENT_AUR") <(echo "$TRACKED_AUR"))
if [[ -n "$NEW_AUR" ]]; then
    echo "$NEW_AUR" | while read pkg; do
        desc=$(pacman -Qi "$pkg" 2>/dev/null | grep "Description" | cut -d: -f2 | xargs)
        echo "  $pkg - $desc"
    done
else
    echo "  (none)"
fi
echo ""

# Find removed packages (tracked but not installed)
echo -e "${YELLOW}Native packages tracked but not installed:${NC}"
REMOVED_NATIVE=$(comm -13 <(echo "$CURRENT_NATIVE") <(echo "$TRACKED_NATIVE"))
if [[ -n "$REMOVED_NATIVE" ]]; then
    echo "$REMOVED_NATIVE"
else
    echo "  (none)"
fi
echo ""

echo -e "${YELLOW}AUR packages tracked but not installed:${NC}"
REMOVED_AUR=$(comm -13 <(echo "$CURRENT_AUR") <(echo "$TRACKED_AUR"))
if [[ -n "$REMOVED_AUR" ]]; then
    echo "$REMOVED_AUR"
else
    echo "  (none)"
fi
echo ""

# Summary
NATIVE_COUNT=$(echo "$CURRENT_NATIVE" | wc -l)
AUR_COUNT=$(echo "$CURRENT_AUR" | wc -l)
TRACKED_NATIVE_COUNT=$(echo "$TRACKED_NATIVE" | grep -c . || echo 0)
TRACKED_AUR_COUNT=$(echo "$TRACKED_AUR" | grep -c . || echo 0)
NEW_NATIVE_COUNT=$(echo "$NEW_NATIVE" | grep -c . || echo 0)
NEW_AUR_COUNT=$(echo "$NEW_AUR" | grep -c . || echo 0)

echo -e "${BLUE}=== Summary ===${NC}"
echo "Currently installed: $NATIVE_COUNT native, $AUR_COUNT AUR"
echo "Tracked in lists: $TRACKED_NATIVE_COUNT native, $TRACKED_AUR_COUNT AUR"
echo "New to categorize: $NEW_NATIVE_COUNT native, $NEW_AUR_COUNT AUR"
