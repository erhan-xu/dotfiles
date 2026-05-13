#!/bin/bash

# Smart Translator: select text, press SUPER+D to translate

# 1. Get selected text: try primary selection first, then clipboard
text=$(wl-paste --primary --no-newline 2>/dev/null)

if [ -z "$text" ]; then
  text=$(wl-paste --no-newline 2>/dev/null)
fi

# If still empty, exit
if [ -z "$text" ] || [[ "$text" =~ ^[[:space:]]*$ ]]; then
  notify-send -u normal -a "Translator" "No text selected"
  exit 1
fi

# Trim whitespace
text=$(echo "$text" | xargs)

# 2. Translation logic
translation=""
char_count=$(echo -n "$text" | wc -m)

if [ "$char_count" -le 20 ]; then
  # Short text: try offline dictionary first
  sdcv_result=$(sdcv -n "$text" 2>/dev/null)

  if [[ "$sdcv_result" == *"Nothing similar to"* ]] || [[ -z "$sdcv_result" ]]; then
    translation=$(trans -e bing -b -no-ansi :zh "$text" 2>/dev/null)
  else
    translation=$(echo "$sdcv_result" | sed '1d' | sed 's/^-->//' | head -n 20)
  fi
else
  # Long text: online translation
  translation=$(trans -e bing -b -no-ansi :zh "$text" 2>/dev/null)
fi

if [ -z "$translation" ]; then
  translation="Translation failed"
fi

# 3. Show result
notify-send -u normal -a "Translator" -- "$text" "$translation"
