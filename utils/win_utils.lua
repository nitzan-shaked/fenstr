-- local mp = require("experimental.mini_preview")
local hsu = require("utils.hs_utils")

--[[ STATE ]]

---@type table<string, boolean>
local ALLOWED_BUNDLE_IDS = {}
for _, bundle_id in ipairs({
	"com.kapeli.dashdoc",
	hsu.hammerspoon_app_bundle_id,
}) do ALLOWED_BUNDLE_IDS[bundle_id] = true end

--[[ LOGIC ]]

---@return Window[]
local function my_visibleWindows()
	local result = {}
	for _, app in pairs(hs.application.runningApplications()) do
		if (
			app:kind() > 0
			or ALLOWED_BUNDLE_IDS[app:bundleID()]
		) and not app:isHidden() then
			for _, w in ipairs(app:visibleWindows()) do
				result[#result + 1] = w
			end
		end
	end
	return result
end

---@return Window[]
local function my_orderedWindows()
	local win_set = {}
	for _, w in ipairs(my_visibleWindows()) do
		win_set[w:id() or -1] = w
	end

	local result = {}
	for _, win_id in ipairs(hs.window._orderedwinids()) do
		result[#result + 1] = win_set[win_id]
	end
	return result
end

---@return Window?
local function mini_preview_under_pointer()
	return nil
	-- local mouse_pos = hs.geometry(hs.mouse.absolutePosition())
	-- local mouse_screen = hs.mouse.getCurrentScreen()
	-- local hammerspoon_app = hsu.hammerspoon_app
	-- local result = hs.fnutils.find(hammerspoon_app:visibleWindows(), function (w)
	-- 	return (
	-- 		w:screen() == mouse_screen
	-- 		and mp.MiniPreview.by_mini_preview_window(w) ~= nil
	-- 		and mouse_pos:inside(w:frame())
	-- 	)
	-- end)
	-- return result
end

---@param include_mini_previews boolean?
---@return Window?
local function window_under_pointer(include_mini_previews)
	local mouse_pos = hs.geometry(hs.mouse.absolutePosition())
	local mouse_screen = hs.mouse.getCurrentScreen()
	if include_mini_previews then
		local result = mini_preview_under_pointer()
		if result then
			return result
		end
	end
	local result = hs.fnutils.find(my_orderedWindows(), function (w)
		return (
			w:screen() == mouse_screen
			and w:isStandard()
			and mouse_pos:inside(w:frame())
		)
	end)
	return result
end

local function dump_windows_list()
	for _, w in ipairs(hs.window.allWindows()) do
		print(
			w:id(),
			w:application():name(),
			w:title(),
			w:role(),
			w:subrole(),
			w:isStandard()
		)
	end
end

--[[ MODULE ]]

return {
	my_visibleWindows=my_visibleWindows,
	my_orderedWindows=my_orderedWindows,
	window_under_pointer=window_under_pointer,
	dump_windows_list=dump_windows_list,
}
