# dotfiles

zsh, tmux, Starship and Claude Code config, kept in one place so a new machine
is one command away from the setup I actually work in.

## Install

```bash
git clone https://github.com/tirumalnaidu/dotfiles.git ~/dotfiles
~/dotfiles/install.sh && exec zsh
```

Debian / Ubuntu. Safe to re-run as often as you like.

`install.sh` uses `sudo` — it apt-installs zsh, tmux, git, curl and the
optional tools (fzf, zoxide, ripgrep), fetches Starship, clones the four zsh
plugins into `~/.zsh/plugins`, symlinks the configs, and offers to make zsh
your login shell. Because the configs are symlinks, a later `git pull` here
updates every machine at once; no reinstall.

## What's here

| File | What |
| --- | --- |
| `zshrc` | history, completion, plugins, and the tmux autostart below |
| `tmux.conf` | `Ctrl-a` prefix, mouse enabled, vim-style splits |
| `tmux-cheatsheet.md` | the key list `C-a ?` pops up over your work |
| `starship.toml` | prompt |
| `.claude/` | Claude Code settings, hooks and statusline |
| `.vscode/` | machine settings and the list of extensions to install |
| `install.sh` | the bootstrap described above |

## Three things that will surprise you

1. **Every interactive shell opens inside tmux.** Terminals in one project share
   a set of tabs; another checkout gets its own. Close the terminal and it keeps
   running; the next one reattaches. `NO_TMUX=1 zsh` opts out.
2. **The tmux prefix is `Ctrl-a`**, so it no longer jumps to the start of the
   line in zsh — press it twice, or use `Home`. `C-a ?` shows the cheat sheet.
3. **A `.venv` at the git repo root activates itself.** No venv, no effect.

## What the shell gives you

- Completion menu driven by fzf, with previews for files and directories.
- Autosuggestions from history, and syntax highlighting as you type.
- 200k lines of history, shared live between every open shell.
- `z <partial-name>` jumps to a directory by frecency; `..` and bare directory
  names work as `cd`.
- Spelling correction on command names only, so long generated paths are never
  "corrected" out from under you.

## Machine-local settings

Anything tied to one host — work paths, licence-server variables, local
aliases — belongs in `~/.zshrc.local`, not in this repo. It is sourced
automatically at the end of `zshrc` if it exists, and `*.local` is gitignored,
so it can never be committed by accident. That is what keeps this repo
portable enough to be public.

```bash
cat >> ~/.zshrc.local <<'EOF'
export SOME_TOOL_HOME=/opt/some-tool
alias deploy='./scripts/deploy.sh'
EOF
```

## Keeping it in sync

Everything is symlinked, so editing `~/.zshrc` edits this repo. The exception is
`~/.claude/settings.json` — a copy, because Claude Code rewrites it and would
silently replace a link. After changing Claude settings:

```bash
cp ~/.claude/settings.json ~/dotfiles/.claude/settings.json
```

## Notes

- Extensions install from `.vscode/extensions.txt`; they are a gigabyte on disk.
  Settings Sync owns user settings and keybindings, so they are not here.
- `.claude/.gitignore` is an allowlist, so it fails closed — `~/.claude` also
  holds an OAuth token and gigabytes of transcripts.
- `.claude/settings.json` carries the plugin list, so syncing it reinstalls the
  marketplace-sourced skills.
