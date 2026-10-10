local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameState = require(ReplicatedStorage.Shared.GameState)
local MapConfig = require(ReplicatedStorage.Shared.Config.MapConfig)

local MapService = {}

export type MapInfo = {
	Id: string,
	Name: string,
	Source: string,
	Object: string,
	Lighting: string?,
	SpawnRadius: number?,
}

type LoadedMap = {
	Info: MapInfo,
	Root: Instance,
	Cloned: boolean,
}

local current: LoadedMap? = nil
local random = Random.new()

local function findSource(info: MapInfo): Instance?
	if info.Source == "ServerStorage" then
		local folder = ServerStorage:FindFirstChild("Maps")
		return folder and folder:FindFirstChild(info.Object)
	end
	return workspace:FindFirstChild(info.Object)
end

function MapService.GetAvailable(): { MapInfo }
	local list = {}
	for _, info in MapConfig :: { MapInfo } do
		if findSource(info) then
			table.insert(list, info)
		else
			warn(string.format("[MapService] map %q skipped: %s.%s not found", info.Id, info.Source, info.Object))
		end
	end
	return list
end

function MapService.Get(id: string): MapInfo?
	for _, info in MapConfig :: { MapInfo } do
		if info.Id == id then
			return info
		end
	end
	return nil
end

function MapService.Load(id: string): boolean
	MapService.Unload()
	local info = MapService.Get(id)
	if not info then
		return false
	end
	local source = findSource(info)
	if not source then
		return false
	end

	local root = source
	local cloned = false
	if info.Source == "ServerStorage" then
		root = source:Clone()
		root.Parent = workspace
		cloned = true
	end
	current = { Info = info, Root = root, Cloned = cloned }
	GameState.Set("MapId", info.Id)
	return true
end

function MapService.Unload()
	if current and current.Cloned then
		current.Root:Destroy()
	end
	current = nil
end

local function getBounds(root: Instance): (CFrame, Vector3)
	if root:IsA("BasePart") then
		return root.CFrame, root.Size
	elseif root:IsA("Model") then
		return root:GetBoundingBox()
	end
	return CFrame.new(), Vector3.new(100, 1, 100)
end

local function dropToGround(root: Instance, position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { root }
	local result = workspace:Raycast(position + Vector3.new(0, 60, 0), Vector3.new(0, -400, 0), params)
	if result then
		return result.Position + Vector3.new(0, 3.5, 0)
	end
	return position + Vector3.new(0, 3.5, 0)
end

function MapService.GetSpawnCFrames(count: number): { CFrame }
	local spawns = {}
	if not current then
		return spawns
	end
	local root = current.Root

	local folder = root:FindFirstChild("Spawns")
	if folder then
		local points = {}
		for _, point in folder:GetChildren() do
			if point:IsA("BasePart") then
				table.insert(points, point)
			end
		end
		if #points > 0 then
			for i = 1, count do
				local point = points[(i - 1) % #points + 1]
				table.insert(spawns, point.CFrame + Vector3.new(0, point.Size.Y / 2 + 3, 0))
			end
			return spawns
		end
	end

	local center, size = getBounds(root)
	local radius = math.min(current.Info.SpawnRadius or 40, size.X / 2 - 4, size.Z / 2 - 4)
	radius = math.max(radius, 4)
	local top = center.Position + Vector3.new(0, size.Y / 2, 0)
	local offset = random:NextNumber(0, math.pi * 2)
	for i = 1, count do
		local angle = offset + (i / math.max(count, 1)) * math.pi * 2
		local distance = radius * random:NextNumber(0.55, 1)
		local position =
			dropToGround(root, top + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance))
		local lookTarget = Vector3.new(top.X, position.Y, top.Z)
		table.insert(spawns, CFrame.lookAt(position, lookTarget))
	end
	return spawns
end

return MapService
