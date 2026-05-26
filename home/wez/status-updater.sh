#!/usr/bin/env bash
# Background data collector for the WezTerm status bar.
#
# Why this exists:
#   WezTerm's update-status callback runs on the GUI main thread. Calling
#   io.popen()/wezterm.run_child_process() from there blocks the renderer
#   until the subprocess closes its stdout. With ~10 spawns/sec across git,
#   kubectl, sysctl, netstat, and ps, any subprocess slowness (DNS reconfig,
#   slow disk, big git repo) beachballs every wezterm window simultaneously.
#
# Design:
#   This daemon does the gathering off the GUI thread and writes
#   ~/.cache/wezterm/status.kv every second. The Lua config reads that file
#   (a microsecond local-FS read) and renders from it. Daemon and renderer
#   are fully decoupled.
#
#   WezTerm writes the active pane's cwd to ~/.cache/wezterm/cwd so the
#   daemon can scope git queries to the right directory.

set -u

CACHE="$HOME/.cache/wezterm"
STATUS="$CACHE/status.kv"
CWD_REQ="$CACHE/cwd"
LOCK="$CACHE/updater.pid"

mkdir -p "$CACHE"

# Single-instance: bail if a live daemon already owns the lock.
if [ -f "$LOCK" ]; then
    existing=$(cat "$LOCK" 2>/dev/null)
    if [ -n "$existing" ] && kill -0 "$existing" 2>/dev/null; then
        exit 0
    fi
fi
echo "$$" > "$LOCK"
trap 'rm -f "$LOCK"' EXIT

i=0
prev_rx=0
prev_tx=0
k8s_ctx=""
k8s_ns=""
git_cwd=""
git_branch=""
git_conf=0; git_untrack=0; git_ren=0
git_staged=0; git_mod=0; git_del=0
git_ahead=0; git_behind=0; git_stash=0
last_cwd=""

while :; do
    # Self-exit when no wezterm-gui is running — keeps us from orphaning.
    if ! pgrep -x wezterm-gui >/dev/null 2>&1; then
        exit 0
    fi

    # --- Per-tick: load average ---
    load=$(sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}')
    load=${load:--.--}

    # --- Per-tick: net rates on en0 ---
    # netstat -ib columns: Name Mtu Network Address Ipkts Ierrs Ibytes Opkts Oerrs Obytes Coll
    read -r rx tx <<<"$(netstat -ib 2>/dev/null | awk '$1=="en0" && !seen{print $7, $10; seen=1}')"
    rx=${rx:-0}
    tx=${tx:-0}
    if [ "$prev_rx" -gt 0 ] 2>/dev/null; then
        net_rx=$(( rx - prev_rx ))
        net_tx=$(( tx - prev_tx ))
        [ "$net_rx" -lt 0 ] && net_rx=0
        [ "$net_tx" -lt 0 ] && net_tx=0
    else
        net_rx=0
        net_tx=0
    fi
    prev_rx=$rx
    prev_tx=$tx

    # --- Every 5 ticks: kubectl context (heaviest, least time-sensitive) ---
    if [ $((i % 5)) -eq 0 ]; then
        k8s_ctx=$(kubectl config current-context 2>/dev/null)
        if [ -n "$k8s_ctx" ]; then
            k8s_ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
            [ -z "$k8s_ns" ] && k8s_ns="default"
        else
            k8s_ns=""
        fi
    fi

    # --- Every 2 ticks OR on cwd change: git info for the active pane's cwd ---
    cwd=""
    [ -r "$CWD_REQ" ] && cwd=$(cat "$CWD_REQ" 2>/dev/null)
    if [ -n "$cwd" ] && [ -d "$cwd" ] && { [ $((i % 2)) -eq 0 ] || [ "$cwd" != "$last_cwd" ]; }; then
        if branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null); then
            git_cwd="$cwd"
            git_branch="$branch"
            git_conf=0; git_untrack=0; git_ren=0
            git_staged=0; git_mod=0; git_del=0

            while IFS= read -r line; do
                [ -z "$line" ] && continue
                idx=${line:0:1}
                wt=${line:1:1}
                if [ "$idx" = "U" ] || [ "$wt" = "U" ] \
                   || { [ "$idx" = "A" ] && [ "$wt" = "A" ]; } \
                   || { [ "$idx" = "D" ] && [ "$wt" = "D" ]; }; then
                    git_conf=$((git_conf + 1))
                elif [ "$idx" = "?" ]; then
                    git_untrack=$((git_untrack + 1))
                elif [ "$idx" = "R" ]; then
                    git_ren=$((git_ren + 1))
                else
                    if [ "$idx" != " " ] && [ "$idx" != "?" ]; then
                        git_staged=$((git_staged + 1))
                    fi
                    if [ "$wt" = "M" ]; then
                        git_mod=$((git_mod + 1))
                    elif [ "$wt" = "D" ]; then
                        git_del=$((git_del + 1))
                    fi
                fi
            done < <(git -C "$cwd" status --porcelain 2>/dev/null)

            ab=$(git -C "$cwd" rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)
            git_ahead=${ab%%$'\t'*}
            git_behind=${ab##*$'\t'}
            [[ "$git_ahead" =~ ^[0-9]+$ ]] || git_ahead=0
            [[ "$git_behind" =~ ^[0-9]+$ ]] || git_behind=0

            git_stash=$(git -C "$cwd" stash list 2>/dev/null | wc -l | tr -d ' ')
            [[ "$git_stash" =~ ^[0-9]+$ ]] || git_stash=0
        else
            git_cwd="$cwd"
            git_branch=""
            git_conf=0; git_untrack=0; git_ren=0
            git_staged=0; git_mod=0; git_del=0
            git_ahead=0; git_behind=0; git_stash=0
        fi
        last_cwd="$cwd"
    elif [ -z "$cwd" ] || [ ! -d "$cwd" ]; then
        git_cwd=""
        git_branch=""
        git_conf=0; git_untrack=0; git_ren=0
        git_staged=0; git_mod=0; git_del=0
        git_ahead=0; git_behind=0; git_stash=0
        last_cwd=""
    fi

    # --- Atomic write ---
    tmp="$STATUS.tmp"
    {
        echo "ts=$(date +%s)"
        echo "load=$load"
        echo "net_rx=$net_rx"
        echo "net_tx=$net_tx"
        echo "k8s_ctx=$k8s_ctx"
        echo "k8s_ns=$k8s_ns"
        echo "git_cwd=$git_cwd"
        echo "git_branch=$git_branch"
        echo "git_conf=$git_conf"
        echo "git_untrack=$git_untrack"
        echo "git_ren=$git_ren"
        echo "git_staged=$git_staged"
        echo "git_mod=$git_mod"
        echo "git_del=$git_del"
        echo "git_ahead=$git_ahead"
        echo "git_behind=$git_behind"
        echo "git_stash=$git_stash"
    } > "$tmp"
    mv -f "$tmp" "$STATUS"

    i=$((i + 1))
    sleep 1
done
