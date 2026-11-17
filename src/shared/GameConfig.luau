-- GameConfig.luau
-- Every tuning number of Brainrot Bay in one table: the island layout, the
-- conveyor rhythm, the tide cycle, base locks, steals and rebirths. Server
-- and client both read it, so a balance change is one edit, never a hunt.

local GameConfig = {}

-- Island layout (studs). The island is a square dock over the sea; bases
-- ring the edge and the conveyor lane crosses the middle, north to south.
GameConfig.ISLAND_SIZE = 220
GameConfig.ISLAND_TOP_Y = 2
GameConfig.BASE_COUNT = 8
GameConfig.PADS_PER_BASE = 6
GameConfig.LANE_Z_LENGTH = 150
GameConfig.LANE_WIDTH = 18

-- Player start and economy.
GameConfig.STARTING_CASH = 250
GameConfig.INCOME_TICK_SECONDS = 1
GameConfig.MAX_CARRIED = 1

-- Conveyor: a new wild brainrot walks in every few seconds and strolls the
-- lane once; unbought ones dive back into the sea at the far end.
GameConfig.SPAWN_INTERVAL_SECONDS = 4
GameConfig.WALK_SPEED = 7
GameConfig.MAX_WILD_AT_ONCE = 7

-- Carrying: hauling a brainrot home is slower than running empty, which is
-- what makes the dash back to base a decision when the tide siren sounds.
GameConfig.WALK_SPEED_NORMAL = 16
GameConfig.WALK_SPEED_CARRYING = 11.5
GameConfig.WALK_SPEED_PER_REBIRTH = 0.4

-- Bases: the lock button seals a base against thieves for a while, then
-- needs a breather before it can seal again.
GameConfig.LOCK_SECONDS = 60
GameConfig.LOCK_COOLDOWN_SECONDS = 30

-- The tide: a long calm, a shouted warning, then the wave sweeps the lane.
-- Anyone caught in the lane zone loses the brainrot on their head and is
-- washed back to the plaza; brainrots already placed on bases stay safe.
GameConfig.TIDE_CALM_SECONDS = 75
GameConfig.TIDE_WARNING_SECONDS = 10
GameConfig.TIDE_SWEEP_SECONDS = 6
GameConfig.TIDE_SAFE_HEIGHT = 6 -- standing this high (hill, base deck) is safe

-- Rebirth: hand back your cash and your placed brainrots, keep your pads,
-- and every future dollar is multiplied. The price climbs steeply.
GameConfig.REBIRTH_BASE_COST = 25000
GameConfig.REBIRTH_COST_GROWTH = 6
GameConfig.INCOME_PER_REBIRTH = 1.0 -- +100% income per rebirth

function GameConfig.rebirthCost(rebirthsDone)
	return math.floor(GameConfig.REBIRTH_BASE_COST * (GameConfig.REBIRTH_COST_GROWTH ^ rebirthsDone))
end

function GameConfig.incomeMultiplier(rebirthsDone)
	return 1 + rebirthsDone * GameConfig.INCOME_PER_REBIRTH
end

-- Upgrades sold from the plaza stall: one-time buys, priced to matter.
GameConfig.UPGRADES = {
	{ id = "swift_shoes", name = "Swift Shoes", price = 2500, blurb = "+3 walk speed, even while carrying" },
	{ id = "hauler_gloves", name = "Hauler Gloves", price = 9000, blurb = "Carrying barely slows you down" },
	{ id = "lucky_charm", name = "Lucky Tide Charm", price = 30000, blurb = "The tide never takes your carried brainrot" },
}

function GameConfig.upgradeById(id)
	for _, upgrade in ipairs(GameConfig.UPGRADES) do
		if upgrade.id == id then
			return upgrade
		end
	end
	return nil
end

return GameConfig
