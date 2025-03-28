local config = {}

local wezterm = require 'wezterm'
-------------------------------------
-- Highlevel WezTerm configuration --
-------------------------------------
config.front_end = "WebGpu" 

----------------------------------------------------------------------------------------
-- To get this to work - we had to manually add the terminfo to the local machine ;-( 
-- tempfile=$(mktemp) \
--  && curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
--  && tic -x -o ~/.terminfo $tempfile \
--  && rm $tempfile
----------------------------------------------------------------------------------------
config.term = "wezterm"
config.font_size = 14.0
config.default_prog = { "zsh" }

--------------------------------------
-- Startup and New Windows Handling --
--------------------------------------
wezterm.on("gui-startup", function(cmd)
   local screen = wezterm.gui.screens().main
   local ratio = 0.7
   local width, height = screen.width * ratio, screen.height * ratio
   local tab, pane, window = wezterm.mux.spawn_window(cmd or {
      position = { x = (screen.width - width) / 2, y = (screen.height - height) / 2 },
	})
   window:gui_window():set_inner_size(width, height)
end)

wezterm.on("gui-attached", function(cmd)
   local screen = wezterm.gui.screens().main
   local ratio = 0.7
   local width, height = screen.width * ratio, screen.height * ratio
   local tab, pane, window = wezterm.mux.spawn_window(cmd or {
      position = { x = (screen.width - width) / 2, y = (screen.height - height) / 2 },
	})
   window:gui_window():set_inner_size(width, height)
end)



--------------------------------------------------------------------------------
-- Custom Key Bindings                                                        --
-- see https://wezfurlong.org/wezterm/config/key-tables.html fot more options --
--------------------------------------------------------------------------------
config.keys = {
   ----------------------------------------------------
   -- Panel spliting and window handling and closing --
   ----------------------------------------------------
   {  key = 'd',           mods = 'SUPER|SHIFT',   action = wezterm.action.SplitVertical                 { domain = 'CurrentPaneDomain' },   },
   {  key = 'd',           mods = 'SUPER',         action = wezterm.action.SplitHorizontal               { domain = 'CurrentPaneDomain' },   },
   {  key = 'w',           mods = 'SUPER',         action = wezterm.action.CloseCurrentPane              { confirm = true },                 },

   ----------------------------
   -- navigate to the panels --
   ----------------------------
   {  key = 'DownArrow',   mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Down'  },
   {  key = 'UpArrow',     mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Up'    },
   {  key = 'LeftArrow',   mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Left'  },
   {  key = 'RightArrow',  mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Right' },

   {  key = 'j',           mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Down'  },
   {  key = 'k',           mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Up'    },
   {  key = 'h',           mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Left'  },
   {  key = 'l',           mods = 'SUPER',         action = wezterm.action.ActivatePaneDirection 'Right' },

   --------------------------------------
   -- Activate the next or last window --
   --------------------------------------
   {  key = '1',           mods = 'SUPER',         action = wezterm.action.ActivateWindowRelative(1)  },
   {  key = '2',           mods = 'SUPER',         action = wezterm.action.ActivateWindowRelative(-1) },
}



-----------------------------------------
-- Custom Terminal Color and overrides --
-----------------------------------------
config.colors = {
   foreground = 'white',
   background = 'black',

   cursor_bg = '#52ad70',
   cursor_fg = 'black',
   cursor_border = 'green',

   selection_fg = 'black',
   selection_bg = 'green',

   scrollbar_thumb = '#222222',

   split = '#444444',

   ansi = {
      'black',
      'maroon',
      'green',
      'olive',
      '#7B68EE',
      'purple',
      'teal',
      'silver',
   },
   brights = {
      'grey',
      'red',
      'lime',
      'yellow',
      '#7B68EE',
      'fuchsia',
      'aqua',
      'white',
   },

   indexed = { [136] = '#af8700' },
   compose_cursor = 'orange',
   copy_mode_active_highlight_bg = { Color = '#000000' },
   copy_mode_active_highlight_fg = { AnsiColor = 'Black' },
   copy_mode_inactive_highlight_bg = { Color = '#52ad70' },
   copy_mode_inactive_highlight_fg = { AnsiColor = 'White' },

   quick_select_label_bg = { Color = 'peru' },
   quick_select_label_fg = { Color = '#ffffff' },
   quick_select_match_bg = { AnsiColor = 'Navy' },
   quick_select_match_fg = { Color = '#ffffff' },
}



return config






