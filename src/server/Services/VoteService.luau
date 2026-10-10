local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameState = require(ReplicatedStorage.Shared.GameState)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local MapService = require(script.Parent.MapService)
local NotifyService = require(script.Parent.NotifyService)

local VoteService = {}

local MAX_OPTIONS = 9

local options: { MapService.MapInfo } = {}
local votes: { [Player]: number } = {}
local open = false
local endsAt = 0
local random = Random.new()

local function counts(): { number }
	local result = table.create(#options, 0)
	for _, index in votes do
		result[index] += 1
	end
	return result
end

local function publish()
	local tally = counts()
	local list = {}
	for index, info in options do
		table.insert(list, { Id = info.Id, Name = info.Name, Votes = tally[index] })
	end
	GameState.Set(
		"Vote",
		HttpService:JSONEncode({
			Open = open,
			EndsAt = endsAt,
			Options = list,
		})
	)
end

local function pickOptions(): { MapService.MapInfo }
	local available = MapService.GetAvailable()
	if #available <= MAX_OPTIONS then
		return available
	end
	local first = available[1]
	local rest = table.clone(available)
	table.remove(rest, 1)
	local picked = { first }
	while #picked < MAX_OPTIONS do
		table.insert(picked, table.remove(rest, random:NextInteger(1, #rest)) :: MapService.MapInfo)
	end
	return picked
end

function VoteService.Open(duration: number): boolean
	options = pickOptions()
	votes = {}
	if #options == 0 then
		open = false
		publish()
		return false
	end
	open = true
	endsAt = workspace:GetServerTimeNow() + duration
	publish()
	NotifyService.Chat("VoteStarted")
	return true
end

function VoteService.IsOpen(): boolean
	return open
end

function VoteService.EndsAt(): number
	return endsAt
end

function VoteService.Finish(): string?
	if #options == 0 then
		return nil
	end
	open = false
	local tally = counts()
	local best, bestVotes = {}, -1
	for index, amount in tally do
		if amount > bestVotes then
			best, bestVotes = { index }, amount
		elseif amount == bestVotes then
			table.insert(best, index)
		end
	end
	local winner = options[best[random:NextInteger(1, #best)]]
	publish()
	if bestVotes > 0 then
		NotifyService.Chat("VoteFinished", winner.Name)
	else
		NotifyService.Chat("VoteNobody", winner.Name)
	end
	return winner.Id
end

function VoteService.Cancel()
	if not open then
		return
	end
	open = false
	options = {}
	votes = {}
	publish()
	NotifyService.Chat("VoteCancelled")
end

function VoteService.Init()
	publish()
end

function VoteService.Start()
	Remotes.Get("Vote").OnServerEvent:Connect(function(player, index)
		if not open or votes[player] or type(index) ~= "number" then
			return
		end
		if index ~= index // 1 or index < 1 or index > #options then
			return
		end
		votes[player] = index
		publish()
		NotifyService.Chat("VoteChose", player.DisplayName, options[index].Name)
	end)
	Players.PlayerRemoving:Connect(function(player)
		if votes[player] then
			votes[player] = nil
			publish()
		end
	end)
end

return VoteService
