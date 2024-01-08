package.path = package.path .. ";/lib/?.lua";
local Peripheralia = require("gravityio.Peripheralia");
local Logger = require("gravityio.Logger")
.setDebug(true)
.setFormatter(function(level, namespace, message) return ("(%s) (%s) %s: %s"):format(os.date("%H:%M:%S"), level, namespace, message) end);
Logger.setHandler(Logger.FileLogHandler.new("/logs/storage.log"))
local Inventoreez = require("gravityio.Inventoreez");
local Inventorio = require("gravityio.Inventorio")
local AddressTranslations = require("gravityio.AddressTranslations");
local Helper = require("gravityio.Helper");
local Pretty = require("cc.pretty");

local NAMESPACE = "storage";
local LOGGER = Logger.new(NAMESPACE);
local ADTR = AddressTranslations.new(NAMESPACE);

local storage = Inventoreez.new();
-- local input = Inventorio.get(ADTR.get("input"));

local function init()
    for i, p in ipairs(Peripheralia.find("minecraft:chest")) do
        storage.add(p.address.full);
    end
    storage.init();
end

init();

LOGGER.debug("Before")
storage.pushName("minecraft:chest_23", "minecraft:redstone_torch", nil, 64);
LOGGER.debug("After")

-- local items = storage.getItems();
-- LOGGER.debug(items[1].name);
-- LOGGER.debug(items[28].name);
-- LOGGER.debug(("Connected Inventories: %d"):format(storage.getConnected()));
-- LOGGER.debug(("Size: %d"):format(storage.getSize()));
-- LOGGER.debug(("Total Items: %d"):format(storage.total()));
-- LOGGER.debug(("Occupied Slots: %d"):format(storage.occupied()));
-- LOGGER.debug(("Free Slots: %d"):format(storage.getSize() - storage.occupied()));