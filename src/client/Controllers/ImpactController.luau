local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RagdollConfig = require(ReplicatedStorage.Shared.Config.RagdollConfig)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)

local ImpactController = {}

local HEAR_DISTANCE = 140
local OWNER_COOLDOWN = 0.09

type Tracked = {
	Owner: Instance,
	Kind: string,
}

local lastVelocity: { [BasePart]: Vector3 } = {}
local lastSound: { [Instance]: number } = setmetatable({}, { __mode = "k" }) :: any
local inWater: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function isLimp(character: Model): boolean
	if character:GetAttribute("Ragdolled") then
		return true
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health <= 0
end

local function collect(): { [BasePart]: Tracked }
	local result = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and isLimp(character) then
			for _, child in character:GetChildren() do
				if child:IsA("BasePart") and child.Name ~= "HumanoidRootPart" then
					result[child] = { Owner = character, Kind = "Body" }
				end
			end
		end
	end
	for _, prop in CollectionService:GetTagged("ZMProp") do
		if prop:IsA("BasePart") and prop:IsDescendantOf(workspace) then
			result[prop] = { Owner = prop, Kind = "Prop" }
		end
	end
	return result
end

local function insideWater(position: Vector3): boolean
	for _, water in CollectionService:GetTagged("ZMWater") do
		if water:IsA("BasePart") then
			local point = water.CFrame:PointToObjectSpace(position)
			local half = water.Size / 2
			if math.abs(point.X) <= half.X and math.abs(point.Y) <= half.Y and math.abs(point.Z) <= half.Z then
				return true
			end
		end
	end
	return false
end

local function playImpact(part: BasePart, info: Tracked, jolt: number)
	local now = os.clock()
	if now - (lastSound[info.Owner] or 0) < OWNER_COOLDOWN then
		return
	end
	lastSound[info.Owner] = now

	local volume = math.clamp(jolt / RagdollConfig.ImpactHardSpeed, 0.3, 1)
	if info.Kind == "Prop" then
		SoundPlayer.Play("PropImpact", part, volume)
		return
	end
	if jolt >= RagdollConfig.ImpactBreakSpeed and SoundPlayer.Has("BodyBreak") then
		SoundPlayer.Play("BodyBreak", part)
	end
	if jolt >= RagdollConfig.ImpactHardSpeed then
		SoundPlayer.Play("BodyImpactHard", part, volume)
	else
		SoundPlayer.Play("BodyImpactSoft", part, volume)
	end
end

local function step()
	local cameraPosition = workspace.CurrentCamera.CFrame.Position
	local tracked = collect()
	local nextVelocity: { [BasePart]: Vector3 } = {}
	local wetOwners: { [Instance]: boolean } = {}

	for part, info in tracked do
		if (part.Position - cameraPosition).Magnitude > HEAR_DISTANCE then
			continue
		end
		local velocity = part.AssemblyLinearVelocity
		local previous = lastVelocity[part]
		nextVelocity[part] = velocity
		if previous then
			local jolt = (previous - velocity).Magnitude
			if jolt >= RagdollConfig.ImpactSoftSpeed and velocity.Magnitude < previous.Magnitude * 0.85 then
				playImpact(part, info, jolt)
			end
		end
		if insideWater(part.Position) then
			wetOwners[info.Owner] = true
			if not inWater[info.Owner] then
				inWater[info.Owner] = true
				SoundPlayer.Play("Splash", part)
			end
		end
	end

	for owner in inWater do
		if not wetOwners[owner] then
			inWater[owner] = nil
		end
	end
	lastVelocity = nextVelocity
end

function ImpactController.Start()
	RunService.Heartbeat:Connect(step)
end

return ImpactController
