local Language = require("gravityio.Language");
local Identifier = require("gravityio.Identifier");
local Helper = require("gravityio.Helper")

local EasyAddress = {};

local NAMESPACE = "easy_address";
local BUILDER = Identifier.Builder.new(NAMESPACE);
local _build = BUILDER.buildString;

local WAIT_KEY = _build("message.wait");
local WAIT_MULTI_KEY = _build("message.wait_multi");
local DESC_KEY = _build("message.desc_info");
local DESC_VALUE_KEY = _build("message.desc_value");
local MULTIPLE_KEY = _build("message.select_multi");
local MULTIPLE_MULTI_KEY = _build("message.do_multi");
local CONFIRM_KEY = _build("message.confirm");
local CONFIRM_MULTI_KEY = _build("message.confirm_multi");

local PATH = "/data/easy_address/";

function EasyAddress.pullMultiple(name)
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
function EasyAddress.load(namespace)
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
function EasyAddress.save(namespace, translations)
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
function EasyAddress.wait(name, description)

    --- <b>Before we block the thread, we need to clear the terminal, and print some info.</b>
    local function ui_waiting()
        term.clear();
        term.setCursorPos(1, 1)
        Language.printKey(WAIT_KEY, name);
        if (description) then
            Language.printKey(DESC_KEY);
            Language.printKey(DESC_VALUE_KEY, description:format(name));
        end
    end

    --- <b>When we receive the address list of peripherals enabled, we return an address from that list</b>
    ---@param addressList string[]
    ---@return boolean success Whether the user confirmed the address
    ---@return string|nil address The address of the peripheral
    local function ui_received(addressList)
        local addr = addressList[1];
        if (#addressList > 1) then
            Language.write(MULTIPLE_KEY);
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
        Language.printKey(CONFIRM_KEY, addr, name);
        local confirm = read():lower();
        if (confirm == "y") then return true, addr; end
        return false;
    end

    while true do
        ui_waiting();
        local addrs = EasyAddress.pullMultiple("peripheral");
        local success, addr = ui_received(addrs);
        if (success) then return addr; end
    end
end

--- <b>Waits for an peripheral to be enabled.</b>
---@param name string
---@param description string|nil
---@return string[]
function EasyAddress.waitMultiple(name, description, prev)
    --- <b>Before we block the thread, we need to clear the terminal, and print some info.</b>
    local function ui_waiting()
        term.clear();
        term.setCursorPos(1, 1)
        Language.printKey(WAIT_MULTI_KEY, name);
        if (description) then
            Language.printKey(DESC_KEY);
            Language.printKey(DESC_VALUE_KEY, description:format(name));
        end
    end

    --- <b>When we receive the address list of peripherals enabled, we return an address from that list</b>
    ---@param addressList string[]
    ---@return string[]|nil address The address of the peripheral
    local function ui_received(addressList)
        if (#addressList > 1) then
            Language.write(MULTIPLE_MULTI_KEY);
            local confirm = read():lower();
            if (confirm == "y") then
                local str = "";
                for i, a in ipairs(addressList) do
                    str = str .. a .. ",";
                end
                Language.printKey(CONFIRM_MULTI_KEY, str, name);
                local confirmMulti = read():lower();
                if (confirmMulti == "y") then return addressList; end
            else
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
                return {addressList[index]};
            end
        else
            Language.printKey(CONFIRM_KEY, addressList[1], name);
            local confirm = read():lower();
            if (confirm == "y") then return {addressList[1]}; end
        end
    end

    local ret = {};

    while true do
        ui_waiting();
        local addrs = EasyAddress.pullMultiple("peripheral");
        local filteredAddrs = ui_received(addrs);
        Helper.concat(ret, filteredAddrs);
        print("Are you done? (y/n): ");
        if (read():lower() == "y") then break; end
    end

    return ret;
end

--- <b>Creates an address translation table.</b>
---@param namespace string
---@return EasyAddress
function EasyAddress.new(namespace)
    ---@class EasyAddress
    local self = {};

    ---@type any[]
    local translations = {};
    local decriptions = {};

    --- <b>Sets the descriptions.</b>
    ---@param descriptions table A lookup table with address keys and description values.
    function self.setDescriptions(descriptions)
        decriptions = descriptions;
    end

    --- <b>Gets an address translation.</b>
    ---@param name string The name of the address
    ---@param request boolean|nil Whether to request for user input if it doesn't exist
    ---@return string address The translated address.
    function self.get(name, request)
        if (request == nil) then request = true; end

        ---@type string
        local ret = translations[name];
        if (request and ret == nil) then
            self.request(name);
            ret = translations[name];
        end
        return ret;
    end

    --- <b>Gets multiple addresses.</b>
    ---@param name string The name of the address
    ---@param request boolean|nil Whether to request for user input if it doesn't exist
    ---@return string[] addresses The translated address.
    function self.getMultiple(name, request)
        if (request == nil) then request = true; end

        local ret = translations[name];
        if (ret == nil) then translations[name] = {}; ret = translations[name]; end
        if (request and #ret == 0) then
            self.requestMultiple(name);
            ret = translations[name];
        end
        return ret;
    end

    --- <b>Requests an address translation from the user.</b> <br>
    --- <b>After the user has entered an address, it will be stored in the translation table.</b>
    ---@param name string
    function self.request(name)
        self.set(name, EasyAddress.wait(name, decriptions[name]));
        self.save();
    end

    --- <b>Requests multiple address translations from the user.</b> <br>
    --- <b>After the user has entered an address, it will be stored in the translation table.</b>
    ---@param name string
    function self.requestMultiple(name)
        translations[name] = EasyAddress.waitMultiple(name, decriptions[name]);
        self.save();
    end

    --- <b>Sets an address translation.</b>
    ---@param name string
    ---@param addr string|string[]|nil
    function self.set(name, addr)
        translations[name] = addr;
        self.save();
    end

    function self.remove(name)
        self.set(name, nil);
    end

    function self.save()
        EasyAddress.save(namespace, translations);
    end

    function self.load()
        translations = EasyAddress.load(namespace);
    end

    self.load();
    return self;
end

return EasyAddress;