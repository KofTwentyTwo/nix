# nix
Personal Nix Setup


## read this 
## https://nixcademy.com/posts/nix-on-macos/ 
## Maybe this is the way 
## https://davi.sh/blog/2024/01/nix-darwin/ 


## install Nix 
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

## Clone Nix 
mkdir -p ~/.config
cd ~/.config

git clone git@github.com:KofTwentyTwo/nix.git

cd ~/.config/nix 

nix run nix-darwin --extra-experimental-features nix-command --extra-experimental-features flakes -- switch --flake ~/.config/nix
