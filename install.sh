#!/usr/bin/env bash
# Bootstrap a fresh macOS machine from this repo.
#   ./install.sh              full run
#   ./install.sh --skip-brew  configs only, no package install
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
SKIP_BREW=0
[[ "${1:-}" == "--skip-brew" ]] && SKIP_BREW=1

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }

# Symlink $DOTFILES/$1 to $2, backing up whatever is already there.
link() {
  local src="$DOTFILES/$1" dest="$2"
  [[ -e "$src" ]] || { warn "missing in repo: $1"; return; }
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak.$STAMP"
    warn "backed up $dest -> $dest.bak.$STAMP"
  fi
  ln -s "$src" "$dest"
  printf '    %s -> %s\n' "${dest/#$HOME/\~}" "$1"
}

# ---------------------------------------------------------------- packages
if [[ $SKIP_BREW -eq 0 ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    info "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  info "Installing Brewfile packages (this takes a while)"
  brew bundle --file="$DOTFILES/Brewfile"
else
  info "Skipping Homebrew"
fi

# ---------------------------------------------------------------- oh-my-zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing oh-my-zsh"
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone_plugin() {
  local repo="$1" dir="$ZSH_CUSTOM/plugins/$2"
  [[ -d "$dir" ]] || { info "Cloning $2"; git clone -q --depth=1 "$repo" "$dir"; }
}
clone_plugin https://github.com/zsh-users/zsh-autosuggestions zsh-autosuggestions
clone_plugin https://github.com/zdharma-continuum/fast-syntax-highlighting fast-syntax-highlighting

# ---------------------------------------------------------------- symlinks
info "Linking configs"
link zsh/zshrc                        "$HOME/.zshrc"
link zsh/zprofile                     "$HOME/.zprofile"
link git/gitconfig                    "$HOME/.gitconfig"
link starship/starship.toml           "$HOME/.config/starship.toml"
link ghostty/config                   "$HOME/.config/ghostty/config"
link ghostty/themes/tokyonight-black  "$HOME/.config/ghostty/themes/tokyonight-black"
link cmux/cmux.json                   "$HOME/.config/cmux/cmux.json"
link cmux/dock.json                   "$HOME/.config/cmux/dock.json"
link bat/themes/tokyonight_night.tmTheme "$HOME/.config/bat/themes/tokyonight_night.tmTheme"
link bat/themes/tokyonight_day.tmTheme   "$HOME/.config/bat/themes/tokyonight_day.tmTheme"
link claude/settings.json             "$HOME/.claude/settings.json"
link claude/CLAUDE.md                 "$HOME/.claude/CLAUDE.md"
link claude/statusline.sh             "$HOME/.claude/statusline.sh"
link claude/hooks                     "$HOME/.claude/hooks"
link claude/skills                    "$HOME/.claude/skills"
link agents/skills                    "$HOME/.agents/skills"
link zed/settings.json                "$HOME/.config/zed/settings.json"
link nvim                             "$HOME/.config/nvim"

chmod +x "$HOME/.claude/statusline.sh" 2>/dev/null || true
chmod +x "$DOTFILES/scripts/dotfiles-drift.sh" 2>/dev/null || true

# ---------------------------------------------------------------- weekly drift PR
DRIFT_LABEL="local.dotfiles-drift"
DRIFT_PLIST="$HOME/Library/LaunchAgents/$DRIFT_LABEL.plist"
info "Installing weekly drift job (Sundays 10:00)"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
cat > "$DRIFT_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$DRIFT_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>exec "$DOTFILES/scripts/dotfiles-drift.sh"</string>
  </array>
  <key>WorkingDirectory</key><string>$DOTFILES</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Weekday</key><integer>0</integer>
    <key>Hour</key><integer>10</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>RunAtLoad</key><false/>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/dotfiles-drift.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/dotfiles-drift.log</string>
</dict>
</plist>
PLIST
launchctl bootout "gui/$(id -u)/$DRIFT_LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$DRIFT_PLIST" || warn "launchctl bootstrap failed for $DRIFT_LABEL"

# ---------------------------------------------------------------- post-setup
if command -v bat >/dev/null 2>&1; then
  info "Building bat theme cache"
  bat cache --build >/dev/null
fi

if command -v atuin >/dev/null 2>&1; then
  info "Importing shell history into atuin"
  atuin import auto || warn "atuin import skipped"
fi

if command -v cmux >/dev/null 2>&1; then
  info "Installing cmux agent hooks"
  cmux hooks setup --yes || warn "cmux hooks setup skipped"
  cmux reload-config || true
else
  warn "cmux not installed — grab it from https://cmux.com, then run: cmux hooks setup --yes"
fi

cat <<'DONE'

Done. Remaining manual steps:

  1. Open a new terminal (or: exec zsh)
  2. gh auth login                       GitHub CLI
  3. Set your own keys where the repo has placeholders:
       ~/.config/zed/settings.json       context7_api_key
       ~/.gitconfig                      work includeIf block, if you need one
  4. Install cmux from https://cmux.com if it is not already there
  5. claude                              sign in, then /plugin to restore plugins

DONE
