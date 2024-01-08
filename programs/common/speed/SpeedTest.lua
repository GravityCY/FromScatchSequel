package.path = package.path .. ";/lib/?.lua";

local BigFont = require("gravityio.BigFont");
local Helper = require("gravityio.Helper");
local Timer = require("gravityio.Timer");
local AddressTranslations = require("gravityio.AddressTranslations");

local FORMAT_0 = "Waiting for first integrator activation...";
local FORMAT_1 = "Waiting for last integrator activation...";
local FORMAT_2 = "You have a speed of";
local FORMAT_3 = "blocks per second.";

local Integrator = {};
local Speaker = {};

function Integrator.new(address)
    local self = {};
    local periph = peripheral.wrap(address);

    --- <b>Compares two input lists.</b>
    ---@param prevInputs table Table of input states
    ---@param newInputs table Table of input states
    ---@return boolean same Whether the inputs are the same
    ---@return string|nil side The side that is different
    ---@return boolean|nil prevState The previous state
    ---@return boolean|nil nowState The current state
    function self.compare(prevInputs, newInputs)
        for side, prevState in pairs(prevInputs) do
            local newState = newInputs[side];
            if (prevState ~= newState) then return false, side, prevState, newState; end
        end
        return true;
    end

    --- <b>Gets the current state of all sides.</b>
    ---@return table
    function self.getInputs()
        local ret = {};
        for _, side in ipairs(periph.getSides()) do
            ret[side] = periph.getInput(side);
        end
        return ret;
    end

    --- <b>Waits for a redstone signal.</b>
    ---@param onlyState boolean|nil Only returns the state that matches the given value
    ---@return string side
    function self.onEvent(onlyState)
        while true do
            local prevOnSides = self.getInputs();
            local _, addr = os.pullEvent("redstone");
            if (addr == address) then
                local nowOnSides = self.getInputs();
                local same, side, prevState, nowState = self.compare(prevOnSides, nowOnSides);
                if (onlyState == nil) then return side;
                elseif (onlyState == nowState) then return side; end
            end
        end
    end
    return self;
end

function Speaker.new(periph)
    if (periph == nil) then
        periph = {}
            
        --- Plays a note block note through the speaker.
        ---  @param instrument string The instrument to use to play this note.
        ---  @param volume number|nil The volume to play the note at, from 0.0 to 3.0. Defaults to 1.0.
        ---  @param pitch number|nil The pitch to play the note at in semitones, from 0 to 24. Defaults to 12.
        ---  @return boolean success Whether the note could be played as the limit was reached.
        function periph.playNote(instrument, volume, pitch)
            return false;
        end
    end
    return periph;
end

local adtr = AddressTranslations.new("speed_test");

local sx, sy = term.getSize();

local speaker = Speaker.new(peripheral.find("speaker"));

local startInteg = Integrator.new(adtr.get("first_integrator"));
local finishInteg = Integrator.new(adtr.get("second_integrator"));

local settings = Helper.loadJSON("/data/speed_test/settings.json");

local function writeAt(x, y, str)
    term.setCursorPos(x, y);
    write(str);
end

if (settings == nil) then
    settings = {};
    write("Enter distance between integrators: ");
    local inp = read();
    settings.distance = tonumber(inp);
    Helper.saveJSON("/data/speed_test/settings.json", settings);
end

while true do

    term.clear();
    writeAt(1, 1, FORMAT_0);

    startInteg.onEvent(true);
    -- On Start
    local startTime = Timer.start();

    term.clear();
    writeAt(1, 1, FORMAT_1);

    speaker.playNote("harp", 1, 5);
    sleep(0.2);
    speaker.playNote("harp", 1, 15);

    finishInteg.onEvent(true);
    -- On Finish
    term.clear();
    local timeDiff = Timer.stop();

    local bps = settings.distance / timeDiff;
    local str = ("%.2f"):format(bps);
    local data = BigFont.getData(str, 2);

    local bx = math.ceil((sx - data.getWidth()) / 2);
    local by = math.ceil((sy - data.getHeight()) / 2) + 1;
    local fx2 = math.ceil((sx - #FORMAT_2) / 2);
    local fx3 = math.ceil((sx - #FORMAT_3) / 2);

    writeAt(fx2, by - 1, FORMAT_2);
    BigFont.writeData(data, bx, by);
    writeAt(fx3, by + data.getHeight() - 1, FORMAT_3);
    writeAt(1, sy, "Press any key to continue");

    speaker.playNote("harp", 1, 15);
    sleep(0.2);
    speaker.playNote("harp", 1, 5);
    
    os.pullEvent("key");
end