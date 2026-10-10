-- Список карт для голосования (максимум 9 за раз, как в старом amx-меню).
--
-- Как добавить свою карту:
--   1. Собери карту в одну Model и положи её в ServerStorage > Maps (папку создай сам).
--   2. Внутри модели сделай папку Spawns и накидай туда парты - это точки появления.
--      Без папки Spawns игроков раскидает по кругу вокруг центра карты.
--   3. Добавь сюда запись с Source = "ServerStorage".

return {
	{
		Id = "Baseplate", -- уникальный id, не повторяй
		Name = "Baseplate", -- название в голосовании
		Source = "Workspace", -- карта уже стоит в Workspace, мы её не двигаем и не удаляем
		Object = "Baseplate", -- имя модели или парта карты
		Lighting = "OldNight", -- пресет света из LightingConfig
		SpawnRadius = 40, -- радиус круга появления, если нет папки Spawns
	},

	-- {
	-- 	Id = "zm_sewers",
	-- 	Name = "zm_sewers",
	-- 	Source = "ServerStorage",
	-- 	Object = "zm_sewers",
	-- 	Lighting = "OldNight",
	-- 	SpawnRadius = 30,
	-- },
}
