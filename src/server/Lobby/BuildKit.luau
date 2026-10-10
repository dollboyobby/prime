local CollectionService = game:GetService("CollectionService")

local BuildKit = {}

export type Props = { [string]: any }

function BuildKit.Part(props: Props, className: string?): BasePart
	local part = Instance.new(className or "Part") :: BasePart
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = Enum.Material.SmoothPlastic
	local parent = props.Parent
	for key, value in props do
		if key ~= "Parent" then
			(part :: any)[key] = value
		end
	end
	part.Parent = parent
	return part
end

function BuildKit.Group(className: string, name: string, parent: Instance): Instance
	local group = Instance.new(className)
	group.Name = name
	group.Parent = parent
	return group
end

function BuildKit.Light(className: string, props: Props): Light
	local light = Instance.new(className) :: Light
	local parent = props.Parent
	for key, value in props do
		if key ~= "Parent" then
			(light :: any)[key] = value
		end
	end
	light.Parent = parent
	return light
end

function BuildKit.Sign(part: BasePart, key: string, textColor: Color3, background: Color3?): BasePart
	part:SetAttribute("SignKey", key)
	part:SetAttribute("SignTextColor", textColor)
	if background then
		part:SetAttribute("SignBackground", background)
	end
	CollectionService:AddTag(part, "ZMSign")
	return part
end

function BuildKit.Box(
	name: string,
	cframe: CFrame,
	size: Vector3,
	thickness: number,
	props: Props,
	parent: Instance
): Model
	local model = Instance.new("Model")
	model.Name = name
	local half = size / 2
	local t = thickness
	local faces = {
		{
			Name = "Floor",
			Offset = CFrame.new(0, -half.Y - t / 2, 0),
			Size = Vector3.new(size.X + t * 2, t, size.Z + t * 2),
		},
		{
			Name = "Ceiling",
			Offset = CFrame.new(0, half.Y + t / 2, 0),
			Size = Vector3.new(size.X + t * 2, t, size.Z + t * 2),
		},
		{ Name = "Left", Offset = CFrame.new(-half.X - t / 2, 0, 0), Size = Vector3.new(t, size.Y, size.Z + t * 2) },
		{ Name = "Right", Offset = CFrame.new(half.X + t / 2, 0, 0), Size = Vector3.new(t, size.Y, size.Z + t * 2) },
		{ Name = "Back", Offset = CFrame.new(0, 0, half.Z + t / 2), Size = Vector3.new(size.X, size.Y, t) },
		{ Name = "Front", Offset = CFrame.new(0, 0, -half.Z - t / 2), Size = Vector3.new(size.X, size.Y, t) },
	}
	for _, face in faces do
		local partProps = table.clone(props)
		partProps.Name = face.Name
		partProps.CFrame = cframe * face.Offset
		partProps.Size = face.Size
		partProps.Parent = model
		BuildKit.Part(partProps)
	end
	model.Parent = parent
	return model
end

return BuildKit
