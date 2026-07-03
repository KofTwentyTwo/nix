# Java Toolchain (Linux/WSL)
# ==========================
# macOS gets its JDK from Homebrew (openjdk@21 in modules/homebrew.nix), so
# this module is Linux-only. It exists for two reasons:
#
#  1. WSL had maven/gradle (home/linux-cli) but no JDK at all — mvn could not
#     run. This provides JDK 21, matching the qrunio projects
#     (maven.compiler.release=21) and the mac's openjdk@21.
#
#  2. IntelliJ runs on WINDOWS and reaches this JDK over
#     \\wsl.localhost\Ubuntu\home\james\.jdk. That path must be BOTH stable
#     across nix updates AND traversable from Windows. A symlink into
#     /nix/store satisfies neither for Windows: the WSL 9p server exposes
#     Linux symlinks but Windows cannot traverse INTO them (verified:
#     Test-Path \\wsl…\.jdk is True, \\wsl…\.jdk\bin is False). So instead
#     of symlinking, the activation below MATERIALIZES ~/.jdk as a real
#     directory copied from the store (~330 MB, re-copied only when the JDK
#     derivation changes; atomic swap via .new/.old). This matches the
#     real-directory layout of normal WSL JDK installs that JetBrains' WSL
#     support expects. See docs/INTELLIJ-WSL.md.
#
# JAVA_HOME points at ~/.jdk (here for the generic env, mirrored in
# home/zsh sessionVariables) so WSL-side maven/gradle and the Windows-side
# IDE always agree on one JDK.

{ config, pkgs, lib, ... }:

let
  jdk = pkgs.jdk21;
in
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = [ jdk ];

    home.sessionVariables.JAVA_HOME = "${config.home.homeDirectory}/.jdk";

    # NB: never use bare `exit 0` to skip (see home/claude bootstrapQqqClaudeMd).
    home.activation.materializeJdk = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      jdkSrc="${jdk.home}"
      dest="${config.home.homeDirectory}/.jdk"
      marker="$dest/.nix-jdk-source"
      # Migrate away from the earlier symlink layout, if present
      if [ -L "$dest" ]; then rm "$dest"; fi
      if [ ! -f "$marker" ] || [ "$(cat "$marker")" != "$jdkSrc" ]; then
        echo "[java] materializing JDK $jdkSrc -> $dest"
        rm -rf "$dest.new"
        mkdir -p "$dest.new"
        # -L dereferences store symlinks into real files — required for
        # Windows-side traversal over 9p; store modes are read-only, so
        # restore user write for future swaps/deletes.
        cp -rL "$jdkSrc/." "$dest.new/"
        chmod -R u+w "$dest.new"
        printf '%s\n' "$jdkSrc" > "$dest.new/.nix-jdk-source"
        if [ -e "$dest" ]; then
          rm -rf "$dest.old"
          mv "$dest" "$dest.old"
        fi
        mv "$dest.new" "$dest"
        rm -rf "$dest.old"
      fi
    '';
  };
}
