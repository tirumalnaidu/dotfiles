#!/usr/bin/env bash
# Bootstrap Tirumal's terminal setup on WSL / Debian / Ubuntu.
# Safe to re-run (idempotent). Symlinks the configs into place.
set -euo pipefail

CONF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZPLUG="$HOME/.zsh/plugins"

echo "==> Installing packages (zsh, tmux, curl, git)…"
sudo apt-get update -qq
sudo apt-get install -y -qq zsh tmux curl git

# zshrc wires these in only when present, so a failure here is not fatal.
echo "==> Installing optional tools (fzf, zoxide, ripgrep)…"
sudo apt-get install -y -qq fzf zoxide ripgrep \
  || echo "    (not all available on this release; zshrc skips whatever is missing)"

echo "==> Installing Starship prompt…"
if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "    starship already installed"
fi

# Required, not optional: zshrc sources these three unconditionally, so without
# them zsh throws on every single start.
echo "==> Cloning zsh plugins…"
mkdir -p "$ZPLUG"
clone_or_update() {
  if [ -d "$2/.git" ]; then git -C "$2" pull --ff-only -q; else git clone -q --depth 1 "$1" "$2"; fi
  echo "    $(basename "$2")"
}
clone_or_update https://github.com/Aloxaf/fzf-tab.git                           "$ZPLUG/fzf-tab"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git            "$ZPLUG/zsh-autosuggestions"
clone_or_update https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$ZPLUG/fast-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-completions.git                "$ZPLUG/zsh-completions"

echo "==> Linking configs…"
ln -sfn "$CONF_DIR/zshrc"              "$HOME/.zshrc"
mkdir -p "$HOME/.config"
ln -sfn "$CONF_DIR/starship.toml"      "$HOME/.config/starship.toml"
ln -sfn "$CONF_DIR/tmux.conf"          "$HOME/.tmux.conf"
# tmux shells out to this at runtime for the C-a ? popup, so it needs a real path.
ln -sfn "$CONF_DIR/tmux-cheatsheet.md" "$HOME/.tmux-cheatsheet.md"

echo "==> Linking Claude Code config…"
mkdir -p "$HOME/.claude/bin"
ln -sfn "$CONF_DIR/.claude/CLAUDE.md"               "$HOME/.claude/CLAUDE.md"
ln -sfn "$CONF_DIR/.claude/statusline-command.sh"   "$HOME/.claude/statusline-command.sh"
ln -sfn "$CONF_DIR/.claude/bin/claude-turn-diff.sh" "$HOME/.claude/bin/claude-turn-diff.sh"
ln -sfn "$CONF_DIR/.claude/bin/cc-sessions"         "$HOME/.claude/bin/cc-sessions"
# settings.json is copied, never linked: Claude Code rewrites this file itself
# when you change model, plugins or /config. An atomic write would replace the
# symlink with a regular file and the sync would stop with no error at all.
if [ -e "$HOME/.claude/settings.json" ]; then
  echo "    settings.json already exists, left alone"
  echo "    (compare: diff $CONF_DIR/.claude/settings.json ~/.claude/settings.json)"
else
  cp "$CONF_DIR/.claude/settings.json" "$HOME/.claude/settings.json"
fi

echo "==> VSCode…"
if [ -d "$HOME/.vscode-server/data/Machine" ]; then
  ln -sfn "$CONF_DIR/.vscode/settings.json" "$HOME/.vscode-server/data/Machine/settings.json"
  echo "    machine settings linked"
fi
# The extensions themselves are ~1.4G on disk; replay the list instead.
if command -v code >/dev/null 2>&1; then
  while IFS= read -r ext; do
    [ -n "$ext" ] && code --install-extension "$ext" --force >/dev/null || true
  done < "$CONF_DIR/.vscode/extensions.txt"
  echo "    $(wc -l < "$CONF_DIR/.vscode/extensions.txt") extensions requested"
else
  echo "    'code' not on PATH; install later with:"
  echo "      xargs -n1 code --install-extension < $CONF_DIR/.vscode/extensions.txt"
fi

echo "==> Making zsh the default shell…"
if [ "$SHELL" != "$(command -v zsh)" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER" || echo "    (run: chsh -s \$(which zsh) to finish)"
fi

echo
echo "Done! Start a new shell (or: exec zsh) to use the setup."
echo "Heads up: every interactive shell now starts inside tmux. NO_TMUX=1 zsh opts out."
echo "Machine-local extras go in ~/.zshrc.local -- sourced automatically, never committed."
