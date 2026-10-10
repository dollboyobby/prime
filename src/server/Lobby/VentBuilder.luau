local BuildKit = require(script.Parent.BuildKit)
local CollisionGroups = require(script.Parent.Parent.Util.CollisionGroups)
local LobbyConfig = require(game:GetService("ReplicatedStorage").Shared.Config.LobbyConfig)

local VentBuilder = {}

export type VentParts = {
	Model: Model,
	Exit: BasePart,
	Start: BasePart,
}

local WALL_THICKNESS = 2

function VentBuilder.Build(origin: CFrame, parent: Instance): VentParts
	local colors = LobbyConfig.Colors
	local vent = LobbyConfig.Vent
	local S = vent.HatchSize
	local HY = vent.HatchHeight
	local wallZ = LobbyConfig.RoomSize.Z / 2
	local ductLength = vent.DuctLength + WALL_THICKNESS
	local ductZ = wallZ + ductLength / 2

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	local function facing(x: number, y: number, z: number, direction: Vector3): CFrame
		local position = at(x, y, z).Position
		return CFrame.lookAt(position, position + origin:VectorToWorldSpace(direction))
	end

	local model = BuildKit.Group("Model", "Vent", parent) :: Model

	local slippery = PhysicalProperties.new(0.7, 0.05, 0.1, 100, 1)
	local duct = BuildKit.Group("Folder", "Duct", model)
	local ductProps: BuildKit.Props = {
		Material = Enum.Material.Metal,
		Color = colors.Metal:Lerp(Color3.new(), 0.45),
		CustomPhysicalProperties = slippery,
		Parent = duct,
	}
	local ductParts: { BuildKit.Props } = {
		{
			Name = "Floor",
			CFrame = at(0, HY - 0.25, ductZ),
			Size = Vector3.new(S + 1, 0.5, ductLength),
			Material = Enum.Material.DiamondPlate,
		},
		{ Name = "Ceiling", CFrame = at(0, HY + S + 0.25, ductZ), Size = Vector3.new(S + 1, 0.5, ductLength) },
		{ Name = "Left", CFrame = at(-S / 2 - 0.25, HY + S / 2, ductZ), Size = Vector3.new(0.5, S, ductLength) },
		{ Name = "Right", CFrame = at(S / 2 + 0.25, HY + S / 2, ductZ), Size = Vector3.new(0.5, S, ductLength) },
		{ Name = "End", CFrame = at(0, HY + S / 2, wallZ + ductLength + 0.25), Size = Vector3.new(S + 1, S + 1, 0.5) },
	}
	for _, info in ductParts do
		local props = table.clone(ductProps)
		for key, value in info do
			props[key] = value
		end
		BuildKit.Part(props)
	end

	local frame = BuildKit.Group("Folder", "Frame", model)
	local frameProps: BuildKit.Props = { Material = Enum.Material.DiamondPlate, Color = colors.Metal, Parent = frame }
	local frameParts: { BuildKit.Props } = {
		{ Name = "Top", CFrame = at(0, HY + S + 0.3, wallZ - 0.3), Size = Vector3.new(S + 1.2, 0.6, 0.6) },
		{ Name = "Bottom", CFrame = at(0, HY - 0.3, wallZ - 0.3), Size = Vector3.new(S + 1.2, 0.6, 0.6) },
		{ Name = "Left", CFrame = at(-S / 2 - 0.3, HY + S / 2, wallZ - 0.3), Size = Vector3.new(0.6, S, 0.6) },
		{ Name = "Right", CFrame = at(S / 2 + 0.3, HY + S / 2, wallZ - 0.3), Size = Vector3.new(0.6, S, 0.6) },
	}
	for _, info in frameParts do
		local props = table.clone(frameProps)
		for key, value in info do
			props[key] = value
		end
		BuildKit.Part(props)
	end

	local flap = BuildKit.Group("Model", "Flap", model) :: Model
	local flapProps = {
		Material = Enum.Material.DiamondPlate,
		Color = colors.Metal:Lerp(Color3.new(), 0.2),
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = flap,
	}
	local plate = table.clone(flapProps)
	plate.Name = "Plate"
	plate.CFrame = at(0, HY + S / 2, wallZ - 0.3)
	plate.Size = Vector3.new(S - 0.2, S - 0.1, 0.2)
	BuildKit.Part(plate)
	for i = 1, 5 do
		local slat = table.clone(flapProps)
		slat.Name = "Slat"
		slat.Material = Enum.Material.Metal
		slat.Color = colors.Metal:Lerp(Color3.new(), 0.5)
		slat.CFrame = at(0, HY + S * (i / 6), wallZ - 0.45) * CFrame.Angles(math.rad(-25), 0, 0)
		slat.Size = Vector3.new(S - 0.8, 0.5, 0.12)
		BuildKit.Part(slat)
	end
	local hinge = table.clone(flapProps)
	hinge.Name = "Hinge"
	hinge.CFrame = at(0, HY + S - 0.05, wallZ - 0.3)
	hinge.Size = Vector3.new(0.2, 0.2, 0.2)
	hinge.Transparency = 1
	hinge.CastShadow = false
	flap.PrimaryPart = BuildKit.Part(hinge)

	BuildKit.Part({
		Name = "Blocker",
		CFrame = at(0, HY + S / 2, wallZ + WALL_THICKNESS / 2),
		Size = Vector3.new(S, S, WALL_THICKNESS),
		Transparency = 1,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		CollisionGroup = CollisionGroups.VentBlocker,
		Parent = model,
	})

	local lamp = BuildKit.Part({
		Name = "WarningLamp",
		CFrame = at(0, HY + S + 1.4, wallZ - 0.3),
		Size = Vector3.new(1.4, 0.7, 0.6),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(70, 12, 10),
		CanCollide = false,
		Parent = model,
	})
	BuildKit.Light("PointLight", {
		Color = Color3.fromRGB(255, 40, 30),
		Range = 16,
		Brightness = 0,
		Shadows = false,
		Parent = lamp,
	})

	BuildKit.Sign(
		BuildKit.Part({
			Name = "WarningSign",
			CFrame = facing(S / 2 + 6, HY + S / 2 + 0.5, wallZ - 0.06, Vector3.new(0, 0, -1)),
			Size = Vector3.new(9, 2.2, 0.1),
			Color = LobbyConfig.Colors.Hazard,
			CanCollide = false,
			Parent = model,
		}),
		"SignVent",
		Color3.fromRGB(20, 20, 20),
		LobbyConfig.Colors.Hazard
	)

	local markerProps = {
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = model,
	}

	local exitProps = table.clone(markerProps)
	exitProps.Name = "Exit"
	exitProps.CFrame = facing(0, HY + S / 2, wallZ - 0.05, Vector3.new(0, 0, -1))
	local exit = BuildKit.Part(exitProps)

	local startProps = table.clone(markerProps)
	startProps.Name = "Start"
	local startPosition = at(0, HY + 1.3, wallZ + ductLength - 4.5).Position
	startProps.CFrame =
		CFrame.lookAt(startPosition, startPosition - origin.UpVector, origin:VectorToWorldSpace(Vector3.new(0, 0, -1)))
	local start = BuildKit.Part(startProps)

	return {
		Model = model,
		Exit = exit,
		Start = start,
	}
end

return VentBuilder
