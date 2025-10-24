{ config, pkgs, lib, ... }:
{
   config = {
      programs.zsh = {
         enable = true;
         enableCompletion = true;
         syntaxHighlighting.enable = true;
         enableVteIntegration = true;
         autosuggestion.strategy = "completion";

         initContent = lib.mkOrder 550 "export TERM=wezterm; eval \"$(task --completion zsh)\"; source <(velero completion zsh); . /Users/james.maes/Git.Local/QRun-IO/qqq/qqq-dev-tools/lib/qqq-shell-functions.sh; . $HOME/.cargo/env";


         shellAliases = {
            switch      = "clear;sudo darwin-rebuild switch --flake ~/.config/nix";
            hist        = "history";
            his         = "history";
            hi          = "history";
            ping        = "ping";
            tl          = "task --list-all";
            t           = "task";
            h           = "helm";
            v           = "velero";
            vi          = "nvim";
            vim         = "nvim";

            kdns        = "kubectl run -i --tty dnsutils --image=infoblox/dnstools --restart=Never --rm";
            k           = "kubectl";
            ka          = "kubectl apply -f ";
            kns         = "kubectl config set-context --current --namespace ";
            kshell      = "kubectl exec --stdin --tty ";

            sshc        = "ssh-keygen -R";

            ## overwrite some of the standard git aliases 
            gc          = "git cz c";
         };

         history = {
            size = 100000;
            save = 100000;
         };

         sessionVariables = {
            AICOMMITS_PROMPT="$(cat /Users/james.maes/Documents/LLM/aic_prompt.txt)";
            GPG_TTY="$(tty)";
            GRAALVM_HOME="/Library/Java/JavaVirtualMachines/graalvm-25.jdk/Contents/HOME";
            JAVA_HOME="/Library/Java/JavaVirtualMachines/graalvm-25.jdk/Contents/HOME/";
            KUBECONFIG="$(find ~/.kube/configs -type f | tr '\n' ':')";
            NPM_TOKEN="7wgYGrYB24i!H94K8fZ2";
            PAGER="cat";
            QQQ_DEV_TOOLS_DIR="/Users/james.maes/Git.Local/QRun-IO/qqq/qqq-dev-tools";
            SSL_CERT_FILE="/Users/james.maes/.config/ca-certs.pem";
         };
      };
   };
}
