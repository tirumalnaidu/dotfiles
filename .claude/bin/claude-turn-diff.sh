#!/usr/bin/env bash
# Open a VSCode red/green diff for every file Claude changed during one turn.
#
# Baseline on UserPromptSubmit via `git stash create` (writes objects only -- never touches the
# working tree, the index, or the stash list), diff against it on Stop. Git-based on purpose:
# ~/.claude/file-history only snapshots Edit/Write tool calls, so it misses every Bash edit.
set -uo pipefail

MODE=${1:?usage: claude-turn-diff.sh baseline|show}
MAX_TABS=12
STATE_DIR=$HOME/.claude/diff-baseline
CODE=$(command -v code || echo "$HOME/.vscode-server/cli/servers/Stable-*/server/bin/remote-cli/code")

payload=$(cat)
sid=$(printf '%s' "$payload" | jq -r '.session_id // "nosession"')
cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
state=$STATE_DIR/$sid

# A background session inherits VSCODE_IPC_HOOK_CLI from whatever window spawned it, which is
# often closed by now. Try that socket, then the most recent ones, until one actually answers.
try_code() {
  local c; c=$(eval echo "$CODE" 2>/dev/null | tr ' ' '\n' | grep -v '\*' | head -1)
  [ -x "$c" ] || return 1
  local s
  for s in "${VSCODE_IPC_HOOK_CLI:-}" $(ls -t /run/user/$(id -u)/vscode-ipc-*.sock 2>/dev/null | head -8); do
    [ -n "$s" ] || continue
    VSCODE_IPC_HOOK_CLI=$s "$c" "$@" >/dev/null 2>&1 && return 0
  done
  return 1
}

case $MODE in
baseline)
  mkdir -p "$STATE_DIR"
  # Arm/disarm from the prompt. Grep the whole raw payload rather than a named field: the
  # UserPromptSubmit schema is undocumented here, and the prompt is the only user text in it.
  if printf '%s' "$payload" | grep -qiE 'show +(me +)?(the +)?diffs?( +as +you +(change|go|edit))?'; then
    : > "$state.armed"
  elif printf '%s' "$payload" | grep -qiE '(stop|no more|quit) +(showing +)?(me +)?diffs?|diffs? +off'; then
    rm -f "$state.armed"
  fi
  sha=$(git -C "$root" stash create 2>/dev/null)
  [ -z "$sha" ] && sha=$(git -C "$root" rev-parse HEAD 2>/dev/null)
  [ -z "$sha" ] && exit 0
  printf '%s\n%s\n' "$sha" "$root" > "$state"
  git -C "$root" ls-files --others --exclude-standard > "$state.untracked" 2>/dev/null
  ;;
show)
  [ -r "$state.armed" ] || exit 0          # not armed: say nothing, open nothing
  [ -r "$state" ] || exit 0
  sha=$(sed -n 1p "$state"); root=$(sed -n 2p "$state")
  [ -n "$sha" ] && [ -d "$root" ] || exit 0

  changed=$(git -C "$root" diff --name-only "$sha" 2>/dev/null)
  if [ -r "$state.untracked" ]; then
    fresh=$(comm -13 <(sort "$state.untracked") <(git -C "$root" ls-files --others --exclude-standard 2>/dev/null | sort))
    changed=$(printf '%s\n%s\n' "$changed" "$fresh" | sed '/^$/d' | sort -u)
  fi
  [ -n "$changed" ] || exit 0

  tmp=$(mktemp -d "${TMPDIR:-/tmp}/claude-diff-XXXXXX")
  n=0; total=0; failed=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    total=$((total+1))
    [ "$n" -ge "$MAX_TABS" ] && continue
    [ -f "$root/$f" ] || continue                    # deleted: nothing to show on the right
    before=$tmp/$(printf '%s' "$f" | tr '/' '_').BEFORE
    git -C "$root" show "$sha:$f" > "$before" 2>/dev/null || : > "$before"
    if try_code --reuse-window --diff "$before" "$root/$f"; then n=$((n+1)); else failed=1; fi
  done <<< "$changed"

  if [ "$failed" = 1 ] && [ "$n" = 0 ]; then
    printf '{"systemMessage":"%d file(s) changed but no VSCode window answered. Diff by hand: git diff %s"}\n' "$total" "$sha"
  elif [ "$total" -gt "$n" ]; then
    printf '{"systemMessage":"Opened %d of %d changed files (cap %d). Rest: git diff --name-only %s"}\n' "$n" "$total" "$MAX_TABS" "$sha"
  elif [ "$n" -gt 0 ]; then
    printf '{"systemMessage":"Opened %d VSCode diff(s) for this turn."}\n' "$n"
  fi
  ;;
esac
exit 0
