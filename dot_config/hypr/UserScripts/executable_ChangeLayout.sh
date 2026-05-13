#!/usr/bin/env bash
# Cycle Hyprland layouts: Dwindle → Master → Scrolling → Dwindle

notif="$HOME/.config/swaync/images/ja.png"

LAYOUT=$(hyprctl -j getoption general:layout | jq '.str' | sed 's/"//g')

setup_dwindle() {
  hyprctl keyword unbind SUPER,J
  hyprctl keyword unbind SUPER,K
  hyprctl keyword bind SUPER,J,cyclenext
  hyprctl keyword bind SUPER,K,cyclenext,prev
  hyprctl keyword bind SUPER,O,layoutmsg,togglesplit
}

setup_master() {
  hyprctl keyword unbind SUPER,J
  hyprctl keyword unbind SUPER,K
  hyprctl keyword unbind SUPER,O
  hyprctl keyword bind SUPER,J,layoutmsg,cyclenext
  hyprctl keyword bind SUPER,K,layoutmsg,cycleprev
}

setup_scrolling() {
  hyprctl keyword unbind SUPER,J
  hyprctl keyword unbind SUPER,K
  hyprctl keyword unbind SUPER,O
  hyprctl keyword bind SUPER,J,cyclenext
  hyprctl keyword bind SUPER,K,cyclenext,prev
}

# On init, set up keybinds for the CURRENT layout without toggling
if [ "$1" = "init" ]; then
  case $LAYOUT in
    "dwindle")   setup_dwindle ;;
    "master")    setup_master ;;
    "scrolling") setup_scrolling ;;
  esac
  exit 0
fi

# Cycle: dwindle → master → scrolling → dwindle
case $LAYOUT in
"dwindle")
  hyprctl keyword general:layout master
  setup_master
  notify-send -e -u low -i "$notif" "Master Layout"
  ;;
"master")
  hyprctl keyword general:layout scrolling
  setup_scrolling
  notify-send -e -u low -i "$notif" "Scrolling Layout"
  ;;
"scrolling")
  hyprctl keyword general:layout dwindle
  setup_dwindle
  notify-send -e -u low -i "$notif" "Dwindle Layout"
  ;;
*) ;;
esac
