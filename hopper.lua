local ServerHop = {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Gets a NEW server that isn't your current JobId
function ServerHop:GetNewServer(placeId, currentJobId)
	local servers = {}
	local cursor = nil
	
	while true do
		local url
		
		if cursor then
			url = string.format(
				"https://games.roblox.com/v1/games/%d/servers/Public?limit=100&cursor=%s",
				placeId,
				cursor
			)
		else
			url = string.format(
				"https://games.roblox.com/v1/games/%d/servers/Public?limit=100",
				placeId
			)
		end

		local success, response = pcall(function()
			return HttpService:GetAsync(url)
		end)

		if not success then
			warn("[ServerHop] Request failed:", response)
			break
		end

		local data = HttpService:JSONDecode(response)

		for _, server in ipairs(data.data) do
			if server.playing < server.maxPlayers and server.id ~= currentJobId then
				table.insert(servers, server.id)
			end
		end

		if data.nextPageCursor then
			cursor = data.nextPageCursor
		else
			break
		end
	end

	if #servers > 0 then
		return servers[math.random(1, #servers)]
	end

	return nil
end

function ServerHop:Teleport(placeId)
	local newServer = self:GetNewServer(placeId, game.JobId)

	if newServer then
		TeleportService:TeleportToPlaceInstance(placeId, newServer, game.Players.LocalPlayer)
		return true
	else
		warn("[ServerHop] No available servers found.")
		return false
	end
end

return ServerHop
