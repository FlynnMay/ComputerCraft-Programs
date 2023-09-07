load("quarry");
load("update");

function load(name)
    shell.run("delete", name + ".lua")
    os.sleep(.4)
    shell.run("wget", "https://raw.githubusercontent.com/FlynnMay/ComputerCraft-Programs/master/" + name + ".lua")
    print("Updated: " + name)
end