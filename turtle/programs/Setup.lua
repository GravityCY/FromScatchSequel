local TurtyBoy = require("TurtyBoy");
local Sides = require("Sides");
local Files = require("Files");
local Helper = require("Helper");

local INPUT_PATH = "input.txt";

local args = {...};

local driveSlot = TurtyBoy.findName("computercraft:disk_drive");

if (driveSlot == nil) then
    print("No drive found");
    return;
end

local items = TurtyBoy.listCB(function(slot, item) return item.name:find("turtle"); end);
for slot, item in pairs(items) do
    TurtyBoy.select(slot);
end