local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GameState = require(ReplicatedStorage.Shared.GameState)
local MapConfig = require(ReplicatedStorage.Shared.Config.MapConfig)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Make = require(script.Parent.Parent.UI.Make)
local Theme = require(script.Parent.Parent.UI.Theme)

local HudController = {}

local player = Players.LocalPlayer
local Phase = GameState.Phase

local screen: ScreenGui
local status: TextLabel
local timer: TextLabel
local health: TextLabel
local hint: TextLabel
local announce: TextLabel
local announceToken = 0

local function mapName(id: string?): string
	for _, info in MapConfig do
		if info.Id == id then
			return info.Name
		end
	end
	return id or ""
end

local function voteOpen(): boolean
	local raw = GameState.Get("Vote")
	if type(raw) ~= "string" or raw == "" then
		return false
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	return ok and type(data) == "table" and data.Open == true
end

local function statusText(): string
	local phase = GameState.Get("Phase")
	local mapId = GameState.Get("MapId")
	if phase == Phase.Waiting then
		return Strings.Get("WaitingPlayers", #Players:GetPlayers(), GameState.Get("NeedPlayers") or 1)
	elseif phase == Phase.Intermission then
		if voteOpen() then
			return Strings.Get("VoteRunning")
		elseif mapId and mapId ~= "" then
			return Strings.Get("NextMap", mapName(mapId))
		end
	elseif phase == Phase.Round then
		return Strings.Get("CurrentMap", mapName(mapId))
	elseif phase == Phase.RoundEnd then
		return Strings.Get("RoundOver")
	end
	return ""
end

local function refresh()
	status.Text = statusText()

	local left = GameState.TimeLeft()
	timer.Visible = left > 0
	timer.Text = Strings.Time(left)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local location = player:GetAttribute("Location")
	if humanoid and location ~= GameState.Location.Vent then
		local value = math.max(0, math.ceil(humanoid.Health))
		health.Visible = true
		health.Text = "+ " .. value
		health.TextColor3 = if value <= 25 then Theme.Danger else Theme.Hud
	else
		health.Visible = false
	end

	local keyboard = UserInputService.KeyboardEnabled
	hint.Visible = keyboard and location == GameState.Location.Lobby
end

function HudController.Announce(text: string, color: Color3?)
	announceToken += 1
	local token = announceToken
	announce.Text = text
	announce.TextColor3 = color or Theme.Announce
	announce.TextTransparency = 1
	announce.TextStrokeTransparency = 1
	TweenService:Create(announce, TweenInfo.new(0.15), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	task.delay(3.2, function()
		if announceToken == token then
			TweenService:Create(announce, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 })
				:Play()
		end
	end)
end

function HudController.Init()
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Health, false)

	screen = Make.Screen("ZMHud", 5)

	status = Make.Label({
		Name = "Status",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 64),
		Size = UDim2.fromOffset(640, 26),
		FontFace = Theme.FontBold,
		TextSize = 20,
		TextColor3 = Theme.Hud,
		Parent = screen,
	})

	timer = Make.Label({
		Name = "Timer",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.fromOffset(220, 48),
		FontFace = Theme.FontBold,
		TextSize = 42,
		TextColor3 = Theme.Hud,
		TextTransparency = 0.1,
		Parent = screen,
	})

	health = Make.Label({
		Name = "Health",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 26, 1, -16),
		Size = UDim2.fromOffset(220, 48),
		FontFace = Theme.FontBold,
		TextSize = 42,
		TextColor3 = Theme.Hud,
		TextTransparency = 0.1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = screen,
	})

	hint = Make.Label({
		Name = "Hint",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -26, 1, -26),
		Size = UDim2.fromOffset(260, 20),
		FontFace = Theme.Font,
		TextSize = 16,
		TextColor3 = Theme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = Strings.Get("HintRagdoll"),
		Parent = screen,
	})

	announce = Make.Label({
		Name = "Announce",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.28),
		Size = UDim2.fromOffset(900, 40),
		FontFace = Theme.FontBold,
		TextSize = 30,
		TextColor3 = Theme.Announce,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Parent = screen,
	})
end

function HudController.Start()
	while true do
		refresh()
		task.wait(0.1)
	end
end

return HudController
