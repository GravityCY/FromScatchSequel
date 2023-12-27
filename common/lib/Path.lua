--- Title: Path
--- Description: A library for working with paths.
--- Version: 0.2.0

local Helper = require(".lib.gravityio.Helper");

local _def = Helper._def;
local _if = Helper._if;

local Path = {};

local function instanceof(obj, class)
    return type(obj) == "table" and getmetatable(obj) == class;
end

--- <b>Clean a path string.</b> <br>
--- Examples: `"hello/there/"` → `"hello/there"`.
---@param str string
---@return string
local function clean(str)
    local ret = str:gsub("\\", "/"):gsub("/+", "/");
    local slash = ret:sub(-1) == "/";
    if (slash) then ret = ret:sub(1, -2); end
    return ret;
end

--- <b>Join two or more paths.</b> <br>
--- Examples: `"hello, there, world.txt"` → `"hello/there/world.txt"`.
---@param topPath string
---@param ... string
---@return string
function Path.join(topPath, ...)
    local subPaths = {...};
    local ret = clean(topPath);
    for _, subPath in ipairs(subPaths) do
        ret = clean(ret .. "/" .. clean(subPath));
    end
    return ret;
end

--- <b>Get the name of a path w/ extension</b> <br>
--- Examples: `"hello/there.txt"` → `"there.txt"`.
---@param path any
---@return string
function Path.getFile(path)
    return Path.getFileName(path) .. Path.getFileExtension(path);
end

--- <b>Get the name of a path.</b> <br>
--- Examples: `"hello/there.txt"` → `"there"`.
---@param path string
---@return string
function Path.getFileName(path)
    local i = Helper.lastIndexOf("/", path);
    local ret = _if(i == -1, path, path:sub(i + 1));

    local j = Helper.lastIndexOf(".", ret);
    return _if(j == -1, ret, ret:sub(1, j - 1));
end

--- <b>Get the file extension of a path.</b> <br>
--- Examples: `"hello/there.txt"` → `"txt"`.
---@param path string
---@return string
function Path.getFileExtension(path)
    local i = Helper.lastIndexOf(".", path);
    return _if(i == -1, nil, path:sub(i));
end

--- <b>Get the file path of a path.</b> <br>
--- Examples: `"hello/there.txt"` → `"hello/"`.
---@param path string
---@return string
function Path.getFilePath(path)
    local i = Helper.lastIndexOf("/", path);
    return _if(i == -1, "/", path:sub(1, i));
end

--- <b>Get the absolute path of a path.</b> <br>
--- Examples: `"hello/there.txt"` → `"disk/something/hello/there.txt"`.
---@param path any
---@return unknown
function Path.getAbsolutePath(path)
    return shell.resolve(path);
end

function Path.new(path)
    local self = {};

    local absolutePath;
    local fileName;
    local fileExtension;
    local filePath;

    local exists;
    local file;

    local function setup()
        absolutePath = Path.getAbsolutePath(path);
        fileName = Path.getFileName(absolutePath);
        fileExtension = Path.getFileExtension(absolutePath);
        filePath = Path.getFilePath(absolutePath);

        exists = fs.exists(absolutePath);
        file = not fs.isDir(absolutePath);
    end

    --- <b>Get the absolute path of the path.</b>
    ---@return string
    function self.getAbsolutePath()
        return absolutePath;
    end

    --- <b>Get the path of the path.</b>
    ---@return any
    function self.getPath()
        return path;
    end

    --- <b>Get the name of the path.</b> <br>
    --- Examples: `"hello/there.txt"` → `"there"`.
    ---@return unknown
    function self.getFileName()
        return fileName;
    end

    --- <b>Get the file extension of the path.</b> <br>
    --- Examples: `"hello/there.txt"` → `"txt"`.
    ---@return string
    function self.getFileExtension()
        return fileExtension;
    end

    --- <b>Get the file path of the path.</b> <br>
    --- Examples: `"hello/there.txt"` → `"hello/"`.
    ---@return string
    function self.getFilePath()
        return filePath;
    end

    --- <b>Check if the path exists.</b>
    ---@return boolean
    function self.exists()
        return exists;
    end

    --- <b>Check if the path is a file.</b>
    ---@return boolean
    function self.isFile()
        return file;
    end

    --- <b>Join the path with another path.</b>
    ---@param joinPath string
    ---@return table self
    function self.join(joinPath)
        return Path.new(absolutePath .. "/" .. joinPath);
    end

    function self.equals(obj)
        return instanceof(obj, Path) and obj.getPath() == self.getPath();
    end

    setmetatable(self, Path);
    setup();
    return self;
end

return Path;