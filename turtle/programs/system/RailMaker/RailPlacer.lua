local TurtyBoy = require(".lib.gravityio.TurtyBoy");
local Sides = require(".lib.gravityio.Sides");

local function findCb(items, cb)
    for slot, item in pairs(items) do
        if (cb(slot, item)) then return slot, item end
    end
end

local function findShulkerContents(cb)
    for slot, item in pairs(TurtyBoy.list()) do
        if (item.name:find("shulker")) then
            local shulkerSlot = slot;
            local shulkerItem = turtle.getItemDetail(slot, true);

            local foundSlot, foundItem = findCb(shulkerItem.items, cb)
            if (foundSlot ~= nil) then
                return shulkerSlot, foundSlot
            end
        end
    end
end

local function getFind(str)
    return function(slot, item) return item.name:find(str) end
end

local function findTurtleBox()
    return findShulkerContents(getFind("turtle"))
end

local function findMaterialBox()
    return findShulkerContents(getFind("rail"));
end

local turtleSlot = findTurtleBox();
local materialSlot = findMaterialBox();

local function start()

end

local function stop()

end

local function setup()

end

setup();