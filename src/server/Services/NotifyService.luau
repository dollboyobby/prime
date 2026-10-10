local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local NotifyService = {}

local remote: RemoteEvent

function NotifyService.Init()
	remote = Remotes.Get("Notify")
end

function NotifyService.Chat(key: string, ...: any)
	remote:FireAllClients("Chat", key, { ... })
end

function NotifyService.Center(key: string, ...: any)
	remote:FireAllClients("Center", key, { ... })
end

function NotifyService.ChatTo(player: Player, key: string, ...: any)
	remote:FireClient(player, "Chat", key, { ... })
end

function NotifyService.CenterTo(player: Player, key: string, ...: any)
	remote:FireClient(player, "Center", key, { ... })
end

return NotifyService
