--- Title: TurtyBoy
--- Description: A library for working with turtles.
--- Version: 0.4.1

---@diagnostic disable: redundant-parameter

local Helper = require("gravityio.Helper");
local Inventorio = require("gravityio.Inventorio");
local Sides = require("gravityio.Sides");

local _def = Helper._def;
local _if = Helper._if;

local facing = Sides.FORWARD;
local pos = vector.new(0, 0, 0);

local TurtyBoy = {};

local Actions = {
    MOVE=0, MINE=1, PLACE=2, ATTACK=3, TURN=4, SUCK=5, DROP=6, INSPECT=7, COMPARE=8, length=9,
    "MOVE", "MINE", "PLACE", "ATTACK", "TURN", "SUCK", "DROP", "INSPECT", "COMPARE"
};

local baseActions = {
    [Actions.MOVE] = {
        [Sides.FORWARD] = turtle.forward,
        [Sides.BACK] = turtle.back,
        [Sides.UP] = turtle.up,
        [Sides.DOWN] = turtle.down
    },
    [Actions.MINE] = {
        [Sides.FORWARD] = turtle.dig,
        [Sides.UP] = turtle.digUp,
        [Sides.DOWN] = turtle.digDown,
    },
    [Actions.PLACE] = {
        [Sides.FORWARD] = turtle.place,
        [Sides.UP] = turtle.placeUp,
        [Sides.DOWN] = turtle.placeDown,
    },
    [Actions.ATTACK] = {
        [Sides.FORWARD] = turtle.attack,
        [Sides.UP] = turtle.attackUp,
        [Sides.DOWN] = turtle.attackDown,
    },
    [Actions.TURN] = {
        [Sides.RIGHT] = turtle.turnRight,
        [Sides.LEFT] = turtle.turnLeft,
        [Sides.BACK] = function() for i = 1, 2 do turtle.turnRight(); end end
    },
    [Actions.SUCK] = {
        [Sides.FORWARD] = turtle.suck,
        [Sides.UP] = turtle.suckUp,
        [Sides.DOWN] = turtle.suckDown,
    },
    [Actions.DROP] = {
        [Sides.FORWARD] = turtle.drop,
        [Sides.UP] = turtle.dropUp,
        [Sides.DOWN] = turtle.dropDown,
    },
    [Actions.INSPECT] = {
        [Sides.FORWARD] = turtle.inspect,
        [Sides.UP] = turtle.inspectUp,
        [Sides.DOWN] = turtle.inspectDown,
    },
    [Actions.COMPARE] = {
        [Sides.FORWARD] = turtle.compare,
        [Sides.UP] = turtle.compareUp,
        [Sides.DOWN] = turtle.compareDown
    }
}

--- <b>Converts a side to a peripheral</b>
---@param side integer Side Enum
---@return table|nil peripheral Peripheral Object
local function toPeripheral(side)
    local address = Sides.toPeripheralName(side);
    return peripheral.wrap(address);
end

--- <b>Executes an action</b>
---@param action integer Action Enum
---@param side integer Side Enum
---@param ... any Arguments
---@return any
function TurtyBoy.act(action, side, ...)
    side = _def(side, Sides.FORWARD);

    local fn = baseActions[action][side];
    if (fn == nil) then return end
    return fn(...);
end

--- <b>Moves the turtle</b>
---@param side number
---@return boolean success Whether the turtle could successfully move.
---@return string|nil error The reason the turtle could not move.
function TurtyBoy.move(side)
    local success, message = TurtyBoy.act(Actions.MOVE, side);
    if (not success) then return success, message; end
    local facingVec = Sides.toVector(facing);

    if (Sides.isHorizontal(side)) then
        local scale = _if(side == Sides.FORWARD, 1, -1);
        pos.x = pos.x + facingVec.x * scale;
        pos.y = pos.y + facingVec.y * scale;
        pos.z = pos.z + facingVec.z * scale;
    else
        local sideVec = Sides.toVector(side);
        pos.y = pos.y + sideVec.y;
    end
    return success, message;
end

--- <b>Mines a block</b>
---@param side integer
---@return boolean dug Whether a block was broken.
---@return string|nil error The reason no block was broken.
function TurtyBoy.mine(side)
    return TurtyBoy.act(Actions.MINE, side);
end

--- <b>Places an item</b>
---@param slot integer|nil Slot
---@param side integer Side Enum
---@return any
function TurtyBoy.place(side, slot)
    if (slot ~= nil) then turtle.select(slot); end
    return TurtyBoy.act(Actions.PLACE, side);
end

--- <b>Attacks an entity</b>
---@param side integer Side Enum
---@return any
function TurtyBoy.attack(side)
    return TurtyBoy.act(Actions.ATTACK, side);
end

--- <b>Turns the turtle</b>
---@param side integer Side Enum
---@return any
function TurtyBoy.turn(side)
    side = _def(side, Sides.RIGHT);

    return TurtyBoy.act(Actions.TURN, side);
end

--- <b>Faces the turtle</b>
---@param preferred integer Side Enum
function TurtyBoy.face(preferred)
    if (preferred == facing) then return; end

    local distClock = (preferred - facing) % 4;
    local distCClock = (facing - preferred) % 4;
    local turnSide = _if(distClock < distCClock, Sides.RIGHT, Sides.LEFT);
    local turnCount = _if(distClock < distCClock, distClock, distCClock);
    for i = 1, turnCount do TurtyBoy.turn(turnSide); end
    facing = preferred;
end

--- <b>Moves the turtle to the specified position</b>
---@param x integer
---@param y integer
---@param z integer
---@return boolean
function TurtyBoy.go(x, y, z, moveFn)
    if (pos.x == x and pos.y == y and pos.z == z) then return true; end
    moveFn = _def(moveFn, TurtyBoy.move);

    local to = vector.new(x, y, z);

    local dx = x - pos.x;
    local dy = y - pos.y;
    local dz = z - pos.z;

    local ax = math.abs(dx);
    local ay = math.abs(dy);
    local az = math.abs(dz);

    local xDir = _if(dx > 0, Sides.RIGHT, Sides.LEFT);
    local yDir = _if(dy > 0, Sides.UP, Sides.DOWN);
    local zDir = _if(dz > 0, Sides.FORWARD, Sides.BACK);

    -- Forward
    if (az ~= 0) then
        TurtyBoy.face(zDir);
        Helper.rep(az, moveFn, Sides.FORWARD);
    end

    -- Right
    if (ax ~= 0) then
        TurtyBoy.face(xDir);
        Helper.rep(ax, moveFn, Sides.FORWARD);
    end

    -- Up
    if (ay ~= 0) then
        Helper.rep(ay, moveFn, yDir);
    end

    return pos:equals(to);
end

--- <b> Sucks an item </b> <br>
--- @param side integer
--- @return any
function TurtyBoy.suck(side, count)
    return TurtyBoy.act(Actions.SUCK, side, count);
end

--- <b>Sucks an item from the specified slot</b>
---@param side integer def: 
---@param slot integer
---@param amount integer
---@return boolean
function TurtyBoy.suckSlot(side, slot, amount)
    local p = toPeripheral(side);
    if (p == nil) then return false; end

    local inven = Inventorio.new(p);
    inven.init();

    if (inven.isEmptyAt(slot)) then return true; end

    local order = inven.getFillOrder(slot);
    if (order == 1) then
        TurtyBoy.suck(side, amount);
    elseif (order == 2) then
        local firstSlot = inven.getFromFillOrder(1);
        local emptySlot = inven.findEmpty(true);
        if (emptySlot == nil) then return false; end
        inven.swap(firstSlot, emptySlot);
        TurtyBoy.suck(side, amount);
        inven.swap(firstSlot, emptySlot);
    else
        inven.swap(slot, 1);
        TurtyBoy.suck(side, amount);
        inven.swap(slot, 1)
    end
    return true;
end

--- <b>Sucks all items</b> <br>
--- Keeps going until there are no items left to suck.
---@param side any
---@return nil
function TurtyBoy.suckAll(side)
    while true do
        local success, failReason = TurtyBoy.suck(side);
        if (not success) then return failReason end
    end
end

--- <b>Drops an Item</b> <br>
--- Given a side enum drops the currently selected item in that direction.
---@param side number
---@return any
function TurtyBoy.drop(side)
    return TurtyBoy.act(Actions.DROP, side);
end

--- <b>Drops all items</b> <br>
--- Drops all items in the turtles inventory, and returns which slots it dropped.
---@param side number
---@return table slots A table of all the dropped slots.
function TurtyBoy.dropAll(side)
    local slots = {};
    local function drop(slot, item)
        turtle.select(slot);
        TurtyBoy.drop(side);
        table.insert(slots, slot);
        return true;
    end
    TurtyBoy.forEach(drop);
    return slots;
end

--- <b>Inspect an item</b>
---@param side integer
---@return boolean exists Whether there is a block in front of the turtle.
---@return table|string info Information about the block in front, or a message explaining that there is no block.
function TurtyBoy.inspect(side)
    return TurtyBoy.act(Actions.INSPECT, side)
end

--- <b>Compares an Item against block</b>
---@param side integer Side Enum
---@return any 
function TurtyBoy.compare(side)
    return TurtyBoy.act(Actions.COMPARE, side)
end

--- <b>Navigates an area</b> <br>
--- Will go along the x axis then turn, go one forward and go along -x axis then repeat <br>
--- ```
--- S>>>>>>>>>
--- <<<<<<<<<<
--- >>>>>>>>>E
--- ```
---@param dz integer How many times to go forward
---@param dx integer How many times to go left or right (Supports negative numbers)
---@param forward function A function defining how to move forward. Receives 2 optional `integer` arguments, of the current z and x coordinates.
---@return boolean
function TurtyBoy.goArea(dz, dx, forward)
    forward = _def(forward, turtle.forward);

    local ax = math.abs(dx);

    local isForward = true;
    local goRight = dx > 0;
    local rightSide = nil;
    local leftSide = nil;
    if (goRight) then
        rightSide = Sides.RIGHT;
        leftSide = Sides.LEFT;
    else
        rightSide = Sides.LEFT;
        leftSide = Sides.RIGHT;
    end

    local function turn()
        if (isForward) then TurtyBoy.turn(rightSide);
        else TurtyBoy.turn(leftSide); end
    end

    if (forward(0, 0) == false) then return false; end
    for cx = 1, ax do
        for cz = 1, dz - 1 do
            if (forward(cz, cx) == false) then return false; end
        end
        if (cx ~= ax) then
            turn();
            if (forward(dz, cx) == false) then return false; end
            turn();
            isForward = not isForward;
        end
    end
    return true;
end

--- <b>Mines an area</b>
---@param dz integer forward
---@param dx integer right
---@return boolean
function TurtyBoy.mineArea(dz, dx)

    local function forward(z, x)
        TurtyBoy.goMine(Sides.FORWARD);
        TurtyBoy.mine(Sides.UP);
        TurtyBoy.mine(Sides.DOWN);
        return true;
    end

    return TurtyBoy.goArea(dz, dx, forward);
end

--- <b>Ensures a Move, by digging out an obstacle</b> <br>
--- Tries to move and if it can't, will mine the obstacle, and repeats...
---@param side number
function TurtyBoy.goMine(side)
    while true do
        local exists, info = TurtyBoy.inspect(side);
        if (exists) then TurtyBoy.mine(side); end
        if (TurtyBoy.move(side)) then break; end
    end
end

--- <b>Lists all Items in the turtles inventory</b>
---@param detail boolean If true, will return the full item details (takes 50ms)
---@return table
function TurtyBoy.list(detail)
    return TurtyBoy.listCB(detail, function(slot, item) return true; end);
end

--- <b>Lists all Items in the turtles inventory</b> <br>
--- Given a callback function, will only return items that return true from the callback
---@param detail boolean If true, will return the full item details (takes 50ms)
---@param cb function
---@return table
function TurtyBoy.listCB(detail, cb)
    detail = _def(detail, false);

    local items = {};
    if (detail) then
        local fns = {};
        for slot = 1, 16 do
            fns[slot] = function()
                local item = turtle.getItemDetail(slot, true);
                if (item ~= nil and cb(slot, item)) then
                    items[slot] = item;
                end
            end
        end
        parallel.waitForAll(table.unpack(fns));
    else
        for slot = 1, 16 do
            local item = turtle.getItemDetail(slot);
            if (item ~= nil and cb(slot, item)) then
                items[slot] = item;
            end
        end
    end
    return items;
end

--- <b>Selects any non-null Item</b>
---@return boolean
function TurtyBoy.selectAny()
    local slot = TurtyBoy.findAny();
    if (slot == nil) then return false; end
    turtle.select(slot);
    return true;
end

--- <b>Selects an Item by Name</b>
---@param itemName string Name of the item. eg. "minecraft:stick"
---@return boolean success
function TurtyBoy.selectName(itemName)
    local slot = TurtyBoy.findName(itemName);
    if (slot == nil) then return false; end
    turtle.select(slot);
    return true;
end

--- <b>Finds an item by callback</b> <br>
--- Given a function that accepts as arguments, an item object, and a slot number,
--- selects an item that the function returns true
---@param cb function Function that receives as arguments, an item object, and a slot number; returns boolean. 
---@return boolean success
function TurtyBoy.selectCB(cb)
    local slot = TurtyBoy.findCB(cb);
    if (slot == nil) then return false; end
    turtle.select(slot);
    return true;
end

--- <b>Find any non-null item</b>
---@return integer|nil slot The slot of the item
function TurtyBoy.findAny()
    return TurtyBoy.findCB(function(item, slot) return true end);
end

--- <b>Find any item by Name</b>
---@param itemName string Name of the item. eg. "minecraft:stick"
---@return integer|nil slot The slot of the item
function TurtyBoy.findName(itemName)
    return TurtyBoy.findCB(function(item, slot) return item.name == itemName end);
end

--- <b>Find an item by callback</b> <br>
--- Given a function that accepts as arguments, an item object, and a slot number,
--- returns a slot number that the function returns as true.
---@param cb function Function that receives as arguments, an item object, and a slot number; returns boolean.
---@return integer|nil slot
function TurtyBoy.findCB(cb)
    for i = 1, 16 do
        local item = turtle.getItemDetail(i);
        if (item ~= nil and cb(item, i)) then return i; end
    end
end

--- <b> Count all Items</b> <br>
---@return integer count
function TurtyBoy.countAll()
    return TurtyBoy.countCB(function(item) return true end);
end

--- <b> Count an Item by Name</b> <br>
---@param itemName string Name of the item. eg. "minecraft:stick"
---@return integer count
function TurtyBoy.countName(itemName)
    return TurtyBoy.countCB(function(item) return item.name == itemName end);
end

--- <b>Count an Item by callback</b> <br>
--- Given a function that accepts as arguments, an item object, and a slot number,
--- returns a total count of items that return true from the function.
---@param cb function Function that receives as arguments, an item object, and a slot number; returns boolean.
---@return integer count
function TurtyBoy.countCB(cb)
    local count = 0;
    for i = 1, 16 do
        local item = turtle.getItemDetail(i);
        if (item ~= nil and cb(item)) then
            count = count + item.count;
        end
    end
    return count;
end

function TurtyBoy.getFacing()
    return facing;
end

function TurtyBoy.getPos()
    return pos;
end

return TurtyBoy;