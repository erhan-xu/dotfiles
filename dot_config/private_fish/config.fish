if status is-interactive
    # Commands to run in interactive sessions can go here
end

alias proxy "set -x https_proxy https://127.0.0.1:7897 &&
set -x http_proxy http://127.0.0.1:7897 &&
set -x all_proxy socks5://127.0.0.1:7897"

alias unproxy "set -e https_proxy &&
set -e http_proxy &&
set -e all_proxy"

thefuck --alias | source

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# keychain --eval --quiet ~/.ssh/beast_rsa | source

set -x PYENV_ROOT "$HOME/.pyenv"
fish_add_path "$PYENV_ROOT/bin"
pyenv init - | source
