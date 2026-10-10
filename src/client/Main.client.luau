local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundPlayer = require(ReplicatedStorage.Shared.SoundPlayer)

SoundPlayer.Preload()

local Controllers = script.Parent:WaitForChild("Controllers")
local order = {
	"HudController",
	"NotifyController",
	"VoteController",
	"BoardController",
	"AmbienceController",
	"RagdollController",
	"ImpactController",
	"VentController",
}

local loaded = {}
for _, name in order do
	local controller = require(Controllers:WaitForChild(name)) :: any
	if controller.Init then
		controller.Init()
	end
	table.insert(loaded, controller)
end

for _, controller in loaded do
	if controller.Start then
		task.spawn(controller.Start)
	end
end
