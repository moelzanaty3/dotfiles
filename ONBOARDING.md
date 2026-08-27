# Onboarding

Setting this repo up on a machine that isn't mine. Start to finish, roughly 40 minutes, most of it Homebrew downloading.

Read [README.md](README.md) first if you want to know what you're getting. This file is the procedure.

---

## Before you start

| Requirement | Check | Fix |
|---|---|---|
| macOS on Apple Silicon | `uname -m` → `arm64` | Intel works, but `/opt/homebrew` paths in `zprofile` become `/usr/local` — edit before installing |
| Command Line Tools | `xcode-select -p` | `xcode-select --install` |
| A GitHub account | — | the drift automation pushes branches, so you need one |

Nothing else. `install.sh` brings Homebrew, oh-my-zsh, and every package with it.

---

## 1. Fork, don't clone

Fork on GitHub first, then clone your fork. The weekly drift job pushes branches and opens PRs against `origin` — you want that pointing at a repo you own.

```sh
gh repo fork moelzanaty3/dotfiles --clone --remote-name origin ~/dotfiles
cd ~/dotfiles
```

Without `gh`: fork in the browser, then `git clone https://github.com/<you>/dotfiles.git ~/dotfiles`.

Any clone path works — `install.sh` resolves its own location. `~/dotfiles` is what the rest of this guide assumes.

---

## 2. Know what it will touch

`install.sh` symlinks the repo over your existing config. Anything already at a target path is renamed to `<path>.bak.<timestamp>` before the link goes in, so nothing is destroyed — but skim the table in the README so no target surprises you, `~/.zshrc` and `~/.gitconfig` especially.

Two dry-ish escape hatches:

```sh
./install.sh --skip-brew   # configs and symlinks only, no package install
grep '^link ' install.sh   # every path it will claim
```

---

## 3. Install

```sh
./install.sh
```

Homebrew's first run asks for your password. The Brewfile step is the slow one. When it finishes it prints the manual steps that remain.

---

## 4. Make it yours

The repo is public, so anything personal was stripped to a placeholder. Fill these in before you use it seriously:

- **`git/gitconfig`** — `user.name` and `user.email` are mine. Change them. The work `includeIf` block is a commented template; uncomment and point it at your own path if you juggle two identities.
- **`zsh/zshrc`** — `$WORK_GH_USER` is referenced but not set. Export it in `~/.zprofile`, or delete the lines that use it.
- **`zed/settings.json`** — `context7_api_key` is a placeholder. Replace it or drop the block.
- **`claude/CLAUDE.md`** — my working rules, pnpm conventions and all. Read it and cut what doesn't apply to you; Claude Code follows this file globally.
- **`vscode/settings.json`** — my editor, minus anything work-specific. It replaces your `~/Library/Application Support/Code/User/settings.json` (the old one is kept as a `.bak`), so merge yours back in from that file. Extensions are separate: they ride in the Brewfile as `vscode "..."` lines.
- **`agents/skills/`** — my Claude skills. They live here once; `install.sh` links the folder to `~/.agents/skills` and drops a symlink per skill into `~/.claude/skills`. Delete the ones you don't want before installing.
- **`Brewfile`** — 149 formulae is my machine, not a recommendation. Trim before step 3 if you'd rather not have all of it.

Edit these in the repo, not in `~`. They're the same file — the symlink means `~/.gitconfig` *is* `git/gitconfig`.

Then:

```sh
gh auth login   # required by the drift job
claude          # sign in, then /plugin to restore the plugin list in the README
```

---

## 5. Verify

```sh
exec zsh                       # prompt should be starship, ll should have icons
git config user.email          # yours, not mine
ls -l ~/.zshrc                 # symlink into ~/dotfiles
launchctl print gui/$(id -u)/local.dotfiles-drift | head -3   # drift job loaded
./scripts/dotfiles-drift.sh --dry-run                          # should say "No drift."
```

If the drift dry run lists files right after installing, that's your placeholder edits from step 4 — expected.

---

## 6. Living with it

Configs are symlinks, so editing `~/.zshrc` edits the repo. Two ways to get those edits committed:

**By hand**

```sh
cd ~/dotfiles && git add -A && git commit -m "update" && git push
```

**On its own.** `install.sh` registered a launchd agent (`local.dotfiles-drift`) that runs Sundays at 10:00: it collects the dirty working tree plus a fresh `brew bundle dump`, opens a PR on your fork, and squash-merges it. Log at `~/Library/Logs/dotfiles-drift.log`.

```sh
launchctl kickstart -k gui/$(id -u)/local.dotfiles-drift   # run it now
./scripts/dotfiles-drift.sh --no-merge                     # open the PR, merge it yourself
./scripts/dotfiles-drift.sh --dry-run                      # look, don't touch
```

It refuses to run when you're not on `main`, when `main` has diverged from origin, or when the drift contains something shaped like a credential. It never checks out or stashes, so a run can't cost you local changes.

If your fork is public, add the things that aren't credentials but still shouldn't leave your machine — your employer's hostnames, org slugs, the path your work repos live under — one extended regex per line:

```sh
mkdir -p ~/.config/dotfiles-drift
printf 'acme-corp\nacme\.internal\nDesktop/work/\n' > ~/.config/dotfiles-drift/blocklist
```

That file is read by the script and deliberately not tracked. Any added line matching one of its patterns stops the run before anything is pushed.

Prefer reviewing every sync? Drop `--no-merge` into the plist's `ProgramArguments`, or unload the job entirely:

```sh
launchctl bootout gui/$(id -u)/local.dotfiles-drift
rm ~/Library/LaunchAgents/local.dotfiles-drift.plist
```

---

## Backing out

```sh
launchctl bootout gui/$(id -u)/local.dotfiles-drift
rm ~/Library/LaunchAgents/local.dotfiles-drift.plist
```

Then restore whatever the installer backed up. Every replaced file is still there with a `.bak.<timestamp>` suffix:

```sh
ls -d ~/.zshrc.bak.* ~/.gitconfig.bak.* ~/.config/**/*.bak.* 2>/dev/null
rm ~/.zshrc && mv ~/.zshrc.bak.20260101-120000 ~/.zshrc   # one at a time, on purpose
```

Homebrew packages stay installed. `brew bundle cleanup --file=Brewfile` removes what isn't in the Brewfile, which is the opposite of what you want here — uninstall by hand instead.

---

## When something's off

| Symptom | Cause |
|---|---|
| `command not found` for brew tools in a new shell | `~/.zprofile` didn't link, or you're on Intel with `/opt/homebrew` paths |
| Prompt is plain, no starship | `exec zsh`; if it persists, `~/.zshrc` isn't the symlink |
| bat/delta have no colors | `bat cache --build` |
| Drift job never runs | `launchctl print gui/$(id -u)/local.dotfiles-drift`; check the log |
| Drift job runs, PR never appears | `gh auth status` — launchd needs the keychain unlocked, so it only fires while you're logged in |
| `local main and origin/main have diverged` | you pushed from another machine; reconcile with `git pull --rebase` yourself |
| cmux missing | not in Homebrew — download from [cmux.com](https://cmux.com), then `cmux hooks setup --yes` |
