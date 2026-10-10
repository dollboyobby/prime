local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Strings = require(ReplicatedStorage.Shared.Strings)
local HudController = require(script.Parent.HudController)
local Make = require(script.Parent.Parent.UI.Make)
local Theme = require(script.Parent.Parent.UI.Theme)

local NotifyController = {}

local function systemChannel(): TextChannel?
	if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		return nil
	end
	local channels = TextChatService:FindFirstChild("TextChannels")
	local channel = channels and channels:FindFirstChild("RBXSystem")
	if channel and channel:IsA("TextChannel") then
		return channel
	end
	return nil
end

function NotifyController.Chat(text: string)
	local channel = systemChannel()
	if channel then
		local line = string.format(
			'<font color="#%s">%s</font> %s',
			Theme.Hud:ToHex(),
			Make.Escape(GameConfig.ChatTag),
			Make.Escape(text)
		)
		local ok = pcall(channel.DisplaySystemMessage, channel, line)
		if ok then
			return
		end
	end
	pcall(StarterGui.SetCore, StarterGui, "ChatMakeSystemMessage", {
		Text = GameConfig.ChatTag .. " " .. text,
		Color = Theme.Hud,
	})
end

function NotifyController.Start()
	Remotes.Get("Notify").OnClientEvent:Connect(function(kind: string, key: string, args: { any }?)
		local text = Strings.Get(key, table.unpack(args or {}))
		if kind == "Center" then
			HudController.Announce(text)
		else
			NotifyController.Chat(text)
		end
	end)
end

return NotifyController
