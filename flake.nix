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

      devbox = {
         url = "github:jetify-com/devbox/latest";
         inputs.nixpkgs.follows = "nixpkgs";
      };
   };

   outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ...}:
   let
   configuration = {pkgs, ... }: {
      #############################
      ## defaults - do not touch ##
      #############################
      nix.settings.experimental-features = "nix-command flakes";
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 4;
      system.primaryUser = "james.maes";
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowBroken = true;

          # Set the build user group ID to 350, matching your current system setting.
    ids.gids.nixbld = 350;

      #########################################################
      ## Declare the user that will be running `nix-darwin`. ##
      ######################################################### 
      users.users."james.maes" = {
         name = "james.maes";
         home = "/Users/james.maes";
      };
      users.groups.nixbld.gid = pkgs.lib.mkForce 350;

      #####################################################################
      ## Apple / MacOS Configuration                                     ##
      ## Options here - https://daiderd.com/nix-darwin/manual/index.html ##
      #####################################################################
      security.pam.services.sudo_local.touchIdAuth = true;
      system.defaults.NSGlobalDomain.InitialKeyRepeat = 15;
      system.defaults.NSGlobalDomain.KeyRepeat = 2;
      system.defaults.finder.ShowStatusBar = true;
      system.defaults.finder.ShowPathbar = true;
      system.defaults.finder.FXPreferredViewStyle = "clmv";
      system.defaults.finder.AppleShowAllFiles = true;
      system.defaults.finder._FXShowPosixPathInTitle = true;
      system.defaults.dock.tilesize = 48;
      system.defaults.dock.show-recents = false; 
      system.defaults.dock.show-process-indicators = true;
      system.defaults.dock.orientation = "left";
      system.defaults.dock.minimize-to-application = true;
      system.defaults.dock.launchanim = false;
      system.defaults.dock.expose-animation-duration = -.01;
      system.defaults.dock.mouse-over-hilite-stack = true;
      system.defaults.alf.loggingenabled = 1;
      system.defaults.alf.globalstate = 1; 
      system.defaults.menuExtraClock.ShowDate = 1;
      system.defaults.menuExtraClock.ShowSeconds = true;
      system.defaults.screencapture.location = "/Users/james.maes/Documents/Screenshots";
      system.defaults.screensaver.askForPassword = true;
      system.defaults.screensaver.askForPasswordDelay = 600;
      system.defaults.CustomUserPreferences.com.apple.Safari.AutoFillFromAddressBook = false;
      system.defaults.CustomUserPreferences.com.apple.Safari.AutoFillCreditCardData = false;
      system.defaults.CustomUserPreferences.com.apple.Safari.AutoFillMiscellaneousForms = false;
      system.defaults.CustomUserPreferences.com.apple.SoftwareUpdate.AutomaticCheckEnabled = true;
      system.defaults.CustomUserPreferences.com.apple.SoftwareUpdate.ScheduleFrequency = 1;
      system.defaults.CustomUserPreferences.com.apple.SoftwareUpdate.AutomaticDownload =  1;
      system.defaults.CustomUserPreferences.com.apple.SoftwareUpdate.CriticalUpdateInstall = 1;
      system.defaults.CustomUserPreferences.com.apple.LSSharedFileList.FavoriteItems = ["/Applications"];


      system.defaults.dock.persistent-others = [
         "/Users/james.maes/Downloads"
         "/Users/james.maes/Documents"
      ];
      system.defaults.dock.persistent-apps = [
         "/Applications/1Password.app"
         "/Applications/AWS VPN Client/AWS VPN Client.app"
         "/Applications/Adobe Lightroom Classic/Adobe Lightroom Classic.app"
         "/Applications/Arc.app"
         "/Applications/ConnectMeNow4.app"
         "/Applications/DBeaver.app"
         "/Applications/DEVONthink 3.app"
         "/Applications/Docker.app"
         "/Applications/Ecamm Live.app"
         "/Applications/Elgato Stream Deck.app"
         "/Applications/Ember.app"
         "/Applications/GitHub Desktop.app"
         "/Applications/IntelliJ IDEA.app"
         "/Applications/Ivory.app"
         "/Applications/Karabiner-Elements.app"
         "/Applications/Keynote.app"
         "/Applications/Numbers.app"
         "/Applications/Obsidian.app"
         "/Applications/OmniFocus.app"
         "/Applications/OmniGraffle.app"
         "/Applications/OmniPlan.app"
         "/Applications/Pages.app"
         "/Applications/Parcel.app"
         "/Applications/Slack.app"
         "/Applications/Tunnelblick.app"
         "/Applications/Visual Studio Code.app"
         "/Applications/Warp.app"
         "/Applications/WezTerm.app"
         "/Applications/WhatsApp.app"
         "/Applications/Xcode.app"
         "/Applications/draw.io.app"
         "/Applications/zoom.us.app"
         "/System/Applications/Calendar.app"
         "/System/Applications/Mail.app"
         "/System/Applications/Messages.app"
         "/System/Applications/Music.app"
      ];

      system.defaults.dock.wvous-tl-corner = 1;    ## Disabled 
      system.defaults.dock.wvous-tr-corner = 12;   ## Notification Center
      system.defaults.dock.wvous-bl-corner = 5;    ## Start Screensaver 
      system.defaults.dock.wvous-br-corner = 10;   ## Put Displays to Sleep 

      #############################################################
      ## Create /etc/zshrc that loads the nix-darwin environment ##
      #############################################################
      programs.zsh.enable = true;
      environment.systemPackages = [ ];

      homebrew = {
         enable = true;
         # onActivation.cleanup = "uninstall";

         taps = [];
         masApps = {
            Xcode                         = 497799835;
            airmail-lightning-fast-email  = 918858936;
            blackmagic-disk-speed-test    = 425264550;
            ivory-for-mastodon-by-tapbots = 6444602274;
            keynote                       = 409183694;
            lanscan                       = 472226235;
            numbers                       = 409203825;
            pages                         = 409201541;
            pagesi                        = 409201541;
            parcel-delivery-tracking      = 639968404;
            whatsapp-messenger            = 310633997;
            wireguard                     = 1451685025;
         };
         brews = [ 
            "ansible-creator"
            "ansible-lint"
            "argocd"
            "bash"
            "boxes"
            "calicoctl"
            "coturn"
            "glow"
            "k9s"
            "ldapvi"
            "liquibase"
            "maven"
            "minio-mc"
            "mysql"
            "npm"
            "opentofu"
            "pandoc"
            "pdns" 
            "pv"
            "velero"
         ];
         casks = [
            "1password-cli"
            "1password"
            "adobe-creative-cloud"
            "alfred"
            "alt-tab"
            "arc"
            "aws-vpn-client"
            "backblaze"
            "balenaetcher"
            "bettertouchtool"
            "cleanshot"
            "connectmenow"
            "dbeaver-community"
            "devonthink"
            "docker"
            "drawio"
            "ecamm-live"
            "elgato-camera-hub"
            "elgato-stream-deck"
            "fantastical"
            "github"
            "istat-menus"
            "jump"
            "karabiner-elements"
            "keyboard-maestro"
            "lens"
            "loopback"
            "obsidian"
            "omnifocus"
            "omnigraffle"
            "omniplan"
            "openwebstart"
            "slack"
            ## "tailscale"
            "tunnelblick"
            "visual-studio-code"
            "warp"
            "wezterm"
            "zoom"
         ];
      };
   };
 

   homeconfig = {pkgs, ...}: {
      home.stateVersion = "24.05";
      programs.home-manager.enable = true;

      programs.git = {
         enable = true;
         userName = "James Maes";
         userEmail = "james@kof22.com";
         ignores = [ ".DS_Store" ];
         signing = {
            key = "62859E8ABE1FC2B7FCCB89080021767055740E6D";
            signByDefault = true;         
         };   
         extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
            http.postBuffer = "157286400";
            core.compression = "0";
            gpg.program = "gpg";
         };
      };

      #############################################################
      ## Bring in the brokenup sub sections of our configuration ##
      #############################################################
      imports = [
         ./home
      ];

      #########################
      ## Packages to install ##
      #########################
      home.packages = with pkgs; [ 
         ansible
         arping
         cmctl
         dialog
         fastfetch 
         gnupg
         go
         go-task
         gping 
         helmfile
         inetutils
         iperf3
         kubernetes-helm
         ncdu
         nmap
         postgresql_16_jit.out
         ripgrep
         sshpass
         stuntman
         texliveFull
         watch
         yamllint
      ];

      ################
      ## Path Setup ##
      ################
      home.sessionPath = [
         "/Users/james.maes/.local/bin"
         "/opt/ansible-virtual/bin/"
         "/Users/james.maes/Library/Python/3.9/bin/"
      ];
   };
   in
   {
      darwinConfigurations."Darth" = nix-darwin.lib.darwinSystem {
         modules = [
            configuration
               home-manager.darwinModules.home-manager  {
                  home-manager.useGlobalPkgs = true;
                  nix.enable = false;
                  home-manager.useUserPackages = true;
                  home-manager.verbose = true;
                  home-manager.users."james.maes" = homeconfig;
               }
         ];
      };
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
