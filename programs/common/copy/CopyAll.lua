local Path = require("Path");
local Files = require("Files");

local args = {...};

local txtFilePath = args[1];
local outputDirPath = args[2];

local inputPathList = Files.readLines(txtFilePath);

if (inputPathList == nil) then
    print("Text file doesn't exist");
elseif (#inputPathList == 0) then
    print("Text file is empty.");
else
    Files.copyAll(inputPathList, outputDirPath);
end