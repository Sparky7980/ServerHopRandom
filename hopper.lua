local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local Deleted = false
local S_T = game:GetService("TeleportService")
local S_H = game:GetService("HttpService")

local File = pcall(function()
    AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
end)
if not File then
    table.insert(AllIDs, actualHour)
    pcall(function()
        writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
    end)
end

local function TPReturner(placeId)
    local Site
    if foundAnything == "" then
        Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
    else
        Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
    end
    
    local ID = ""
    if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
        foundAnything = Site.nextPageCursor
    end

    local validServers = {}
    for i, v in pairs(Site.data) do
        local Possible = true
        ID = tostring(v.id)
        
        -- Adjust condition for selecting servers: Avoid fully full servers but also avoid completely empty servers.
        local maxPlayers = tonumber(v.maxPlayers)
        local playing = tonumber(v.playing)

        -- Random factor: consider a server if it has space, and has some players but not too many
        if maxPlayers > playing and playing > 2 and playing < maxPlayers * 0.75 then
            for _, Existing in pairs(AllIDs) do
                if ID == tostring(Existing) then
                    Possible = false
                    break
                end
            end

            if Possible then
                table.insert(validServers, ID)
            end
        end
    end

    -- If there are valid servers, select one at random to teleport to
    if #validServers > 0 then
        local selectedServer = validServers[math.random(1, #validServers)]  -- Randomly select a server
        table.insert(AllIDs, selectedServer)
        wait()
        pcall(function()
            writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
            wait()
            S_T:TeleportToPlaceInstance(placeId, selectedServer, game.Players.LocalPlayer)
        end)
        wait(4)
    end
end

local module = {}
function module:Teleport(placeId)
    while wait() do
        pcall(function()
            TPReturner(placeId)
            if foundAnything ~= "" then
                TPReturner(placeId)
            end
        end)
    end
end

return module
