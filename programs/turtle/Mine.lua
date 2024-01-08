package.path = package.path .. ";/lib/?.lua"
local TurtyBoy = require("gravityio.TurtyBoy");

local args = {...};
local forward, right = nil, nil;

local function setup()
    if (args[1] ~= nil) then forward = args[1];
    else
        write("Enter Z (forward): ");
        forward = read()
    end

    if (args[2] ~= nil) then right = args[2];
    else
        write("Enter X (left/right): ");
        right = read()
    end

    forward = tonumber(forward);
    right = tonumber(right);
end

setup();
TurtyBoy.mineArea(forward, right);