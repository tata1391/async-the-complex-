local PortalService = {}
PortalService.__index = PortalService

function PortalService.new(hubBuilder, sessionService, remotes)
	local self = setmetatable({
		HubBuilder = hubBuilder,
		SessionService = sessionService,
		Remotes = remotes,
		Connections = {},
	}, PortalService)

	for portalId, portal in pairs(hubBuilder.Portals) do
		self.Connections[portalId] = portal.Prompt.Triggered:Connect(function(player)
			sessionService:OpenPanel(player, portalId)
		end)
	end

	self.RequestConnection = remotes.PortalRequest.OnServerEvent:Connect(function(player, payload)
		sessionService:HandleRequest(player, payload)
	end)
	return self
end

function PortalService:Destroy()
	for _, connection in pairs(self.Connections) do
		connection:Disconnect()
	end
	if self.RequestConnection then
		self.RequestConnection:Disconnect()
	end
end

return PortalService
