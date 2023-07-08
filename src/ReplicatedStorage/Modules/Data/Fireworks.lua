
local Module = {}

Module.FireworkTypes = {
	Handheld = 1,
	Ground = 2,
	Mortar = 3,
}

Module.FireworkVariants = {
	Handheld = {
		None = 1,

		Sparkler = 2,
	},

	Ground = {
		None = 1,

		Cake = 2,
		Fountain = 3,
		Barrage = 4,
		SingleShot = 5,
		MultiShots = 6,
		Spinners = 7,
		Firecrackers = 8,
		Rocket = 9,
		Missile = 10,
		Fan = 11,
	},

	Shells = {
		None = 1,

		Brocade = 2,
		Chrysanthemum = 3,
		Comet = 4,
		Corssette = 5,
		Pearls = 6,
		DragonEggs = 7,
		Waterfall = 8,
		FlyingFish = 9,
		PalmTree = 10,
		Peony = 11,
		Pistil = 12,
		Strobe = 13,
		Tourbillion = 14,
		Willow = 15,
		Crackle = 16,
	},

	Trails = {
		None = 1,

		RisingTail = 2,
	},
}

return Module
