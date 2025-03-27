---@meta "hs.geometry"

---@class Geometry
---@field x number
---@field y number
---@field w number
---@field h number
---@field x1 number
---@field y1 number
---@field x2 number
---@field y2 number
---@field x1y1 Point | Geometry
---@field x2y2 Point | Geometry
---@field topleft Point | Geometry
---@field bottomright Point | Geometry
---@field center Point | Geometry
---@field size Size | Geometry
local Geometry = {}

---@return Geometry
function Geometry.new() end

---@return Geometry
function Geometry:copy() end

---@param other Geometry
---@return boolean
function Geometry:inside(other) end

---@class hs.geometry
---@operator call:Geometry
local module = {}

---@param x number
---@param y number
---@param w number
---@param h number
---@return Geometry
function module.rect(x, y, w, h) end


---@param w number
---@param h number
---@return Geometry
function module.size(w, h) end

return module
