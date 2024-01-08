local arg = ...;

local metaList = {};
local metaMap = {};

local function add(key, value)
    metaMap[key] = value;
    table.insert(metaList, {key=key, value=value})
end

local f = fs.open(arg, "r");
while (true) do 
    local line = f.readLine();
    if (line:sub(1, 2) ~= "--") then break end
    line = line:match("-+%s*(.+)")
    local key = line:match("(.+)%s*:");
    local value = line:match(":%s*(.+)")
    add(key, value);
end

for i, v in ipairs(metaList) do
    print(v.key .. ": " .. v.value)
end