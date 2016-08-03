-- init.lua
print("Autostart in 1 second")

tmr.alarm(6, 1000, 0, function() 
    if (file.open("beamer_init.lua")) then
        dofile("beamer_init.lua")
    else
        print("No file found")
    end
end)
