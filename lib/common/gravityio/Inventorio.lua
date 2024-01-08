--- Title: Inventorio
--- Description: A library for working with inventories.
--- Version: 0.4.3

---@class InventoryPeripheral
---@field list fun():table[]
---@field getItemDetail fun(slot: integer):table
---@field size fun():integer
---@field getItemLimit fun(slot: integer):integer
---@field pushItems fun(addr: string, fromSlot: integer, amount: integer|nil, toSlot: integer|nil):integer
---@field pullItems fun(addr: string, fromSlot: integer, amount: integer|nil, toSlot: integer|nil):integer

local Logger = require("gravityio.Logger");
local Helper = require("gravityio.Helper");
local Peripheralia = require("gravityio.Peripheralia");

local _def = Helper._def;
local _if = Helper._if;
local _gnil = Helper._gnil;

local function instanceof(obj, class)
    return type(obj) == "table" and getmetatable(obj) == class;
end

local function isInventory(obj)
    local _, type = peripheral.getType(obj);
    return type == "inventory";
end

--- Tries to convert any object to a peripheral.
---@param obj any
---@return InventoryPeripheral|nil
local function asInventory(obj)
    if (not isInventory(obj)) then return nil; end
    return Peripheralia.asPeripheral(obj);
end

local LOGGER = Logger.new("inventorio");

local Timer = {}

-- A library for working with inventories.
local Inventorio = {};

---@type Inventorio[]
local inventoryCache = {};

function Timer.start()
    Timer.startTime = os.clock();
end

function Timer.stop()
    return os.clock() - Timer.startTime;
end

--- Moves an item from one list to another
---@param fromItemList table[]|nil
---@param toItemList table[]|nil
---@param fromSlot integer
---@param toSlot integer|nil
---@param moved integer
function Inventorio.moveItem(fromItemList, toItemList, fromSlot, toSlot, moved)
    local fromItem = _gnil(fromItemList, fromSlot);
    local toItem = _gnil(toItemList, toSlot);

    if (fromItemList == nil or fromItem == nil or moved == 0) then
        if (fromItem == nil) then
            LOGGER.debug("Trying to move an empty item.")
        end
        if (fromItemList == nil) then
            LOGGER.debug("From Item List is nil...");
        end
        if (moved == 0) then
            LOGGER.debug("Pushed is 0...");
        end
        return;
    end

    if (toItemList == nil or toSlot == nil) then
        if (fromItem.count == moved) then
            LOGGER.debug(("Moved all of '%s' into an unknown slot."):format(fromItem.name));
            fromItemList[fromSlot] = nil;
        else
            LOGGER.debug(("Moved '%d' of '%s' into an unknown slot."):format(moved, fromItem.name));
            fromItem.count = fromItem.count - moved;
        end
    else
        if (toItem == nil) then
            if (fromItem.count == moved) then
                LOGGER.debug(("Moved all of '%s' into slot '%d'."):format(fromItem.name, toSlot));
                fromItemList[fromSlot] = nil;
                toItemList[toSlot] = fromItem;
            else
                local newItem = Helper.copy(fromItem);
                newItem.count = moved;
                fromItem.count = fromItem.count - moved;
                toItemList[toSlot] = newItem;
                LOGGER.debug(("Moved '%d' of '%s' into slot '%d'."):format(moved, fromItem.name, toSlot));
            end
        else
            fromItem.count = fromItem.count - moved;
            toItem.count = toItem.count + moved;
        end
    end
end

--- <b>An item name predicate</b>
---@param name string
---@return fun(slot: integer, item: table):boolean
function Inventorio.getNamePredicate(name)
    return function(slot, item) return item.name == name; end
end

--- <b>Tries to convert any object to an address.</b> <br>
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
---@return Inventorio|nil
function Inventorio.get(periph)
    local inv = asInventory(periph);
    if (inv == nil) then return; end
    
    Peripheralia.wrap(inv);
    ---@cast inv +Peripheralia

    if (inventoryCache[inv.address.full] ~= nil) then
        return inventoryCache[inv.address.full];
    end

    ---@class Inventorio
    local self = {};
    self.address = inv.address;

    self.itemListCache = {};
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

    ---@param slot integer
    ---@param item table|nil
    local function setAt(slot, item)
        self.itemListCache[slot] = item;
    end

    function self.init()
        self.sizeCache = inv.size();
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
        return self.itemListCache;
    end

    --- <b>Iterates over all items in this inventory using a given callback.</b>
    ---@param cb function Function that receives as arguments, an item object, and a slot number; returns boolean.
    function self.forEach(cb)
        for slot, item in pairs(self.getItems()) do
            if (not cb(slot, item)) then break end
        end
    end

    --- <b>Caches the list of items.</b>
    ---@param detail boolean|nil def: `false` - Whether to cache the items in detail or not.
    function self.cacheItems(detail)
        detail = _def(detail, false);

        if (detail) then
            local fns = {};
            for i = 1, self.sizeCache do
                table.insert(fns, function() self.itemListCache[i] = inv.getItemDetail(i); end);
            end
            parallel.waitForAll(table.unpack(fns));
        else
            local items = inv.list();
            for i = 1, self.sizeCache do
                self.itemListCache[i] = items[i];
            end
        end
    end

    --- <b>Caches information about the inventory.</b>
    ---@param detail boolean|nil def: `false` - Whether to cache the items in detail or not.
    function self.cache(detail)
        self.cacheItems(detail);
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
        toAddr = _def(toAddr, self.address.full);
        toAddr = Inventorio.asAddress(toAddr);
        fromSlot = _def(fromSlot, 1);

        local toInventory = inventoryCache[toAddr];
        local toItemListCache = nil;
        if (toInventory ~= nil) then toItemListCache = toInventory.itemListCache; end
        local pushed = inv.pushItems(toAddr, fromSlot, amount, toSlot);
        Inventorio.moveItem(self.itemListCache, toItemListCache, fromSlot, toSlot, pushed);
        return pushed;
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

        local fromInventory = inventoryCache[fromAddr];
        local fromItemListCache = nil;
        if (fromInventory ~= nil) then fromItemListCache = fromInventory.itemListCache; end
        local pulled = inv.pullItems(fromAddr, fromSlot, amount, toSlot);
        Inventorio.moveItem(fromItemListCache, self.itemListCache, fromSlot, toSlot, pulled);
        return pulled;
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
        return self.pushCB(toAddr, Inventorio.getNamePredicate(itemName), toSlot, amount);
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
            local nonEmpty = _if(emptyA, slotB, slotA);
            local empty = _if(emptyA, slotA, slotB);
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
    ---@return number|nil slot
    function self.findEmpty(reverse)
        reverse = _def(reverse, true);

        local start = _if(reverse, self.sizeCache, 1);
        local finish = _if(reverse, 1, self.sizeCache);

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
        return inv.size() - self.occupied();
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
    inventoryCache[self.address.full] = self;
    return self;
end

return Inventorio;