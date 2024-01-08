local Inventorio = require("gravityio.Inventorio");
local Logger = require("gravityio.Logger");
local Helper = require("gravityio.Helper");

local _def = Helper._def;

local Inventoreez = {};
local LOGGER = Logger.new("inventoreez");

function Inventoreez.new()
    ---@class Inventoreez
    local self = {};

    ---@type Inventorio[]
    local all = {};
    local size = 0;
    local itemList = {};

    local function updateItems()
        local start = 1;
        for ind, inv in ipairs(all) do
            local items = inv.getItems();
            for i = 1, inv.getSize() do
                itemList[i + start - 1] = items[i];
            end
            start = start + inv.getSize();
        end
    end

    local function getStart(index)
        local start = 1;
        for i = 1, index - 1 do
            local inv = all[i];
            start = start + inv.getSize();
        end
        return start;
    end

    --- <b>Initializes all inventories</b> <br>
    --- Initializes all the internal inventories, updates the total size, and updates the item list
    function self.init()
        LOGGER.debug("Initializing inventories");
        local fns = {};
        for ind, inv in ipairs(all) do
            table.insert(fns, inv.init);
        end
        Helper.batchExecute(fns);
        size = 0;
        for ind, inv in ipairs(all) do
            size = size + inv.getSize();
        end
        LOGGER.debug("Initialized size:", size);
        updateItems();
    end

    --- <b>Get internal inventory from global slot</b> <br>
    --- Example: `self.getInternal(500)` -> the_inventory at slot 500, the interal slot of the_inventory
    ---@param slot integer
    ---@return Inventorio|nil inv
    ---@return integer|nil slot
    function self.getInternal(slot)
        if (slot < 1 or slot > size) then return; end

        local start = 1;
        for _, inv in ipairs(all) do
            local finish = start + inv.getSize() - 1;
            if (slot >= start and slot <= finish) then
                local ownSlot = slot - start + 1;
                return inv, ownSlot;
            end
            start = finish + 1;
        end
    end

    function self.getExternal(slot, index)
        local start = getStart(index);
        return start + slot - 1;
    end

    function self.getItems()
        return itemList;
    end

    function self.getSize()
        return size;
    end

    function self.getConnected()
        return #all;
    end

    function self.add(addr)
        LOGGER.debug("Adding inventory", addr);
        table.insert(all, Inventorio.get(addr));
    end

    function self.remove(addr)
        LOGGER.debug("Removing inventory", addr);
        local prev = all;
        all = {};
        for ind, inv in ipairs(prev) do
            if (inv.address.full ~= addr) then
                table.insert(all, inv);
            end
        end
    end

    --- <b>Caches all inventories</b> <br>
    --- Caches all the internal inventories, and updates the item lists
    function self.cache()
        local fns = {};
        for ind, inv in ipairs(all) do
            table.insert(fns, inv.cache);
        end
        Helper.batchExecute(fns);
        updateItems();
    end

    function self.getAt(slot)
        return itemList[slot];
    end

    function self.isEmptyAt(slot)
        return self.getAt(slot) == nil;
    end

    --- <b>Finds an empty slot</b>
    ---@param reverse boolean|nil
    ---@return integer|nil
    ---@return Inventorio|nil
    function self.findEmpty(reverse)
        if (reverse == nil) then reverse = true; end

        local it = nil;
        if (reverse) then it = Helper.iterate(size, 1);
        else it = Helper.iterate(1, size); end
        for i in it do
            local inv = all[i];
            local empty = inv.findEmpty();
            if (empty ~= nil) then return empty, inv; end
        end
    end

    function self.swap(slotA, slotB)
        local invA, intSlotA = self.getInternal(slotA);
        local invB, intSlotB = self.getInternal(slotB);
        local aEmpty, bEmpty = invA.isEmptyAt(intSlotA), invB.isEmptyAt(intSlotB);
        if (aEmpty or bEmpty) then
            if (aEmpty) then invB.push(invA, intSlotB, intSlotA);
            else invA.push(invB, intSlotA, intSlotB); end
        else
            local emptySlot, emptyInv = self.findEmpty();
            if (emptySlot == nil) then return false; end
            invA.push(emptyInv, intSlotA, emptySlot);
            invB.push(invA, intSlotB, intSlotA)
            invA.pull(emptyInv, emptySlot, intSlotB);
        end
        return true;
    end

    --- <b>Push items from one inventory to another</b>
    ---@param toAddr string
    ---@param fromSlot integer
    ---@param toSlot integer|nil
    ---@param amount integer|nil
    ---@return integer
    function self.push(toAddr, fromSlot, toSlot, amount)
        local internalInv, internalSlot = self.getInternal(fromSlot);
        if (internalInv == nil or internalSlot == nil) then return 0 end
        local pushed = internalInv.push(toAddr, internalSlot, toSlot, amount);
        itemList[fromSlot] = internalInv.getAt(internalSlot);
        return pushed;
    end

    --- THINK: Make it so that you can not specify toSlot, so that it by default tries to find the first available slot.
    --- <b>Pull items from one inventory to another</b>
    ---@param fromAddr string
    ---@param fromSlot integer
    ---@param toSlot integer
    ---@param amount integer|nil
    ---@return integer
    function self.pull(fromAddr, fromSlot, toSlot, amount)
        local internalInv, internalSlot = self.getInternal(toSlot);
        if (internalInv == nil) then return 0 end
        local pulled = internalInv.pull(fromAddr, fromSlot, internalSlot, amount);
        itemList[toSlot] = internalInv.getAt(toSlot);
        return pulled;
    end

    --- <b>Push items from one inventory to another</b> <br>
    --- Pushes items that the callback function returns true for.
    ---@param toAddr string
    ---@param cb fun(slot: integer, item: table): boolean
    ---@param toSlot integer|nil
    ---@param amount integer|nil
    ---@return boolean
    ---@return integer
    function self.pushCB(toAddr, cb, toSlot, amount)
        amount = _def(amount, 64);

        local pushed = 0;
        for slot, item in pairs(self.getItems()) do
            if (cb(slot, item)) then
                pushed = pushed + self.push(toAddr, slot, toSlot, amount - pushed);
                if (pushed == amount) then return true, pushed; end
            end
        end
        return pushed == amount, pushed;
    end

    --- <b>Push items from one inventory to another</b> <br>
    --- Pushes items by name.
    ---@param toAddr string
    ---@param itemName string
    ---@param toSlot integer|nil
    ---@param amount integer
    function self.pushName(toAddr, itemName, toSlot, amount)
        return self.pushCB(toAddr, Inventorio.getNamePredicate(itemName), toSlot, amount);
    end

    function self.totalCB(cb)
        local total = 0;
        for slot, item in pairs(self.getItems()) do
            if (cb(slot, item)) then
                total = total + item.count;
            end
        end
        return total;
    end

    function self.total()
        return self.totalCB(function() return true; end);
    end

    function self.occupiedCB(cb)
        local count = 0;
        for slot, item in pairs(self.getItems()) do
            if (cb(slot, item)) then
                count = count + 1;
            end
        end
        return count;
    end

    function self.occupied()
        return self.occupiedCB(function() return true; end);
    end

    setmetatable(self, Inventoreez);
    return self;
end

return Inventoreez;