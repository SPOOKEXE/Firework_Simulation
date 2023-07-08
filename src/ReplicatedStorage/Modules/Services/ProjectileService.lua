
--[[
	ProjectileService:
	- Coded by SPOOK_EXE

	Features:
	- Physics-Based Projectiles
	- Raycast-Stepping
	- Global & Local Acceleration
	- Global & Local Time Scale
	- Editable Step Iteration
	- Enable/Disable Lifetime Stepping
	- Projectile Lifetime
]]

local RunService = game:GetService('RunService')
local HttpService = game:GetService('HttpService')

local EventClassModule = require(script.Parent.Parent.Classes.Event)
local VisualizersModule = require(script.Parent.Parent.Utility.Visualizers)

local ACTIVE_PROJECTILE_INSTANCES = {}
local INVALID_RAY_CALLBACK_MSG = "RayOnHitCallback called with invalid parameters; expecting type 'function' but got type %s. Using default callback."

local GLOBAL_TIME_SCALE = 1
local GLOBAL_ACCELERATION = -Vector3.new( 0, workspace.Gravity * 0.15, 0 )
local STEP_ITERATIONS = 1

local function GetPositionAtTime(time: number, origin: Vector3, initialVelocity: Vector3, acceleration: Vector3) : Vector3
	return origin + (initialVelocity * time) + Vector3.new(acceleration.X, acceleration.Y, acceleration.Z ) * (math.pow(time, 2) / 2)
end

local function GetVelocityAtTime(time: number, initialVelocity: Vector3, acceleration: Vector3) : Vector3
	return initialVelocity + (acceleration * time)
end

local function DEFAULT_RAY_HIT( _, raycastResult )
	return raycastResult ~= nil
end

local DEFAULT_RAYCAST_PARAMS = RaycastParams.new()
DEFAULT_RAYCAST_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
DEFAULT_RAYCAST_PARAMS.IgnoreWater = true

-- // Projectile // --
local ProjectileClass = {}
ProjectileClass.__index = ProjectileClass

function ProjectileClass.New( Origin, Velocity )
	local self = setmetatable({
		Enabled = true,
		IsUpdating = false,
		Destroyed = false,

		TimeElapsed = 0,
		DelayTime = 0,
		Lifetime = 3,

		Position = Origin,
		Velocity = Velocity,
		Acceleration = Vector3.zero,

		OnRayHit = DEFAULT_RAY_HIT,
		OnHitEvent = EventClassModule.New(),
		OnUpdatedEvent = EventClassModule.New(),
		OnTerminatedEvent = EventClassModule.New(),

		UserData = { UUID = HttpService:GenerateGUID(false), },
		RaycastParams = DEFAULT_RAYCAST_PARAMS,

		_initPosition = Origin,
		_initVelocity = Velocity,

		DebugVisuals = false, -- visualize with beams
		DebugData = false, -- do we store DebugStep data
		DebugSteps = nil, -- DebugStep data (projectile path with info)
	}, ProjectileClass)
	self:Update(0)
	return self
end

function ProjectileClass:Update(deltaTime)
	self.TimeElapsed += deltaTime
	if self.Lifetime and (self.TimeElapsed > self.Lifetime) then
		self:Destroy()
		return
	end

	if self.DelayTime > 0 then
		self.DelayTime -= deltaTime
		if self.DelayTime > 0 then
			return
		end
	end

	local netAcceleration = (self.Acceleration + GLOBAL_ACCELERATION)
	local nextPosition = GetPositionAtTime( deltaTime, self.Position, self.Velocity, netAcceleration)
	local nextVelocity = GetVelocityAtTime( deltaTime, self.Velocity, netAcceleration)

	local rayDirection = self.Velocity * deltaTime
	local raycastResult = workspace:Raycast( self.Position, rayDirection, self.RaycastParams or DEFAULT_RAYCAST_PARAMS )

	if self.DebugVisuals then
		local Point = Instance.new('Attachment')
		Point.Visible = false
		Point.WorldPosition = self.Position
		Point.Parent = workspace.Terrain
		VisualizersModule:Beam(
			self.Position,
			self.Position + rayDirection,
			4,
			{ Color = ColorSequence.new(Color3.new(1, 1, 1))
		})
	end

	local killProjectile = self.OnRayHit and self.OnRayHit( self, raycastResult ) or false

	local beforePosition = self.Position
	local beforeVelocity = self.Velocity
	if killProjectile then
		self.Position = raycastResult and raycastResult.Position or nextPosition
		self.Velocity = Vector3.new()
		self.OnHitEvent:Fire(self, raycastResult)
	else
		self.Position = nextPosition
		self.Velocity = nextVelocity
	end

	local stepData = {
		DeltaTime = deltaTime,
		TimeElapsed = self.TimeElapsed,
		BeforePosition = beforePosition,
		BeforeVelocity = beforeVelocity,
		AfterPosition = self.Position,
		AfterVelocity = self.Velocity,
	}

	if self.DebugData then
		if self.DebugSteps then
			table.insert(self.DebugSteps, stepData)
		else
			self.DebugSteps = { stepData }
		end
	end

	self.OnUpdatedEvent:Fire(self, stepData)

	if killProjectile then
		self:Destroy()
	end
end

function ProjectileClass:SetEnabled( enabled )
	self.Enabled = (enabled==true)
end

function ProjectileClass:SetRayOnHitCallback( func )
	if typeof(func) == 'function' then
		self.OnRayHit = func
	else
		warn( string.format(INVALID_RAY_CALLBACK_MSG, typeof(func)) )
		self.OnRayHit = DEFAULT_RAY_HIT
	end
end

function ProjectileClass:AddAccelerate( acceleration : Vector3 )
	self.Acceleration += acceleration
end

function ProjectileClass:SetAcceleration( acceleration : Vector3 )
	self.Acceleration = acceleration
end

function ProjectileClass:IsDestroyed()
	return self.Destroyed == true
end

function ProjectileClass:Destroy()
	if (not self:IsDestroyed()) and self.OnTerminatedEvent then
		self.OnTerminatedEvent:Fire(self)
	end
	self.Destroyed = true
end

function ProjectileClass:IsInResolver()
	-- find the index of this table
	return table.find(ACTIVE_PROJECTILE_INSTANCES, self)
end

function ProjectileClass:AddToResolver()
	-- if not within the global resolver, add it
	if not self:IsInResolver() then
		table.insert(ACTIVE_PROJECTILE_INSTANCES, self)
	end
end

function ProjectileClass:RemoveFromResolver()
	-- remove all occurances of this projectile from the resolver
	local index = self:IsInResolver()
	while index do
		table.remove(ACTIVE_PROJECTILE_INSTANCES, index)
		index = self:IsInResolver()
	end
end

-- // Module // --
local Module = {}

Module.ProjectileClass = ProjectileClass

--[[
	main projectile updater;
		- updates each projectile in a new thread
		- utilizes IsUpdating flag to only update
			projectiles when they are not busy.
]]
function Module:_StepProjectiles(deltaTime)
	deltaTime *= GLOBAL_TIME_SCALE
	local step_iter_delta_time = (deltaTime / STEP_ITERATIONS)

	local index = 1
	while index <= #ACTIVE_PROJECTILE_INSTANCES do
		local projectileClass = ACTIVE_PROJECTILE_INSTANCES[index]
		if projectileClass:IsDestroyed() then
			table.remove(ACTIVE_PROJECTILE_INSTANCES, index)
			continue
		end
		if projectileClass.Enabled and (not projectileClass.IsUpdating) then
			projectileClass.IsUpdating = true
			task.defer(function()
				for _ = 1, STEP_ITERATIONS do
					projectileClass:Update(step_iter_delta_time)
				end
				projectileClass.IsUpdating = false
			end)
		end
		index += 1
	end

	print(#ACTIVE_PROJECTILE_INSTANCES)
end

function Module:StartResolver() : RBXScriptConnection
	return RunService.Heartbeat:Connect(function(deltaTime)
		Module:_StepProjectiles(deltaTime)
	end)
end

function Module:SetGlobalAcceleration( AccelerationVector3 )
	GLOBAL_ACCELERATION = AccelerationVector3
end

function Module:SetGlobalTimeScale( newTimeScale )
	GLOBAL_TIME_SCALE = newTimeScale
end

function Module:SetStepIterations( newCount )
	STEP_ITERATIONS = newCount
end

function Module:RemoveProjectilesFromUUID( projectileUUID )
	for _, projectileData in ipairs( ACTIVE_PROJECTILE_INSTANCES ) do
		if projectileData.UserData and projectileData.UserData.UUID == projectileUUID then
			projectileData:Destroy()
			break
		end
	end
end

return Module
