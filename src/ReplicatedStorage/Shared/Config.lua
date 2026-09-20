local Config = {}

Config.Game = {
	Name = "ASYNC: THE COMPLEX",
	Version = "Hub Vertical Slice 0.2.0",
	MaxPlayersPerSession = 4,
	PortalCount = 6,
	SessionCountdownSeconds = 30,
	SessionAutoStartWhenFull = true,
	IntroDurationSeconds = 8,
}

Config.Hub = {
	CorridorLength = 112,
	CorridorWidth = 14,
	CorridorHeight = 20,
	PortalRoomWidth = 28,
	PortalRoomDepth = 34,
	PortalRoomHeight = 20,
	RoomSpacing = 38,
	SideOffset = 25,
	PortalWidth = 9,
	PortalHeight = 14,
	WallThickness = 1.2,
	FloorThickness = 0.6,
	SpawnCFrame = CFrame.new(0, 0.5, -70) * CFrame.Angles(0, math.pi, 0),
}

Config.Portals = {
	{Id = "P01", DisplayName = "THRESHOLD 01", DefaultLevel = "LEVEL_0", Accent = Color3.fromRGB(160, 190, 210)},
	{Id = "P02", DisplayName = "THRESHOLD 02", DefaultLevel = "LEVEL_1", Accent = Color3.fromRGB(180, 150, 100)},
	{Id = "P03", DisplayName = "THRESHOLD 03", DefaultLevel = "LEVEL_2", Accent = Color3.fromRGB(110, 150, 180)},
	{Id = "P04", DisplayName = "THRESHOLD 04", DefaultLevel = "LEVEL_3", Accent = Color3.fromRGB(190, 120, 90)},
	{Id = "P05", DisplayName = "THRESHOLD 05", DefaultLevel = "LEVEL_5", Accent = Color3.fromRGB(180, 180, 150)},
	{Id = "P06", DisplayName = "THRESHOLD 06", DefaultLevel = "LEVEL_6", Accent = Color3.fromRGB(120, 130, 160)},
}

Config.Levels = {
	LEVEL_0 = {Id = "LEVEL_0", Name = "YELLOW ROOMS", Status = "AVAILABLE", Unlocked = true},
	LEVEL_1 = {Id = "LEVEL_1", Name = "HABITABLE ZONE", Status = "LOCKED", Unlocked = false},
	LEVEL_2 = {Id = "LEVEL_2", Name = "UTILITY HALLS", Status = "LOCKED", Unlocked = false},
	LEVEL_3 = {Id = "LEVEL_3", Name = "ELECTRICAL STATION", Status = "LOCKED", Unlocked = false},
	LEVEL_5 = {Id = "LEVEL_5", Name = "TERROR HOTEL", Status = "LOCKED", Unlocked = false},
	LEVEL_6 = {Id = "LEVEL_6", Name = "LIGHTS OUT", Status = "LOCKED", Unlocked = false},
}

Config.Visuals = {
	Wall = Color3.fromRGB(103, 105, 100),
	Panel = Color3.fromRGB(179, 183, 176),
	Brick = Color3.fromRGB(103, 88, 78),
	Metal = Color3.fromRGB(55, 60, 59),
	Floor = Color3.fromRGB(62, 63, 58),
	SafetyYellow = Color3.fromRGB(211, 164, 43),
	EmergencyRed = Color3.fromRGB(180, 30, 25),
	PortalIdle = Color3.fromRGB(105, 125, 135),
	PortalActive = Color3.fromRGB(185, 225, 255),
}

Config.Teleport = {
	Enabled = false,
	PlaceId = 0,
}

Config.Audio = { AmbientId = "", ActivationId = "" } -- Supply audio assets owned/authorized by your experience.

return Config
