{ config, pkgs, lib, ... }:
{
  config = {
    programs.zsh.oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "docker" "kubectl" ];
    };
  };
}
