-- Все звуки игры. Всё в этом файле можно менять.
--
-- Ids - список звуков, каждый раз берётся случайный. Сюда можно вставлять свои: "rbxassetid://1234567".
-- Pitch - случайная высота звука от и до (1 = как есть, меньше = ниже и тяжелее).
-- Пустой список Ids = звук просто не играет.
--
-- Сейчас стоят встроенные звуки Roblox (rbxasset://), они есть у всех и без авторских прав.
-- Оригинальные звуки из Garry's Mod принадлежат Valve, их загружать нельзя. Похожие можно найти
-- в Creator Store (Toolbox > Audio): "body impact", "body fall", "bone crack", "metal vent".

local LAND = "rbxasset://sounds/action_jump_land.mp3"

return {
	BodyImpactSoft = { Ids = { LAND }, Volume = 0.5, Pitch = { 1.15, 1.45 } }, -- тело слегка стукнулось
	BodyImpactHard = { Ids = { LAND }, Volume = 1, Pitch = { 0.7, 0.88 } }, -- тело сильно шмякнулось
	BodyBreak = { Ids = {}, Volume = 0.8, Pitch = { 0.95, 1.1 } }, -- хруст при очень сильном ударе
	PropImpact = { Ids = { LAND }, Volume = 0.6, Pitch = { 0.5, 0.65 } }, -- ящики и бочки
	Splash = { Ids = { "rbxasset://sounds/impact_water.mp3" }, Volume = 0.7, Pitch = { 0.85, 1.05 } }, -- падение в воду

	VentBang = { Ids = { LAND }, Volume = 1, Pitch = { 0.42, 0.5 } }, -- люк распахнулся
	VentFlapHit = { Ids = { LAND }, Volume = 0.6, Pitch = { 0.55, 0.7 } }, -- крышка люка хлопнула обратно
	PipeClank = { Ids = { LAND }, Volume = 0.55, Pitch = { 0.5, 0.75 } }, -- удары о трубу, пока летишь в темноте
	PipeRush = { Ids = { "rbxasset://sounds/action_falling.ogg" }, Volume = 0.55, Pitch = { 0.7, 0.7 }, Looped = true }, -- гул трубы
	PipeWater = { Ids = { "rbxasset://sounds/action_swim.mp3" }, Volume = 0.5, Pitch = { 0.55, 0.55 }, Looped = true }, -- вода в трубе

	-- шум воды в канале
	SewerAmbience = {
		Ids = { "rbxasset://sounds/action_swim.mp3" },
		Volume = 0.3,
		Pitch = { 0.32, 0.32 },
		Looped = true,
	},
	LobbyMusic = { Ids = {}, Volume = 0.25, Pitch = { 1, 1 }, Looped = true }, -- музыка в лобби
	MenuSelect = { Ids = {}, Volume = 0.5, Pitch = { 1, 1 } }, -- выбор пункта в меню голосования
}
