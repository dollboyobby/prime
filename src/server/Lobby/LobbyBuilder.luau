local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildKit = require(script.Parent.BuildKit)
local VentBuilder = require(script.Parent.VentBuilder)
local LobbyConfig = require(ReplicatedStorage.Shared.Config.LobbyConfig)

local LobbyBuilder = {}

export type Lobby = {
	Model: Model,
	Origin: CFrame,
	Exit: BasePart,
	Start: BasePart,
	Landing: BasePart,
	Hold: BasePart,
	SpawnLocation: SpawnLocation,
	Props: { BasePart },
}

local T = 2
local CHANNEL = 7
local HOLD_DEPTH = 70

function LobbyBuilder.Build(): Lobby
	local origin = CFrame.new(LobbyConfig.Position)
	local colors = LobbyConfig.Colors
	local W, H, D = LobbyConfig.RoomSize.X, LobbyConfig.RoomSize.Y, LobbyConfig.RoomSize.Z
	local S = LobbyConfig.Vent.HatchSize
	local HY = LobbyConfig.Vent.HatchHeight

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	local function facing(x: number, y: number, z: number, direction: Vector3): CFrame
		local position = at(x, y, z).Position
		return CFrame.lookAt(position, position + origin:VectorToWorldSpace(direction))
	end

	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	lobby.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

	local structure = BuildKit.Group("Folder", "Structure", lobby)
	local decor = BuildKit.Group("Folder", "Decor", lobby)
	local lights = BuildKit.Group("Folder", "Lights", lobby)
	local propsFolder = BuildKit.Group("Folder", "Props", lobby)
	local points = BuildKit.Group("Folder", "Points", lobby)

	local function block(
		name: string,
		cframe: CFrame,
		size: Vector3,
		color: Color3,
		material: Enum.Material,
		parent: Instance?
	)
		return BuildKit.Part({
			Name = name,
			CFrame = cframe,
			Size = size,
			Color = color,
			Material = material,
			Parent = parent or structure,
		})
	end

	local floorWidth = W - CHANNEL + T
	block(
		"Floor",
		at((CHANNEL + T) / 2, -2, 0),
		Vector3.new(floorWidth, 4, D + T * 2),
		colors.Floor,
		Enum.Material.Concrete
	)
	block(
		"ChannelBed",
		at(-W / 2 + (CHANNEL - T) / 2, -4, 0),
		Vector3.new(CHANNEL + T, 2, D + T * 2),
		colors.Floor:Lerp(Color3.new(), 0.35),
		Enum.Material.Slate
	)
	block("Ceiling", at(0, H + 1, 0), Vector3.new(W + T * 2, 2, D + T * 2), colors.Ceiling, Enum.Material.Concrete)

	local water = BuildKit.Part({
		Name = "Water",
		CFrame = at(-W / 2 + CHANNEL / 2, -1.95, 0),
		Size = Vector3.new(CHANNEL, 2.1, D),
		Color = colors.Water,
		Material = Enum.Material.Glass,
		Transparency = 0.3,
		Reflectance = 0.08,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Parent = structure,
	})
	water:SetAttribute("AmbientSound", "SewerAmbience")
	CollectionService:AddTag(water, "ZMWater")
	CollectionService:AddTag(water, "ZMAmbient")

	local wallHeight = H + 3
	local wallY = (H - 3) / 2
	block(
		"WallLeft",
		at(-W / 2 - T / 2, wallY, 0),
		Vector3.new(T, wallHeight, D + T * 2),
		colors.Walls,
		Enum.Material.Concrete
	)
	block("WallRight", at(W / 2 + T / 2, H / 2, 0), Vector3.new(T, H, D + T * 2), colors.Walls, Enum.Material.Concrete)
	block(
		"WallFront",
		at(0, wallY, -D / 2 - T / 2),
		Vector3.new(W, wallHeight, T),
		colors.Walls,
		Enum.Material.Concrete
	)

	local backZ = D / 2 + T / 2
	local leftWidth = W / 2 - S / 2
	block(
		"WallBackLeft",
		at(-W / 2 + leftWidth / 2, wallY, backZ),
		Vector3.new(leftWidth, wallHeight, T),
		colors.Walls,
		Enum.Material.Concrete
	)
	block(
		"WallBackRight",
		at(W / 2 - leftWidth / 2, wallY, backZ),
		Vector3.new(leftWidth, wallHeight, T),
		colors.Walls,
		Enum.Material.Concrete
	)
	block("WallBackBottom", at(0, (HY - 3) / 2, backZ), Vector3.new(S, HY + 3, T), colors.Walls, Enum.Material.Concrete)
	block(
		"WallBackTop",
		at(0, (HY + S + H) / 2, backZ),
		Vector3.new(S, H - HY - S, T),
		colors.Walls,
		Enum.Material.Concrete
	)

	local band = 4
	block(
		"BandRight",
		at(W / 2 - 0.1, band / 2, 0),
		Vector3.new(0.2, band, D),
		colors.WallsBottom,
		Enum.Material.Concrete
	)
	block(
		"BandFront",
		at(0, band / 2, -D / 2 + 0.1),
		Vector3.new(W, band, 0.2),
		colors.WallsBottom,
		Enum.Material.Concrete
	)
	block(
		"BandBack",
		at(0, band / 2, D / 2 - 0.1),
		Vector3.new(W, band, 0.2),
		colors.WallsBottom,
		Enum.Material.Concrete
	)
	block(
		"ChannelEdge",
		at(-W / 2 + CHANNEL + 0.3, 0.15, 0),
		Vector3.new(0.6, 0.3, D),
		colors.Hazard,
		Enum.Material.SmoothPlastic
	)

	for _, spot in { Vector2.new(-20, -10), Vector2.new(-20, 10), Vector2.new(20, -10), Vector2.new(20, 10) } do
		block(
			"Pillar",
			at(spot.X, H / 2, spot.Y),
			Vector3.new(3, H, 3),
			colors.Walls:Lerp(Color3.new(), 0.1),
			Enum.Material.Concrete
		)
		block("PillarBase", at(spot.X, 1, spot.Y), Vector3.new(3.4, 2, 3.4), colors.WallsBottom, Enum.Material.Concrete)
	end

	local pipes = BuildKit.Group("Folder", "Pipes", decor)
	local function pipe(name: string, cframe: CFrame, length: number, diameter: number, color: Color3)
		BuildKit.Part({
			Name = name,
			Shape = Enum.PartType.Cylinder,
			CFrame = cframe,
			Size = Vector3.new(length, diameter, diameter),
			Color = color,
			Material = Enum.Material.Metal,
			Parent = pipes,
		})
	end
	local alongZ = CFrame.Angles(0, math.rad(90), 0)
	pipe("CeilingPipe", at(-W / 2 + 3, H - 1.6, 0) * alongZ, D, 2.2, colors.Rust)
	pipe("CeilingPipe", at(-W / 2 + 5.6, H - 1.1, 0) * alongZ, D, 1.2, colors.Metal)
	pipe("CeilingPipe", at(0, H - 1.4, D / 2 - 3), W, 1.6, colors.Metal:Lerp(colors.Rust, 0.4))
	pipe("CeilingPipe", at(W / 2 - 4, H - 1.2, 0) * alongZ, D, 1, colors.Metal)

	for _, outlet in { { z = -14, d = 6 }, { z = 12, d = 4.5 } } do
		pipe("Outlet", at(-W / 2 + 1.5, 2.6, outlet.z), 3, outlet.d, colors.Rust:Lerp(Color3.new(), 0.2))
		local mouth = BuildKit.Part({
			Name = "OutletMouth",
			Shape = Enum.PartType.Cylinder,
			CFrame = at(-W / 2 + 3.02, 2.6, outlet.z),
			Size = Vector3.new(0.05, outlet.d - 1.2, outlet.d - 1.2),
			Color = Color3.fromRGB(8, 10, 8),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
			Parent = pipes,
		})
		local drip = Instance.new("Attachment")
		drip.Position = Vector3.new(0, -(outlet.d - 1.2) / 2 + 0.3, 0)
		drip.Parent = mouth
		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(colors.Water:Lerp(Color3.new(1, 1, 1), 0.25))
		emitter.LightEmission = 0.1
		emitter.Size = NumberSequence.new(0.18, 0.1)
		emitter.Transparency = NumberSequence.new(0.2, 0.6)
		emitter.Lifetime = NumberRange.new(0.4, 0.6)
		emitter.Rate = outlet.d * 6
		emitter.Speed = NumberRange.new(3, 5)
		emitter.SpreadAngle = Vector2.new(12, 12)
		emitter.Acceleration = Vector3.new(0, -60, 0)
		emitter.EmissionDirection = Enum.NormalId.Right
		emitter.Parent = drip
	end

	BuildKit.Sign(
		BuildKit.Part({
			Name = "WaterSign",
			CFrame = facing(-W / 2 + 0.06, 7, -1, Vector3.new(1, 0, 0)),
			Size = Vector3.new(6, 1.6, 0.1),
			Color = Color3.fromRGB(150, 28, 24),
			CanCollide = false,
			Parent = decor,
		}),
		"SignWater",
		Color3.fromRGB(245, 240, 230),
		Color3.fromRGB(150, 28, 24)
	)

	local lampIndex = 0
	for _, x in { -14, 4, 22 } do
		for _, z in { -12, 10 } do
			lampIndex += 1
			local fixture = BuildKit.Group("Model", "Lamp", lights)
			BuildKit.Part({
				Name = "Housing",
				CFrame = at(x, H - 0.25, z),
				Size = Vector3.new(2, 0.5, 9),
				Color = colors.Metal:Lerp(Color3.new(), 0.4),
				Material = Enum.Material.Metal,
				Parent = fixture,
			})
			local tube = BuildKit.Part({
				Name = "Tube",
				CFrame = at(x, H - 0.6, z),
				Size = Vector3.new(0.8, 0.3, 8),
				Color = colors.Lamp,
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = fixture,
			})
			BuildKit.Light("PointLight", {
				Color = colors.Lamp,
				Range = LobbyConfig.LampRange,
				Brightness = LobbyConfig.LampBrightness,
				Shadows = true,
				Parent = tube,
			})
			if lampIndex == 5 then
				CollectionService:AddTag(tube, "ZMFlicker")
			end
		end
	end

	local vent = VentBuilder.Build(origin, lobby)
	local landingZ = D / 2 - 15
	block("Mattress", at(0, 0.5, landingZ), Vector3.new(10, 1, 8), colors.Mattress, Enum.Material.Fabric, decor)
	block(
		"Mattress",
		at(-1.2, 1.3, landingZ + 0.8) * CFrame.Angles(0, math.rad(12), 0),
		Vector3.new(8, 0.6, 6),
		colors.Mattress:Lerp(Color3.fromRGB(80, 90, 110), 0.35),
		Enum.Material.Fabric,
		decor
	)
	local zoneMinZ, zoneMaxZ, zoneX = D / 2 - 23, D / 2 - 1, 7
	local zoneDepth = zoneMaxZ - zoneMinZ
	local zoneMidZ = (zoneMinZ + zoneMaxZ) / 2
	block(
		"Hazard",
		at(-zoneX, 0.03, zoneMidZ),
		Vector3.new(0.7, 0.06, zoneDepth),
		colors.Hazard,
		Enum.Material.SmoothPlastic,
		decor
	)
	block(
		"Hazard",
		at(zoneX, 0.03, zoneMidZ),
		Vector3.new(0.7, 0.06, zoneDepth),
		colors.Hazard,
		Enum.Material.SmoothPlastic,
		decor
	)
	block(
		"Hazard",
		at(0, 0.03, zoneMinZ),
		Vector3.new(zoneX * 2 + 0.7, 0.06, 0.7),
		colors.Hazard,
		Enum.Material.SmoothPlastic,
		decor
	)

	local boardCFrame = facing(0, 10, -D / 2 + 0.25, Vector3.new(0, 0, 1))
	BuildKit.Part({
		Name = "InfoBoard",
		CFrame = boardCFrame,
		Size = Vector3.new(22, 11, 0.3),
		Color = Color3.fromRGB(10, 14, 10),
		Material = Enum.Material.SmoothPlastic,
		Parent = decor,
	})
	BuildKit.Part({
		Name = "InfoBoardFrame",
		CFrame = boardCFrame * CFrame.new(0, 0, 0.15),
		Size = Vector3.new(23.2, 12.2, 0.3),
		Color = colors.Metal:Lerp(Color3.new(), 0.3),
		Material = Enum.Material.Metal,
		Parent = decor,
	})

	local doorX = W / 2 - 16
	BuildKit.Part({
		Name = "Door",
		CFrame = at(doorX, 4.5, -D / 2 + 0.2),
		Size = Vector3.new(5, 9, 0.4),
		Color = Color3.fromRGB(52, 70, 58),
		Material = Enum.Material.Metal,
		Parent = decor,
	})
	BuildKit.Part({
		Name = "DoorHandle",
		CFrame = at(doorX + 1.7, 4.2, -D / 2 + 0.5),
		Size = Vector3.new(0.3, 0.9, 0.3),
		Color = colors.Metal,
		Material = Enum.Material.Metal,
		Parent = decor,
	})
	BuildKit.Sign(
		BuildKit.Part({
			Name = "StaffSign",
			CFrame = facing(doorX, 6.6, -D / 2 + 0.43, Vector3.new(0, 0, 1)),
			Size = Vector3.new(3.8, 1.1, 0.05),
			Color = Color3.fromRGB(235, 232, 220),
			CanCollide = false,
			Parent = decor,
		}),
		"SignStaff",
		Color3.fromRGB(170, 20, 20),
		Color3.fromRGB(235, 232, 220)
	)
	local exitSign = BuildKit.Part({
		Name = "ExitSign",
		CFrame = facing(doorX, 10.3, -D / 2 + 0.35, Vector3.new(0, 0, 1)),
		Size = Vector3.new(4, 1.3, 0.5),
		Color = Color3.fromRGB(30, 140, 60),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = decor,
	})
	BuildKit.Sign(exitSign, "SignExit", Color3.fromRGB(235, 255, 235))
	BuildKit.Light(
		"PointLight",
		{ Color = Color3.fromRGB(60, 255, 110), Range = 7, Brightness = 0.8, Parent = exitSign }
	)

	local function crate(name: string, cframe: CFrame, size: number, anchored: boolean, shade: number): BasePart
		local part = BuildKit.Part({
			Name = name,
			CFrame = cframe,
			Size = Vector3.new(size, size, size),
			Color = colors.Crate:Lerp(Color3.new(), shade),
			Material = Enum.Material.WoodPlanks,
			Anchored = anchored,
			Parent = propsFolder,
		})
		return part
	end

	crate("Crate", at(W / 2 - 3, 2, -D / 2 + 3), 4, true, 0.1)
	crate("Crate", at(W / 2 - 3, 2, -D / 2 + 7.5), 4, true, 0.2)
	crate("Crate", at(W / 2 - 7.5, 2, -D / 2 + 3), 4, true, 0)
	crate("Crate", at(W / 2 - 3, 6, -D / 2 + 4.5), 4, true, 0.15)
	crate("Crate", at(W / 2 - 3, 2.5, D / 2 - 3.5), 5, true, 0.25)
	crate("Crate", at(W / 2 - 3, 7, D / 2 - 3.5) * CFrame.Angles(0, math.rad(18), 0), 4, true, 0.05)

	local props: { BasePart } = {}
	local woodProps = PhysicalProperties.new(0.45, 0.5, 0.15, 1, 1)
	local metalProps = PhysicalProperties.new(0.35, 0.35, 0.25, 1, 1)
	local crateSpots = {
		Vector3.new(12, 2, -4),
		Vector3.new(16.5, 2, -4),
		Vector3.new(14.2, 6.05, -4),
		Vector3.new(12, 2, 2),
		Vector3.new(26, 2, 4),
		Vector3.new(-10, 2, -18),
		Vector3.new(6, 2, -20),
		Vector3.new(26, 2, -8),
	}
	for i = 1, math.min(LobbyConfig.PhysicsCrates, #crateSpots) do
		local spot = crateSpots[i]
		local part = crate("PhysicsCrate", at(spot.X, spot.Y, spot.Z), 4, false, (i % 3) * 0.08)
		part.CustomPhysicalProperties = woodProps
		part:SetAttribute("Surface", "Wood")
		table.insert(props, part)
	end
	local barrelSpots = {
		Vector3.new(8, 1.75, 10),
		Vector3.new(10.8, 1.75, 11.5),
		Vector3.new(-14, 1.75, 16),
		Vector3.new(28, 1.75, 14),
		Vector3.new(-6, 1.75, -6),
		Vector3.new(30, 1.75, -14),
	}
	local barrelColors = { colors.Rust, Color3.fromRGB(62, 84, 58), Color3.fromRGB(150, 42, 34) }
	for i = 1, math.min(LobbyConfig.PhysicsBarrels, #barrelSpots) do
		local spot = barrelSpots[i]
		local part = BuildKit.Part({
			Name = "PhysicsBarrel",
			Shape = Enum.PartType.Cylinder,
			CFrame = at(spot.X, spot.Y, spot.Z) * CFrame.Angles(0, 0, math.rad(90)),
			Size = Vector3.new(3.5, 2.6, 2.6),
			Color = barrelColors[(i - 1) % #barrelColors + 1],
			Material = Enum.Material.CorrodedMetal,
			Anchored = false,
			CustomPhysicalProperties = metalProps,
			Parent = propsFolder,
		})
		part:SetAttribute("Surface", "Metal")
		table.insert(props, part)
	end
	for _, part in props do
		part:SetAttribute("Home", part.CFrame)
		CollectionService:AddTag(part, "ZMProp")
	end

	local markerProps = {
		Size = Vector3.new(1, 1, 1),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Parent = points,
	}
	local landingProps = table.clone(markerProps)
	landingProps.Name = "Landing"
	landingProps.CFrame = facing(4, 3, landingZ - 7, Vector3.new(0, 0, -1))
	local landing = BuildKit.Part(landingProps)

	local holdCenter = at(0, -HOLD_DEPTH, 0)
	BuildKit.Box(
		"HoldRoom",
		holdCenter,
		Vector3.new(16, 10, 16),
		1,
		{ Color = Color3.fromRGB(20, 20, 20), Material = Enum.Material.Concrete },
		points
	)
	local holdProps = table.clone(markerProps)
	holdProps.Name = "Hold"
	holdProps.CFrame = holdCenter * CFrame.new(0, -1, 0)
	local hold = BuildKit.Part(holdProps)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "VentSpawn"
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = false
	spawnLocation.CanQuery = false
	spawnLocation.CanTouch = false
	spawnLocation.Transparency = 1
	spawnLocation.Size = Vector3.new(6, 1, 6)
	spawnLocation.CFrame = holdCenter * CFrame.new(0, -4.5, 0)
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = points
	local decal = spawnLocation:FindFirstChildOfClass("Decal")
	if decal then
		decal:Destroy()
	end

	lobby.WorldPivot = origin
	lobby.Parent = workspace

	return {
		Model = lobby,
		Origin = origin,
		Exit = vent.Exit,
		Start = vent.Start,
		Landing = landing,
		Hold = hold,
		SpawnLocation = spawnLocation,
		Props = props,
	}
end

return LobbyBuilder
