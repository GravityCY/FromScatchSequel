--- Title: Files
--- Description: A library for working with files.
--- Version: 0.1.0

local Path = require("Path");

local Files = {};

--- <b>Copy a file</b> <br>
--- Overwrites existing file
---@param fromPath string
---@param toPath string
---@return boolean
function Files.copy(fromPath, toPath)
    if (not fs.exists(fromPath)) then return false; end
    if (fs.exists(toPath)) then fs.delete(toPath); end
    fs.copy(fromPath, toPath);
    return true;
end

--- <b>Copy all files in a list to a path</b> <br>
--- Example: `Files.copyAll({"path/to/file1", "path/to/file2"}, "path/to/output")` <br>
--- Output: `/path/to/output/file1`, `/path/to/output/file2`
---@param fromList table
---@param toPath string
function Files.copyAll(fromList, toPath)
    for _, path in ipairs(fromList) do
        local fileName = Path.getFile(path);
        local outPath = Path.join(toPath, fileName);
        Files.copy(path, outPath);
    end
end

--- <b>Read lines from a file</b>
---@param pathString string
---@return table|nil
function Files.readLines(pathString)
    if (not fs.exists(pathString)) then return nil; end
    local lines = {};
    local f = fs.open(pathString, "r");
    while true do
        local line = f.readLine();
        if (line == nil) then break end
        table.insert(lines, line);
    end
    return lines;
end

return Files;