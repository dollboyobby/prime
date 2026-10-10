local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameState = {}

GameState.Phase = {
	Waiting = "Waiting",
	Intermission = "Intermission",
	Round = "Round",
	RoundEnd = "RoundEnd",
}

GameState.Location = {
	Vent = "Vent",
	Lobby = "Lobby",
	Map = "Map",
}

local folder: Instance
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("GameState") or Instance.new("Folder")
	folder.Name = "GameState"
	folder:SetAttribute("Phase", GameState.Phase.Waiting)
	folder:SetAttribute("EndsAt", 0)
	folder:SetAttribute("MapId", "")
	folder:SetAttribute("NeedPlayers", 0)
	folder:SetAttribute("Vote", "")
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("GameState")
end

function GameState.Get(key: string): any
	return folder:GetAttribute(key)
end

function GameState.Set(key: string, value: any)
	assert(RunService:IsServer(), "GameState.Set is server only")
	folder:SetAttribute(key, value)
end

function GameState.Changed(key: string, callback: (any) -> ()): RBXScriptConnection
	return folder:GetAttributeChangedSignal(key):Connect(function()
		callback(folder:GetAttribute(key))
	end)
end

function GameState.TimeLeft(): number
	local endsAt = folder:GetAttribute("EndsAt")
	if type(endsAt) ~= "number" or endsAt <= 0 then
		return 0
	end
	return math.max(0, endsAt - workspace:GetServerTimeNow())
end

return GameState
