package.path = package.path .. ";/lib/?.lua";

local Logger = require("gravityio.Logger")
.setDebug(true)
.setFormatter(function(level, namespace, message) return ("(%s) (%s) %s: %s"):format(os.date("%H:%M:%S"), level, namespace, message) end);
local fl = Logger.FileLogHandler.new("/logs/storage.log");
local pl = Logger.PrintLogHandler.new();
local lh = Logger.LogHandlerList.new(fl, pl);
Logger.setHandler(lh);

local CMDL = require("gravityio.CMDL");
local Language = require("gravityio.Language");
local Peripheralia = require("gravityio.Peripheralia");
local Inventoreez = require("gravityio.Inventoreez");
local Inventorio = require("gravityio.Inventorio")
local EasyAddress = require("gravityio.EasyAddress");
local Helper = require("gravityio.Helper");
local Pretty = require("cc.pretty");

local NAMESPACE = "storage";
local LOGGER = Logger.new(NAMESPACE);
local ADTR = EasyAddress.new(NAMESPACE);

local storage = Inventoreez.new();
local input = Inventorio.get(ADTR.get("input"));
local internal = ADTR.getMultiple("storage", false);

CMDL.command("add", "storage.commands.add.desc", function()
    Helper.concat(internal, EasyAddress.waitMultiple("storage"));
    ADTR.save();
end);


while true do
    term.clear();
    term.setCursorPos(1, 1);

    Language.write("storage.commands.prompt");
    local inp = read();
    CMDL.input(inp);
end