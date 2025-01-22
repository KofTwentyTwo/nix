{ config, pkgs, lib, ... }:
{
   config = {
   
      home.file."./.config/ca-certs.pem" = {
         source = ./config/ca-certs.pem;
      };

   };
}
