local class = require("utils.class")


local EXT_MARGIN = 10
local INT_MARGIN = 10


---@class MyContainer: Class
local MyContainer = class.make_class("MyContainer")


---@param screen Screen | nil
---@param content string
function MyContainer:__init__(screen, content)
    self._screen = screen
    self._is_top_level = (screen ~= nil)

    self._rect = screen and hs.geometry.rect(
        screen:frame().x + EXT_MARGIN,
        screen:frame().y + EXT_MARGIN,
        screen:frame().w - 2 * EXT_MARGIN,
        screen:frame().h - 2 * EXT_MARGIN
    ) or nil

    ---@type string | nil
    self._content = content

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
    self._canvas:appendElements({
        id = "text",
        type = "text",
        action = "skip",
        text = self._content,
        textSize = 16,
        textColor = {red=0, green=0.6, blue = 0.8, alpha = 0.7},
        frame = {x = 0, y = 0, w = "100%", h = "100%"},
        textAlignment = "right",
    })
    self:_redraw()
end


---@param content string | nil
function MyContainer:set_content(content)
    assert(#self._children == 0)
    self._content = content
    self:_redraw()
end


---@param layout_direction string
function MyContainer:set_layout_direction(layout_direction)
    if layout_direction == self._layout_direction then return end
    self._layout_direction = layout_direction
    self:_relayout()
end


---@param new_child MyContainer
function MyContainer:append_child(new_child)
    if self._content ~= nil then
        assert(#self._children == 0)
        local wrapper_child = MyContainer()
        wrapper_child:set_content(self._content)
        self._content = nil
        table.insert(self._children, wrapper_child)
        table.insert(self._children_ratios, 1)
    else
        assert(#self._children >= 2)
    end

    table.insert(self._children, new_child)
    table.insert(self._children_ratios, 0)
    local new_ratio = 1 / #self._children
    for i, _ in ipairs(self._children_ratios) do
        self._children_ratios[i] = new_ratio
    end

    assert(#self._children >= 2)

    self:_relayout()
end


---@param i_child number
function MyContainer:remove_child(i_child)
    assert(i_child >= 1 and i_child <= #self._children)
    local child = self._children[i_child]
    local child_ratio = self._children_ratios[i_child]

    assert(#child._children == 0)
    child:_set_rect(nil)
    child._content = nil

    table.remove(self._children, i_child)
    table.remove(self._children_ratios, i_child)

    if #self._children >= 2 then
        local delta_ratio_others = child_ratio / #self._children
        for i, _ in ipairs(self._children_ratios) do
            self._children_ratios[i] = self._children_ratios[i] + delta_ratio_others
        end

    elseif #self._children == 1 then
        local wrapper_child = self._children[1]
        self._content = wrapper_child._content
        wrapper_child._content = nil
        wrapper_child:_set_rect(nil)
        self._children = {}
        self._children_ratios = {}
    end
    assert(#self._children == 0 or #self._children >= 2)

    self:_relayout()
end


---@param i_child number
---@param delta_ratio number
function MyContainer:resize_child(i_child, delta_ratio)
    assert(#self._children > 1)
    assert(i_child >= 1 and i_child <= #self._children)
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


---@param rect Geometry | nil
function MyContainer:_set_rect(rect)
    assert(not self._is_top_level)
    if rect == self._rect then return end
    if rect == nil then
        self._rect = nil
    else
        self._rect = hs.geometry(rect)
    end
    self:_relayout()
end


function MyContainer:_relayout()
    if self._rect == nil then
        self:_redraw()
        return
    end

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

    self:_redraw()
end


function MyContainer:_layout_children_horizontally()
    local x = self._rect.x
    local available_width = self._rect.w - (#self._children - 1) * INT_MARGIN
    for i, child in ipairs(self._children) do
        local child_width = math.floor(available_width * self._children_ratios[i])
        child:_set_rect(hs.geometry.rect(x, self._rect.y, child_width, self._rect.h))
        x = x + child_width + INT_MARGIN
    end
end


function MyContainer:_layout_children_vertically()
    local y = self._rect.y
    local available_height = self._rect.h - (#self._children - 1) * INT_MARGIN
    for i, child in ipairs(self._children) do
        local child_height = math.floor(available_height * self._children_ratios[i])
        child:_set_rect(hs.geometry.rect(self._rect.x, y, self._rect.w, child_height))
        y = y + child_height + INT_MARGIN
    end
end


function MyContainer:_redraw()
    if self._rect == nil then
        self._canvas:hide()
        return
    end

    self._canvas:frame(self._rect)
    if #self._children == 0 then
        self._canvas:show()
    else
        self._canvas:hide()
    end

    local txt_element = self._canvas["text"]

    if self._content == nil then
        txt_element.text = ""
        txt_element.action = "skip"
    else
        txt_element.text = self._content
        txt_element.action = "stroke"
    end
end


return MyContainer
