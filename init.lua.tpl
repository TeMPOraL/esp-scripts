-- -*- mode: lua -*-

wifi.setmode(wifi.STATION)
wifi.sta.config("ROUTER_ESSID", "WIFI_PASSWORD") -- replace values with real data

print(wifi.sta.getip())

node.compile("startup.lua")
dofile("startup.lc")

