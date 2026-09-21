local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))
local Services = script.Parent:WaitForChild("Services")
local remoteFolder = Net.createFolder(ReplicatedStorage)
local remotes = {}
for _, name in pairs(Net.Events) do remotes[name]=remoteFolder:WaitForChild(name) end
local hub = require(Services.HubBuilder).new():Build()
local sessions = require(Services.SessionService).new(remotes,hub)
require(Services.PortalService).new(hub,sessions,remotes)
require(Services.HubEffects).new(hub):Start()
local ready = {}
local connected = {}
local function onPlayer(player)
	if connected[player] then return end
	connected[player]=true
	local function onCharacter(character)
		sessions:Leave(player)
		local root=character:WaitForChild("HumanoidRootPart",10)
		if root then character:PivotTo(hub.HubSpawn.CFrame+Vector3.new(0,3,0)) end
		player:SetAttribute("AsyncPhase","HUB")
	end
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then task.spawn(onCharacter,player.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do onPlayer(player) end
remotes.ClientReady.OnServerEvent:Connect(function(player)
	if ready[player] then return end
	ready[player]=true
	remotes.PortalState:FireClient(player,sessions:_allPortalStates())
	remotes.PlayHubIntro:FireClient(player,{Duration=8})
end)
Players.PlayerRemoving:Connect(function(player)
	sessions:PlayerRemoving(player)
	ready[player]=nil
	connected[player]=nil
end)
print("[Async] Hub 0.2.0 — six chambers ready; test mode enabled by default.")
