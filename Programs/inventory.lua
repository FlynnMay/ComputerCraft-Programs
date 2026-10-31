local extendedTurtle = require("extendedTurtle")
local blacklist = require("blacklist")

-- helpers
local function loopInventory(fn)
    for i = 1, 16 do
        local found, slot = fn(i, turtle.getItemDetail(i))
        if found then return true, slot end
    end
    return false, 0
end

local function loopItems(fn)
    return loopInventory(function(i, item)
        if item ~= nil and fn(i, item) then
            return true, i
        end
    end)
end


-- returns if it was found and the slot (0 if not found)
local function findItem(targetName)
    return loopItems(function(_, item) return item["name"] == targetName end)
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
    local emptyFound = loopInventory(function(i, item) return item == nil end)
    return not emptyFound
end

local function hoveringOverItem()
    local name, _ = turtle.getItemDetail()

    return name ~= nil
end

local function getTotalItemCount(itemName)
    local totalFound = 0

    loopItems(function(_, item)
        if item["name"] == itemName then
            totalFound = totalFound + item["count"]
        end
        return false
    end)

    return totalFound
end

local function dropBlacklistedItems()
    local blist = blacklist.get()
    loopItems(function(i, item)
        if blist[item["name"]] then
            turtle.select(i)
            print("Dropping: " .. item["name"])
            turtle.drop()
        end
        return false
    end)
    turtle.select(1)
end

local cmd = arg[1]

if cmd == "blacklist" then
    loopItems(function(_, item) blacklist.registerItem(item["name"]) end)
    dropBlacklistedItems()
else
    print("Usage: blacklist")
end

return {
    findItem = findItem,
    placeItemDownFromSlot = placeItemDownFromSlot,
    placeItemUpFromSlot = placeItemUpFromSlot,
    placeItemFromSlot = placeItemFromSlot,
    allSlotsContainItems = allSlotsContainItems,
    hoveringOverItem = hoveringOverItem,
    getTotalItemCount = getTotalItemCount,
    dropBlacklistedItems = dropBlacklistedItems,
}
