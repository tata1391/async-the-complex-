local TweenService = game:GetService("TweenService")
local HubEffects = {}
HubEffects.__index = HubEffects

function HubEffects.new(hub)
	return setmetatable({Hub=hub, Running=false, Lights={}}, HubEffects)
end

function HubEffects:Start()
	if self.Running then return end
	self.Running=true
	for _, object in ipairs(self.Hub.Root:GetDescendants()) do
		if object:IsA("PointLight") and object.Name=="CeilingLight" then table.insert(self.Lights,object) end
	end
	task.spawn(function()
		while self.Running and self.Hub.Root.Parent do
			task.wait(math.random(12,22))
			if #self.Lights==0 then continue end
			local light=self.Lights[math.random(1,#self.Lights)]
			local original=light.Brightness
			for _=1,math.random(2,4) do
				light.Brightness=0.05
				task.wait(math.random(5,12)/100)
				light.Brightness=original
				task.wait(math.random(5,18)/100)
			end
		end
	end)
end

function HubEffects:Stop()
	self.Running=false
end
return HubEffects
