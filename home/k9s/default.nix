# K9s Configuration Module
# =======================
# Configures k9s, a terminal UI for Kubernetes clusters.
#
# Features:
#   - Favorite namespaces for quick access
#   - Custom k9s settings
#
# Portability:
#   - Works on any machine with k9s installed
#   - Namespace favorites can be customized per machine if needed

{ config, pkgs, lib, ... }:

{
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        namespace = {
          # Favorite namespaces shown at the top of namespace list
          favorites = [ "default" "kube-system" "qrun-io" "traefik" "-" ];
        };
      };
    };
  };
}
