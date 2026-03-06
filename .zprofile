#!/usr/bin/env zsh

# Homebrew (conditional)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Add ~/bin and ~/.local/bin to PATH
[[ -d "${HOME}/bin" ]] && export PATH="${HOME}/bin:${PATH}"
[[ -d "${HOME}/.local/bin" ]] && export PATH="${HOME}/.local/bin:${PATH}"

# Cargo env (conditional)
[ -f "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"
