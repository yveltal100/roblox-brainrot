-- BrainrotData.luau
-- The single catalogue of Brainrot Bay: rarities, mutations and the twelve
-- absurd original brainrots the player can buy, carry home and collect on.
-- Every other script reads its names, prices and money-per-second from here,
-- so the cast stays in one place and the labels always agree with the maths.

local BrainrotData = {}

-- Rarity ladder, cheapest first. The weight steers how often a rarity walks
-- the conveyor; the colour paints its name label and its base pad ring.
BrainrotData.RARITIES = {
	{ name = "Common", weight = 46, color = Color3.fromRGB(205, 210, 215) },
	{ name = "Rare", weight = 27, color = Color3.fromRGB(70, 160, 255) },
	{ name = "Epic", weight = 15, color = Color3.fromRGB(178, 92, 255) },
	{ name = "Legendary", weight = 8, color = Color3.fromRGB(255, 176, 32) },
	{ name = "Mythic", weight = 3, color = Color3.fromRGB(255, 64, 120) },
	{ name = "Brainrot God", weight = 1, color = Color3.fromRGB(64, 255, 214) },
}

-- Mutations roll on top of a species when it spawns. A mutation multiplies
-- both the price and the money per second, and re-skins the body material.
BrainrotData.MUTATIONS = {
	{ name = "Normal", chance = 0.86, multiplier = 1, material = nil },
	{ name = "Gold", chance = 0.09, multiplier = 2, material = Enum.Material.Metal, tint = Color3.fromRGB(255, 205, 60) },
	{ name = "Diamond", chance = 0.04, multiplier = 4, material = Enum.Material.Glass, tint = Color3.fromRGB(140, 235, 255) },
	{ name = "Rainbow", chance = 0.01, multiplier = 8, material = Enum.Material.Neon, tint = nil },
}

-- The cast. Each species is built from plain parts by BrainrotFactory:
-- bodyShape picks the torso, accessory picks the silly hat or prop, and the
-- two colours paint it. price is the conveyor price, perSecond is what one
-- placed copy earns its owner every second before multipliers.
BrainrotData.SPECIES = {
	{ id = "cone_crab", name = "Cone Crab Carl", rarity = "Common", price = 50, perSecond = 1,
		bodyShape = "Ball", accessory = "TrafficCone", color = Color3.fromRGB(255, 122, 40), accent = Color3.fromRGB(255, 240, 220), height = 2.2 },
	{ id = "biscuit_buffalo", name = "Biscuit Buffalo Beni", rarity = "Common", price = 150, perSecond = 2,
		bodyShape = "Block", accessory = "BiscuitHorns", color = Color3.fromRGB(196, 141, 74), accent = Color3.fromRGB(245, 222, 179), height = 2.8 },
	{ id = "banana_butler", name = "Sir Banana Butler", rarity = "Rare", price = 500, perSecond = 5,
		bodyShape = "Cylinder", accessory = "BananaPeel", color = Color3.fromRGB(255, 225, 64), accent = Color3.fromRGB(90, 60, 30), height = 3.4 },
	{ id = "toaster_giraffe", name = "Toaster Giraffe Gigi", rarity = "Rare", price = 1200, perSecond = 9,
		bodyShape = "TallNeck", accessory = "Toaster", color = Color3.fromRGB(244, 190, 90), accent = Color3.fromRGB(160, 90, 40), height = 4.6 },
	{ id = "disco_potato", name = "Disco Potato Duke", rarity = "Epic", price = 3500, perSecond = 18,
		bodyShape = "Ball", accessory = "DiscoBall", color = Color3.fromRGB(168, 120, 70), accent = Color3.fromRGB(230, 230, 255), height = 3.0 },
	{ id = "sub_whale", name = "Submarine Sandwich Whale", rarity = "Epic", price = 8000, perSecond = 32,
		bodyShape = "LongBlock", accessory = "Periscope", color = Color3.fromRGB(90, 170, 220), accent = Color3.fromRGB(250, 240, 200), height = 3.2 },
	{ id = "wifi_rhino", name = "WiFi Router Rhino", rarity = "Legendary", price = 20000, perSecond = 60,
		bodyShape = "Block", accessory = "Antennas", color = Color3.fromRGB(120, 128, 140), accent = Color3.fromRGB(60, 220, 120), height = 3.4 },
	{ id = "turbo_grandma", name = "Turbo Grandma Scooter", rarity = "Legendary", price = 45000, perSecond = 110,
		bodyShape = "Cylinder", accessory = "Scooter", color = Color3.fromRGB(230, 150, 190), accent = Color3.fromRGB(240, 240, 240), height = 3.6 },
	{ id = "moon_emperor", name = "Moon Cheese Emperor", rarity = "Mythic", price = 110000, perSecond = 220,
		bodyShape = "Ball", accessory = "CheeseCrown", color = Color3.fromRGB(250, 220, 110), accent = Color3.fromRGB(255, 160, 40), height = 3.8 },
	{ id = "fridge_phoenix", name = "Galaxy Fridge Phoenix", rarity = "Mythic", price = 260000, perSecond = 420,
		bodyShape = "Block", accessory = "FridgeWings", color = Color3.fromRGB(150, 110, 255), accent = Color3.fromRGB(255, 120, 220), height = 4.2 },
	{ id = "kraken_dj", name = "DJ Headphone Kraken", rarity = "Brainrot God", price = 650000, perSecond = 900,
		bodyShape = "Ball", accessory = "Headphones", color = Color3.fromRGB(110, 70, 200), accent = Color3.fromRGB(64, 255, 214), height = 4.4 },
	{ id = "sock_dragon", name = "The Eternal Sock Dragon", rarity = "Brainrot God", price = 1500000, perSecond = 2000,
		bodyShape = "LongBlock", accessory = "SockHorns", color = Color3.fromRGB(80, 220, 160), accent = Color3.fromRGB(255, 255, 255), height = 4.8 },
}

function BrainrotData.speciesById(id)
	for _, species in ipairs(BrainrotData.SPECIES) do
		if species.id == id then
			return species
		end
	end
	return nil
end

function BrainrotData.rarityInfo(rarityName)
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		if rarity.name == rarityName then
			return rarity
		end
	end
	return BrainrotData.RARITIES[1]
end

-- Weighted pick of one species for the conveyor: roll a rarity by weight,
-- then pick evenly among that rarity's species so gods stay genuinely rare.
function BrainrotData.rollSpecies(rng)
	local totalWeight = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		totalWeight += rarity.weight
	end
	local roll = rng:NextNumber(0, totalWeight)
	local chosenRarity = BrainrotData.RARITIES[1].name
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		roll -= rarity.weight
		if roll <= 0 then
			chosenRarity = rarity.name
			break
		end
	end
	local pool = {}
	for _, species in ipairs(BrainrotData.SPECIES) do
		if species.rarity == chosenRarity then
			table.insert(pool, species)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Roll a mutation for a fresh spawn; Rainbow is the one-in-a-hundred dream.
function BrainrotData.rollMutation(rng)
	local roll = rng:NextNumber()
	local seen = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		seen += mutation.chance
		if roll <= seen then
			return mutation
		end
	end
	return BrainrotData.MUTATIONS[1]
end

-- The price a player pays and the rate a placed copy earns, after mutation.
function BrainrotData.priceWithMutation(species, mutation)
	return math.floor(species.price * mutation.multiplier + 0.5)
end

function BrainrotData.rateWithMutation(species, mutation)
	return species.perSecond * mutation.multiplier
end

-- Short money label for signs and prompts: 950, 1.2K, 3.4M.
function BrainrotData.formatMoney(amount)
	amount = math.floor(amount)
	if amount >= 1000000 then
		return string.format("%.1fM", amount / 1000000)
	end
	if amount >= 10000 then
		return string.format("%.1fK", amount / 1000)
	end
	if amount >= 1000 then
		return string.format("%.2fK", amount / 1000)
	end
	return tostring(amount)
end

return BrainrotData
