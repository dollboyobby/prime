local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local GameState = require(ReplicatedStorage.Shared.GameState)
local LobbyService = require(script.Parent.LobbyService)
local MapService = require(script.Parent.MapService)
local NotifyService = require(script.Parent.NotifyService)
local SpawnService = require(script.Parent.SpawnService)
local VoteService = require(script.Parent.VoteService)

local RoundService = {}

local Phase = GameState.Phase
local Location = GameState.Location

local function now(): number
	return workspace:GetServerTimeNow()
end

local function setPhase(phase: string, duration: number?)
	GameState.Set("EndsAt", if duration then now() + duration else 0)
	GameState.Set("Phase", phase)
end

local function enoughPlayers(): boolean
	return #Players:GetPlayers() >= GameConfig.MinPlayers
end

local function isAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function playersAt(locations: { string }): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		if table.find(locations, player:GetAttribute("Location")) then
			table.insert(list, player)
		end
	end
	return list
end

local function waitForPlayers()
	if enoughPlayers() then
		return
	end
	setPhase(Phase.Waiting)
	while not enoughPlayers() do
		task.wait(0.5)
	end
end

local function runIntermission(): string?
	local duration = GameConfig.IntermissionTime
	local voteTime = math.clamp(GameConfig.VoteTime, 3, math.max(duration - 3, 3))
	GameState.Set("MapId", "")
	setPhase(Phase.Intermission, duration)
	local endsAt = now() + duration

	local voting = VoteService.Open(voteTime)
	if not voting then
		warn("[RoundService] no maps to vote for, check MapConfig")
	end

	local mapId: string? = nil
	while now() < endsAt do
		if not enoughPlayers() then
			VoteService.Cancel()
			return nil
		end
		if VoteService.IsOpen() and now() >= VoteService.EndsAt() then
			mapId = VoteService.Finish()
			GameState.Set("MapId", mapId or "")
		end
		task.wait(0.2)
	end
	if VoteService.IsOpen() then
		mapId = VoteService.Finish()
	end
	return mapId
end

local function sendToMap(players: { Player })
	local spawns = MapService.GetSpawnCFrames(#players)
	for index, player in players do
		local spawnCFrame = spawns[index]
		player:SetAttribute("Location", Location.Map)
		task.spawn(function()
			SpawnService.Cancel(player)
			local character = player.Character
			if not character or not spawnCFrame then
				return
			end
			pcall(player.RequestStreamAroundAsync, player, spawnCFrame.Position, 3)
			if player.Character == character and player:GetAttribute("Location") == Location.Map then
				character:PivotTo(spawnCFrame)
			end
		end)
	end
end

local function returnToLobby()
	for _, player in playersAt({ Location.Map }) do
		player:SetAttribute("Location", Location.Vent)
		task.spawn(function()
			local ok = pcall(function()
				(player :: any):LoadCharacterAsync()
			end)
			if not ok and player.Parent then
				pcall(player.LoadCharacter, player)
			end
		end)
	end
end

local function runRound(mapId: string)
	if not MapService.Load(mapId) then
		return
	end
	local info = MapService.Get(mapId)
	local players = {}
	for _, player in playersAt({ Location.Lobby, Location.Vent }) do
		if isAlive(player) then
			table.insert(players, player)
		end
	end
	if not info or #players == 0 then
		MapService.Unload()
		return
	end

	sendToMap(players)
	setPhase(Phase.Round, GameConfig.RoundTime)
	local endsAt = now() + GameConfig.RoundTime
	NotifyService.Chat("RoundStarted", info.Name)
	NotifyService.Center("RoundStartedCenter")

	task.wait(1)
	while now() < endsAt and #playersAt({ Location.Map }) > 0 do
		task.wait(0.5)
	end

	setPhase(Phase.RoundEnd, GameConfig.RoundEndTime)
	NotifyService.Center("RoundOver")
	NotifyService.Chat("RoundEnded")
	task.wait(GameConfig.RoundEndTime)

	returnToLobby()
	MapService.Unload()
	LobbyService.ResetProps()
end

function RoundService.Init()
	GameState.Set("NeedPlayers", GameConfig.MinPlayers)
end

function RoundService.Start()
	task.spawn(function()
		while true do
			local ok, err = xpcall(function()
				waitForPlayers()
				local mapId = runIntermission()
				if mapId then
					runRound(mapId)
				end
			end, debug.traceback)
			if not ok then
				warn("[RoundService] round loop error:", err)
				returnToLobby()
				MapService.Unload()
				task.wait(2)
			end
		end
	end)
end

return RoundService
