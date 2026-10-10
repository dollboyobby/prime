local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local GameState = require(ReplicatedStorage.Shared.GameState)
local MapConfig = require(ReplicatedStorage.Shared.Config.MapConfig)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Make = require(script.Parent.Parent.UI.Make)
local Theme = require(script.Parent.Parent.UI.Theme)

local BoardController = {}

local Phase = GameState.Phase
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function mapName(id: any): string
	for _, info in MapConfig do
		if info.Id == id then
			return info.Name
		end
	end
	return "-"
end

local function phaseText(): string
	local phase = GameState.Get("Phase")
	if phase == Phase.Waiting then
		return Strings.Get("BoardWaiting")
	elseif phase == Phase.Intermission then
		local raw = GameState.Get("Vote")
		local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
		if ok and type(data) == "table" and data.Open then
			return Strings.Get("BoardVote")
		end
		return Strings.Get("BoardStarting")
	elseif phase == Phase.Round then
		return Strings.Get("BoardRound")
	elseif phase == Phase.RoundEnd then
		return Strings.Get("BoardRoundEnd")
	end
	return "-"
end

local function voteLines(): { string }
	local lines = {}
	local raw = GameState.Get("Vote")
	if type(raw) ~= "string" or raw == "" then
		return lines
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(data) ~= "table" or type(data.Options) ~= "table" then
		return lines
	end
	for index, option in data.Options do
		local name = tostring(option.Name)
		local length = utf8.len(name) or #name
		local dots = string.rep(".", math.max(2, 22 - length))
		table.insert(lines, string.format(" %d. %s %s %d", index, Make.Escape(name), dots, option.Votes or 0))
	end
	return lines
end

local function buildBoard(part: BasePart)
	local gui = Make.New("SurfaceGui", {
		Name = "ZMInfoBoard",
		Adornee = part,
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 45,
		LightInfluence = 0,
		Brightness = 1.4,
		ResetOnSpawn = false,
		ClipsDescendants = true,
		Parent = playerGui,
	})
	local frame = Make.New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(6, 12, 8),
		BorderSizePixel = 0,
		Parent = gui,
	}, {
		Make.New("UIPadding", {
			PaddingTop = UDim.new(0, 26),
			PaddingLeft = UDim.new(0, 34),
			PaddingRight = UDim.new(0, 34),
		}),
	})
	local title = Make.Label({
		Size = UDim2.new(1, 0, 0, 56),
		FontFace = Theme.FontMono,
		TextSize = 50,
		TextColor3 = Theme.Terminal,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "> " .. Make.Escape(GameConfig.ServerName),
		Parent = frame,
	})
	local body = Make.Label({
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.new(1, 0, 1, -80),
		FontFace = Theme.FontMono,
		TextSize = 32,
		LineHeight = 1.15,
		TextColor3 = Theme.Terminal,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Parent = frame,
	})

	task.spawn(function()
		local blink = false
		while gui.Parent do
			blink = not blink
			local timeLeft = GameState.TimeLeft()
			local status = phaseText()
			if timeLeft > 0 then
				status ..= "  " .. Strings.Time(timeLeft)
			end
			local lines = {
				string.format("%s: %s", Strings.Get("BoardStatus"), status),
				string.format("%s: %d", Strings.Get("BoardPlayers"), #Players:GetPlayers()),
				string.format("%s: %s", Strings.Get("BoardMap"), Make.Escape(mapName(GameState.Get("MapId")))),
			}
			local votes = voteLines()
			if #votes > 0 then
				table.insert(lines, "")
				table.insert(lines, Strings.Get("BoardVotes") .. ":")
				for _, voteLine in votes do
					table.insert(lines, voteLine)
				end
			end
			body.Text = table.concat(lines, "\n") .. (if blink then "\n_" else "\n ")
			title.TextTransparency = if blink then 0 else 0.08
			task.wait(0.5)
		end
	end)
end

local function buildSign(part: BasePart)
	local key = part:GetAttribute("SignKey")
	if type(key) ~= "string" then
		return
	end
	local textColor = part:GetAttribute("SignTextColor")
	local background = part:GetAttribute("SignBackground")
	local gui = Make.New("SurfaceGui", {
		Name = "ZMSign",
		Adornee = part,
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = 60,
		LightInfluence = if part.Material == Enum.Material.Neon then 0 else 0.6,
		ResetOnSpawn = false,
		Parent = playerGui,
	})
	Make.New("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = if typeof(background) == "Color3" then background else Color3.new(0, 0, 0),
		BackgroundTransparency = if typeof(background) == "Color3" then 0 else 1,
		BorderSizePixel = 0,
		Text = Strings.Get(key),
		TextScaled = true,
		FontFace = Theme.FontBold,
		TextColor3 = if typeof(textColor) == "Color3" then textColor else Color3.new(1, 1, 1),
		Parent = gui,
	}, {
		Make.New("UIPadding", {
			PaddingTop = UDim.new(0.14, 0),
			PaddingBottom = UDim.new(0.14, 0),
			PaddingLeft = UDim.new(0.04, 0),
			PaddingRight = UDim.new(0.04, 0),
		}),
	})
	part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(workspace) then
			gui:Destroy()
		end
	end)
end

function BoardController.Start()
	for _, part in CollectionService:GetTagged("ZMSign") do
		if part:IsA("BasePart") then
			buildSign(part)
		end
	end
	CollectionService:GetInstanceAddedSignal("ZMSign"):Connect(function(part)
		if part:IsA("BasePart") then
			buildSign(part)
		end
	end)

	local lobby = workspace:WaitForChild("Lobby", 60)
	local decor = lobby and lobby:WaitForChild("Decor", 10)
	local board = decor and decor:WaitForChild("InfoBoard", 10)
	if board and board:IsA("BasePart") then
		buildBoard(board)
	end
end

return BoardController
