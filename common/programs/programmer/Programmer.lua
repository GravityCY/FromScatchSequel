--- Title: Programmer
--- Description: A program for programming computers.
--- Version: 0.1.0

---@diagnostic disable: need-check-nil

local Path = require("Path");
local Files = require("Files");
local Peripheralia = require("Peripheralia");
local Inventorio = require("Inventorio")

local args = {...};

local drive = Peripheralia.first("drive");

local input = Inventorio.new("minecraft:chest_2");
local output = Inventorio.new("minecraft:chest_3");

local txtFilePath = args[1];

local inputPathList = Files.readLines(txtFilePath);

local function program(slot)
    input.push(drive, slot);
    Files.copyAll(inputPathList, drive.getMountPath());
    output.pull(drive, 1);
end

if (inputPathList == nil) then
    print("Text file doesn't exist");
elseif (#inputPathList == 0) then
    print("Text file is empty.");
else
    input.cache();
    for slot, item in pairs(input.getItems()) do
        program(slot);
    end
end