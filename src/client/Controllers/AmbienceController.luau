local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameState = require(ReplicatedStorage.Shared.GameState)
local LightingConfig = require(ReplicatedStorage.Shared.Config.LightingConfig)
local MapConfig = require(ReplicatedStorage.Shared.Config.MapConfig)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)

local AmbienceController = {}

local player = Players.LocalPlayer
local music: Sound? = nil
local musicVolume = 0
local random = Random.new()

local function getEffect(className: string, name: string): Instance
	local effect = Lighting:FindFirstChild(name)
	if not effect then
		effect = Lighting:FindFirstChildOfClass(className)
	end
	if not effect then
		effect = Instance.new(className)
		effect.Name = name
		effect.Parent = Lighting
	end
	return effect
end

local function presetName(): string
	if player:GetAttribute("Location") == GameState.Location.Map then
		local mapId = GameState.Get("MapId")
		for _, info in MapConfig do
			if info.Id == mapId and info.Lighting then
				return info.Lighting
			end
		end
		return "Day"
	end
	return "Lobby"
end

local function apply()
	local preset = (LightingConfig :: any)[presetName()] or LightingConfig.Lobby
	Lighting.ClockTime = preset.ClockTime
	Lighting.Brightness = preset.Brightness
	Lighting.Ambient = preset.Ambient
	Lighting.OutdoorAmbient = preset.OutdoorAmbient
	Lighting.ExposureCompensation = preset.ExposureCompensation

	local atmosphere = getEffect("Atmosphere", "ZMAtmosphere") :: Atmosphere
	for key, value in preset.Atmosphere do
		(atmosphere :: any)[key] = value
	end
	local correction = getEffect("ColorCorrectionEffect", "ZMColor") :: ColorCorrectionEffect
	for key, value in preset.ColorCorrection do
		(correction :: any)[key] = value
	end
	SoundService.AmbientReverb = preset.Reverb

	if music then
		local inLobby = player:GetAttribute("Location") ~= GameState.Location.Map
		TweenService:Create(music, TweenInfo.new(1.5), { Volume = if inLobby then musicVolume else 0 }):Play()
	end
end

local function flicker(tube: BasePart)
	local light = tube:FindFirstChildOfClass("PointLight")
	local onColor = tube.Color
	local offColor = onColor:Lerp(Color3.new(), 0.75)
	local brightness = light and light.Brightness or 1

	local function set(on: boolean)
		tube.Color = if on then onColor else offColor
		tube.Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
		if light then
			light.Brightness = if on then brightness else 0
		end
	end

	task.spawn(function()
		while tube.Parent do
			task.wait(random:NextNumber(1.5, 6))
			local blinks = random:NextInteger(2, 5)
			for _ = 1, blinks do
				set(false)
				task.wait(random:NextNumber(0.04, 0.12))
				set(true)
				task.wait(random:NextNumber(0.03, 0.15))
			end
			if random:NextNumber() < 0.25 then
				set(false)
				task.wait(random:NextNumber(0.4, 1.2))
				set(true)
			end
		end
	end)
end

local function ambient(part: Instance)
	local name = part:GetAttribute("AmbientSound")
	if type(name) == "string" then
		SoundPlayer.Loop(name, part)
	end
end

function AmbienceController.Start()
	for _, tube in CollectionService:GetTagged("ZMFlicker") do
		if tube:IsA("BasePart") then
			flicker(tube)
		end
	end
	CollectionService:GetInstanceAddedSignal("ZMFlicker"):Connect(function(tube)
		if tube:IsA("BasePart") then
			flicker(tube)
		end
	end)

	for _, part in CollectionService:GetTagged("ZMAmbient") do
		ambient(part)
	end
	CollectionService:GetInstanceAddedSignal("ZMAmbient"):Connect(ambient)

	music = SoundPlayer.Loop("LobbyMusic")
	if music then
		musicVolume = music.Volume
	end

	player:GetAttributeChangedSignal("Location"):Connect(apply)
	GameState.Changed("MapId", apply)
	apply()
end

return AmbienceController
