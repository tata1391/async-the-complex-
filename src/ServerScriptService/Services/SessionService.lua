local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

-- Server owns membership, capacity, privacy, countdowns and all movement.
local SessionService = {}
SessionService.__index = SessionService

function SessionService.new(remotes, hub)
	local self = setmetatable({Remotes=remotes, HubBuilder=hub, Sessions={}, PlayerSessions={}, LastRequest={}, NextSessionNumber=1}, SessionService)
	TeleportService.TeleportInitFailed:Connect(function(player, _, message)
		local session = self.PlayerSessions[player]
		if session and session.State == "TELEPORTING" then
			self:Toast(player, "Transfer failed. You can leave and retry.", "ERROR")
			warn("[Async] Transfer failed: " .. tostring(message))
			self:Leave(player)
		end
	end)
	return self
end

function SessionService:Toast(player, message, kind)
	if player and player.Parent then self.Remotes.Toast:FireClient(player, {Message=message, Kind=kind or "INFO"}) end
end

function SessionService:_sessionPayload(session)
	local members = {}
	for _, player in ipairs(session.Players) do
		table.insert(members, {UserId=player.UserId, Name=player.DisplayName, Username=player.Name})
	end
	return {Id=session.Id, PortalId=session.PortalId, HostUserId=session.Host.UserId, Level=session.Level,
		State=session.State, Countdown=math.max(0, math.ceil(session.Deadline-workspace:GetServerTimeNow())),
		Players=members, Capacity=session.Capacity, Visibility=session.Visibility}
end

function SessionService:_allPortalStates()
	local result = {}
	for _, portal in ipairs(Config.Portals) do
		local s = self.Sessions[portal.Id]
		result[portal.Id] = {PortalId=portal.Id, DisplayName=portal.DisplayName, State=s and s.State or "AVAILABLE",
			Level=s and s.Level or "LEVEL_0", Players=s and #s.Players or 0, MaxPlayers=s and s.Capacity or 4,
			Session=s and self:_sessionPayload(s) or nil}
	end
	return result
end

function SessionService:BroadcastStates()
	self.Remotes.PortalState:FireAllClients(self:_allPortalStates())
	for _, session in pairs(self.Sessions) do
		self.HubBuilder:SetPortalState(session.PortalId, session.State, session)
		for _, member in ipairs(session.Players) do
			self.Remotes.SessionUpdate:FireClient(member, self:_sessionPayload(session))
		end
	end
end

function SessionService:_near(player, portalId)
	local portal = self.HubBuilder.Portals[portalId]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return portal and root and humanoid and humanoid.Health > 0 and (root.Position-portal.Prompt.Parent.Position).Magnitude <= 18
end

function SessionService:OpenPanel(player, portalId)
	if not self:_near(player, portalId) then return end
	self.Remotes.OpenPortalPanel:FireClient(player, self:_allPortalStates()[portalId])
end

function SessionService:_setMembership(player, session)
	self.PlayerSessions[player] = session
	player:SetAttribute("AsyncSessionId", session and session.Id or nil)
	player:SetAttribute("AsyncSessionPortal", session and session.PortalId or nil)
	if not session then player:SetAttribute("AsyncPhase", "HUB") end
end

function SessionService:Leave(player)
	local session = self.PlayerSessions[player]
	if not session then return end
	local index = table.find(session.Players, player)
	if index then table.remove(session.Players, index) end
	self:_setMembership(player, nil)
	if session.State ~= "WAITING" and player.Character then
		player.Character:PivotTo(self.HubBuilder.HubSpawn.CFrame + Vector3.new(0,3,0))
	end
	if #session.Players == 0 then
		self.Sessions[session.PortalId] = nil
		self.HubBuilder:SetPortalState(session.PortalId, "AVAILABLE")
	elseif session.Host == player then
		session.Host = session.Players[1]
		if session.Visibility == "Private" then self:Toast(session.Host, "PRIVATE CODE: " .. session.Code) end
	end
	self.Remotes.SessionUpdate:FireClient(player, {Cleared=true})
	self:BroadcastStates()
end

function SessionService:Join(player, portalId, options)
	if not self:_near(player, portalId) or self.PlayerSessions[player] then return end
	options = type(options) == "table" and options or {}
	local session = self.Sessions[portalId]
	if session then
		if session.State ~= "WAITING" or #session.Players >= session.Capacity then
			return self:Toast(player, "This session is full or already running.", "ERROR")
		end
		if session.Visibility == "Private" and options.Code ~= session.Code then
			return self:Toast(player, "Enter the private code from the host.", "ERROR")
		end
		if session.Visibility == "Friends" then
			local host = session.Host
			local ok, friend = pcall(function() return player:IsFriendsWithAsync(host.UserId) end)
			if not ok or not friend then return self:Toast(player, "Friends of the host only.", "ERROR") end
			-- Friendship lookup yields: revalidate before changing shared membership.
			if self.Sessions[portalId] ~= session or session.Host ~= host or session.State ~= "WAITING"
				or #session.Players >= session.Capacity or self.PlayerSessions[player] or not player.Parent or not self:_near(player, portalId) then return end
		end
		table.insert(session.Players, player)
	else
		local capacity = options.Capacity
		if type(capacity) ~= "number" or capacity ~= capacity or capacity % 1 ~= 0 or capacity < 1 or capacity > 4 then capacity=4 end
		local visibility = options.Visibility
		if visibility ~= "Private" and visibility ~= "Friends" then visibility="Public" end
		local level = Config.Levels[options.LevelId or "LEVEL_0"]
		if not level or not level.Unlocked then return self:Toast(player,"This level is locked.","ERROR") end
		session = {Id=string.format("TEAM-%03d",self.NextSessionNumber), PortalId=portalId, Host=player, Players={player},
			Capacity=capacity, Visibility=visibility, Code=HttpService:GenerateGUID(false):sub(1,8):upper(),
			Level=level.Id, State="WAITING", Deadline=workspace:GetServerTimeNow()+Config.Game.SessionCountdownSeconds}
		self.NextSessionNumber += 1
		self.Sessions[portalId]=session
		if visibility == "Private" then self:Toast(player,"PRIVATE CODE: " .. session.Code) end
		self:_runCountdown(session)
	end
	self:_setMembership(player,session)
	self:BroadcastStates()
	if Config.Game.SessionAutoStartWhenFull and #session.Players >= session.Capacity then self:Start(session.Host) end
end

function SessionService:SetLevel(player, levelId)
	local session=self.PlayerSessions[player]
	local level=Config.Levels[levelId]
	if session and session.Host==player and session.State=="WAITING" and level and level.Unlocked then
		session.Level=levelId
		self:BroadcastStates()
	end
end

function SessionService:_runCountdown(session)
	task.spawn(function()
		while self.Sessions[session.PortalId]==session and session.State=="WAITING" do
			task.wait(1)
			if self.Sessions[session.PortalId]~=session or session.State~="WAITING" then return end
			if workspace:GetServerTimeNow() >= session.Deadline then self:Start(session.Host) else self:BroadcastStates() end
		end
	end)
end

function SessionService:_teleport(session)
	if self.Sessions[session.PortalId]~=session or #session.Players==0 then return end
	session.State="TELEPORTING"
	self:BroadcastStates()
	local members=table.clone(session.Players)
	local options=Instance.new("TeleportOptions")
	options.ShouldReserveServer=true
	options:SetTeleportData({SessionId=session.Id,Level=session.Level,PortalId=session.PortalId})
	local ok, err=pcall(function() TeleportService:TeleportAsync(Config.Teleport.PlaceId, members, options) end)
	if not ok then
		warn("[Async] " .. tostring(err))
		if self.Sessions[session.PortalId]~=session then return end
		session.State="ACTIVE"
		for _, p in ipairs(session.Players) do self:Toast(p,"Transfer unavailable. Leave to return to reception.","ERROR") end
		self:BroadcastStates()
	end
	-- A hung handoff must not reserve a chamber forever.
	task.delay(45,function()
		if self.Sessions[session.PortalId]==session and session.State=="TELEPORTING" then
			for _, p in ipairs(table.clone(session.Players)) do self:Leave(p) end
		end
	end)
end

function SessionService:Start(player)
	local session=self.PlayerSessions[player]
	if not session or session.Host~=player or session.State~="WAITING" then return end
	session.State="STARTING" -- Lock synchronously, before delayed work or yielding APIs.
	self:BroadcastStates()
	for slot, member in ipairs(session.Players) do
		local spawn=self.HubBuilder.SpawnLocations[session.PortalId][slot]
		local portal=self.HubBuilder.Portals[session.PortalId]
		if member.Character then
			local position=spawn.Position+Vector3.new(0,3,0)
			member.Character:PivotTo(CFrame.lookAt(position,Vector3.new(portal.PortalField.Position.X,position.Y,portal.PortalField.Position.Z)))
		end
		member:SetAttribute("AsyncPhase","EMPLOYEE")
		self.Remotes.PortalCinematic:FireClient(member,{PortalId=session.PortalId, Duration=7})
	end
	task.delay(7,function()
		if self.Sessions[session.PortalId]~=session then return end
		session.State="ACTIVE"
		self:BroadcastStates()
		if Config.Teleport.Enabled and Config.Teleport.PlaceId>0 then
			self:_teleport(session)
		else
			for _, member in ipairs(session.Players) do
				self:Toast(member,"HUB TEST COMPLETE — Leave session to return. Level gameplay is not installed.","SUCCESS")
			end
		end
	end)
end

function SessionService:HandleRequest(player, payload)
	local now=os.clock()
	if now-(self.LastRequest[player] or -1)<0.2 then return end
	self.LastRequest[player]=now
	if type(payload)~="table" or type(payload.Action)~="string" then return end
	if payload.Action=="Join" and type(payload.PortalId)=="string" and #payload.PortalId<16 then
		self:Join(player,payload.PortalId,payload)
	elseif payload.Action=="Open" and type(payload.PortalId)=="string" then self:OpenPanel(player,payload.PortalId)
	elseif payload.Action=="Leave" then self:Leave(player)
	elseif payload.Action=="Start" then self:Start(player)
	elseif payload.Action=="SetLevel" and type(payload.LevelId)=="string" then self:SetLevel(player,payload.LevelId)
	elseif payload.Action=="Code" then
		local s=self.PlayerSessions[player]
		if s and s.Host==player and s.Visibility=="Private" then self:Toast(player,"PRIVATE CODE: "..s.Code) end
	end
end

function SessionService:PlayerRemoving(player)
	self:Leave(player)
	self.LastRequest[player]=nil
end
return SessionService
