local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollisionGroups = require(script.Parent.Parent.Util.CollisionGroups)
local GameState = require(ReplicatedStorage.Shared.GameState)
local RagdollConfig = require(ReplicatedStorage.Shared.Config.RagdollConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RagdollService = {}

local JOINT_LIMITS = {
	{ Name = "Neck", Cone = 35, Twist = 40 },
	{ Name = "Waist", Cone = 20, Twist = 25 },
	{ Name = "Shoulder", Cone = 90, Twist = 85 },
	{ Name = "Elbow", Cone = 12, Twist = 75 },
	{ Name = "Wrist", Cone = 25, Twist = 25 },
	{ Name = "Hip", Cone = 50, Twist = 60 },
	{ Name = "Knee", Cone = 12, Twist = 75 },
	{ Name = "Ankle", Cone = 25, Twist = 25 },
}

local HOLDER_NAME = "RagdollParts"
local ATTACHMENT_NAME = "RagdollAttachment"

local nextId = 0
local startedAt: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any
local lastToggle: { [Player]: number } = {}

local function limitsFor(jointName: string): (number, number)
	for _, entry in JOINT_LIMITS do
		if string.find(jointName, entry.Name, 1, true) then
			return entry.Cone, entry.Twist
		end
	end
	return 45, 45
end

local function makeCollider(part: BasePart, holder: Instance)
	local collider = Instance.new("Part")
	collider.Name = "RagdollCollider"
	collider.Size = part.Size * 0.85
	collider.CFrame = part.CFrame
	collider.Transparency = 1
	collider.CanCollide = true
	collider.CanQuery = false
	collider.CanTouch = false
	collider.CastShadow = false
	collider.Massless = true
	collider.CollisionGroup = CollisionGroups.Ragdoll
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = part
	weld.Part1 = collider
	weld.Parent = collider
	collider.Parent = holder
end

function RagdollService.IsRagdolled(character: Model): boolean
	return character:GetAttribute("Ragdolled") == true
end

function RagdollService.Enable(character: Model, reason: string): boolean
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	nextId += 1
	startedAt[character] = os.clock()
	if RagdollService.IsRagdolled(character) then
		character:SetAttribute("RagdollReason", reason)
		character:SetAttribute("RagdollId", nextId)
		return true
	end

	local holder = Instance.new("Folder")
	holder.Name = HOLDER_NAME

	for _, motor in character:GetDescendants() do
		if not motor:IsA("Motor6D") or not motor.Enabled then
			continue
		end
		local part0, part1 = motor.Part0, motor.Part1
		if not part0 or not part1 or part0.Name == "HumanoidRootPart" then
			continue
		end
		if part0.Parent ~= character or part1.Parent ~= character then
			continue
		end
		local attachment0 = Instance.new("Attachment")
		attachment0.Name = ATTACHMENT_NAME
		attachment0.CFrame = motor.C0
		attachment0.Parent = part0
		local attachment1 = Instance.new("Attachment")
		attachment1.Name = ATTACHMENT_NAME
		attachment1.CFrame = motor.C1
		attachment1.Parent = part1

		local cone, twist = limitsFor(motor.Name)
		local socket = Instance.new("BallSocketConstraint")
		socket.Name = motor.Name
		socket.Attachment0 = attachment0
		socket.Attachment1 = attachment1
		socket.LimitsEnabled = true
		socket.UpperAngle = cone
		socket.TwistLimitsEnabled = true
		socket.TwistLowerAngle = -twist
		socket.TwistUpperAngle = twist
		socket.Restitution = 0
		socket.Parent = holder

		motor:SetAttribute("RagdollOff", true)
		motor.Enabled = false
	end

	for _, part in character:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		if part.Name == "HumanoidRootPart" then
			part:SetAttribute("RagdollCanCollide", part.CanCollide)
			part.CanCollide = false
		else
			makeCollider(part, holder)
		end
	end

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part.Parent ~= holder then
			part:SetAttribute("RagdollGroup", part.CollisionGroup)
			part.CollisionGroup = CollisionGroups.Ragdoll
		end
	end

	holder.Parent = character
	humanoid.AutoRotate = false
	character:SetAttribute("RagdollReason", reason)
	character:SetAttribute("RagdollId", nextId)
	character:SetAttribute("Ragdolled", true)
	return true
end

function RagdollService.Disable(character: Model)
	if not RagdollService.IsRagdolled(character) then
		return
	end
	startedAt[character] = nil

	local holder = character:FindFirstChild(HOLDER_NAME)
	if holder then
		holder:Destroy()
	end

	for _, item in character:GetDescendants() do
		if item:IsA("Motor6D") then
			if item:GetAttribute("RagdollOff") then
				item:SetAttribute("RagdollOff", nil)
				item.Enabled = true
			end
		elseif item:IsA("Attachment") and item.Name == ATTACHMENT_NAME then
			item:Destroy()
		elseif item:IsA("BasePart") then
			local group = item:GetAttribute("RagdollGroup")
			if type(group) == "string" then
				item.CollisionGroup = group
				item:SetAttribute("RagdollGroup", nil)
			end
			local canCollide = item:GetAttribute("RagdollCanCollide")
			if type(canCollide) == "boolean" then
				item.CanCollide = canCollide
				item:SetAttribute("RagdollCanCollide", nil)
			end
		end
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
	end
	character:SetAttribute("RagdollReason", nil)
	character:SetAttribute("Ragdolled", false)
end

function RagdollService.Prepare(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.BreakJointsOnDeath = not RagdollConfig.RagdollOnDeath
	humanoid.RequiresNeck = false
	if RagdollConfig.RagdollOnDeath then
		humanoid.Died:Once(function()
			if character.Parent then
				RagdollService.Enable(character, "Death")
			end
		end)
	end
end

local function onToggle(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end
	local now = os.clock()

	if RagdollService.IsRagdolled(character) then
		local since = startedAt[character] or 0
		if character:GetAttribute("RagdollReason") == "Manual" and now - since >= RagdollConfig.ManualMinTime then
			lastToggle[player] = now
			RagdollService.Disable(character)
		end
		return
	end

	if now - (lastToggle[player] or 0) < RagdollConfig.ManualCooldown then
		return
	end
	if RagdollConfig.ManualOnlyInLobby and player:GetAttribute("Location") ~= GameState.Location.Lobby then
		return
	end
	lastToggle[player] = now
	RagdollService.Enable(character, "Manual")

	local id = character:GetAttribute("RagdollId")
	task.delay(RagdollConfig.ManualMaxTime, function()
		if
			character.Parent
			and RagdollService.IsRagdolled(character)
			and character:GetAttribute("RagdollReason") == "Manual"
			and character:GetAttribute("RagdollId") == id
		then
			RagdollService.Disable(character)
		end
	end)
end

function RagdollService.Start()
	Remotes.Get("Ragdoll").OnServerEvent:Connect(function(player, action)
		if action == "Toggle" then
			onToggle(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastToggle[player] = nil
	end)
end

return RagdollService
