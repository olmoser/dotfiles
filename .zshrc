#!/usr/bin/env zsh

# Load shared dotfiles (same files as bash)
for file in ~/.{path,exports,aliases,functions,extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

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

# --- pyenv (conditional) ---
if command -v pyenv &>/dev/null; then
  export PYENV_ROOT="${HOME}/.pyenv"
  case ":${PATH}:" in
    *":${PYENV_ROOT}/bin:"*) ;;
    *) export PATH="${PYENV_ROOT}/bin:${PATH}" ;;
  esac
  eval "$(pyenv init -)"
  command -v pyenv-virtualenv-init &>/dev/null && eval "$(pyenv virtualenv-init -)"
fi

# --- Go paths (conditional) ---
if command -v go &>/dev/null; then
  [ -n "$GOROOT" ] && export PATH="${GOROOT}/bin:${PATH}"
  [ -n "$GOPATH" ] && export PATH="${PATH}:${GOPATH}/bin"
fi

# --- Cargo env (conditional) ---
[ -f "${HOME}/.cargo/env" ] && source "${HOME}/.cargo/env"

# --- Modern shell tools ---

# Starship prompt
command -v starship &>/dev/null && eval "$(starship init zsh)"

# Zoxide (smart cd)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd j)"

# Skim keybindings
if command -v sk &>/dev/null; then
  for sk_bindings in \
    "$(brew --prefix 2>/dev/null)/opt/sk/share/skim/completion.zsh" \
    "$(brew --prefix 2>/dev/null)/opt/sk/share/skim/key-bindings.zsh" \
    "${HOME}/.skim/shell/completion.zsh" \
    "${HOME}/.skim/shell/key-bindings.zsh" \
    "/usr/share/skim/completion.zsh" \
    "/usr/share/skim/key-bindings.zsh"; do
    [ -f "$sk_bindings" ] && source "$sk_bindings"
  done
  unset sk_bindings
fi

# fzf fuzzy search
command -v fzf &>/dev/null && eval "$(fzf --zsh)"

# --- Zsh plugins (brew-installed) ---

# Autosuggestions (fish-like inline history suggestions)
if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Syntax highlighting (must be sourced last)
if [ -f "$(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
