-- Module: ServerHop.lua
local ServerHop = {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = game.Players.LocalPlayer

-----------------------------------------
-- Safe request wrapper
-----------------------------------------
local function GET(url)
    local ok, res = pcall(function()
        return request({
            Url = url,
            Method = "GET"
        })
    end)

    if not ok or not res or not res.Body then
        warn("[ServerHop] Request failed:", res)
        return nil
    end

    return res.Body
end

-----------------------------------------
-- Get BEST server
-----------------------------------------
function ServerHop:GetBestServer(placeId)
    local cursor = nil
    local bestServer = nil

    while true do
        local url = "https://games.roblox.com/v1/games/"..placeId.."/servers/Public?limit=100"
        if cursor then
            url = url .. "&cursor=" .. cursor
        end

        local body = GET(url)
        if not body then
            warn("[ServerHop] No body received.")
            return nil
        end

        local data
        local ok, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)

        if not ok or type(decoded) ~= "table" then
            warn("[ServerHop] JSON decode failed:", body)
            return nil
        end

        -- Validate required field
        if not decoded.data or type(decoded.data) ~= "table" then
            warn("[ServerHop] API returned invalid data:", decoded)
            return nil
        end

        -----------------------------------------
        -- Loop servers safely
        -----------------------------------------
        for _, server in ipairs(decoded.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                if not bestServer or server.playing < bestServer.playing then
                    bestServer = server
                end
            end
        end

        cursor = decoded.nextPageCursor
        if not cursor or bestServer then
            break
        end
    end

    return bestServer and bestServer.id or nil
end

-----------------------------------------
-- Single hop
-----------------------------------------
function ServerHop:TeleportOnce(placeId)
    local srv = self:GetBestServer(placeId)
    if not srv then return false end

    TeleportService:TeleportToPlaceInstance(placeId, srv, LocalPlayer)
    return true
end

-----------------------------------------
-- Auto hop loop
-----------------------------------------
function ServerHop:AutoHop(placeId)
    while true do
        local srv = self:GetBestServer(placeId)
        if srv then
            warn("🔥 Hopping to:", srv)
            TeleportService:TeleportToPlaceInstance(placeId, srv, LocalPlayer)
            return
        end

        warn("⚠️ No servers found. Retrying...")
        task.wait(1)
    end
end

return ServerHop
