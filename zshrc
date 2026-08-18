# ~/.zshrc -- interactive zsh setup (userspace, no root)
# Layout: binaries in ~/.local/bin, plugins in ~/.zsh/plugins, cache in ~/.cache/zsh

ZPLUG=$HOME/.zsh/plugins
ZCACHE=${XDG_CACHE_HOME:-$HOME/.cache}/zsh
[[ -d $ZCACHE ]] || mkdir -p $ZCACHE

# --- environment ------------------------------------------------------------
# Replays what the login shell sets up after handing over to zsh: the handoff
# execs us before it has run these steps itself, so they would otherwise be lost.
typeset -U path PATH                      # auto-dedupe PATH
path=($HOME/.local/bin $path)
[[ -f $HOME/.cargo/env ]] && source $HOME/.cargo/env

# --- tmux ---------------------------------------------------------------------
# Every terminal lands in a tab set shared per tree: two windows on the same
# clone see the same tabs, each sitting on whichever tab it likes, while another
# clone or worktree gets its own set. The second and later terminals join as
# views that self-destruct on close, so only the first session holds the tabs.
# Escape hatch: NO_TMUX=1. The -t 1 test keeps tool-spawned shells out.
if [[ -z $TMUX && -z $NO_TMUX && -t 1 && $TERM != (dumb|emacs) ]] \
   && (( $+commands[tmux] )); then
  _grp=${$(git rev-parse --show-toplevel 2>/dev/null):-$PWD}
  _grp=${${_grp:t}//[.:]/_}        # ':' and '.' are illegal in a session name
  # Exact match, not `tmux has-session`, which matches on prefix -- that would
  # drop a `proj` terminal into `proj_2`'s tabs whenever `proj` itself is gone.
  if tmux ls -F '#{session_name}' 2>/dev/null | grep -qxF -- $_grp; then
    exec tmux new-session -t $_grp \; set-option destroy-unattached on
  else
    exec tmux new-session -s $_grp
  fi
fi

# Activate this tree's venv here rather than letting VSCode's Python extension
# inject `source .../activate` into the terminal
_tree=${$(git rev-parse --show-toplevel 2>/dev/null):-$PWD}
if [[ -f $_tree/.venv/bin/activate ]]; then
  source $_tree/.venv/bin/activate
  # Label the prompt with the tree, not the venv dir: every venv here is a plain
  # `.venv` recorded as `prompt = sw`, identical in every clone.
  export PROMPT_VENV=${_tree:t}
fi
unset _tree

# LS_COLORS is unset on this host, which also left the completion menu colourless
# (`list-colors` below reads it). dircolors ships with coreutils -- no extra dep.
eval "$(dircolors -b)"

export EDITOR=${EDITOR:-vim}
export PAGER=less
export LESS='-R -F -X -i -M'
export MANPAGER='less -R'

# --- history ----------------------------------------------------------------
HISTFILE=$HOME/.zsh_history
HISTSIZE=200000
SAVEHIST=200000
setopt EXTENDED_HISTORY          # timestamp + duration per entry
setopt INC_APPEND_HISTORY_TIME   # write after each command, not just on exit
setopt SHARE_HISTORY             # live-share history between open shells
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE         # leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS HIST_VERIFY
setopt HIST_FCNTL_LOCK           # safe concurrent writes from many shells

# --- shell behaviour --------------------------------------------------------
setopt AUTO_CD                   # `..` / a bare dir name cds into it
setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT   # `cd -<TAB>` history
setopt EXTENDED_GLOB GLOB_DOTS NUMERIC_GLOB_SORT
setopt INTERACTIVE_COMMENTS      # allow # comments when typing
setopt NO_BEEP
setopt LONG_LIST_JOBS NOTIFY
setopt MULTIOS
setopt PROMPT_SUBST
unsetopt FLOW_CONTROL            # frees ^S / ^Q for keybindings
DIRSTACKSIZE=20

# --- autocorrection ---------------------------------------------------------
setopt CORRECT                   # offer a fix for a mistyped command name
# CORRECT_ALL (argument correction too) is deliberately off: on a tree full of
# generated paths it "corrects" them constantly. Enable with `setopt CORRECT_ALL`.
CORRECT_IGNORE='_*'              # never suggest completion functions
CORRECT_IGNORE_FILE='.*'
SPROMPT='zsh: %F{yellow}%R%f -> %F{green}%r%f ? [%Uy%ues%Un%bo%Ua%ubort%Ue%udit] '
alias sudo='nocorrect sudo'
alias git='nocorrect git'
alias mkdir='nocorrect mkdir'

# --- completion -------------------------------------------------------------
fpath=($ZPLUG/zsh-completions/src $fpath)
autoload -Uz compinit
# Rebuild the completion dump at most once a day; a full compinit scan of fpath
# is the single biggest startup cost on a networked filesystem.
_zcompdump=$ZCACHE/zcompdump-$ZSH_VERSION
if [[ -n $_zcompdump(#qN.mh-24) ]]; then
  compinit -C -d $_zcompdump      # -C: trust the dump, skip security scan
else
  compinit -d $_zcompdump
  { zcompile -R -- $_zcompdump } &!   # precompile in background for next start
fi

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZCACHE/compcache
zstyle ':completion:*' menu no                     # fzf-tab draws the menu
zstyle ':completion:*' matcher-list \
  'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'                                    # case-insensitive + fuzzy
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>3?3:($#PREFIX+$#SUFFIX)/3))numeric)'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{blue}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*:(cd|pushd):*' ignore-parents parent pwd
zstyle ':completion:*:*:kill:*:processes' \
  command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion:*:*:*:*:processes' menu yes select

# --- plugins ----------------------------------------------------------------

# fzf-tab must load after compinit and before syntax highlighting.
source $ZPLUG/fzf-tab/fzf-tab.plugin.zsh
zstyle ':fzf-tab:*' fzf-flags --height=45% --layout=reverse --border
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
zstyle ':fzf-tab:complete:(cat|bat|less|vim|nvim|head|tail):*' \
  fzf-preview 'head -100 $realpath 2>/dev/null'

# Loaded eagerly, not via zsh-defer: deferring let autosuggestions run its widget
# binding twice, so one Ctrl-Right partial-accept inserted the suggestion twice.
source $ZPLUG/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZPLUG/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40   # skip suggesting on very long lines

# --- keybindings ------------------------------------------------------------
bindkey -e                                   # emacs mode
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search   # Up: prefix-search history
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[1;5C' forward-word               # ctrl-right
bindkey '^[[1;5D' backward-word              # ctrl-left
bindkey '^[[3~'   delete-char
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[Z'    reverse-menu-complete      # shift-tab
bindkey '^ '      autosuggest-accept         # ctrl-space accepts suggestion
bindkey '^[m'     copy-prev-shell-word
autoload -Uz edit-command-line; zle -N edit-command-line
bindkey '^X^E' edit-command-line             # open $EDITOR on the current line

# --- tools ------------------------------------------------------------------
if (( $+commands[fzf] )); then
  # Truecolor hex, not the 16 ANSI slots, so fzf looks the same whatever palette
  # the client terminal is themed with ($COLORTERM is truecolor here).
  export FZF_DEFAULT_OPTS='--height=45% --layout=reverse --border --info=inline
    --color=bg+:#283457,spinner:#7aa2f7,hl:#7aa2f7
    --color=fg:#c0caf5,header:#7aa2f7,info:#9ece6a,pointer:#7aa2f7
    --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff
    --color=border:#3b4261'
  (( $+commands[rg] )) && export FZF_DEFAULT_COMMAND='rg --files --hidden --glob !.git'
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  source <(fzf --zsh)                        # ctrl-r, ctrl-t, alt-c
fi
# zoxide: `z <partial>` jumps to a frecency-ranked dir, `zi` picks via fzf.
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

# --- aliases ----------------------------------------------------------------
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -lh' la='ls -lAh' l='ls -CF'
alias grep='grep --color=auto' egrep='egrep --color=auto' fgrep='fgrep --color=auto'
alias ..='cd ..' ...='cd ../..' ....='cd ../../..'
alias df='df -h' du='du -h' free='free -h'
alias tree='ls -R'  # tree(1) is not installed on this host
alias gs='git status -sb' gd='git diff' gl='git log --oneline --graph --decorate -20'
alias gco='git checkout' gb='git branch' gp='git push'
alias t='tmux' ta='tmux attach -t' tl='tmux ls' tn='tmux new -s'
alias reload='exec zsh'
alias zshrc='$EDITOR ~/.zshrc'
alias path='print -l $path'
# Escape hatch back to the login shell without the exec hook re-firing.
alias tcsh='NO_ZSH=1 command tcsh'

# mkdir + cd in one step
mkcd() { mkdir -p -- "$1" && cd -- "$1"; }

# VSCode gives each window its own IPC socket and exports its path. A tmux pane
# keeps whichever path was current when the pane was created, so `code` from an
# older pane reaches a closed window and dies with ECONNREFUSED. Retarget only
# when that socket has no listener, so a pane that still works is left alone.
code() {
  local live newest
  live=$(ss -lx 2>/dev/null | grep -o "/run/user/${UID}/vscode-ipc-[^[:space:]]*\.sock")
  if [[ -n $TMUX ]] && ! grep -qxF -- "$VSCODE_IPC_HOOK_CLI" <<< "$live"; then
    newest=$(xargs -r ls -t 2>/dev/null <<< "$live" | head -1)
    [[ -n $newest ]] && export VSCODE_IPC_HOOK_CLI=$newest
  fi
  command code "$@"
}


# Pull latest for every plugin, then drop the stale bytecode.
zsh-plugins-update() {
  for d in $ZPLUG/*(/); do print "== ${d:t}"; git -C $d pull --ff-only -q && print "  ok"; done
  rm -f $ZCACHE/zcompdump-* $HOME/.zshrc.zwc $ZPLUG/**/*.zwc(N)
  print "done -- run 'exec zsh'"
}

# --- prompt (starship) ------------------------------------------------------
# Replaced powerlevel10k: its README declares limited support / most bugs
# unfixed, and with the git markers gone it was running a ~20MB gitstatusd
# daemon per shell purely to print a branch name.
eval "$(starship init zsh)"

# Local, untracked overrides.
[[ -f $HOME/.zshrc.local ]] && source $HOME/.zshrc.local

# Keep the bytecode fresh. Without this, editing ~/.zshrc would have no effect
# until the stale ~/.zshrc.zwc was deleted by hand.
if [[ ! $HOME/.zshrc.zwc -nt $HOME/.zshrc ]]; then
  { zcompile -R -- $HOME/.zshrc } &!
fi


# ----- custom aliases ------------------
alias pt='pytest'
alias py='python'
alias cc='claude'
alias gc='git checkout'

