# Nix-Darwin & Home Manager Configuration Flake
# =============================================
# This flake manages macOS system configuration and user environment.
#
# Structure:
#   - flake.nix: Main flake definition and macOS system configuration
#   - modules/homebrew.nix: Homebrew taps, formulae, casks, masApps
#   - userConfig (inline): User-specific settings (username, git, paths)
#   - home/: Home Manager modules for user environment
#
# Portability:
#   - Update userConfig in flake.nix with your username and paths for different machines
#   - Most paths use variables from user-config.nix or home directory
#   - Machine-specific settings are clearly marked
#
# Usage:
#   darwin-rebuild switch --flake ~/.config/nix

{
   description = "Nix-Darwin & Home Manager configuration for macOS";

   inputs = {
      # Using nixpkgs-unstable for latest packages
      # For better reproducibility, pin to a specific commit:
      # nixpkgs.url = "github:NixOS/nixpkgs/abc123def456...";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

      nix-darwin = {
         url = "github:LnL7/nix-darwin";
         inputs.nixpkgs.follows = "nixpkgs";
      };

      home-manager = {
         url = "github:nix-community/home-manager";
         inputs.nixpkgs.follows = "nixpkgs";
      };

      # Claude Code skill repositories (non-flake, fetched as source trees)
      # Update with: nix flake update
      claude-skills-phuryn = {
         url = "github:phuryn/pm-skills";
         flake = false;
      };
      claude-skills-alireza = {
         url = "github:alirezarezvani/claude-skills";
         flake = false;
      };
      claude-skills-spillwave-jira = {
         url = "github:SpillwaveSolutions/jira";
         flake = false;
      };
      claude-skills-product-on-purpose = {
         url = "github:product-on-purpose/pm-skills";
         flake = false;
      };
      claude-skills-deanpeters = {
         url = "github:deanpeters/Product-Manager-Skills";
         flake = false;
      };
      claude-skills-ccpm = {
         url = "github:automazeio/ccpm";
         flake = false;
      };
   };

   outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, ...}:
   let
      # Import user-specific configuration
      # This file should be updated when deploying to different machines
      # Note: Must use builtins.readFile + fromJSON or import with --impure
      # For now, we'll define it inline to avoid pure evaluation issues
      userConfig = {
        username = "james.maes";
        git = {
          userName = "James Maes";
          userEmail = "james@kof22.com";
          signingKey = "62859E8ABE1FC2B7FCCB89080021767055740E6D";
        };
        paths = {
          qqqDevTools = "/Users/james.maes/Git.Local/QRun-IO/qqq/qqq-dev-tools";
          aicommitsPrompt = "/Users/james.maes/Documents/LLM/aic_prompt.txt";
        };
      };
      username = userConfig.username;
      userHome = "/Users/${username}";
      
   configuration = {pkgs, ... }: {
      #######################################################################
      ## Nix Configuration & System Settings                              ##
      ## These settings configure Nix itself and system-level preferences  ##
      #######################################################################
      
      # Enable Nix flakes and commands
      nix.settings.experimental-features = "nix-command flakes";
      
      # Track configuration revision for system updates
      system.configurationRevision = self.rev or self.dirtyRev or null;
      
      # System state version - increment when upgrading nix-darwin
      system.stateVersion = 4;
      
      # Primary user for nix-darwin (from user-config.nix)
      system.primaryUser = username;
      
      # Platform and package settings
      nixpkgs.hostPlatform = "aarch64-darwin";  # Apple Silicon (change to "x86_64-darwin" for Intel)
      nixpkgs.config.allowUnfree = true;        # Allow non-free packages
      nixpkgs.config.allowBroken = true;        # Allow broken packages (useful for development)

      # Set the build user group ID to 350, matching your current system setting.
      # This may need adjustment on different machines - check with: dscl . -read /Groups/nixbld PrimaryGroupID
      ids.gids.nixbld = 350;

      #######################################################################
      ## User Configuration                                                ##
      ## Declare the user that will be running nix-darwin                 ##
      #######################################################################
      users.users."${username}" = {
         name = username;
         home = userHome;
      };
      users.groups.nixbld.gid = pkgs.lib.mkForce 350;

      #####################################################################
      ## Apple / MacOS Configuration                                     ##
      ## Options here - https://daiderd.com/nix-darwin/manual/index.html ##
      #####################################################################
      security.pam.services.sudo_local.touchIdAuth = true;
      security.pam.services.sudo_local.reattach = true;  # Enable Touch ID in tmux
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
      system.defaults.dock.expose-animation-duration = 0.001;
      system.defaults.dock.mouse-over-hilite-stack = true;
      system.defaults.menuExtraClock.ShowDate = 1;
      system.defaults.menuExtraClock.ShowSeconds = true;
      # Screenshot location (uses user home directory)
      system.defaults.screencapture.location = "${userHome}/Documents/Screenshots";
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
      networking.applicationFirewall = {
        enable = true;
        blockAllIncoming = false;
      };

      # Enable SSH (Remote Login)
      services.openssh.enable = true;

      # Dock persistent folders (uses user home directory)
      system.defaults.dock.persistent-others = [
         "${userHome}/Downloads"
         "${userHome}/Documents"
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

      # Homebrew packages managed in modules/homebrew.nix
      imports = [ ./modules/homebrew.nix ];

      #############################################################
      ## Launchd Agents                                            ##
      ## User-level background services                            ##
      #############################################################
      # Update checker - runs daily at 9 AM to check for brew and nix updates
      # Using system.activationScripts to install and load the plist
      system.activationScripts.setupUpdateChecker.text = ''
        USER_NAME="${username}"
        USER_HOME="${userHome}"
        USER_UID=$(id -u "$USER_NAME")
        USER_GROUP=$(id -gn "$USER_NAME")

        # Ensure log directory exists with correct ownership
        install -d -m 755 -o "$USER_NAME" -g "$USER_GROUP" "$USER_HOME/.local/log"

        PLIST_PATH="$USER_HOME/Library/LaunchAgents/com.jamesmaes.check-updates.plist"
        if [ -f "$PLIST_PATH" ]; then
          chown "$USER_NAME":"$USER_GROUP" "$PLIST_PATH"
          chmod 644 "$PLIST_PATH"
          # Unload if already loaded (try both old and new methods)
          launchctl bootout "gui/$USER_UID/com.jamesmaes.check-updates" 2>/dev/null || \
          launchctl unload "$PLIST_PATH" 2>/dev/null || true
          # Load using modern bootstrap method (macOS 10.11+)
          launchctl bootstrap "gui/$USER_UID" "$PLIST_PATH" 2>/dev/null || \
          launchctl load "$PLIST_PATH" 2>/dev/null || true
        fi
      '';

      # Enable Screen Sharing (VNC/ARD)
      system.activationScripts.enableScreenSharing.text = ''
        # Load screen sharing daemon if not already running
        if ! launchctl list com.apple.screensharing &>/dev/null; then
          launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist 2>/dev/null || true
        fi
      '';
   };


   homeconfig = {pkgs, config, ...}: {
      #######################################################################
      ## Home Manager Configuration                                        ##
      ## User environment, packages, and application settings             ##
      #######################################################################
      
      # Home Manager state version - increment when upgrading Home Manager
      home.stateVersion = "24.05";
      
      # Enable Home Manager
      programs.home-manager.enable = true;

      # Disable HM manual generation to suppress builtins.toFile options.json warning
      # See: https://github.com/nix-community/home-manager/issues/7935
      manual.manpages.enable = false;
      manual.html.enable = false;
      manual.json.enable = false;

      #######################################################################
      ## Git Configuration                                                 ##
      ## Git settings from userConfig (defined inline above)              ##
      #######################################################################
      programs.git = {
         enable = true;
         ignores = [ ".DS_Store" ];
         signing = {
            key = userConfig.git.signingKey;
            signByDefault = true;
            format = "openpgp";
         };
         settings = {
            user.name = userConfig.git.userName;
            user.email = userConfig.git.userEmail;
            core.editor = "vi";
            alias.cz = "!cz";
            fetch.prune = true;
            gpg.program = "gpg";
            http.postBuffer = "157286400";
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
         };
      };

      # Delta diff viewer (promoted to top-level in HM 25.05+)
      programs.delta = {
         enable = true;
         enableGitIntegration = true;
         options = {
           syntax-theme = "TwoDark";
           line-numbers = true;
           side-by-side = true;
         };
      };

      #############################################################
      ## Bring in the brokenup sub sections of our configuration ##
      #############################################################
      imports = [
         ./home
      ];

      # Note: Packages managed in home/default.nix and modules/homebrew.nix
      # Note: sessionPath is now managed in home/default.nix for better modularity
   };
   in
   {
      # Dev shell with auto git-crypt unlock
      devShells.aarch64-darwin.default = let
        pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      in pkgs.mkShell {
        buildInputs = [ pkgs.git-crypt pkgs.gnupg ];
        shellHook = ''
          if [ -d .git ] && [ ! -d .git/git-crypt ]; then
            echo "git-crypt not unlocked. Unlocking..."
            git-crypt unlock && echo "git-crypt unlocked successfully."
          fi
        '';
      };

      darwinConfigurations."Darth" = nix-darwin.lib.darwinSystem {
         modules = [
            configuration
               home-manager.darwinModules.home-manager  {
                  home-manager.useGlobalPkgs = true;
                  nix.enable = false;
                  home-manager.useUserPackages = true;
                  home-manager.verbose = true;
                  # Backup existing files when Home Manager would overwrite them
                  # This prevents errors when migrating to Home Manager
                  home-manager.backupFileExtension = "backup";
                  home-manager.extraSpecialArgs = { inherit inputs userConfig; };
                  home-manager.users."${username}" = homeconfig;
               }
         ];
      };
      darwinConfigurations."Grogu" = nix-darwin.lib.darwinSystem {
         modules = [
            configuration
               home-manager.darwinModules.home-manager  {
                  home-manager.useGlobalPkgs = true;
                  nix.enable = false;
                  home-manager.useUserPackages = true;
                  home-manager.verbose = true;
                  # Backup existing files when Home Manager would overwrite them
                  # This prevents errors when migrating to Home Manager
                  home-manager.backupFileExtension = "backup";
                  home-manager.extraSpecialArgs = { inherit inputs userConfig; };
                  home-manager.users."${username}" = homeconfig;
               }
         ];
      };
      darwinConfigurations."Renova" = nix-darwin.lib.darwinSystem {
         modules = [
            configuration
               home-manager.darwinModules.home-manager  {
                  home-manager.useGlobalPkgs = true;
                  nix.enable = false;
                  home-manager.useUserPackages = true;
                  home-manager.verbose = true;
                  # Backup existing files when Home Manager would overwrite them
                  # This prevents errors when migrating to Home Manager
                  home-manager.backupFileExtension = "backup";
                  home-manager.extraSpecialArgs = { inherit inputs userConfig; };
                  home-manager.users."${username}" = homeconfig;
               }
         ];
      };
   };
}
