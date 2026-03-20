#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

# Shell options
shopt -s nocaseglob   # Case-insensitive globbing
shopt -s histappend   # Append to history, don't overwrite
shopt -s cdspell      # Autocorrect typos in cd paths

for option in autocd globstar; do
  shopt -s "$option" 2>/dev/null
done

# Homebrew (must be early — bash completion and .shell_shared depend on it)
if [ -f /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Bash completion (must be before .shell_shared — tools there register completions)
if command -v brew &>/dev/null; then
  brew_prefix="$(brew --prefix)"
  [ -r "${brew_prefix}/etc/profile.d/bash_completion.sh" ] && source "${brew_prefix}/etc/profile.d/bash_completion.sh"
  [ -f "${brew_prefix}/etc/bash_completion" ] && source "${brew_prefix}/etc/bash_completion"
  unset brew_prefix
elif [ -f /etc/bash_completion ]; then
  source /etc/bash_completion
fi

# Shared shell bootstrap (bash + zsh)
if [ -f "${HOME}/.shell_shared" ]; then
  source "${HOME}/.shell_shared"
else
  echo "[WARN] ~/.shell_shared not found. Run install.sh to set up dotfiles." >&2
fi

# SSH hostname tab completion
[ -e "${HOME}/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# Terraform completion (conditional)
command -v terraform &>/dev/null && complete -C "$(command -v terraform)" terraform

# History: flush to file after every command
# Report CWD to terminal via OSC 7 (enables new tab/split in same directory)
__report_cwd() {
  local encoded
  encoded="$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe='/'))" "$PWD" 2>/dev/null)" || encoded="$PWD"
  # shellcheck disable=SC1003
  printf '\e]7;file://%s%s\e\\' "${HOSTNAME}" "${encoded}"
}
PROMPT_COMMAND="${PROMPT_COMMAND:+${PROMPT_COMMAND};}history -a;__report_cwd"

# Silence macOS bash deprecation warning
export BASH_SILENCE_DEPRECATION_WARNING=1

# fzf — must be after bash completion to avoid Ctrl-R binding being overwritten
if [ -f "${HOME}/.fzf.bash" ]; then
  source "${HOME}/.fzf.bash"
elif command -v fzf &>/dev/null && fzf --bash >/dev/null 2>&1; then
  eval "$(fzf --bash)"
else
  echo "[WARN] fzf not found or too old (need >=0.48). No fzf keybindings." >&2
fi
