-- TideWave.luau
-- The bay's threat. Every cycle the sea goes quiet, a siren banner warns
-- the whole server, and a wall of water sweeps down the conveyor lane.
-- Anyone caught standing in the lane is washed back to the plaza — and a
-- brainrot on their head is the sea's now. Bases, the plaza and the Safe
-- Hill stay dry: the dash home with a fresh catch is the game's heartbeat.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ConveyorBelt = require(script.Parent:WaitForChild("ConveyorBelt"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local TideWave = {}
TideWave._notify = function(_player, _message) end
TideWave._broadcast = function(_phase, _seconds) end
TideWave._running = false
TideWave._forceWave = false

function TideWave.init(notifyFn, broadcastFn)
	if notifyFn then
		TideWave._notify = notifyFn
	end
	if broadcastFn then
		TideWave._broadcast = broadcastFn
	end
end

-- TOUR.json calls this to bring the wave screenshot within reach: the next
-- cycle skips its calm and goes straight to the warning.
function TideWave.startWaveNow(_arg)
	TideWave._forceWave = true
end

local function buildWaveWall()
	local wall = Instance.new("Part")
	wall.Name = "TideWall"
	wall.Size = Vector3.new(GameConfig.LANE_WIDTH + 26, 15, 4)
	wall.Color = Color3.fromRGB(40, 140, 230)
	wall.Material = Enum.Material.Glass
	wall.Transparency = 0.35
	wall.Anchored = true
	wall.CanCollide = false
	wall.CastShadow = false
	local foam = Instance.new("Part")
	foam.Name = "Foam"
	foam.Size = Vector3.new(GameConfig.LANE_WIDTH + 26, 2.2, 4.6)
	foam.Color = Color3.fromRGB(240, 252, 255)
	foam.Material = Enum.Material.Neon
	foam.Anchored = true
	foam.CanCollide = false
	foam.CastShadow = false
	foam.Parent = wall
	return wall
end

-- Wash one player back to the plaza; the sea keeps a carried brainrot
-- unless the player bought the Lucky Tide Charm.
local function washPlayer(player)
	local state = PlayerState.get(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	if state and state.carried then
		if PlayerState.hasUpgrade(state, "lucky_charm") then
			TideWave._notify(player, "Your Lucky Tide Charm kept your brainrot dry!")
		else
			ConveyorBelt.destroyCarried(player)
			TideWave._notify(player, "The tide took the brainrot on your head!")
		end
	end
	root.CFrame = CFrame.new(0, GameConfig.ISLAND_TOP_Y + 4, 88)
	root.AssemblyLinearVelocity = Vector3.zero
	TideWave._notify(player, "Washed back to the plaza! Run for your base or the Safe Hill next time.")
end

-- Sweep the wall down the lane, washing whoever it catches in the zone.
local function runSweep()
	TideWave._broadcast("sweep", GameConfig.TIDE_SWEEP_SECONDS)
	local wall = buildWaveWall()
	wall.Parent = Workspace:FindFirstChild("BrainrotBay") or Workspace
	local foam = wall:FindFirstChild("Foam")
	local startZ = -GameConfig.LANE_Z_LENGTH / 2 - 14
	local endZ = GameConfig.LANE_Z_LENGTH / 2 + 14
	local washed = {}
	local elapsed = 0
	local step = 0.1
	while elapsed < GameConfig.TIDE_SWEEP_SECONDS do
		task.wait(step)
		elapsed += step
		local alpha = elapsed / GameConfig.TIDE_SWEEP_SECONDS
		local z = startZ + (endZ - startZ) * alpha
		wall.CFrame = CFrame.new(0, GameConfig.ISLAND_TOP_Y + 6.5, z)
		if foam then
			foam.CFrame = CFrame.new(0, GameConfig.ISLAND_TOP_Y + 14.6, z)
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if not washed[player] then
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and math.abs(root.Position.Z - z) < 7 and WorldBuilder.isInTideZone(root.Position) then
					washed[player] = true
					washPlayer(player)
				end
			end
		end
	end
	wall:Destroy()
	TideWave._broadcast("calm", GameConfig.TIDE_CALM_SECONDS)
end

-- The endless cycle: calm, warning, sweep. startWaveNow shortens the calm.
local function cycleLoop()
	while TideWave._running do
		local calmLeft = GameConfig.TIDE_CALM_SECONDS
		while calmLeft > 0 and not TideWave._forceWave do
			task.wait(1)
			calmLeft -= 1
			if calmLeft == 15 then
				TideWave._broadcast("incoming", 15)
			end
		end
		TideWave._forceWave = false
		for secondsLeft = GameConfig.TIDE_WARNING_SECONDS, 1, -1 do
			TideWave._broadcast("warning", secondsLeft)
			task.wait(1)
		end
		runSweep()
	end
end

function TideWave.start()
	if TideWave._running then
		return
	end
	TideWave._running = true
	task.spawn(cycleLoop)
end

function TideWave.stop()
	TideWave._running = false
end

return TideWave
