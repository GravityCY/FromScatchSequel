--- Title: Helper
--- Description: A general utility library.
--- Version: 0.2.1

local Helper = {};

--- Returns the index of a character in a string.
---@param char string
---@param str string
---@return integer
function Helper.indexOf(char, str)
    for i = 1, #str do
        local tempChar = str:sub(i, i);
        if (tempChar == char) then return i end
    end
    return -1
end

--- Returns the last index of a character in a string.
---@param char string
---@param str string
---@return integer
function Helper.lastIndexOf(char, str)
    for i = #str, 1, -1 do
        local tempChar = str:sub(i, i);
        if (tempChar == char) then return i end
    end
    return -1;
end

--- Iterates from start to finish (works with going from larger to smaller).
---@param start number
---@param finish number
---@return function
function Helper.iterate(start, finish)
    local index = start;

    local up = start < finish;
    local delta = Helper._if(up, 1, -1);
    local endIndex = Helper._if(up, finish + 1, finish - 1);
    return function()
        if (index == endIndex) then return nil; end

        local current = index;
        index = index + 1;
        return current;
    end
end

--- Returns the minimum value.
---@param ... number
---@return number min The minimum value
function Helper.min(...)
    local ret = math.huge;
    for _, v in ipairs({...}) do
        if (v < ret) then ret = v; end
    end
    return ret;
end

--- Returns the maximum value.
---@param ... number
---@return number max The maximum value
function Helper.max(...)
    local ret = -math.huge;
    for _, v in ipairs({...}) do
        if (v > ret) then ret = v; end
    end
    return ret;
end

--- Rounds value down to the nearest multiple of target.
---@param value number 
---@param target number
---@return number
function Helper.roundDown(value, target)
    return value - (value % target);
end

--- Rounds value up to the nearest multiple of target.
---@param value number 
---@param target number
---@return number
function Helper.roundUp(value, target)
    return value + (target - (value % target));
end

--- Rounds value to the nearest multiple of target.
---@param value number
---@param target number
---@return number
function Helper.round(value, target)
    local up = Helper.roundUp(value, target);
    local down = Helper.roundDown(value, target);
    return Helper._if(up - value < value - down, up, down);
end

--- A way to return a default value, if the given value is nil.
---@param value any
---@param defValue any
---@return any
function Helper._def(value, defValue)
    if (value == nil) then return defValue; end
    return value;
end

--- Simplified if else statement.
---@param exp boolean
---@param a any
---@param b any
---@return any
function Helper._if(exp, a, b)
    if (exp) then return a;
    else return b; end
end


return Helper;