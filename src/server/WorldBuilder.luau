-- WorldBuilder.luau
-- Raises the whole island of Brainrot Bay out of parts at server start:
-- the dock, the conveyor lane down its middle, eight player bases around
-- the edge, the plaza, the upgrade stall and the safe hill the tide cannot
-- reach. Building the world from code keeps every plank inside the place's
-- scripts, so the dossier shows the world the screenshots show.

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local WorldBuilder = {}
WorldBuilder.bases = {}
WorldBuilder.lane = nil

local function part(parent, name, size, cframe, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local SAND = Color3.fromRGB(238, 214, 160)
local WOOD = Color3.fromRGB(146, 102, 62)
local WOOD_DARK = Color3.fromRGB(110, 76, 44)
local LANE_COLOR = Color3.fromRGB(52, 56, 68)
local PLAZA_COLOR = Color3.fromRGB(255, 176, 84)

local BASE_DECK_COLORS = {
	Color3.fromRGB(255, 107, 107), Color3.fromRGB(84, 160, 255), Color3.fromRGB(120, 224, 143),
	Color3.fromRGB(255, 217, 61), Color3.fromRGB(204, 121, 255), Color3.fromRGB(255, 146, 72),
	Color3.fromRGB(56, 217, 196), Color3.fromRGB(240, 128, 170),
}

-- One palm: a leaning trunk and a burst of leaf spheres. Cheap, cheerful,
-- and unmistakably a beach wherever a screenshot catches one.
local function buildPalm(parent, position, lean)
	local palm = Instance.new("Model")
	palm.Name = "Palm"
	palm.Parent = parent
	local trunk = part(palm, "Trunk", Vector3.new(1.1, 9, 1.1),
		CFrame.new(position + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, 0, lean),
		Color3.fromRGB(140, 100, 60), Enum.Material.Wood)
	trunk.CanCollide = false
	local top = position + Vector3.new(math.sin(lean) * -4, 9.2, 0)
	for i = 1, 6 do
		local angle = (i / 6) * math.pi * 2
		local leaf = part(palm, "Leaf", Vector3.new(5.5, 0.5, 1.6),
			CFrame.new(top + Vector3.new(math.cos(angle) * 2.2, 0.3, math.sin(angle) * 2.2))
				* CFrame.Angles(0, -angle, 0.35),
			Color3.fromRGB(64, 176, 84), Enum.Material.SmoothPlastic)
		leaf.CanCollide = false
	end
end

-- A lamp post whose head glows at dusk screenshots and marks the lane.
local function buildLamp(parent, position)
	local post = part(parent, "LampPost", Vector3.new(0.5, 8, 0.5),
		CFrame.new(position + Vector3.new(0, 4, 0)), Color3.fromRGB(40, 42, 50), Enum.Material.Metal)
	post.CanCollide = false
	local head = part(parent, "LampHead", Vector3.new(1.4, 1.4, 1.4),
		CFrame.new(position + Vector3.new(0, 8.4, 0)), Color3.fromRGB(255, 230, 150), Enum.Material.Neon)
	head.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 150)
	light.Range = 22
	light.Brightness = 1.2
	light.Parent = head
end

-- A standing sign: post, board and a SurfaceGui headline anyone can read.
local function buildSign(parent, name, position, yaw, text, textColor, boardColor, boardSize)
	local group = Instance.new("Model")
	group.Name = name
	group.Parent = parent
	local base = CFrame.new(position) * CFrame.Angles(0, yaw, 0)
	part(group, "Post", Vector3.new(0.7, boardSize.Y + 3, 0.7),
		base * CFrame.new(0, (boardSize.Y + 3) / 2, 0), WOOD_DARK, Enum.Material.Wood)
	local board = part(group, "Board", boardSize,
		base * CFrame.new(0, boardSize.Y / 2 + 3.4, 0), boardColor, Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignText"
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = textColor
	label.Text = text
	label.Parent = gui
	return board
end

-- One player base: a coloured deck, six earning pads in two rows, a gold
-- collect pad by the door, a lock button post and an owner sign. Returns
-- everything BaseManager needs to run the base without searching again.
local function buildBase(parent, index, center, facing)
	local baseFolder = Instance.new("Folder")
	baseFolder.Name = "Base" .. index
	baseFolder.Parent = parent
	local deckColor = BASE_DECK_COLORS[((index - 1) % #BASE_DECK_COLORS) + 1]
	local yaw = CFrame.Angles(0, facing, 0)
	local baseCFrame = CFrame.new(center) * yaw

	local deck = part(baseFolder, "Deck", Vector3.new(38, 1.6, 30),
		baseCFrame * CFrame.new(0, GameConfig.ISLAND_TOP_Y + 0.8, 0), deckColor, Enum.Material.SmoothPlastic)
	deck.Name = "Deck"

	-- Low fence on three sides; the side facing the lane stays open so the
	-- owner can dash in and a thief can be seen trying their luck.
	for _, fence in ipairs({
		{ offset = Vector3.new(0, 2.2, -15), size = Vector3.new(38, 3, 1) },
		{ offset = Vector3.new(-19, 2.2, 0), size = Vector3.new(1, 3, 30) },
		{ offset = Vector3.new(19, 2.2, 0), size = Vector3.new(1, 3, 30) },
	}) do
		part(baseFolder, "Fence", fence.size, baseCFrame * CFrame.new(fence.offset), WOOD, Enum.Material.Wood)
	end

	local pads = {}
	for row = 0, 1 do
		for col = 0, 2 do
			local padIndex = row * 3 + col + 1
			local pad = part(baseFolder, "Pad" .. padIndex, Vector3.new(6.4, 0.5, 6.4),
				baseCFrame * CFrame.new(-11 + col * 11, GameConfig.ISLAND_TOP_Y + 1.85, -7 + row * 11),
				Color3.fromRGB(245, 245, 250), Enum.Material.Neon)
			pad:SetAttribute("PadIndex", padIndex)
			pads[padIndex] = pad
		end
	end

	local collectPad = part(baseFolder, "CollectPad", Vector3.new(7, 0.5, 7),
		baseCFrame * CFrame.new(0, GameConfig.ISLAND_TOP_Y + 1.85, 11.5),
		Color3.fromRGB(255, 205, 40), Enum.Material.Neon)
	collectPad:SetAttribute("IsCollectPad", true)

	local lockButton = part(baseFolder, "LockButton", Vector3.new(2.2, 3.2, 2.2),
		baseCFrame * CFrame.new(14.5, GameConfig.ISLAND_TOP_Y + 3.2, 11.5),
		Color3.fromRGB(90, 200, 120), Enum.Material.SmoothPlastic)
	lockButton:SetAttribute("IsLockButton", true)

	local sign = buildSign(baseFolder, "OwnerSign", center + Vector3.new(0, 0, 0), facing,
		"EMPTY BASE", Color3.fromRGB(255, 255, 255), deckColor, Vector3.new(20, 4.5, 0.6))
	sign.CFrame = baseCFrame * CFrame.new(0, 9.5, -13)

	return {
		index = index,
		folder = baseFolder,
		deck = deck,
		pads = pads,
		collectPad = collectPad,
		lockButton = lockButton,
		signBoard = sign,
		center = center,
		doorCFrame = baseCFrame * CFrame.new(0, GameConfig.ISLAND_TOP_Y + 3, 17),
	}
end

-- The conveyor lane: a dark belt down the island's middle with chevron
-- stripes, a start arch where brainrots climb out of the sea and an end
-- arch where the unbought dive back in.
local function buildLane(parent)
	local laneFolder = Instance.new("Folder")
	laneFolder.Name = "ConveyorLane"
	laneFolder.Parent = parent
	local belt = part(laneFolder, "Belt", Vector3.new(GameConfig.LANE_WIDTH, 0.6, GameConfig.LANE_Z_LENGTH),
		CFrame.new(0, GameConfig.ISLAND_TOP_Y + 0.3, 0), LANE_COLOR, Enum.Material.SmoothPlastic)
	belt.CanCollide = false
	for i = 0, 14 do
		local z = -GameConfig.LANE_Z_LENGTH / 2 + 6 + i * 10
		local stripe = part(laneFolder, "Chevron", Vector3.new(GameConfig.LANE_WIDTH - 3, 0.15, 1.6),
			CFrame.new(0, GameConfig.ISLAND_TOP_Y + 0.68, z), Color3.fromRGB(255, 205, 40), Enum.Material.Neon)
		stripe.CanCollide = false
	end
	for _, z in ipairs({ -GameConfig.LANE_Z_LENGTH / 2, GameConfig.LANE_Z_LENGTH / 2 }) do
		for _, x in ipairs({ -GameConfig.LANE_WIDTH / 2 - 1, GameConfig.LANE_WIDTH / 2 + 1 }) do
			part(laneFolder, "ArchPost", Vector3.new(1.4, 13, 1.4),
				CFrame.new(x, GameConfig.ISLAND_TOP_Y + 6.5, z), WOOD_DARK, Enum.Material.Wood)
		end
		part(laneFolder, "ArchTop", Vector3.new(GameConfig.LANE_WIDTH + 4, 1.6, 1.6),
			CFrame.new(0, GameConfig.ISLAND_TOP_Y + 13.4, z), WOOD, Enum.Material.Wood)
	end
	buildSign(laneFolder, "LaneSignNorth", Vector3.new(0, GameConfig.ISLAND_TOP_Y, -GameConfig.LANE_Z_LENGTH / 2 - 4),
		0, "FRESH BRAINROTS!", Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 107, 107), Vector3.new(24, 5, 0.6))
	return {
		startZ = -GameConfig.LANE_Z_LENGTH / 2 + 4,
		endZ = GameConfig.LANE_Z_LENGTH / 2 - 4,
		width = GameConfig.LANE_WIDTH,
		folder = laneFolder,
	}
end

-- The plaza at the island's heart: spawn, the upgrade stall and the big
-- welcome sign. The hill behind it is the tide's safe ground.
local function buildPlaza(parent)
	local plaza = Instance.new("Folder")
	plaza.Name = "Plaza"
	plaza.Parent = parent
	local disc = part(plaza, "PlazaDisc", Vector3.new(44, 0.7, 44),
		CFrame.new(0, GameConfig.ISLAND_TOP_Y + 0.35, 88), PLAZA_COLOR, Enum.Material.SmoothPlastic)
	disc.Shape = Enum.PartType.Cylinder
	disc.CFrame = CFrame.new(0, GameConfig.ISLAND_TOP_Y + 0.35, 88) * CFrame.Angles(0, 0, math.rad(90))

	buildSign(plaza, "WelcomeSign", Vector3.new(-16, GameConfig.ISLAND_TOP_Y, 96), math.rad(160),
		"BRAINROT BAY", Color3.fromRGB(255, 255, 255), Color3.fromRGB(64, 160, 255), Vector3.new(22, 5.5, 0.6))
	buildSign(plaza, "HowToSign", Vector3.new(16, GameConfig.ISLAND_TOP_Y, 96), math.rad(-160),
		"BUY • CARRY • COLLECT!", Color3.fromRGB(40, 40, 50), Color3.fromRGB(255, 217, 61), Vector3.new(22, 5.5, 0.6))

	-- Upgrade stall: a striped awning over a counter on the plaza's south.
	local stall = Instance.new("Folder")
	stall.Name = "UpgradeStall"
	stall.Parent = plaza
	part(stall, "Counter", Vector3.new(14, 3, 4), CFrame.new(0, GameConfig.ISLAND_TOP_Y + 1.5, 70), WOOD, Enum.Material.Wood)
	for _, x in ipairs({ -6.5, 6.5 }) do
		part(stall, "StallPost", Vector3.new(0.7, 8, 0.7), CFrame.new(x, GameConfig.ISLAND_TOP_Y + 4, 70), WOOD_DARK, Enum.Material.Wood)
	end
	local awning = part(stall, "Awning", Vector3.new(16, 0.5, 7),
		CFrame.new(0, GameConfig.ISLAND_TOP_Y + 8.2, 70) * CFrame.Angles(math.rad(8), 0, 0),
		Color3.fromRGB(255, 90, 120), Enum.Material.SmoothPlastic)
	awning.CanCollide = false
	buildSign(stall, "StallSign", Vector3.new(0, GameConfig.ISLAND_TOP_Y, 66.4), math.rad(180),
		"UPGRADES", Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 80, 200), Vector3.new(14, 3.6, 0.5))
	return plaza
end

-- The safe hill at the north end: high enough that the tide sweeping the
-- lane can never touch a player (or a carried brainrot) standing on it.
local function buildSafeHill(parent)
	local hill = Instance.new("Folder")
	hill.Name = "SafeHill"
	hill.Parent = parent
	part(hill, "HillBase", Vector3.new(56, 8, 30),
		CFrame.new(0, GameConfig.ISLAND_TOP_Y + 4, -96), Color3.fromRGB(110, 190, 100), Enum.Material.Grass)
	part(hill, "HillTop", Vector3.new(40, 2, 20),
		CFrame.new(0, GameConfig.ISLAND_TOP_Y + 9, -96), Color3.fromRGB(130, 205, 115), Enum.Material.Grass)
	buildSign(hill, "HillSign", Vector3.new(0, GameConfig.ISLAND_TOP_Y + 10, -84), 0,
		"SAFE HILL — TIDE CAN'T REACH!", Color3.fromRGB(30, 90, 40), Color3.fromRGB(200, 245, 200), Vector3.new(24, 4.5, 0.6))
	buildPalm(hill, Vector3.new(-16, GameConfig.ISLAND_TOP_Y + 10, -98), 0.12)
	buildPalm(hill, Vector3.new(16, GameConfig.ISLAND_TOP_Y + 10, -94), -0.1)
end

-- Build everything and remember the layout for the other systems.
function WorldBuilder.build()
	local world = Instance.new("Folder")
	world.Name = "BrainrotBay"
	world.Parent = Workspace

	local size = GameConfig.ISLAND_SIZE
	part(world, "IslandDock", Vector3.new(size, 4, size),
		CFrame.new(0, GameConfig.ISLAND_TOP_Y - 2, 0), SAND, Enum.Material.Sand)
	-- Wooden rim so the dock reads as built over the sea in screenshots.
	part(world, "DockRim", Vector3.new(size + 6, 2.5, size + 6),
		CFrame.new(0, GameConfig.ISLAND_TOP_Y - 3.4, 0), WOOD_DARK, Enum.Material.Wood)

	WorldBuilder.lane = buildLane(world)
	buildPlaza(world)
	buildSafeHill(world)

	-- Eight bases: four down each side, doors facing the lane.
	local basesFolder = Instance.new("Folder")
	basesFolder.Name = "Bases"
	basesFolder.Parent = world
	local basePositions = {}
	for i = 0, 3 do
		table.insert(basePositions, { center = Vector3.new(-72, GameConfig.ISLAND_TOP_Y, -66 + i * 44), facing = math.rad(90) })
	end
	for i = 0, 3 do
		table.insert(basePositions, { center = Vector3.new(72, GameConfig.ISLAND_TOP_Y, -66 + i * 44), facing = math.rad(-90) })
	end
	for index, spot in ipairs(basePositions) do
		WorldBuilder.bases[index] = buildBase(basesFolder, index, spot.center, spot.facing)
	end

	-- Beach dressing: palms and lamps scattered where they frame the play.
	for _, spot in ipairs({
		Vector3.new(-30, GameConfig.ISLAND_TOP_Y, -88), Vector3.new(30, GameConfig.ISLAND_TOP_Y, -88),
		Vector3.new(-100, GameConfig.ISLAND_TOP_Y, 88), Vector3.new(100, GameConfig.ISLAND_TOP_Y, 88),
		Vector3.new(-30, GameConfig.ISLAND_TOP_Y, 100), Vector3.new(30, GameConfig.ISLAND_TOP_Y, 100),
	}) do
		buildPalm(world, spot, (spot.X % 7) * 0.02)
	end
	for _, spot in ipairs({
		Vector3.new(-16, GameConfig.ISLAND_TOP_Y, -40), Vector3.new(16, GameConfig.ISLAND_TOP_Y, -40),
		Vector3.new(-16, GameConfig.ISLAND_TOP_Y, 20), Vector3.new(16, GameConfig.ISLAND_TOP_Y, 20),
		Vector3.new(-16, GameConfig.ISLAND_TOP_Y, 60), Vector3.new(16, GameConfig.ISLAND_TOP_Y, 60),
	}) do
		buildLamp(world, spot)
	end

	return world
end

-- Is this position inside the tide's kill zone? The lane strip at dock
-- height: on a base deck, the plaza disc or the hill you are safe.
function WorldBuilder.isInTideZone(position)
	if math.abs(position.X) > GameConfig.LANE_WIDTH / 2 + 3 then
		return false
	end
	if position.Z < -GameConfig.LANE_Z_LENGTH / 2 - 4 or position.Z > GameConfig.LANE_Z_LENGTH / 2 + 4 then
		return false
	end
	if position.Y > GameConfig.ISLAND_TOP_Y + GameConfig.TIDE_SAFE_HEIGHT then
		return false
	end
	return true
end

return WorldBuilder
