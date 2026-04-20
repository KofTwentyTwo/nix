#!/usr/bin/env bash
# tmux-help.sh - Interactive tmux command palette
# Launched by prefix+Space, uses fzf inside a tmux popup.
# Fuzzy search, arrow keys to navigate, Enter to execute.
#
# Interactive commands (rename, new session, etc.) prompt inside the popup
# via bash read, then send the direct tmux command. This avoids context
# issues with command-prompt running from inside display-popup.

# Capture current state for interactive prompts
CURRENT_SESSION=$(tmux display-message -p '#S')
CURRENT_WINDOW=$(tmux display-message -p '#W')

# Interactive handlers - prompt inside the popup, run direct tmux command
run_interactive() {
  local action="$1"
  case "$action" in
    rename-session)
      printf "Rename session [%s]: " "$CURRENT_SESSION"
      read -r name
      [[ -z "$name" ]] && exit 0
      tmux rename-session -t "=$CURRENT_SESSION" -- "$name"
      ;;
    new-session)
      printf "New session name: "
      read -r name
      [[ -z "$name" ]] && exit 0
      tmux new-session -d -s "$name"
      tmux switch-client -t "$name"
      ;;
    rename-window)
      printf "Rename window [%s]: " "$CURRENT_WINDOW"
      read -r name
      [[ -z "$name" ]] && exit 0
      tmux rename-window -- "$name"
      ;;
    find-window)
      printf "Find window: "
      read -r pattern
      [[ -z "$pattern" ]] && exit 0
      tmux find-window -Z -- "$pattern"
      ;;
    move-window)
      printf "Move window to index: "
      read -r idx
      [[ -z "$idx" ]] && exit 0
      tmux move-window -t "$idx"
      ;;
  esac
}

# Format: "hotkey | description | command"
# command is either a tmux command or @action for interactive handlers
commands=(
  "# Sessions"
  "prefix s       | Pick session (tree view)               | choose-tree -Zs"
  "prefix S       | New named session                      | @new-session"
  "prefix \$       | Rename current session                 | @rename-session"
  "prefix d       | Detach from session                    | detach-client"
  "prefix L       | Lock session (screensaver)             | lock-session"
  "# Windows"
  "prefix c       | New window                             | new-window"
  "prefix ,       | Rename window                          | @rename-window"
  "prefix n       | Next window                            | next-window"
  "prefix p       | Previous window                        | previous-window"
  "prefix w       | Pick window (tree view)                | choose-tree -Zw"
  "prefix 0-9     | Jump to window by number               | "
  "prefix &       | Kill window                            | confirm-before -p 'kill window? (y/n)' kill-window"
  "# Panes"
  "prefix \"       | Split horizontal                       | split-window -v"
  "prefix %       | Split vertical                         | split-window -h"
  "prefix z       | Zoom/unzoom pane                       | resize-pane -Z"
  "prefix x       | Kill pane                              | confirm-before -p 'kill pane? (y/n)' kill-pane"
  "prefix !       | Break pane to new window               | break-pane"
  "prefix q       | Show pane numbers (then press number)  | display-panes"
  "prefix {       | Move pane left                         | swap-pane -U"
  "prefix }       | Move pane right                        | swap-pane -D"
  "prefix arrows  | Navigate between panes                 | "
  "# Resize Panes"
  "prefix M-Up    | Resize pane up                         | resize-pane -U 5"
  "prefix M-Down  | Resize pane down                       | resize-pane -D 5"
  "prefix M-Left  | Resize pane left                       | resize-pane -L 5"
  "prefix M-Right | Resize pane right                      | resize-pane -R 5"
  "# Copy Mode"
  "prefix [       | Enter copy mode (scroll/select)        | copy-mode"
  "prefix ]       | Paste buffer                           | paste-buffer"
  "prefix t       | Thumbs mode (quick copy)               | thumbs-pick"
  "# Custom"
  "F12            | Toggle remote mode (nested SSH tmux)   | "
  "prefix Space   | This help menu                         | "
  "# Miscellaneous"
  "prefix ?       | List all keybindings (raw)             | list-keys"
  "prefix :       | Command prompt                         | command-prompt"
  "prefix ~       | Show messages                          | show-messages"
  "prefix f       | Find window by name                    | @find-window"
  "prefix .       | Move window to index                   | @move-window"
)

# Build the list for fzf, skip section headers for execution but show them
display_lines=()
for entry in "${commands[@]}"; do
  if [[ "$entry" == "# "* ]]; then
    # Section header - strip # and format
    header="${entry#\# }"
    display_lines+=("─── ${header} ───")
  else
    # Extract hotkey and description
    hotkey=$(echo "$entry" | cut -d'|' -f1 | sed 's/[[:space:]]*$//')
    desc=$(echo "$entry" | cut -d'|' -f2 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    printf -v line "%-16s  %s" "$hotkey" "$desc"
    display_lines+=("$line")
  fi
done

# Run fzf with the display lines
selected=$(printf '%s\n' "${display_lines[@]}" | fzf \
  --ansi \
  --no-sort \
  --reverse \
  --border=rounded \
  --border-label=" Tmux Help " \
  --border-label-pos=3 \
  --prompt="Search: " \
  --pointer="▶" \
  --margin=0 \
  --padding=0 \
  --info=hidden \
  --header="Arrow keys to navigate, Enter to run, Esc to close" \
  --header-first \
  --color="fg:white,bg:black,hl:green,fg+:green,bg+:#1a1a1a,hl+:green:bold,border:green,label:green:bold,header:yellow,prompt:cyan,pointer:green,info:cyan" \
  --bind="enter:accept" \
  --no-multi)

# Exit if nothing selected or if it's a header
[[ -z "$selected" ]] && exit 0
[[ "$selected" == "───"* ]] && exit 0

# Find the matching command entry and extract the tmux command
selected_hotkey=$(echo "$selected" | sed 's/[[:space:]]*  .*//')
for entry in "${commands[@]}"; do
  [[ "$entry" == "# "* ]] && continue
  hotkey=$(echo "$entry" | cut -d'|' -f1 | sed 's/[[:space:]]*$//')
  cmd=$(echo "$entry" | cut -d'|' -f3 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  if [[ "$hotkey" == "$selected_hotkey" && -n "$cmd" ]]; then
    if [[ "$cmd" == @* ]]; then
      # Interactive handler - prompt inside the popup
      run_interactive "${cmd#@}"
    else
      # Direct tmux command
      eval "tmux $cmd"
    fi
    exit 0
  fi
done
