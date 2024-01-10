local Helper = require("gravityio.Helper");

local Graphics = {};

local _term = term;

local tx, ty = 0, 0;
local tpx, tpy = 0, 0;

local pixelMode = false;
local pixels = {};


local function getLowHigh(a, b)
    if (a < b) then return a, b;
    else return b, a; end
end

--- Sets the background color.
---@param color any
local function setBackgroundColor(color)
    local prev = _term.getBackgroundColor();
    _term.setBackgroundColor(color);
    return prev;
end

local function setTextColor(color)
    local prev = _term.getTextColor();
    _term.setTextColor(color);
    return prev;
end

local function setCursorPos(x, y)
    local px, py = _term.getCursorPos();
    _term.setCursorPos(x, y);
    return px, py;
end

local function getLetter(binary)
    local flip = bit.band(binary, 32) ~= 0;
    binary = bit.band(binary, 31);
    if (flip) then binary = 159 - binary;
    else binary = 128 + binary; end

    return string.char(binary), flip
end

local function getPixel(px, py)
    return pixels[px][py] or false;
end

local function getGrid(x, y)
    local px, py = (x - 1) * 2 + 1, (y - 1) * 3 + 1;
    local num = 0;
    local i = 0;
    for iy = py, py + 2 do
        for ix = px, px + 1 do
            if (pixels[ix][iy]) then
                num = bit.bor(num, 2 ^ i);
            end
            i = i + 1;
        end
    end
    return num;
end

function Graphics.getSize()
    if (pixelMode) then return tpx, tpy;
    else return tx, ty; end
end

function Graphics.clear()
    pixels = Helper._arr(tpx);
    _term.clear();
    _term.setCursorPos(1, 1);
end

function Graphics.setTerm(t)
    _term = t;
    tx, ty = _term.getSize();
    tpx, tpy = tx * 2, ty * 3;

    pixels = Helper._arr(tpx);
end

function Graphics.setPixelMode(on)
    pixelMode = on;
end

function Graphics.getPixelMode()
    return pixelMode;
end

function Graphics.setPixel(px, py, on)
    local x, y = math.ceil(px / 2), math.ceil(py / 3);
    if (getPixel(px, py) == on) then return end
    pixels[px][py] = on;

    local grid = getGrid(x, y);
    local letter, flip = getLetter(grid);

    local tc, bc = _term.getTextColor(), _term.getBackgroundColor();
    local ptc = setTextColor(flip and bc or tc);
    local pbc = setBackgroundColor(flip and tc or bc);
    local pvx, pvy = setCursorPos(x, y);
    _term.write(letter);
    setCursorPos(pvx, pvy);
    setTextColor(ptc);
    setBackgroundColor(pbc);
end

function Graphics.drawPixel(x, y, color)
    if (color == nil) then color = _term.getTextColor(); end

    if (pixelMode) then
        local on = color ~= _term.getBackgroundColor();
        Graphics.setPixel(x, y, on);
    else
        local pb = setBackgroundColor(color);
        local px, py = setCursorPos(x, y);
        _term.write("\160");
        setBackgroundColor(pb);
        setCursorPos(px, py);
    end
end

function Graphics.drawOutline(cx, cy, xs, ys, thickness, color)
    if (thickness == nil or thickness < 1) then thickness = 1; end

    local nx, px = cx - xs, cx + xs;
    local ny, py = cy - ys, cy + ys;

    for ix = nx, px do
        for i = 0, thickness - 1 do
            Graphics.drawPixel(ix, ny - i, color);
            Graphics.drawPixel(ix, py + i, color);
        end
    end

    for iy = ny, py do
        for i = 0, thickness - 1 do
            Graphics.drawPixel(nx - i, iy, color);
            Graphics.drawPixel(px + i, iy, color);
        end
    end
end

function Graphics.drawBox(cx, cy, sx, sy, color)
    local nx, px = cx - sx, cx + sx;
    local ny, py = cy - sy, cy + sy;
    for y = ny, py do
        for x = nx, px do
            Graphics.drawPixel(x, y, color);
        end
    end
end

function Graphics.drawCircle(centerX, centerY, radius, color)
    local scalar = 1.5;
    if (pixelMode) then scalar = 1; end

    for i = 1, 360, 1 do
        local angle = i * math.pi / 180;
        local ptx = math.floor(centerX + (radius * scalar * math.cos(angle)));
        local pty = math.floor(centerY + radius * math.sin(angle));

        Graphics.drawPixel(ptx, pty, color);
    end
end

Graphics.setTerm(term);
return Graphics;