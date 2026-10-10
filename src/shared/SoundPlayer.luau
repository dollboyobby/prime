local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local SoundConfig = require(script.Parent.Config.SoundConfig)

type SoundEntry = {
	Ids: { string },
	Volume: number,
	Pitch: { number }?,
	Looped: boolean?,
}

local SoundPlayer = {}

local failed: { [string]: boolean } = {}
local random = Random.new()

local function getEntry(name: string): SoundEntry?
	local entry = (SoundConfig :: any)[name]
	if not entry then
		warn("[SoundPlayer] unknown sound:", name)
	end
	return entry
end

local function pickId(entry: SoundEntry): string?
	local ids = {}
	for _, id in entry.Ids do
		if id ~= "" and not failed[id] then
			table.insert(ids, id)
		end
	end
	if #ids == 0 then
		return nil
	end
	return ids[random:NextInteger(1, #ids)]
end

function SoundPlayer.Has(name: string): boolean
	local entry = getEntry(name)
	return entry ~= nil and pickId(entry) ~= nil
end

function SoundPlayer.Create(name: string, parent: Instance?, volumeScale: number?): Sound?
	local entry = getEntry(name)
	if not entry then
		return nil
	end
	local id = pickId(entry)
	if not id then
		return nil
	end
	local pitch = entry.Pitch or { 1, 1 }
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = id
	sound.Volume = entry.Volume * (volumeScale or 1)
	sound.PlaybackSpeed = random:NextNumber(pitch[1], pitch[2])
	sound.Looped = entry.Looped == true
	sound.RollOffMinDistance = 10
	sound.RollOffMaxDistance = 120
	sound.Parent = parent or SoundService
	return sound
end

function SoundPlayer.Play(name: string, parent: Instance?, volumeScale: number?): Sound?
	local sound = SoundPlayer.Create(name, parent, volumeScale)
	if not sound then
		return nil
	end
	sound.Ended:Once(function()
		sound:Destroy()
	end)
	sound:Play()
	Debris:AddItem(sound, 8)
	return sound
end

function SoundPlayer.PlayAt(name: string, position: Vector3, volumeScale: number?): Sound?
	local holder = Instance.new("Attachment")
	holder.Name = "SoundAt"
	holder.WorldPosition = position
	holder.Parent = workspace.Terrain
	Debris:AddItem(holder, 8)
	return SoundPlayer.Play(name, holder, volumeScale)
end

function SoundPlayer.Loop(name: string, parent: Instance?, volumeScale: number?): Sound?
	local sound = SoundPlayer.Create(name, parent, volumeScale)
	if sound then
		sound.Looped = true
		sound:Play()
	end
	return sound
end

function SoundPlayer.Preload()
	local seen: { [string]: boolean } = {}
	local sounds: { Instance } = {}
	for _, entry in SoundConfig :: any do
		for _, id in entry.Ids do
			if id ~= "" and not seen[id] then
				seen[id] = true
				local sound = Instance.new("Sound")
				sound.SoundId = id
				table.insert(sounds, sound)
			end
		end
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(sounds, function(contentId: string, status: Enum.AssetFetchStatus)
				if status == Enum.AssetFetchStatus.Failure then
					failed[contentId] = true
					warn("[SoundPlayer] sound failed to load, skipping it:", contentId)
				end
			end)
		end)
		for _, sound in sounds do
			sound:Destroy()
		end
	end)
end

return SoundPlayer
