# Home Manager Default Configuration
# ==================================
# This is the main Home Manager module that imports all sub-modules
# and defines shared configuration like packages and paths.
#
# Structure:
#   - Imports all sub-modules (1password, ssh, zsh, etc.)
#   - Defines common packages (utilities, fonts)
#   - Configures session paths (uses home directory for portability)
#
# Portability:
#   - Uses ${config.home.homeDirectory} for user-specific paths
#   - Machine-specific paths come from userConfig (defined inline in flake.nix)

{ config, pkgs, lib, inputs ? {}, userConfig, ... }:
let
  homeDir = config.home.homeDirectory;
  
  # Optional paths from userConfig (with fallbacks)
  # userConfig is defined inline in flake.nix and passed via extraSpecialArgs
  qqqDevTools = if userConfig ? paths && userConfig.paths ? qqqDevTools
    then userConfig.paths.qqqDevTools
    else "${homeDir}/Git.Local/QRun-IO/qqq/qqq-dev-tools";
in
{
  # Import all Home Manager sub-modules
  imports = [
    ./1password
    ./ai
    ./aws
    ./ca-certs
    ./claude
    ./gpg
    ./k9s
    ./nvim
    ./ohmyzsh
    ./python
    ./scripts
    ./ssh
    ./starship
    ./tmux
    ./updates
    ./wez
    ./zsh
  ];

  config = {
    #######################################################################
    ## Session Variables & Paths                                         ##
    ## Environment variables and PATH configuration                     ##
    #######################################################################
    home = {
      # Default editor and pager settings
      # Using mkForce to override neovim module's defaultEditor setting
      sessionVariables = {
        EDITOR = lib.mkForce "vi";    # Default editor (vi aliases to nvim)
        VISUAL = lib.mkForce "vi";    # Visual editor (same as EDITOR)
        PAGER  = "less -FR";  # Pager with colors and no pause on exit
        QQQ_SELENIUM_HEADLESS = "true";  # Run Selenium tests headless
      };

      # PATH configuration - paths are added to $PATH
      # Uses home directory for portability across machines
      sessionPath = [
         "./bin/"                                    # Local bin in current directory
         "/opt/homebrew/opt/postgresql@17/bin"        # PostgreSQL 17 tools (keg-only)
         "/opt/homebrew/opt/node@22/bin"             # Node.js 22 as default
         "/opt/homebrew/bin/"                        # Homebrew (Apple Silicon)
         "${homeDir}/.local/bin"                     # User local binaries
         "/opt/homebrew/opt/llvm/bin"                # LLVM from Homebrew
         "/opt/ansible-virtual/bin/"                 # Ansible virtualenv (if exists)
         "${homeDir}/Library/Python/3.9/bin/"       # Python 3.9 user packages
         "$JAVA_HOME/bin"                            # Java (if JAVA_HOME is set)
         "${homeDir}/.cargo/bin"                     # Rust/Cargo binaries
         "${qqqDevTools}/bin/"                       # QQQ dev tools (from userConfig in flake.nix)
      ];


      #######################################################################
      ## Packages                                                          ##
      ## Nix packages installed via Home Manager                          ##
      ## Organized by category for easier management                      ##
      #######################################################################
      packages = with pkgs; let
        # Command-line utilities and tools
        commonPackages = [
          delta        # Better git diff viewer (configured via git.delta.enable)
          comma        # Run programs without installing (Nix-specific)
        ];

        # Font packages - installed system-wide
        fontPackages = [
          cozette      # Pixel font
          scientifica  # Scientific font
          monocraft    # Monospace font
        ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);

        # Work/Development specific packages
        # Add machine-specific packages here if needed
        workPackages = [
        ];

      in
      commonPackages
      ++ fontPackages
      ++ workPackages;
    };

    #######################################################################
    ## Program Configuration                                             ##
    ## Enable various Home Manager programs                              ##
    #######################################################################
    
    # Enable nix-index for command lookup (faster than nix-locate)
    programs.nix-index.enable = true;

    # Better cat with syntax highlighting
    programs.bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";  # Use less as pager (matches PAGER env var)
      };
    };

    # Modern ls replacement with colors and git status
    # Zsh integration disabled - we define our own ls wrapper function
    # and aliases in home/zsh/default.nix for proper flag translation
    programs.eza = {
      enable = true;
      enableZshIntegration = false;
    };

    # Smart cd that learns your habits
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    # Fuzzy finder with shell integration
    # Ctrl+R: fuzzy history search
    # Ctrl+T: fuzzy file picker
    # Alt+C: fuzzy cd into directory
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [ "--height 40%" "--border" "--reverse" ];
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
      fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    };

    # Auto-load .envrc files per directory
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;  # Faster nix integration
    };
  };

}
