# dotfiles

macOS terminal setup: cmux + Ghostty + zsh + Claude Code, plus everything installed through Homebrew.

Goal: a new machine reaches the same working state with one command.

```sh
git clone https://github.com/moelzanaty3/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` installs Homebrew and the Brewfile, installs oh-my-zsh with its plugins, symlinks every config below (backing up anything already there as `.bak.<timestamp>`), builds the bat theme cache, imports shell history into atuin, and installs the cmux agent hooks. `./install.sh --skip-brew` does the config half only.

---

## What's in here

| Path | Links to | What it is |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` | oh-my-zsh, starship, eza/bat/fzf/zoxide/atuin wiring, aliases |
| `zsh/zprofile` | `~/.zprofile` | login-shell env |
| `git/gitconfig` | `~/.gitconfig` | identity, delta as pager, zdiff3 conflicts |
| `starship/starship.toml` | `~/.config/starship.toml` | prompt: single line, git status, command duration |
| `ghostty/config` | `~/.config/ghostty/config` | terminal rendering — theme, font, cursor, keybinds |
| `ghostty/themes/` | `~/.config/ghostty/themes/` | custom `tokyonight-black` theme |
| `cmux/cmux.json` | `~/.config/cmux/cmux.json` | cmux app config — agents, sidebar, notifications, workspace presets |
| `cmux/dock.json` | `~/.config/cmux/dock.json` | cmux Dock panes (Feed + lazygit) |
| `bat/themes/` | `~/.config/bat/themes/` | Tokyo Night themes for bat and delta |
| `claude/settings.json` | `~/.claude/settings.json` | Claude Code permissions, hooks, statusline |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | global instructions for Claude Code |
| `claude/statusline.sh` | `~/.claude/statusline.sh` | context/rate-limit statusline |
| `claude/hooks/` | `~/.claude/hooks/` | caveman-mode hooks |
| `claude/skills/` | `~/.claude/skills/` | personal skills |
| `agents/skills/` | `~/.agents/skills/` | shared skills store (paymob, frontend-design, perf, …) |
| `zed/settings.json` | `~/.config/zed/settings.json` | Zed editor |
| `nvim/` | `~/.config/nvim/` | Neovim (lazy.nvim) |
| `Brewfile` | — | 149 formulae, 12 casks, 52 VS Code extensions |

---

## The terminal setup

**cmux** ([cmux.com](https://cmux.com)) — Ghostty-based terminal with vertical tabs, built for running several coding agents at once. Not in Homebrew; download it from the site.

Terminal rendering comes from `~/.config/ghostty/config`, cmux's own features from `~/.config/cmux/cmux.json`. Apply changes to either with `cmux reload-config` or `cmd+shift+,` — no restart.

**Theme.** GitHub High Contrast, dark and light, switched by macOS appearance. Chosen for contrast, not looks: transparency off, `minimum-contrast = 4`, `bold-is-bright`, 20% extra line height, unfocused splits barely dimmed. `ghostty/themes/tokyonight-black` is a near-black Tokyo Night variant kept as an alternative — swap the `theme =` line to use it.

**Font.** JetBrainsMono Nerd Font 16 with ligatures, installed by the Brewfile.

**Workspace presets** (cmux `+` button, right-click for the menu):

- `Dev trio` — shell | Claude / runner
- `Agent pair` — Claude | Codex side by side
- `Review` — lazygit | shell, runs `git fetch --all --prune` first

**Submit actions** in the agent text box (Shift-Tab cycles): Claude Code, Claude skip-permissions, Codex, Cursor Agent, OpenCode, plain text entry.

**Dock** — the right sidebar seeds with the cmux Feed TUI and lazygit. It persists across restarts once you've arranged it.

**Agent hibernation** is on: more than 8 live agent terminals and idle ones get killed and resumed from their session when you return to the tab.

---

## Shell

| Tool | What it gives you |
|---|---|
| starship | prompt, single line, shows command duration over 2s |
| eza | `ls` `ll` `la` `lt` with icons and git status |
| bat | pager with syntax highlighting, `batp` to page |
| fzf | ctrl-t files, alt-c dirs, both previewed, fd-backed |
| zoxide | `z <partial>` jumps to frecent dirs; plain `cd` untouched |
| atuin | ctrl-r history search across sessions; up-arrow stays native |
| delta | side-by-side-capable git diffs, `n`/`N` to move between files |
| lazygit | git TUI |
| zsh-autosuggestions | inline completion from history |
| fast-syntax-highlighting | colors commands as you type |

cmux aliases: `cm-diff`, `cm-staged`, `cm-branch`, `cm-turn`, `cm-open`, `cm-feed`, `cm-reload`.

---

## Claude Code

Global instructions live in `claude/CLAUDE.md`. `claude/settings.json` carries permissions (allow/deny lists), the statusline, and hooks.

Plugins aren't in this repo — they're cached, not config. Reinstall from `/plugin` inside Claude Code:

`frontend-design`, `context7`, `superpowers`, `code-review`, `code-simplifier`, `playwright`, `typescript-lsp`, `claude-md-management`, `feature-dev`, `security-guidance`, `claude-code-setup` (all `@claude-plugins-official`), plus `caveman` from `JuliusBrussee/caveman`.

Agent hooks for cmux (Feed approvals, turn-complete notifications) install via `cmux hooks setup --yes`, which `install.sh` runs.

---

## Keeping it current

Configs are symlinks, so edits to `~/.zshrc` and friends are edits to this repo:

```sh
cd ~/dotfiles && git add -A && git commit -m "update" && git push
```

Refresh the package list after installing something new:

```sh
brew bundle dump --force --file=~/dotfiles/Brewfile
```

---

## What was removed before publishing

This repo is public, so machine- and work-specific material was stripped:

- Context7 API key in `zed/settings.json` → placeholder
- Private-org environment notes in `claude/settings.json` (`autoMode.environment`: repo names, internal hosts, deployment posture) → removed
- Employer git host and work `includeIf` block in `gitconfig` → commented template
- Work GitHub username in `zshrc` → `$WORK_GH_USER`
- Absolute `/Users/<name>` paths → `$HOME`

Not included at all, because they hold live credentials: `~/.config/gh`, `~/.config/atuin`, `~/.config/github-copilot`, `~/.config/opencode`, `~/.claude.json`, SSH keys.

Re-scan before any future push:

```sh
grep -rniE "ghp_|gho_|sk-[A-Za-z0-9]{16}|api[_-]?key\"?\s*[:=]\s*\"[^\"]{12,}" ~/dotfiles
```
