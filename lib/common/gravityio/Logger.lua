local Helper = require("gravityio.Helper");

local Logger = {};

local LogHandlerList = {};
local PrintLogHandler = {};
local FileLogHandler = {};

function LogHandlerList.new()
    local self = {};
    local handlers = {};

    function self.add(handler)
        table.insert(handlers, handler);
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

function FileLogHandler.new(dest)
    local self = {};

    function self.setPath(path)
        dest = path;
        f = fs.open(dest, "w");
    end

    function self.print(message)
        f.writeLine(message);
        f.flush();
    end

    self.setPath(dest);

    return self;
end

Logger.LogHandlerList = LogHandlerList;
Logger.PrintLogHandler = PrintLogHandler;
Logger.FileLogHandler = FileLogHandler;

local HANDLER = PrintLogHandler.new();
local MESSAGE_FORMATTER = function(level, namespace, message) return ("(%s) %s: %s"):format(level, namespace, message) end;
local IS_DEBUG = false;

function Logger.setHandler(handler)
    HANDLER = handler;
    return Logger;
end

function Logger.setDebug(debug)
    IS_DEBUG = debug;
    return Logger;
end

function Logger.setFormatter(format)
    MESSAGE_FORMATTER = format;
    return Logger;
end

function Logger.new(namespace)
    local self = {};

    local isDebug = IS_DEBUG;

    function self.setDebug(debug)
        isDebug = debug;
    end

    function self.log(level, ...)
        local message = Helper.toString({...});
        if (level == nil) then level = "NORMAL"; end
        HANDLER.print(MESSAGE_FORMATTER(level, namespace, message));
    end

    function self.info(...)
        self.log("INFO", ...);
    end

    function self.debug(...)
        if (not isDebug) then return end
        self.log("DEBUG", ...);
    end

    return self;
end

return Logger;