local TurtyBoy = require("TurtyBoy");
local Sides = require("Sides");

local function findCb(items, cb)
    for slot, item in pairs(items) do
        if (cb(slot, item)) then return slot, item end
    end
end

local function getShulkerSlots()
    local list = {};
    for slot, item in pairs(TurtyBoy.list()) do
        if (item.name:find("shulker")) then
            list[slot] = item;
        end
    end
    return list;
end

local function findShulkerContents(cb)
    for shulkerSlot in pairs(getShulkerSlots()) do
        local shulkerItem = turtle.getItemDetail(shulkerSlot, true);
        local foundSlot, foundItem = findCb(shulkerItem.items, cb);
        if (foundSlot ~= nil) then
            return shulkerSlot, foundSlot;
        end
    end
end

local shulkerSlot = findShulkerContents(function(slot, item) return item.name:find("turtle") end);
print(shulkerSlot);