local CollisionGroups = require(script.Parent.Util.CollisionGroups)

CollisionGroups.Setup()

local Services = script.Parent.Services
local order = {
	"NotifyService",
	"LobbyService",
	"RagdollService",
	"SpawnService",
	"MapService",
	"VoteService",
	"RoundService",
}

local loaded = {}
for _, name in order do
	local service = require(Services:WaitForChild(name)) :: any
	if service.Init then
		service.Init()
	end
	table.insert(loaded, service)
end

for _, service in loaded do
	if service.Start then
		service.Start()
	end
end
