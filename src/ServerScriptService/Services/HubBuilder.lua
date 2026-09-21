local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local HubBuilder = {}
HubBuilder.__index = HubBuilder

local V = Config.Visuals

local function createPart(parent, name, size, cframe, color, material, transparency, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = canCollide ~= false
	part.CanTouch = false
	part.CanQuery = true
	part.Color = color or V.Metal
	part.Material = material or Enum.Material.Metal
	part.Transparency = transparency or 0
	part.CastShadow = transparency == nil or transparency < 0.9
	part.Parent = parent
	return part
end

local function createLight(parent, name, color, brightness, range, angle)
	local light = Instance.new("SurfaceLight")
	light.Name = name
	light.Color = color
	light.Brightness = brightness or 1
	light.Range = range or 18
	light.Angle = angle or 100
	light.Face = Enum.NormalId.Bottom
	light.Parent = parent
	return light
end

local function createLabel(parent, text, color)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "StatusDisplay"
	billboard.Size = UDim2.fromOffset(210, 46)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 90
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(12, 14, 13)
	label.BackgroundTransparency = 0.15
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(210, 220, 215)
	label.TextScaled = true
	label.Font = Enum.Font.Code
	label.Parent = billboard
	return label
end

local function createRail(parent, position, length, axis)
	local horizontalSize
	local horizontalCFrame
	if axis == "Z" then
		horizontalSize = Vector3.new(0.2, 0.2, length)
		horizontalCFrame = CFrame.new(position)
	else
		horizontalSize = Vector3.new(length, 0.2, 0.2)
		horizontalCFrame = CFrame.new(position)
	end
	createPart(parent, "RailTop", horizontalSize, horizontalCFrame, V.Metal, Enum.Material.Metal)
	for offset = -length / 2, length / 2, 5 do
		local x = position.X
		local z = position.Z
		if axis == "Z" then
			z += offset
		else
			x += offset
		end
		createPart(parent, "RailPost", Vector3.new(0.2, 2.2, 0.2), CFrame.new(x, position.Y - 1.1, z), V.Metal, Enum.Material.Metal)
	end
end

local function createCeilingLight(parent, position, color)
	local fixture = createPart(parent, "FluorescentFixture", Vector3.new(4, 0.15, 0.8), CFrame.new(position), Color3.fromRGB(195, 201, 192), Enum.Material.Metal)
	local light = Instance.new("PointLight")
	light.Name = "CeilingLight"
	light.Color = color or Color3.fromRGB(220, 230, 218)
	light.Brightness = 1.8
	light.Range = 22
	light.Shadows = true
	light.Parent = fixture
	return light
end

local function createTank(parent, position)
	local tank = createPart(parent, "IndustrialTank", Vector3.new(2.2, 4, 2.2), CFrame.new(position), Color3.fromRGB(45, 74, 78), Enum.Material.Metal)
	local top = createPart(parent, "TankCap", Vector3.new(2.35, 0.25, 2.35), CFrame.new(position + Vector3.new(0, 2.12, 0)), Color3.fromRGB(86, 92, 86), Enum.Material.Metal)
	local pipe = createPart(parent, "TankPipe", Vector3.new(0.3, 1.4, 0.3), CFrame.new(position + Vector3.new(0, 2.9, 0)), Color3.fromRGB(67, 71, 67), Enum.Material.Metal)
	return tank, top, pipe
end

local function createCameraPoint(parent, name, cframe)
	local cameraPoint = createPart(parent, name, Vector3.new(0.4, 0.4, 0.4), cframe, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1, false)
	cameraPoint.CanQuery = false
	return cameraPoint
end

function HubBuilder.new()
	return setmetatable({
		Root = nil,
		Portals = {},
		Prompts = {},
		SpawnLocations = {},
	}, HubBuilder)
end

function HubBuilder:ApplyLighting()
	-- LightingStyle is also configured on the place for edit-mode preview.
	pcall(function() Lighting.LightingStyle = Enum.LightingStyle.Realistic end)
	Lighting.GlobalShadows = true
	Lighting.Brightness = 1.1
	Lighting.ClockTime = 2.4
	Lighting.Ambient = Color3.fromRGB(35, 38, 36)
	Lighting.OutdoorAmbient = Color3.fromRGB(18, 20, 19)
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.25

	local atmosphere = Lighting:FindFirstChild("AsyncAtmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "AsyncAtmosphere"
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.05
	atmosphere.Color = Color3.fromRGB(137, 145, 139)
	atmosphere.Decay = Color3.fromRGB(61, 66, 63)
	atmosphere.Glare = 0.05
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting

	local correction = Lighting:FindFirstChild("AsyncColorCorrection") or Instance.new("ColorCorrectionEffect")
	correction.Name = "AsyncColorCorrection"
	correction.Brightness = -0.04
	correction.Contrast = 0.16
	correction.Saturation = -0.12
	correction.TintColor = Color3.fromRGB(218, 224, 215)
	correction.Parent = Lighting

	local bloom = Lighting:FindFirstChild("AsyncBloom") or Instance.new("BloomEffect")
	bloom.Name = "AsyncBloom"
	bloom.Intensity = 0.18
	bloom.Size = 18
	bloom.Threshold = 1.2
	bloom.Parent = Lighting
end

function HubBuilder:Build()
	local previous = workspace:FindFirstChild("AsyncHub")
	if previous then
		previous:Destroy()
	end

	local root = Instance.new("Model")
	root.Name = "AsyncHub"
	root.Parent = workspace
	self.Root = root
	self:ApplyLighting()

	local geometry = Instance.new("Folder")
	geometry.Name = "Geometry"
	geometry.Parent = root
	local interactables = Instance.new("Folder")
	interactables.Name = "Interactables"
	interactables.Parent = root
	local cameraPoints = Instance.new("Folder")
	cameraPoints.Name = "CameraPoints"
	cameraPoints.Parent = root

	local hub = Config.Hub
	local halfLength = hub.CorridorLength / 2
	local halfWidth = hub.CorridorWidth / 2

	createPart(geometry, "MainFloor", Vector3.new(hub.CorridorWidth + 58, hub.FloorThickness, hub.CorridorLength + 16), CFrame.new(0, -0.3, 0), V.Floor, Enum.Material.Concrete)
	createPart(geometry, "CorridorCeiling", Vector3.new(hub.CorridorWidth + 58, 0.5, hub.CorridorLength + 16), CFrame.new(0, hub.CorridorHeight, 0), V.Metal, Enum.Material.Metal)
	-- Only structural piers here: chamber walls provide the doorway openings.
	for _, side in ipairs({-1, 1}) do
		for _, gap in ipairs({{-56, -55}, {-21, -17}, {17, 21}, {55, 56}}) do
			createPart(geometry, "CorridorPier", Vector3.new(0.8, hub.CorridorHeight, gap[2]-gap[1]), CFrame.new(side*halfWidth, hub.CorridorHeight/2, (gap[1]+gap[2])/2), V.Brick, Enum.Material.Brick)
		end
	end
	createPart(geometry, "NorthWall", Vector3.new(72, 20, 1), CFrame.new(0, 10, 56), V.Brick, Enum.Material.Brick)
	-- Rear maintenance galleries: sealed during the hub slice, reserved for archive and secret-content gates.
	local service = Instance.new("Model")
	service.Name = "RearMaintenanceGalleries"
	service.Parent = root
	for _, side in ipairs({-1, 1}) do
		local x = side * 41
		createPart(service, "ServiceFloor", Vector3.new(10, 0.3, hub.CorridorLength), CFrame.new(x, -0.1, 0), V.Floor, Enum.Material.Concrete)
		createPart(service, "ServiceCeiling", Vector3.new(10, 0.35, hub.CorridorLength), CFrame.new(x, 12, 0), V.Metal, Enum.Material.Metal)
		createPart(service, "ServiceOuterWall", Vector3.new(0.8, 12, hub.CorridorLength), CFrame.new(side*46, 6, 0), V.Brick, Enum.Material.Brick)
		createPart(service, "ServiceInnerWall", Vector3.new(0.8, 12, hub.CorridorLength), CFrame.new(side*36, 6, 0), V.Panel, Enum.Material.Metal)
		for _, z in ipairs({-46, -8, 30}) do
			createPart(service, "MaintenanceLight", Vector3.new(3, 0.12, 0.5), CFrame.new(x, 11.7, z), V.Panel, Enum.Material.Metal)
		end
		for _, z in ipairs({-56, 56}) do
			createPart(service, "ServiceEndWall", Vector3.new(10, 12, 0.8), CFrame.new(x, 6, z), V.Brick, Enum.Material.Brick)
		end
		local hatch = createPart(service, "MaintenanceHatch", Vector3.new(0.2, 4, 3), CFrame.new(side*36.45, 4.5, -52), V.Metal, Enum.Material.Metal, 0, true)
		hatch:SetAttribute("SecretContentGate", true)
	end
	-- Stair to the accessible control gallery; 20 steps at 0.55 studs.
	for step = 1, 20 do
		createPart(geometry, "ControlStair", Vector3.new(5, step*0.55, 1), CFrame.new(0, step*0.275, 30-step), V.Metal, Enum.Material.DiamondPlate)
	end


	for z = -halfLength + 8, halfLength - 8, 14 do
		createCeilingLight(geometry, Vector3.new(0, hub.CorridorHeight - 0.3, z), Color3.fromRGB(215, 225, 214))
	end

	for z = -halfLength + 8, halfLength - 8, 16 do
		local stripLeft = createPart(geometry, "SafetyStrip", Vector3.new(0.12, 0.12, 9), CFrame.new(-halfWidth + 0.1, 0.08, z), V.SafetyYellow, Enum.Material.Neon, 0.35, false)
		stripLeft.CanQuery = false
		local stripRight = stripLeft:Clone()
		stripRight.Parent = geometry
		stripRight.CFrame = CFrame.new(halfWidth - 0.1, 0.08, z)
	end

	local controlRoom = Instance.new("Model")
	controlRoom.Name = "ControlGallery"
	controlRoom.Parent = root
	createPart(controlRoom, "ControlFloor", Vector3.new(34, 0.35, 20), CFrame.new(0, 11, 0), V.Metal, Enum.Material.Metal)
	createPart(controlRoom, "ControlBackWall", Vector3.new(13, 8, 0.5), CFrame.new(-10.5, 15, 10), V.Panel, Enum.Material.Metal)
	createPart(controlRoom, "ControlFrontGlass", Vector3.new(34, 7, 0.2), CFrame.new(0, 15, -10), Color3.fromRGB(110, 145, 145), Enum.Material.Glass, 0.55, true)
	createRail(controlRoom, Vector3.new(0, 14, -10), 34, "X")
	createPart(controlRoom, "ControlBackWallRight", Vector3.new(13,8,0.5), CFrame.new(10.5,15,10), V.Panel, Enum.Material.Metal)
	for x = -12, 12, 6 do
		local console = createPart(controlRoom, "ControlConsole", Vector3.new(4.5, 1.3, 1.6), CFrame.new(x, 11.9, 5), Color3.fromRGB(34, 39, 36), Enum.Material.Metal)
		local monitor = createPart(controlRoom, "Monitor", Vector3.new(2.4, 1.4, 0.15), CFrame.new(x, 13.1, 4.1), Color3.fromRGB(42, 70, 65), Enum.Material.Glass, 0.15, false)
		local monitorLight = Instance.new("PointLight")
		monitorLight.Color = Color3.fromRGB(130, 210, 190)
		monitorLight.Brightness = 0.25
		monitorLight.Range = 5
		monitorLight.Parent = monitor
	end

	local roomOffsets = {-38, 0, 38}
	for index, portalConfig in ipairs(Config.Portals) do
		local row = math.ceil(index / 2)
		local side = index % 2 == 1 and -1 or 1
		local z = roomOffsets[row]
		local roomCenter = Vector3.new(side * (halfWidth + hub.PortalRoomWidth / 2), 0, z)
		local room = Instance.new("Model")
		room.Name = portalConfig.Id .. "_Room"
		room.Parent = root

		local roomWidth = hub.PortalRoomWidth
		local roomDepth = hub.PortalRoomDepth
		local roomHeight = hub.PortalRoomHeight
		local innerX = side * (halfWidth + roomWidth / 2)
		local outerX = side * (halfWidth + roomWidth)

		createPart(room, "RoomFloor", Vector3.new(roomWidth, 0.35, roomDepth), CFrame.new(roomCenter.X, -0.08, roomCenter.Z), V.Floor, Enum.Material.Concrete)
		createPart(room, "RoomCeiling", Vector3.new(roomWidth, 0.35, roomDepth), CFrame.new(roomCenter.X, roomHeight, roomCenter.Z), V.Metal, Enum.Material.Metal)
		createPart(room, "RoomSideWallA", Vector3.new(roomWidth, roomHeight, 0.7), CFrame.new(roomCenter.X, roomHeight / 2, roomCenter.Z - roomDepth / 2), V.Brick, Enum.Material.Brick)
		createPart(room, "RoomSideWallB", Vector3.new(roomWidth, roomHeight, 0.7), CFrame.new(roomCenter.X, roomHeight / 2, roomCenter.Z + roomDepth / 2), V.Brick, Enum.Material.Brick)

		local innerWallX = side * (halfWidth + 0.35)
		createPart(room, "InnerWallLeft", Vector3.new(0.7, roomHeight, roomDepth / 2 - 4), CFrame.new(innerWallX, roomHeight / 2, roomCenter.Z - roomDepth / 4 - 2), V.Panel, Enum.Material.Metal)
		createPart(room, "InnerWallRight", Vector3.new(0.7, roomHeight, roomDepth / 2 - 4), CFrame.new(innerWallX, roomHeight / 2, roomCenter.Z + roomDepth / 4 + 2), V.Panel, Enum.Material.Metal)
		local glassDoor = createPart(room, "ObservationWindow", Vector3.new(0.15, 7, 8), CFrame.new(innerWallX - side * 0.1, 12, roomCenter.Z), Color3.fromRGB(100, 145, 146), Enum.Material.Glass, 0.58, true)
		glassDoor:SetAttribute("PortalId", portalConfig.Id)

		local outerWallX = outerX
		createPart(room, "OuterWallLeft", Vector3.new(0.7, roomHeight, roomDepth / 2 - 5), CFrame.new(outerWallX, roomHeight / 2, roomCenter.Z - roomDepth / 4 - 2.5), V.Panel, Enum.Material.Metal)
		createPart(room, "OuterWallRight", Vector3.new(0.7, roomHeight, roomDepth / 2 - 5), CFrame.new(outerWallX, roomHeight / 2, roomCenter.Z + roomDepth / 4 + 2.5), V.Panel, Enum.Material.Metal)

		local portalZ = roomCenter.Z
		local portalFrameX = outerWallX - side * 0.5
		local frameColor = Color3.fromRGB(145, 148, 142)
		createPart(room, "PortalFrameTop", Vector3.new(1.2, 1.4, hub.PortalWidth + 1.2), CFrame.new(portalFrameX, hub.PortalHeight + 1.2, portalZ), frameColor, Enum.Material.Metal)
		createPart(room, "PortalFrameBottom", Vector3.new(1.2, 1.1, hub.PortalWidth + 1.2), CFrame.new(portalFrameX, 0.65, portalZ), frameColor, Enum.Material.Metal)
		createPart(room, "PortalFrameLeft", Vector3.new(1.2, hub.PortalHeight, 1.2), CFrame.new(portalFrameX, hub.PortalHeight / 2 + 0.7, portalZ - (hub.PortalWidth / 2 + 0.6)), frameColor, Enum.Material.Metal)
		createPart(room, "PortalFrameRight", Vector3.new(1.2, hub.PortalHeight, 1.2), CFrame.new(portalFrameX, hub.PortalHeight / 2 + 0.7, portalZ + (hub.PortalWidth / 2 + 0.6)), frameColor, Enum.Material.Metal)
		local portalField = createPart(room, "PortalField", Vector3.new(0.15, hub.PortalHeight - 1.1, hub.PortalWidth - 1), CFrame.new(portalFrameX - side * 0.7, hub.PortalHeight / 2 + 0.7, portalZ), V.PortalIdle, Enum.Material.Neon, 0.32, false)
		portalField:SetAttribute("PortalId", portalConfig.Id)

		createPart(room, "ThresholdBacking", Vector3.new(0.7, roomHeight, 10), CFrame.new(outerWallX+side*0.7, roomHeight/2, portalZ), Color3.fromRGB(22,26,27), Enum.Material.Metal)
		createPart(room, "ThresholdLintel", Vector3.new(0.7,4,10), CFrame.new(outerWallX,18,portalZ), V.Panel)
		for _, edge in ipairs({-1,1}) do
			local leaf = createPart(room, "ArmoredDoor", Vector3.new(4.5,13,0.5), CFrame.new(portalFrameX-side*2.7,7.2,portalZ+edge*5.1), V.Panel)
			for y=2,12,5 do
				createPart(room, "DoorHinge", Vector3.new(0.6,1,0.8), CFrame.new(portalFrameX-side*0.7,y,portalZ+edge*5.1), V.Metal)
			end
		end
		createPart(room, "SafetyLine", Vector3.new(0.25,0.03,14), CFrame.new(roomCenter.X+side*2,0.12,portalZ), V.SafetyYellow, Enum.Material.SmoothPlastic,0,false)
		for height=9,15,2 do
			createPart(room, "Conduit", Vector3.new(roomWidth-2,0.22,0.22), CFrame.new(roomCenter.X,height,portalZ-16.4), V.Metal)
		end
		for beam=-12,12,12 do
			createPart(room, "RoofBeam", Vector3.new(roomWidth,0.7,0.5), CFrame.new(roomCenter.X,19,portalZ+beam), V.Metal)
		end
		local indicator = createPart(room, "StatusIndicator", Vector3.new(1.1, 0.3, 0.3), CFrame.new(portalFrameX - side * 0.8, hub.PortalHeight + 2.1, portalZ), V.EmergencyRed, Enum.Material.Neon, 0, false)
		local statusLabel = createLabel(indicator, portalConfig.DisplayName .. "\nAVAILABLE", Color3.fromRGB(160, 220, 185))

		for _, offset in ipairs({-8, 8}) do
			createTank(room, Vector3.new(roomCenter.X + side * offset, 2.1, roomCenter.Z + offset * 0.5))
		end
		for zOffset = -10, 10, 10 do
			createPart(room, "WallCable", Vector3.new(0.25, 0.25, 8), CFrame.new(roomCenter.X - side * 8, 12, roomCenter.Z + zOffset), Color3.fromRGB(23, 25, 24), Enum.Material.SmoothPlastic)
		end
		createCeilingLight(room, Vector3.new(roomCenter.X, roomHeight - 0.4, roomCenter.Z), Color3.fromRGB(210, 218, 210))
		createRail(room, Vector3.new(roomCenter.X - side * 9, 2.4, roomCenter.Z - 10.5), 12, "Z")
		createRail(room, Vector3.new(roomCenter.X - side * 9, 2.4, roomCenter.Z + 10.5), 12, "Z")

		local promptPart = createPart(interactables, portalConfig.Id .. "_Prompt", Vector3.new(3, 2, 0.4), CFrame.new(innerWallX - side * 0.8, 3, roomCenter.Z + 5), Color3.fromRGB(25, 30, 28), Enum.Material.Metal, 0.05, false)
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PortalPrompt"
		prompt.ActionText = "Open Session Panel"
		prompt.ObjectText = portalConfig.DisplayName
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = 0.35
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart

		local spawnFolder = Instance.new("Folder")
		spawnFolder.Name = portalConfig.Id .. "_TeamSpawns"
		spawnFolder.Parent = room
		for slot = 1, Config.Game.MaxPlayersPerSession do
			local spawn = createPart(spawnFolder, "TeamSpawn_" .. slot, Vector3.new(1, 0.2, 1), CFrame.new(roomCenter.X - side * (roomWidth / 2 - 5), 0.3, roomCenter.Z - 5 + slot * 2.4), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 1, false)
			spawn.CanQuery = false
			self.SpawnLocations[portalConfig.Id] = self.SpawnLocations[portalConfig.Id] or {}
			self.SpawnLocations[portalConfig.Id][slot] = spawn
		end

		self.Portals[portalConfig.Id] = {
			Config = portalConfig,
			Room = room,
			Prompt = prompt,
			PortalField = portalField,
			Indicator = indicator,
			StatusLabel = statusLabel,
			RoomCenter = roomCenter,
		}
		self.Prompts[portalConfig.Id] = prompt
	end

	local entrance = Instance.new("Model")
	entrance.Name = "SecurityArrival"
	entrance.Parent = root
	createPart(entrance, "ArrivalFloor", Vector3.new(28, 0.35, 16), CFrame.new(0, -0.1, -70), V.Floor, Enum.Material.Concrete)
	createPart(entrance, "ArrivalBackWall", Vector3.new(28, 14, 0.6), CFrame.new(0, 7, -78), V.Panel, Enum.Material.Metal)
	createPart(entrance, "ArrivalGlass", Vector3.new(26, 5, 0.15), CFrame.new(0, 11, -61.8), Color3.fromRGB(100, 140, 140), Enum.Material.Glass, 0.5, true)
	createLabel(createPart(entrance, "ArrivalSign", Vector3.new(5, 0.4, 0.15), CFrame.new(0, 11, -77.5), Color3.fromRGB(37, 48, 42), Enum.Material.Metal, 0, false), "ASYNC FACILITY\nTHRESHOLD WING", Color3.fromRGB(185, 218, 194))

	createPart(entrance, "ArrivalRoof", Vector3.new(28,0.5,22), CFrame.new(0,14,-67), V.Panel)
	for _, side in ipairs({-1,1}) do
		createPart(entrance,"ArrivalSideWall",Vector3.new(0.7,14,22),CFrame.new(side*14,7,-67),V.Panel)
		createPart(entrance,"ArrivalFrontWing",Vector3.new(7,14,0.7),CFrame.new(side*10.5,7,-56),V.Panel)
		for z=-74,-66,4 do
			createPart(entrance,"EquipmentLocker",Vector3.new(2,6,2.7),CFrame.new(side*12.5,3,z),V.Metal)
		end
	end
	createCeilingLight(entrance, Vector3.new(0,13.7,-70))
	local archiveSign = createPart(entrance, "ArchiveSign", Vector3.new(5.5, 0.25, 0.12), CFrame.new(7.8, 8.5, -72), Color3.fromRGB(39, 52, 46), Enum.Material.Metal, 0, false)
	createLabel(archiveSign, "ARCHIVE / LOGS", Color3.fromRGB(175, 210, 185))
	local equipmentSign = createPart(entrance, "EquipmentSign", Vector3.new(5.5, 0.25, 0.12), CFrame.new(-7.8, 8.5, -72), Color3.fromRGB(39, 52, 46), Enum.Material.Metal, 0, false)
	createLabel(equipmentSign, "EQUIPMENT / ISSUE", Color3.fromRGB(175, 210, 185))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Size = Vector3.new(5, 0.5, 5)
	spawn.CFrame = hub.SpawnCFrame
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Parent = root
	self.HubSpawn = spawn

	createCameraPoint(cameraPoints, "IntroStart", CFrame.new(0, 7, -74) * CFrame.Angles(0, 0, 0))
	createCameraPoint(cameraPoints, "IntroCorridor", CFrame.new(0, 8, -35) * CFrame.Angles(0, math.rad(180), 0))
	createCameraPoint(cameraPoints, "IntroOverview", CFrame.new(0, 8, -12) * CFrame.Angles(math.rad(-8), math.rad(180), 0))
	createCameraPoint(cameraPoints, "SpawnView", CFrame.new(0, 4, -63) * CFrame.Angles(0, math.rad(180), 0))

	return self
end

function HubBuilder:SetPortalState(portalId, state, session)
	local portal = self.Portals[portalId]
	if not portal then
		return
	end

	local color = V.PortalIdle
	local indicatorColor = Color3.fromRGB(90, 210, 125)
	local status = "AVAILABLE"
	if state == "WAITING" then
		color = Color3.fromRGB(165, 175, 130)
		indicatorColor = Color3.fromRGB(225, 185, 65)
		status = string.format("WAITING %d/%d", session and #session.Players or 0, (session and session.Capacity or Config.Game.MaxPlayersPerSession))
	elseif state == "STARTING" or state == "TELEPORTING" or state == "ACTIVE" then
		color = V.PortalActive
		indicatorColor = Color3.fromRGB(90, 170, 255)
		status = state == "ACTIVE" and "PORTAL ACTIVE" or state
	elseif state == "ALERT" then
		color = Color3.fromRGB(255, 100, 80)
		indicatorColor = V.EmergencyRed
		status = "CONTAINMENT ALERT"
	end

	portal.Room:SetAttribute("PortalState", state)
	portal.PortalField.Color = color
	portal.PortalField.Transparency = state == "ACTIVE" and 0.18 or 0.75
	portal.Indicator.Color = indicatorColor
	portal.StatusLabel.Text = portal.Config.DisplayName .. "\n" .. status
	portal.StatusLabel.TextColor3 = indicatorColor
	end

return HubBuilder
