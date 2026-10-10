-- Цвета и шрифты интерфейса. Всё в этом файле можно менять.

return {
	Hud = Color3.fromRGB(255, 160, 0), -- жёлто-оранжевый, как HUD в CS 1.6
	Danger = Color3.fromRGB(255, 40, 30), -- мало здоровья
	Text = Color3.fromRGB(235, 235, 230),
	Muted = Color3.fromRGB(150, 150, 145),
	Terminal = Color3.fromRGB(110, 255, 140), -- зелёный текст на табло
	Announce = Color3.fromRGB(255, 200, 60), -- текст по центру экрана

	Font = Font.fromEnum(Enum.Font.Arimo),
	FontBold = Font.fromEnum(Enum.Font.ArimoBold),
	FontMono = Font.fromEnum(Enum.Font.RobotoMono),
}
