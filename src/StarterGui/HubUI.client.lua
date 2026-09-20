local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local UserInputService=game:GetService("UserInputService")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("AsyncRemotes")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local gui=Instance.new("ScreenGui")
gui.Name="AsyncHubUI"; gui.ResetOnSpawn=false; gui.DisplayOrder=10; gui.Parent=player:WaitForChild("PlayerGui")
local ink=Color3.fromRGB(210,220,207)
local dark=Color3.fromRGB(17,22,20)
local muted=Color3.fromRGB(115,140,122)
local function make(class,props,parent)
	local obj=Instance.new(class)
	for k,v in pairs(props) do obj[k]=v end
	obj.Parent=parent
	return obj
end
local function label(parent,text,pos,size,fontSize)
	return make("TextLabel",{Text=text,Position=pos,Size=size,BackgroundTransparency=1,TextColor3=ink,Font=Enum.Font.Code,TextSize=fontSize or 14,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local function button(parent,text,pos,size,callback)
	local b=make("TextButton",{Text=text,Position=pos,Size=size,BackgroundColor3=Color3.fromRGB(37,49,41),TextColor3=ink,Font=Enum.Font.Code,TextSize=14,BorderSizePixel=0},parent)
	make("UICorner",{CornerRadius=UDim.new(0,3)},b)
	b.Activated:Connect(callback)
	return b
end
local top=make("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=dark,BackgroundTransparency=0.12,BorderSizePixel=0},gui)
label(top,"ASYNC  /  THRESHOLD WING",UDim2.fromOffset(14,0),UDim2.new(0.62,0,1,0),14)
local low=UserInputService.TouchEnabled
player:SetAttribute("LowGraphics",low)
local quality
quality=button(top,low and "FX: LOW" or "FX: HIGH",UDim2.new(1,-108,0,7),UDim2.fromOffset(96,30),function()
	low=not low; player:SetAttribute("LowGraphics",low); quality.Text=low and "FX: LOW" or "FX: HIGH"
end)
local status=label(gui,"RECEPTION  /  FIND A THRESHOLD TERMINAL",UDim2.fromOffset(14,50),UDim2.new(1,-28,0,28),13)
local sessionBar=button(gui,"OPEN MY SESSION",UDim2.fromOffset(14,84),UDim2.fromOffset(220,36),function() end)
sessionBar.Visible=false
local panel=make("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.52),Size=UDim2.fromOffset(440,560),BackgroundColor3=dark,BorderSizePixel=0,Visible=false},gui)
make("UIStroke",{Color=muted,Thickness=1},panel)
local scale=make("UIScale",{Scale=1},panel)
local function resize()
	local v=workspace.CurrentCamera.ViewportSize
	scale.Scale=math.min(1,(v.X-24)/440,(v.Y-64)/560)
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize); resize()
local title=label(panel,"CREATE EXPLORATION SESSION",UDim2.fromOffset(18,10),UDim2.fromOffset(360,32),17)
button(panel,"X",UDim2.fromOffset(394,12),UDim2.fromOffset(30,30),function() panel.Visible=false end)
local detail=label(panel,"",UDim2.fromOffset(18,46),UDim2.fromOffset(400,46),13)
local levels=make("ScrollingFrame",{Position=UDim2.fromOffset(18,100),Size=UDim2.fromOffset(404,162),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.fromOffset(0,204)},panel)
local capacity=4
local visibility="Public"
local selected="LEVEL_0"
local currentId
local states={}
local mySession
local refresh
local capButton
capButton=button(panel,"CAPACITY: 4",UDim2.fromOffset(18,276),UDim2.fromOffset(190,36),function()
	if not mySession and not (states[currentId] and states[currentId].Session) then capacity=capacity%4+1; capButton.Text="CAPACITY: "..capacity end
end)
local privacyButton
privacyButton=button(panel,"PUBLIC",UDim2.fromOffset(220,276),UDim2.fromOffset(202,36),function()
	if mySession or (states[currentId] and states[currentId].Session) then return end
	local nextMode={Public="Friends",Friends="Private",Private="Public"}
	visibility=nextMode[visibility]; privacyButton.Text=visibility:upper()
end)
local code=make("TextBox",{Position=UDim2.fromOffset(18,322),Size=UDim2.fromOffset(404,34),PlaceholderText="Private join code (from host)",Text="",ClearTextOnFocus=false,TextColor3=ink,PlaceholderColor3=muted,BackgroundColor3=Color3.fromRGB(29,34,30),Font=Enum.Font.Code,TextSize=14,BorderSizePixel=0},panel)
local roster=label(panel,"",UDim2.fromOffset(18,364),UDim2.fromOffset(404,62),12)
local function request(action,extra)
	local data=extra or {}; data.Action=action; remotes.PortalRequest:FireServer(data)
end
local join=button(panel,"CREATE / JOIN",UDim2.fromOffset(18,436),UDim2.fromOffset(195,42),function()
	if currentId then request("Join",{PortalId=currentId,Capacity=capacity,Visibility=visibility,LevelId=selected,Code=code.Text:upper():sub(1,8)}) end
end)
button(panel,"LEAVE / RETURN",UDim2.fromOffset(225,436),UDim2.fromOffset(197,42),function() request("Leave") end)
local start=button(panel,"START AS HOST",UDim2.fromOffset(18,488),UDim2.fromOffset(250,42),function() request("Start") end)
button(panel,"SHOW CODE",UDim2.fromOffset(280,488),UDim2.fromOffset(142,42),function() request("Code") end)
local buttons={}
local order={"LEVEL_0","LEVEL_1","LEVEL_2","LEVEL_3","LEVEL_4","LEVEL_5","LEVEL_6"}
for i,id in ipairs(order) do
	local level=Config.Levels[id]
	buttons[id]=button(levels,id.."  "..level.Name..(level.Unlocked and "" or " [LOCKED]"),UDim2.fromOffset(0,(i-1)*34),UDim2.fromOffset(394,30),function()
		if not level.Unlocked then return end
		selected=id
		if mySession and mySession.PortalId==currentId then request("SetLevel",{LevelId=id}) end
		refresh()
	end)
	buttons[id].TextSize=12
end
refresh=function()
	local state=states[currentId]
	if not state then return end
	local s=state.Session
	local member=mySession and mySession.PortalId==currentId
	local host=s and s.HostUserId==player.UserId
	title.Text=state.DisplayName
	detail.Text=string.format("%s  /  %d OF %d\n%s",state.State,state.Players,state.MaxPlayers,s and (s.Id.."  /  "..s.Visibility.."  /  "..(s.State=="WAITING" and (s.Countdown.."s") or s.State)) or "CREATE EXPLORATION SESSION")
	capButton.Text="CAPACITY: "..(s and s.Capacity or capacity)
	privacyButton.Text=(s and s.Visibility or visibility):upper()
	join.Text=member and "SESSION JOINED" or s and "JOIN SESSION" or "CREATE SESSION"
	start.Text=host and "START AS HOST" or "HOST START CONTROL"
	start.BackgroundColor3=host and Color3.fromRGB(55,73,61) or Color3.fromRGB(27,32,29)
	local names={}
	if s then for _, p in ipairs(s.Players) do table.insert(names,(p.UserId==s.HostUserId and "[HOST] " or "")..p.Name) end end
	roster.Text=table.concat(names,"   /   ")
	for id,b in pairs(buttons) do b.BackgroundColor3=id==(s and s.Level or selected) and Color3.fromRGB(65,77,55) or Color3.fromRGB(30,38,33) end
end
sessionBar.Activated:Connect(function()
	if mySession then currentId=mySession.PortalId; refresh(); panel.Visible=true end
end)
remotes.OpenPortalPanel.OnClientEvent:Connect(function(data)
	currentId=data.PortalId; states[currentId]=data; refresh(); panel.Visible=true
end)
remotes.PortalState.OnClientEvent:Connect(function(data)
	states=data
	if currentId then refresh() end
end)
remotes.SessionUpdate.OnClientEvent:Connect(function(data)
	mySession=not data.Cleared and data or nil
	sessionBar.Visible=mySession~=nil
	if mySession then
		sessionBar.Text=mySession.Id.." / "..mySession.State
		status.Text=mySession.State=="WAITING" and ("DEPARTURE IN "..mySession.Countdown.."s") or "THRESHOLD TEST / RETURN USING SESSION PANEL"
	else status.Text="RECEPTION / FIND A THRESHOLD TERMINAL" end
	if currentId then refresh() end
end)
local notice=label(gui,"",UDim2.new(0.05,0,1,-100),UDim2.new(0.9,0,0,66),14)
notice.BackgroundColor3=dark; notice.BackgroundTransparency=0.08; notice.Visible=false
local noticeId=0
remotes.Toast.OnClientEvent:Connect(function(data)
	noticeId+=1; local id=noticeId
	notice.Text=data.Message; notice.Visible=true
	notice.TextColor3=data.Kind=="ERROR" and Color3.fromRGB(230,130,110) or ink
	task.delay(8,function() if id==noticeId then notice.Visible=false end end)
end)
local bars={}
for _, bottom in ipairs({false,true}) do
	local bar=make("Frame",{Size=UDim2.new(1,0,0,38),Position=bottom and UDim2.new(0,0,1,-38) or UDim2.fromOffset(0,0),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,Visible=false,ZIndex=20},gui)
	table.insert(bars,bar)
end
player:GetAttributeChangedSignal("CinematicPlaying"):Connect(function()
	local active=player:GetAttribute("CinematicPlaying")==true
	for _,bar in ipairs(bars) do bar.Visible=active end
	if active then panel.Visible=false end
end)
-- Both client scripts must have listeners before the server sends the one-shot intro.
while not player:GetAttribute("CameraReady") do task.wait() end
local character=player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
workspace:WaitForChild("AsyncHub"):WaitForChild("SecurityArrival")
remotes.ClientReady:FireServer()
