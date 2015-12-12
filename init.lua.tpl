-- -*- mode: lua -*-

print("Connecting to Wi-Fi...")
wifi.setmode(wifi.STATION)
wifi.sta.config("ROUTER_ESSID", "WIFI_PASSWORD") -- replace values with real data
wifi.sta.autoconnect(1)

tmr.alarm(1, 1000, 1, function()
             if wifi.sta.getip() == nil then
                print("IP not assigned, waiting...")
             else
                tmr.stop(1)
                print("Connected, received IP " .. wifi.sta.getip() .. ".")
                node.compile("startup.lua")
                dofile("startup.lc")
             end
end)
