local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(ReplicatedStorage.Shared.GameState)
local RagdollConfig = require(ReplicatedStorage.Shared.Config.RagdollConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Strings = require(ReplicatedStorage.Shared.Strings)

local RagdollController = {}

local ACTION = "ZMRagdoll"

local player = Players.LocalPlayer
local remote: RemoteEvent
local bound = false

local function standHeight(humanoid: Humanoid, root: BasePart): number
	if humanoid.RigType == Enum.HumanoidRigType.R6 then
		return 3
	end
	return humanoid.HipHeight + root.Size.Y / 2
end

local function standUp(character: Model, humanoid: Humanoid, root: BasePart)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(root.CFrame.UpVector.X, 0, root.CFrame.UpVector.Z)
	end
	if flat.Magnitude < 0.1 then
		flat = Vector3.new(0, 0, -1)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -8, 0), params)
	local y = if result then result.Position.Y + standHeight(humanoid, root) else root.Position.Y + 1.5

	local position = Vector3.new(root.Position.X, y, root.Position.Z)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(position, position + flat.Unit)
	humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

local function trip(root: BasePart)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude > 0.1 then
		flat = flat.Unit
	end
	root.AssemblyLinearVelocity += flat * RagdollConfig.TripSpeed + Vector3.new(0, 6, 0)
	root.AssemblyAngularVelocity = root.CFrame.RightVector * -5
end

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not humanoid or not root then
		return
	end

	local function update()
		if character:GetAttribute("Ragdolled") then
			if humanoid.Health <= 0 then
				return
			end
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			if character:GetAttribute("RagdollReason") == "Manual" then
				trip(root)
			end
		else
			humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			if humanoid.Health > 0 and humanoid:GetState() == Enum.HumanoidStateType.Physics then
				standUp(character, humanoid, root)
			end
		end
	end

	character:GetAttributeChangedSignal("Ragdolled"):Connect(update)
	if character:GetAttribute("Ragdolled") then
		update()
	end
end

local function setBound(enabled: boolean)
	if enabled == bound then
		return
	end
	bound = enabled
	if enabled then
		ContextActionService:BindAction(ACTION, function(_, state)
			if state == Enum.UserInputState.Begin then
				remote:FireServer("Toggle")
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, true, RagdollConfig.ManualKey, Enum.KeyCode.ButtonY)
		ContextActionService:SetTitle(ACTION, Strings.Get("ButtonRagdoll"))
	else
		ContextActionService:UnbindAction(ACTION)
	end
end

local function updateBinding()
	local location = player:GetAttribute("Location")
	if RagdollConfig.ManualOnlyInLobby then
		setBound(location == GameState.Location.Lobby)
	else
		setBound(location ~= GameState.Location.Vent)
	end
end

function RagdollController.Init()
	remote = Remotes.Get("Ragdoll")
end

function RagdollController.Start()
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player:GetAttributeChangedSignal("Location"):Connect(updateBinding)
	updateBinding()
end

return RagdollController
