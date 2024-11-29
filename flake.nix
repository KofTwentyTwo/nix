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
      services.nix-daemon.enable = true;

      nix.settings.experimental-features = "nix-command flakes";
      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 4;
      nixpkgs.hostPlatform = "aarch64-darwin";
      nixpkgs.config.allowUnfree = true;

      #########################################################
      ## Declare the user that will be running `nix-darwin`. ##
      ######################################################### 
      users.users."james.maes" = {
         name = "james.maes";
         home = "/Users/james.maes";
      };

      #####################################################################
      ## Apple / MacOS Configuration                                     ##
      ## Options here - https://daiderd.com/nix-darwin/manual/index.html ##
      #####################################################################
      security.pam.enableSudoTouchIdAuth = true;
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
         "/Applications/Airmail.app"
         "/Applications/Arc.app"
         "/Applications/DEVONthink 3.app"
         "/Applications/Docker.app"
         "/Applications/Ecamm Live.app"
         "/Applications/Elgato Stream Deck.app"
         "/Applications/Ember.app"
         "/Applications/Fantastical.app"
         "/Applications/GitHub Desktop.app"
         "/Applications/IntelliJ IDEA.app"
         "/Applications/Ivory.app"
         "/Applications/Keynote.app"
         "/Applications/Numbers.app"
         "/Applications/Obsidian.app"
         "/Applications/OmniFocus.app"
         "/Applications/OmniGraffle.app"
         "/Applications/OmniPlan.app"
         "/Applications/Pages.app"
         "/Applications/Parcel.app"
         "/Applications/Slack.app"
         "/Applications/WezTerm.app"
         "/Applications/WhatsApp.app"
         "/Applications/Xcode.app"
         "/Applications/zoom.us.app"
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
            ## ember-temperature-control     = 1147470931;     ## New version will not auto install?
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
         };
         brews = [ ];
         casks = [
            "1password"
            "1password-cli"
            "adobe-creative-cloud"
            "alfred"
            "arc"
            "aws-vpn-client"
            "backblaze"
            "balenaetcher"
            "bettertouchtool"
            "cleanshot"
            "devonthink"
            "docker"
            "ecamm-live"
            "elgato-camera-hub"
            "elgato-stream-deck"
            "fantastical"
            "github"
            "intellij-idea"
            "keyboard-maestro"
            "loopback"
            "obsidian"
            "omnifocus"
            "omnigraffle"
            "omniplan"
            "openwebstart"
            "slack"
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
         extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
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
         fastfetch 
         go-task
         gping 
         iperf3
         ncdu
         nmap
      ];
   };
   in
   {
      darwinConfigurations."Darth" = nix-darwin.lib.darwinSystem {
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
