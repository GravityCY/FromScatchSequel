--- Title: Peripheralia
--- Description: A library for working with peripherals.
--- Version: 0.2.2

local Address = require("Address");
--- A wrapper for CC peripherals.

local Peripharalia = {};

--- <b>Checks if an object is a peripheral.</b>
---@param obj any
---@return boolean
function Peripharalia.isPeripheral(obj)
    if (type(obj) ~= "table") then return false; end
    local meta = getmetatable(obj);
    if (meta == nil) then return false; end
    return meta.__name == "peripheral";
end

--- <b>Checks if an object is an address.</b>
---@param obj any
---@return boolean
function Peripharalia.isAddress(obj)
    return type(obj) == "string" and peripheral.wrap(obj) ~= nil;
end

--- <b>Converts an object to a peripheral.</b>
---@param obj any
---@return any
function Peripharalia.asPeripheral(obj)
    local p = nil;
    if (Peripharalia.isAddress(obj)) then p = peripheral.wrap(obj);
    elseif (Peripharalia.isPeripheral(obj)) then p = obj; end
    return p;
end

--- <b>Converts an object to an address.</b>
---@param obj any
---@return any
function Peripharalia.asAddress(obj)
    local a = nil;
    if (Peripharalia.isAddress(obj)) then a = obj;
    elseif (Peripharalia.isPeripheral(obj)) then a = peripheral.getName(obj); end
    return a;
end

--- <b>Wraps a peripheral.</b> <br>
--- *Modifies the original peripheral.*
---@param periph table
---@return table Wrapper
function Peripharalia.wrap(periph)
    periph.type = peripheral.getType(periph);
    periph.address = Address.new(peripheral.getName(periph));
    return periph;
end

--- <b>Creates a peripheral wrapper.</b>
--- @param periph table
---@return table Wrapper
function Peripharalia.new(periph)
    local self = {};
    self.type = peripheral.getType(periph);
    self.address = Address.new(peripheral.getName(periph));
    self.invoker = periph;
    return self;
end


--- Get a peripheral by address and wraps it.
---@param address string
---@return table|nil Wrapper
function Peripharalia.get(address)
    local original = peripheral.wrap(address);
    if (original == nil) then return nil; end
    return Peripharalia.wrap(original);
end

--- Get the first peripheral of the given type.
---@param type string
---@return table|nil Wrapper
function Peripharalia.first(type)
    local original = peripheral.find(type);
    if (original == nil) then return nil; end
    return Peripharalia.wrap(original);
end

--- Get all peripherals of the given type.
---@param type string
---@return table|nil peripherals A list of wrapped peripherals.
function Peripharalia.find(type)
    local original = {peripheral.find(type)};
    if (#original == 0) then return nil; end
    local wrapped = {};
    for i = 1, #original do
        table.insert(wrapped, Peripharalia.wrap(original[i]));
    end
    return wrapped;
end

return Peripharalia;