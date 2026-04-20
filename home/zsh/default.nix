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
      # Shell tips file for MOTD display (fortune-style, % delimited)
      home.file.".local/share/shell-tips".source = ./config/shell-tips;

      programs.zsh = {
         enable = true;
         enableCompletion = true;
         syntaxHighlighting.enable = true;
         enableVteIntegration = true;
         autosuggestion.enable = true;
         autosuggestion.strategy = [ "history" "completion" ];

         # Shell initialization script (runs when zsh starts)
         # Order 550 ensures it runs after other init scripts
         initContent = lib.mkOrder 550 ''
           # Terminal type: set TERM=wezterm only outside tmux.
           # Inside tmux, TERM is set by default-terminal (tmux-256color).
           if [[ -z "$TMUX" ]]; then
             export TERM=wezterm
           fi

           # Forward OSC 7 (cwd reporting) through tmux to WezTerm
           # enableVteIntegration sends OSC 7 but tmux captures it for its own
           # pane_current_path tracking. This re-sends via DCS passthrough so
           # WezTerm also receives the cwd (needed for split-pane, status bar, etc.)
           if [[ -n "$TMUX" ]]; then
             _wezterm_osc7() {
               printf '\ePtmux;\e\e]7;file://%s%s\a\e\\' "$(hostname)" "$PWD"
             }
             precmd_functions+=(_wezterm_osc7)
           fi
           
           # Load completions
           eval "$(task --completion zsh)"
           source <(velero completion zsh)
           
           # AWS CLI completion (native zsh completion)
           # Ensure Homebrew's zsh site-functions are in fpath for automatic completion loading
           if [[ -d /opt/homebrew/share/zsh/site-functions ]]; then
             fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
           fi
           
           # Source AWS CLI zsh completer
           # Note: compinit should already be run by Home Manager (enableCompletion = true)
           # The completer script sets up bashcompinit and defines the completion
           if [[ -f /opt/homebrew/share/zsh/site-functions/aws_zsh_completer.sh ]]; then
             # Ensure compinit has run (Home Manager should handle this, but check to be safe)
             if ! (( $+functions[compdef] )); then
               autoload -Uz compinit && compinit
             fi
             source /opt/homebrew/share/zsh/site-functions/aws_zsh_completer.sh
           fi
           
           # Load QQQ dev tools (if present)
           if [[ -f "${qqqDevTools}/lib/qqq-shell-functions.sh" ]]; then
             . "${qqqDevTools}/lib/qqq-shell-functions.sh"
           fi
           
           # Load Cargo environment (Rust)
           if [[ -f "$HOME/.cargo/env" ]]; then
             . $HOME/.cargo/env
           fi

           # Secrets are loaded via op-load-secrets function (see 1password module)

           # ls wrapper - translates standard ls flags to eza equivalents
           # Handles: -t (sort by time), -S (sort by size), -s (show size), -h (skip, eza default)
           # All other flags pass through directly to eza
           ls() {
             local eza_args=()
             local files=()
             local sort_field=""

             for arg in "$@"; do
               if [[ "$arg" == -* && "$arg" != --* ]]; then
                 local chars="''${arg#-}"
                 local j
                 for (( j=0; j<''${#chars}; j++ )); do
                   local c="''${chars:$j:1}"
                   case "$c" in
                     t) sort_field="modified" ;;
                     S) sort_field="size" ;;
                     s) eza_args+=("-S") ;;
                     h) ;;
                     *) eza_args+=("-$c") ;;
                   esac
                 done
               elif [[ "$arg" == --* ]]; then
                 eza_args+=("$arg")
               else
                 files+=("$arg")
               fi
             done

             [[ -n "$sort_field" ]] && eza_args+=("--sort=$sort_field")

             command eza "''${eza_args[@]}" "''${files[@]}"
           }

           # Shell help - quick reference for all tools, aliases, scripts, and apps
           shelp() {
             local filter="$1"
             local help_text='ALIASES - File Listing
  ls              eza wrapper              translates ls flags to eza automatically
  ls-la           eza -la                  long, all files
  ls-lt           eza -l --sort=modified   long, newest first
  ls-lrt          eza -lr --sort=modified  long, oldest first
  ls-lsrt         eza -lrS --sort=modified long, sizes, oldest first
  ls-lsart        eza -larS --sort=modified long, all, sizes, oldest first
  ls-lS           eza -l --sort=size       long, largest first
  ls-lSr          eza -lr --sort=size      long, smallest first
  ll              eza -l                   long listing (auto from eza)
  la              eza -la                  long listing, all (auto from eza)
  tree            eza --tree               tree view (auto from eza)
  cat             bat                      syntax-highlighted cat

ALIASES - Editors
  vi              nvim
  vim             nvim

ALIASES - Nix/Darwin
  switch          darwin-rebuild switch    rebuild and activate nix config

ALIASES - Git
  gc              git cz c               commitizen commit
  gt              gitops-publish.sh      publish feature branch tag
  gsa             git-sync-all.sh        fetch, switch, pull all repos
  gsall           git-status-all.sh      status of all repos
  gclo            git-clone-all.sh       clone all repos from org
  gfa             git-fetch-all.sh       fetch all repos
  gpa             git-pull-all.sh        pull all repos
  gba             git-branch-all.sh      branches for all repos
  gcoa            git-checkout-all.sh    checkout branch in all repos
  gla             git-log-all.sh         recent commits for all repos
  gi              git-info.sh            comprehensive repo info
  ghelp           git-help.sh            all custom git commands

ALIASES - Kubernetes
  k               kubectl
  ka              kubectl apply -f
  kns             kubectl config set-context --current --namespace
  kshell          kubectl exec --stdin --tty
  kdns            kubectl run dnsutils   spin up dnsutils debug pod
  h               helm
  v               velero

ALIASES - Task/History/Other
  t               task                   go-task runner
  tl              task --list-all        list all tasks
  hist/his/hi     history
  sshc            ssh-keygen -R          remove host from known_hosts
  secure          op-load-secrets        load 1Password secrets to env
  check-updates   check-updates.sh       check brew/nix updates
  cr              claude-resume.sh       resume Claude session

FUNCTIONS - Shell Helpers
  hint            show a random shell tip (same as login MOTD tip)
  help CMD        CMD --help | bat       colored, paged help output
  hg PATTERN      search all history     rg-powered full history grep (replaces hist|grep)
  fco             fzf git checkout       interactive branch picker
  flog            fzf git log            interactive commit browser with diff preview
  extract FILE    universal extract      handles tar.gz, zip, 7z, rar, etc. (OMZ plugin)

TOOLS - Modern Replacements (installed via brew)
  bat             replaces cat           syntax highlighting, line numbers, paging
  eza             replaces ls            colors, git status, tree view, icons
  zoxide (z)      replaces cd            learns frequent directories, fuzzy match
  delta           replaces diff          git diff viewer, syntax highlighting, side-by-side
  fd              replaces find          faster, simpler syntax, respects .gitignore
  ripgrep (rg)    replaces grep          faster, respects .gitignore, regex
  dust            replaces du            visual disk usage, sorted, colored
  duf             replaces df            disk free with colors, table layout
  procs           replaces ps            modern process viewer, tree, search
  sd              replaces sed           simpler syntax: sd FIND REPLACE file
  xh              replaces curl/httpie   friendlier HTTP client, colored output
  doggo           replaces dig           modern DNS client, colored, JSON output
  difftastic      replaces diff          structural, syntax-aware, language-aware diffs
  gdu             replaces ncdu          interactive disk usage with colors
  dua             replaces du            Rust-based disk analyzer (dua i for interactive)
  tokei           replaces cloc          fast line-of-code counter by language
  mtr             replaces traceroute    traceroute + ping combined, live updating
  hyperfine       replaces time          statistical benchmarking, multiple runs
  btop            replaces top/htop      resource monitor TUI with graphs
  tldr            replaces man           simplified, example-based man pages
  glow            replaces less (for md) terminal markdown viewer with styling

TOOLS - Shell Integration
  fzf             Ctrl+R                 fuzzy history search
  fzf             Ctrl+T                 fuzzy file picker (insert path)
  fzf             Alt+C                  fuzzy cd into directory
  zoxide          z DIR                  jump to frequent directory
  direnv          (automatic)            loads .envrc files on cd
  starship        (automatic)            customizable shell prompt

TOOLS - Git & Version Control
  gh              github cli             PRs, issues, releases, actions, API
  lazygit         git TUI                interactive staging, commits, branches
  git-absorb      auto fixup             auto-absorb staged changes into prior commits
  git-crypt       encryption             transparent file encryption in git repos
  git-lfs         large files            large file storage for git
  gitleaks        secrets scanner        detect hardcoded secrets in repos
  bfg             repo cleaner           remove large files/secrets from git history
  commitizen      commit tool            interactive conventional commit messages
  commitlint      commit linter          validate commit message format

TOOLS - Kubernetes & DevOps
  kubectl         kubernetes cli         manage k8s clusters
  k9s             kubernetes TUI         terminal UI for k8s clusters
  kubectx         context switcher       fast k8s context/namespace switching (also kubens)
  krew            kubectl plugins        kubectl plugin manager
  stern           log tailing            multi-pod log streaming with filtering
  helm            package manager        k8s package manager (charts)
  helmfile        helm declarative       declarative helm chart management
  kustomize       k8s overlays           template-free k8s configuration
  velero          k8s backup             backup and restore k8s resources
  kubeseal        k8s secrets            encrypt secrets for sealed-secrets controller
  argocd          gitops                 declarative GitOps continuous delivery
  calicoctl       network policy         calico CNI network policy management
  cmctl           cert-manager           cert-manager CLI for TLS certificates
  talosctl        talos linux            manage Talos Linux k8s nodes
  eksctl          EKS management         create and manage AWS EKS clusters
  lens            kubernetes IDE         GUI for k8s cluster management (app)

TOOLS - Cloud & AWS
  awscli          AWS CLI                manage AWS services from terminal
  aws (omz)       zsh completions        AWS CLI tab completion (oh-my-zsh plugin)
  session-manager AWS SSM                connect to EC2 instances via SSM

TOOLS - Infrastructure
  ansible         automation             infrastructure automation and config management
  ansible-lint    linting                lint ansible playbooks
  opentofu        IaC                    terraform-compatible infrastructure as code
  terragrunt      IaC wrapper            terraform/tofu wrapper for DRY configs
  docker          containers             container runtime (Docker Desktop cask)
  lazydocker      docker TUI             interactive docker container management

TOOLS - Database
  postgresql@17   postgres               PostgreSQL 17 server and client
  mysql@8.4       mysql                  MySQL 8.4 server and client
  liquibase       migrations             database schema migration tool
  sqlfluff        SQL linter             lint and auto-format SQL
  dbeaver         database GUI           universal database client (app)

TOOLS - Security & Encryption
  gnupg (gpg)     encryption             GPG encryption, signing, key management
  age             encryption             simple file encryption tool
  sops            secrets management     encrypted secrets in config files (yaml/json)
  cosign          code signing           sign and verify container images
  nmap            network scanner        network discovery and security auditing
  wireshark       packet analyzer        network protocol analyzer (app)
  1password       password manager       password vault (app + CLI)
  op              1password CLI          manage vault items from terminal

TOOLS - Development Languages
  openjdk@21      Java 21                primary JDK (JAVA_HOME set)
  graalvm-jdk@21  GraalVM 21             native image compilation
  maven           Java build             project management and build tool
  gradle          Java build             build automation tool
  node@22         Node.js 22             default node (v25, v22, v20 installed)
  go              Go                     Go programming language
  rust            Rust                   Rust programming language (cargo in PATH)
  python/pipx     Python                 Python 3 with pipx for isolated CLI tools
  lua/luarocks    Lua                    Lua language and package manager
  julia           Julia                  Julia programming language
  llvm            LLVM                   compiler infrastructure (clang, etc.)

TOOLS - Build & CI/CD
  go-task (task)  task runner             Makefile alternative (yaml-based)
  circleci        CI/CD CLI              CircleCI local testing and config validation
  act             GitHub Actions         run GitHub Actions locally
  qctl            QRun.IO CLI            QRun.IO management tool

TOOLS - Text & Documents
  jq              JSON processor         query, filter, transform JSON
  yq              YAML processor         query, filter, transform YAML
  pandoc          document converter     convert between markup formats
  weasyprint      HTML to PDF            convert HTML/CSS to PDF
  glow            markdown viewer        render markdown in terminal
  w3m             text browser           text-based web browser
  markdownlint-cli2 markdown linter      lint markdown files

TOOLS - Code Quality
  shellcheck      shell linter           lint bash/sh scripts
  semgrep         code scanner           static analysis, find bugs and vulnerabilities
  ast-grep        code search            AST-based code search and refactoring
  clang-format    C/C++ formatter        format C/C++/ObjC code
  yamllint        YAML linter            lint YAML files
  sqlfluff        SQL linter             lint and format SQL

TOOLS - Network & System
  iperf3          bandwidth test         network throughput measurement
  arping          ARP ping               ping at the ARP layer
  inetutils       network utils          telnet, ftp, ping, traceroute, etc.
  minio-mc (mc)   S3 client              MinIO/S3 compatible object storage client
  pv              pipe viewer            monitor data through a pipeline (progress bar)
  watch           repeat command         run command repeatedly, show output
  fastfetch       system info            display system info (neofetch replacement)
  imagemagick     image tools            convert, resize, edit images from CLI

TOOLS - TUI Applications
  k9s             kubernetes             terminal UI for k8s
  lazygit         git                    terminal UI for git
  lazydocker      docker                 terminal UI for docker
  btop            system monitor         terminal UI for system resources
  ncdu / gdu      disk usage             terminal UI for disk usage (gdu has colors)

TOOLS - Fun / Screensavers (tmux lock picks one randomly)
  cmatrix         matrix rain            classic green rain (any key exits)
  asciiquarium    aquarium               ASCII fish tank (any key exits)
  cbonsai         bonsai tree            grows random ASCII bonsai (q to exit)
  pipes.sh        animated pipes         colorful pipes fill the screen (q to exit)
  lavat           lava lamp              terminal lava lamp (q to exit)
  tty-clock       clock                  big terminal clock (q to exit)
  genact          fake activity          pretend to compile/deploy (ctrl+c)
  cowsay          cow                    ASCII art cow with message
  boxes           ASCII boxes            draw ASCII art boxes around text

SCRIPTS - Custom (in ~/.local/bin)
  check-updates.sh    check brew and nix for available updates
  update-nix.sh       update nix flake inputs
  gitops-publish.sh   publish feature branch tag for GitOps
  fix-git-remote.sh   fix git remote URL issues
  git-sync-all.sh     morning sync: fetch, switch, pull all repos
  git-status-all.sh   check status of all repos in current dir
  git-clone-all.sh    clone all repos from a GitHub org
  git-fetch-all.sh    fetch updates for all repos
  git-pull-all.sh     pull all repos in current dir
  git-branch-all.sh   show current branch for all repos
  git-checkout-all.sh checkout branch in all repos
  git-log-all.sh      show recent commits for all repos
  git-info.sh         show comprehensive repo info
  git-help.sh         show all custom git commands
  claude-resume.sh    resume Claude Code session for current dir
  op-load-secrets     load env vars from 1Password vault
  confluence-blog.sh  post to Confluence blog
  confluence.sh       Confluence integration

SHELL - Oh-My-Zsh Plugins
  git             git shortcuts and status in prompt
  sudo            press ESC ESC to prepend sudo to last command
  docker          docker command completions
  kubectl         kubectl command completions
  aws             aws cli completions
  helm            helm command completions
  terraform       terraform/tofu completions
  fzf             fzf shell integration
  aliases         alias management (acs to search aliases)

CONFIG - Key Paths
  ~/.config/nix           nix-darwin + home-manager config
  ~/.ai/                  AI agent config (profile, rules, style, prefs)
  ~/.config/nvim/         neovim config (LazyVim)
  ~/.config/wezterm/      wezterm terminal config
  ~/.config/starship.toml starship prompt config
  ~/.config/k9s/          k9s kubernetes TUI config
  ~/.gnupg/               GPG keys and agent config
  ~/.aws/                 AWS CLI config and credentials
  ~/.kube/configs/        kubernetes config files (auto-merged via KUBECONFIG)
  ~/.local/bin/           custom scripts

CONFIG - Key Environment Variables
  JAVA_HOME       /opt/homebrew/opt/openjdk@21/...
  KUBECONFIG      auto-merged from ~/.kube/configs/*
  EDITOR/VISUAL   vi (aliases to nvim)
  PAGER           less -FR
  SSL_CERT_FILE   ~/.config/ca-certs.pem
  GPG_TTY         current tty (for gpg passphrase prompt)

APPS - macOS (managed via brew cask)
  1password       password manager
  alfred          spotlight replacement / launcher
  alt-tab         window switcher (like Windows)
  arc             browser
  bettertouchtool trackpad/keyboard customization
  cleanshot       screenshot tool
  dbeaver         database GUI
  devonthink      document management
  docker-desktop  container runtime
  drawio          diagram editor
  fantastical     calendar
  intellij-idea   Java IDE
  istat-menus     system monitor in menu bar
  karabiner       keyboard remapping
  keyboard-maestro macro automation
  lens            kubernetes GUI
  obsidian        knowledge base / notes
  omnifocus       task management
  omnigraffle     diagramming
  omniplan        project management
  slack           team communication
  tailscale-app   mesh VPN
  visual-studio-code code editor
  wezterm         GPU-accelerated terminal
  zoom            video conferencing

TIP: shelp KEYWORD   filter output (e.g., shelp kubectl, shelp replace, shelp git)'

             if [[ -n "$filter" ]]; then
               echo "$help_text" | grep -i "$filter"
             else
               echo "$help_text"
             fi
           }

           # SSH wrapper for WezTerm host tracking
           # Updates terminal title with remote hostname for interactive SSH sessions
           ssh() {
             local update_title=false
             local host=""

             # Only update terminal title for interactive TTY sessions
             if [[ -t 1 ]] && [[ -t 0 ]]; then
               local skip_next=false
               local has_command=false
               local tunnel_only=false

               for arg in "$@"; do
                 if $skip_next; then
                   skip_next=false
                   continue
                 fi
                 case "$arg" in
                   -b|-c|-D|-E|-e|-F|-I|-i|-J|-L|-l|-m|-O|-o|-p|-Q|-R|-S|-W|-w)
                     skip_next=true ;;
                   -[bcDEeFIiJLlmOopQRSWw]*)
                     ;;
                   -f|-N|-n)
                     tunnel_only=true ;;
                   -*)
                     ;;
                   *)
                     if [[ -z "$host" ]]; then
                       host="$arg"
                     else
                       has_command=true
                     fi
                     ;;
                 esac
               done

               if [[ -n "$host" ]] && ! $tunnel_only && ! $has_command; then
                 update_title=true
               fi
             fi

             local display_host="''${host#*@}"

             if $update_title; then
               printf '\033]7;file://%s/\007' "$display_host"
             fi

             command ssh "$@"
             local ssh_exit=$?

             if $update_title; then
               printf '\033]7;file://%s%s\007' "$(hostname)" "$PWD"
             fi

             return $ssh_exit
           }

           # Help - colored --help output via bat
           help() { "$@" --help 2>&1 | bat -l help -p; }

           # History grep - search ALL shell history with rg (replaces hist|grep)
           hg() { fc -l 1 | rg --color=always "$@"; }

           # fzf git checkout - interactive branch picker
           fco() {
             local branch=$(git branch --all | fzf --no-multi | sed 's/^[* ]*//' | sed 's|remotes/origin/||')
             [[ -n "$branch" ]] && git checkout "$branch"
           }

           # fzf git log - interactive commit browser with diff preview
           flog() {
             git log --oneline --color=always | fzf --ansi --no-sort --preview 'git show --color=always {1}'
           }

           # Show a random shell tip in a bordered box
           hint() {
             local tips_file="$HOME/.local/share/shell-tips"
             [[ -f "$tips_file" ]] || { echo "No tips file found"; return 1; }

             local tip=$(awk 'BEGIN{RS="\n%\n"; srand()} NF{a[++n]=$0} END{if(n>0) print a[int(rand()*n)+1]}' "$tips_file")
             [[ -z "$tip" ]] && return

             # Measure longest line to size the box dynamically
             local max_len=0
             while IFS= read -r line; do
               (( ''${#line} > max_len )) && max_len=''${#line}
             done <<< "$tip"
             (( max_len < 40 )) && max_len=40

             local top_dashes=$(printf '─%.0s' $(seq 1 $(( max_len - 9 ))))
             local bottom_dashes=$(printf '─%.0s' $(seq 1 $(( max_len + 3 ))))

             echo ""
             echo -e "\033[0;32m╭─ \033[1;32mShell Tip\033[0;32m ''${top_dashes}╮\033[0m"
             while IFS= read -r line; do
               printf "\033[0;32m│\033[0m  %-''${max_len}s \033[0;32m│\033[0m\n" "$line"
             done <<< "$tip"
             echo -e "\033[0;32m╰''${bottom_dashes}╯\033[0m"
             echo ""
           }

           # MOTD: fastfetch + random shell tip on new sessions
           if [[ -t 1 ]]; then
             fastfetch
             hint
           fi

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
            # Note: ls is wrapped as a function (in initContent) that translates ls flags to eza
            # programs.eza.enableZshIntegration = false, so we define all eza aliases here
            ll          = "eza -l";                            # long listing
            la          = "eza -la";                           # long listing, all
            tree        = "eza --tree";                        # tree view
            "ls-la"     = "eza -la";                          # ls -la    (long, all)
            "ls-lt"     = "eza -l --sort=modified";           # ls -lt    (long, newest first)
            "ls-lrt"    = "eza -lr --sort=modified";          # ls -lrt   (long, oldest first)
            "ls-lsrt"   = "eza -lrS --sort=modified";        # ls -lsrt  (long, sizes, oldest first)
            "ls-lsart"  = "eza -larS --sort=modified";       # ls -lsart (long, all, sizes, oldest first)
            "ls-lS"     = "eza -l --sort=size";               # ls -lS    (long, largest first)
            "ls-lSr"    = "eza -lr --sort=size";              # ls -lSr   (long, smallest first)
            
            # Modern CLI replacements (originals still available via: command du, command grep, etc.)
            du          = "dust";       # Visual disk usage, sorted, colored
            df          = "duf";        # Disk free with colors, table layout
            dig         = "doggo";      # Modern DNS client, colored output
            top         = "btop";       # Resource monitor TUI with graphs
            htop        = "btop";       # Resource monitor TUI with graphs
            traceroute  = "mtr";        # Traceroute + ping combined, live updating
            diff        = "difft";      # Structural, syntax-aware diffs
            grep        = "rg";         # Faster, respects .gitignore, regex
            ps          = "procs";      # Modern process viewer, tree, search

            cloc        = "tokei";      # Fast line-of-code counter by language

            # SSH utilities
            sshc        = "ssh-keygen -R";  # Remove host from known_hosts
            
            # Git shortcuts
            gc          = "git cz c";  # Commit using commitizen
            gt          = "gitops-publish.sh";  # GitOps: publish feature branch tag
            gsa         = "git-sync-all.sh";    # Morning sync: fetch, switch branch, pull all repos
            gsall       = "git-status-all.sh";  # Check status of all repos in current dir
            gclo        = "git-clone-all.sh";  # Clone all repos from a GitHub org
            gfa         = "git-fetch-all.sh";  # Fetch updates for all repos
            gpa         = "git-pull-all.sh";   # Pull all repos
            gba         = "git-branch-all.sh"; # Show current branch for all repos
            gcoa        = "git-checkout-all.sh"; # Checkout branch in all repos
            gla         = "git-log-all.sh";    # Show recent commits for all repos
            gi          = "git-info.sh";       # Show comprehensive repo info
            ghelp       = "git-help.sh";       # Show all custom git commands
            
            # Security
            secure      = "op-load-secrets";  # Load secrets from 1Password vault

            # Updates
            check-updates = "check-updates.sh";  # Check for brew and nix updates

            # Claude Code
            cr          = "claude-resume.sh";  # Resume session for current directory

            # Help
            # shelp is a function (in initContent) - supports: shelp, shelp grep, shelp kubectl
         };

         # History configuration
         history = {
            size = 100000;  # Maximum number of entries in memory
            save = 100000;  # Maximum number of entries saved to file
            ignoreAllDups = true;         # Remove older duplicate when new one added
            expireDuplicatesFirst = true;  # Expire dupes first when trimming to size
         };

         # Environment variables
         sessionVariables = {
            # AI Commits prompt (optional - file checked at runtime)
            # Uses userConfig.paths.aicommitsPrompt or defaults to ~/Documents/LLM/aic_prompt.txt
            AICOMMITS_PROMPT = "$(cat ${aicommitsPrompt} 2>/dev/null || echo '')";
            
            # GPG configuration
            GPG_TTY = "$(tty)";  # Required for GPG to work in terminal
            
            # Java/GraalVM configuration
            # Note: Uses Homebrew's stable symlink to avoid breakage on version upgrades
            GRAALVM_HOME = "/opt/homebrew/opt/graalvm-jdk@21/Contents/Home";
            JAVA_HOME = "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home";
            
            # Kubernetes configuration
            KUBECONFIG = "$(find ~/.kube/configs -type f 2>/dev/null | tr '\n' ':' || echo '')";
            KUBE_EDITOR = "vi";
            
            # Editor settings (vi aliases to nvim via shellAliases)
            # EDITOR and VISUAL are set in home/default.nix with mkForce to override neovim module

            # Development tools (uses portable paths)
            QQQ_DEV_TOOLS_DIR = qqqDevTools;
            
            # SSL certificate bundle (managed by ca-certs module)
            SSL_CERT_FILE = "${homeDir}/.config/ca-certs.pem";
            
            # Man page viewer - syntax highlighting via bat
            MANPAGER = "sh -c 'col -bx | bat -l man -p'";

            # Secrets are loaded via op-load-secrets function (see 1password module)
            # See: op-load-secrets --help or ~/.config/nix/SECRETS.md
         };
      };
   };
}
