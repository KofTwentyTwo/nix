# CA Certificates Module
# =====================
# Manages custom CA certificates bundle for SSL/TLS verification.
# This is useful for corporate networks or self-signed certificates.
#
# The certificate bundle is installed to ~/.config/ca-certs.pem
# and referenced by SSL_CERT_FILE environment variable (see zsh/default.nix)
#
# To update certificates:
#   1. Update ./config/ca-certs.pem
#   2. Run: darwin-rebuild switch --flake ~/.config/nix

{ config, pkgs, lib, ... }:
{
   config = {
      # Install CA certificates bundle
      home.file."./.config/ca-certs.pem" = {
         source = ./config/ca-certs.pem;
      };
   };
}
