--- Title: Helper
--- Description: A general utility library.
--- Version: 0.4.0

local Helper = {};

local executeLimit = 128;

---Execute a table of functions in batches
---@param func function[]
---@param skipPartial? boolean Only do complete batches and skip the remainder.
---@return function[] skipped Functions that were skipped as they didn't fit.
function Helper.batchExecute(func, skipPartial, limit)
    skipPartial = Helper._def(skipPartial, false);
    limit = Helper._def(limit, executeLimit);

    local batches = #func / limit
    batches = Helper._if(skipPartial, math.floor(batches), math.ceil(batches));

    for batch = 1, batches do
      local start = ((batch - 1) * limit) + 1
      local batch_end = math.min(start + limit - 1, #func)
      parallel.waitForAll(table.unpack(func, start, batch_end))
    end
    return table.pack(table.unpack(func, 1 + limit * batches))
  end

--- <b>Wait for all functions to finish.</b>
---@param tab table List of objects to wait for.
---@param fnGetter function A function receiving objects from the table and returning a function.
function Helper.waitForAllTab(tab, fnGetter)
    local fns = {};
    for _, v in ipairs(tab) do
        table.insert(fns, fnGetter(v));
    end
    parallel.waitForAll(table.unpack(fns));
end

function Helper.waitForAllIt(from, to, fnGetter)
    local fns = {};
    for i = from, to do
        table.insert(fns, fnGetter(i));
    end
    parallel.waitForAll(table.unpack(fns));
end


--- <b>Check if a program is run from shell or from `require`.</b>
---@param args table Arguments passed to the program from `{...}`.
---@return boolean required Whether the program was run from `require`.
function Helper.isRequired(args)
    return #args == 2 and type(package.loaded[args[1]]) == "table" and not next(package.loaded[args[1]]);
end

function Helper.rep(times, fn, ...)
    for i = 1, times do fn(...); end
end

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

--- Returns an iterator that iterates throughout a table.
---@param t table
---@return function
function Helper.ipairs(t)
    return Helper.iterate(1, #t);
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