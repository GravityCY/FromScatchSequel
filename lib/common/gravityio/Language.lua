local Helper = require("gravityio.Helper");
local Path = require("gravityio.Path");
local Identifier = require("gravityio.Identifier")

-- TODO: Redesign so that Language is a Global Instance, that anyone can access, without needing to create a language instance per user

local PATH = "/data/language/";

local Language = {};

local current = "en";

---@type Language[]
local cache = {};

function Language.getLanguages(namespace)
    local translationList = {};
    local path = Path.join(PATH, namespace);
    if (not fs.exists(path)) then return translationList; end

    for _, file in ipairs(fs.list(path)) do
        local name = Path.getFileName(file);
        table.insert(translationList, name);
    end
    return translationList;
end

function Language.loadAll(namespace)
    local translationMap = {};
    local translationList = Language.getLanguages(namespace);
    if (translationList == nil) then return translationMap; end

    for _, name in ipairs(translationList) do
        translationMap[name] = Language.load(name);
    end
    return translationMap;
end

function Language.load(namespace, lang)
    local path = Path.join(PATH, namespace, lang .. ".json");
    if (not fs.exists(path)) then return {}; end
    return Helper.loadJSON(path);
end

function Language.save(namespace, translations, lang)
    local path = Path.join(PATH, namespace, lang .. ".json");
    Helper.saveJSON(path, translations);
end

function Language.setLanguage(lang)
    current = lang;
    for id, namespace in pairs(cache) do
        namespace.setLanguage(current);
    end
end

function Language.getKey(key, ...)
    local namespace = Identifier.getNamespace(key);
    local path = Identifier.getPath(key);
    return Language.get(namespace, path, ...);
end

function Language.get(namespace, path, ...)
    return Language.getInstance(namespace).get(path, ...);
end

function Language.getInstance(namespace)
    if (cache[namespace] ~= nil) then return cache[namespace]; end

    ---@class Language
    local self = {};

    local namespaceMap = {};
    ---@type table<string, string>
    local currentLangageMap = {};
    local languageList = Language.getLanguages(namespace);

    function self.getLanguage(lang)
        return namespaceMap[lang];
    end

    function self.isLoaded(lang)
        return self.getLanguage(lang) ~= nil;
    end

    function self.isValid(lang)
        for _, name in ipairs(languageList) do
            if (name == lang) then return true; end
        end
        return false;
    end

    function self.setLanguage(lang)
        if (not self.isValid(lang)) then return false; end

        if (not self.isLoaded(lang)) then self.load(lang); end
        currentLangageMap = self.getLanguage(lang);
        return true;
    end

    function self.list()
        return languageList;
    end

    function self.load(lang)
        namespaceMap[lang] = Language.load(namespace, lang);
    end

    function self.loadAll()
        namespaceMap = Language.loadAll(namespace);
    end

    function self.get(name, ...)
        if (currentLangageMap == nil or currentLangageMap[name] == nil) then return name; end
        return currentLangageMap[name]:format(...);
    end

    self.setLanguage("en");
    cache[namespace] = self;
    return self;
end

function Language.print(key, ...)
    print(Language.getKey(key, ...));
end

function Language.write(key, ...)
    write(Language.getKey(key, ...));
end

return Language