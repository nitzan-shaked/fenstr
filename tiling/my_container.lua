local class = require("utils.class")


local EXT_MARGIN = 10
local INT_MARGIN = 10

---@class MyContainer: Class
local MyContainer = class.make_class("MyContainer")


---@param w Window | nil
---@param screen Screen | nil
function MyContainer:__init__(w, screen)

    self._deleted = false

    ---@type Geometry | nil
    self._rect = nil

    ---@type Window | nil
    self._window = nil

    ---@type string | nil
    self._layout_direction = "long_axis"
    ---@type MyContainer[]
    self._children = {}
    ---@type number[]
    self._children_ratios = {}

    self._canvas = hs.canvas.new({x = 0, y = 0, w = 0, h = 0})
    self._canvas:level(hs.canvas.windowLevels.tornOffMenu)
    self._canvas:appendElements({
        id = "rect",
        type = "rectangle",
        action = "stroke",
        strokeColor = {white = 1, alpha = 1},
    })

    if screen then
        self:_set_rect(hs.geometry.rect(
            screen:frame().x + EXT_MARGIN,
            screen:frame().y + EXT_MARGIN,
            screen:frame().w - 2 * EXT_MARGIN,
            screen:frame().h - 2 * EXT_MARGIN
        ))
    end

    if w then
        self:_set_window(w)
    end
end


function MyContainer:delete()
    assert(not self._deleted)
    self._deleted = true
    assert(#self._children == 0)
    self._canvas:hide()
    self._canvas:delete()
    self._w = nil
    self._rect = nil
end


---@param layout_direction string
function MyContainer:set_layout_direction(layout_direction)
    assert(not self._deleted)
    if layout_direction == self._layout_direction then return end
    self._layout_direction = layout_direction
    self:_relayout()
end


---@param new_child MyContainer
function MyContainer:append_child(new_child)
    assert(not self._deleted)

    -- no window and no children
    if self._window == nil and #self._children == 0 then
        if new_child._window then
            self:_set_window(new_child._window)
            new_child:delete()
        else
            assert(#new_child._children >= 2)
            self._children = new_child._children
            self._children_ratios = new_child._children_ratios
            new_child:delete()
            self:_relayout()
        end

        return
    end

    -- existing window (so on children)
    -- => convert window to a container
    if self._window then
        local wrapper_child = MyContainer(self._window)
        self._window = nil
        table.insert(self._children, wrapper_child)
        table.insert(self._children_ratios, 1)
    end

    -- add new child to existing children
    table.insert(self._children, new_child)
    table.insert(self._children_ratios, 0)
    local new_ratio = 1 / #self._children
    for i, _ in ipairs(self._children_ratios) do
        self._children_ratios[i] = new_ratio
    end

    self:_relayout()
end


---@param i_child number
function MyContainer:remove_child(i_child)
    assert(not self._deleted)

    assert(i_child >= 1 and i_child <= #self._children)
    local child = self._children[i_child]
    local child_ratio = self._children_ratios[i_child]

    table.remove(self._children, i_child)
    table.remove(self._children_ratios, i_child)
    child:delete()

    if #self._children >= 2 then
        local delta_ratio_others = child_ratio / #self._children
        for i, _ in ipairs(self._children_ratios) do
            self._children_ratios[i] = self._children_ratios[i] + delta_ratio_others
        end

    elseif #self._children == 1 then
        local only_child = self._children[1]
        self._children = {}
        self._children_ratios = {}

        local only_child_window = only_child._window
        if only_child_window then
            self:_set_window(only_child_window)
        else
            self._children = only_child._children
            self._children_ratios = only_child._children_ratios
        end

        only_child:delete()
    end

    self:_relayout()
end


---@param i_child number
---@param delta_ratio number
function MyContainer:resize_child(i_child, delta_ratio)
    assert(not self._deleted)

    assert(#self._children > 1)
    assert(i_child >= 1 and i_child <= #self._children)
    if delta_ratio == 0 then return end
    local delta_ratio_others = delta_ratio / (#self._children - 1)
    for i, _ in ipairs(self._children_ratios) do
        if i == i_child then
            self._children_ratios[i] = self._children_ratios[i] + delta_ratio
        else
            self._children_ratios[i] = self._children_ratios[i] - delta_ratio_others
        end
    end
    self:_relayout()
end


---@param rect Geometry
function MyContainer:_set_rect(rect)
    assert(not self._deleted)
    if rect == self._rect then return end
    self._rect = rect
    if self._window then
        self._window:setFrame(self._rect)
    end
    self:_relayout()
end


---@param w Window
function MyContainer:_set_window(w)
    assert(not self._deleted)
    assert(self._window == nil)
    assert(#self._children == 0)
    self._window = w
    if self._rect then
        self._window:setFrame(self._rect)
    end
end


function MyContainer:_relayout()
    assert(not self._deleted)

    if self._rect == nil then return end

    if self._layout_direction == "long_axis" then
        if self._rect.w >= self._rect.h then
            self:_layout_children_horizontally()
        else
            self:_layout_children_vertically()
        end

    elseif self._layout_direction == "short_axis" then
        if self._rect.w <= self._rect.h then
            self:_layout_children_horizontally()
        else
            self:_layout_children_vertically()
        end

    elseif self._layout_direction == "horizontal" then
        self:_layout_children_horizontally()

    elseif self._layout_direction == "vertical" then
        self:_layout_children_vertically()

    else
        assert(false, "Not implemented")
    end

    self:_redraw_frame()
end


function MyContainer:_layout_children_horizontally()
    assert(not self._deleted)

    local x = self._rect.x
    local available_width = self._rect.w - (#self._children - 1) * INT_MARGIN
    for i, child in ipairs(self._children) do
        local child_width = math.floor(available_width * self._children_ratios[i])
        child:_set_rect(hs.geometry.rect(x, self._rect.y, child_width, self._rect.h))
        x = x + child_width + INT_MARGIN
    end
end


function MyContainer:_layout_children_vertically()
    assert(not self._deleted)

    local y = self._rect.y
    local available_height = self._rect.h - (#self._children - 1) * INT_MARGIN
    for i, child in ipairs(self._children) do
        local child_height = math.floor(available_height * self._children_ratios[i])
        child:_set_rect(hs.geometry.rect(self._rect.x, y, self._rect.w, child_height))
        y = y + child_height + INT_MARGIN
    end
end


function MyContainer:_redraw_frame()
    assert(not self._deleted)

    self._canvas:frame(self._rect)
    if #self._children == 0 then
        self._canvas:show()
    else
        self._canvas:hide()
    end
end


return MyContainer
