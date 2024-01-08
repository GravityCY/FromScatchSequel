local Sides = {
    FORWARD = 0, RIGHT = 1, BACK = 2, LEFT = 3, UP = 4, DOWN = 5
};

local sideNames = {
    [0] = "FORWARD", [1] = "RIGHT", [2] = "BACK", [3] = "LEFT", [4] = "UP", [5] = "DOWN"
};

local toPeripheralMap = {
    [Sides.FORWARD] = "front",
    [Sides.RIGHT] = "right";
    [Sides.BACK] = "back",
    [Sides.LEFT] = "left",
    [Sides.UP] = "top",
    [Sides.DOWN] = "bottom"
};

local fromPeripheralMap = {
    ["front"] = Sides.FORWARD,
    ["right"] = Sides.RIGHT,
    ["back"] = Sides.BACK,
    ["left"] = Sides.LEFT,
    ["top"] = Sides.UP,
    ["bottom"] = Sides.DOWN
}

local toVectorMap = {
    [Sides.FORWARD] = vector.new(0, 0, 1),
    [Sides.RIGHT] = vector.new(1, 0, 0),
    [Sides.BACK] = vector.new(0, 0, -1),
    [Sides.LEFT] = vector.new(-1, 0, 0),
    [Sides.UP] = vector.new(0, 1, 0),
    [Sides.DOWN] = vector.new(0, -1, 0)
}

function Sides.fromPeripheralName(name)
    return fromPeripheralMap[name];
end

function Sides.toPeripheralName(index)
    return toPeripheralMap[index];
end

function Sides.toName(index)
    return sideNames[index];
end

function Sides.toEnum(name)
    return Sides[name];
end

function Sides.toVector(side)
    return toVectorMap[side];
end

function Sides.isHorizontal(side)
    return side >= 0 and side <= 3;
end

function Sides.isVertical(side)
    return side >= 4 and side <= 5;
end

--- Will rotate along all of the axis. <br>
--- `FORWARD` -> `RIGHT` -> `BACK` -> `LEFT` -> `UP` -> `DOWN`
---@param sideIndex integer
---@param amount integer
---@return integer
function Sides.rotateAll(sideIndex, amount)
    local new = (sideIndex + amount) % 6;
    return new;
end

--- Will rotate along the Y axis. <br><br>
--- `FRONT` -> `RIGHT` -> `BACK` -> `LEFT.`
--- @param sideIndex integer
--- @param amount integer
--- @return integer
function Sides.rotateUp(sideIndex, amount)
    local new = (sideIndex + amount) % 4;
    return new;
end

return Sides;