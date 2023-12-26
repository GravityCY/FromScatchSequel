local PotionRecipe = {};

function PotionRecipe.new()
    local self = {};
    self.input = nil;
    self.ingredient = nil;
    self.display = "Unknown Potion";

    function self.setInput(inputId)
        self.input = inputId;
    end

    function self.setIngredient(ingredientId)
        self.ingredient = ingredientId;
    end

    function self.setDisplay(display)
        self.display = display;
    end

    return self;
end

function PotionRecipe.builder()
    local self = {};
    self.input = nil;
    self.ingredient = nil;
    self.display = nil;

    function self.input(inputId)
        self.input = inputId;
        return self;
    end

    function self.ingredient(ingredientId)
        self.ingredient = ingredientId;
        return self;
    end

    function self.display(display)
        self.display = display;
        return self;
    end

    function self.build()
        local recipe = PotionRecipe.new();
        recipe.setInput(self.input);
        recipe.setIngredient(self.ingredient);
        recipe.setDisplay(self.display);
        return recipe;
    end

    return self;
end

return PotionRecipe;