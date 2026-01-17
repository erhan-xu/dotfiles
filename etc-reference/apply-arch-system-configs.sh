#!/bin/bash
# Apply Arch Linux system configurations
# Run with: sudo ./apply-arch-system-configs.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)"
    exit 1
fi

echo "This will overwrite system configs in /etc/"
echo "Files to be replaced:"
echo "  - /etc/pacman.conf"
echo "  - /etc/environment"
echo "  - /etc/locale.conf"
echo "  - /etc/mkinitcpio.conf"
echo "  - /etc/ly/config.ini"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# Backup existing configs
BACKUP_DIR="/etc/backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp /etc/pacman.conf "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/environment "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/locale.conf "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/mkinitcpio.conf "$BACKUP_DIR/" 2>/dev/null || true
cp /etc/ly/config.ini "$BACKUP_DIR/" 2>/dev/null || true
echo "Backed up existing configs to $BACKUP_DIR"

# Apply configs
cp "$SCRIPT_DIR/pacman.conf" /etc/pacman.conf
cp "$SCRIPT_DIR/environment" /etc/environment
cp "$SCRIPT_DIR/locale.conf" /etc/locale.conf
cp "$SCRIPT_DIR/mkinitcpio.conf" /etc/mkinitcpio.conf
mkdir -p /etc/ly
cp "$SCRIPT_DIR/ly/config.ini" /etc/ly/config.ini

echo "Done! You may need to:"
echo "  - Run 'sudo pacman-key --populate archlinuxcn' for archlinuxcn repo"
echo "  - Run 'sudo mkinitcpio -P' to regenerate initramfs"
echo "  - Run 'sudo systemctl enable ly' to enable ly display manager"
