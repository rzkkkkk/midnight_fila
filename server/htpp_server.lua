-- http_server.lua
local json = require "json"

local function handleTebexPurchase(req, res)
    local body = ""
    req.on("data", function(data)
        body = body .. data
    end)

    req.on("end", function()
        local purchaseData = json.decode(body)
        TriggerEvent('tebex:purchase', purchaseData)
        res.writeHead(200)
        res.write("OK")
        res.send()
    end)
end

RegisterCommand('tebex_purchase', handleTebexPurchase)
