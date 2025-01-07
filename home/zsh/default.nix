{ config, pkgs, lib, ... }:
{
   config = {
      programs.zsh = {
         enable = true;
         enableCompletion = true;
         syntaxHighlighting.enable = true;
         enableVteIntegration = true;
         autosuggestion.strategy = "completion";
         initExtra = "export TERM=wezterm";

         initExtraBeforeCompInit = "eval \"$(task --completion zsh)\" ";

         shellAliases = {
            switch      = "clear;darwin-rebuild switch --flake ~/.config/nix";
            hist        = "history";
            ping        = "gping";
            tl          = "task --list-all";
            t           = "task";
            k           = "kubectl";
            ssh-clean   = "ssh-keygen -R"
         };

         history = {
            size = 10000;
            save = 100000;
         };
      };
   };
}
