
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedModules = require(ReplicatedStorage:WaitForChild("Modules"))

local FireworksClassModule = ReplicatedModules.Classes.Fireworks

local SystemsContainer = {}

-- // Module // --
local Module = {}

Module.FireworkTracks = { }
Module.ActiveFireworkTrack = false

function Module:SetFireworkTrack( UUID )

end

function Module:CreateNewFireworkTrack(  )
	local Track = FireworksClassModule.Simulation.New()
	table.insert(Module.FireworkTracks, Track)
	return Track
end

function Module:CreateFireworkInstance()

end

function Module:LoadFromJSON()

end

function Module:SaveToJSON()
	local Tracks = {}
	for _, trackClass in ipairs( Module.FireworkTracks ) do
		table.insert(Tracks, trackClass:ToJSON())
	end
	return Tracks
end

function Module:Start()

end

function Module:Init(otherSystems)
	SystemsContainer = otherSystems
end

return Module
