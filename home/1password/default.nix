{ config, pkgs, lib, ... }:
{
   config = {
      home.file."./.config/1passowrd/agent.toml" = {
         source = ./config/agent.toml"
      };
   };
}
