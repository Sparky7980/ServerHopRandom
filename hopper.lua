local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local AllIDs = {}
local currentHour = os.date("!*t").hour
local cursor = nil

-- Load file
local ok, data = pcall(function()
    return HttpService:JSONDecode(readfile("server-hop-temp.json"))
end)

if ok and type(data) == "table" then
    AllIDs = data
else
    AllIDs = { currentHour }
    pcall(function()
        writefile("server-hop-temp.json", HttpService:JSONEncode(AllIDs))
    end)
end

-- Reset file if hour changed
if AllIDs[1] ~= currentHour then
    AllIDs = { currentHour }
    pcall(function()
        writefile("server-hop-temp.json", HttpService:JSONEncode(AllIDs))
    end)
end


--===== MAIN SERVER FINDER =====--

local function GetServers(placeId)
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100"

    if cursor then
        url = url .. "&cursor=" .. cursor
    end

    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if not success then
        return nil
    end

    cursor = result.nextPageCursor
    return result.data
end


local function FindServer(placeId)
    while true do
        local servers = GetServers(placeId)
        if not servers then return nil end

        for _, server in ipairs(servers) do
            local id = server.id
            local playing = server.playing
            local maxPlayers = server.maxPlayers

            -- SKIP FULL SERVERS
            if playing < maxPlayers then

                local visited = false
                for _, loggedID in ipairs(AllIDs) do
                    if tostring(loggedID) == tostring(id) then
                        visited = true
                        break
                    end
                end

                if not visited then
                    table.insert(AllIDs, id)

                    pcall(function()
                        writefile("server-hop-temp.json", HttpService:JSONEncode(AllIDs))
                    end)

                    return id
                end
            end
        end

        -- no server found on this page, go to next
        if not cursor then
            return nil
        end

        task.wait(0.1)
    end
end


--===== MODULE API =====--

local module = {}

function module:Teleport(placeId)
    while true do
        local server = FindServer(placeId)
        if server then
            TeleportService:TeleportToPlaceInstance(placeId, server, game.Players.LocalPlayer)
            return
        end

        -- restart cursor search
        cursor = nil
        task.wait(1)
    end
end

return module
