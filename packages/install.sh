#!/bin/bash
# Arch Linux package installer
# Usage: ./install.sh [category...] or ./install.sh --all

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Available categories
CATEGORIES=(
    "base"
    "network"
    "shell"
    "terminal"
    "editors"
    "cli-tools"
    "desktop-hyprland"
    "desktop-niri"
    "file-manager"
    "fonts"
    "audio"
    "bluetooth"
    "input-method"
    "gpu-amd"
    "power"
    "utilities"
    "virtualization"
    "apps-browser"
    "apps-office"
    "apps-media"
    "apps-communication"
    "apps-gaming"
    "dev-core"
    "dev-python"
    "dev-r"
    "dev-cross"
    "aur"
)

# Profiles (predefined category sets)
declare -A PROFILES
PROFILES[minimal]="base network shell terminal editors cli-tools"
PROFILES[desktop]="base network shell terminal editors cli-tools desktop-hyprland file-manager fonts audio bluetooth input-method gpu-amd power utilities"
PROFILES[full]="base network shell terminal editors cli-tools desktop-hyprland file-manager fonts audio bluetooth input-method gpu-amd power utilities virtualization apps-browser apps-office apps-media apps-communication dev-core"

show_help() {
    echo -e "${BLUE}Arch Linux Package Installer${NC}"
    echo ""
    echo "Usage: $0 [options] [categories...]"
    echo ""
    echo "Options:"
    echo "  --all           Install all categories"
    echo "  --aur           Include AUR packages (requires yay)"
    echo "  --profile NAME  Use a predefined profile (minimal, desktop, full)"
    echo "  --list          List available categories"
    echo "  --dry-run       Show what would be installed without installing"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 base shell cli-tools              # Install specific categories"
    echo "  $0 --profile desktop                 # Install desktop profile"
    echo "  $0 --profile desktop --aur           # Desktop profile + AUR packages"
    echo "  $0 --all                             # Install everything"
}

list_categories() {
    echo -e "${BLUE}Available categories:${NC}"
    for cat in "${CATEGORIES[@]}"; do
        if [[ -f "$SCRIPT_DIR/$cat.txt" ]]; then
            count=$(grep -v '^#' "$SCRIPT_DIR/$cat.txt" | grep -v '^$' | wc -l)
            echo -e "  ${GREEN}$cat${NC} ($count packages)"
        fi
    done
    echo ""
    echo -e "${BLUE}Profiles:${NC}"
    for profile in "${!PROFILES[@]}"; do
        echo -e "  ${YELLOW}$profile${NC}: ${PROFILES[$profile]}"
    done
}

get_packages() {
    local file="$SCRIPT_DIR/$1.txt"
    if [[ -f "$file" ]]; then
        grep -v '^#' "$file" | grep -v '^$'
    fi
}

install_native() {
    local packages=("$@")
    if [[ ${#packages[@]} -gt 0 ]]; then
        echo -e "${GREEN}Installing ${#packages[@]} native packages...${NC}"
        sudo pacman -S --needed "${packages[@]}"
    fi
}

install_aur() {
    local packages=("$@")
    if [[ ${#packages[@]} -gt 0 ]]; then
        if command -v yay &> /dev/null; then
            echo -e "${GREEN}Installing ${#packages[@]} AUR packages with yay...${NC}"
            yay -S --needed "${packages[@]}"
        elif command -v paru &> /dev/null; then
            echo -e "${GREEN}Installing ${#packages[@]} AUR packages with paru...${NC}"
            paru -S --needed "${packages[@]}"
        else
            echo -e "${RED}No AUR helper found. Install yay or paru first.${NC}"
            echo "Packages to install manually: ${packages[*]}"
            return 1
        fi
    fi
}

# Parse arguments
SELECTED_CATS=()
INCLUDE_AUR=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --list)
            list_categories
            exit 0
            ;;
        --all)
            SELECTED_CATS=("${CATEGORIES[@]}")
            INCLUDE_AUR=true
            shift
            ;;
        --aur)
            INCLUDE_AUR=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --profile)
            if [[ -n "${PROFILES[$2]}" ]]; then
                read -ra SELECTED_CATS <<< "${PROFILES[$2]}"
            else
                echo -e "${RED}Unknown profile: $2${NC}"
                exit 1
            fi
            shift 2
            ;;
        *)
            SELECTED_CATS+=("$1")
            shift
            ;;
    esac
done

if [[ ${#SELECTED_CATS[@]} -eq 0 ]]; then
    show_help
    exit 1
fi

# Collect packages
NATIVE_PKGS=()
AUR_PKGS=()

for cat in "${SELECTED_CATS[@]}"; do
    if [[ "$cat" == "aur" ]]; then
        if $INCLUDE_AUR; then
            while IFS= read -r pkg; do
                AUR_PKGS+=("$pkg")
            done < <(get_packages "aur")
        fi
    else
        while IFS= read -r pkg; do
            NATIVE_PKGS+=("$pkg")
        done < <(get_packages "$cat")
    fi
done

# Remove duplicates
NATIVE_PKGS=($(printf "%s\n" "${NATIVE_PKGS[@]}" | sort -u))
AUR_PKGS=($(printf "%s\n" "${AUR_PKGS[@]}" | sort -u))

echo -e "${BLUE}=== Package Installation Summary ===${NC}"
echo -e "Native packages: ${#NATIVE_PKGS[@]}"
echo -e "AUR packages: ${#AUR_PKGS[@]}"
echo ""

if $DRY_RUN; then
    echo -e "${YELLOW}[DRY RUN] Would install:${NC}"
    echo -e "${GREEN}Native:${NC} ${NATIVE_PKGS[*]}"
    if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
        echo -e "${GREEN}AUR:${NC} ${AUR_PKGS[*]}"
    fi
    exit 0
fi

# Install
if [[ ${#NATIVE_PKGS[@]} -gt 0 ]]; then
    install_native "${NATIVE_PKGS[@]}"
fi

if [[ ${#AUR_PKGS[@]} -gt 0 ]] && $INCLUDE_AUR; then
    install_aur "${AUR_PKGS[@]}"
fi

echo -e "${GREEN}Done!${NC}"
