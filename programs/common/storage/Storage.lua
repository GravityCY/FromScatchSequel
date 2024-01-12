package.path = package.path .. ";/lib/?.lua";

local Logger = require("gravityio.Logger")
.setFormatter(
    function(level, namespace, message, ...)
        return ("(%s) (%s) %s: %s"):format(os.date("%H:%M:%S"), level, namespace, message:format(...));
    end
);
local fl = Logger.FileLogHandler.new("/logs/storage.log", true);
Logger.setHandler(fl);

local CMDL = require("gravityio.CMDL");
local Language = require("gravityio.Language");
local Peripheralia = require("gravityio.Peripheralia");
local Inventoreez = require("gravityio.Inventoreez");
local Inventorio = require("gravityio.Inventorio")
local EasyAddress = require("gravityio.EasyAddress");
local Helper = require("gravityio.Helper");
local NAMESPACE = "storage";

local LOGGER = Logger.get(NAMESPACE);
local ADTR = EasyAddress.new(NAMESPACE);

Logger.setDebugTo(NAMESPACE, true);
Logger.setDebugTo("inventoreez", true);

local settings = {
    language = "en",
    history = {}
};

local storage = Inventoreez.new();
local input = Inventorio.get(ADTR.get("input"));
local internal = ADTR.getMultiple("storage", false);

local function save()
    Helper.saveJSON("/data/storage/settings.json", settings);
end

local function setLanguage(lang)
    LOGGER.debug("Set new language to %s", lang);
    settings.language = lang;
    Language.setLanguage(lang);
    save();
end

local function setup()
    local temp = Helper.loadJSON("/data/storage/settings.json");
    if (temp ~= nil) then
        LOGGER.debug("Loaded settings");
        settings = temp;
        settings.language = settings.language or "en";
        settings.history = settings.history or {};
    end
    Language.setLanguage(settings.language);
end

local function main()
    term.clear();
    term.setCursorPos(1, 1);
    while true do
        Language.write("storage:commands.prompt");
        local inp = read(nil, settings.history);
        term.clear();
        term.setCursorPos(1, 1);
        CMDL.input(inp);
        table.insert(settings.history, inp);
        save();
    end
end

CMDL.command("storage", "storage:command.storage.desc", function()
    LOGGER.debug("storage");
end);

CMDL.command("interface", "storage:command.interface.desc", function()
    LOGGER.debug("interface");

end);

CMDL.command("importer", "storage:command.importer.desc", function()
    LOGGER.debug("importer");
 
end);

CMDL.command("exporter", "storage:command.exporter.desc", function()
    LOGGER.debug("exporter");

end);

CMDL.command("language", "storage:command.language.desc", function(lang)
    LOGGER.debug("language");

    if (lang == nil) then
        Language.writeKey("storage:messages.enter_language");
        lang = read();
    end

    if (Language.isValid(lang)) then
        Language.printKey("storage:command.language.success", lang);
    else
        while true do
            Language.printKey("storage:command.language.incomplete", lang);
            Language.writeKey("storage:messages.continue");
            local inp = read():lower();
            if (inp == "n") then return
            elseif (inp == "y") then break end
        end
    end
    setLanguage(lang);
end);

setup();
main();