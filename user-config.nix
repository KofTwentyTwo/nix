# User Configuration Template
# ===========================
# NOTE: Due to Nix flake pure evaluation mode, this file is not directly imported.
# Instead, the userConfig is defined inline in flake.nix (around line 40).
#
# To customize for different machines:
# 1. Edit flake.nix and update the userConfig definition
# 2. Update username, git info, and paths as needed
# 3. Rebuild: darwin-rebuild switch --flake ~/.config/nix
#
# This file serves as documentation/reference for the structure.
# The actual configuration is in flake.nix.

{
  # Username - CHANGE THIS for different machines
  username = "james.maes";
  
  # Git configuration
  git = {
    userName = "James Maes";
    userEmail = "james@kof22.com";
    signingKey = "62859E8ABE1FC2B7FCCB89080021767055740E6D";
  };
  
  # Machine-specific paths (optional - will use home directory if not set)
  # These are paths that might differ between machines
  paths = {
    # Development tools (optional - comment out if not present)
    qqqDevTools = "/Users/james.maes/Git.Local/QRun-IO/qqq/qqq-dev-tools";
    # Alternative location if different on other machines:
    # qqqDevTools = "/Users/james.maes/Git.Local/Kingsrook/qqq/qqq-dev-tools";
    
    # LLM prompt file (optional - comment out if not present)
    aicommitsPrompt = "/Users/james.maes/Documents/LLM/aic_prompt.txt";
  };
}

