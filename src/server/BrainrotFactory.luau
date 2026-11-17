-- BrainrotFactory.luau
-- Builds one brainrot character out of plain parts: a body in the species'
-- shape, a face, little legs and the silly accessory its name promises (a
-- traffic cone, a toaster, a disco ball...). Every copy wears a billboard
-- label with its name, rarity and money per second, coloured by rarity, so
-- a player can read the whole ladder at a glance across the plaza.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local function makePart(name, shape, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CastShadow = true
	return part
end

local function weldTo(model, part, offset)
	local root = model.PrimaryPart
	part.CFrame = root.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = model
end

-- The accessory is the joke made visible; each kind is a few parts on top
-- of (or beside) the body, placed relative to the body's top.
local ACCESSORY_BUILDERS = {}

function ACCESSORY_BUILDERS.TrafficCone(model, species, topY)
	local cone = makePart("Cone", Enum.PartType.Cylinder, Vector3.new(0.9, 1.1, 0.9), Color3.fromRGB(255, 110, 30))
	weldTo(model, cone, CFrame.new(0, topY + 0.5, 0))
	local stripe = makePart("ConeStripe", Enum.PartType.Cylinder, Vector3.new(0.98, 0.25, 0.98), Color3.fromRGB(255, 255, 255))
	weldTo(model, stripe, CFrame.new(0, topY + 0.45, 0))
end

function ACCESSORY_BUILDERS.BiscuitHorns(model, species, topY)
	for _, side in ipairs({ -1, 1 }) do
		local horn = makePart("BiscuitHorn", Enum.PartType.Cylinder, Vector3.new(0.85, 0.3, 0.85), species.accent)
		weldTo(model, horn, CFrame.new(side * 0.9, topY + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)))
	end
end

function ACCESSORY_BUILDERS.BananaPeel(model, species, topY)
	for i = 1, 4 do
		local angle = (i / 4) * math.pi * 2
		local peel = makePart("Peel", Enum.PartType.Block, Vector3.new(0.35, 1.0, 0.6), species.color)
		local offset = CFrame.new(math.cos(angle) * 0.45, topY + 0.3, math.sin(angle) * 0.45)
			* CFrame.Angles(math.cos(angle) * 0.7, 0, math.sin(angle) * 0.7)
		weldTo(model, peel, offset)
	end
end

function ACCESSORY_BUILDERS.Toaster(model, species, topY)
	local toaster = makePart("Toaster", Enum.PartType.Block, Vector3.new(1.5, 0.9, 1.0), Color3.fromRGB(210, 215, 220), Enum.Material.Metal)
	weldTo(model, toaster, CFrame.new(0, topY + 0.45, 0))
	local toast = makePart("Toast", Enum.PartType.Block, Vector3.new(0.9, 0.7, 0.25), Color3.fromRGB(235, 195, 120))
	weldTo(model, toast, CFrame.new(0.2, topY + 1.05, 0))
end

function ACCESSORY_BUILDERS.DiscoBall(model, species, topY)
	local ball = makePart("DiscoBall", Enum.PartType.Ball, Vector3.new(1.2, 1.2, 1.2), Color3.fromRGB(220, 225, 255), Enum.Material.Metal)
	ball.Reflectance = 0.7
	weldTo(model, ball, CFrame.new(0, topY + 0.9, 0))
end

function ACCESSORY_BUILDERS.Periscope(model, species, topY)
	local post = makePart("PeriscopePost", Enum.PartType.Cylinder, Vector3.new(0.35, 1.2, 0.35), Color3.fromRGB(90, 100, 110), Enum.Material.Metal)
	weldTo(model, post, CFrame.new(0.8, topY + 0.5, 0))
	local eye = makePart("PeriscopeEye", Enum.PartType.Block, Vector3.new(0.9, 0.4, 0.4), Color3.fromRGB(90, 100, 110), Enum.Material.Metal)
	weldTo(model, eye, CFrame.new(0.8, topY + 1.1, 0.3))
end

function ACCESSORY_BUILDERS.Antennas(model, species, topY)
	for _, side in ipairs({ -0.6, 0.6 }) do
		local rod = makePart("Antenna", Enum.PartType.Cylinder, Vector3.new(0.14, 1.5, 0.14), Color3.fromRGB(40, 44, 50), Enum.Material.Metal)
		weldTo(model, rod, CFrame.new(side, topY + 0.7, 0))
		local tip = makePart("AntennaTip", Enum.PartType.Ball, Vector3.new(0.4, 0.4, 0.4), species.accent, Enum.Material.Neon)
		weldTo(model, tip, CFrame.new(side, topY + 1.5, 0))
	end
end

function ACCESSORY_BUILDERS.Scooter(model, species, topY)
	local deck = makePart("ScooterDeck", Enum.PartType.Block, Vector3.new(2.4, 0.25, 0.9), Color3.fromRGB(255, 80, 120), Enum.Material.Metal)
	weldTo(model, deck, CFrame.new(0, -species.height / 2 + 0.35, 0.2))
	for _, x in ipairs({ -1.0, 1.0 }) do
		local wheel = makePart("ScooterWheel", Enum.PartType.Cylinder, Vector3.new(0.3, 0.65, 0.65), Color3.fromRGB(30, 30, 35))
		weldTo(model, wheel, CFrame.new(x, -species.height / 2 + 0.05, 0.2) * CFrame.Angles(0, 0, math.rad(90)))
	end
end

function ACCESSORY_BUILDERS.CheeseCrown(model, species, topY)
	local crown = makePart("CheeseCrown", Enum.PartType.Cylinder, Vector3.new(1.5, 0.6, 1.5), Color3.fromRGB(255, 190, 40), Enum.Material.Metal)
	weldTo(model, crown, CFrame.new(0, topY + 0.3, 0))
	for i = 1, 5 do
		local angle = (i / 5) * math.pi * 2
		local spike = makePart("CrownSpike", Enum.PartType.Block, Vector3.new(0.3, 0.6, 0.3), Color3.fromRGB(255, 190, 40), Enum.Material.Metal)
		weldTo(model, spike, CFrame.new(math.cos(angle) * 0.6, topY + 0.8, math.sin(angle) * 0.6))
	end
end

function ACCESSORY_BUILDERS.FridgeWings(model, species, topY)
	for _, side in ipairs({ -1, 1 }) do
		local wing = makePart("FridgeDoorWing", Enum.PartType.Block, Vector3.new(0.25, 1.8, 1.3), species.accent, Enum.Material.Metal)
		weldTo(model, wing, CFrame.new(side * 1.5, topY - 0.6, -0.2) * CFrame.Angles(0, 0, side * -0.5))
	end
end

function ACCESSORY_BUILDERS.Headphones(model, species, topY)
	local band = makePart("HeadphoneBand", Enum.PartType.Cylinder, Vector3.new(2.3, 0.25, 2.3), Color3.fromRGB(30, 30, 40))
	weldTo(model, band, CFrame.new(0, topY + 0.15, 0))
	for _, side in ipairs({ -1, 1 }) do
		local cup = makePart("HeadphoneCup", Enum.PartType.Cylinder, Vector3.new(0.45, 0.8, 0.8), species.accent, Enum.Material.Neon)
		weldTo(model, cup, CFrame.new(side * 1.15, topY - 0.2, 0) * CFrame.Angles(0, 0, math.rad(90)))
	end
end

function ACCESSORY_BUILDERS.SockHorns(model, species, topY)
	for _, side in ipairs({ -1, 1 }) do
		local sock = makePart("SockHorn", Enum.PartType.Block, Vector3.new(0.5, 1.4, 0.5), Color3.fromRGB(255, 255, 255))
		weldTo(model, sock, CFrame.new(side * 0.8, topY + 0.6, 0) * CFrame.Angles(0, 0, side * -0.4))
		local toe = makePart("SockToe", Enum.PartType.Ball, Vector3.new(0.55, 0.55, 0.55), Color3.fromRGB(255, 120, 120))
		weldTo(model, toe, CFrame.new(side * 1.05, topY + 1.25, 0))
	end
end

local function bodySizeFor(species)
	if species.bodyShape == "Ball" then
		return Vector3.new(species.height, species.height, species.height)
	elseif species.bodyShape == "Cylinder" then
		return Vector3.new(species.height * 0.7, species.height, species.height * 0.7)
	elseif species.bodyShape == "TallNeck" then
		return Vector3.new(1.6, species.height, 1.6)
	elseif species.bodyShape == "LongBlock" then
		return Vector3.new(species.height * 1.5, species.height * 0.7, 2.0)
	end
	return Vector3.new(2.2, species.height, 2.2)
end

local function bodyShapeEnum(species)
	if species.bodyShape == "Ball" then
		return Enum.PartType.Ball
	elseif species.bodyShape == "Cylinder" or species.bodyShape == "TallNeck" then
		return Enum.PartType.Cylinder
	end
	return Enum.PartType.Block
end

-- The floating label: name in white, rarity in its colour, rate underneath.
-- It faces every camera (BillboardGui) and is readable across the plaza.
local function buildNameLabel(model, species, mutation, rate)
	local rarity = BrainrotData.rarityInfo(species.rarity)
	local gui = Instance.new("BillboardGui")
	gui.Name = "NameLabel"
	gui.Size = UDim2.fromOffset(220, 74)
	gui.StudsOffset = Vector3.new(0, species.height / 2 + 1.6, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameText"
	nameLabel.Size = UDim2.new(1, 0, 0.42, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.35
	local displayName = species.name
	if mutation and mutation.name ~= "Normal" then
		displayName = mutation.name .. " " .. displayName
	end
	nameLabel.Text = displayName
	nameLabel.Parent = gui

	local detailLabel = Instance.new("TextLabel")
	detailLabel.Name = "DetailText"
	detailLabel.Position = UDim2.new(0, 0, 0.42, 0)
	detailLabel.Size = UDim2.new(1, 0, 0.4, 0)
	detailLabel.BackgroundTransparency = 1
	detailLabel.Font = Enum.Font.FredokaOne
	detailLabel.TextScaled = true
	detailLabel.TextColor3 = rarity.color
	detailLabel.TextStrokeTransparency = 0.35
	detailLabel.Text = string.format("%s  •  $%s/s", species.rarity, BrainrotData.formatMoney(rate))
	detailLabel.Parent = gui

	gui.Adornee = model.PrimaryPart
	gui.Parent = model
end

-- Build a complete brainrot model, unanchored parts welded to an anchored
-- invisible root so whole models can be carried, placed and tweened as one.
function BrainrotFactory.buildModel(species, mutation)
	mutation = mutation or BrainrotData.MUTATIONS[1]
	local model = Instance.new("Model")
	model.Name = species.id

	local root = makePart("Root", Enum.PartType.Block, Vector3.new(0.5, 0.5, 0.5), species.color)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.Parent = model
	model.PrimaryPart = root

	local body = makePart("Body", bodyShapeEnum(species), bodySizeFor(species), species.color)
	if mutation.material then
		body.Material = mutation.material
	end
	if mutation.tint then
		body.Color = mutation.tint
	end
	weldTo(model, body, CFrame.new(0, 0, 0))

	-- Face on the +Z side: two eyes and a grin, the brainrot stare.
	for _, side in ipairs({ -0.45, 0.45 }) do
		local eye = makePart("Eye", Enum.PartType.Ball, Vector3.new(0.42, 0.5, 0.3), Color3.fromRGB(255, 255, 255))
		weldTo(model, eye, CFrame.new(side, 0.35, bodySizeFor(species).Z / 2))
		local pupil = makePart("Pupil", Enum.PartType.Ball, Vector3.new(0.2, 0.24, 0.16), Color3.fromRGB(20, 20, 25))
		weldTo(model, pupil, CFrame.new(side, 0.35, bodySizeFor(species).Z / 2 + 0.14))
	end
	local mouth = makePart("Grin", Enum.PartType.Block, Vector3.new(0.8, 0.16, 0.12), Color3.fromRGB(30, 20, 20))
	weldTo(model, mouth, CFrame.new(0, -0.3, bodySizeFor(species).Z / 2 + 0.05))

	-- Little legs so the cast reads as characters, not statues.
	for _, side in ipairs({ -0.6, 0.6 }) do
		local leg = makePart("Leg", Enum.PartType.Cylinder, Vector3.new(0.4, 0.8, 0.4), species.accent)
		weldTo(model, leg, CFrame.new(side, -species.height / 2 - 0.3, 0))
	end

	local builder = ACCESSORY_BUILDERS[species.accessory]
	if builder then
		builder(model, species, species.height / 2)
	end

	local rate = BrainrotData.rateWithMutation(species, mutation)
	model:SetAttribute("SpeciesId", species.id)
	model:SetAttribute("Mutation", mutation.name)
	model:SetAttribute("Rate", rate)
	model:SetAttribute("Price", BrainrotData.priceWithMutation(species, mutation))
	model:SetAttribute("Rainbow", mutation.name == "Rainbow")

	buildNameLabel(model, species, mutation, rate)
	return model
end

-- A record is the bookkeeping twin of a model: who it is, what it earns,
-- which model shows it. PlayerState stores records; models live in Workspace.
function BrainrotFactory.makeRecord(species, mutation, model)
	return {
		speciesId = species.id,
		mutationName = mutation.name,
		rate = BrainrotData.rateWithMutation(species, mutation),
		price = BrainrotData.priceWithMutation(species, mutation),
		model = model,
		pending = 0, -- uncollected dollars waiting on the pad
		bobPhase = math.random() * math.pi * 2,
	}
end

return BrainrotFactory
