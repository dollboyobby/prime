-- Пресеты освещения. Включаются у каждого игрока свои: в лобби один, на карте другой.
-- Всё в этом файле можно менять. Пресет для карты задаётся в MapConfig (поле Lighting).
-- Совет: в Lighting > Technology поставь Future, тогда свет ламп в лобби будет с тенями.

return {
	Lobby = {
		ClockTime = 0,
		Brightness = 0,
		Ambient = Color3.fromRGB(34, 34, 32), -- общий свет в помещении (темнее = мрачнее)
		OutdoorAmbient = Color3.fromRGB(20, 20, 20),
		ExposureCompensation = 0.2,
		Atmosphere = {
			Density = 0.32,
			Haze = 1.2,
			Glare = 0,
			Color = Color3.fromRGB(70, 72, 60),
			Decay = Color3.fromRGB(30, 30, 26),
		},
		ColorCorrection = {
			Brightness = 0,
			Contrast = 0.12,
			Saturation = -0.25,
			TintColor = Color3.fromRGB(236, 244, 222),
		},
		Reverb = Enum.ReverbType.SewerPipe, -- эхо как в трубе
	},

	OldNight = {
		ClockTime = 20.6,
		Brightness = 1.2,
		Ambient = Color3.fromRGB(60, 64, 78),
		OutdoorAmbient = Color3.fromRGB(86, 92, 116),
		ExposureCompensation = 0.3,
		Atmosphere = {
			Density = 0.42,
			Haze = 2,
			Glare = 0,
			Color = Color3.fromRGB(52, 62, 74),
			Decay = Color3.fromRGB(28, 34, 44),
		},
		ColorCorrection = {
			Brightness = 0,
			Contrast = 0.08,
			Saturation = -0.15,
			TintColor = Color3.fromRGB(222, 236, 255),
		},
		Reverb = Enum.ReverbType.NoReverb,
	},

	Day = {
		ClockTime = 14,
		Brightness = 2,
		Ambient = Color3.fromRGB(110, 110, 110),
		OutdoorAmbient = Color3.fromRGB(128, 128, 128),
		ExposureCompensation = 0,
		Atmosphere = {
			Density = 0.3,
			Haze = 0,
			Glare = 0,
			Color = Color3.fromRGB(199, 199, 199),
			Decay = Color3.fromRGB(106, 112, 125),
		},
		ColorCorrection = { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.fromRGB(255, 255, 255) },
		Reverb = Enum.ReverbType.NoReverb,
	},
}
