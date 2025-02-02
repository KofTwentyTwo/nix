{ config, pkgs, lib, ... }:

{
  programs.k9s = {
    enable = true;
    settings = {
      k9s = {
        namespace = {
          favorites = [ "default" "kube-system" "qrun-io" "traefik" "-" ];
        };
      };
    };
  };
}
