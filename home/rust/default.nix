# Rust Toolchain (rustup-managed)
# ===============================
# The `rustup` manager itself is installed via Homebrew (modules/homebrew.nix);
# it conflicts_with the `rust` formula, so that formula was removed. Homebrew
# only gives us the `rustup` proxy — the actual toolchain, components, and
# cross-targets are installed here so a fresh machine ends up release-ready.
#
# Why rustup over the `rust` formula: `dist` (cargo-dist) expects rustup when it
# checks/installs cross-compile targets, and rustup gives multi-toolchain +
# component management (rustfmt, clippy) that a single pinned brew formula can't.
#
# Note: the linux-gnu *targets* below only install the std library. Actually
# *linking* a linux binary from macOS still needs a cross linker (zig /
# cargo-zigbuild / cross) — `dist` does that in CI. Targets are added per the
# release spec so local `cargo check --target ...` works.

{ config, pkgs, lib, ... }:

let
  # rustup's Homebrew proxies (cargo, rustc, rustfmt, ...) live here; cargo-installed
  # binaries land in ~/.cargo/bin. Put both on PATH ahead of the generic brew prefix.
  rustupBin = "/opt/homebrew/opt/rustup/bin";
  cargoBin = "${config.home.homeDirectory}/.cargo/bin";
in
{
  home.sessionPath = [
    rustupBin
    cargoBin
  ];

  # Install/refresh the stable toolchain, lint/format components, and the
  # cross-targets `dist` may request. All rustup subcommands here are idempotent,
  # so reruns on every `darwin-rebuild switch` are cheap once the toolchain
  # exists. Non-fatal: a network hiccup logs but never aborts activation.
  home.activation.rustToolchain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${rustupBin}:/opt/homebrew/bin:$PATH"

    if command -v rustup &>/dev/null; then
      # Self-heal a partially-installed toolchain. An interrupted download (e.g.
      # a Ctrl-C'd switch) leaves the stable dir present but with a missing
      # manifest; `rustup default stable` then errors instead of re-downloading,
      # so it would stay broken across future switches. If stable is listed but
      # can't actually run rustc, it's corrupt — force a clean reinstall.
      if rustup toolchain list 2>/dev/null | grep -q '^stable-' \
         && ! rustup run stable rustc --version >/dev/null 2>&1; then
        echo >&2 "[rust] stable toolchain looks corrupt; reinstalling"
        rustup toolchain uninstall stable >/dev/null 2>&1 || true
      fi

      # `rustup default stable` auto-installs the stable toolchain if missing.
      rustup default stable >/dev/null 2>&1 \
        || echo >&2 "[rust] could not set default stable toolchain (offline?)"

      # rust-analyzer is a component (NOT the brew formula): rustup proxies the
      # `rust-analyzer` name on PATH, so a brew binary would be shadowed and
      # recurse. The component makes the proxy resolve to a real RA, version-
      # locked to the toolchain.
      rustup component add rustfmt clippy rust-analyzer >/dev/null 2>&1 \
        || echo >&2 "[rust] could not add rustfmt/clippy/rust-analyzer components"

      rustup target add \
        aarch64-apple-darwin \
        x86_64-apple-darwin \
        x86_64-unknown-linux-gnu \
        aarch64-unknown-linux-gnu >/dev/null 2>&1 \
        || echo >&2 "[rust] could not add one or more cross targets"
    fi
  '';
}
