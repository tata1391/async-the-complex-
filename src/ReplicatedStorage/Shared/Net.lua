local Net = {}

Net.FolderName = "AsyncRemotes"

Net.Events = {
	PortalRequest = "PortalRequest",
	ClientReady = "ClientReady",
	PortalCinematic = "PortalCinematic",
	OpenPortalPanel = "OpenPortalPanel",
	PortalState = "PortalState",
	SessionUpdate = "SessionUpdate",
	PlayHubIntro = "PlayHubIntro",
	Toast = "Toast",
}

function Net.getOrCreate(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local object = Instance.new(className)
	object.Name = name
	object.Parent = parent
	return object
end

function Net.createFolder(parent)
	local folder = parent:FindFirstChild(Net.FolderName)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Net.FolderName
		folder.Parent = parent
	end

	for _, eventName in pairs(Net.Events) do
		Net.getOrCreate(folder, "RemoteEvent", eventName)
	end
	return folder
end

return Net
