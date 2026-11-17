-- PlayerState.luau
-- The one place a player's run lives: cash, rebirths, upgrades, the brainrot
-- on their head and the brainrots standing on their base. Nothing else keeps
-- a copy; BaseManager, ConveyorBelt and TideWave all read and write here, so
-- the numbers on the HUD can never drift from the numbers that pay out.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local PlayerState = {}
PlayerState._states = {}

-- A fresh run: starting cash, no rebirths, empty hands, empty base.
function PlayerState.create(player)
	local state = {
		player = player,
		cash = GameConfig.STARTING_CASH,
		rebirths = 0,
		upgrades = {}, -- upgrade id -> true
		carried = nil, -- the wild/stolen brainrot record on the player's head
		placed = {}, -- pad index -> placed brainrot record
		baseIndex = nil, -- filled by BaseManager when a base is claimed
		totalEarned = 0,
		steals = 0,
	}
	PlayerState._states[player] = state
	PlayerState._syncLeaderstats(state)
	return state
end

function PlayerState.get(player)
	return PlayerState._states[player]
end

function PlayerState.remove(player)
	PlayerState._states[player] = nil
end

function PlayerState.all()
	return PlayerState._states
end

-- leaderstats mirrors cash and rebirths for the Roblox player list; the
-- state table stays the source of truth and this only publishes it.
function PlayerState._syncLeaderstats(state)
	local leaderstats = state.player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = state.player
		local cashValue = Instance.new("IntValue")
		cashValue.Name = "Cash"
		cashValue.Parent = leaderstats
		local rebirthValue = Instance.new("IntValue")
		rebirthValue.Name = "Rebirths"
		rebirthValue.Parent = leaderstats
	end
	leaderstats.Cash.Value = math.floor(state.cash)
	leaderstats.Rebirths.Value = state.rebirths
end

function PlayerState.addCash(state, amount)
	state.cash += amount
	if amount > 0 then
		state.totalEarned += amount
	end
	PlayerState._syncLeaderstats(state)
end

function PlayerState.trySpend(state, amount)
	if state.cash < amount then
		return false
	end
	state.cash -= amount
	PlayerState._syncLeaderstats(state)
	return true
end

function PlayerState.hasUpgrade(state, upgradeId)
	return state.upgrades[upgradeId] == true
end

function PlayerState.grantUpgrade(state, upgradeId)
	state.upgrades[upgradeId] = true
end

-- The money per second this player's placed brainrots earn right now,
-- after each copy's own rate and the owner's rebirth multiplier.
function PlayerState.incomePerSecond(state)
	local total = 0
	for _, record in pairs(state.placed) do
		total += record.rate
	end
	return total * GameConfig.incomeMultiplier(state.rebirths)
end

function PlayerState.placedCount(state)
	local count = 0
	for _ in pairs(state.placed) do
		count += 1
	end
	return count
end

function PlayerState.firstFreePad(state)
	for padIndex = 1, GameConfig.PADS_PER_BASE do
		if state.placed[padIndex] == nil then
			return padIndex
		end
	end
	return nil
end

-- Rebirth wipes cash and placed brainrots (BaseManager clears the models)
-- and banks the permanent multiplier.
function PlayerState.applyRebirth(state)
	state.cash = GameConfig.STARTING_CASH
	state.rebirths += 1
	state.placed = {}
	state.carried = nil
	PlayerState._syncLeaderstats(state)
end

-- Wire the lifecycle once, from Main.server: join makes a state, leaving
-- drops it. BaseManager listens to the same events for bases and models.
function PlayerState.bindLifecycle()
	Players.PlayerAdded:Connect(function(player)
		PlayerState.create(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		PlayerState.remove(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		if not PlayerState._states[player] then
			PlayerState.create(player)
		end
	end
end

return PlayerState
