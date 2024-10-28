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

         shellAliases = {
            switch   = "clear;darwin-rebuild switch --flake ~/.config/nix";
            hist     = "history";
            ping     = "gping";
            gc       = "git commit -m ";
            ga       = "git add ";
            gr       = "git rm ";
            gp       = "git push ";
            gs       = "git status ";
            gd       = "git diff ";
         };

         history = {
            size = 10000;
            save = 100000;
         };

      };
   };
}
