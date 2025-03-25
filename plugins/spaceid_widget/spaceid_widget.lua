local Module = require("module")
local class = require("utils.class")

local spaces = require("hs.spaces")
local screen = require("hs.screen")


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
	self:_on_screen_changed()
    self._menubar_item:returnToMenuBar()
end

function SpaceIdWidget:stopImpl()
    self._menubar_item:removeFromMenuBar()
	self._screen_watcher:stop()
	self._system_watcher:stop()
	-- self._canvas:hide()
end

function SpaceIdWidget:unloadImpl()
	self._menubar_item:delete()
	self._menubar_item = nil

	if self._canvas ~= nil then
		-- self._canvas:hide()
		self._canvas:delete()
		self._canvas = nil
	end

	self._screen_watcher = nil
	self._system_watcher = nil
end


function SpaceIdWidget:_rebuild_canvas()
	if self._canvas ~= nil then
		-- self._canvas:hide()
		self._canvas:delete()
		self._canvas = nil
	end

	self._total_width  = self._frame_thickness + self._cell_size * #self._spaces_for_screen
	self._total_height = self._frame_thickness + self._cell_size

	self._curr_space_num = nil

	self._canvas = hs.canvas.new({
		x = 0,
		y = 0,
		w = self._total_width,
		h = self._total_height,
	})
	self._canvas:appendElements({
		type = "rectangle",
		action = "fill",
		fillColor = {black = 1, alpha = 0.2},
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
				y = self._frame_thickness / 2,
				w = self._cell_size,
				h = self._cell_size,
			},
			textAlignment = "center",
		})
	end
	-- self._canvas:level(hs.canvas.windowLevels.overlay)
	-- self._canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
	-- local f = self._primary_screen:fullFrame()
	-- local dy = (self._primary_screen:name() == "Built-in Retina Display") and 7 or 1
    -- self._canvas:topLeft({
	-- 	x = f.x + f.w / 2 - 110 - self._total_width,
	-- 	y = f.y + dy,
	-- })
	-- self._canvas:show()
end

function SpaceIdWidget:_dim_space_num(space_num)
	self._canvas["text_" .. space_num].textColor.alpha = 0.4
end

function SpaceIdWidget:_highlight_space_num(space_num)
	self._canvas["text_" .. space_num].textColor.alpha = 1.0
end

function SpaceIdWidget:_hide_frame()
	self._canvas.curr_frame.action = "skip"
end

function SpaceIdWidget:_set_frame(space_num)
	self._canvas.curr_frame.frame = {
		x = self._frame_thickness / 2 + (space_num - 1) * self._cell_size,
		y = self._frame_thickness / 2,
		w = self._cell_size,
		h = self._cell_size,
	}
	self._canvas.curr_frame.action = "stroke"
end

function SpaceIdWidget:_on_space_changed()
	if self._curr_space_num ~= nil then
		self:_dim_space_num(self._curr_space_num)
	end

	local space_id = spaces.activeSpaceOnScreen()
	if spaces.spaceType(space_id) ~= "user" then
		self._curr_space_num = nil
		self:_hide_frame()
		-- self._canvas:hide()
		self._menubar_item:setIcon(self._canvas:imageFromCanvas())
		return
	end

	-- self._canvas:show()
	for i, v in ipairs(self._spaces_for_screen) do
		if v == space_id then
			self._curr_space_num = i
			self:_highlight_space_num(self._curr_space_num)
			self:_set_frame(self._curr_space_num)
			self._menubar_item:setIcon(self._canvas:imageFromCanvas())
			return
		end
	end

	self._curr_space_num = nil
	self:_hide_frame()
	self._menubar_item:setIcon(self._canvas:imageFromCanvas())
end

function SpaceIdWidget:_on_screen_changed()
	self._primary_screen = screen.primaryScreen()
	self._spaces_for_screen = {}
	for i, v in ipairs(spaces.spacesForScreen()) do
		if spaces.spaceType(v) == "user" then
			table.insert(self._spaces_for_screen, v)
		end
	end
	self:_rebuild_canvas()
	self:_on_space_changed()
end


return SpaceIdWidget()
