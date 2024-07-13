local json = require "json"

local function handleTebexPurchase(req, res)
    local body = ""
    req.on("data", function(data)
        body = body .. data
    end)

    req.on("end", function()
        local purchaseData = json.decode(body)
        if purchaseData then
            TriggerEvent('tebex:purchase', purchaseData)
        end
        res.writeHead(200, { ["Content-Type"] = "text/plain" })
        res.write("OK")
        res.send()
    end)
end

-- Define endpoint for Tebex purchase webhook
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetHttpHandler(function(req, res)
            if req.path == "/tebex_purchase" and req.method == "POST" then
                handleTebexPurchase(req, res)
            else
                res.writeHead(404, { ["Content-Type"] = "text/plain" })
                res.write("Not Found")
                res.send()
            end
        end)
    end
end)
