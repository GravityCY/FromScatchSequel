package.path = package.path .. ";/lib/?.lua";
local Graphics = require("gravityio.Graphics");
local tx, ty = Graphics.getSize();

while true do
    local inp = read();
    local command = inp:match("(%S+)%s?");
    local size = tonumber(inp:match("%s(%d+)"));
    Graphics.clear();
    local mx, my = math.floor(tx / 2), math.floor(ty / 2);
    if (command == "outline") then
        print("Drawing outline at ", mx, ", ", my);
        Graphics.drawOutline(mx, my, size, size, 1);
    elseif (command == "box") then
        print("Drawing box at ", mx, ", ", my);
        Graphics.drawBox(mx, my, size, size);
    elseif (command == "circle") then
        print("Drawing circle at ", mx, ", ", my);
        Graphics.drawCircle(mx, my, size);
    elseif (command == "pixel") then
        Graphics.setPixelMode(not Graphics.getPixelMode());
        tx, ty = Graphics.getSize();
        print("Set Pixel Mode to " .. tostring(Graphics.getPixelMode()));
    end
end