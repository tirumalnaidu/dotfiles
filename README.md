# dotfiles

Tirumal's terminal setup — zsh, Starship, tmux. No oh-my-zsh, no framework;
just a config that starts fast and gets out of the way.

## Install (WSL / Debian / Ubuntu)

```bash
git clone https://github.com/tirumalnaidu/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
exec zsh
```

Idempotent — safe to re-run. It installs packages, clones the zsh plugins, and
symlinks the configs, so `git pull` here updates every machine live.

## Contents

| File                 | Installs to                | Purpose                                     |
| -------------------- | -------------------------- | ------------------------------------------- |
| `zshrc`              | `~/.zshrc`                 | Shell: history, completion, plugins, keys  |
| `tmux.conf`          | `~/.tmux.conf`             | tmux: `Ctrl-a` prefix, mouse on, vim splits |
| `tmux-cheatsheet.md` | `~/.tmux-cheatsheet.md`    | Read at runtime by tmux's `C-a ?` popup     |
| `starship.toml`      | `~/.config/starship.toml`  | Prompt                                      |
| `install.sh`         | —                          | Bootstrap                                   |

## What you get

**Every interactive shell starts inside tmux.** Terminals in the same project
share one set of tabs; a different checkout gets its own. Close the terminal and
the session keeps running — the next one reattaches. `NO_TMUX=1 zsh` opts out.

**tmux** — prefix is `Ctrl-a`. Mouse is on, so you can click panes, drag borders
and click tabs. `C-a ?` pops the cheat sheet up over your work; `C-a |` and
`C-a -` split; `Alt-Arrow` moves between panes; `C-a z` zooms one fullscreen.

**zsh** — completion menu driven by fzf, autosuggestions from history, syntax
highlighting as you type, 200k lines of history shared live between shells,
`cd`-less navigation (`..`, bare directory names, `z` via zoxide), and spelling
correction on command names only.

**Prompt** — Starship. Shows the active virtualenv named after the project
rather than the venv directory, since every one of them is just `.venv`.

## Per-machine settings

Anything tied to one host — work paths, licence-server variables, local aliases —
goes in `~/.zshrc.local`. It's sourced automatically if present and is
gitignored (`*.local`), so this repo stays portable and publishable.

```bash
cat >> ~/.zshrc.local <<'EOF'
export SOME_TOOL_HOME=/opt/some-tool
alias deploy='./scripts/deploy.sh'
EOF
```

## Notes

- A `.venv` at the **git repo root** (or the current directory, outside a repo)
  is activated automatically. Machines and projects without one are unaffected.
- The four zsh plugins live in `~/.zsh/plugins`; `install.sh` clones them and
  `zsh-plugins-update` (defined in `zshrc`) pulls them all and clears the
  stale bytecode.
- Binaries are picked up from `~/.local/bin` if present, so the whole setup
  works without root.
