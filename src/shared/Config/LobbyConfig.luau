-- Внешний вид и размеры лобби. Всё в этом файле можно менять.
-- Лобби строится кодом при запуске сервера, в Workspace оно появится как модель "Lobby".

return {
	Position = Vector3.new(0, 600, 0), -- где висит лобби (высоко над картой, чтобы его не было видно)
	RoomSize = Vector3.new(72, 22, 56), -- ширина, высота, глубина комнаты в стадах

	Vent = {
		HatchSize = 6, -- размер квадратного люка
		HatchHeight = 9, -- на какой высоте от пола низ люка
		DuctLength = 16, -- длина вентиляционной трубы за стеной
	},

	PhysicsCrates = 5, -- сколько ящиков можно пинать
	PhysicsBarrels = 4, -- сколько бочек можно пинать

	Colors = {
		Floor = Color3.fromRGB(74, 72, 66),
		Walls = Color3.fromRGB(92, 94, 86),
		WallsBottom = Color3.fromRGB(58, 62, 56), -- нижняя полоса на стенах
		Ceiling = Color3.fromRGB(46, 46, 44),
		Metal = Color3.fromRGB(88, 90, 92),
		Rust = Color3.fromRGB(110, 72, 48),
		Water = Color3.fromRGB(58, 74, 44),
		Crate = Color3.fromRGB(148, 112, 70),
		Mattress = Color3.fromRGB(122, 108, 84),
		Hazard = Color3.fromRGB(214, 170, 32),
		Lamp = Color3.fromRGB(226, 236, 214), -- цвет ламп дневного света
	},

	LampBrightness = 1.6, -- яркость ламп
	LampRange = 28, -- дальность света ламп
}
