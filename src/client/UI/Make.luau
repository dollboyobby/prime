local Players = game:GetService("Players")

local Make = {}

function Make.New(className: string, props: { [string]: any }?, children: { Instance }?): any
	local instance = Instance.new(className)
	local properties: { [string]: any } = props or {}
	local list: { Instance } = children or {}
	local parent = nil
	for key, value in properties do
		if key == "Parent" then
			parent = value
		else
			(instance :: any)[key] = value
		end
	end
	for _, child in list do
		child.Parent = instance
	end
	instance.Parent = parent
	return instance
end

function Make.Screen(name: string, displayOrder: number): ScreenGui
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	local screen = Make.New("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = displayOrder,
		Parent = playerGui,
	})
	local scale = Make.New("UIScale", { Parent = screen })
	local camera = workspace.CurrentCamera
	local function rescale()
		scale.Scale = math.clamp(camera.ViewportSize.Y / 820, 0.6, 1.25)
	end
	rescale()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	return screen
end

function Make.Label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		TextStrokeTransparency = 0.55,
		TextStrokeColor3 = Color3.new(0, 0, 0),
		RichText = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	return Make.New("TextLabel", defaults)
end

function Make.Escape(text: string): string
	return (
		string.gsub(text, "[&<>\"']", {
			["&"] = "&amp;",
			["<"] = "&lt;",
			[">"] = "&gt;",
			['"'] = "&quot;",
			["'"] = "&apos;",
		})
	)
end

return Make
