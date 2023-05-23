--[[ LOGIC ]]

local Cell1D = {}
Cell1D.__index = Cell1D

function Cell1D.new (x1, cell_size)
	local self = {}
	setmetatable(self, Cell1D)
	self.x1 = x1
	self.cell_size = cell_size
	self.x2 = self.x1 + self.cell_size
	return self
end

function Cell1D:edge (which_edge)
	if math.abs(which_edge) ~= 1 then
		error("invalid value ", which_edge, " for 'which_edge'")
	end
	return which_edge == -1 and self.x1 or self.x2
end

function Cell1D:edge_is_close_to (which_edge, x)
	return math.abs(self:edge(which_edge) - x) <= 1
end

function Cell1D:skip (delta_cells)
	return Cell1D.new(
		self.x1 + delta_cells * self.cell_size,
		self.cell_size
	)
end


--[[ MODULE ]]

return Cell1D
