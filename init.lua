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

-- local MyContainer = require("tiling.my_container")
-- local c0 = MyContainer(hs.screen.primaryScreen())

-- local iterm2_windows = hs.window.filter.new("iTerm2"):getWindows()

-- local c1 = nil
-- local c2 = nil
-- local c3 = nil

-- if #iterm2_windows > 0 then
-- 	c1 = MyContainer(nil, table.remove(iterm2_windows, 1))
-- end

-- if #iterm2_windows > 0 then
-- 	c2 = MyContainer(nil, table.remove(iterm2_windows, 1))
-- end

-- if #iterm2_windows > 0 then
-- 	c3 = MyContainer(nil, table.remove(iterm2_windows, 1))
-- end

-- c0:set_layout_direction("horizontal")

-- if c1 ~= nil then
-- 	c0:append_child(c1)
-- end

-- if c2 ~= nil then
-- 	c0:append_child(c2)
-- end

-- if c3 ~= nil then
-- 	assert(c2 ~= nil)
-- 	c2:set_layout_direction("vertical")
-- 	c2:append_child(c3)
-- 	c2:resize_child(2, 0.2)
-- end

-- if c1 ~= nil then
-- 	c0:resize_child(1, -0.2)
-- end