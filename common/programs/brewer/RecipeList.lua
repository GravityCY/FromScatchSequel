local PotionRecipe = require("PotionRecipe");
local recipes = {};

local function register(recipe)
    table.insert(recipes, recipe);
    return recipe;
end

local StrengthPotion = register(PotionRecipe.builder()
    .input("minecraft:awkward_potion")
    .ingredient("minecraft:blaze_powder")
    .display("Strength Potion")
    .build());

local SpeedPotion = register(PotionRecipe.builder()
    .input("minecraft:awkward_potion")
    .ingredient("minecraft:sugar")
    .display("Speed Potion")
    .build());

local RegenPotion = register(PotionRecipe.builder()
    .input("minecraft:awkward_potion")
    .ingredient("minecraft:ghast_tear")
    .display("Regeneration Potion")
    .build());

local HastePotion = register(PotionRecipe.builder()
    .input("minecraft:awkward_potion")
    .ingredient("minecraft:end_crystal")
    .display("Haste Potion")
    .build());

return recipes;