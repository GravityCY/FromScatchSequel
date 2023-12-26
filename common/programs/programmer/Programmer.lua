--- Title: Programmer
--- Description: A program for programming computers.
--- Version: 0.1.0

---@diagnostic disable: need-check-nil

local Path = require("Path");
local Files = require("Files");
local Peripheralia = require("Peripheralia");
local Inventorio = require("Inventorio")

local inventories = Peripheralia.find("minecraft:chest");

local drive = Peripheralia.first("drive");

local input = Inventorio.new(inventories[1]);
local output = Inventorio.new(inventories[2]);

local args = {...};

local txtFilePath = args[1];
local outputDirPath = args[2];

local inputPathList = Files.readLines(txtFilePath);

local function program(slot)
    input.transfer(output, slot, 1);
end

if (inputPathList == nil) then
    print("Text file doesn't exist");
elseif (#inputPathList == 0) then
    print("Text file is empty.");
else
    input.cache();
    for slot, item in pairs(input.getItems()) do
        input.transfer(output, slot, 1);
    end
    Files.copyAll(inputPathList, outputDirPath);
end