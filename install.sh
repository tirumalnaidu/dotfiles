#!/usr/bin/env bash
# Bootstrap Tirumal's terminal setup on WSL / Debian / Ubuntu.
# Safe to re-run (idempotent). Symlinks the configs into place.
set -euo pipefail

CONF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Installing packages (zsh, tmux, curl, git)…"
sudo apt-get update -qq
sudo apt-get install -y -qq zsh tmux curl git

echo "==> Installing Starship prompt…"
if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "    starship already installed"
fi

echo "==> Linking configs…"
# zshrc
ln -sfn "$CONF_DIR/zshrc"        "$HOME/.zshrc"
# starship
mkdir -p "$HOME/.config"
ln -sfn "$CONF_DIR/starship.toml" "$HOME/.config/starship.toml"
# tmux
ln -sfn "$CONF_DIR/tmux.conf"      "$HOME/.tmux.conf"

echo "==> Making zsh the default shell…"
if [ "$SHELL" != "$(command -v zsh)" ]; then
  sudo chsh -s "$(command -v zsh)" "$USER" || echo "    (run: chsh -s \$(which zsh) to finish)"
fi

echo
echo "Done! Start a new shell (or: exec zsh) to use the setup."
echo "Tip: if you use a project-local venv, create ~/.venv to auto-activate it."
