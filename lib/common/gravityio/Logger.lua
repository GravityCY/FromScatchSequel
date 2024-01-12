local Files = require("gravityio.Files")
local Path = require("gravityio.Path")
local Helper = require("gravityio.Helper");

local Logger = {};

local cache = {};

local LogHandlerList = {};
local PrintLogHandler = {};
local FileLogHandler = {};

function LogHandlerList.new(...)
    local self = {};
    local handlers = {...};

    function self.add(...)
        for _, handler in ipairs({...}) do
            table.insert(handlers, handler);
        end
        return self;
    end

    function self.print(message)
        for _, handler in ipairs(handlers) do
            handler.print(message);
        end
    end
    return self;
end

function PrintLogHandler.new()
    local self = {};

    function self.print(message)
        print(message);
    end

    return self;
end

function FileLogHandler.new(dest, keepOld)
    local self = {};
    local f = nil;

    --- <b>Sets the path of the log file</b>
    ---@param path string
    function self.setPath(path)
        dest = path;
        if (f ~= nil) then f.close(); end
        f = fs.open(dest, "w");
        return self;
    end

    function self.print(message)
        if (f == nil) then return end

        f.writeLine(message);
        f.flush();
    end

    if (keepOld and fs.exists(dest)) then
        local path = Path.getFilePath(dest);
        local name = Path.getFileName(dest);
        local ext = Path.getFileExtension(dest);
        local date = os.date("%d-%m-%Y");
        local new = Path.join(path, date.."-"..name.."{-%d}."..ext);
        Files.rename(dest, new);
    end

    self.setPath(dest);
    return self;
end

Logger.LogHandlerList = LogHandlerList;
Logger.PrintLogHandler = PrintLogHandler;
Logger.FileLogHandler = FileLogHandler;

local HANDLER = PrintLogHandler.new();
local MESSAGE_FORMATTER = function(level, namespace, message, ...)
    return ("(%s) %s: %s"):format(level, namespace, message:format(...));
end;
local IS_DEBUG = false;

function Logger.setHandler(handler)
    HANDLER = handler;
    return Logger;
end

function Logger.setDebug(debug)
    IS_DEBUG = debug;
    return Logger;
end

function Logger.setDebugTo(namespace, debug)
    if (cache[namespace] ~= nil) then cache[namespace].setDebug(debug); end
    return Logger;
end

function Logger.setFormatter(format)
    MESSAGE_FORMATTER = format;
    return Logger;
end

function Logger.get(namespace)
    if (cache[namespace] ~= nil) then return cache[namespace]; end

    local self = {};

    local isDebug = IS_DEBUG;

    function self.setDebug(debug)
        isDebug = debug;
        return self;
    end

    function self.log(level, message, ...)
        if (level == nil) then level = "NORMAL"; end
        HANDLER.print(MESSAGE_FORMATTER(level, namespace, message, ...));
    end

    function self.info(message, ...)
        self.log("INFO", message, ...);
    end

    function self.debug(message, ...)
        if (not isDebug) then return end
        self.log("DEBUG", message, ...);
    end

    cache[namespace] = self;
    return self;
end

return Logger;