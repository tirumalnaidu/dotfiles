# Minimal zsh — fast, no oh-my-zsh bloat
# Portable: works on this server and WSL. See README.
autoload -Uz compinit promptinit
compinit
promptinit

# === Features ===
setopt correct           # autocorrect typos (gti → "did you mean git?")
setopt autocd            # cd by typing dir name
setopt autolist          # show completions in columns
setopt extendedglob      # advanced pattern matching
setopt nobeep            # no beeps
setopt histignorealldups # dedupe history
setopt sharehistory      # share history across sessions
HISTSIZE=10000
SAVEHIST=10000

# === Completion system ===
zstyle ':completion:*' menu select
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'r:|[._-]=** r:|=**' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# === Starship prompt (fast, written in Rust) ===
eval "$(starship init zsh)"

# === Aliases ===
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -F'
alias ..='cd ..'
alias ...='cd ../..'

# === Tmux auto-attach on SSH ===
#[[ -z "$TMUX" ]] && tmux new -A -s main

# === Default venv: only activate if it exists (portable across machines) ===
[[ -f "$HOME/.venv/bin/activate" ]] && source "$HOME/.venv/bin/activate"
