local extendedTurtle = require("extendedTurtle")
local blacklist = {}

-- Helper Functions

local function has_value(table, value)
    for index, otherValue in ipairs(table) do
        if otherValue == value then
            return true
        end
    end

    return false;
end


-- returns if it was found and the slot (0 if not found)
local function findItem(targetName)
    for i = 1, 16 do      
        local item = turtle.getItemDetail(i)

        if item ~= nil then
            if item["name"] == targetName then
                return true, i
            end
        end
    end
    return false, 0
end

local function placeItemFromSlot(slot)
    extendedTurtle.clearObstructions()
    turtle.select(slot)
    local placed, _ = turtle.place()
    return placed
end

local function placeItemUpFromSlot(slot)
    extendedTurtle.clearObstructionsUp()
    turtle.select(slot)
    local placed, _ = turtle.placeUp()
    return placed
end

local function placeItemDownFromSlot(slot)
    extendedTurtle.clearObstructionsDown()
    turtle.select(slot)
    local placed, _ = turtle.placeDown()
    return placed
end

local function allSlotsContainItems()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item == nil then return false end
    end

    return true
end

local function hoveringOverItem()
    local name, _ = turtle.getItemDetail()

    return name ~= nil
end

local function getTotalItemCount(itemName)
    local totalFound = 0

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        
        if item ~= nil then
            if item["name"] == itemName then
                totalFound = totalFound + turtle.getItemCount()
            end
        end
    end
    
    return totalFound
end

local function dropBlacklistedItems()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        
        if item == nil then
            if has_value(blacklist, item["name"]) then
                turtle.drop()                
            end         
        end
    end
end

local function registerBlacklistItem(itemName)
    if has_value(blacklist, itemName) then
        return
    end

    blacklist[#blacklist+1] = itemName;
end

local function registerSlotAsBlacklistItem()
    local name, _ = turtle.getItemDetail()
    registerBlacklistItem(name);
end

local function registerInventoryAsBlacklistItems()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        
        if item ~= nil then
            registerBlacklistItem(item["name"])
        end
    end
end

return { findItem = findItem, placeItemDownFromSlot = placeItemDownFromSlot, placeItemUpFromSlot = placeItemUpFromSlot,
    placeItemFromSlot = placeItemFromSlot, allSlotsContainItems = allSlotsContainItems, hoveringOverItem = hoveringOverItem, getTotalItemCount = getTotalItemCount,
    dropBlacklistedItems = dropBlacklistedItems, registerBlacklistItem = registerBlacklistItem, registerSlotAsBlacklistItem = registerSlotAsBlacklistItem, registerInventoryAsBlacklistItems = registerInventoryAsBlacklistItems }
