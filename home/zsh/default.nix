{ config, pkgs, lib, ... }:
{
   config = {
      programs.zsh = {
         enable = true;
         enableCompletion = true;
         syntaxHighlighting.enable = true;
         enableVteIntegration = true;
         autosuggestion.strategy = "completion";

         initContent = lib.mkOrder 550 "export TERM=wezterm; eval \"$(task --completion zsh)\"; source <(velero completion zsh); . /Users/james.maes/Git.Local/Kingsrook/qqq/qqq-dev-tools/lib/qqq-shell-functions.sh ";         

         shellAliases = {
            switch      = "clear;sudo darwin-rebuild switch --flake ~/.config/nix";
            hist        = "history";
            hi          = "history";
            ping        = "gping";
            tl          = "task --list-all";
            t           = "task";
            h           = "helm";
            v           = "velero";

            kdns        = "kubectl run -i --tty dnsutils --image=infoblox/dnstools --restart=Never --rm";
            k           = "kubectl";
            ka          = "kubectl apply -f ";
            kns         = "kubectl config set-context --current --namespace ";
            kshell      = "kubectl exec --stdin --tty ";

            sshc        = "ssh-keygen -R";
         };

         history = {
            size = 10000;
            save = 100000;
         };

         sessionVariables = {
            SSL_CERT_FILE="/Users/james.maes/.config/ca-certs.pem";
            KUBECONFIG="/Users/james.maes/Documents/Lens/k8s-prod.config:/Users/james.maes/Documents/Lens/k8s-secure.config";
            QQQ_DEV_TOOLS_DIR="/Users/james.maes/Git.Local/Kingsrook/qqq/qqq-dev-tools";
            NPM_TOKEN="7wgYGrYB24i!H94K8fZ2";
         };
      };
   };
}
