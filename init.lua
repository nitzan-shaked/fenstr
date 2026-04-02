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
PluginsManager.init(hs.configdir .. "/plugins")

local plugins = PluginsManager.getPluginsMap()

--[[ SETTINGS ]]

local SettingsManager = require("settings_manager")
SettingsManager.init(plugins)
SettingsManager.reloadSettings()

core_modules.hyper:bind(",", function() SettingsManager.showSettingsDialog(true,  true,  false) end)
core_modules.hyper:bind(".", function() SettingsManager.showSettingsDialog(false, false, true ) end)
core_modules.hyper:bind("b", function() plugins["launch"]:newEdgeWindow() end)

--[[ EXPERIMENTAL TILING ]]--

-- local MyContainer = require("tiling.my_container")
-- local c0 = MyContainer.top_level_for_screen(hs.screen.primaryScreen())

-- local function parent_for_new_window(w)
-- 	local parent = c0
-- 	while #parent._children > 0 do
-- 		parent = parent._children[#parent._children]
-- 	end
-- 	return parent
-- end

-- local wf = hs.window.filter.new("iTerm2")

-- wf:subscribe(hs.window.filter.windowAllowed, function(w)
-- 	if MyContainer.existing_for_window(w) then return end
-- 	local parent = parent_for_new_window(w)
-- 	local new_container = MyContainer.new_for_window(w)
-- 	parent:append_child(new_container)
-- end)

-- wf:subscribe(hs.window.filter.windowRejected, function(w)
-- 	local c = MyContainer.existing_for_window(w)
-- 	if not c then return end
-- 	c:forget_window()
-- 	c:delete()
-- end)

-- wf:subscribe(hs.window.filter.windowMoved, function(w)
-- 	local c = MyContainer.existing_for_window(w)
-- 	if not c then return end
-- 	c:_refresh_window()
-- end)

-- wf:subscribe(hs.window.filter.windowFocused, function(w)
-- 	local c = MyContainer.existing_for_window(w)
-- 	if not c then return end
-- 	c:indicate_focus(true)
-- end)

-- wf:subscribe(hs.window.filter.windowUnfocused, function(w)
-- 	local c = MyContainer.existing_for_window(w)
-- 	if not c then return end
-- 	c:indicate_focus(false)
-- end)
