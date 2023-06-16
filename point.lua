local Vector2 = require("vector2")
local class = require("class")

--[[ LOGIC ]]

---@class Point: Vector2
---@field x number
---@field y number
local Point = class("Point", {
    base_cls=Vector2,
    slots={"x", "y"},
})

--[[ MODULE ]]

return Point
