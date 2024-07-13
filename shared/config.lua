-- config.lua
Config = {}

-- Priority packages and their priorities
Config.PriorityPackages = {
    ["priority_package_1_id"] = 100,
    ["priority_package_2_id"] = 75,
    ["priority_package_3_id"] = 50,
}

Config.Priority = {
    ["steam:11000010a7b4f5e"] = 100, -- Example Steam ID with high priority
    ["steam:11000010a7b4f5f"] = 50   -- Another Steam ID with lower priority
}

Config.MaxQueueSize = 64 -- Adjust based on your server capacity
