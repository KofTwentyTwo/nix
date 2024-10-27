{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
  let


    configuration = {pkgs, ... }: {

        #############################
        ## defaults - do not touch ##
        #############################
        services.nix-daemon.enable = true;
        nix.settings.experimental-features = "nix-command flakes";
        system.configurationRevision = self.rev or self.dirtyRev or null;
        system.stateVersion = 4;
        nixpkgs.hostPlatform = "aarch64-darwin";

        #########################################################
        ## Declare the user that will be running `nix-darwin`. ##
        ######################################################### 
        users.users."james.maes" = {
            name = "james.maes";
            home = "/Users/james.maes";
        };

        security.pam.enableSudoTouchIdAuth = true;

        #############################################################
        ## Create /etc/zshrc that loads the nix-darwin environment ##
        #############################################################
        programs.zsh.enable = true;
        environment.systemPackages = [ ];

        homebrew = {
            enable = false;
            # onActivation.cleanup = "uninstall";

            taps = [];
            brews = [];
            casks = [];
        };
    };
 

    homeconfig = {pkgs, ...}: {
      home.stateVersion = "23.05";
      programs.home-manager.enable = true;
      programs.neovim = {
         enable = true;
         defaultEditor = true;
         viAlias = true;
         vimAlias = true;
         vimdiffAlias = true;
      };
      programs.git = {
         enable = true;
         userName = "James Maes";
         userEmail = "james@kof22.com";
         ignores = [ ".DS_Store" ];
         extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
         };
      };
      programs.zsh = {
         enable = true;
         shellAliases = {
            switch   = "clear;darwin-rebuild switch --flake ~/.config/nix";
            hist     = "history";
            ping     = "gping";
         };
      };

    imports = [
       ./home
    ];

      #########################
      ## Packages to install ##
      #########################
      home.packages = with pkgs; [ pkgs.fastfetch pkgs.gping ];

      ################################################################
      ## Home "dotfiles and configs" that are handled by homeconfig ##
      ################################################################
      home.file.".vimrc".source = ./vim_configuration;
    };
  in
  {
    darwinConfigurations."Grogu" = nix-darwin.lib.darwinSystem {
      modules = [
         configuration
            home-manager.darwinModules.home-manager  {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.verbose = true;
                home-manager.users."james.maes" = homeconfig;
            }
      ];
    };
  };
}
