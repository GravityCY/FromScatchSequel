local AddressTranslations = {};

local PATH = "data/address_translations/";
local MULTIPLE_FORMAT = "Select one of the following: ";
local WAIT_FORMAT = "Please enable the peripheral '%s'...";
local DESC_FORMAT = "Additional Information is Available: ";
local DESC_FORMAT_1 = "'%s'";
local CONFIRM_FORMAT = "Are you sure you want to set the peripheral '%s' as '%s'? (y/n): ";

function AddressTranslations.pullMultiple(name)
    local ret = {};
    local _, addr = os.pullEvent(name);
    table.insert(ret, addr);
    os.queueEvent("pullMultiple");
    while true do
        local e, a = os.pullEvent();
        if (e == "pullMultiple") then break
        elseif (e == name) then table.insert(ret, a); end
    end
    return ret;
end

--- <b>Loads an address translation table.</b>
---@param namespace string
---@return table
function AddressTranslations.load(namespace)
    local fpath = PATH .. namespace .. ".json";
    if (not fs.exists(fpath)) then return {}; end
    local f = fs.open(fpath, "r");
    local text = f.readAll();
    f.close();
    return textutils.unserialiseJSON(text);
end

--- <b>Saves an address translation table.</b>
---@param namespace string
---@param translations table
function AddressTranslations.save(namespace, translations)
    local fpath = PATH .. namespace .. ".json";
    fs.makeDir(PATH);
    local f = fs.open(fpath, "w");
    f.write(textutils.serialiseJSON(translations));
    f.close();
end

--- <b>Waits for an peripheral to be enabled.</b>
---@param name string
---@param description string|nil
---@return string
function AddressTranslations.wait(name, description)

    --- <b>Before we block the thread, we need to clear the terminal, and print some info.</b>
    local function ui_waiting()
        term.clear();
        term.setCursorPos(1, 1)
        print(WAIT_FORMAT:format(name));
        if (description) then
            print(DESC_FORMAT);
            print(DESC_FORMAT_1:format(description:format(name)));
        end
    end

    --- <b>When we receive the address list of peripherals enabled, we return an address from that list</b>
    ---@param addressList string[]
    ---@return boolean success Whether the user confirmed the address
    ---@return string|nil address The address of the peripheral
    local function ui_received(addressList)
        local addr = addressList[1];
        if (#addressList > 1) then
            write(MULTIPLE_FORMAT);
            local x, y = term.getCursorPos();
            local ey;
            print();
            for i, a in ipairs(addressList) do
                print(i .. ": '" .. a .. "'");
                _, ey = term.getCursorPos();
            end
            term.setCursorPos(x, y);
            local index = tonumber(read());
            term.setCursorPos(1, ey);
            addr = addressList[index];
        end
        print(CONFIRM_FORMAT:format(addr, name));
        local confirm = read():lower();
        if (confirm == "y") then return true, addr; end
        return false;
    end

    while true do
        ui_waiting();
        local addrs = AddressTranslations.pullMultiple("peripheral");
        local success, addr = ui_received(addrs);
        if (success) then return addr; end
    end
end

--- <b>Creates an address translation table.</b>
---@param namespace string
---@return AddressTranslations
function AddressTranslations.new(namespace)
    ---@class AddressTranslations
    local self = {};

    local translations = AddressTranslations.load(namespace);
    local decriptions = {};
    local waitCustomHandler = nil;

    --- <b>Sets the descriptions.</b>
    ---@param descriptions table A lookup table with address keys and description values.
    function self.setDescriptions(descriptions)
        decriptions = descriptions;
    end

    --- <b>Sets a custom handler.</b> <br>
    --- Useful for overriding the UI this library provides for saving a new peripheral.
    ---@param customHandler fun(name: string): string A function that accepts the name and returns the translated address.
    function self.setCustomHandler(customHandler)
        waitCustomHandler = customHandler;
    end

    --- <b>Gets an address translation.</b>
    ---@param name string
    ---@return string address The translated address.
    function self.get(name)
        local ret = translations[name];
        if (ret == nil) then
            if (waitCustomHandler ~= nil) then
                ret = waitCustomHandler(name);
            else
                ret = AddressTranslations.wait(name, decriptions[name]);
            end
            translations[name] = ret;
            AddressTranslations.save(namespace, translations);
        end
        return ret;
    end

    --- <b>Sets an address translation.</b>
    ---@param name string
    ---@param addr string
    function self.set(name, addr)
        translations[name] = addr;
        AddressTranslations.save(namespace, translations);
    end

    return self;
end

return AddressTranslations;