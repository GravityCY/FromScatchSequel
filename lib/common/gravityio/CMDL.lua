local CMDL = {};

local cmdMap = {};
local unknownCommandCB;

local function toTable(str)
    local ret = {};
    for bite in str:gmatch("%S+") do
        table.insert(ret, bite);
    end
    return ret;
end

local function unpack(tab)
    return table.unpack(tab, 2);
end

local function addCommand(name, command)
    cmdMap[name] = command;
end

local function getCommand(name)
    return cmdMap[name];
end

function CMDL.onUnknownCommand(cb)
    unknownCommandCB = cb;
end

function CMDL.commands()
    local list = {};
    for name, cmd in pairs(cmdMap) do
        table.insert(list, cmd);
    end
    return list;
end

function CMDL.command(name, callback, data)
    local self = {};

    self.name = name;
    self.callback = callback;
    self.data = callback;

    addCommand(name, self);
end

function CMDL.input()
    local strInput = read();
    local tabInput = toTable(strInput);
    local cmdName = tabInput[1];
    local cmd = getCommand(cmdName);
    if (cmd ~= nil) then
        cmd.callback(unpack(tabInput))
    elseif (unknownCommandCB ~= nil) then
        unknownCommandCB(cmdName);
    end
end

return CMDL;