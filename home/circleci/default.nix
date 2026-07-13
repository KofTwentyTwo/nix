# CircleCI CLI Configuration Module
# =================================
# Authenticates the `circleci` CLI on every platform by writing its native
# config file (~/.circleci/cli.yml) from the sops-deployed token.
#
# Distinct from the MCP server: home/zsh exports CIRCLECI_TOKEN (read by the
# circleci-mcp-server), while the CLI reads ~/.circleci/cli.yml (or the
# CIRCLECI_CLI_TOKEN env var). Before this module, WSL's cli.yml was an empty
# 0-byte file and Windows had none — so the CLI was effectively unauthenticated
# even though the MCP token was present.
#
# Token source: ~/.config/secrets/circleci-token, decrypted from
# secrets/circleci-token.enc by home/sops (deployCircleciToken). This module's
# activations run after that so the token file exists.
#
# The CLI package itself: circleci-cli in home/linux-cli (Linux/WSL), `circleci`
# in modules/homebrew.nix (macOS), and circleci-cli via scoop on Windows
# (windows/scoop.json).

{ config, pkgs, lib, ... }:

let
  homeDir = config.home.homeDirectory;
  tokenFile = "${homeDir}/.config/secrets/circleci-token";

  # Emit ~/.circleci/cli.yml (mode 0600) from a token file. host/token are the
  # two keys `circleci setup` writes; the CLI derives API endpoints from host.
  writeCliYml = ''
    if [ -r "${tokenFile}" ]; then
      mkdir -p "${homeDir}/.circleci"
      tok="$(cat "${tokenFile}")"
      umask 077
      printf 'host: https://circleci.com\ntoken: %s\n' "$tok" > "${homeDir}/.circleci/cli.yml"
      chmod 600 "${homeDir}/.circleci/cli.yml"
    else
      echo "[circleci] token file ${tokenFile} not present; skipping cli.yml" >&2
    fi
  '';
in
{
  # Native cli.yml on the host running this activation (WSL/mac).
  home.activation.circleciCliConfig =
    lib.hm.dag.entryAfter [ "writeBoundary" "deployCircleciToken" ] writeCliYml;

  # LORE bridge: same cli.yml for Windows-native circleci (scoop). Resolves ~
  # to the Windows profile, so both PowerShell and Claude's Git Bash authenticate
  # with no env var and no Claude restart. Written fresh (no store read-only
  # attribute concern).
  home.activation.syncWindowsCircleci = lib.mkIf pkgs.stdenv.isLinux
    (lib.hm.dag.entryAfter [ "circleciCliConfig" ] ''
      win="/mnt/c/Users/james"
      if [ -d "$win" ] && [ -r "${tokenFile}" ]; then
        mkdir -p "$win/.circleci"
        tok="$(cat "${tokenFile}")"
        printf 'host: https://circleci.com\ntoken: %s\n' "$tok" > "$win/.circleci/cli.yml"
        echo "[circleci-win] cli.yml written to Windows profile"
      fi
    '');
}
