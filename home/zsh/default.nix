# Zsh Configuration Module
# ========================
# Configures zsh shell with:
#   - Oh My Zsh integration (see ohmyzsh/default.nix)
#   - Syntax highlighting and autosuggestions
#   - Custom aliases and shell functions
#   - Environment variables
#   - Shell history settings
#
# Portability:
#   - Uses ${config.home.homeDirectory} for user-specific paths
#   - Optional paths are checked before sourcing

{ config, pkgs, lib, userConfig, ... }:
let
  homeDir = config.home.homeDirectory;
  # Optional paths from userConfig (defined inline in flake.nix, passed via extraSpecialArgs)
  qqqDevTools = if userConfig ? paths && userConfig.paths ? qqqDevTools
    then userConfig.paths.qqqDevTools
    else "${homeDir}/Git.Local/QRun-IO/qqq/qqq-dev-tools";
  aicommitsPrompt = if userConfig ? paths && userConfig.paths ? aicommitsPrompt
    then userConfig.paths.aicommitsPrompt
    else "${homeDir}/Documents/LLM/aic_prompt.txt";
in
{
   config = {
      programs.zsh = {
         enable = true;
         enableCompletion = true;
         syntaxHighlighting.enable = true;
         enableVteIntegration = true;
         autosuggestion.strategy = "completion";

         # Shell initialization script (runs when zsh starts)
         # Order 550 ensures it runs after other init scripts
         initContent = lib.mkOrder 550 ''
           # Terminal type
           export TERM=wezterm
           
           # Load completions
           eval "$(task --completion zsh)"
           source <(velero completion zsh)
           
           # Load QQQ dev tools (if present)
           if [[ -f "${qqqDevTools}/lib/qqq-shell-functions.sh" ]]; then
             . "${qqqDevTools}/lib/qqq-shell-functions.sh"
           fi
           
           # Load Cargo environment (Rust)
           if [[ -f "$HOME/.cargo/env" ]]; then
             . $HOME/.cargo/env
           fi
           
           # Secrets are loaded via op-load-secrets function (see 1password module)
           
           # Check for available updates (similar to oh-my-zsh update notification)
           if [[ -f "$HOME/.config/nix/.updates-available" ]]; then
             echo ""
             echo -e "\033[0;33m╭─────────────────────────────────────────────────────────╮\033[0m"
             echo -e "\033[0;33m│\033[0m \033[1;33m⚠️  Updates Available\033[0m                                    \033[0;33m│\033[0m"
             echo -e "\033[0;33m├─────────────────────────────────────────────────────────┤\033[0m"
             # Display update messages (skip comment lines)
             grep -v "^#" "$HOME/.config/nix/.updates-available" | while IFS= read -r line; do
               if [[ -n "$line" ]]; then
                 echo -e "\033[0;33m│\033[0m $line"
               fi
             done
             echo -e "\033[0;33m│\033[0m                                                         \033[0;33m│\033[0m"
             echo -e "\033[0;33m│\033[0m To update:                                            \033[0;33m│\033[0m"
             echo -e "\033[0;33m│\033[0m   • Brew:    \033[0;36mbrew upgrade\033[0m                              \033[0;33m│\033[0m"
             echo -e "\033[0;33m│\033[0m   • Nix:     \033[0;36mnix flake update ~/.config/nix && switch\033[0m     \033[0;33m│\033[0m"
             echo -e "\033[0;33m│\033[0m   • Check:   \033[0;36mcheck-updates.sh\033[0m                           \033[0;33m│\033[0m"
             echo -e "\033[0;33m╰─────────────────────────────────────────────────────────╯\033[0m"
             echo ""
           fi
         '';


         # Shell aliases - shortcuts for common commands
         shellAliases = {
            # Nix/Darwin management
            switch      = "clear;sudo darwin-rebuild switch --flake ~/.config/nix";
            
            # History shortcuts
            hist        = "history";
            his         = "history";
            hi          = "history";
            
            # Task management
            tl          = "task --list-all";
            t           = "task";
            
            # Kubernetes shortcuts
            kdns        = "kubectl run -i --tty dnsutils --image=infoblox/dnstools --restart=Never --rm";
            k           = "kubectl";
            ka          = "kubectl apply -f ";
            kns         = "kubectl config set-context --current --namespace ";
            kshell      = "kubectl exec --stdin --tty ";
            
            # Helm and Velero
            h           = "helm";
            v           = "velero";
            
            # Editors
            vi          = "nvim";
            vim         = "nvim";
            
            # File utilities (using modern replacements)
            cat         = "bat";  # Better cat with syntax highlighting
            # Note: eza aliases (ls, ll, la, tree) are auto-added by programs.eza.enableAliases
            
            # SSH utilities
            sshc        = "ssh-keygen -R";  # Remove host from known_hosts
            
            # Git shortcuts
            gc          = "git cz c";  # Commit using commitizen
            gt          = "gitops-publish.sh";  # GitOps: publish feature branch tag
            
            # Security
            secure      = "op-load-secrets";  # Load secrets from 1Password vault
            
            # Updates
            check-updates = "check-updates.sh";  # Check for brew and nix updates
         };

         # History configuration
         history = {
            size = 100000;  # Maximum number of entries in memory
            save = 100000;  # Maximum number of entries saved to file
         };

         # Environment variables
         sessionVariables = {
            # AI Commits prompt (optional - file checked at runtime)
            # Uses userConfig.paths.aicommitsPrompt or defaults to ~/Documents/LLM/aic_prompt.txt
            AICOMMITS_PROMPT = "$(cat ${aicommitsPrompt} 2>/dev/null || echo '')";
            
            # GPG configuration
            GPG_TTY = "$(tty)";  # Required for GPG to work in terminal
            
            # Testcontainers with Colima configuration
            # Colima exposes the Docker socket at ~/.colima/default/docker.sock on macOS,
            # but inside containers it's at /var/run/docker.sock. We need to tell Testcontainers:
            # 1. DOCKER_HOST: where to connect to Docker (the Colima socket on macOS)
            # 2. TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE: what path to mount into containers (inside VM)
            DOCKER_HOST = "unix://${homeDir}/.colima/default/docker.sock";
            TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
            
            # Java/GraalVM configuration
            # Note: These paths are system-wide and should work on all Macs
            GRAALVM_HOME = "/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home/";
            JAVA_HOME = "/opt/homebrew/Cellar/openjdk@21/21.0.9/libexec/openjdk.jdk/Contents/Home/";
            
            # Kubernetes configuration
            KUBECONFIG = "$(find ~/.kube/configs -type f 2>/dev/null | tr '\n' ':' || echo '')";
            KUBE_EDITOR = "vi";
            
            # Editor settings (vi aliases to nvim via shellAliases)
            # EDITOR and VISUAL are set in home/default.nix with mkForce to override neovim module
            PAGER = "less -FR";  # Pager with colors and no pause on exit
            
            # Development tools (uses portable paths)
            QQQ_DEV_TOOLS_DIR = qqqDevTools;
            
            # SSL certificate bundle (managed by ca-certs module)
            SSL_CERT_FILE = "${homeDir}/.config/ca-certs.pem";
            
            # Secrets are loaded via op-load-secrets function (see 1password module)
            # See: op-load-secrets --help or ~/.config/nix/SECRETS.md
         };
      };
   };
}
