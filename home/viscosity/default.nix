# Viscosity VPN Client Configuration
# ====================================
# Deploys OpenVPN connection bundles to Viscosity's config directory.
# Config files are git-crypt encrypted in the repo.

{ config, lib, pkgs, ... }:

let
  viscosityDir = "Library/Application Support/Viscosity/OpenVPN";
  configDir = ./configs;

  # Each connection: slot number, config dir name, extra files beyond the base set
  connections = {
    "1" = { name = "dev";           extras = []; };
    "2" = { name = "prod";          extras = []; };
    "3" = { name = "staging";       extras = []; };
    "4" = { name = "st-marys-lan";  extras = [ "ta.key" ]; };
    "5" = { name = "galaxy-lan";    extras = [ "ta.key" ]; };
  };

  # Base files present in every connection
  baseFiles = [ "config.conf" "ca.crt" "cert.crt" "key.key" ];

  # Generate home.file entries for all files in a connection
  mkFileEntry = slot: dir: file: {
    "${viscosityDir}/${slot}/${file}" = {
      source = "${configDir}/${dir}/${file}";
    };
  };

  mkConnection = slot: conn:
    let allFiles = baseFiles ++ conn.extras;
    in lib.foldl (acc: file: acc // mkFileEntry slot conn.name file) {} allFiles;

  # All slot numbers for the activation script
  allSlots = lib.attrNames connections;
in
{
  home.file = lib.mkMerge (lib.mapAttrsToList mkConnection connections);

  # Register connections in Viscosity's plist on activation
  # NB: never use bare `exit 0` to skip — home-manager runs every
  # `home.activation.*` block as one bash process, so `exit` aborts every
  # downstream activation (notably syncClaudeJson). Wrap the body in `if`.
  home.activation.viscosityConnections = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PLIST="$HOME/Library/Preferences/com.viscosityvpn.Viscosity.plist"

    # Skip if Viscosity has never been launched (no plist yet)
    if [ -f "$PLIST" ]; then
      PLISTBUDDY=/usr/libexec/PlistBuddy
      changed=false

      for slot in ${lib.concatStringsSep " " allSlots}; do
        # Check if this slot is already registered
        if ! $PLISTBUDDY -c "Print :ConnectionOrder" "$PLIST" 2>/dev/null | grep -q "name = $slot"; then
          # Find the next array index
          count=$($PLISTBUDDY -c "Print :ConnectionOrder" "$PLIST" 2>/dev/null | grep -c "name = " || echo "0")
          $PLISTBUDDY \
            -c "Add :ConnectionOrder:$count dict" \
            -c "Add :ConnectionOrder:$count:name string $slot" \
            -c "Add :ConnectionOrder:$count:type string openvpn" \
            -c "Add :ConnectionOrder:$count:children array" \
            -c "Add :ConnectionOrder:$count:options dict" \
            "$PLIST" 2>/dev/null
          changed=true
        fi
      done

      # Restart Viscosity if we added connections and it's running
      if [ "$changed" = true ]; then
        if pgrep -x Viscosity >/dev/null 2>&1; then
          osascript -e 'tell application "Viscosity" to quit' 2>/dev/null || true
          sleep 1
          open -a Viscosity
        fi
      fi
    fi
  '';
}
