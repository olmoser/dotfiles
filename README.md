# dotfiles

Personal shell configuration for macOS and Ubuntu/Debian.

## Quick start

```bash
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles

# Preview what will happen
DRY_RUN=true ./install.sh

# Run for real
./install.sh
```

The install script detects your OS, installs packages, and symlinks config files into place. Existing files are backed up to `~/.dotfiles-backup-<timestamp>/` before overwriting.

## What's included

### Shell (bash + zsh)

| File             | Purpose                                                        |
|------------------|----------------------------------------------------------------|
| `.bash_profile`  | Bash init: loads dotfiles, sets up brew/pyenv/go/cargo/fzf     |
| `.zshrc`         | Zsh init: mirrors `.bash_profile` with zsh-native options      |
| `.shell_shared`  | Shared bootstrap sourced by both bash and zsh                  |
| `.zprofile`      | Zsh login shell: brew, PATH, cargo env                         |
| `.exports`       | Environment variables (editor, history, locale)                |
| `.aliases`       | Shortcuts, `eza`/`bat`/`fd` wrappers, k8s/cloud/git aliases   |
| `.functions`     | Utilities: `calc`, `targz`, `json`, `gwt` (git worktree), etc |

`.exports`, `.aliases`, and `.functions` are shared between bash and zsh.

### Tools

| Config              | Tool                                          |
|---------------------|-----------------------------------------------|
| `.vimrc`            | Vim (lean, 6 plugins via vim-plug for quick edits) |
| `nvim/`             | [Neovim](https://neovim.io) (lazy.nvim, treesitter, telescope, Codex autocomplete via minuet-ai) |
| `starship.toml`     | [Starship](https://starship.rs) prompt (dark teal theme with powerline + nerd font icons) |
| `starship-simple.toml` | Minimal single-line starship prompt        |
| `ghostty.config`    | [Ghostty](https://ghostty.org) terminal       |
| `hammerspoon.lua`   | [Hammerspoon](https://www.hammerspoon.org) window management (macOS) |
| `RectangleConfig.json` | [Rectangle](https://rectangleapp.com) window snapping (macOS) |
| `karabiner.json`    | [Karabiner-Elements](https://karabiner-elements.pqrs.org) key remapping (macOS) |

### Display fix on wake (macOS)

`fix-displays.sh` detects when external monitors revert to the wrong resolution or refresh rate after sleep and restores the correct config using [`displayplacer`](https://github.com/jakehilborn/displayplacer). It runs automatically via [`sleepwatcher`](https://www.bernhard-baehr.de/) — the `.wakeup` file tells sleepwatcher to execute the script on wake.

**Setup:**

1. `brew install displayplacer sleepwatcher` (handled by `install.sh`)
2. While displays look correct, run `displayplacer list` and copy the command from the last line
3. Paste it as the `CORRECT_CONFIG` value in `fix-displays.sh`
4. Set `TARGET_RES` and `TARGET_HZ` to match your monitors
5. Start sleepwatcher: `brew services start sleepwatcher`

### Packages installed

**Both platforms:** ripgrep, bat, fd, jq, yq, shellcheck, btop, kubectl, tmux, zoxide, starship, neovim, gh

**macOS (brew):** eza, sk (skim), jqp, jnv, git-delta, kubectx, pnpm, uv, neovim, difftastic, lazygit, lazydocker, dust, xh, hammerspoon, rectangle, google-cloud-sdk

**Ubuntu:** Packages not in apt are installed via curl installers (starship, zoxide, kubectl, gh, lazygit, lazydocker, pnpm, uv) or cargo (skim, eza, jnv, difftastic, dust, xh).

## Starship theme

The installer prompts for a theme choice in interactive shells (or set `STARSHIP_THEME=simple` to skip the prompt):

- **default** -- powerline segments with git metrics, k8s context, language versions, battery
- **simple** -- minimal single-line prompt

## Switching to zsh

To try zsh, run `chsh -s /bin/zsh` and open a new terminal. The zsh config sources the same `.exports`, `.aliases`, and `.functions` files as bash.

## Requirements

- Bash 4+ or Zsh 5+
- A [Nerd Font](https://www.nerdfonts.com) for starship icons (the powerline theme uses nerd font symbols)
- macOS: Xcode Command Line Tools (`xcode-select --install`)
- Ubuntu: `curl`, `git`, `sudo`
