local tb = require("TurtyBoy");
local args = {...};
local x, z = nil, nil;

local function setup()
    if (args[1] ~= nil) then
        x = args[1];
    else
        write("Enter X: ");
        x = read()
    end

    if (args[2] ~= nil) then
        z = args[2];
    else
        write("Enter Z: ");
        z = read()
    end

    x = tonumber(x);
    z = tonumber(z);
end

setup();
tb.mineArea(x, z);