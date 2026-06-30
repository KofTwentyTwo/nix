# Viscosity VPN Client Configuration
# ====================================
# Deploys OpenVPN connection bundles to Viscosity's config directory AND
# reproduces the Viscosity sidebar folder structure. Config files are
# git-crypt encrypted in the repo (see .gitattributes: configs/**).
#
# Nix is AUTHORITATIVE for the connection/folder layout: each activation
# rebuilds the plist's :ConnectionOrder to match `folders` below. Reorganizing
# folders or setting per-connection options in Viscosity's UI will be
# overwritten on the next `darwin-rebuild switch` — change them here instead.

{ config, lib, pkgs, ... }:

let
  viscosityDir = "Library/Application Support/Viscosity/OpenVPN";
  configDir = ./configs;

  # Each connection: slot number -> { name = configs/<name> dir; extras = files
  # beyond the base set }. The slot number IS the on-disk folder name under
  # Viscosity's OpenVPN/ dir and the stable id referenced by `folders`.
  connections = {
    "1" = { name = "dev";                  extras = []; };          # me-health-portal-dev
    "2" = { name = "prod";                 extras = []; };          # me-health-portal-prod
    "3" = { name = "staging";              extras = []; };          # me-health-portal-staging
    "4" = { name = "st-marys-lan";         extras = [ "ta.key" ]; };
    "5" = { name = "galaxy-lan";           extras = [ "ta.key" ]; };
    "6" = { name = "greater-goods-dev";    extras = []; };
    "7" = { name = "greater-goods-staging"; extras = []; };
    # When the greater-goods prod bundle exists, add it here as "8" and append
    # "8" to the "Greater Goods - AFT" folder below.
  };

  # Viscosity sidebar folders (order = display order). `slots` lists the slot
  # ids in each folder, in display order. This mirrors the structure captured
  # from the live machine on 2026-06-01.
  folders = [
    { name = "Greater Goods - AFT";    slots = [ "7" "6" ]; }
    { name = "Greater Goods - Legacy"; slots = [ "2" "3" "1" ]; }
    { name = "Personal";               slots = [ "5" ]; }
    { name = "Clients";                slots = [ "4" ]; }
  ];

  # Base files present in every connection
  baseFiles = [ "config.conf" "ca.crt" "cert.crt" "key.key" ];

  # ---- file deployment (symlinks into the nix store) ----
  mkFileEntry = slot: dir: file: {
    "${viscosityDir}/${slot}/${file}" = {
      source = "${configDir}/${dir}/${file}";
    };
  };

  mkConnection = slot: conn:
    let allFiles = baseFiles ++ conn.extras;
    in lib.foldl (acc: file: acc // mkFileEntry slot conn.name file) {} allFiles;

  # ---- plist :ConnectionOrder reproduction ----
  # Build the nested nix value that matches Viscosity's plist schema, then
  # render it to an Apple XML plist (root = array). Field values mirror what
  # Viscosity writes: folders carry sharedAuth/sharedReconnect=false; openvpn
  # entries carry empty options + empty children.
  mkOpenvpnEntry = slot: {
    options = {};
    name = slot;
    type = "openvpn";
    children = [];
  };

  mkFolderEntry = folder: {
    # Viscosity requires boolean false here, not the string "false".
    options = { sharedAuth = false; sharedReconnect = false; };
    type = "folder";
    name = folder.name;
    children = map mkOpenvpnEntry folder.slots;
  };

  connectionOrderValue = map mkFolderEntry folders;

  connectionOrderPlist = pkgs.writeText "viscosity-connectionorder.plist"
    (lib.generators.toPlist {} connectionOrderValue);
in
{
  # Viscosity is a macOS-only VPN client. Guard the whole module so Linux
  # (WSL) does not deploy dead ~/Library symlinks or run the plutil activation.
  config = lib.mkIf pkgs.stdenv.isDarwin {
  home.file = lib.mkMerge (lib.mapAttrsToList mkConnection connections);

  # Reproduce Viscosity's :ConnectionOrder (folders + connections) from the nix
  # declaration above. Idempotent: only rewrites + restarts Viscosity when the
  # live structure differs from the desired one (a normalized JSON compare),
  # so a no-op `switch` never drops an active VPN session.
  #
  # NB: never use bare `exit 0` to skip — home-manager runs every
  # `home.activation.*` block as one bash process, so `exit` aborts every
  # downstream activation (notably syncClaudeJson). Wrap the body in `if`.
  home.activation.viscosityConnections = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PLIST="$HOME/Library/Preferences/com.viscosityvpn.Viscosity.plist"
    DESIRED="${connectionOrderPlist}"

    # Skip if Viscosity has never been launched (no plist yet). It will be
    # seeded on the next switch after first launch.
    if [ -f "$PLIST" ]; then
      desired_json=$(/usr/bin/plutil -convert json -o - "$DESIRED" 2>/dev/null \
        | ${pkgs.jq}/bin/jq -S . 2>/dev/null || echo "DESIRED_ERR")
      current_json=$(/usr/bin/plutil -extract ConnectionOrder json -o - "$PLIST" 2>/dev/null \
        | ${pkgs.jq}/bin/jq -S . 2>/dev/null || echo "MISSING")

      if [ "$desired_json" = "DESIRED_ERR" ]; then
        echo "viscosity: could not render desired ConnectionOrder; leaving plist untouched" >&2
      elif [ "$desired_json" != "$current_json" ]; then
        # Quit Viscosity before writing — cfprefsd caches preferences for the
        # running app and Viscosity would overwrite any change made while open.
        viscosity_was_running=false
        if pgrep -x Viscosity >/dev/null 2>&1; then
          osascript -e 'tell application "Viscosity" to quit' 2>/dev/null || true
          sleep 1
          viscosity_was_running=true
        fi

        # plutil -replace writes the JSON as a typed plist value (array of dicts).
        /usr/bin/plutil -replace ConnectionOrder -json "$desired_json" "$PLIST"
        killall cfprefsd 2>/dev/null || true
        echo "viscosity: ConnectionOrder updated from nix declaration"

        if [ "$viscosity_was_running" = true ]; then
          open -a Viscosity
        fi
      fi
    fi
  '';
  };
}
