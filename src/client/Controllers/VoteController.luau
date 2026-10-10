local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(ReplicatedStorage.Shared.GameState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Make = require(script.Parent.Parent.UI.Make)
local Theme = require(script.Parent.Parent.UI.Theme)

local VoteController = {}

local KEYS_ACTION = "ZMVoteKeys"
local OPEN_ACTION = "ZMVoteOpen"

local NUMBER_KEYS = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.KeypadFive] = 5,
	[Enum.KeyCode.KeypadSix] = 6,
	[Enum.KeyCode.KeypadSeven] = 7,
	[Enum.KeyCode.KeypadEight] = 8,
	[Enum.KeyCode.KeypadNine] = 9,
	[Enum.KeyCode.Zero] = 0,
	[Enum.KeyCode.KeypadZero] = 0,
}

type VoteOption = { Id: string, Name: string, Votes: number }
type VoteData = { Open: boolean, EndsAt: number, Options: { VoteOption } }

local remote: RemoteEvent
local menu: Frame
local list: Frame
local reopen: TextButton
local vote: VoteData? = nil
local votedIn: number? = nil
local hidden = false
local keysBound = false
local openBound = false

local function decode(raw: any): VoteData?
	if type(raw) ~= "string" or raw == "" then
		return nil
	end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(data) == "table" then
		return data :: VoteData
	end
	return nil
end

local function canVote(): boolean
	return vote ~= nil and vote.Open and votedIn ~= vote.EndsAt
end

local function castVote(index: number)
	if not canVote() or not vote or not vote.Options[index] then
		return
	end
	votedIn = vote.EndsAt
	remote:FireServer(index)
	SoundPlayer.Play("MenuSelect")
	VoteController.Refresh()
end

local function bindKeys(enabled: boolean)
	if enabled == keysBound then
		return
	end
	keysBound = enabled
	if enabled then
		local keys = {}
		for key in NUMBER_KEYS do
			table.insert(keys, key)
		end
		ContextActionService:BindActionAtPriority(KEYS_ACTION, function(_, state, input)
			if state ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
			local number = NUMBER_KEYS[input.KeyCode]
			if number == 0 then
				hidden = true
				VoteController.Refresh()
			elseif number then
				castVote(number)
			end
			return Enum.ContextActionResult.Sink
		end, false, Enum.ContextActionPriority.High.Value, table.unpack(keys))
	else
		ContextActionService:UnbindAction(KEYS_ACTION)
	end
end

local function bindOpen(enabled: boolean)
	if enabled == openBound then
		return
	end
	openBound = enabled
	if enabled then
		ContextActionService:BindAction(OPEN_ACTION, function(_, state)
			if state == Enum.UserInputState.Begin then
				hidden = false
				VoteController.Refresh()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.M)
	else
		ContextActionService:UnbindAction(OPEN_ACTION)
	end
end

local function line(text: string, order: number, onClick: (() -> ())?)
	local button = Make.New("TextButton", {
		Name = "Line",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		RichText = true,
		Text = text,
		FontFace = Theme.FontBold,
		TextSize = 19,
		TextColor3 = Theme.Text,
		TextStrokeTransparency = 0.6,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = list,
	})
	if onClick then
		button.Activated:Connect(onClick)
	end
end

function VoteController.Refresh()
	for _, child in list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	local showMenu = canVote() and not hidden
	menu.Visible = showMenu
	reopen.Visible = canVote() and hidden
	bindKeys(showMenu)
	bindOpen(canVote() and hidden)
	if not showMenu or not vote then
		return
	end

	local yellow = Theme.Hud:ToHex()
	local grey = Theme.Muted:ToHex()
	line(string.format('<font color="#%s">%s</font>', yellow, Make.Escape(Strings.Get("VoteTitle"))), 0)
	line("", 1)
	for index, option in vote.Options do
		local text =
			string.format('%d. %s <font color="#%s">(%d)</font>', index, Make.Escape(option.Name), grey, option.Votes)
		line(text, index + 1, function()
			castVote(index)
		end)
	end
	line("", 20)
	line(string.format("0. %s", Make.Escape(Strings.Get("VoteExit"))), 21, function()
		hidden = true
		VoteController.Refresh()
	end)
end

function VoteController.Init()
	remote = Remotes.Get("Vote")
	local screen = Make.Screen("ZMVote", 6)

	menu = Make.New("Frame", {
		Name = "Menu",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 26, 0.5, 0),
		Size = UDim2.fromOffset(400, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Visible = false,
		Parent = screen,
	}, {
		Make.New("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
	})

	list = Make.New("Frame", {
		Name = "List",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = menu,
	}, {
		Make.New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	reopen = Make.New("TextButton", {
		Name = "Reopen",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 26, 0.5, 0),
		Size = UDim2.fromOffset(220, 30),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Text = Strings.Get("VoteReopen"),
		FontFace = Theme.FontBold,
		TextSize = 17,
		TextColor3 = Theme.Hud,
		Visible = false,
		Parent = screen,
	})
	reopen.Activated:Connect(function()
		hidden = false
		VoteController.Refresh()
	end)
end

function VoteController.Start()
	local function update(raw: any)
		local previous = vote and vote.EndsAt
		vote = decode(raw)
		if vote and vote.EndsAt ~= previous then
			hidden = false
		end
		VoteController.Refresh()
	end
	GameState.Changed("Vote", update)
	update(GameState.Get("Vote"))
end

return VoteController
