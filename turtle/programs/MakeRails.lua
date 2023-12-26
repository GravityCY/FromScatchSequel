local TB = require("TurtyBoy");
local Sides = require("Sides");
local Helper = require("Helper");

local function isNotRail(item)
    return item.name ~= "minecraft:rail" and item.name ~= "minecraft:powered_rail";
end

local function isNotRedstone(item)
    return item.name ~= "minecraft:redstone_block";
end

local function isBlock(item)
    return isNotRail(item) and isNotRedstone(item);
end

local normalRails = TB.countName("minecraft:rail");
local poweredRails = TB.countName("minecraft:powered_rail");
local redstoneBlock = TB.countName("minecraft:redstone_block");
local normalBlocks = TB.countCB(isBlock);

local distPerPoweredRail = 16;
local poweredRailsToPlace = 4;

-- Powered Rails: 16
-- Rails: 64
-- Redstone: 3
-- Blocks: 6
local timesRedstoneBlock = redstoneBlock;
local timesPoweredRail = poweredRails / 4;
local timesRail = normalRails / distPerPoweredRail;
local timesBlocks = normalBlocks / (distPerPoweredRail + poweredRailsToPlace);

local times = math.floor(Helper.min(timesPoweredRail, timesRail, timesRedstoneBlock, timesBlocks));

local redstoneBlockTotal = redstoneBlock;
local poweredRailsTotal = times * poweredRailsToPlace;
local normalRailsTotal = times * distPerPoweredRail;
local normalBlocksTotal = distPerPoweredRail * times + poweredRailsToPlace * times;

local function rail(toPlace)
    TB.selectName(toPlace);
    TB.goMine(Sides.FORWARD);
    TB.mine(Sides.UP);
    if (not TB.compare(Sides.DOWN)) then
        TB.mine(Sides.DOWN);
        if (not TB.place(Sides.DOWN)) then
            TB.move(Sides.DOWN);
            TB.selectCB(isBlock);
            TB.place(Sides.DOWN);
            TB.move(Sides.UP);
            TB.selectName(toPlace);
            TB.place(Sides.DOWN);
        end
    end
end

local function placeRedstone()
    TB.goMine(Sides.FORWARD);
    TB.mine(Sides.UP);
    TB.goMine(Sides.DOWN);
    TB.selectName("minecraft:redstone_block");
    TB.place(Sides.DOWN);
    TB.move(Sides.UP);
    TB.selectName("minecraft:powered_rail");
    TB.place(Sides.DOWN);
end

local function render(index)
    term.clear();
    term.setCursorPos(1, 1);
    
    print("Placing:")
    print(("%d Powered Rails (%d)"):format(poweredRailsToPlace * times));
    print(("%d Normal Rails (%d)"):format(distPerPoweredRail * times));
    print(("%d Blocks (%d)"):format(distPerPoweredRail * times + (poweredRailsToPlace * times)));
    print(("%d Redstone Blocks (%d)"):format(times));
    print(("Progress: %d%%"):format((index / times) * 100))
end

local function main()
    for i = 1, times do
        render(i);

        for j = 1, distPerPoweredRail do
            rail("minecraft:rail");
        end
        placeRedstone();
        for j = 1, poweredRailsToPlace - 1 do
            rail("minecraft:powered_rail");
        end
    end
end

