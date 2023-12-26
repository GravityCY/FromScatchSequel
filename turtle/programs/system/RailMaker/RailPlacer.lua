local TurtyBoy = require("TurtyBoy");
local Sides = require("Sides");

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

local function findTurtleBox()
    local function isTurtle(slot, item)
        return item.name:find("turtle");
    end

    return findShulkerContents(isTurtle)
end

local function findMaterialBox()
    local function isMaterial(slot, item)
        return item.name:find("rail");
    end

    return findShulkerContents(isMaterial);
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