local Graphics = {};

local prev;

local function getHighLow(a, b)
    if (a > b) then return a, b;
    else return b, a; end
end

--- Sets the background color.
---@param color any
local function setBackgroundColor(color)
    if (color ~= nil) then
        prev = term.getBackgroundColor();
        term.setBackgroundColor(color);
    else
        term.setBackgroundColor(prev);
        prev = nil;
    end
end

function Graphics.drawBox(x1, x2, y1, y2, color)
    setBackgroundColor(color);

    local px, nx = getHighLow(x1, x2);
    local py, ny = getHighLow(y1, y2);

    for x = nx, px do
        term.setCursorPos(x, y1);
        term.write(" ");
        term.setCursorPos(x, y2);
        term.write(" ");
    end
    for y = ny, py do
        term.setCursorPos(x1, y);
        term.write(" ");
        term.setCursorPos(x2, y);
        term.write(" ");
    end
    
    setBackgroundColor();
end

return Graphics;