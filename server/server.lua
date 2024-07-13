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
local function updatePlayerPackages(steamId, discordId, packageId, priority)
    MySQL.Async.execute('REPLACE INTO player_packages (steam_id, discord_id, package_id, priority) VALUES (@steam_id, @discord_id, @package_id, @priority)', {
        ['@steam_id'] = steamId,
        ['@discord_id'] = discordId,
        ['@package_id'] = packageId,
        ['@priority'] = priority
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print("Updated package data for " .. (steamId or discordId))
        end
    end)
end

-- Handle incoming Tebex webhook
RegisterNetEvent('tebex:purchase')
AddEventHandler('tebex:purchase', function(purchaseData)
    local steamId = nil
    local discordId = nil
    local highestPriority = 0

    for _, id in ipairs(purchaseData.identifiers) do
        if string.find(id, "steam:") then
            steamId = id
        elseif string.find(id, "discord:") then
            discordId = id
        end
    end

    for packageId, priority in pairs(Config.PriorityPackages) do
        if purchaseData.package_id == packageId and priority > highestPriority then
            highestPriority = priority
        end
    end

    if highestPriority > 0 then
        local identifier = steamId or discordId
        if identifier then
            priorities[identifier] = highestPriority
            updatePlayerPackages(steamId, discordId, purchaseData.package_id, highestPriority)
        end
    end
end)

-- Function to load priorities from database
local function loadPrioritiesFromDatabase()
    MySQL.Async.fetchAll('SELECT * FROM player_packages', {}, function(results)
        for _, row in ipairs(results) do
            local identifier = row.steam_id or row.discord_id
            if identifier then
                priorities[identifier] = row.priority
            end
        end
    end)
end

-- Function to handle player connecting
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    deferrals.defer()

    local identifiers = getIdentifiers(source)
    local steamId = nil
    local discordId = nil

    for _, id in ipairs(identifiers) do
        if string.find(id, "steam:") then
            steamId = id
        elseif string.find(id, "discord:") then
            discordId = id
        end
    end

    local identifier = steamId or discordId

    if not identifier then
        deferrals.done("Failed to retrieve identifiers. Please restart your game and try again.")
        return
    end

    -- Check if queue is full
    if #queue >= Config.MaxQueueSize then
        deferrals.done("Server is full. Please try again later.")
        return
    end

    -- Check for priority
    local priority = priorities[identifier] or 0

    -- Add player to the queue
    table.insert(queue, { id = source, priority = priority })
    table.sort(queue, function(a, b) return a.priority > b.priority end)

    -- Allow connection
    deferrals.done()
end)

-- Periodically update queue priorities from Tebex
CreateThread(function()
    while true do
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
