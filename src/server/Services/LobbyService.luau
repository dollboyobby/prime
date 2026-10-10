local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LobbyBuilder = require(script.Parent.Parent.Lobby.LobbyBuilder)
local LobbyConfig = require(ReplicatedStorage.Shared.Config.LobbyConfig)

local LobbyService = {}

local lobby: LobbyBuilder.Lobby
local random = Random.new()

local function resetProp(prop: BasePart)
	local home = prop:GetAttribute("Home")
	if typeof(home) ~= "CFrame" then
		return
	end
	pcall(prop.SetNetworkOwner, prop, nil)
	prop.AssemblyLinearVelocity = Vector3.zero
	prop.AssemblyAngularVelocity = Vector3.zero
	prop.CFrame = home
	task.delay(1, function()
		if prop.Parent then
			pcall(prop.SetNetworkOwnershipAuto, prop)
		end
	end)
end

function LobbyService.Init()
	lobby = LobbyBuilder.Build()
end

function LobbyService.Start()
	task.spawn(function()
		while true do
			task.wait(2)
			for _, prop in lobby.Props do
				if prop.Parent and not LobbyService.IsInside(prop.Position, 4) then
					resetProp(prop)
				end
			end
		end
	end)
end

function LobbyService.GetSpawnLocation(): SpawnLocation
	return lobby.SpawnLocation
end

function LobbyService.GetHoldCFrame(): CFrame
	return lobby.Hold.CFrame
end

function LobbyService.GetStartCFrame(): CFrame
	return lobby.Start.CFrame
end

function LobbyService.GetExitCFrame(): CFrame
	return lobby.Exit.CFrame
end

function LobbyService.GetLandingCFrame(): CFrame
	local offset = Vector3.new(random:NextNumber(-3, 3), 0, random:NextNumber(-2, 2))
	return lobby.Landing.CFrame + offset
end

function LobbyService.IsInside(position: Vector3, margin: number?): boolean
	local extra = margin or 0
	local size = LobbyConfig.RoomSize
	local point = lobby.Origin:PointToObjectSpace(position)
	return math.abs(point.X) <= size.X / 2 + extra
		and math.abs(point.Z) <= size.Z / 2 + extra
		and point.Y >= -6 - extra
		and point.Y <= size.Y + extra
end

function LobbyService.ResetProps()
	for _, prop in lobby.Props do
		if prop.Parent then
			resetProp(prop)
		end
	end
end

return LobbyService
