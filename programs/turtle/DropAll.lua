local TurtyBoy = require("TurtyBoy");
local Sides = require("Sides");
local Completion = require("cc.completion");

local arg = ...;
local path = shell.getRunningProgram();

local function getSuggestionA(shell, index, currentArg, prevArgs)
    return Completion.side(currentArg);
end

local function getSuggestionB(str)
    return Completion.side(str);
end

local function getSide()
    local retSide;
    local tempSide;
    if (arg == nil) then
        write("Enter Side: ");
        tempSide = read(nil, nil, getSuggestionB);
    else tempSide = arg; end
    retSide = Sides.fromPeripheralName(tempSide);
    if (retSide == nil) then return Sides.FORWARD end
    return retSide;
end

local function main()
    local side = getSide();
    TurtyBoy.dropAll(side);
end

shell.setCompletionFunction(path, getSuggestionA);
main();

