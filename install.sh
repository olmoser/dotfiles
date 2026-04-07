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
  direnv
  starship
  fzf
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
  fnm       # fast Node manager
  gh        # GitHub CLI
  git-delta
  deno
  go-task   # Taskfile runner
  shellcheck
  btop
  kubectl
  kubectx   # provides kubectx (kctx) and kubens (kns)
  nethogs
  pnpm
  uv
  tmux
  neovim
  difftastic
  lazygit
  lazydocker
  dust      # modern du
  xh        # modern httpie/curl
  zsh-autosuggestions
  zsh-syntax-highlighting
  displayplacer
  sleepwatcher
)

BREW_CASKS=(
  hammerspoon
  rectangle
  google-cloud-sdk
)

APT_PACKAGES=(
  direnv
  ripgrep
  bat
  fd-find
  jq
  shellcheck
  btop
  nethogs
  tmux
  vim
  zsh-autosuggestions
  zsh-syntax-highlighting
)

install_apt_binary_if_available() {
  local binary="$1"
  local apt_package="$2"
  local missing_message="$3"

  if command -v "$binary" &>/dev/null; then
    ok "${binary} already installed"
    return
  fi

  if apt-cache show "$apt_package" &>/dev/null; then
    info "Installing ${apt_package} via apt..."
    run sudo apt-get install -y -qq "$apt_package"
  else
    warn "${missing_message}"
  fi
}

install_cargo_binary_if_missing() {
  local binary="$1"
  local crate="${2:-$1}"
  local missing_message="$3"

  if command -v "$binary" &>/dev/null; then
    ok "${binary} already installed"
    return
  fi

  if command -v cargo &>/dev/null; then
    info "Installing ${crate} via cargo..."
    run cargo install "$crate"
  else
    warn "${missing_message}"
  fi
}

install_macos_packages() {
  install_homebrew

  # Source brew shellenv for this script
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  # Snapshot installed formulae and casks once (avoids per-package subprocess)
  local -A installed_formulae=()
  local -A installed_casks=()
  while IFS= read -r p; do installed_formulae["$p"]=1; done < <(brew list --formula -1 2>/dev/null)
  while IFS= read -r p; do installed_casks["$p"]=1; done < <(brew list --cask -1 2>/dev/null)

  info "Installing brew packages..."
  for pkg in "${BREW_PACKAGES[@]}"; do
    if [[ -n "${installed_formulae[$pkg]:-}" ]]; then
      ok "${pkg} already installed"
    else
      info "Installing ${pkg}..."
      run brew install "$pkg"
    fi
  done

  info "Installing brew casks..."
  for cask in "${BREW_CASKS[@]}"; do
    if [[ -n "${installed_casks[$cask]:-}" ]]; then
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

  # Vim PPA (Ubuntu < 24.04 ships Vim 8.x; need 9.0+ for habamax colorscheme)
  _ubuntu_major="$(. /etc/os-release && echo "${VERSION_ID%%.*}")"
  if [ "${_ubuntu_major:-0}" -lt 24 ]; then
    if ! grep -q "jonathonf/vim" /etc/apt/sources.list.d/*.list 2>/dev/null; then
      info "Adding Vim PPA (system vim too old)..."
      run sudo add-apt-repository -y ppa:jonathonf/vim
    fi
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

  # eza
  install_apt_binary_if_available "eza" "eza" \
    "eza not available in apt. Install manually or via cargo: cargo install eza"

  # skim
  install_cargo_binary_if_missing "sk" "skim" \
    "skim requires cargo. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"

  # fnm (fast Node manager) — installer puts binary in ~/.local/share/fnm
  if command -v fnm &>/dev/null || [ -x "${HOME}/.local/share/fnm/fnm" ]; then
    ok "fnm already installed"
  else
    info "Installing fnm..."
    run sh -c 'curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell'
  fi

  # Activate fnm in the current shell and install Node LTS so that npm/npx
  # resolve to a user-scoped installation (no sudo needed for global installs)
  if ! command -v fnm &>/dev/null && [ -x "${HOME}/.local/share/fnm/fnm" ]; then
    export PATH="${HOME}/.local/share/fnm:${PATH}"
  fi
  if command -v fnm &>/dev/null; then
    eval "$(fnm env)"
    if ! fnm ls | grep -q lts-latest; then
      info "Installing Node LTS via fnm..."
      run fnm install --lts
    fi
    run fnm use lts-latest
    if command -v node &>/dev/null; then
      ok "Node $(node --version) active via fnm"
    else
      warn "fnm activated but node not yet on PATH"
    fi
  fi

  # git-delta
  install_apt_binary_if_available "delta" "git-delta" \
    "git-delta not available in apt. Install manually: https://github.com/dandavison/delta/releases"

  # GitHub CLI
  if ! command -v gh &>/dev/null; then
    info "Installing GitHub CLI..."
    run sh -c 'curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt-get update -qq && sudo apt-get install -y -qq gh'
  else
    ok "gh already installed"
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

  # jqp (GitHub release)
  if ! command -v jqp &>/dev/null; then
    info "Installing jqp..."
    run sh -c 'JQP_VERSION=$(curl -fsSL "https://api.github.com/repos/noahgorstein/jqp/releases/latest" | jq -r .tag_name | sed "s/v//") && curl -fsSLo /tmp/jqp.tar.gz "https://github.com/noahgorstein/jqp/releases/download/v${JQP_VERSION}/jqp_Linux_x86_64.tar.gz" && tar xzf /tmp/jqp.tar.gz -C /tmp jqp && sudo install /tmp/jqp /usr/local/bin && rm /tmp/jqp /tmp/jqp.tar.gz'
  else
    ok "jqp already installed"
  fi

  # jnv
  install_cargo_binary_if_missing "jnv" "jnv" \
    "jnv requires cargo. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"

  # yq (GitHub release — not available in apt on Ubuntu < 24.04)
  if ! command -v yq &>/dev/null; then
    info "Installing yq..."
    run sh -c 'YQ_VERSION=$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" | jq -r .tag_name) && YQ_ARCH=$(dpkg --print-architecture) && curl -fsSLo /tmp/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${YQ_ARCH}" && sudo install /tmp/yq /usr/local/bin/yq && rm /tmp/yq'
  else
    ok "yq already installed"
  fi


  # deno
  if ! command -v deno &>/dev/null; then
    info "Installing deno..."
    run sh -c 'curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh'
  else
    ok "deno already installed"
  fi

  # task (Taskfile runner — GitHub release)
  if ! command -v task &>/dev/null; then
    info "Installing task..."
    run sh -c 'TASK_ARCH=$(dpkg --print-architecture) && curl -fsSL "https://github.com/go-task/task/releases/download/v3.49.1/task_linux_${TASK_ARCH}.tar.gz" | tar -xz -C /tmp task && sudo install /tmp/task /usr/local/bin && rm /tmp/task'
  else
    ok "task already installed"
  fi

  # fzf (from git — apt version is too old, ~/.fzf/bin takes precedence via .shell_shared)
  if [ ! -d "${HOME}/.fzf" ]; then
    info "Installing fzf from git..."
    run git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
    # --no-bash/--no-zsh: skip generating ~/.fzf.bash/~/.fzf.zsh;
    # shell init is handled by .bash_profile and .zshrc via eval "$(fzf --bash/--zsh)"
    run "${HOME}/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-zsh --no-fish
  else
    ok "fzf already installed (${HOME}/.fzf)"
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
  install_cargo_binary_if_missing "difft" "difftastic" \
    "difftastic requires cargo. Install Rust first: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"

  # Google Cloud SDK
  if command -v gcloud &>/dev/null || [ -d "${HOME}/google-cloud-sdk" ]; then
    ok "gcloud already installed"
  else
    info "Installing Google Cloud SDK..."
    run sh -c 'curl -fsSL https://sdk.cloud.google.com | bash -s -- --disable-prompts'
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

  # neovim (GitHub release — apt package is outdated or missing on Ubuntu)
  local _nvim_version="0.12.0"
  if command -v nvim &>/dev/null; then
    ok "nvim already installed ($(nvim --version | head -1))"
  else
    info "Installing neovim v${_nvim_version} from GitHub release..."
    local _nvim_arch _nvim_sha256
    case "$(uname -m)" in
      x86_64)
        _nvim_arch="x86_64"
        _nvim_sha256="160b69125defb16e60b283b69be112fd4850d67ac8f9a752328c20ad43ec34af"
        ;;
      aarch64)
        _nvim_arch="arm64"
        _nvim_sha256="89024e7be2ef3c8f08e9c002b1eb3e3b36672ee44bd6343cf2d168d38b3736b2"
        ;;
      *) err "Unsupported architecture for neovim: $(uname -m)"; return 1 ;;
    esac
    local _nvim_tarball="nvim-linux-${_nvim_arch}.tar.gz"
    local _nvim_url="https://github.com/neovim/neovim/releases/download/v${_nvim_version}/${_nvim_tarball}"
    run sh -c "curl -fsSLo '/tmp/${_nvim_tarball}' '${_nvim_url}' \
      && echo '${_nvim_sha256}  /tmp/${_nvim_tarball}' | sha256sum -c - \
      && sudo tar xzf '/tmp/${_nvim_tarball}' -C /opt \
      && sudo ln -sf '/opt/nvim-linux-${_nvim_arch}/bin/nvim' /usr/local/bin/nvim \
      && rm '/tmp/${_nvim_tarball}'"
  fi

  # dust
  install_cargo_binary_if_missing "dust" "du-dust" \
    "dust requires cargo. Install Rust first."

  # xh
  install_cargo_binary_if_missing "xh" "xh" \
    "xh requires cargo. Install Rust first."

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

  # tmux bash completion (not packaged on Ubuntu < 24.04)
  local _tmux_comp="/usr/share/bash-completion/completions/tmux"
  if command -v tmux &>/dev/null && [ ! -f "$_tmux_comp" ]; then
    info "Installing tmux bash completion..."
    run sudo cp "${DOTFILES_DIR}/completions/tmux" "$_tmux_comp"
  fi
}

# --- Autojump -> Zoxide migration ---
import_autojump_history() {
  if ! command -v zoxide &>/dev/null; then
    return
  fi

  # Common autojump data paths (macOS and Linux)
  local aj_paths=(
    "${HOME}/Library/autojump/autojump.txt"
    "${HOME}/.local/share/autojump/autojump.txt"
  )

  for aj_file in "${aj_paths[@]}"; do
    if [ -f "$aj_file" ]; then
      info "Importing autojump history from ${aj_file}..."
      run zoxide import --from autojump --merge "$aj_file"
      ok "Autojump history imported into zoxide"
      return
    fi
  done
}

# --- LSP servers (for neovim) ---
install_lsp_servers() {
  # basedpyright (Python LSP — installed via uv to avoid npm/brew conflicts)
  if command -v uv &>/dev/null; then
    if command -v basedpyright &>/dev/null; then
      ok "basedpyright already installed"
    else
      info "Installing basedpyright..."
      run uv tool install basedpyright
    fi
  else
    warn "uv not found — skipping basedpyright install"
  fi

  # TypeScript LSP (requires npm)
  if command -v npm &>/dev/null; then
    for pkg in typescript typescript-language-server; do
      if npm list -g "$pkg" &>/dev/null; then
        ok "${pkg} already installed"
      else
        info "Installing ${pkg}..."
        run npm install -g "$pkg"
      fi
    done
  else
    warn "npm not found — skipping TypeScript LSP server installs"
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
  if compgen -G "${theme_dir}/catppuccin_*.theme" >/dev/null; then
    ok "Catppuccin btop theme already installed"
    return
  fi
  info "Installing Catppuccin btop theme..."
  run mkdir -p "${theme_dir}"
  run git clone --depth 1 https://github.com/catppuccin/btop.git /tmp/catppuccin-btop
  if [ "$DRY_RUN" != "true" ]; then
    cp -r /tmp/catppuccin-btop/themes/* "${theme_dir}/"
    rm -rf /tmp/catppuccin-btop
  fi
  ok "Catppuccin btop theme installed to ${theme_dir}"
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

  if [ ! -t 0 ] || [ ! -t 1 ]; then
    info "Non-interactive shell detected; using gruvbox theme"
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
  symlink "${DOTFILES_DIR}/.zshrc"        "${HOME}/.zshrc"
  symlink "${DOTFILES_DIR}/.zprofile"     "${HOME}/.zprofile"
  symlink "${DOTFILES_DIR}/.shell_shared" "${HOME}/.shell_shared"
  symlink "${DOTFILES_DIR}/.aliases"      "${HOME}/.aliases"
  symlink "${DOTFILES_DIR}/.exports"      "${HOME}/.exports"
  symlink "${DOTFILES_DIR}/.functions"    "${HOME}/.functions"
  symlink "${DOTFILES_DIR}/.vimrc"        "${HOME}/.vimrc"
  symlink "${DOTFILES_DIR}/.tmux.conf"    "${HOME}/.tmux.conf"
  symlink "${DOTFILES_DIR}/.gitconfig"   "${HOME}/.gitconfig"
  symlink "${DOTFILES_DIR}/nvim"      "${HOME}/.config/nvim"
  symlink "${STARSHIP_CONFIG}" "${HOME}/.config/starship.toml"

  # Global gitignore (path configured in .gitconfig via core.excludesfile)
  symlink "${DOTFILES_DIR}/.gitignore_global" "${HOME}/.gitignore_global"

  # Platform-dependent config
  case "$OS" in
    macos)
      symlink "${DOTFILES_DIR}/ghostty.config" \
        "${HOME}/Library/Application Support/com.mitchellh.ghostty/config"
      symlink "${DOTFILES_DIR}/hammerspoon.lua" \
        "${HOME}/.hammerspoon/init.lua"
      symlink "${DOTFILES_DIR}/RectangleConfig.json" \
        "${HOME}/Library/Application Support/com.knollsoft.Rectangle/RectangleConfig.json"
      symlink "${DOTFILES_DIR}/.wakeup"          "${HOME}/.wakeup"
      symlink "${DOTFILES_DIR}/fix-displays.sh"  "${HOME}/fix-displays.sh"
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
  info "=== Importing autojump history ==="
  import_autojump_history

  echo ""
  info "=== Installing LSP servers ==="
  install_lsp_servers

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
  info "Restart your shell or run: source ~/.bash_profile (bash) / source ~/.zshrc (zsh)"
  if [ "$DRY_RUN" = "true" ]; then
    warn "This was a dry run. Re-run without DRY_RUN=true to apply changes."
  fi
}

main "$@"
