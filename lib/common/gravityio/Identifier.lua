local Identifier = {};

function Identifier.new(namespace, path)
    local self = {};

    local function _new1(_namespace, _path)
        self.namespace = _namespace;
        self.path = _path;
        self.key = self.namespace .. ":" .. self.path;
    end

    local function _new2(_key)
        local _namespace, _path = Identifier.getNamespace(_key), Identifier.getPath(_key);
        _new1(_namespace, _path);
    end

    if (namespace ~= nil and path ~= nil) then
        _new1(namespace, path);
    elseif (namespace ~= nil and path == nil) then
        _new2(namespace);
    end

    --- <b>Returns true if the identifier is equal to the key</b>
    ---@param key string
    ---@return boolean
    function self.is(key)
        return self.key == key;
    end

    --- <b>Returns true if the identifier is equal to the other identifier</b>
    ---@param other any
    ---@return boolean
    function self.equals(other)
        if (getmetatable(other) ~= Identifier) then return false; end
        return self.key == other.key;
    end

    setmetatable(self, Identifier);
    return self;
end

--- <b>Returns the namespace of the identifier.</b>
---@param key string
---@return string
function Identifier.getNamespace(key)
    return key:match("(.+):")
end

--- <b>Returns the path of the identifier.</b>
---@param key string
---@return string
function Identifier.getPath(key)
    return key:match(":(.+)")
end

return Identifier;