local config = {}

local wezterm = require("wezterm")
-------------------------------------
-- Highlevel WezTerm configuration --
-------------------------------------
-- OpenGL is now the default; WebGpu had issues on macOS
config.front_end = "OpenGL"

-- Reduce frame rate for smoother rendering in tmux
config.max_fps = 60

----------------------------------------------------------------------------------------
-- To get this to work - we had to manually add the terminfo to the local machine ;-(
-- tempfile=$(mktemp) \
--  && curl -o $tempfile https://raw.githubusercontent.com/wez/wezterm/main/termwiz/data/wezterm.terminfo \
--  && tic -x -o ~/.terminfo $tempfile \
--  && rm $tempfile
----------------------------------------------------------------------------------------
config.term = "wezterm"
config.font_size = 14.0
-- Tmux auto-start: each WezTerm window gets a new tmux session.
-- Use prefix+s (or ctrl-b s) inside tmux to list/switch sessions.
config.default_prog = { "/opt/homebrew/bin/tmux", "new-session" }

--------------------------
-- Visual Bell Settings --
--------------------------
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_duration_ms = 50,
	fade_out_duration_ms = 30,
	fade_in_function = "EaseIn",
	fade_out_function = "EaseOut",
	target = "BackgroundColor",
}

--------------------------------
-- Bottom Status Bar Settings --
--------------------------------
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.status_update_interval = 1000
config.tab_max_width = 32

-- Hacker-style color palette
local C = {
	bg_dark = "#0a0a0a",
	bg_mid = "#111111",
	bg_light = "#1a1a1a",
	green = "#00ff41",
	green_dim = "#00aa2a",
	cyan = "#00d4ff",
	red = "#ff0040",
	yellow = "#ffcc00",
	orange = "#ff6600",
	purple = "#bf00ff",
	white = "#ffffff",
	gray = "#555555",
}

-- Cache for system stats (updated less frequently)
local stats_cache = {
	load = "-.--",
	net_rx_rate = "0K",
	net_tx_rate = "0K",
	last_update = 0,
	last_rx_bytes = 0,
	last_tx_bytes = 0,
}

-- Cache for git info (per directory)
local git_cache = {
	cwd = "",
	branch = "",
	status = "",
	last_update = 0,
}

-- Cache for kubernetes context
local k8s_cache = {
	context = "",
	namespace = "",
	last_update = 0,
}

-- Resolve local hostname once at config load.
-- wezterm.hostname() can stall on macOS when Tailscale MagicDNS is reconverging,
-- because it walks getaddrinfo -> mDNSResponder -> 100.100.100.100. Calling it
-- per-tick from update-status amplifies that into visible status-bar lag.
local LOCAL_HOST = (function()
	local ok, h = pcall(wezterm.hostname)
	if not ok or not h or h == "" then return "localhost" end
	return h:match("^([^.]+)") or h
end)()

-- Status bar data plane.
-- A background daemon (~/.local/bin/wezterm-status-updater, installed by the
-- wez nix module) gathers git/k8s/sysctl/netstat output every second and
-- writes ~/.cache/wezterm/status.kv. update-status reads that file instead
-- of spawning subprocesses on the GUI thread.
local HOME = os.getenv("HOME") or ""
local STATUS_FILE = HOME .. "/.cache/wezterm/status.kv"
local CWD_REQ_FILE = HOME .. "/.cache/wezterm/cwd"
local UPDATER_PATH = HOME .. "/.local/bin/wezterm-status-updater"

-- Format bytes to human readable
local function format_rate(bytes_per_sec)
	if bytes_per_sec >= 1048576 then
		return string.format("%.1fM", bytes_per_sec / 1048576)
	elseif bytes_per_sec >= 1024 then
		return string.format("%.0fK", bytes_per_sec / 1024)
	else
		return string.format("%.0fB", bytes_per_sec)
	end
end

-- Build the starship-style status icon string from raw counts.
local function format_git_status(counts)
	local parts = {}
	if counts.conf > 0 then table.insert(parts, "=" .. counts.conf) end
	if counts.ahead > 0 and counts.behind > 0 then
		table.insert(parts, "⇕⇡" .. counts.ahead .. "⇣" .. counts.behind)
	elseif counts.ahead > 0 then
		table.insert(parts, "⇡" .. counts.ahead)
	elseif counts.behind > 0 then
		table.insert(parts, "⇣" .. counts.behind)
	end
	if counts.stash > 0 then table.insert(parts, " " .. counts.stash) end
	if counts.staged > 0 then table.insert(parts, "++" .. counts.staged) end
	if counts.mod > 0 then table.insert(parts, " " .. counts.mod) end
	if counts.ren > 0 then table.insert(parts, "󰑕 " .. counts.ren) end
	if counts.del > 0 then table.insert(parts, " " .. counts.del) end
	if counts.untrack > 0 then table.insert(parts, " " .. counts.untrack) end
	return table.concat(parts, " ")
end

-- Read the daemon's status file into the cache structs. Fast local-FS read,
-- ~10µs on APFS. Silently no-ops if the file isn't there yet (daemon hasn't
-- written its first tick).
local function read_status_file()
	local f = io.open(STATUS_FILE, "r")
	if not f then return end
	local content = f:read("*a")
	f:close()
	if not content then return end

	local kv = {}
	for line in content:gmatch("[^\n]+") do
		local k, v = line:match("^([^=]+)=(.*)$")
		if k then kv[k] = v end
	end

	if kv.load then stats_cache.load = kv.load end
	if kv.net_rx then stats_cache.net_rx_rate = format_rate(tonumber(kv.net_rx) or 0) end
	if kv.net_tx then stats_cache.net_tx_rate = format_rate(tonumber(kv.net_tx) or 0) end

	k8s_cache.context = kv.k8s_ctx or ""
	k8s_cache.namespace = (kv.k8s_ns ~= "" and kv.k8s_ns) or "default"

	git_cache.cwd = kv.git_cwd or ""
	git_cache.branch = kv.git_branch or ""
	if git_cache.branch ~= "" then
		git_cache.status = format_git_status({
			conf    = tonumber(kv.git_conf) or 0,
			untrack = tonumber(kv.git_untrack) or 0,
			ren     = tonumber(kv.git_ren) or 0,
			staged  = tonumber(kv.git_staged) or 0,
			mod     = tonumber(kv.git_mod) or 0,
			del     = tonumber(kv.git_del) or 0,
			ahead   = tonumber(kv.git_ahead) or 0,
			behind  = tonumber(kv.git_behind) or 0,
			stash   = tonumber(kv.git_stash) or 0,
		})
	else
		git_cache.status = ""
	end
end

-- Tell the daemon which directory to scope git queries to.
-- Only writes when the cwd changes — avoids 1 disk write/sec for nothing.
local last_written_cwd = nil
local function write_cwd_request(cwd)
	cwd = cwd or ""
	if cwd == last_written_cwd then return end
	local f = io.open(CWD_REQ_FILE, "w")
	if f then
		f:write(cwd)
		f:close()
		last_written_cwd = cwd
	end
end

-- Best-effort SSH host detection using only wezterm's built-in proc info.
-- No subprocess spawn — earlier `ps` fallback was the main culprit blocking
-- the GUI thread under DNS reconfig.
local function get_ssh_host(pane)
	local proc_info = pane:get_foreground_process_info()
	if not proc_info then return nil end
	local name = (proc_info.name or ""):match("([^/]+)$") or proc_info.name or ""
	if name ~= "ssh" then return nil end

	local argv = proc_info.argv
	if not argv or #argv < 2 then return nil end

	-- argv = {"ssh", [options...], [user@]host, [command...]}
	local skip_next = false
	for i = 2, #argv do
		local arg = argv[i]
		if skip_next then
			skip_next = false
		elseif arg:match("^%-[46AaCfGgKkMNnqsTtVvXxYy]+$") then
			-- option(s) without arguments
		elseif arg:match("^%-[bcDEeFIiJLlmOopQRSWw]$") then
			skip_next = true
		elseif arg:match("^%-[bcDEeFIiJLlmOopQRSWw].") then
			-- option with attached arg (-p22)
		elseif not arg:match("^%-") then
			return arg:match("@(.+)") or arg
		end
	end
	return nil
end

wezterm.on("update-status", function(window, pane)
	-- Pull the latest daemon-gathered data. No subprocess spawns here.
	read_status_file()

	-- Get current working directory and host
	local cwd_url = pane:get_current_working_dir()
	local cwd_str = "~"
	local remote_host = nil

	-- First try OSC 7 (if remote shell supports it)
	if cwd_url then
		cwd_str = cwd_url.file_path or "~"
		if cwd_url.host and cwd_url.host ~= "" and cwd_url.host ~= "localhost" then
			remote_host = cwd_url.host
		end
	end

	-- If no remote host from OSC 7, try detecting from SSH process
	if not remote_host then
		remote_host = get_ssh_host(pane)
	end

	-- Shorten home directory
	if HOME ~= "" and cwd_str:sub(1, #HOME) == HOME then
		cwd_str = "~" .. cwd_str:sub(#HOME + 1)
	end

	-- Tell the daemon which directory to gather git for next tick.
	-- Only if local — no point asking it to git over an SSH'd cwd.
	if cwd_url and cwd_url.file_path and not remote_host then
		write_cwd_request(cwd_url.file_path)
	else
		write_cwd_request("")
		git_cache.branch = ""
		git_cache.status = ""
	end

	-- Get process name
	local proc = pane:get_foreground_process_name() or ""
	proc = proc:match("([^/]+)$") or proc -- basename only

	-- Hostname - use remote host if SSH'd, otherwise the cached local hostname
	local host = remote_host or LOCAL_HOST
	local host_color = remote_host and C.orange or C.green -- Orange if remote
	local is_remote = remote_host ~= nil

	-- Build left status elements
	local left_elements = {
		{ Background = { Color = C.bg_dark } },
		{ Foreground = { Color = host_color } },
		{ Attribute = { Intensity = "Bold" } },
		{ Text = " " .. (is_remote and "󰣀 " or "󰀵 ") .. os.getenv("USER") .. "@" .. host .. " " },
		{ Foreground = { Color = C.gray } },
		{ Text = "" },
		{ Background = { Color = C.bg_mid } },
		{ Foreground = { Color = C.cyan } },
		{ Attribute = { Intensity = "Normal" } },
		{ Text = " " .. proc .. " " },
	}

	-- Add kubernetes context if available
	if k8s_cache.context ~= "" then
		table.insert(left_elements, { Foreground = { Color = C.gray } })
		table.insert(left_elements, { Text = "" })
		table.insert(left_elements, { Background = { Color = C.bg_light } })
		table.insert(left_elements, { Foreground = { Color = C.purple } })
		table.insert(left_elements, { Text = " 󱃾 " .. k8s_cache.context .. "(" .. k8s_cache.namespace .. ") " })
	end

	-- Add directory
	table.insert(left_elements, { Foreground = { Color = C.gray } })
	table.insert(left_elements, { Text = "" })
	table.insert(left_elements, { Background = { Color = C.bg_mid } })
	table.insert(left_elements, { Foreground = { Color = C.green_dim } })
	table.insert(left_elements, { Text = " 󰋜 " .. cwd_str .. " " })

	-- Add git info if in a repo
	if git_cache.branch ~= "" then
		local git_status_color = git_cache.status ~= "" and C.yellow or C.green
		table.insert(left_elements, { Foreground = { Color = C.gray } })
		table.insert(left_elements, { Text = "" })
		table.insert(left_elements, { Background = { Color = C.bg_light } })
		table.insert(left_elements, { Foreground = { Color = C.green } })
		table.insert(left_elements, { Text = "  " .. git_cache.branch })
		if git_cache.status ~= "" then
			table.insert(left_elements, { Foreground = { Color = git_status_color } })
			table.insert(left_elements, { Text = " [" .. git_cache.status .. "]" })
		end
		table.insert(left_elements, { Text = " " })
	end

	window:set_left_status(wezterm.format(left_elements))

	-- Battery with color coding
	local battery_text = ""
	local battery_color = C.gray
	local battery_info = wezterm.battery_info()
	if battery_info and #battery_info > 0 then
		local b = battery_info[1]
		local charge = b.state_of_charge
		if charge and charge == charge then -- NaN check
			charge = math.floor(charge * 100 + 0.5)
			battery_color = C.green
			if charge <= 20 then
				battery_color = C.red
			elseif charge <= 50 then
				battery_color = C.orange
			end
			local state = b.state or ""
			local icon = ""
			if state == "Charging" then
				icon = ""
			elseif charge > 80 then
				icon = ""
			elseif charge > 60 then
				icon = ""
			elseif charge > 40 then
				icon = ""
			elseif charge > 20 then
				icon = ""
			else
				icon = ""
			end
			battery_text = icon .. " " .. charge .. "%"
		end
	end

	-- Load average color
	local load_num = tonumber(stats_cache.load) or 0
	local load_color = C.green
	if load_num > 8 then
		load_color = C.red
	elseif load_num > 4 then
		load_color = C.orange
	elseif load_num > 2 then
		load_color = C.yellow
	end

	-- Date and time
	local date = wezterm.strftime("%Y-%m-%d")
	local time = wezterm.strftime("%H:%M:%S")

	-- Right status: net | load | battery | date | time (with icons)
	local right_elements = {
		{ Background = { Color = C.bg_light } },
		{ Foreground = { Color = C.cyan } },
		{ Text = " 󰇚 " .. stats_cache.net_rx_rate .. " " },  -- download icon
		{ Foreground = { Color = C.purple } },
		{ Text = "󰕒 " .. stats_cache.net_tx_rate .. " " },  -- upload icon
		{ Foreground = { Color = C.gray } },
		{ Text = "" },
		{ Background = { Color = C.bg_mid } },
		{ Foreground = { Color = load_color } },
		{ Text = " 󰍛 " .. stats_cache.load .. " " },  -- CPU/load icon
		{ Foreground = { Color = C.gray } },
		{ Text = "" },
	}

	-- Only show battery if we have valid data
	if battery_text ~= "" then
		table.insert(right_elements, { Background = { Color = C.bg_light } })
		table.insert(right_elements, { Foreground = { Color = battery_color } })
		table.insert(right_elements, { Text = " " .. battery_text .. " " })
		table.insert(right_elements, { Foreground = { Color = C.gray } })
		table.insert(right_elements, { Text = "" })
	end

	table.insert(right_elements, { Background = { Color = C.bg_mid } })
	table.insert(right_elements, { Foreground = { Color = C.purple } })
	table.insert(right_elements, { Text = "  " .. date .. " " })  -- calendar icon
	table.insert(right_elements, { Foreground = { Color = C.gray } })
	table.insert(right_elements, { Text = "" })
	table.insert(right_elements, { Background = { Color = C.bg_dark } })
	table.insert(right_elements, { Foreground = { Color = C.cyan } })
	table.insert(right_elements, { Attribute = { Intensity = "Bold" } })
	table.insert(right_elements, { Text = "  " .. time .. " " })  -- clock icon

	window:set_right_status(wezterm.format(right_elements))
end)

--------------------------------------
-- Startup and New Windows Handling --
--------------------------------------
-- Helper function to find the largest screen (by area)
local function get_largest_screen()
	local ok, screens = pcall(function()
		return wezterm.gui.screens()
	end)
	if not ok or not screens then
		return nil
	end

	local largest = nil
	local largest_area = 0

	for name, screen in pairs(screens.by_name) do
		-- Use effective dimensions (accounts for scaling)
		local area = screen.width * screen.height
		wezterm.log_info("Screen: " .. name .. " = " .. screen.width .. "x" .. screen.height .. " @ " .. screen.x .. "," .. screen.y)
		if area > largest_area then
			largest_area = area
			largest = screen
		end
	end

	return largest
end

-- Get all screens sorted by x position (for cycling)
local function get_screens_sorted()
	local ok, screens = pcall(function()
		return wezterm.gui.screens()
	end)
	if not ok or not screens then
		return {}
	end

	local sorted = {}
	for name, screen in pairs(screens.by_name) do
		table.insert(sorted, { name = name, screen = screen })
	end
	table.sort(sorted, function(a, b)
		return a.screen.x < b.screen.x
	end)
	return sorted
end

-- Move window to a specific screen
local function move_to_screen(window, screen)
	if screen then
		window:set_position(screen.x + 50, screen.y + 50)
		wezterm.time.call_after(0.1, function()
			window:maximize()
		end)
	end
end

-- Spawn the background status-bar updater. Fire-and-forget via shell &;
-- the daemon owns a pidfile so duplicate spawns are no-ops. The one /bin/sh
-- invocation here happens once per gui-startup, not per status tick.
local function ensure_status_updater()
	os.execute("nohup " .. UPDATER_PATH .. " > /dev/null 2>&1 &")
end

-- Startup: spawn on largest screen
wezterm.on("gui-startup", function(cmd)
	ensure_status_updater()
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	-- Defer the move until GUI is ready
	wezterm.time.call_after(0.3, function()
		local screen = get_largest_screen()
		if screen then
			local gui_win = window:gui_window()
			if gui_win then
				gui_win:set_position(screen.x + 50, screen.y + 50)
				wezterm.time.call_after(0.1, function()
					gui_win:maximize()
				end)
			end
		end
	end)
end)

-- Split pane, starting tmux in the current working directory
local function tmux_split(vertical)
	return wezterm.action_callback(function(window, pane)
		-- Query tmux directly for the active pane's cwd (most reliable).
		-- run_child_process skips the /bin/sh wrapper that io.popen would use.
		local ok, stdout = wezterm.run_child_process({
			"/opt/homebrew/bin/tmux", "display-message", "-p", "#{pane_current_path}"
		})
		local cwd_path = (ok and stdout) and (stdout:gsub("^%s+", ""):gsub("%s+$", "")) or ""
		if cwd_path == "" then
			-- Fallback to WezTerm's OSC 7 tracking, then $HOME
			local cwd = pane:get_current_working_dir()
			cwd_path = (cwd and cwd.file_path) or os.getenv("HOME")
		end
		local spawn = {
			args = { "/opt/homebrew/bin/tmux", "new-session", "-c", cwd_path },
		}
		local action = vertical
			and wezterm.action.SplitVertical(spawn)
			or wezterm.action.SplitHorizontal(spawn)
		window:perform_action(action, pane)
	end)
end

-- Action to cycle window to next screen
local function cycle_screen_action()
	return wezterm.action_callback(function(window, pane)
		local screens = get_screens_sorted()
		if #screens <= 1 then
			return
		end

		local dims = window:get_dimensions()
		local current_x = dims.pixel_x

		-- Find current screen and move to next
		local next_screen = screens[1].screen
		for i, s in ipairs(screens) do
			if current_x >= s.screen.x and current_x < s.screen.x + s.screen.width then
				next_screen = screens[(i % #screens) + 1].screen
				break
			end
		end

		move_to_screen(window, next_screen)
	end)
end

-- Action to move to largest screen
local function move_to_largest_action()
	return wezterm.action_callback(function(window, pane)
		local screen = get_largest_screen()
		move_to_screen(window, screen)
	end)
end

-----------------------------------------------------------------------------------
-- Enable Neovim to handle mouse input correctly (prevents copying line numbers) --
-----------------------------------------------------------------------------------
config.enable_wayland = false -- optional, depending on your system
----  config.enable_mouse_reporting = true

---------------------------------------------------------------------------------
-- Disable WezTerm's "copy on select" so the terminal doesn't grab text itself --
---------------------------------------------------------------------------------
-- config.copy_on_select = false

--------------------------------------------------------------------------------------
-- Optional: custom mouse bindings so Shift+drag falls back to normal terminal copy --
--------------------------------------------------------------------------------------
config.mouse_bindings = {
	------------------------------------------
	-- Let Neovim handle normal mouse input --
	------------------------------------------
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.SelectTextAtMouseCursor("Cell"),
	},
	{
		event = { Drag = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.ExtendSelectionToMouseCursor("Cell"),
	},
	--------------------------------------------------------------------------------
	-- Allow Shift+Drag to bypass Neovim and copy raw screen text (like in a log) --
	--------------------------------------------------------------------------------
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		action = wezterm.action.SelectTextAtMouseCursor("Cell"),
	},
	{
		event = { Drag = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		action = wezterm.action.ExtendSelectionToMouseCursor("Cell"),
	},
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "SHIFT",
		action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor("PrimarySelection"),
	},
}

--------------------------------------------------------------------------------
-- Custom Key Bindings                                                        --
-- see https://wezfurlong.org/wezterm/config/key-tables.html fot more options --
--------------------------------------------------------------------------------
config.keys = {
	----------------------------------------------------
	-- Panel spliting and window handling and closing --
	----------------------------------------------------
	{
		key = "d",
		mods = "SUPER|SHIFT",
		action = tmux_split(true),
	},
	{
		key = "d",
		mods = "SUPER",
		action = tmux_split(false),
	},
	{
		key = "w",
		mods = "SUPER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},

	----------------------------
	-- navigate to the panels --
	----------------------------
	{ key = "DownArrow", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "UpArrow", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "LeftArrow", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Right") },

	{ key = "j", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "h", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "l", mods = "SUPER", action = wezterm.action.ActivatePaneDirection("Right") },

	--------------------------------------
	-- Activate the next or last window --
	--------------------------------------
	{ key = "1", mods = "SUPER", action = wezterm.action.ActivateWindowRelative(1) },
	{ key = "2", mods = "SUPER", action = wezterm.action.ActivateWindowRelative(-1) },

	--------------------------------------
	-- Move window between screens      --
	--------------------------------------
	{ key = "`", mods = "SUPER", action = cycle_screen_action() },
	{ key = "0", mods = "SUPER", action = move_to_largest_action() },
}

-----------------------------------------
-- Custom Terminal Color and overrides --
-----------------------------------------
config.colors = {
	foreground = "white",
	background = "black",

	cursor_bg = "#52ad70",
	cursor_fg = "black",
	cursor_border = "green",

	selection_fg = "black",
	selection_bg = "green",

	scrollbar_thumb = "#222222",

	split = "#444444",

	ansi = {
		"black",
		"maroon",
		"green",
		"olive",
		"#7B68EE",
		"purple",
		"teal",
		"silver",
	},
	brights = {
		"grey",
		"red",
		"lime",
		"yellow",
		"#7B68EE",
		"fuchsia",
		"aqua",
		"white",
	},

	indexed = { [136] = "#af8700" },
	compose_cursor = "orange",
	copy_mode_active_highlight_bg = { Color = "#000000" },
	copy_mode_active_highlight_fg = { AnsiColor = "Black" },
	copy_mode_inactive_highlight_bg = { Color = "#52ad70" },
	copy_mode_inactive_highlight_fg = { AnsiColor = "White" },

	quick_select_label_bg = { Color = "peru" },
	quick_select_label_fg = { Color = "#ffffff" },
	quick_select_match_bg = { AnsiColor = "Navy" },
	quick_select_match_fg = { Color = "#ffffff" },

	-- Visual bell color (must contrast with cursor_bg to be visible)
	visual_bell = "#ff6b6b",
}

return config
