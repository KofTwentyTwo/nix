# Procs Configuration Module
# ==========================
# Configures procs, a modern ps replacement with colored output,
# tree view, and built-in search.
#
# Key defaults:
#   - Sorted by CPU descending (busiest processes on top)
#   - Shows State, RSS, TCP ports, and elapsed time
#   - Kernel threads hidden (show_kthreads = false)

{ config, pkgs, lib, ... }:

{
   config = {
      home.file."./.config/procs/config.toml" = {
         source = ./config/config.toml;
      };
   };
}
