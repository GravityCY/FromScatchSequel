local RecipeList = require("RecipeList");
local Basalt = require("basalt");

local monitor = peripheral.find("monitor");
local stands = {peripheral.find("minecraft:brewing_stand")};

--> Now we want to create a base frame, we call the variable "main" - by default everything you create is visible. (you don't need to use :show())
local main = Basalt.addMonitor()
main:setMonitor(monitor);

local box = main:addFlexbox():setWrap("wrap"):setPosition(1, 1):setSize("parent.w", "parent.h");

local button = box:addButton() --> Here we add our first button
button:setPosition(4, 4) -- We want to change the default position of our button
button:setSize(16, 3) -- And the default size.
button:setText("Click me!") --> This method sets the text displayed on our button

local function buttonClick() --> Create a function we want to call when the button gets clicked 
    Basalt.debug("I got clicked!")
end

-- Now we just need to register the function to the button's onClick event handlers, this is how we can achieve that:
button:onClick(buttonClick)

Basalt.autoUpdate() -- As soon as we call basalt.autoUpdate, the event and draw handlers will listen to any incoming events (and draw if necessary)
