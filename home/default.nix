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
#   - Machine-specific paths can be overridden in user-config.nix

{ config, pkgs, lib, inputs, userConfig, ... }:
let
  homeDir = config.home.homeDirectory;
  
  # Optional paths from user-config (with fallbacks)
  # userConfig is passed via extraSpecialArgs from flake.nix
  qqqDevTools = if userConfig ? paths && userConfig.paths ? qqqDevTools
    then userConfig.paths.qqqDevTools
    else "${homeDir}/Git.Local/QRun-IO/qqq/qqq-dev-tools";
in
{
  # Import all Home Manager sub-modules
  imports = [
    ./1password
    ./ca-certs
    ./k9s
    ./nvim
    ./ohmyzsh
    ./ssh
    ./starship
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
      sessionVariables = {
        VISUAL = "nvim";  # Default editor
        PAGER  = "less";  # Default pager
      };

      # PATH configuration - paths are added to $PATH
      # Uses home directory for portability across machines
      sessionPath = [
         "./bin/"                                    # Local bin in current directory
         "/opt/homebrew/bin/"                        # Homebrew (Apple Silicon)
         "${homeDir}/.local/bin"                     # User local binaries
         "/opt/homebrew/opt/llvm/bin"                # LLVM from Homebrew
         "/opt/ansible-virtual/bin/"                 # Ansible virtualenv (if exists)
         "${homeDir}/Library/Python/3.9/bin/"       # Python 3.9 user packages
         "$JAVA_HOME/bin"                            # Java (if JAVA_HOME is set)
         "${homeDir}/.cargo/bin"                     # Rust/Cargo binaries
         "${qqqDevTools}/bin/"                       # QQQ dev tools (from user-config.nix)
      ];


      #######################################################################
      ## Packages                                                          ##
      ## Nix packages installed via Home Manager                          ##
      ## Organized by category for easier management                      ##
      #######################################################################
      packages = with pkgs; let
        # Command-line utilities and tools
        commonPackages = [
          ack          # Better grep alternative
          curl         # HTTP client
          htop         # Interactive process viewer
          btop         # Modern system monitor
          fastfetch    # System information tool
          tldr         # Simplified man pages
          wget         # File downloader
          comma        # Run programs without installing
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
  };

}
