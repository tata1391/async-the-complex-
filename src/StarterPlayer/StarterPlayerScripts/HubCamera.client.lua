local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local ContextActionService=game:GetService("ContextActionService")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("AsyncRemotes")
local serial=0
local cleanup

local function stop()
	serial+=1
	if cleanup then local f=cleanup; cleanup=nil; f() end
end
local function play(frames)
	stop()
	local token=serial
	local camera=workspace.CurrentCamera
	local character=player.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local walk,jump,height,rotate=humanoid.WalkSpeed,humanoid.JumpPower,humanoid.JumpHeight,humanoid.AutoRotate
	local fov=camera.FieldOfView
	local tween
	cleanup=function()
		if tween then tween:Cancel() end
		ContextActionService:UnbindAction("AsyncSkip")
		humanoid.WalkSpeed=walk; humanoid.JumpPower=jump; humanoid.JumpHeight=height; humanoid.AutoRotate=rotate
		camera.CameraType=Enum.CameraType.Custom
		camera.CameraSubject=player.Character and player.Character:FindFirstChildOfClass("Humanoid") or humanoid
		camera.FieldOfView=fov
		player:SetAttribute("CinematicPlaying",false)
	end
	humanoid.WalkSpeed=0; humanoid.JumpPower=0; humanoid.JumpHeight=0; humanoid.AutoRotate=false
	player:SetAttribute("CinematicPlaying",true)
	camera.CameraType=Enum.CameraType.Scriptable
	camera.FieldOfView=62
	ContextActionService:BindAction("AsyncSkip",function(_,state)
		if state==Enum.UserInputState.Begin then stop() end
		return Enum.ContextActionResult.Sink
	end,true,Enum.KeyCode.Space,Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("AsyncSkip","SKIP")
	ContextActionService:SetPosition("AsyncSkip",UDim2.fromScale(0.8,0.15))
	camera.CFrame=frames[1].Frame
	for i=2,#frames do
		if token~=serial then return end
		tween=TweenService:Create(camera,TweenInfo.new(frames[i].Duration,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=frames[i].Frame})
		tween:Play(); tween.Completed:Wait()
	end
	if token==serial then stop() end
end

remotes.PlayHubIntro.OnClientEvent:Connect(function()
	play({
		{Frame=CFrame.lookAt(Vector3.new(0,6,-74),Vector3.new(0,6,-45))},
		{Frame=CFrame.lookAt(Vector3.new(0,7,-42),Vector3.new(-16,7,-38)),Duration=3},
		{Frame=CFrame.lookAt(Vector3.new(0,7,-18),Vector3.new(16,7,0)),Duration=3},
		{Frame=CFrame.lookAt(Vector3.new(0,7,-14),Vector3.new(0,6,30)),Duration=2},
	})
end)
remotes.PortalCinematic.OnClientEvent:Connect(function(payload)
	local hub=workspace:FindFirstChild("AsyncHub")
	local room=hub and hub:FindFirstChild(payload.PortalId.."_Room")
	local field=room and room:FindFirstChild("PortalField")
	if not field then return end
	local sign=field.Position.X<0 and -1 or 1
	local target=field.Position
	play({{Frame=CFrame.lookAt(target+Vector3.new(-sign*19,2,4),target)},
		{Frame=CFrame.lookAt(target+Vector3.new(-sign*13,0.5,2),target),Duration=4},
		{Frame=CFrame.lookAt(target+Vector3.new(-sign*8,0,0),target),Duration=3}})
end)
player.CharacterAdded:Connect(stop)
player:GetAttributeChangedSignal("AsyncSessionId"):Connect(function()
	if not player:GetAttribute("AsyncSessionId") then stop() end
end)
player:SetAttribute("CameraReady",true)
