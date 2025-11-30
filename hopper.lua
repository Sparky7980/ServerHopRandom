-- Module: ServerHop.lua
-- ULTIMATE EXPLOIT SERVERHOP MODULE (request version)

local ServerHop = {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = game.Players.LocalPlayer

--------------------------------------------------------------------
-- Safe wrapper for request() so module works on all executors
--------------------------------------------------------------------
local function GET(url)
    local result = request({
        Url = url,
        Method = "GET"
    })
    return result.Body
end

--------------------------------------------------------------------
-- Finds the BEST new public server (lowest players & not current)
--------------------------------------------------------------------
function ServerHop:GetBestServer(placeId)
    local cursor = nil
    local bestServer = nil

    repeat
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100"
        if cursor then
            url = url .. "&cursor=" .. cursor
        end

        local data
        
        local ok, res = pcall(function()
            return HttpService:JSONDecode(GET(url))
        end)

        if not ok then
            warn("[ServerHop] Failed to get server list:", res)
            return nil
        end

        for _, server in ipairs(res.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                
                -- pick lower player count first (fastest load)
                if not bestServer or server.playing < bestServer.playing then
                    bestServer = server
                end
            end
        end

        cursor = res.nextPageCursor
    until cursor == nil or bestServer ~= nil

    return bestServer and bestServer.id or nil
end

--------------------------------------------------------------------
-- Teleport one time to a new server
--------------------------------------------------------------------
function ServerHop:TeleportOnce(placeId)
    local newServer = self:GetBestServer(placeId)

    if newServer then
        TeleportService:TeleportToPlaceInstance(placeId, newServer, LocalPlayer)
        return true
    end

    return false
end

--------------------------------------------------------------------
-- AUTO-HOP LOOP: tries until successful teleport
--------------------------------------------------------------------
function ServerHop:AutoHop(placeId)
    while true do
        local newServer = self:GetBestServer(placeId)

        if newServer then
            warn("🔥 Auto-hopping to new server:", newServer)
            TeleportService:TeleportToPlaceInstance(placeId, newServer, LocalPlayer)
            break
        end

        warn("⚠️ No servers found. Retrying in 1s...")
        task.wait(1)
    end
end

--------------------------------------------------------------------

return ServerHop
