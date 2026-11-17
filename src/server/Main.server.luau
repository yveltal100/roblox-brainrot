-- Main.server.luau
-- Brainrot Bay's bootstrap and switchboard. It builds the world, creates
-- the RemoteEvents the HUD talks through, starts every system (conveyor,
-- bases, tide), answers the client's requests (place, collect, rebirth,
-- upgrades, drop) and keeps each player's HUD snapshot flowing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local ConveyorBelt = require(script.Parent:WaitForChild("ConveyorBelt"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local TideWave = require(script.Parent:WaitForChild("TideWave"))

-- Remotes live in one folder the client waits for by name.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local notifyRemote = makeRemote("Notify")
local tideRemote = makeRemote("TideUpdate")
local stateRemote = makeRemote("StateSync")
local requestPlace = makeRemote("RequestPlace")
local requestCollect = makeRemote("RequestCollect")
local requestDrop = makeRemote("RequestDrop")
local requestRebirth = makeRemote("RequestRebirth")
local requestUpgrade = makeRemote("RequestUpgrade")
local requestLock = makeRemote("RequestLock")

local function notify(player, message)
	notifyRemote:FireClient(player, message)
end

local function broadcastTide(phase, seconds)
	tideRemote:FireAllClients(phase, seconds)
end

-- World first: every other system reads the layout WorldBuilder raises.
WorldBuilder.build()

ConveyorBelt.init(notify)
BaseManager.init(notify)
TideWave.init(notify, broadcastTide)

PlayerState.bindLifecycle()
BaseManager.start()
ConveyorBelt.start()
TideWave.start()

-- A respawned character walks at the right speed for what it carries.
local function bindCharacter(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			-- Death drops the catch back into the sea, like the tide does.
			ConveyorBelt.destroyCarried(player)
		end)
		task.wait(0.2)
		ConveyorBelt.refreshWalkSpeed(player)
	end)
end
Players.PlayerAdded:Connect(bindCharacter)
for _, player in ipairs(Players:GetPlayers()) do
	bindCharacter(player)
end

-- Rainbow mutations cycle their hue wherever the model stands: lane,
-- head or pad. One loop over the Brainrots folder paints them all.
RunService.Heartbeat:Connect(function()
	local folder = Workspace:FindFirstChild("Brainrots")
	if not folder then
		return
	end
	local hue = (tick() % 6) / 6
	for _, model in ipairs(folder:GetChildren()) do
		if model:GetAttribute("Rainbow") then
			local body = model:FindFirstChild("Body")
			if body then
				body.Color = Color3.fromHSV(hue, 0.65, 1)
			end
		end
	end
end)

-- HUD requests. Each is small, checked on the server, and answered by the
-- next StateSync snapshot rather than a reply payload.
requestPlace.OnServerEvent:Connect(function(player)
	BaseManager.tryPlaceCarried(player)
end)

requestCollect.OnServerEvent:Connect(function(player)
	BaseManager.collectPending(player)
end)

requestDrop.OnServerEvent:Connect(function(player)
	if ConveyorBelt.destroyCarried(player) then
		notify(player, "Threw it back to the sea. No refunds out here.")
	end
end)

requestLock.OnServerEvent:Connect(function(player)
	BaseManager.tryLock(player)
end)

requestRebirth.OnServerEvent:Connect(function(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local cost = GameConfig.rebirthCost(state.rebirths)
	if state.cash < cost then
		notify(player, string.format("Rebirth needs $%s banked. You have $%s.", BrainrotData.formatMoney(cost), BrainrotData.formatMoney(state.cash)))
		return
	end
	ConveyorBelt.destroyCarried(player)
	BaseManager.clearBase(player)
	PlayerState.applyRebirth(state)
	BaseManager.refreshSign(player)
	ConveyorBelt.refreshWalkSpeed(player)
	notify(player, string.format("REBIRTH %d! All income is now x%d forever.", state.rebirths, GameConfig.incomeMultiplier(state.rebirths)))
end)

requestUpgrade.OnServerEvent:Connect(function(player, upgradeId)
	local state = PlayerState.get(player)
	local upgrade = GameConfig.upgradeById(upgradeId)
	if not state or not upgrade then
		return
	end
	if PlayerState.hasUpgrade(state, upgradeId) then
		notify(player, "You already own " .. upgrade.name .. ".")
		return
	end
	if not PlayerState.trySpend(state, upgrade.price) then
		notify(player, string.format("%s costs $%s.", upgrade.name, BrainrotData.formatMoney(upgrade.price)))
		return
	end
	PlayerState.grantUpgrade(state, upgradeId)
	ConveyorBelt.refreshWalkSpeed(player)
	notify(player, "Bought " .. upgrade.name .. "! " .. upgrade.blurb)
end)

-- The HUD snapshot: everything the client draws, from the one state table.
local function snapshotFor(player)
	local state = PlayerState.get(player)
	if not state then
		return nil
	end
	local pendingTotal = 0
	for _, record in pairs(state.placed) do
		pendingTotal += record.pending
	end
	local carriedName = nil
	if state.carried then
		local species = BrainrotData.speciesById(state.carried.speciesId)
		carriedName = species and species.name or "Brainrot"
		if state.carried.mutationName ~= "Normal" then
			carriedName = state.carried.mutationName .. " " .. carriedName
		end
	end
	return {
		cash = math.floor(state.cash),
		incomePerSecond = PlayerState.incomePerSecond(state),
		pending = math.floor(pendingTotal),
		placedCount = PlayerState.placedCount(state),
		maxPads = GameConfig.PADS_PER_BASE,
		carriedName = carriedName,
		rebirths = state.rebirths,
		rebirthCost = GameConfig.rebirthCost(state.rebirths),
		baseLocked = state.baseIndex ~= nil and BaseManager.isLocked(state.baseIndex) or false,
		lockSecondsLeft = state.baseIndex ~= nil and BaseManager.lockSecondsLeft(state.baseIndex) or 0,
		upgrades = state.upgrades,
		steals = state.steals,
	}
end

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local snapshot = snapshotFor(player)
			if snapshot then
				stateRemote:FireClient(player, snapshot)
			end
		end
	end
end)

print("[Brainrot Bay] World built, conveyor running, tide scheduled. Good hunting!")
