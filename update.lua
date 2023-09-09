local function loadFile(name)
    shell.run("delete", name .. ".lua")
    os.sleep(.4)
    shell.run("wget", "https://raw.githubusercontent.com/FlynnMay/ComputerCraft-Programs/master/" .. name .. ".lua")
    print("Updated: " .. name)
end


if #arg < 1 then
    loadFile("update")
    loadFile("quarry")
    loadFile("travel")
else
    for i = 1, #arg, 1 do
        loadFile(arg[i])
    end
end
