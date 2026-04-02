local Module = require("module")
local class = require("utils.class")


---@class Launch: Module
local Launch = class.make_class("Launch", Module)


function Launch:__init__()
	Module.__init__(
		self,
		"launch",
		"Launch",
		"Launch applications and perform actions.",
		{},
		{{
			name="newFinderWindow",
			title="New Finder Window",
			descr="Open a new Finder window.",
			fn=function() self:newFinderWindow() end,
		}, {
			name="newEdgeWindow",
			title="New Edge Window",
			descr="Open a new Edge window.",
			fn=function() self:newEdgeWindow() end,
			default={"hyper", "b"},
		}, {
			name="newChromeWindow",
			title="New Chrome Window",
			descr="Open a new Chrome window.",
			fn=function() self:newChromeWindow() end,
		}, {
			name="newIterm2Window",
			title="New iTerm2 Window",
			descr="Open a new iTerm2 window.",
			fn=function() self:newIterm2Window() end,
		}, {
			name="launchMacPass",
			title="Launch MacPass",
			descr="Launch or focus MacPass.",
			fn=function() self:launchMacPass() end,
		}, {
			name="launchNotes",
			title="Launch Notes",
			descr="Launch or focus Notes.",
			fn=function() self:launchNotes() end,
		}, {
			name="startScreenSaver",
			title="Start Screen Saver",
			descr="Start the screen saver.",
			fn=function() self:startScreenSaver() end,
		}}
	)
end


function Launch:newFinderWindow()
	self:_check_loaded_and_started()
	hs.osascript.applescript([[
		tell application "Finder"
			make new Finder window to home
			activate
		end tell
	]])
end


function Launch:newChromeWindow()
	self:_check_loaded_and_started()
	local app = hs.appfinder.appFromName("Google Chrome")
	if not app then
		hs.application.launchOrFocus("Google Chrome")
		return
	end
	if not app:isRunning() then
		return
	end
	hs.osascript.applescript([[
		tell application "Google Chrome"
			make new window
			activate
		end tell
	]])
end


function Launch:newEdgeWindow()
	self:_check_loaded_and_started()
	hs.osascript.applescript([[
		set appName to "Microsoft Edge"

		if application appName is not running then
			tell application appName to launch

		else
			tell application appName
				make new window
				activate
			end tell

		end if
	]])
end


function Launch:newIterm2Window()
	self:_check_loaded_and_started()
	-- this is good when iTerm2 is configured with:
	--   "create window on startup?" -> No
	--   "window restoration policy" -> only restore hotkey window
	hs.osascript.applescript([[
		tell application "iTerm"
			create window with default profile
			activate
		end tell
	]])
end


function Launch:launchMacPass()
	self:_check_loaded_and_started()
	hs.application.launchOrFocus("MacPass")
end


function Launch:launchNotes()
	self:_check_loaded_and_started()
	hs.application.launchOrFocus("Notes")
end


function Launch:startScreenSaver()
	self:_check_loaded_and_started()
	hs.caffeinate.startScreensaver()
end


return Launch()
