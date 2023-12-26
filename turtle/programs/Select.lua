local arg = ...;

local input = nil;
if (arg == nil) then
    write("Enter a Slot: ");
    input = read();
else input = arg; end

local slot = tonumber(input);
if (slot == nil) then
    print("Enter a number!");
    return;
end

if (slot < 1 or slot > 16) then
    print("Enter a slot between 1 - 16!");
    return;
end

turtle.select(slot);