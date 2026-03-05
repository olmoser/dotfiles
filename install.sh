#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN="${DRY_RUN:-false}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$1"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$1"; }
err()   { printf "${RED}[ERR]${NC}   %s\n" "$1" >&2; }

# --- OS Detection ---
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
          ubuntu|debian) echo "ubuntu" ;;
          *) err "Unsupported Linux distribution: $ID"; exit 1 ;;
        esac
      else
        err "Cannot detect Linux distribution"; exit 1
      fi
      ;;
    *) err "Unsupported OS: $(uname -s)"; exit 1 ;;
  esac
}

OS="$(detect_os)"
info "Detected OS: ${OS}"

# --- Dry run wrapper ---
run() {
  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] $*"
  else
    "$@"
  fi
}

# --- Package Manager Setup ---
install_homebrew() {
  if command -v brew &>/dev/null; then
    ok "Homebrew already installed"
    return
  fi
  info "Installing Homebrew..."
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

# --- Package Installation ---
BREW_PACKAGES=(
  starship
  sk        # skim
  ripgrep
  zoxide
  bat
  fd
  eza
  jq
  jqp       # jq playground
  jnv       # interactive JSON viewer
  yq        # YAML processor (like jq for YAML)
  git-delta
  shellcheck
  btop
  kubectl
  kubectx   # provides kubectx (kctx) and kubens (kns)
  nethogs
  pnpm
  uv
  tmux
  difftastic
  lazygit
  lazydocker
  dust      # modern du
  xh        # modern httpie/curl
)

BREW_CASKS=(
  hammerspoon
  rectangle
  google-cloud-sdk
)

APT_PACKAGES=(
  ripgrep
  bat
  fd-find
  jq
  shellcheck
  btop
  nethogs
  tmux
  yq
)

install_macos_packages() {
  install_homebrew

  # Source brew shellenv for this script
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  info "Installing brew packages..."
  for pkg in "${BREW_PACKAGES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      ok "${pkg} already installed"
    else
      info "Installing ${pkg}..."
      run brew install "$pkg"
    fi
  done

  info "Installing brew casks..."
  for cask in "${BREW_CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
      ok "${cask} already installed"
    else
      info "Installing ${cask}..."
      run brew install --cask "$cask"
    fi
  done
}

install_ubuntu_packages() {
  # Prompt for sudo upfront and keep it alive for the duration of the install
  if [ "$DRY_RUN" != "true" ]; then
    info "Requesting sudo access..."
    sudo -v
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
  fi

  info "Updating apt cache..."
  run sudo apt-get update -qq

  info "Installing apt packages..."
  for pkg in "${APT_PACKAGES[@]}"; do
    if dpkg -l "$pkg" &>/dev/null 2>&1; then
      ok "${pkg} already installed"
    else
      info "Installing ${pkg}..."
      run sudo apt-get install -y -qq "$pkg"
    fi
  done

  # starship (curl installer)
  if ! command -v starship &>/dev/null; then
    info "Installing starship..."
    run sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes
  else
    ok "starship already installed"
  fi

  # zoxide (curl installer)
  if ! command -v zoxide &>/dev/null; then
    info "Installing zoxide..."
    run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)"
  else
    ok "zoxide already installed"
  fi

  # eza (via cargo or apt on newer Ubuntu)
  if ! command -v eza &>/dev/null; then
    if apt-cache show eza &>/dev/null 2>&1; then
      info "Installing eza via apt..."
      run sudo apt-get install -y -qq eza
    else
      warn "eza not available in apt. Install manually or via cargo: cargo install eza"
    fi
  else
    ok "eza already installed"
  fi

  # skim (via cargo)
  if ! command -v sk &>/dev/null; then
    if command -v cargo &>/dev/null; then
      info "Installing skim via cargo..."
      run cargo install skim
    else
      warn "skim requires cargo. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi
  else
    ok "skim already installed"
  fi

  # git-delta
  if ! command -v delta &>/dev/null; then
    if apt-cache show git-delta &>/dev/null 2>&1; then
      info "Installing git-delta via apt..."
      run sudo apt-get install -y -qq git-delta
    else
      warn "git-delta not available in apt. Install manually: https://github.com/dandavison/delta/releases"
    fi
  else
    ok "git-delta already installed"
  fi

  # kubectl
  if ! command -v kubectl &>/dev/null; then
    info "Installing kubectl..."
    run sh -c 'curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl && rm /tmp/kubectl'
  else
    ok "kubectl already installed"
  fi

  # kubectx + kubens
  if ! command -v kubectx &>/dev/null; then
    if apt-cache show kubectx &>/dev/null 2>&1; then
      info "Installing kubectx via apt..."
      run sudo apt-get install -y -qq kubectx
    else
      warn "kubectx not available in apt. Install manually: https://github.com/ahmetb/kubectx/releases"
    fi
  else
    ok "kubectx already installed"
  fi

  # jnv (via cargo)
  if ! command -v jnv &>/dev/null; then
    if command -v cargo &>/dev/null; then
      info "Installing jnv via cargo..."
      run cargo install jnv
    else
      warn "jnv requires cargo. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi
  else
    ok "jnv already installed"
  fi

  # pnpm
  if ! command -v pnpm &>/dev/null; then
    info "Installing pnpm..."
    run sh -c 'curl -fsSL https://get.pnpm.io/install.sh | sh -'
  else
    ok "pnpm already installed"
  fi

  # uv
  if ! command -v uv &>/dev/null; then
    info "Installing uv..."
    run sh -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
  else
    ok "uv already installed"
  fi

  # difftastic
  if ! command -v difft &>/dev/null; then
    if command -v cargo &>/dev/null; then
      info "Installing difftastic via cargo..."
      run cargo install difftastic
    else
      warn "difftastic requires cargo. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi
  else
    ok "difftastic already installed"
  fi

  # Google Cloud SDK
  if ! command -v gcloud &>/dev/null; then
    info "Installing Google Cloud SDK..."
    run sh -c 'curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts'
  else
    ok "gcloud already installed"
  fi

  # lazygit
  if ! command -v lazygit &>/dev/null; then
    info "Installing lazygit..."
    run sh -c 'LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | jq -r .tag_name | sed "s/v//") && curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && tar xzf /tmp/lazygit.tar.gz -C /tmp lazygit && sudo install /tmp/lazygit /usr/local/bin && rm /tmp/lazygit /tmp/lazygit.tar.gz'
  else
    ok "lazygit already installed"
  fi

  # lazydocker
  if ! command -v lazydocker &>/dev/null; then
    info "Installing lazydocker..."
    run sh -c 'curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash'
  else
    ok "lazydocker already installed"
  fi

  # dust (via cargo)
  if ! command -v dust &>/dev/null; then
    if command -v cargo &>/dev/null; then
      info "Installing dust via cargo..."
      run cargo install du-dust
    else
      warn "dust requires cargo. Install Rust first."
    fi
  else
    ok "dust already installed"
  fi

  # xh (via cargo)
  if ! command -v xh &>/dev/null; then
    if command -v cargo &>/dev/null; then
      info "Installing xh via cargo..."
      run cargo install xh
    else
      warn "xh requires cargo. Install Rust first."
    fi
  else
    ok "xh already installed"
  fi

  # fd is named fd-find on Ubuntu, create symlink if needed
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    info "Creating fd symlink for fd-find..."
    run sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi

  # bat is named batcat on Ubuntu, create symlink if needed
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    info "Creating bat symlink for batcat..."
    run sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
  fi
}

# --- Claude Code ---
install_claude_code() {
  if command -v claude &>/dev/null; then
    ok "Claude Code already installed"
    return
  fi
  if command -v npm &>/dev/null; then
    info "Installing Claude Code via npm..."
    run npm install -g @anthropic-ai/claude-code
  elif command -v pnpm &>/dev/null; then
    info "Installing Claude Code via pnpm..."
    run pnpm install -g @anthropic-ai/claude-code
  else
    warn "Claude Code requires npm or pnpm. Install Node.js first."
  fi
}

# --- btop catppuccin theme ---
install_btop_theme() {
  local theme_dir="${HOME}/.config/btop/themes"
  if [ -d "${theme_dir}/catppuccin" ]; then
    ok "Catppuccin btop theme already installed"
    return
  fi
  info "Installing Catppuccin btop theme..."
  run mkdir -p "${theme_dir}"
  run git clone --depth 1 https://github.com/catppuccin/btop.git /tmp/catppuccin-btop
  if [ "$DRY_RUN" != "true" ]; then
    cp -r /tmp/catppuccin-btop/themes "${theme_dir}/catppuccin"
    rm -rf /tmp/catppuccin-btop
  fi
  ok "Catppuccin btop theme installed to ${theme_dir}/catppuccin"
}

# --- Starship theme selection ---
select_starship_theme() {
  local gruvbox="${DOTFILES_DIR}/starship.toml"
  local simple="${DOTFILES_DIR}/starship-simple.toml"

  if [ ! -f "$simple" ]; then
    STARSHIP_CONFIG="$gruvbox"
    return
  fi

  if [ -n "${STARSHIP_THEME:-}" ]; then
    case "$STARSHIP_THEME" in
      gruvbox) STARSHIP_CONFIG="$gruvbox" ;;
      simple)  STARSHIP_CONFIG="$simple" ;;
      *)       warn "Unknown STARSHIP_THEME='${STARSHIP_THEME}', defaulting to gruvbox"; STARSHIP_CONFIG="$gruvbox" ;;
    esac
    return
  fi

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would prompt for starship theme selection (default: gruvbox)"
    STARSHIP_CONFIG="$gruvbox"
    return
  fi

  echo ""
  info "Select starship prompt theme:"
  echo "  1) gruvbox  — powerline with nerd font icons, git metrics, battery (default)"
  echo "  2) simple   — minimal single-line prompt"
  echo ""
  read -rp "Choice [1]: " choice
  case "${choice:-1}" in
    2) STARSHIP_CONFIG="$simple"; ok "Using simple theme" ;;
    *) STARSHIP_CONFIG="$gruvbox"; ok "Using gruvbox theme" ;;
  esac
}

# --- Symlink Management ---
symlink() {
  local src="$1"
  local dest="$2"

  # Create parent directory if needed
  local dest_dir
  dest_dir="$(dirname "$dest")"
  if [ ! -d "$dest_dir" ]; then
    run mkdir -p "$dest_dir"
  fi

  # Back up existing file (skip if already a symlink pointing to src)
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      ok "Already linked: ${dest} -> ${src}"
      return
    fi
    info "Backing up ${dest} to ${BACKUP_DIR}/"
    if [ "$DRY_RUN" != "true" ]; then
      mkdir -p "${BACKUP_DIR}"
      mv "$dest" "${BACKUP_DIR}/"
    fi
  fi

  info "Linking ${dest} -> ${src}"
  run ln -sf "$src" "$dest"
  ok "Linked: ${dest}"
}

create_symlinks() {
  info "Creating symlinks..."

  # Common symlinks (both platforms)
  symlink "${DOTFILES_DIR}/.bashrc"       "${HOME}/.bashrc"
  symlink "${DOTFILES_DIR}/.bash_profile" "${HOME}/.bash_profile"
  symlink "${DOTFILES_DIR}/.aliases"      "${HOME}/.aliases"
  symlink "${DOTFILES_DIR}/.exports"      "${HOME}/.exports"
  symlink "${DOTFILES_DIR}/.functions"    "${HOME}/.functions"
  symlink "${DOTFILES_DIR}/.vimrc"        "${HOME}/.vimrc"
  symlink "${STARSHIP_CONFIG}" "${HOME}/.config/starship.toml"

  # Ghostty config (platform-dependent path)
  case "$OS" in
    macos)
      symlink "${DOTFILES_DIR}/ghostty.config" \
        "${HOME}/Library/Application Support/com.mitchellh.ghostty/config"
      symlink "${DOTFILES_DIR}/hammerspoon.lua" \
        "${HOME}/.hammerspoon/init.lua"
      symlink "${DOTFILES_DIR}/RectangleConfig.json" \
        "${HOME}/Library/Application Support/com.knollsoft.Rectangle/RectangleConfig.json"
      ;;
    ubuntu)
      symlink "${DOTFILES_DIR}/ghostty.config" \
        "${HOME}/.config/ghostty/config"
      ;;
  esac
}

# --- Main ---
main() {
  if [ "$DRY_RUN" = "true" ]; then
    warn "DRY RUN mode — no changes will be made"
  fi

  echo ""
  info "=== Installing packages ==="
  case "$OS" in
    macos)  install_macos_packages ;;
    ubuntu) install_ubuntu_packages ;;
  esac

  echo ""
  info "=== Installing Claude Code ==="
  install_claude_code

  echo ""
  info "=== Installing btop theme ==="
  install_btop_theme

  echo ""
  info "=== Starship theme ==="
  select_starship_theme

  echo ""
  info "=== Creating symlinks ==="
  create_symlinks

  echo ""
  info "=== Summary ==="
  ok "Package installation complete"
  ok "Symlinks created (backups in ${BACKUP_DIR} if any existed)"
  echo ""
  info "Restart your shell or run: source ~/.bash_profile"
  if [ "$DRY_RUN" = "true" ]; then
    warn "This was a dry run. Re-run without DRY_RUN=true to apply changes."
  fi
}

main "$@"
