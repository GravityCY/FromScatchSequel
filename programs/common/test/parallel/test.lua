local function a()
    local fns = {};
    print("a");
    for i = 1, 2 do
        table.insert(fns, function() print(i); sleep(0.05) end)
    end
    parallel.waitForAll(table.unpack(fns));
end

local function b()
    local fns = {};
    print("b");
    for i = 3, 4 do
        table.insert(fns, function() print(i); sleep(0.05) end);
    end
    parallel.waitForAll(table.unpack(fns));
end

local function c()
    local fns = {};
    print("c");
    for i = 5, 6 do
        table.insert(fns, function() print(i); sleep(0.05) end);
    end
    parallel.waitForAll(table.unpack(fns));
end

local function d()
    local fns = {};
    print("d");
    for i = 7, 8 do
        table.insert(fns, function() print(i); sleep(0.05) end);
    end
    parallel.waitForAll(table.unpack(fns));
end

local function e()
    local fns = {};
    print("e");
    for i = 9, 10 do
        table.insert(fns, function() print(i); sleep(0.05) end);
    end
    parallel.waitForAll(table.unpack(fns));
end

print(os.clock());
parallel.waitForAll(a, b, c, d, e);
print(os.clock());
