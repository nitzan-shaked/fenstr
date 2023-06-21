
---@class Class
---@field __name__ string
---@field __base__ Class?
---@field __props__ table<string, boolean>
---@field __cls__ Class

-------------------------------------------------------------------------------

---@param cls Class
---@return table
local function __cls_new(cls, ...)
	local obj = {}
	setmetatable(obj, cls)
	obj:__init__(...)
	return obj
end

---@param cls Class
---@return string
local function __cls_tostring(cls)
	return "class " .. cls.__name__
end

-------------------------------------------------------------------------------

---@alias ClassKwargs {base_cls: Class?, props: string[]? }

---@param cls_name string
---@param kwargs ClassKwargs
---@return Class
local function _make_class(cls_name, kwargs)
	local kwargs_base_cls = kwargs.base_cls
	kwargs.base_cls = nil

	local cls = {}
	for k, v in pairs(kwargs_base_cls or {}) do
		cls[k] = v
	end
	cls.__name__ = cls_name
	cls.__base__ = kwargs_base_cls

	cls.__props__ = {}
	for prop_name, _ in pairs((kwargs_base_cls or {}).__props__ or {}) do
		cls.__props__[prop_name] = true
	end

	local kwargs_props = kwargs.props
	kwargs.props = nil
	for _, prop_name in ipairs(kwargs_props or {}) do
		cls.__props__[prop_name] = true
	end

	for kwarg_k, kwarg_v in pairs(kwargs) do
		cls[kwarg_k] = kwarg_v
	end

	setmetatable(cls, {
		__call=__cls_new,
		__tostring=function () return __cls_tostring(cls) end,
	})

	---@param k string
	---@return any
	function cls:__index(k)
		if k == "__cls__" then
			return cls

		elseif cls.__props__[k] then
			local func = cls["get_" .. k]
			if not func then
				error(
					"reading property " .. k
					.. " in class " .. cls_name
					.. " is not implemented"
				)
			end
			return func(self)

		else
			return rawget(cls, k)
		end
	end

	---@param k string
	---@param v any
	function cls:__newindex(k, v)
		if k == "__cls__" then
			error("cannot set " .. cls_name .. ".__cls__")

		elseif cls.__props__[k] then
			local func = cls["set_" .. k]
			if not func then
				error(
					"writing property " .. k
					.. " in class " .. cls_name
					.. " is not implemented"
				)
			end
			func(self, v)

		else
			rawset(self, k, v)
		end
	end

	return cls
end

-------------------------------------------------------------------------------

local Object = _make_class("Object", {})

function Object:__init__()
end

---@return string
function Object:__tostring()
	return self.__cls__.__name__ .. " instance"
end

-------------------------------------------------------------------------------

---@param name string
---@param kwargs ClassKwargs?
local function class(name, kwargs)
	kwargs = kwargs or {}
	kwargs.base_cls = kwargs.base_cls or Object
	return _make_class(name, kwargs)
end

---@param cls1 Class
---@param cls2 Class
---@return boolean
local function is_subclass(cls1, cls2)
	local c = cls1
	while c do
		if c == cls2 then
			return true
		end
		c = c.__base__
	end
	return false
end

---@param obj any
---@param cls Class
---@return boolean
local function is_instance(obj, cls)
	return is_subclass(obj.__cls__, cls)
end

local module = {
	Object=Object,
	is_instance=is_instance,
	is_subclass=is_subclass,
}
local function _module_call(t, ...)
	return class(...)
end
setmetatable(module, {__call=_module_call})

return module
