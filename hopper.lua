-- ULTIMATE SERVER HOPPER (EXPLOIT VERSION)
-- Optimized for Solara, Synapse-Z, Script-Ware M, KRNL, Hydrogen, etc.

local placeId = game.PlaceId
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = game.Players.LocalPlayer

-- Request wrapper (supports all executors)
local function GET(url)
    local res = request({
        Url = url,
        Method = "GET"
    })
    return res.Body
end

-- Get a NEW public server fast
local function GetServer()
    local cursor = nil
    local bestServer = nil

    repeat
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100"
        if cursor then
            url = url .. "&cursor=" .. cursor
        end

        local data = game:GetService("HttpService"):JSONDecode(GET(url))

        for _, server in ipairs(data.data) do
            -- fastest check: server not full & not current JobId
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                
                -- PRIORITY: lowest player count for fastest load
                if not bestServer or server.playing < bestServer.playing then
                    bestServer = server
                end
            end
        end

        cursor = data.nextPageCursor
    until cursor == nil or bestServer ~= nil

    return bestServer and bestServer.id or nil
end

-- Auto-Hop Loop: hops until a new server is found
local function AutoHop()
    while true do
        local newServer = GetServer()
        if newServer then
            print("🔥 Hopping to:", newServer)
            TeleportService:TeleportToPlaceInstance(placeId, newServer, LocalPlayer)
            break
        else
            print("⚠️ No servers found, retrying...")
            task.wait(1)
        end
    end
end

-- Start hop instantly
AutoHop()
