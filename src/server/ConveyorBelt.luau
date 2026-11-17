-- ConveyorBelt.luau
-- The heart of the hunt: wild brainrots climb out of the sea at the north
-- arch and stroll down the conveyor lane. Each wears its price on a prompt;
-- buy one and it rides on your head, slowing you down, until you place it
-- on your base, lose it to the tide, or a thief's base swallows it instead.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local BrainrotFactory = require(script.Parent:WaitForChild("BrainrotFactory"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local ConveyorBelt = {}
ConveyorBelt._wild = {} -- array of wild records strolling the lane
ConveyorBelt._notify = function(_player, _message) end
ConveyorBelt._rng = Random.new()

function ConveyorBelt.init(notifyFn)
	if notifyFn then
		ConveyorBelt._notify = notifyFn
	end
end

local function brainrotsFolder()
	local folder = Workspace:FindFirstChild("Brainrots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Brainrots"
		folder.Parent = Workspace
	end
	return folder
end

-- How fast this player walks right now: rebirths and shoes help, a
-- brainrot on the head hurts, Hauler Gloves mostly cancel the hurt.
function ConveyorBelt.refreshWalkSpeed(player)
	local state = PlayerState.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not state or not humanoid then
		return
	end
	local speed = GameConfig.WALK_SPEED_NORMAL + state.rebirths * GameConfig.WALK_SPEED_PER_REBIRTH
	if PlayerState.hasUpgrade(state, "swift_shoes") then
		speed += 3
	end
	if state.carried then
		local carrySpeed = GameConfig.WALK_SPEED_CARRYING
		if PlayerState.hasUpgrade(state, "hauler_gloves") then
			carrySpeed = GameConfig.WALK_SPEED_NORMAL - 1
		end
		if PlayerState.hasUpgrade(state, "swift_shoes") then
			carrySpeed += 3
		end
		speed = carrySpeed
	end
	humanoid.WalkSpeed = speed
end

-- Put a record's model on the player's head and mark the state as carrying.
function ConveyorBelt.carryRecord(player, record)
	local state = PlayerState.get(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not state or not head then
		return false
	end
	local model = record.model
	local root = model.PrimaryPart
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.Massless = true
		end
	end
	root.Anchored = false
	root.CFrame = head.CFrame * CFrame.new(0, 2.6, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = head
	weld.Part1 = root
	weld.Parent = root
	local label = model:FindFirstChild("NameLabel")
	if label then
		label.Enabled = true
	end
	state.carried = record
	ConveyorBelt.refreshWalkSpeed(player)
	return true
end

-- Take the carried model off the head. The record survives; the caller
-- decides whether it is placed on a pad, dropped or destroyed.
function ConveyorBelt.releaseCarried(player)
	local state = PlayerState.get(player)
	if not state or not state.carried then
		return nil
	end
	local record = state.carried
	state.carried = nil
	local root = record.model.PrimaryPart
	local weld = root:FindFirstChild("CarryWeld")
	if weld then
		weld:Destroy()
	end
	root.Anchored = true
	ConveyorBelt.refreshWalkSpeed(player)
	return record
end

-- The tide (or a voluntary throw-back) takes the carried brainrot for good.
function ConveyorBelt.destroyCarried(player)
	local record = ConveyorBelt.releaseCarried(player)
	if record and record.model then
		record.model:Destroy()
	end
	return record
end

-- A buyer at the lane: check hands and wallet, then hand over the catch.
local function onBuyPromptTriggered(wildEntry, player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if state.carried then
		ConveyorBelt._notify(player, "Hands full! Carry this one home first.")
		return
	end
	local price = wildEntry.record.price
	if state.cash < price then
		ConveyorBelt._notify(player, string.format("Need $%s — this one costs $%s.", BrainrotData.formatMoney(price - state.cash), BrainrotData.formatMoney(price)))
		return
	end
	for index, entry in ipairs(ConveyorBelt._wild) do
		if entry == wildEntry then
			table.remove(ConveyorBelt._wild, index)
			break
		end
	end
	local prompt = wildEntry.model.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:Destroy()
	end
	PlayerState.trySpend(state, price)
	if ConveyorBelt.carryRecord(player, wildEntry.record) then
		local species = BrainrotData.speciesById(wildEntry.record.speciesId)
		ConveyorBelt._notify(player, string.format("Got %s! Dash it back to your base!", species and species.name or "a brainrot"))
	else
		PlayerState.addCash(state, price) -- refund: nowhere to carry it
	end
end

-- Spawn one wild brainrot at the sea arch with a rolled species + mutation.
function ConveyorBelt.spawnWild()
	local lane = WorldBuilder.lane
	if not lane then
		return
	end
	local rng = ConveyorBelt._rng
	local species = BrainrotData.rollSpecies(rng)
	local mutation = BrainrotData.rollMutation(rng)
	local model = BrainrotFactory.buildModel(species, mutation)
	local record = BrainrotFactory.makeRecord(species, mutation, model)
	model.Parent = brainrotsFolder()

	local entry = { record = record, model = model, z = lane.startZ, sway = rng:NextNumber(-3.5, 3.5) }
	local root = model.PrimaryPart
	root.CFrame = CFrame.new(entry.sway, GameConfig.ISLAND_TOP_Y + species.height / 2 + 1.2, entry.z)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = string.format("Buy $%s", BrainrotData.formatMoney(record.price))
	prompt.ObjectText = species.name .. " • $" .. BrainrotData.formatMoney(record.rate) .. "/s"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		onBuyPromptTriggered(entry, player)
	end)

	table.insert(ConveyorBelt._wild, entry)
end

-- Stroll every wild brainrot down the lane, bobbing as it goes; at the far
-- arch it dives back into the sea and frees its slot for the next catch.
local function stepWild(dt)
	local lane = WorldBuilder.lane
	if not lane then
		return
	end
	for index = #ConveyorBelt._wild, 1, -1 do
		local entry = ConveyorBelt._wild[index]
		entry.z += GameConfig.WALK_SPEED * dt
		if entry.z >= lane.endZ then
			entry.model:Destroy()
			table.remove(ConveyorBelt._wild, index)
		else
			local root = entry.model.PrimaryPart
			local bob = math.sin(tick() * 5 + entry.record.bobPhase) * 0.22
			local species = BrainrotData.speciesById(entry.record.speciesId)
			local baseY = GameConfig.ISLAND_TOP_Y + (species and species.height or 3) / 2 + 1.2
			root.CFrame = CFrame.new(entry.sway, baseY + bob, entry.z)
				* CFrame.Angles(0, math.sin(tick() * 2 + entry.record.bobPhase) * 0.12, 0)
		end
	end
end

function ConveyorBelt.start()
	task.spawn(function()
		while true do
			task.wait(GameConfig.SPAWN_INTERVAL_SECONDS)
			if #ConveyorBelt._wild < GameConfig.MAX_WILD_AT_ONCE then
				ConveyorBelt.spawnWild()
			end
		end
	end)
	RunService.Heartbeat:Connect(stepWild)
	Players.PlayerRemoving:Connect(function(player)
		ConveyorBelt.destroyCarried(player)
	end)
end

function ConveyorBelt.wildCount()
	return #ConveyorBelt._wild
end

return ConveyorBelt
