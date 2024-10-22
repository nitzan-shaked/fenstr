---@module "hs"

--[[ CONFIG ]]

hs.window.animationDuration = 0

local KBD_WIN_PLACE			= {"ctrl", "cmd"}
local KBD_WIN_MOVE			= {"ctrl", "cmd"}
local KBD_WIN_RESIZE		= {"ctrl", "alt"}
local KBD_DRAG_LIMIT_AXIS	= {"shift"}

--[[ MAIN ]]

hs.console.clearConsole()

--[[ RELOAD ]]

local reload = require("reload")
reload.start()

--[[ MENU-BAR WIDGETS ]]

-- local menubar_volume_widget = require("menubar.volume_widget")
-- menubar_volume_widget.init()

--[[ HYPER-OR-ESC ]]

local hyper_or_esc = require("hyper_or_esc")

--[[ HIGHLIGHT-MOUSE-CURSOR ]]

local highlight_mouse_cursor = require("highlight_mouse_cursor")
highlight_mouse_cursor.bind_hotkey(KBD_WIN_MOVE, "m")

--[[ HIGHLIGHT-MOUSE-CLICKS ]]
-- local highlight_mouse_clicks = require("highlight_mouse_clicks")
-- highlight_mouse_clicks:start()

--[[ KEY-CASTR ]]
-- local key_castr = require("key_castr")
-- key_castr:start()

--[[ HYPER-LAUNCH ]]

local launch = require("launch")
hyper_or_esc.bind("f", launch.new_finder_window)
hyper_or_esc.bind("b", launch.new_chrome_window)
hyper_or_esc.bind("t", launch.new_iterm2_window)
hyper_or_esc.bind("k", launch.launch_mac_pass)
hyper_or_esc.bind("n", launch.launch_notes)
hyper_or_esc.bind("l", launch.start_screen_saver)
hyper_or_esc.bind("y", hs.toggleConsole)

--[[ DARK-BG ]]

local dark_bg = require("dark_bg")
hyper_or_esc.bind("-", dark_bg.darker, true)
hyper_or_esc.bind("=", dark_bg.lighter, true)

--[[ MINI-PREVIEWS ]]

local mini_preview = require("mini_preview")
local win_utils = require("win_utils")

hyper_or_esc.bind("m", function ()
	mini_preview.toggle_for_window(win_utils.window_under_pointer())
end)

-- experimenting with BorderDrag
--local drag_border = require("drag_border")
--hyper_or_esc.bind("x", function ()
--	local d = drag_border.BorderDrag(win_utils.window_under_pointer())
--end)

--[[ KBD-WIN ]]

local kbd_win = require("kbd_win")
kbd_win.bind_hotkeys(
	hs.hotkey.bind,
	KBD_WIN_PLACE,
	KBD_WIN_MOVE,
	KBD_WIN_RESIZE
)

--[[ DRAG-TO-MOVE/RESIZE ]]

local drag = require("drag")
drag.set_kbd_mods(
	KBD_WIN_MOVE,
	KBD_WIN_RESIZE,
	KBD_DRAG_LIMIT_AXIS
)
