-- server.lua
local queue = {}
local priorities = Config.Priority

-- Fetch the Tebex secret key from server.cfg
local tebexSecretKey = GetConvar("tebexSecretKey", "default_key")
if tebexSecretKey == "default_key" then
    print("^1[ERROR] Tebex secret key is not set in server.cfg!^7")
end

-- Function to get player identifiers
local function getIdentifiers(source)
    local identifiers = {}
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        table.insert(identifiers, id)
    end
    return identifiers
end

-- Function to update database with player package data
local function updatePlayerPackages(steamId, packageId, priority)
    MySQL.Async.execute('REPLACE INTO player_packages (steam_id, package_id, priority) VALUES (@steam_id, @package_id, @priority)', {
        ['@steam_id'] = steamId,
        ['@package_id'] = packageId,
        ['@priority'] = priority
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print("Updated package data for " .. steamId)
        end
    end)
end

-- Function to fetch Tebex purchases and update queue priorities
local function updateQueuePriorities()
    PerformHttpRequest("https://plugin.tebex.io/information", function(statusCode, response, headers)
        if statusCode == 200 then
            local data = json.decode(response)
            for _, player in ipairs(data.players) do
                local steamId = player.identifiers[1]
                local highestPriority = 0

                for packageId, priority in pairs(Config.PriorityPackages) do
                    if player.package_id == packageId and priority > highestPriority then
                        highestPriority = priority
                    end
                end

                if highestPriority > 0 then
                    priorities[steamId] = highestPriority
                    updatePlayerPackages(steamId, player.package_id, highestPriority)
                end
            end
        else
            print("Failed to fetch Tebex data")
        end
    end, "GET", "", { ["X-Tebex-Secret"] = tebexSecretKey })
end

-- Function to load priorities from database
local function loadPrioritiesFromDatabase()
    MySQL.Async.fetchAll('SELECT * FROM player_packages', {}, function(results)
        for _, row in ipairs(results) do
            priorities[row.steam_id] = row.priority
        end
    end)
end

-- Function to handle player connecting
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()

    local identifiers = getIdentifiers(source)
    local steamId = identifiers[1]

    -- Check if queue is full
    if #queue >= Config.MaxQueueSize then
        deferrals.done("Server is full. Please try again later.")
        return
    end

    -- Check for priority
    local priority = priorities[steamId] or 0

    -- Add player to the queue
    table.insert(queue, { id = source, priority = priority })
    table.sort(queue, function(a, b) return a.priority > b.priority end)

    -- Allow connection
    deferrals.done()
end)

-- Periodically update queue priorities from Tebex
CreateThread(function()
    while true do
        updateQueuePriorities()
        Wait(60000) -- Update every 60 seconds
    end
end)

-- Load priorities from database on server start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        loadPrioritiesFromDatabase()
    end
end)

-- Remove player from the queue when they disconnect
AddEventHandler('playerDropped', function(reason)
    local source = source
    for i, player in ipairs(queue) do
        if player.id == source then
            table.remove(queue, i)
            break
        end
    end
end)
