local Module = require("module")
local class = require("utils.class")


---@class SpaceIdWidget: Module
local SpaceIdWidget = class.make_class("SpaceIdWidget", Module)

local _CFG_CELL_SIZE = {
	name="cell_size",
	title="Cell Size (px)",
	descr="Width and height of one 'cell'.",
	control="number",
	default=20,
}
local _CFG_FONT_SIZE = {
	name="font_size",
	title="Font Size (points)",
	descr="Font size for space number.",
	control="number",
	default=14,
}
local _CFG_FRAME_THICKNESS = {
	name="frame_thickness",
	title="Frame Thickness",
	descr="Thickness of frame around cell.",
	control="numbe",
	default=1,
}

function SpaceIdWidget:__init__()
	Module.__init__(
		self,
		"spaceid_widget",
		"SpaceId Widget",
		"Visual indication of the current space.",
		{
			_CFG_CELL_SIZE,
			_CFG_FONT_SIZE,
			_CFG_FRAME_THICKNESS,
		},
		{}
	)
end


function SpaceIdWidget:loadImpl(settings)
	self._cell_size = settings.cell_size
	self._font_size = settings.font_size
	self._frame_thickness = settings.frame_thickness

	self._canvas = nil
	self._screen_watcher = hs.screen.watcher.new(function() self:_on_screen_changed() end)
	self._space_watcher = hs.spaces.watcher.new(function() self:_on_space_changed() end)
	self._menubar_item = hs.menubar.new(true, "spaceid_widget")
end

function SpaceIdWidget:startImpl()
	self._screen_watcher:start()
	self._space_watcher:start()
    self._menubar_item:returnToMenuBar()
	self._menubar_item:setClickCallback(function() self:_on_menu_click() end)
	self:_on_screen_changed()
end

function SpaceIdWidget:stopImpl()
    self._menubar_item:removeFromMenuBar()
	self._screen_watcher:stop()
	self._system_watcher:stop()
end

function SpaceIdWidget:unloadImpl()
	self._menubar_item:delete()
	self._menubar_item = nil

	if self._canvas ~= nil then
		self._canvas:hide()
		self._canvas:delete()
		self._canvas = nil
	end

	self._screen_watcher = nil
	self._system_watcher = nil
end


function SpaceIdWidget:_rebuild_canvas()
	if self._canvas ~= nil then
		self._canvas:hide()
		self._canvas:delete()
		self._canvas = nil
	end

	self._curr_space_num = nil

	self._canvas = hs.canvas.new({
		x = 0,
		y = 0,
		w = self._frame_thickness + self._cell_size * #self._spaces_for_screen,
		h = self._frame_thickness + self._cell_size,
	})
	self._canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
	self._canvas:appendElements({
		type = "rectangle",
		action = "fill",
		fillColor = {black = 1, alpha = 0.15},
		roundedRectRadii = {xRadius = 5, yRadius = 5},
	})
	self._canvas:appendElements({
		id = "curr_frame",
		type = "rectangle",
		action = "skip",
		strokeWidth = self._frame_thickness,
		strokeColor = {white = 1, alpha = 0.7},
		roundedRectRadii = {xRadius = 5, yRadius = 5},
	})
    for i = 1, #self._spaces_for_screen do
		self._canvas:appendElements({
			id = "text_" .. i,
			type = "text",
			text = tostring(i),
			textSize = self._font_size,
			textColor = {white = 1, alpha = 0.4},
			frame = {
				x = self._frame_thickness / 2 + (i - 1) * self._cell_size,
				y = self._frame_thickness / 2 + 1,
				w = self._cell_size,
				h = self._cell_size,
			},
			textAlignment = "center",
		})
	end
end

function SpaceIdWidget:_get_menubar_item_actual_frame()
	local f = self._menubar_item:frame()
	local w = self._cell_size * #self._spaces_for_screen
	local h = self._cell_size
	local x0 = f.center.x - w / 2
	local y0 = f.center.y - h / 2
	return hs.geometry.rect(x0, y0, w, h)
end

--@param space_num number
function SpaceIdWidget:_dim_space_num(space_num)
	self._canvas["text_" .. space_num].textColor.alpha = 0.4
end

--@param space_num number
function SpaceIdWidget:_highlight_space_num(space_num)
	self._canvas["text_" .. space_num].textColor.alpha = 1.0
end

function SpaceIdWidget:_hide_frame()
	self._canvas.curr_frame.action = "skip"
end

--@param space_num number
function SpaceIdWidget:_set_frame(space_num)
	self._canvas.curr_frame.frame = {
		x = self._frame_thickness / 2 + (space_num - 1) * self._cell_size,
		y = self._frame_thickness / 2,
		w = self._cell_size,
		h = self._cell_size,
	}
	self._canvas.curr_frame.action = "stroke"
end

--@param space_num number | nil
function SpaceIdWidget:_set_space_num(space_num)
	if self._curr_space_num ~= nil then
		self:_dim_space_num(self._curr_space_num)
	end
	if space_num == nil then
		self:_hide_frame()
	else
		self:_highlight_space_num(space_num)
		self:_set_frame(space_num)
	end
	self._curr_space_num = space_num
	self._menubar_item:setIcon(self._canvas:imageFromCanvas())
	-- local f = self:_get_menubar_item_actual_frame()
	-- self._canvas:topLeft(f.xy)
	-- self._canvas:show()
end

--@param space_num number
function SpaceIdWidget:_goto_space_num(space_num)
	if space_num < 1 or space_num > #self._spaces_for_screen then return end
	if space_num == self._curr_space_num then return end
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, true):post()
	hs.eventtap.event.newKeyEvent(tostring(space_num), true):post()
	hs.eventtap.event.newKeyEvent(tostring(space_num), false):post()
	hs.eventtap.event.newKeyEvent(hs.keycodes.map.ctrl, false):post()
end

function SpaceIdWidget:_on_menu_click()
	local mouse = hs.mouse.absolutePosition()
	local f = self:_get_menubar_item_actual_frame()
	if mouse.x < f.x1 or mouse.x > f.x2 or mouse.y < f.y1 or mouse.y > f.y2 then
		return
	end
	mouse.x = mouse.x - f.x1
	mouse.y = mouse.y - f.y1
	local space_num = math.floor(mouse.x // self._cell_size + 1)
	self:_goto_space_num(space_num)
end

function SpaceIdWidget:_on_space_changed()
	local space_id = hs.spaces.activeSpaceOnScreen()

	for i, v in ipairs(self._spaces_for_screen) do
		if v == space_id then
			self:_set_space_num(i)
			return
		end
	end

	self:_set_space_num(nil)
end

function SpaceIdWidget:_on_screen_changed()
	self._spaces_for_screen = hs.fnutils.filter(
		hs.spaces.spacesForScreen(),
		function(space_id)
			return hs.spaces.spaceType(space_id) == "user"
		end
	)
	self:_rebuild_canvas()
	self:_on_space_changed()
end


return SpaceIdWidget()
