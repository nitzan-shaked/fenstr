---@module "hs"

hs.console.clearConsole()

--[[ HS CONFIG ]]

hs.window.animationDuration = 0

--[[ CORE FUNCTIONALITY ]]

local core_modules = require("core_modules")
for _, core_module in pairs(core_modules) do
	core_module:load({})
	core_module:start()
end

--[[ DEBUG ]]

core_modules.hyper:bind("y", hs.toggleConsole)

--[[ PLUGINS ]]

print("-- Loading plugins")
local PluginsManager = require("plugins_manager")
PluginsManager.init("plugins")

--[[ SETTINGS ]]

local SettingsManager = require("settings_manager")
SettingsManager.init(PluginsManager.getPluginsMap())
SettingsManager.reloadSettings()

core_modules.hyper:bind(",", function() SettingsManager.showSettingsDialog(true,  true,  false) end)
core_modules.hyper:bind(".", function() SettingsManager.showSettingsDialog(false, false, true ) end)

--[[ EXPERIMENTAL TILING ]]--

local MyContainer = require("tiling.my_container")
local c0 = MyContainer.top_level_for_screen(hs.screen.primaryScreen())

local function parent_for_new_window(w)
	local parent = c0
	while #parent._children > 0 do
		parent = parent._children[#parent._children]
	end
	return parent
end

local wf = hs.window.filter.new("iTerm2")

wf:subscribe(hs.window.filter.windowAllowed, function(w)
	if MyContainer.existing_for_window(w) then return end
	local parent = parent_for_new_window(w)
	local new_container = MyContainer.new_for_window(w)
	parent:append_child(new_container)
end)

wf:subscribe(hs.window.filter.windowRejected, function(w)
	local c = MyContainer.existing_for_window(w)
	if not c then return end
	c:forget_window()
	c:delete()
end)
