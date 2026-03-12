#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

# Shared shell bootstrap (bash + zsh)
[ -f "${HOME}/.shell_shared" ] && source "${HOME}/.shell_shared"

# Shell options
shopt -s nocaseglob   # Case-insensitive globbing
shopt -s histappend   # Append to history, don't overwrite
shopt -s cdspell      # Autocorrect typos in cd paths

for option in autocd globstar; do
  shopt -s "$option" 2>/dev/null
done

# Bash completion
if command -v brew &>/dev/null; then
  brew_prefix="$(brew --prefix)"
  [ -r "${brew_prefix}/etc/profile.d/bash_completion.sh" ] && source "${brew_prefix}/etc/profile.d/bash_completion.sh"
  [ -f "${brew_prefix}/etc/bash_completion" ] && source "${brew_prefix}/etc/bash_completion"
  unset brew_prefix
elif [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
fi

# SSH hostname tab completion
[ -e "${HOME}/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# Terraform completion (conditional)
command -v terraform &>/dev/null && complete -C "$(command -v terraform)" terraform

# History: flush to file after every command
PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND};}history -a"

# Silence macOS bash deprecation warning
export BASH_SILENCE_DEPRECATION_WARNING=1

