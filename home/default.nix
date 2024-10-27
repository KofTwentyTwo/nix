{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.my-home;
in
{

  imports = [
    # ./kitty
    #./zsh
    #./starship
    #./git
    # ./nvim
    #./tmux
    #./direnv
    #./games
    #./gh
  ];

  options.my-home = {
    includeFonts = lib.mkEnableOption "fonts";
    useNeovim = lib.mkEnableOption "neovim";
  };

  config = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    home = {
      sessionVariables = {
        EDITOR = "vim";
        VISUAL = "vim";
        PAGER = "less";
      };

      packages = with pkgs; let
        commonPackages = [
          # command line utilities
          ack
          curl
          htop
          # fastfetch
          tldr
          wget
          comma
          nix-cleanup
        ];
        fontPackages = [
          # Fonts
          nerdfonts
          cozette
          scientifica
          monocraft
        ];
        vimPackage = [ vim ];
        workPackages = [
          # Work packages
          #postgresql
          #awscli2
          #oktoast
          #toast-services
          #pizzabox
          #heroku
          #colima
          #docker
          #docker-compose
          #docker-credential-helpers
          #android-tools
          #autossh
          #gh
        ];
      in
      commonPackages
      ++ (lib.optionals cfg.includeFonts fontPackages)
      ++ (lib.optionals (!cfg.useNeovim) vimPackage)
      ++ (lib.optionals cfg.isWork workPackages);
    };

    fonts.fontconfig.enable = cfg.includeFonts;

    programs.nix-index.enable = true;

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "21.05";
  };

}
