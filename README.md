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

### Shell (bash)

| File             | Purpose                                                        |
|------------------|----------------------------------------------------------------|
| `.bash_profile`  | Shell init: loads dotfiles, sets up brew/pyenv/go/cargo/fzf    |
| `.exports`       | Environment variables (editor, history, locale)                |
| `.aliases`       | Shortcuts, `eza`/`bat`/`fd` wrappers, k8s/cloud/git aliases   |
| `.functions`     | Utilities: `calc`, `targz`, `json`, `gwt` (git worktree), etc |

### Tools

| Config              | Tool                                          |
|---------------------|-----------------------------------------------|
| `starship.toml`     | [Starship](https://starship.rs) prompt (dark teal theme with powerline + nerd font icons) |
| `starship-simple.toml` | Minimal single-line starship prompt        |
| `ghostty.config`    | [Ghostty](https://ghostty.org) terminal       |
| `hammerspoon.lua`   | [Hammerspoon](https://www.hammerspoon.org) window management (macOS) |
| `RectangleConfig.json` | [Rectangle](https://rectangleapp.com) window snapping (macOS) |
| `karabiner.json`    | [Karabiner-Elements](https://karabiner-elements.pqrs.org) key remapping (macOS) |

### Packages installed

**Both platforms:** ripgrep, bat, fd, jq, yq, shellcheck, btop, kubectl, tmux, zoxide, starship

**macOS (brew):** eza, sk (skim), jqp, jnv, git-delta, kubectx, pnpm, uv, difftastic, lazygit, lazydocker, dust, xh, hammerspoon, rectangle, google-cloud-sdk

**Ubuntu:** Packages not in apt are installed via curl installers (starship, zoxide, kubectl, lazygit, lazydocker, pnpm, uv) or cargo (skim, eza, jnv, difftastic, dust, xh).

## Starship theme

The installer prompts for a theme choice (or set `STARSHIP_THEME=simple` to skip the prompt):

- **default** -- powerline segments with git metrics, k8s context, language versions, battery
- **simple** -- minimal single-line prompt

## Requirements

- Bash 4+
- A [Nerd Font](https://www.nerdfonts.com) for starship icons (the powerline theme uses nerd font symbols)
- macOS: Xcode Command Line Tools (`xcode-select --install`)
- Ubuntu: `curl`, `git`, `sudo`
