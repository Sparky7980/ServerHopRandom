local ServerHop = {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Finds a NEW server that is not your current JobId
function ServerHop:GetNewServer(placeId, currentJobId)
	local servers = {}
	local nextCursor = ""

	repeat
		local url = string.format(
			"https://games.roblox.com/v1/games/%d/servers/Public?limit=100&cursor=%s",
			placeId,
			HttpService:UrlEncode(nextCursor)
		)

		local response = HttpService:GetAsync(url)
		local data = HttpService:JSONDecode(response)

		for _, server in ipairs(data.data) do
			if server.playing < server.maxPlayers and server.id ~= currentJobId then
				table.insert(servers, server.id)
			end
		end

		nextCursor = data.nextPageCursor
	until not nextCursor

	if #servers > 0 then
		return servers[math.random(#servers)]
	end

	return nil
end

function ServerHop:Teleport(placeId)
	local currentJob = game.JobId
	local newServer = self:GetNewServer(placeId, currentJob)

	if newServer then
		TeleportService:TeleportToPlaceInstance(placeId, newServer, game.Players.LocalPlayer)
		return true
	else
		return false
	end
end

return ServerHop
