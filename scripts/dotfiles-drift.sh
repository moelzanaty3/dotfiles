#!/usr/bin/env bash
# Open a PR with whatever has drifted between this machine and the repo.
#   ./scripts/dotfiles-drift.sh            detect, push branch, open PR
#   ./scripts/dotfiles-drift.sh --dry-run  print the drift, change nothing
#
# Configs are symlinked into the repo, so "drift" is just the dirty working
# tree plus any newly installed brew packages. The commit is built with a
# throwaway index and commit-tree so the working tree is never checked out,
# reset, or stashed -- live configs keep whatever the machine has.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$DOTFILES"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$1"; }
die() { printf '\033[1;31m[x]\033[0m %s\n' "$1" >&2; exit 1; }

RUNDIR="$(mktemp -d)"
trap 'rm -rf "$RUNDIR"' EXIT

# ---------------------------------------------------------------- preconditions
command -v gh >/dev/null 2>&1 || die "gh not installed"
[[ $DRY_RUN -eq 1 ]] || gh auth status >/dev/null 2>&1 || die "gh not authenticated (gh auth login)"

git fetch --quiet origin
BASE="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
BASE="${BASE:-main}"
CURRENT="$(git symbolic-ref --quiet --short HEAD || echo DETACHED)"

[[ "$CURRENT" == "$BASE" ]] \
  || die "on branch '$CURRENT', expected '$BASE' -- skipping so unrelated work is not swept into a PR"
git merge-base --is-ancestor "origin/$BASE" HEAD \
  || die "local $BASE is behind origin/$BASE -- pull first, then rerun"

# ---------------------------------------------------------------- build the tree
export GIT_INDEX_FILE="$RUNDIR/index"
git read-tree HEAD
git add -A

BREW_NOTE=""
if command -v brew >/dev/null 2>&1; then
  BREW_DUMP="$RUNDIR/Brewfile"
  if brew bundle dump --describe --force --file="$BREW_DUMP" >/dev/null 2>&1; then
    if ! cmp -s "$BREW_DUMP" Brewfile; then
      blob="$(git hash-object -w "$BREW_DUMP")"
      git update-index --add --cacheinfo "100644,$blob,Brewfile"
      BREW_NOTE="Brewfile regenerated from installed packages (brew bundle dump --describe)."
    fi
  else
    warn "brew bundle dump failed -- Brewfile left as-is"
  fi
fi

TREE="$(git write-tree)"
unset GIT_INDEX_FILE

if [[ "$TREE" == "$(git rev-parse 'HEAD^{tree}')" ]]; then
  info "No drift."
  exit 0
fi

DIFFSTAT="$(git diff --stat HEAD "$TREE")"

# ---------------------------------------------------------------- secret guard
SECRETS='(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|xox[baprse]-[A-Za-z0-9-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
if git diff --no-color HEAD "$TREE" | grep -nE "^\+.*$SECRETS" >"$RUNDIR/hits"; then
  warn "Possible credentials in the drift -- refusing to push:"
  cat "$RUNDIR/hits" >&2
  die "scrub the value or add the file to .gitignore, then rerun"
fi

if [[ $DRY_RUN -eq 1 ]]; then
  info "Drift detected (dry run):"
  echo "$DIFFSTAT"
  [[ -n "$BREW_NOTE" ]] && echo "$BREW_NOTE"
  exit 0
fi

# ---------------------------------------------------------------- push + PR
BRANCH="chore/drift-$(date +%Y%m%d)"
TITLE="chore: sync dotfiles drift ($(date +%Y-%m-%d))"
BODY="$(printf 'Automated drift sync from %s.\n\n```\n%s\n```\n\n%s\n' \
  "$(scutil --get ComputerName 2>/dev/null || hostname)" "$DIFFSTAT" "$BREW_NOTE")"

COMMIT="$(printf '%s\n\n%s\n' "$TITLE" "$BREW_NOTE" | git commit-tree "$TREE" -p HEAD)"
git push --quiet --force origin "$COMMIT:refs/heads/$BRANCH"
info "Pushed $BRANCH"

if [[ "$(gh pr view "$BRANCH" --json state --jq .state 2>/dev/null)" == "OPEN" ]]; then
  gh pr edit "$BRANCH" --title "$TITLE" --body "$BODY" >/dev/null
  info "Updated PR: $(gh pr view "$BRANCH" --json url --jq .url)"
else
  gh pr create --base "$BASE" --head "$BRANCH" --title "$TITLE" --body "$BODY"
fi
