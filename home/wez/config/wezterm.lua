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
-- Tmux auto-start (re-enabled after fixing status-interval 1->5)
config.default_prog = { "/opt/homebrew/bin/tmux", "new-session", "-A", "-s", "main" }

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

-- Helper to run shell command and get output
local function shell_cmd(cmd)
	local handle = io.popen(cmd)
	if handle then
		local result = handle:read("*a")
		handle:close()
		return result:gsub("^%s+", ""):gsub("%s+$", "") -- trim
	end
	return ""
end

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

-- Update git info for a directory (starship-style icons)
local function update_git_info(cwd)
	local now = os.time()
	-- Update every 2 seconds or when directory changes
	if git_cache.cwd == cwd and now - git_cache.last_update < 2 then
		return
	end
	git_cache.cwd = cwd
	git_cache.last_update = now

	-- Check if in a git repo and get branch
	local branch = shell_cmd("cd " .. wezterm.shell_quote_arg(cwd) .. " && git rev-parse --abbrev-ref HEAD 2>/dev/null")
	if branch == "" then
		git_cache.branch = ""
		git_cache.status = ""
		return
	end
	git_cache.branch = branch

	-- Get git status (starship-style)
	local status_parts = {}

	-- Check for various states
	local status_output = shell_cmd("cd " .. wezterm.shell_quote_arg(cwd) .. " && git status --porcelain 2>/dev/null")

	local modified = 0
	local staged = 0
	local untracked = 0
	local deleted = 0
	local renamed = 0
	local conflicted = 0

	for line in status_output:gmatch("[^\n]+") do
		local index = line:sub(1, 1)
		local worktree = line:sub(2, 2)

		if index == "U" or worktree == "U" or (index == "A" and worktree == "A") or (index == "D" and worktree == "D") then
			conflicted = conflicted + 1
		elseif index == "?" then
			untracked = untracked + 1
		elseif index == "R" then
			renamed = renamed + 1
		else
			if index ~= " " and index ~= "?" then
				staged = staged + 1
			end
			if worktree == "M" then
				modified = modified + 1
			elseif worktree == "D" then
				deleted = deleted + 1
			end
		end
	end

	-- Starship-style icons
	if conflicted > 0 then
		table.insert(status_parts, "=" .. conflicted)  -- conflicted
	end

	-- Check ahead/behind first (like starship)
	local ahead_behind = shell_cmd("cd " .. wezterm.shell_quote_arg(cwd) .. " && git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null")
	local ahead, behind = ahead_behind:match("(%d+)%s+(%d+)")
	ahead = tonumber(ahead) or 0
	behind = tonumber(behind) or 0

	if ahead > 0 and behind > 0 then
		table.insert(status_parts, "⇕⇡" .. ahead .. "⇣" .. behind)  -- diverged
	elseif ahead > 0 then
		table.insert(status_parts, "⇡" .. ahead)  -- ahead
	elseif behind > 0 then
		table.insert(status_parts, "⇣" .. behind)  -- behind
	end

	-- Check stash
	local stash_count = shell_cmd("cd " .. wezterm.shell_quote_arg(cwd) .. " && git stash list 2>/dev/null | wc -l")
	stash_count = tonumber(stash_count) or 0
	if stash_count > 0 then
		table.insert(status_parts, " " .. stash_count)  -- stashed
	end

	if staged > 0 then
		table.insert(status_parts, "++" .. staged)  -- staged
	end
	if modified > 0 then
		table.insert(status_parts, " " .. modified)  -- modified
	end
	if renamed > 0 then
		table.insert(status_parts, "󰑕 " .. renamed)  -- renamed
	end
	if deleted > 0 then
		table.insert(status_parts, " " .. deleted)  -- deleted
	end
	if untracked > 0 then
		table.insert(status_parts, " " .. untracked)  -- untracked
	end

	git_cache.status = table.concat(status_parts, " ")
end

-- Cache for SSH host detection
local ssh_cache = {
	pane_id = nil,
	host = nil,
	last_check = 0,
}

-- Detect SSH host from process
local function get_ssh_host(pane)
	local pane_id = pane:pane_id()
	local now = os.time()

	-- Cache for 1 second per pane
	if ssh_cache.pane_id == pane_id and now - ssh_cache.last_check < 1 then
		return ssh_cache.host
	end

	ssh_cache.pane_id = pane_id
	ssh_cache.last_check = now
	ssh_cache.host = nil

	-- Get foreground process name
	local proc_name = pane:get_foreground_process_name() or ""
	proc_name = proc_name:match("([^/]+)$") or proc_name

	wezterm.log_info("Foreground process: " .. proc_name)

	if proc_name ~= "ssh" then
		return nil
	end

	-- Try multiple methods to get PID
	local pid = nil

	-- Method 1: get_foreground_process_info()
	local proc_info = pane:get_foreground_process_info()
	if proc_info then
		pid = proc_info.pid or proc_info.process_id
		wezterm.log_info("proc_info: " .. wezterm.json_encode(proc_info))
	end

	-- Method 2: If no PID, try to find ssh process for this tty
	if not pid then
		-- Get the tty for this pane and find ssh process
		local tty = pane:get_tty_name()
		if tty then
			local tty_short = tty:match("/dev/(.+)") or tty
			local pid_output = shell_cmd("ps -t " .. tty_short .. " -o pid,comm 2>/dev/null | grep ssh | awk '{print $1}' | head -1")
			pid = tonumber(pid_output)
			wezterm.log_info("Found SSH PID via tty " .. tty_short .. ": " .. tostring(pid))
		end
	end

	if not pid then
		wezterm.log_info("Could not get SSH PID")
		return nil
	end

	-- Use ps to get the full command line on macOS
	local cmd_output = shell_cmd("ps -p " .. pid .. " -o args= 2>/dev/null")
	wezterm.log_info("SSH PID: " .. pid .. " CMD: " .. cmd_output)
	if cmd_output == "" then
		return nil
	end

	-- Parse SSH command line to find the host
	-- Pattern: ssh [options] [user@]hostname [command]
	local ssh_host = nil

	-- Remove leading "ssh" and split into args
	local args_str = cmd_output:gsub("^%s*ssh%s+", "")

	-- Skip options and find the host
	local skip_next = false
	for arg in args_str:gmatch("%S+") do
		if skip_next then
			skip_next = false
		elseif arg:match("^%-[46AaCfGgKkMNnqsTtVvXxYy]+$") then
			-- Options without arguments, continue
		elseif arg:match("^%-[bcDEeFIiJLlmOopQRSWw]$") then
			-- Options that take an argument
			skip_next = true
		elseif arg:match("^%-[bcDEeFIiJLlmOopQRSWw].") then
			-- Option with argument attached (e.g., -p22)
			-- continue
		elseif not arg:match("^%-") then
			-- First non-option is [user@]hostname
			ssh_host = arg:match("@(.+)") or arg
			break
		end
	end

	wezterm.log_info("Extracted SSH host: " .. tostring(ssh_host))
	ssh_cache.host = ssh_host
	return ssh_host
end

-- Update kubernetes context
local function update_k8s_info()
	local now = os.time()
	if now - k8s_cache.last_update < 5 then -- Update every 5 seconds
		return
	end
	k8s_cache.last_update = now

	local context = shell_cmd("kubectl config current-context 2>/dev/null")
	local namespace = shell_cmd("kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null")

	k8s_cache.context = context
	k8s_cache.namespace = namespace ~= "" and namespace or "default"
end

-- Update system stats (load, network)
local function update_stats()
	local now = os.time()
	-- Update every 2 seconds to reduce overhead
	if now - stats_cache.last_update < 2 then
		return
	end
	stats_cache.last_update = now

	-- Get load average (1 min)
	local load_output = shell_cmd("sysctl -n vm.loadavg 2>/dev/null")
	local load1 = load_output:match("{%s*([%d.]+)")
	if load1 then
		stats_cache.load = load1
	end

	-- Get network bytes (macOS - primary interface)
	local net_output = shell_cmd("netstat -ib 2>/dev/null | grep -E '^en0' | head -1")
	if net_output and net_output ~= "" then
		local fields = {}
		for field in net_output:gmatch("%S+") do
			table.insert(fields, field)
		end
		-- netstat -ib columns: Name, Mtu, Network, Address, Ipkts, Ierrs, Ibytes, Opkts, Oerrs, Obytes, Coll
		local rx_bytes = tonumber(fields[7]) or 0
		local tx_bytes = tonumber(fields[10]) or 0

		if stats_cache.last_rx_bytes > 0 then
			local rx_delta = rx_bytes - stats_cache.last_rx_bytes
			local tx_delta = tx_bytes - stats_cache.last_tx_bytes
			local interval = 2 -- seconds
			if rx_delta >= 0 and tx_delta >= 0 then
				stats_cache.net_rx_rate = format_rate(rx_delta / interval)
				stats_cache.net_tx_rate = format_rate(tx_delta / interval)
			end
		end
		stats_cache.last_rx_bytes = rx_bytes
		stats_cache.last_tx_bytes = tx_bytes
	end
end

wezterm.on("update-status", function(window, pane)
	-- Update cached system stats
	update_stats()
	update_k8s_info()

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
	local home = os.getenv("HOME") or ""
	if home ~= "" and cwd_str:sub(1, #home) == home then
		cwd_str = "~" .. cwd_str:sub(#home + 1)
	end

	-- Update git info for current directory (only if local)
	if cwd_url and cwd_url.file_path and not remote_host then
		update_git_info(cwd_url.file_path)
	else
		git_cache.branch = ""
		git_cache.status = ""
	end

	-- Get process name
	local proc = pane:get_foreground_process_name() or ""
	proc = proc:match("([^/]+)$") or proc -- basename only

	-- Hostname - use remote host if SSH'd, otherwise local
	local local_host = wezterm.hostname():match("^([^.]+)") or wezterm.hostname()
	local host = remote_host or local_host
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

-- Startup: spawn on largest screen
wezterm.on("gui-startup", function(cmd)
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
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "d",
		mods = "SUPER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
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
