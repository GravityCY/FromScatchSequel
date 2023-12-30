--- Title: Inventorio
--- Description: A library for working with inventories.
--- Version: 0.3.2

local Helper = require(".lib.gravityio.Helper");
local Peripheralia = require(".lib.gravityio.Peripheralia");

local _def = Helper._def;
local _fels = Helper._if;

local function instanceof(obj, class)
    return type(obj) == "table" and getmetatable(obj) == class;
end

local function getNamePredicate(name)
    return function(slot, item) return item.name == name; end
end

local Timer = {}

function Timer.start()
    Timer.startTime = os.clock();
end

function Timer.stop()
    return os.clock() - Timer.startTime;
end

-- A library for working with inventories.
local Inventorio = {};

--- <b>Converts an object to an address.</b> <br>
--- Converts an Inventory object to an address. <br>
--- Converts a Peripheral object to an address.
---@param obj any
---@return unknown
function Inventorio.asAddress(obj)
    if (instanceof(obj, Inventorio)) then
        return obj.address.full;
    end
    return Peripheralia.asAddress(obj);
end

--- <b>An Inventory Object</b> <br>
--- WARNING! All items are cached, nothing is live, you must call `cache()` everytime you want to make sure the inventory is up-to-date. <br>
--- *Alternatively, you can call `setAutoCache(true)` which tries to cache the inventory every time you call any function querying the inventory.*
---@param periph string|table The peripheral address or object.
function Inventorio.new(periph)
    periph = Peripheralia.asPeripheral(periph);

    local self = {};
    Peripheralia.wrap(periph);
    self.address = periph.address;

    self.itemMapCache = {};
    self.sizeCache = 0;
    self.occupiedSlotsCache = 0;
    self.freeSlotsCache = 0;

    local autoUpdateCache = false;
    local prevAutoUpdateCache = false;

    local function disableAutoCache()
        if (not autoUpdateCache) then return end
        autoUpdateCache = false;
        prevAutoUpdateCache = true;
    end

    --- <b>Reverts `autoUpdateCache` to the previous state.</b> <br>
    --- When `autoCache()` was run with `disableAutoCache()`, this will revert it back to the previous state before that.
    local function enableAutoCache()
        if (not prevAutoUpdateCache) then return end

        autoUpdateCache = true;
    end

    --- <b>Internal function that caches information about the inventory.</b> <br>
    --- By default will disable `autoUpdateCache` so that no sub calls try to cache. 
    ---@param disable boolean|nil def: `true` - disables `autoUpdateCache`
    local function autoCache(disable)
        if (not autoUpdateCache) then return end

        disable = _def(disable, true);
        self.cache();
        if (disable) then disableAutoCache(); end
    end

    function self.init()
        self.sizeCache = periph.size();
        self.cache();
        return self;
    end

    --- <b>Enables or disables `autoUpdateCache`.</b> <br>
    ---@param enable any
    function self.setAutoCache(enable)
        autoUpdateCache = enable;
        return self;
    end

    --- <b>Gets the size of this inventory.</b> <br>
    --- If `autoCache` is set to true, this method will cache the inventory for faster access.
    ---@return integer
    function self.getSize()
        return self.sizeCache;
    end

    --- <b>Gets a table of all items in this inventory.</b> <br>
    --- If `autoCache` is set to true, this method will cache the inventory for faster access.
    ---@return table
    function self.getItems()
        autoCache(false);
        return self.itemMapCache;
    end

    --- <b>Iterates over all items in this inventory using a given callback.</b>
    ---@param cb function Function that receives as arguments, an item object, and a slot number; returns boolean.
    function self.forEach(cb)
        for slot, item in pairs(self.getItems()) do
            if (not cb(slot, item)) then break end
        end
    end

    --- <b>Caches the list of items.</b>
    function self.cacheItems()
        local fns = {};
        for i = 1, self.sizeCache do
            table.insert(fns, function() self.itemMapCache[i] = periph.getItemDetail(i); end);
        end
        parallel.waitForAll(table.unpack(fns));
    end

    --- <b>Caches information about the inventory.</b>
    function self.cache()
        self.cacheItems();
        self.occupiedSlotsCache = self.occupied();
        self.freeSlotsCache = self.sizeCache - self.occupiedSlotsCache;
    end

    --- <b>Push an item to another inventory.</b>
    ---@param toAddr string|table|nil def: `this.address`— an Address `String` | a `Peripheral` object | an `Inventory` object.
    ---@param fromSlot integer|nil def: `1` — The slot to transfer from
    ---@param toSlot integer|nil def: `1` — The slot to transfer to
    ---@param amount integer|nil def: `64` — The amount of items to transfer
    ---@return integer transferred Amount of items transferred
    function self.push(toAddr, fromSlot, toSlot, amount)
        toAddr = Inventorio.asAddress(_def(toAddr, self.address.full));
        fromSlot = _def(fromSlot, 1);

        return periph.pushItems(toAddr, fromSlot, amount, toSlot);
    end

    --- <b>Pull an item to another inventory.</b>
    ---@param fromAddr string|table|nil def: `this.address`— an Address `String` | a `Peripheral` object | an `Inventory` object.
    ---@param fromSlot integer|nil def: `1` — The slot to transfer from
    ---@param toSlot integer|nil def: `1` — The slot to transfer to
    ---@param amount integer|nil def: `64` — The amount of items to transfer
    ---@return integer transferred Amount of items transferred
    function self.pull(fromAddr, fromSlot, toSlot, amount)
        fromAddr = Inventorio.asAddress(_def(fromAddr, self.address.full));
        fromSlot = _def(fromSlot, 1);

        return periph.pullItems(fromAddr, fromSlot, amount, toSlot);
    end

    --- <b>Pushes items to another inventory using a callback.</b>
    ---@param toAddr string|table def: `this.address`— an Address `String` | a `Peripheral` object | an `Inventory` object.
    ---@param cb function Function that receives as arguments, a slot number, and an item object; returns boolean
    ---@param toSlot integer
    ---@param amount integer
    ---@return boolean success, integer|nil pushed `success` Whether all items were pushed | `pushed` Amount of items pushed
    function self.pushCB(toAddr, cb, toSlot, amount)
        toAddr = Inventorio.asAddress(toAddr);
        amount = _def(amount, 64);

        local pushed = 0;
        autoCache();
        for slot, item in pairs(self.getItems()) do
            if (cb(slot, item)) then
                pushed = pushed + self.push(toAddr, slot, toSlot, amount - pushed);
                if (pushed == amount) then return true, pushed; end
            end
        end
        enableAutoCache();
        return false, pushed;
    end

    --- <b>Push an item to another inventory by name.</b>
    ---@param toAddr string|table def: `this.address`— an Address `String` | a `Peripheral` object | an `Inventory` object.
    ---@param itemName string The name of the item; eg. "minecraft:stick"
    ---@param toSlot integer
    ---@param amount integer
    ---@return boolean success, integer|nil pushed `success` Whether all items were pushed | `pushed` Amount of items pushed
    function self.pushName(toAddr, itemName, toSlot, amount)
        return self.pushCB(toAddr, getNamePredicate(itemName), toSlot, amount);
    end

    --- <b>Swaps two slots.</b> <br>
    --- If one of the slots are empty, the item is pushed to the other slot. <br>
    --- If neither are empty, then tries to swap using a temporary empty slot.
    ---@param slotA integer
    ---@param slotB integer
    ---@return boolean success Whether the swap was successful
    function self.swap(slotA, slotB)
        autoCache();

        local emptyA, emptyB = self.isEmptyAt(slotA), self.isEmptyAt(slotB);
        if (emptyA and emptyB) then return true; end

        if (emptyA or emptyB) then
            local nonEmpty = _fels(emptyA, slotB, slotA);
            local empty = _fels(emptyA, slotA, slotB);
            self.push(nil, nonEmpty, empty);
        else
            local emptySlot = self.findEmpty(true);
            if (emptySlot == nil) then return false; end
            self.push(nil, slotA, emptySlot);
            self.push(nil, slotB, slotA);
            self.push(nil, emptySlot, slotB);
        end

        local items = self.getItems();
        local temp = items[slotA];
        items[slotA] = items[slotB];
        items[slotB] = temp;

        enableAutoCache();
        return true;
    end

    --- <b>Returns the item in the specified slot.</b>
    ---@param slot integer
    ---@return table|nil
    function self.getAt(slot)
        return self.getItems()[slot];
    end

    --- <b>Returns whether the slot is empty.</b>
    ---@param slot integer
    ---@return boolean
    function self.isEmptyAt(slot)
        return self.getAt(slot) == nil;
    end

    --- Returns whether a slot is the lowest slot in the inventory.
    ---@param slot integer
    ---@return boolean
    function self.isLowestSlot(slot)
        autoCache();

        local order = self.getFillOrder(slot);

        enableAutoCache();
        return order == 1;
    end

    --- Returns the fill order of a slot.
    ---@param slot integer
    ---@return integer
    function self.getFillOrder(slot)
        autoCache();

        local fillIndex = 1;
        for i = 1, slot - 1 do
            if (not self.isEmptyAt(i)) then fillIndex = fillIndex + 1; end
        end

        enableAutoCache();
        return fillIndex;
    end

    --- <b>Retrieve the slot index based on the fill order</b>
    --- The fill order represents the position of a slot relative to empty slots. <br>
    --- In the example inventory below: <br>
    --- `[x] [_] [_] [_] [_] [_]` <br>
    --- `[_] [_] [_] [x] [x] [_]` <br>
    --- The item at slot 1 has a fill order of 1, the item at slot 10 has a fill order of 2, and the item at slot 11 has a fill order of 3
    ---@param fillIndex any
    ---@return integer
    function self.getFromFillOrder(fillIndex)
        autoCache();

        local ret = -1;
        local currentIndex = 0;
        for i = 1, self.sizeCache do
            if (not self.isEmptyAt(i)) then currentIndex = currentIndex + 1; end
            if (currentIndex == fillIndex) then ret = i; break end
        end

        enableAutoCache();
        return ret;
    end

    --- <b>Returns the lowest slot in the inventory.</b>
    ---@return integer
    function self.getLowestSlot()
        local lowest = math.huge;
        for slot, item in pairs(self.getItems()) do
            if (slot < lowest) then lowest = slot; end
        end
        return lowest;
    end

    function self.findCB(cb)
        for slot, item in pairs(self.getItems()) do
            if (cb(slot, item)) then
                return slot;
            end
        end
    end

    --- Finds and empty slot in this inventory.
    ---@param reverse boolean|nil Whether to search in reverse. (useful since usually empty slots are at the end)
    ---@return number|nil Slot
    function self.findEmpty(reverse)
        reverse = _def(reverse, true);

        local start = _fels(reverse, self.sizeCache, 1);
        local finish = _fels(reverse, 1, self.sizeCache);

        for i in Helper.iterate(start, finish) do
            if (self.isEmptyAt(i)) then return i; end
        end
    end

    --- <b>The amount of occupied slots in this inventory.</b>
    ---@return integer
    function self.occupied()
        local count = 0;
        for slot, item in pairs(self.getItems()) do
            count = count + 1;
        end
        return count;
    end

    --- <b>The amount of free slots left in this inventory.</b>
    ---@return number
    function self.free()
        return periph.size() - self.occupied();
    end

    --- <b>The amount of total item counts in this inventory.</b>
    ---@return integer
    function self.total()
        return self.totalCB(function(slot, item) return true; end);
    end

    --- <b>The amount of total item counts in this inventory using a given callback</b>
    ---@param cb function Function that receives as arguments, a slot number, and an item object; returns boolean
    ---@return integer
    function self.totalCB(cb)
        local total = 0;
        for slot, item in pairs(self.getItems()) do
            if (cb(slot, item)) then
                total = total + item.count;
            end
        end
        return total;
    end

    setmetatable(self, Inventorio);

    return self;
end

return Inventorio;