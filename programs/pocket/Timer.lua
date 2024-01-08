local BigFont = require("BigFont");

local FINISH_FORMAT = "TIMES UP!";
local TIMER_FORMAT = "%.2fs";
local GO_FORMAT = "GO!";

local CLOCK_SOUND = "minecraft:block.lava.pop";
local END_SOUND = "minecraft:block.anvil.land";

local END_SOUND_TIMES = 3;

local MIN_PERCENT = 0.05;
local MIN_CLOCK_TIME = 0.1;
local MAX_CLOCK_TIME = 1;

local speaker = peripheral.find("speaker");
local arg = ...;
local time = nil;

local tx, ty = term.getSize();
local mx, my = math.ceil(tx / 2), math.ceil(ty / 2);

if (arg == nil) then
    write("Enter Time: ");
    time = read()
else time = arg;
end

time = tonumber(time);

local function playDelayed(instrument, volume, pitch, delay)
    speaker.playNote(instrument, volume, pitch)
    sleep(delay);
end

local function playSoundDelayed(sound, volume, pitch, delay)
    speaker.playSound(sound, volume, pitch);
    sleep(delay);
end

local function playStart(delay)
    playDelayed("harp", 1, 1, delay);
end

local function playGo()
    speaker.playNote("harp", 16, 8);
end

local function playClock()
    speaker.playSound(CLOCK_SOUND, 0.25, 0.75);
end

local function playEnd(delay)
    playSoundDelayed(END_SOUND, 0.5, 0.5, delay);
end

local function runIn(fn, s)
    local start = os.clock();
    return function()
        local now = os.clock();
        local elapsed = now - start;
        if (elapsed > s) then
            fn();
            return true;
        else
            return false;
        end
    end
end

local function showDisplay(text)
    local width = #text;
    local x, y = math.ceil(mx - width / 2), my;

    term.clear();
    term.setCursorPos(x, y);
    print(text);
end

local function showBigDisplay(text)
    text = tostring(text);

    term.clear();
    BigFont.writeOn(term, 1, text);
end

for i = 3, 1, -1 do
    showBigDisplay(i);
    playStart(1);
end
showBigDisplay(GO_FORMAT);
playGo();

local function map(value, fromMin, fromMax, toMin, toMax)
    return (value - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin
end


local timeStarted = os.clock();
local delayedFn = runIn(playClock, MAX_CLOCK_TIME);
while true do
    local timeNow = os.clock();
    local timeElapsed = timeNow - timeStarted;
    if (timeElapsed >= time) then break end

    local timeLeft = time - timeElapsed;
    local percentFinished = (timeElapsed / time);
    local tickingDelay = map((math.min(percentFinished, 1.0 - MIN_PERCENT)), 0.0, 1.0 - MIN_PERCENT, MAX_CLOCK_TIME, MIN_CLOCK_TIME);

    if (delayedFn()) then delayedFn = runIn(playClock, tickingDelay) end
    showBigDisplay(TIMER_FORMAT:format(timeLeft));
    sleep(0.05);
end

local function doRepeat(fn, times, ...)
    for i = 1, times do
        fn(...);
    end
end

showDisplay(FINISH_FORMAT);
doRepeat(playEnd, END_SOUND_TIMES, 0.5);
term.clear();
term.setCursorPos(1, 1);