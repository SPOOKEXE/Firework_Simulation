local HttpService = game:GetService("HttpService")

local EventClass = require(script.Parent.Event)

local function SetProperties(Parent, Properties)
	for propName, propValue in pairs( Properties ) do
		Parent[propName] = propValue
	end
end

-- // Firework // --
local Firework = {}
Firework.__index = Firework
Firework.__tostring = Firework.ToJSON

function Firework.New()
	return setmetatable({
		UUID = HttpService:GenerateGUID(false),
		Model = false,

		Enabled = true,
		KeyFrameStart = 0,
		FireworkData = {

		},

		Events = {
			OnEnabledUpdated = EventClass.New(),
			OnModelUpdated = EventClass.New(),
			OnModelChanged = EventClass.New(),
			OnDataUpdated = EventClass.New(),
		},
	}, Firework)
end

function Firework:ToJSON()
	return HttpService:JSONEncode({
		Enabled = self.Enabled,
		Data = self.Data
	})
end

function Firework:FromJSON( data )
	for propName, propValue in pairs( HttpService:JSONDecode(data) ) do
		if propName == "Data" then
			SetProperties(self.Data, propValue)
		else
			self[propName] = propValue
		end
	end
end

function Firework:Enable()
	self.Enabled = true
	self.Events.OnEnabledUpdated:Fire(true)
end

function Firework:Disable()
	self.Enabled = false
	self.Events.OnEnabledUpdated:Fire(false)
end

function Firework:SetModelInstance( Model )
	self.Model = Model
	self.Events.OnModelChanged:Fire(Model)
end

function Firework:PivotTo( PivotCF )
	if typeof(self.Model) == "Instance" then
		self.Model:PivotTo( PivotCF )
		self.Events.OnModelUpdated:Fire()
	end
end

function Firework:SetKeyFrameStart( timeValue )
	self.KeyFrameStart = timeValue
	self.Events.OnDataUpdated:Fire("KeyFrameStart", timeValue)
end

-- // Simulation // --
local Simulation = {}
Simulation.__index = Simulation
Simulation.__tostring = Simulation.ToJSON

function Simulation.New()
	local self = setmetatable({
		UUID = HttpService:GenerateGUID(false),

		Fireworks = { },

		CurrentTimeValue = 0,
		TotalTimeDuration = 0,

		Events = {
			OnTimeValueUpdated = EventClass.New(),
			OnTotalValueUpdated = EventClass.New(),
			OnFireworkAdded = EventClass.New(),
			OnFireworkRemoved = EventClass.New(),
		},
	}, Simulation)
	self:SetTimeValue(0)
	return self
end

function Simulation:OnEvent( eventName, callback )
	return self.Events[eventName]:Connect(callback)
end

function Simulation:ToJSON()
	return HttpService:JSONEncode({
		Fireworks = self.Fireworks,
		TotalTimeDuration = self.TotalTimeDuration,
	})
end

function Simulation:FromJSON( data )
	for propName, propValue in pairs( HttpService:JSONDecode(data) ) do
		if propName == "Fireworks" then
			for _, fireworkData in ipairs( propValue ) do
				table.insert(self.Fireworks, Firework:FromJSON( fireworkData ))
			end
		else
			self[propName] = propValue
		end
	end
end

function Simulation:SetTimeValue( timeValue )
	self.CurrentTimeValue = timeValue
end

function Simulation:SetMaxDuration( timeValue )
	self.TotalTimeDuration = timeValue
end

return { Firework = Firework, Simulation = Simulation }
