#!/usr/bin/env zsh

# Shared shell bootstrap (bash + zsh)
if [ -f "${HOME}/.shell_shared" ]; then
  source "${HOME}/.shell_shared"
else
  echo "[WARN] ~/.shell_shared not found. Run install.sh to set up dotfiles." >&2
fi

# --- Zsh options ---
setopt NO_CASE_GLOB       # Case-insensitive globbing
setopt APPEND_HISTORY     # Append to history, don't overwrite
setopt SHARE_HISTORY      # Share history across sessions
setopt HIST_IGNORE_DUPS   # Skip duplicate history entries
setopt CORRECT            # Autocorrect typos in cd paths
setopt AUTO_CD            # cd into directories by typing the name
setopt EXTENDED_GLOB      # Extended globbing (#, ~, ^ operators)

# --- Keybindings ---
bindkey -e  # Emacs mode (Ctrl-A, Ctrl-E, Ctrl-K, etc.)

# Home / End / Delete keys (terminal-aware via terminfo)
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}"  ]] && bindkey "${terminfo[kend]}"  end-of-line
[[ -n "${terminfo[kdch1]}" ]] && bindkey "${terminfo[kdch1]}" delete-char

# --- Completion system ---
autoload -Uz compinit && compinit

# kubectl completion
command -v kubectl &>/dev/null && source <(kubectl completion zsh)

# gcloud completion
if command -v brew &>/dev/null; then
  local gcloud_inc="$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
  [ -f "$gcloud_inc" ] && source "$gcloud_inc"
fi

# SSH hostname tab completion
if [ -e "${HOME}/.ssh/config" ]; then
  local ssh_hosts
  ssh_hosts=($(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2))
  zstyle ':completion:*:(scp|sftp|ssh):*' hosts $ssh_hosts
fi

# Terraform completion
if command -v terraform &>/dev/null; then
  autoload -U +X bashcompinit && bashcompinit
  complete -C "$(command -v terraform)" terraform
fi

# --- Zsh plugins ---

# Autosuggestions (fish-like inline history suggestions)
if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Syntax highlighting (must be sourced last)
if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
