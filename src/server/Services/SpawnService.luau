local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(ReplicatedStorage.Shared.GameState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SpawnConfig = require(ReplicatedStorage.Shared.Config.SpawnConfig)
local LobbyService = require(script.Parent.LobbyService)
local NotifyService = require(script.Parent.NotifyService)
local RagdollService = require(script.Parent.RagdollService)

local SpawnService = {}

type Entry = {
	Player: Player,
	Character: Model,
	QueuedAt: number,
	Ready: boolean,
}

type Flight = {
	Character: Model,
	Token: number,
	LaunchedAt: number,
}

local READY_TIMEOUT = 8
local APPEARANCE_TIMEOUT = 6

local remote: RemoteEvent
local queue: { Entry } = {}
local flights: { [Player]: Flight } = {}
local arrived: { [Player]: boolean } = {}
local nextToken = 0

local function isAlive(character: Model?): boolean
	if not character or not character.Parent then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function getRoot(character: Model): BasePart?
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setLocation(player: Player, location: string)
	player:SetAttribute("Location", location)
end

local function removeFromQueue(player: Player)
	for i = #queue, 1, -1 do
		if queue[i].Player == player then
			table.remove(queue, i)
		end
	end
end

local function giveOwnership(player: Player, character: Model)
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and not part.Anchored then
			pcall(part.SetNetworkOwner, part, player)
		end
	end
end

local function finish(player: Player)
	local flight = flights[player]
	if not flight then
		return
	end
	flights[player] = nil
	local character = flight.Character
	character:SetAttribute("VentFlight", nil)
	if player.Character ~= character or not isAlive(character) then
		return
	end

	RagdollService.Disable(character)
	local root = getRoot(character)
	if root and not LobbyService.IsInside(root.Position) then
		character:PivotTo(LobbyService.GetLandingCFrame())
	end
	setLocation(player, GameState.Location.Lobby)
	remote:FireClient(player, "Done")

	if SpawnConfig.ShowArrivalMessage and not arrived[player] then
		arrived[player] = true
		NotifyService.Chat("Arrived", player.DisplayName)
	end
	if GameState.Get("Phase") == GameState.Phase.Round then
		NotifyService.CenterTo(player, "RoundInProgress")
	end
end

local function launch(entry: Entry)
	local player, character = entry.Player, entry.Character
	local root = getRoot(character)
	if not root then
		return
	end

	nextToken += 1
	local token = nextToken
	RagdollService.Enable(character, "Vent")
	character:PivotTo(LobbyService.GetStartCFrame())
	root.Anchored = false
	giveOwnership(player, character)

	flights[player] = { Character = character, Token = token, LaunchedAt = os.clock() }
	character:SetAttribute("VentFlight", true)
	remote:FireClient(player, "Launch", character, LobbyService.GetStartCFrame(), LobbyService.GetExitCFrame())

	task.delay(SpawnConfig.MaxLyingTime + 3, function()
		local flight = flights[player]
		if flight and flight.Token == token then
			finish(player)
		end
	end)
end

local function canLaunch(entry: Entry, now: number): boolean
	local waited = now - entry.QueuedAt
	if not entry.Ready and waited < READY_TIMEOUT then
		return false
	end
	if not entry.Player:HasAppearanceLoaded() and waited < APPEARANCE_TIMEOUT then
		return false
	end
	return true
end

local function runQueue()
	while true do
		local now = os.clock()
		local changed = false
		for index, entry in queue do
			local valid = entry.Player.Parent ~= nil
				and entry.Player.Character == entry.Character
				and isAlive(entry.Character)
			if not valid then
				table.remove(queue, index)
				changed = true
				break
			end
			if canLaunch(entry, now) then
				table.remove(queue, index)
				launch(entry)
				task.wait(SpawnConfig.LaunchInterval)
				changed = true
				break
			end
		end
		if not changed then
			task.wait(0.1)
		end
	end
end

local function rescueLoop()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("Location") ~= GameState.Location.Lobby or flights[player] then
				continue
			end
			local character = player.Character
			local root = character and getRoot(character)
			if character and root and isAlive(character) and not LobbyService.IsInside(root.Position, 6) then
				RagdollService.Disable(character)
				character:PivotTo(LobbyService.GetLandingCFrame())
			end
		end
	end
end

function SpawnService.SendThroughVent(player: Player, character: Model)
	removeFromQueue(player)
	flights[player] = nil
	setLocation(player, GameState.Location.Vent)
	character:SetAttribute("VentFlight", nil)

	local root = getRoot(character)
	if root then
		root.Anchored = true
		character:PivotTo(LobbyService.GetHoldCFrame())
	end
	table.insert(queue, {
		Player = player,
		Character = character,
		QueuedAt = os.clock(),
		Ready = false,
	})
	remote:FireClient(player, "Prepare")
end

function SpawnService.Cancel(player: Player)
	removeFromQueue(player)
	flights[player] = nil
	local character = player.Character
	if character then
		character:SetAttribute("VentFlight", nil)
		RagdollService.Disable(character)
		local root = getRoot(character)
		if root and root.Anchored then
			root.Anchored = false
			giveOwnership(player, character)
		end
	end
	remote:FireClient(player, "Cancel")
end

local function onCharacterAdded(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root or player.Character ~= character then
		return
	end
	RagdollService.Prepare(character)
	SpawnService.SendThroughVent(player, character)
end

local function onPlayerAdded(player: Player)
	player.RespawnLocation = LobbyService.GetSpawnLocation()
	setLocation(player, GameState.Location.Vent)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
end

function SpawnService.Init()
	remote = Remotes.Get("VentSpawn")
end

function SpawnService.Start()
	remote.OnServerEvent:Connect(function(player, action)
		if action == "Ready" then
			for _, entry in queue do
				if entry.Player == player and entry.Character == player.Character then
					entry.Ready = true
				end
			end
		elseif action == "Landed" then
			local flight = flights[player]
			if flight and os.clock() - flight.LaunchedAt >= SpawnConfig.MinLyingTime * 0.5 then
				finish(player)
			end
		end
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		removeFromQueue(player)
		flights[player] = nil
		arrived[player] = nil
	end)

	task.spawn(runQueue)
	task.spawn(rescueLoop)
end

return SpawnService
