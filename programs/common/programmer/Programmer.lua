--- Title: Programmer
--- Description: A program for programming computers.
--- Version: 0.1.0

---@diagnostic disable: need-check-nil

local Path = require("gravityio.Path");
local Files = require("gravityio.Files");
local EasyAddress = require("gravityio.EasyAddress");
local Peripheralia = require("gravityio.Peripheralia");
local Inventorio = require("gravityio.Inventorio")
local Helper = require("gravityio.Helper");

local _def = Helper._def;
local _if = Helper._if;

local Programmer = {};

local args = {...};

local adtr = EasyAddress.new("programmer");

local drive = Peripheralia.first("drive");

local input = Inventorio.get(adtr.get("input")).init();
local output = Inventorio.get(adtr.get("output")).init();

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