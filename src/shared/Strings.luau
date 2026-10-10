-- Все тексты игры на двух языках. Тексты можно менять как угодно,
-- главное не трогать %s и %d - туда подставляются ники, карты и числа.

local LocalizationService = game:GetService("LocalizationService")
local RunService = game:GetService("RunService")

local GameConfig = require(script.Parent.Config.GameConfig)

local TEXT = {
	WaitingPlayers = { ru = "Ждём игроков (%d/%d)", en = "Waiting for players (%d/%d)" },
	VoteRunning = { ru = "Голосование за карту", en = "Map vote" },
	NextMap = { ru = "Следующая карта: %s", en = "Next map: %s" },
	CurrentMap = { ru = "Карта: %s", en = "Map: %s" },
	RoundOver = { ru = "Раунд окончен", en = "Round over" },

	VoteStarted = {
		ru = "Пора выбрать следующую карту...",
		en = "It's time to choose the next map...",
	},
	VoteTitle = { ru = "Выберите следующую карту:", en = "Choose the next map:" },
	VoteExit = { ru = "Выход", en = "Exit" },
	VoteReopen = { ru = "M - голосование", en = "M - map vote" },
	VoteChose = { ru = "%s выбрал %s", en = "%s chose %s" },
	VoteFinished = {
		ru = "Голосование завершено. Следующая карта: %s",
		en = "Voting has finished. The next map will be %s",
	},
	VoteNobody = {
		ru = "Никто не голосовал. Следующая карта: %s",
		en = "Nobody voted. The next map will be %s",
	},
	VoteCancelled = {
		ru = "Голосование отменено, мало игроков",
		en = "Vote cancelled, not enough players",
	},

	RoundStarted = { ru = "Раунд начался! Карта: %s", en = "Round started! Map: %s" },
	RoundStartedCenter = { ru = "Вперёд, вперёд, вперёд!", en = "Go, go, go!" },
	RoundEnded = {
		ru = "Раунд окончен. Все обратно в лобби",
		en = "Round over. Everyone back to the lobby",
	},
	RoundInProgress = {
		ru = "Раунд уже идёт, жди следующий",
		en = "Round in progress, wait for the next one",
	},

	Arrived = { ru = "%s выпал из вентиляции", en = "%s fell out of the vent" },

	HintRagdoll = { ru = "R - упасть", en = "R - ragdoll" },
	ButtonRagdoll = { ru = "Упасть", en = "Ragdoll" },

	BoardStatus = { ru = "СТАТУС", en = "STATUS" },
	BoardPlayers = { ru = "ИГРОКОВ", en = "PLAYERS" },
	BoardMap = { ru = "КАРТА", en = "MAP" },
	BoardVotes = { ru = "ГОЛОСА", en = "VOTES" },
	BoardWaiting = { ru = "ЖДЁМ ИГРОКОВ", en = "WAITING" },
	BoardVote = { ru = "ГОЛОСОВАНИЕ", en = "VOTING" },
	BoardStarting = { ru = "СКОРО СТАРТ", en = "STARTING" },
	BoardRound = { ru = "ИДЁТ РАУНД", en = "ROUND IN PROGRESS" },
	BoardRoundEnd = { ru = "КОНЕЦ РАУНДА", en = "ROUND OVER" },

	SignVent = { ru = "НЕ СТОЙ ПОД ЛЮКОМ", en = "DO NOT STAND UNDER THE VENT" },
	SignExit = { ru = "ВЫХОД", en = "EXIT" },
	SignStaff = { ru = "ТОЛЬКО ДЛЯ ПЕРСОНАЛА", en = "STAFF ONLY" },
	SignWater = { ru = "НЕ ПИТЬ", en = "NOT FOR DRINKING" },
}

local Strings = {}

local function detectLanguage(): string
	if GameConfig.Language ~= "auto" then
		return GameConfig.Language
	end
	if RunService:IsClient() then
		local ok, locale = pcall(function()
			return LocalizationService.RobloxLocaleId
		end)
		if ok and type(locale) == "string" and string.sub(locale, 1, 2) == "ru" then
			return "ru"
		end
		local okSystem, systemLocale = pcall(function()
			return LocalizationService.SystemLocaleId
		end)
		if okSystem and type(systemLocale) == "string" and string.sub(systemLocale, 1, 2) == "ru" then
			return "ru"
		end
	end
	return "en"
end

Strings.Language = detectLanguage()

function Strings.Get(key: string, ...: any): string
	local entry = TEXT[key]
	if not entry then
		return key
	end
	local text = entry[Strings.Language] or entry.en
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, text, ...)
		if ok then
			return formatted
		end
	end
	return text
end

function Strings.Time(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", total // 60, total % 60)
end

return Strings
