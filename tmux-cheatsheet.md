# tmux cheat sheet - your config

Prefix is **`Ctrl-a`**. Tap it, *release*, then press the next key. Written
`C-a X`. Press **`C-a ?`** any time to pop this sheet up over your work.

- **tab set** (tmux calls it a session) - one per folder/tree. Survives closing VSCode.
- **tab** (tmux calls it a window) - listed along the bottom status bar.
- **pane** - a split inside one tab.

---

## The mouse already works

| Do this | Result |
| --- | --- |
| Click a pane | Focus it |
| Drag a pane border | Resize |
| Click a name in the bottom bar | Switch to that tab |
| Scroll wheel over a pane | Scroll back through output |
| Drag to select text | Copies it (goes to your system clipboard too) |
| Double / triple click | Select a word / the whole line |
| Right-click a pane | Menu: split, swap, zoom, kill, copy |
| Right-click a tab name | Menu: rename, move left/right, kill, new |
| Right-click the session name (far left) | Menu: new / rename / detach |

---

## Tabs

| Key | Does |
| --- | --- |
| `C-a c` | New tab, in the current directory |
| `C-a 1` … `C-a 9` | Jump straight to tab N (numbered from 1) |
| `C-a n` | Next tab |
| `C-a C-h` / `C-a C-l` | Previous / next - hold `C-a`, keep tapping `h`/`l` |
| `C-a a` | Toggle between the last two tabs |
| `C-a ,` | **Rename this tab** - current name is pre-filled, edit and Enter |
| `C-a <` | Tab menu - rename, **move left/right** (this is how you reorder), kill |
| `C-a w` | Visual picker of every tab |
| `C-a f` | Find a tab by name |

Tabs auto-name themselves after whatever is running. Rename one by hand and it
sticks - tmux stops auto-naming that tab from then on.

> `C-a p` is **not** previous-tab here - it pastes. Previous tab is `C-a C-h`.

---

## Panes

| Key | Does |
| --- | --- |
| `C-a \|` | Split **left/right** (the key looks like the split) |
| `C-a -` | Split **top/bottom** |
| `Alt-Left/Right/Up/Down` | Move between panes - **no prefix needed** |
| `C-a` + arrow | Same thing, if you'd rather use the prefix |
| `C-a h` `j` `k` `l` | Move left / down / up / right (vim keys) |
| `C-a H` `J` `K` `L` | Resize by 5 - hold `C-a`, tap `L L L` to keep going |
| `C-a z` | **Zoom** this pane fullscreen; press again to restore |
| `C-a Space` | Cycle preset layouts |
| `C-a q` | Flash a number on each pane; press one to jump there |
| `C-a ;` | Jump to the last pane |
| `C-a !` | Pop this pane out into its own tab |
| `C-a @` | Pull the previous tab in as a side-by-side pane |
| `C-a e` | Type into **all** panes at once; press again to stop |
| `C-a >` | Pane menu - split, swap, zoom, kill, copy |

A `+` beside a tab name means a pane in it is zoomed. If arrow keys seem to do
nothing, that's usually it - you're looking at one pane filling the screen.

---

## Closing things

| Key | Closes |
| --- | --- |
| `C-a x` | This **pane** (asks y/n) |
| `exit` or `Ctrl-D` | This pane, no confirmation |
| `C-a &` | This **tab** and every pane in it (asks y/n) |
| `C-a X` | This whole **tab set** (asks y/n) |

Closing the last pane in a tab closes the tab too.

---

## Tab sets (one per folder)

Open a terminal anywhere under a tree and you land in that tree's tab set.
A second VSCode window on the *same* tree joins the *same* tabs, but each window
sits on whichever tab it likes. A different clone or worktree gets its own set.

| Key / command | Does |
| --- | --- |
| `C-a s` | **Picker of every tab set** - arrows to move, Enter to switch |
| `C-a )` / `C-a (` | Next / previous tab set |
| `C-a $` | Rename this tab set |
| `C-a d` | Detach - everything keeps running in the background |
| `tl` | List them from the shell |
| `ta <name>` | Attach to one by name |

Because the shell hands itself over to tmux, `C-a d` closes the terminal window
too. The tab set keeps running; your next terminal in that tree lands back in it.
For a plain shell with no tmux at all: `NO_TMUX=1 zsh`.

---

## Scrolling and copying

| Key | Does |
| --- | --- |
| Scroll wheel | Enters scrollback automatically |
| `C-a v` | Enter copy/scroll mode |
| `C-a /` | Copy mode, searching backwards |
| `v` then move | Start a selection |
| `C-v` | Toggle block/rectangle selection |
| `y` | Copy and exit |
| `C-a p` | Paste it back into a pane |
| `q` or `Escape` | Leave copy mode |

Scrollback is 100k lines per pane. Copies also go to your system clipboard, so
`Ctrl-V` works in other apps.

---

## Help and gotchas

| Key | Does |
| --- | --- |
| `C-a ?` | This sheet, in a floating window (`q` to close) |
| `C-a B` | tmux's own raw list of every binding |
| `C-a r` | Reload `~/.tmux.conf` after editing it |

1. **`Ctrl-a` no longer jumps to the start of a line in zsh** - tmux takes it.
   Press `C-a C-a` to send a real one through, or just use `Home`.
2. **`C-a p` pastes**, it does not go to the previous tab.
3. If arrow keys stop moving between panes after a config change, check
   `escape-time` is not `0` - VSCode sends Alt/arrow keys as two chunks and tmux
   needs a few milliseconds to put them back together.
