# Rectangle Window Manager Configuration
# ======================================
# Declarative settings for Rectangle (installed via Homebrew cask in
# modules/homebrew.nix). Writes to plist domain com.knollsoft.Rectangle
# on each rebuild.
#
# Captured from a working config on 2026-04-22. To re-capture after UI
# changes, run: defaults read com.knollsoft.Rectangle
#
# Notes on what's intentionally NOT codified:
#   - SUHasLaunchedBefore / SULastCheckTime — Sparkle runtime state
#   - installVersion / lastVersion         — Rectangle's internal migration markers
#
# Shortcut values use integer keyCode + modifierFlags bitmask.
# modifierFlags is an NSEvent bitmask: Shift=0x20000, Ctrl=0x40000,
# Opt=0x80000, Cmd=0x100000. Values seen in this config:
#   393216  = ⌃⇧    (control + shift)
#   786432  = ⌃⌥    (control + option)
#   917504  = ⌃⌥⇧   (control + option + shift)
#   1441792 = ⌃⇧⌘   (control + shift + command)
#
# Some sixth-actions (topCenterSixth, bottomCenterSixth) are intentionally
# empty: the action is registered with no key bound. Preserve the empty
# dict so Rectangle doesn't silently re-introduce a future default.

{ ... }:

{
  system.defaults.CustomUserPreferences."com.knollsoft.Rectangle" = {
    # --- Behavior -----------------------------------------------------
    allowAnyShortcut = true;
    alternateDefaultShortcuts = true;
    launchOnLogin = true;
    hideMenubarIcon = true;
    doubleClickTitleBar = 3;
    subsequentExecutionMode = 1;
    moveCursorAcrossDisplays = 2;
    gapSize = 3.0;                              # plist type: float
    footprintAnimationDurationMultiplier = 0.75; # plist type: float

    # Suppress first-run dialogs (values captured post-dismissal)
    notifiedOfProblemApps = true;
    internalTilingNotified = true;

    # --- Snap areas (JSON-encoded strings; shape defined by Rectangle) ----
    landscapeSnapAreas = "[1,{\"action\":15},4,{\"compound\":-2},7,{\"action\":10},8,{\"action\":14},2,{\"action\":11},5,{\"compound\":-3},6,{\"action\":13},3,{\"action\":16}]";
    portraitSnapAreas = "[8,{\"action\":14},6,{\"action\":13},2,{\"action\":11},3,{\"action\":16},7,{\"action\":10},4,{\"compound\":-5},5,{\"compound\":-5},1,{\"action\":15}]";

    # --- Keyboard shortcuts -------------------------------------------
    # Halves (⌃⇧)
    leftHalf     = { keyCode = 86; modifierFlags = 393216; };
    rightHalf    = { keyCode = 88; modifierFlags = 393216; };
    topHalf      = { keyCode = 91; modifierFlags = 393216; };
    bottomHalf   = { keyCode = 84; modifierFlags = 393216; };

    # Quarters (⌃⇧)
    topLeft      = { keyCode = 89; modifierFlags = 393216; };
    topRight     = { keyCode = 92; modifierFlags = 393216; };
    bottomLeft   = { keyCode = 83; modifierFlags = 393216; };
    bottomRight  = { keyCode = 85; modifierFlags = 393216; };

    # Sixths (⌃⇧⌘) — two corners intentionally unbound
    topLeftSixth      = { keyCode = 89; modifierFlags = 1441792; };
    topCenterSixth    = { };
    topRightSixth     = { keyCode = 92; modifierFlags = 1441792; };
    bottomLeftSixth   = { keyCode = 83; modifierFlags = 1441792; };
    bottomCenterSixth = { };
    bottomRightSixth  = { keyCode = 85; modifierFlags = 1441792; };

    # Size
    maximize        = { keyCode = 76; modifierFlags = 393216; };  # ⌃⇧
    almostMaximize  = { keyCode = 76; modifierFlags = 786432; };  # ⌃⌥
    maximizeHeight  = { keyCode = 91; modifierFlags = 917504; };  # ⌃⌥⇧
    center          = { keyCode = 87; modifierFlags = 393216; };  # ⌃⇧
    restore         = { keyCode = 82; modifierFlags = 393216; };  # ⌃⇧
    larger          = { keyCode = 69; modifierFlags = 393216; };  # ⌃⇧
    smaller         = { keyCode = 78; modifierFlags = 393216; };  # ⌃⇧

    # Pixel-level move (⌃⇧⌘ + arrows)
    moveUp    = { keyCode = 91; modifierFlags = 1441792; };
    moveDown  = { keyCode = 84; modifierFlags = 1441792; };
    moveLeft  = { keyCode = 86; modifierFlags = 1441792; };
    moveRight = { keyCode = 88; modifierFlags = 1441792; };

    # Displays (⌃⇧ + left/right arrow)
    nextDisplay      = { keyCode = 123; modifierFlags = 393216; };
    previousDisplay  = { keyCode = 124; modifierFlags = 393216; };

    # Todo window (floating side panel, ⌃⌥)
    toggleTodo = { keyCode = 11; modifierFlags = 786432; };
    reflowTodo = { keyCode = 45; modifierFlags = 786432; };
  };
}
