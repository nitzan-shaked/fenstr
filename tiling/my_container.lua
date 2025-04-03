local class = require("utils.class")


local EXT_MARGIN = 10
local INT_MARGIN = 10

---@class MyContainer: Class
local MyContainer = class.make_class("MyContainer")


---@type table<number, MyContainer>
local window_id_to_container = {}


---@param screen Screen
---@return MyContainer
function MyContainer.top_level_for_screen(screen)
    local c = MyContainer()
    c:_set_rect(hs.geometry.rect(
        screen:frame().x + EXT_MARGIN,
        screen:frame().y + EXT_MARGIN,
        screen:frame().w - 2 * EXT_MARGIN,
        screen:frame().h - 2 * EXT_MARGIN
    ))
    return c
end


---@param w Window
---@return MyContainer
function MyContainer.new_for_window(w)
    local w_id = w:id()
    assert(not window_id_to_container[w_id])
    local c = MyContainer()
    c:set_window(w)
    return c
end


---@param w Window
---@return MyContainer
function MyContainer.existing_for_window(w)
    return window_id_to_container[w:id()]
end


function MyContainer:__init__()
    ---@type MyContainer | nil
    self._parent = nil

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
end


function MyContainer:delete()
    assert(not self._window)
    assert(#self._children == 0)
    assert(#self._children_ratios == 0)
    self._canvas:hide()
    self._canvas:delete()
    local parent = self._parent
    if not parent then return end
    self._parent = nil
    local i_child = parent:find_child(self)
    assert(i_child)
    parent:remove_child(i_child)
end


---@param w Window
function MyContainer:set_window(w)
    assert(not self._window)
    assert(#self._children == 0)
    assert(#self._children_ratios == 0)

    local w_id = w:id()
    assert(not window_id_to_container[w_id])
    window_id_to_container[w_id] = self
    self._window = w
    if self._rect then
        self._window:setFrame(self._rect)
    end
end


---@return Window
function MyContainer:forget_window()
    local w = self._window
    assert(w)
    assert(#self._children == 0)
    assert(#self._children_ratios == 0)
    local w_id = w:id()
    self._window = nil
    assert(window_id_to_container[w_id])
    window_id_to_container[w_id] = nil
    return w
end


---@param other MyContainer
function MyContainer:grab_window_from(other)
    self:set_window(other:forget_window())
end


---@param other MyContainer
function MyContainer:grab_children_from(other)
    assert(not self._window)
    assert(#self._children == 0)
    assert(#self._children_ratios == 0)
    self._children = other._children
    self._children_ratios = other._children_ratios
    other._children = {}
    other._children_ratios = {}
    for i, child in ipairs(self._children) do
        child._parent = self
    end
end


---@param layout_direction string
function MyContainer:set_layout_direction(layout_direction)
    if layout_direction == self._layout_direction then return end
    self._layout_direction = layout_direction
    self:_relayout()
end


---@param child MyContainer
---@return number | nil
function MyContainer:find_child(child)
    if self._window then
        assert(#self._children == 0)
        assert(#self._children_ratios == 0)
        return nil
    end
    for i, c in ipairs(self._children) do
        if c == child then
            return i
        end
    end
    return nil
end


---@param new_child MyContainer
function MyContainer:append_child(new_child)
    if self._window then
        assert(#self._children == 0)
        assert(#self._children_ratios == 0)
        local wrapper = MyContainer()
        wrapper:grab_window_from(self)
        wrapper._parent = self
        table.insert(self._children, wrapper)
        table.insert(self._children_ratios, 1)
    end

    assert(not self._window)
    assert(#self._children == #self._children_ratios)

    assert(new_child._parent == nil)
    new_child._parent = self
    table.insert(self._children, new_child)
    table.insert(self._children_ratios, 0)

    local new_ratio = 1 / #self._children
    for i = 1, #self._children_ratios do
        self._children_ratios[i] = new_ratio
    end

    self:_relayout()
    self:_redraw()
end


---@param i_child number
function MyContainer:remove_child(i_child)
    assert(not self._window)
    assert(i_child >= 1 and i_child <= #self._children)
    local child_ratio = self._children_ratios[i_child]
    table.remove(self._children, i_child)
    table.remove(self._children_ratios, i_child)

    if #self._children == 0 then
        self:delete()
        return
    end

    if #self._children == 1 then
        -- adopt the child's content
        local only_child = self._children[1]
        self._children = {}
        self._children_ratios = {}
        if only_child._window then
            self:grab_window_from(only_child)
        else
            self:grab_children_from(only_child)
        end
        only_child._parent = nil
        only_child:delete()

    else
        local delta_ratio_others = child_ratio / #self._children
        for i = 1, #self._children_ratios do
            self._children_ratios[i] = self._children_ratios[i] + delta_ratio_others
        end

    end

    self:_relayout()
    self:_redraw()
end


---@param i_child number
---@param delta_ratio number
function MyContainer:resize_child(i_child, delta_ratio)
    assert(not self._window)
    assert(i_child >= 1 and i_child <= #self._children)
    if #self._children == 1 then return end
    if delta_ratio == 0 then return end
    local delta_ratio_others = delta_ratio / (#self._children - 1)
    for i = 1, #self._children_ratios do
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
    if rect == self._rect then return end
    self._rect = rect
    self._canvas:frame(self._rect)
    if self._window then
        assert(#self._children == 0)
        assert(#self._children_ratios == 0)
        self._window:setFrame(self._rect)
    else
        self:_relayout()
    end
    self:_redraw()
end


function MyContainer:_redraw()
    assert(self._rect)
    if #self._children == 0 then
        self._canvas:show()
    else
        self._canvas:hide()
    end
end


function MyContainer:_relayout()
    if #self._children == 0 then return end
    assert(#self._children == #self._children_ratios)
    assert(not self._window)
    assert(self._rect)

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
end


function MyContainer:_layout_children_horizontally()
    if #self._children == 0 then return end
    assert(#self._children == #self._children_ratios)
    assert(not self._window)
    assert(self._rect)
    local x = self._rect.x
    local available_width = self._rect.w - (#self._children - 1) * INT_MARGIN
    for i, child in ipairs(self._children) do
        local child_width = math.floor(available_width * self._children_ratios[i])
        child:_set_rect(hs.geometry.rect(x, self._rect.y, child_width, self._rect.h))
        x = x + child_width + INT_MARGIN
    end
end


function MyContainer:_layout_children_vertically()
    if #self._children == 0 then return end
    assert(#self._children == #self._children_ratios)
    assert(not self._window)
    assert(self._rect)
    local y = self._rect.y
    local available_height = self._rect.h - (#self._children - 1) * INT_MARGIN
    for i, child in ipairs(self._children) do
        local child_height = math.floor(available_height * self._children_ratios[i])
        child:_set_rect(hs.geometry.rect(self._rect.x, y, self._rect.w, child_height))
        y = y + child_height + INT_MARGIN
    end
end


return MyContainer
