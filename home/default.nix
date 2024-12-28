{ config, pkgs, lib, inputs, ... }:
{

  imports = [
    ./nvim
    ./wez
    ./starship
    ./ohmyzsh
    ./zsh
    ./ssh
    ./1password
  ];



  config = {

    ###############################################################
    ## Home Manager needs a bit of information about you and the ##
    ## paths it should manage.                                   ##
    ###############################################################
    home = {
      sessionVariables = {
        VISUAL = "nvim";
        PAGER  = "less";
      };

      packages = with pkgs; let

        ############################
        ## command line utilities ##
        ############################
        commonPackages = [
          ack
          curl
          htop
          btop
          fastfetch
          tldr
          wget
          comma
        ];

        ###################################
        ## Fonts that we want everywhere ##
        ###################################
        fontPackages = [
          cozette
          scientifica
          monocraft
        ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts) ;

        ##############################################
        ## Work / Development packages that we want ##
        ##############################################
        workPackages = [
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

      ##################################################################
      ## add all of the above to our list of packages to ensure exist ##
      ##################################################################
      in
      commonPackages
      ++ (fontPackages)
      ++ (workPackages);
    };

    programs.nix-index.enable = true;
  };

}
