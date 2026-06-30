# PLAN: Tailscale on Linux/WSL (rootless, via Home Manager)

Status: implemented 2026-06-30. Final connection is user-gated on minting an auth key.

## Goal

Put every Linux machine on the tailnet "too" (the Macs already are, via the
`tailscale-app` cask + `modules/tailscale.nix`). Linux here is **standalone
Home Manager running as the unprivileged user** — there is no nix-darwin/NixOS
and therefore no `services.tailscale`.

## Decisions (confirmed with the user)

| Axis | Choice | Why |
|------|--------|-----|
| Daemon mode | **Userspace networking** (`tailscaled --tun=userspace-networking`) | No root, no `/dev/net/tun`, no kernel module. Runs identically on WSL2 / native / container. Plain-client role only. |
| Process model | **systemd *user* service** (HM `systemd.user.services`) | This box has `systemd=true` in `/etc/wsl.conf` and `systemctl --user` = `running`. Native Linux analogue of the macOS `launchctl asuser` dance. |
| Auth | **Reusable auth key in sops** → regular file via `mkPatDeployer` | Hands-off join. Matches the repo's existing secret pattern; avoids sops-nix's fail-fast batch coupling. |
| Tailscale SSH | **on** (`--ssh`) | User chose "reachable via Tailscale SSH". |
| DNS | `--accept-dns=false` | Rootless can't rewrite `/etc/resolv.conf`; avoids a no-op that logs errors. |
| Routes | `--accept-routes` | Learn subnet routes (e.g. Grogu's `10.100.0.0/16`); reachable via the proxy. |
| Outbound to tailnet | **SOCKS5 proxy on `localhost:1055`** | Userspace mode has no `tailscale0`; outbound goes through the proxy (`ALL_PROXY=socks5h://localhost:1055 …`). NOT exported globally. |

## Files

- **NEW** `home/tailscale/default.nix` — package + 2 user services + CLI alias, all under `lib.mkIf pkgs.stdenv.isLinux` (no-op on macOS).
- `home/default.nix` — add `./tailscale` to `imports`.
- `home/sops/default.nix` — Linux-guarded `deployTailscaleAuthkey` (double-guarded on `builtins.pathExists`); add it to `ensureSecretsDir`'s `entryBefore`.
- `.sops.yaml` — add `&lore` recipient + `creation_rule` for `secrets/tailscale-authkey\.enc`.
- **NEW (user step)** `secrets/tailscale-authkey.enc`.

## Socket detail (the rootless gotcha)

A non-root daemon can't use `/var/run/tailscale/tailscaled.sock`. We use
`$XDG_RUNTIME_DIR/tailscale/tailscaled.sock` (systemd `%t` + `RuntimeDirectory`),
state under `%S/tailscale` (`~/.local/state/tailscale`). The `tailscale` **CLI**
defaults to the root socket, so a Linux-only shell alias pins it to the user
socket — otherwise `tailscale status` says "failed to connect".

## Remaining manual steps (cannot be automated)

1. **Mint the key** — admin console → Settings → Keys → generate a **reusable**
   auth key (consider "pre-approved" + a tag). Then encrypt it:
   ```bash
   printf '%s' 'tskey-auth-XXXXXXXX' \
     | SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt \
       sops -e --filename-override secrets/tailscale-authkey.enc \
            --input-type binary --output-type binary /dev/stdin \
       > secrets/tailscale-authkey.enc
   git add secrets/tailscale-authkey.enc          # flakes only see tracked files
   home-manager switch --flake .#james
   # the systemd units are unchanged, so switch won't re-run the oneshot —
   # nudge it once to consume the freshly-deployed key (or just reboot/WSL restart):
   systemctl --user start tailscale-autoconnect
   ```
2. **Tailnet ACL** must permit Tailscale SSH to this node for SSH-in to work.
3. *(Optional, always-on)* `sudo loginctl enable-linger james` so `tailscaled`
   runs before you open a WSL shell. Otherwise it starts with your first shell.
4. **Key rotation** — reusable keys expire (≤90d): re-run step 1 with a fresh key.

## Adding another Linux machine

All Linux boxes share the `#james` config (identical plain-client prefs;
Tailscale uses each host's own hostname). To onboard box #2:

```bash
age-keygen -y ~/.config/sops/age/keys.txt          # on the new box: its pubkey
# add that pubkey to .sops.yaml (keys: + the tailscale-authkey creation_rule)
sops updatekeys secrets/tailscale-authkey.enc       # from any host that can decrypt
git add .sops.yaml secrets/tailscale-authkey.enc && git commit
home-manager switch --flake .#james                 # on the new box
```

## Verify

```bash
systemctl --user status tailscaled tailscale-autoconnect
tailscale status            # (alias -> user socket)
journalctl --user -u tailscale-autoconnect -n 30
```

## Out of scope

Kernel-mode `tailscale0`, exit-node / subnet-router duties, system MagicDNS —
all require the root system daemon ("Full nodes" path, not chosen).
