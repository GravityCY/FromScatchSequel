--- Title: Smelter
--- Description: A program for smelting ores.
--- Version: 0.3.1

local Peripheralia = require(".lib.gravityio.Peripheralia");
local Inventorio = require(".lib.gravityio.Inventorio");
local Helper = require(".lib.gravityio.Helper");

local _def = Helper._def;
local _if = Helper._if;

local Integrator = {};
local Furnace = {};

local Timer = {}

function Timer.start()
    Timer.startTime = os.clock();
end

function Timer.stop()
    return os.clock() - Timer.startTime;
end

--- <b>Creates an integrator.</b> <br>
--- Creates an integrator from the given address,
--- and stores it's main activation side
---@param addr string
---@param side string `"top"` or `"bottom"` etc.
---@return table
function Integrator.new(addr, side)
    local self = {};
    local periph = Peripheralia.get(addr);
    function self.enable()
        periph.setOutput(side, true);
    end
    function self.disable()
        periph.setOutput(side, false);
    end
    return self
end

--- <b>Wraps a furnace.</b>
---@param self table
---@return table
function Furnace.wrap(self)
    self.materialSlot = 1;
    self.fuelSlot = 2;
    self.outputSlot = 3;

    function self.getMaterial()
        return self.getAt(self.materialSlot);
    end
    function self.getFuelItem()
        return self.getAt(self.fuelSlot);
    end
    function self.getOutput()
        return self.getAt(self.outputSlot);
    end
    return self;
end

--- <b>Creates an array of furnaces.</b>
---@param tab any
---@return table
local function FurnaceArray(tab)
    local self = {};
    for index, periph in ipairs(tab) do
        self[index] = Furnace.wrap(Inventorio.new(periph));
    end

    function self.init()
        local fns = {};

        for index, furnace in ipairs(self) do
            table.insert(fns, furnace.init);
        end

        Helper.batchExecute(fns, nil, 16);
    end

    function self.cache()
        local fns = {};

        for index, furnace in ipairs(self) do
            table.insert(fns, furnace.cache);
        end

        Helper.batchExecute(fns, nil, 16);
    end

    return self;
end

local stats = {
    timesLightsLooped = 0,
    smelted = {},
};

--- <b>How often the lights thread runs in seconds.</b>
local lightSleep = 0.1;

local speaker = Peripheralia.first("speaker");

local input = Inventorio.new("minecraft:barrel_4");
local output = Inventorio.new("minecraft:barrel_7");
local fuel = Inventorio.new("minecraft:barrel_1");

local normalFurnaces = FurnaceArray(Peripheralia.find("minecraft:furnace"));
local blastFurnaces = FurnaceArray(Peripheralia.find("minecraft:blast_furnace"));
local smokerFurnaces = FurnaceArray(Peripheralia.find("minecraft:smoker"));

local totalFurnaces = #normalFurnaces + #blastFurnaces + #smokerFurnaces;

local blastFurnaceItems = {
    "minecraft:raw_copper",
    "minecraft:raw_iron",
    "minecraft:raw_gold",
    "minecraft:nether_gold_ore",
    "minecraft:ancient_debris",
};

local smokerFurnaceItems = {
    "minecraft:rabbit",
    "minecraft:mutton",
    "minecraft:beef",
    "minecraft:chicken",
    "minecraft:porkchop",
    "minecraft:cod",
    "minecraft:potato",
    "minecraft:salmon",
    "minecraft:kelp",
};

local integrators = {
    Integrator.new("redstone_integrator_17", "south"),
    Integrator.new("redstone_integrator_18", "top"),
    Integrator.new("redstone_integrator_19", "top"),
    Integrator.new("redstone_integrator_13", "top"),
    Integrator.new("redstone_integrator_12", "top"),

    Integrator.new("redstone_integrator_11", "north"),
    Integrator.new("redstone_integrator_10", "north"),

    Integrator.new("redstone_integrator_9", "bottom"),
    Integrator.new("redstone_integrator_8", "bottom"),
    Integrator.new("redstone_integrator_14", "bottom"),
    Integrator.new("redstone_integrator_15", "bottom"),

    Integrator.new("redstone_integrator_16", "south"),
}

--- <b>Returns a predicate that matches the given item name.</b>
---@param name string
---@return function
local function getNamePredicate(name)
    return function(itemName) return itemName == name; end
end

--- <b>Returns the index of the first item in the table that matches the given function.</b>
---@param tab any
---@param fn any
---@return integer|nil
local function getIndex(tab, fn)
    for i, v in ipairs(tab) do
        if (fn(v)) then return i end
    end
end

--- <b>Returns whether the item name is a blast furnace item.</b>
---@param name string
---@return boolean
local function isBlastFurnaceItem(name)
    return getIndex(blastFurnaceItems, getNamePredicate(name)) ~= nil;
end

--- <b>Returns whether the item name is a smoker item.</b>
---@param name string
---@return boolean
local function isSmokerItem(name)
    return getIndex(smokerFurnaceItems, getNamePredicate(name)) ~= nil;
end

--- <b>Returns whether the item name is a furnace item.</b>
---@param name string
---@return boolean
local function isFurnaceItem(name)
    return not isBlastFurnaceItem(name) and not isSmokerItem(name);
end

--- <b>Returns the furnace array for the given item name.</b>
---@param itemName string
---@return table|nil furnaceArray
local function getArray(itemName)
    if (isBlastFurnaceItem(itemName)) then return blastFurnaces;
    elseif (isSmokerItem(itemName)) then return smokerFurnaces;
    else return normalFurnaces; end
end

--- <b>Initializes all inventories.</b>
local function init()
    parallel.waitForAll(input.init, fuel.init, normalFurnaces.init, blastFurnaces.init, smokerFurnaces.init);
end

--- <b>Caches all important inventories.</b>
local function cache()
    parallel.waitForAll(input.cache, fuel.cache, normalFurnaces.cache, blastFurnaces.cache, smokerFurnaces.cache);
end

--- Turns the lights on or off.
---@param on boolean
local function setLightBar(on)
    for _, integrator in ipairs(integrators) do
        local fn = _if(on, integrator.enable, integrator.disable);
        fn();
    end
end

--- Fills the light bar by a percentage.
---@param percent number - 0.0 to 1.0.
local function fillLightBar(percent)
    local total = math.ceil(#integrators * percent);
    for i = 1, total do
        integrators[i].enable();
    end
    for i = total + 1, #integrators do
        integrators[i].disable();
    end
end

--- Returns the furnace with the lowest amount of the given item
---@param name string
---@return table|nil furnace
local function getAvailableFurnace(name)
    local lowest = math.huge;
    local lowestFurnace = nil;
    local furnaceArray = getArray(name);
    for _, furnace in ipairs(furnaceArray) do
        local item = furnace.getMaterial();
        if (item == nil) then
            return furnace;
        else
            if (item.name == name and item.count < lowest) then
                lowest = item.count;
                lowestFurnace = furnace;
            end
        end
    end
    return lowestFurnace;
end

local function getOnFurnaces()
    local on = 0;
    for _, furnaceArray in ipairs({normalFurnaces, blastFurnaces, smokerFurnaces}) do
        for _, furnace in ipairs(furnaceArray) do
            if (furnace.getMaterial() ~= nil) then
                on = on + 1;
            end
        end
    end
    return on;
end

local function getItemCounts()
    local ret = {};
    for slot, item in pairs(input.getItems()) do
        ret[item.name] = (ret[item.name] or 0) + item.count;
    end
    return ret;
end

local function doInput()
    for itemName, count in pairs(getItemCounts()) do
        local times = math.floor(count / 8);
        for i = 1, times do
            local furnace = getAvailableFurnace(itemName);
            if (furnace ~= nil) then
                if (fuel.pushName(furnace, "minecraft:coal", furnace.fuelSlot, 1)) then
                    input.pushName(furnace, itemName, furnace.materialSlot, 8);
                    cache();
                end
            end
        end
    end
    cache();
end

--- Get or Make a table
---@param tab table
---@param key string
---@return table
local function _gmk(tab, key)
    tab[key] = _def(tab[key], {});
    return tab[key];
end

local function doOutput()
    local fns = {};
    local furnaceArrays = {normalFurnaces, blastFurnaces, smokerFurnaces};
    for _, furnaceArray in ipairs(furnaceArrays) do
        for _, furnace in ipairs(furnaceArray) do
            local furnaceOut = furnace.getOutput();
            if (furnaceOut ~= nil) then
                table.insert(fns, function()
                    local pushed = furnace.push(output, furnace.outputSlot);
                    stats.smelted[furnaceOut.name] = _def(stats.smelted[furnaceOut.name], 0) + pushedt;
                end)
            end
        end
    end
    parallel.waitForAll(table.unpack(fns));
end

local function lightsThread()
    local prevOn = 0;
    while true do
        local onFurnaces = getOnFurnaces();

        if (onFurnaces == 0 and prevOn ~= 0) then
            speaker.playNote("harp", 1, 8);
            sleep(0.5);
            speaker.playNote("harp", 1, 4);
        elseif (onFurnaces ~= 0 and prevOn == 0) then
            speaker.playNote("bit", 1, 8);
            sleep(0.25);
            speaker.playNote("bit", 1, 16);
        end

        if (onFurnaces == 0) then
            for index, integrator in ipairs(integrators) do
                integrator.enable()
                sleep(lightSleep);
                integrator.disable();
            end
            stats.timedLightsLooped = _def(stats.timedLightsLooped, 0) + 1;
        else
            fillLightBar(onFurnaces / totalFurnaces);
            sleep(1);
        end
        prevOn = onFurnaces;
    end
end

local function mainThread()
    init();
    while true do
        doInput();
        doOutput();
        sleep(1);
    end
end

parallel.waitForAll(lightsThread, mainThread);