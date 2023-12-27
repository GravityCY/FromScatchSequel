--- Title: Programmer
--- Description: A program for programming computers.
--- Version: 0.1.0

---@diagnostic disable: need-check-nil

local Path = require(".lib.gravityio.Path");
local Files = require(".lib.gravityio.Files");
local Peripheralia = require(".lib.gravityio.Peripheralia");
local Inventorio = require(".lib.gravityio.Inventorio")
local Helper = require(".lib.gravityio.Helper");

local _def = Helper._def;
local _if = Helper._if;

local Programmer = {};

local args = {...};

local drive = Peripheralia.first("drive");

local input = Inventorio.new("minecraft:chest_2");
local output = Inventorio.new("minecraft:chest_3");

function Programmer.programCustom(slot, item, customFn)
    input.push(drive, slot);
    customFn(slot, item, drive.getMountPath());
    output.pull(drive, 1);
end

function Programmer.start(fn)
    input.cache();
    for slot, item in pairs(input.getItems()) do
        Programmer.programCustom(slot, item, fn);
    end
end

if (Helper.isRequired(args)) then
    return Programmer;
else
    -- Main
    local txtFilePath = args[1];
    local inputPathList = Files.readLines(txtFilePath);

    local function default(slot, drivePath)
        Files.copyAll(inputPathList, drivePath);
    end

    if (inputPathList == nil) then print("Text file doesn't exist!");
    elseif (#inputPathList == 0) then print("Text file is empty!");
    else Programmer.start(Programmer.default); end
end