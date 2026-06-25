#!/usr/bin/env bash
set -euo pipefail

old_clip="$(pbpaste 2>/dev/null || true)"

osascript -e 'tell application "System Events" to keystroke "c" using command down' >/dev/null 2>&1 || true
sleep 0.15

text="$(pbpaste 2>/dev/null || true)"
printf '%s' "$old_clip" | pbcopy

text="$(printf '%s' "$text" | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"

if [ -z "$text" ]; then
  osascript -e 'display notification "No text selected" with title "Translator"'
  exit 1
fi

if command -v trans >/dev/null 2>&1; then
  translation="$(trans -e bing -b -no-ansi :zh "$text" 2>/dev/null || true)"
  if [ -z "$translation" ]; then
    translation="Translation failed"
  fi
  osascript - "$translation" "$text" <<'OSA'
on run argv
  set translation to item 1 of argv
  set sourceText to item 2 of argv
  if (length of translation) > 240 then set translation to text 1 thru 240 of translation
  if (length of sourceText) > 80 then set sourceText to text 1 thru 80 of sourceText
  display notification translation with title "Translator" subtitle sourceText
end run
OSA
  exit 0
fi

if command -v python3 >/dev/null 2>&1; then
  encoded="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1]))' "$text")"
elif command -v ruby >/dev/null 2>&1; then
  encoded="$(ruby -ruri -e 'puts URI.encode_www_form_component(ARGV[0])' "$text")"
else
  encoded=""
fi

if [ -n "$encoded" ]; then
  open "https://translate.google.com/?sl=auto&tl=zh-CN&text=${encoded}&op=translate"
else
  open "https://translate.google.com/?sl=auto&tl=zh-CN&op=translate"
fi
