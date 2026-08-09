# dotfiles

Tirumal's terminal setup — zsh, Starship prompt, tmux. Minimal, fast, no oh-my-zsh bloat.

## Contents

| File            | Installs to                  | Purpose                          |
|-----------------|------------------------------|----------------------------------|
| `zshrc`         | `~/.zshrc`                   | Fast minimal zsh config          |
| `starship.toml` | `~/.config/starship.toml`    | Clean, minimal Starship prompt   |
| `tmux.conf`     | `~/.tmux.conf`               | Minimal tmux (mouse, vim splits) |

## One-shot install (WSL / Debian / Ubuntu)

```bash
git clone https://github.com/tirumalnaidu/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

The installer is idempotent — safe to re-run. It symlinks the configs so
`git pull` in `~/dotfiles` updates everything live.

## Manual / custom

```
ln -sfn ~/dotfiles/zshrc            ~/.zshrc
ln -sfn ~/dotfiles/starship.toml    ~/.config/starship.toml
ln -sfn ~/dotfiles/tmux.conf        ~/.tmux.conf
```

## Notes

- No oh-my-zsh — keeps startup fast and dependency-free.
- `~/.venv` is auto-activated **only if it exists**, so the config is safe
  on machines without a venv.
- Plugins/other binaries you add on a per-machine basis live on that machine;
  this repo holds the shared, portable baseline.
