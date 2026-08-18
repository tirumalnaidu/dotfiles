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

echo "==> Making zsh the default shell…"
if [ "$SHELL" != "$(command -v zsh)" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER" || echo "    (run: chsh -s \$(which zsh) to finish)"
fi

echo
echo "Done! Start a new shell (or: exec zsh) to use the setup."
echo "Heads up: every interactive shell now starts inside tmux. NO_TMUX=1 zsh opts out."
echo "Machine-local extras go in ~/.zshrc.local -- sourced automatically, never committed."
