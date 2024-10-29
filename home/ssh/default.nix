{ config, pkgs, lib, ... }:
{
   config = {
      programs.ssh = {
         enable = true;
         forwardAgent = true;
         extraConfig = ''
            StrictHostKeyChecking=accept-new
            IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
            User james.maes
            Port 10022
         '';


         matchBlocks = {

            emperor = {
               port     = 10022;
               hostname = "emperor.galaxy.lan";
               user     = "EmperorGalaxyAdmin";
            };
         };
      };
   };
}
