local Language = require "gravityio.Language"
local CMDL = {};

---@type table<string, Command>
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

--- <b>Registers a new command.</b>
---@param name string The name of the command
---@param callback fun(...) The callback function
function CMDL.command(name, descKey, callback)
    ---@class Command
    local self = {};

    self.name = name;
    self.descKey = descKey;
    self.callback = callback;

    addCommand(name, self);
end

--- <b>Sends an user input</b>
---@param strInput string
function CMDL.input(strInput)
    local tabInput = toTable(strInput);
    local cmdName = tabInput[1];
    local cmd = getCommand(cmdName);
    if (cmd ~= nil) then
        cmd.callback(unpack(tabInput))
    elseif (unknownCommandCB ~= nil) then
        unknownCommandCB(cmdName);
    end
end

unknownCommandCB = function (cmdName)
    Language.print("cmdl.messages.unknown_command", cmdName);
    for _, cmd in ipairs(CMDL.commands()) do
        print(" - " .. cmd.name .. " - " .. Language.getKey(cmd.descKey));
    end
end

return CMDL;