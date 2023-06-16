local Point = require("point")
local Size = require("size")
local class = require("class")

--[[ CONFIG ]]

local BUTTON_RADIUS = 6
local BUTTON_PADDING = Size(2, 2)

--[[ LOGIC ]]

---@class TitleBarButton
---@field name string
---@field canvas Canvas
local TitleBarButton = class("TitleBarButton")

---@param name string
---@param callback fun(button: TitleBarButton)
---@param color any
function TitleBarButton:__init__(name, callback, color)
	self.name = name
	self.callback = callback

	self.r = BUTTON_RADIUS
	self.rx = self.r * Size:x_axis()
	self.ry = self.r * Size:y_axis()
	self.rxy = self.rx + self.ry

	local sqrt_2 = math.sqrt(2)
	self.d45 = self.r * (sqrt_2 - 1) / sqrt_2
	self.d45x = self.d45 * Size:x_axis()
	self.d45y = self.d45 * Size:y_axis()
	self.d45xy = self.d45x + self.d45y

	self.circle_xy00       = Point(BUTTON_PADDING)
	self.circle_xy11       = self.circle_xy00 + self.rxy * 2
	self.circle_mid_left   = self.circle_xy00 + self.ry
	self.circle_mid_right  = self.circle_xy11 - self.ry
	self.circle_mid_top    = self.circle_xy00 + self.rx
	self.circle_mid_bottom = self.circle_xy11 - self.rx
	self.circle_center     = self.circle_xy00 + self.rxy

	self.size = BUTTON_PADDING * 2 + self.rxy * 2

	self.canvas = hs.canvas.new({})
	self.canvas:appendElements({
		id="button",
		type="circle",
		action="fill",
		fillColor=color,
		center=self.circle_center,
		radius=self.r,
		trackMouseDown=true,
	})
	self.canvas:mouseCallback(function (...) self:mouseCallback() end)

	---@type string[]
	self.extra_element_ids = {}
end

function TitleBarButton:mouseCallback()
	self.callback(self)
end

function TitleBarButton:showExtraElements()
	for _, elem_id in ipairs(self.extra_element_ids) do
		local elem = self.canvas[elem_id]
		elem.fillColor.alpha = 1
		elem.strokeColor.alpha = 1
	end
end

function TitleBarButton:hideExtraElements()
	for _, elem_id in ipairs(self.extra_element_ids) do
		local elem = self.canvas[elem_id]
		elem.fillColor.alpha = 0
		elem.strokeColor.alpha = 0
	end
end

function TitleBarButton:onEnterButtonArea()
	self:showExtraElements()
end

function TitleBarButton:onExitButtonArea()
	self:hideExtraElements()
end

--[[ MODULE ]]

return TitleBarButton
