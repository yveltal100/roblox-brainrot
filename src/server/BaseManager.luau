-- BaseManager.luau
-- Runs the eight bases: who owns which, placing a carried brainrot on a
-- pad, the dollars that pile up on each pad until the owner steps on the
-- gold collect pad, the lock button that seals a base, and the steal
-- prompts that let a bold visitor carry someone else's earner home.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PlayerState = require(script.Parent:WaitForChild("PlayerState"))
local ConveyorBelt = require(script.Parent:WaitForChild("ConveyorBelt"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

local BaseManager = {}
BaseManager._owners = {} -- baseIndex -> player
BaseManager._lockedUntil = {} -- baseIndex -> os.clock() when the lock ends
BaseManager._lockReadyAt = {} -- baseIndex -> os.clock() when it may lock again
BaseManager._notify = function(_player, _message) end

function BaseManager.init(notifyFn)
	if notifyFn then
		BaseManager._notify = notifyFn
	end
end

local function setSignText(base, text)
	local gui = base.signBoard:FindFirstChild("SignText")
	local label = gui and gui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = text
	end
end

function BaseManager.isLocked(baseIndex)
	local until_ = BaseManager._lockedUntil[baseIndex]
	return until_ ~= nil and os.clock() < until_
end

function BaseManager.lockSecondsLeft(baseIndex)
	if not BaseManager.isLocked(baseIndex) then
		return 0
	end
	return math.ceil(BaseManager._lockedUntil[baseIndex] - os.clock())
end

-- The sign over the door tells the whole story of a base at a glance:
-- whose it is, what it earns, and whether the lock is holding.
function BaseManager.refreshSign(player)
	local state = PlayerState.get(player)
	if not state or not state.baseIndex then
		return
	end
	local base = WorldBuilder.bases[state.baseIndex]
	if not base then
		return
	end
	local income = PlayerState.incomePerSecond(state)
	local text = string.format("%s'S BASE • $%s/s", string.upper(player.DisplayName), BrainrotData.formatMoney(income))
	if BaseManager.isLocked(state.baseIndex) then
		text ..= string.format(" • LOCKED %ds", BaseManager.lockSecondsLeft(state.baseIndex))
	end
	setSignText(base, text)
end

-- Claim the lowest free base for a joining player; with eight bases a
-- ninth visitor watches until someone leaves.
function BaseManager.assignBase(player)
	local state = PlayerState.get(player)
	if not state then
		return nil
	end
	for index = 1, GameConfig.BASE_COUNT do
		if BaseManager._owners[index] == nil then
			BaseManager._owners[index] = player
			state.baseIndex = index
			local base = WorldBuilder.bases[index]
			if base then
				base.folder:SetAttribute("Owner", player.Name)
			end
			BaseManager.refreshSign(player)
			return index
		end
	end
	BaseManager._notify(player, "All bases are taken — watch the bay until one frees up!")
	return nil
end

function BaseManager.releaseBase(player)
	local state = PlayerState.get(player)
	if not state or not state.baseIndex then
		return
	end
	local index = state.baseIndex
	BaseManager.clearBase(player)
	BaseManager._owners[index] = nil
	BaseManager._lockedUntil[index] = nil
	local base = WorldBuilder.bases[index]
	if base then
		base.folder:SetAttribute("Owner", "")
		setSignText(base, "EMPTY BASE")
	end
	state.baseIndex = nil
end

-- Destroy every placed model of a player (rebirth, leaving). Cash already
-- banked is untouched; uncollected pad money vanishes with the models.
function BaseManager.clearBase(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	for _, record in pairs(state.placed) do
		if record.model then
			record.model:Destroy()
		end
	end
	state.placed = {}
end

local function addStealPrompt(record, ownerPlayer)
	local root = record.model.PrimaryPart
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "STEAL!"
	prompt.ObjectText = "Grab and dash to your base"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(thief)
		BaseManager.trySteal(thief, ownerPlayer, record)
	end)
end

-- A thief grabs a placed brainrot: the base must be unlocked, the thief's
-- hands empty. The record changes owner the moment it is placed again;
-- until then it is simply loot on the thief's head.
function BaseManager.trySteal(thief, ownerPlayer, record)
	local thiefState = PlayerState.get(thief)
	local ownerState = PlayerState.get(ownerPlayer)
	if not thiefState or not ownerState or thief == ownerPlayer then
		return
	end
	if thiefState.carried then
		BaseManager._notify(thief, "Hands full! You can only carry one.")
		return
	end
	if ownerState.baseIndex and BaseManager.isLocked(ownerState.baseIndex) then
		BaseManager._notify(thief, "Locked! That base is sealed right now.")
		return
	end
	local padIndex = nil
	for index, placed in pairs(ownerState.placed) do
		if placed == record then
			padIndex = index
			break
		end
	end
	if not padIndex then
		return -- already taken by someone quicker
	end
	ownerState.placed[padIndex] = nil
	local prompt = record.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt:Destroy()
	end
	record.pending = 0
	if ConveyorBelt.carryRecord(thief, record) then
		thiefState.steals += 1
		BaseManager._notify(thief, "STOLEN! Get it to your base before they catch you!")
		BaseManager._notify(ownerPlayer, string.format("%s just stole a brainrot from your base!", thief.DisplayName))
		BaseManager.refreshSign(ownerPlayer)
	end
end

-- Place the carried brainrot on the first free pad of the player's base.
function BaseManager.tryPlaceCarried(player)
	local state = PlayerState.get(player)
	if not state or not state.carried or not state.baseIndex then
		return false
	end
	local padIndex = PlayerState.firstFreePad(state)
	if not padIndex then
		BaseManager._notify(player, "Base full! Rebirth or let one go before buying more.")
		return false
	end
	local base = WorldBuilder.bases[state.baseIndex]
	local record = ConveyorBelt.releaseCarried(player)
	if not record then
		return false
	end
	local pad = base.pads[padIndex]
	local species = BrainrotData.speciesById(record.speciesId)
	local standHeight = (species and species.height or 3) / 2 + 0.6
	local home = pad.CFrame * CFrame.new(0, standHeight + 0.25, 0)
	record.model.PrimaryPart.CFrame = home
	record.homeCFrame = home
	record.pending = 0
	state.placed[padIndex] = record
	addStealPrompt(record, player)
	BaseManager.refreshSign(player)
	BaseManager._notify(player, string.format("Placed! Now earning $%s/s.", BrainrotData.formatMoney(record.rate * GameConfig.incomeMultiplier(state.rebirths))))
	return true
end

-- Step on the gold pad: every dollar your brainrots piled up is banked.
function BaseManager.collectPending(player)
	local state = PlayerState.get(player)
	if not state then
		return 0
	end
	local total = 0
	for _, record in pairs(state.placed) do
		total += record.pending
		record.pending = 0
	end
	if total > 0 then
		PlayerState.addCash(state, total)
		BaseManager._notify(player, string.format("Collected $%s!", BrainrotData.formatMoney(total)))
	end
	return total
end

-- The lock button: seal the base, repaint the button while it holds and
-- while it cools down, and keep the sign's countdown honest. Called by the
-- physical button's Touched and by the HUD's lock button alike.
function BaseManager.tryLock(player)
	local state = PlayerState.get(player)
	if not state or not state.baseIndex then
		return
	end
	local baseIndex = state.baseIndex
	local now = os.clock()
	if BaseManager.isLocked(baseIndex) then
		return
	end
	if BaseManager._lockReadyAt[baseIndex] and now < BaseManager._lockReadyAt[baseIndex] then
		BaseManager._notify(player, "Lock is recharging…")
		return
	end
	BaseManager._lockedUntil[baseIndex] = now + GameConfig.LOCK_SECONDS
	BaseManager._lockReadyAt[baseIndex] = now + GameConfig.LOCK_SECONDS + GameConfig.LOCK_COOLDOWN_SECONDS
	local base = WorldBuilder.bases[baseIndex]
	base.lockButton.Color = Color3.fromRGB(230, 60, 60)
	BaseManager._notify(player, string.format("Base locked for %d seconds!", GameConfig.LOCK_SECONDS))
	task.delay(GameConfig.LOCK_SECONDS, function()
		base.lockButton.Color = Color3.fromRGB(90, 200, 120)
		BaseManager.refreshSign(player)
	end)
	BaseManager.refreshSign(player)
end

local function playerFromHit(hit)
	local character = hit and hit.Parent
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

-- Touch wiring: deck places, collect pad collects, lock button locks.
-- A short per-player debounce keeps Touched spam from double-firing.
local function watchBase(base)
	local debounce = {}
	local function debounceOk(player)
		local now = os.clock()
		if debounce[player] and now - debounce[player] < 0.6 then
			return false
		end
		debounce[player] = now
		return true
	end
	base.deck.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or not debounceOk(player) then
			return
		end
		local state = PlayerState.get(player)
		if state and state.baseIndex == base.index and state.carried then
			BaseManager.tryPlaceCarried(player)
		end
	end)
	base.collectPad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player or not debounceOk(player) then
			return
		end
		local state = PlayerState.get(player)
		if state and state.baseIndex == base.index then
			BaseManager.collectPending(player)
		end
	end)
	base.lockButton.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player and debounceOk(player) then
			local state = PlayerState.get(player)
			if state and state.baseIndex == base.index then
				BaseManager.tryLock(player)
			end
		end
	end)
end

-- Every second, each placed brainrot piles its rate (times its owner's
-- rebirth multiplier) onto its pad, and rich pads glow brighter.
local function incomeTick()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.get(player)
		if state then
			local multiplier = GameConfig.incomeMultiplier(state.rebirths)
			for padIndex, record in pairs(state.placed) do
				record.pending += record.rate * multiplier * GameConfig.INCOME_TICK_SECONDS
				local base = WorldBuilder.bases[state.baseIndex]
				if base then
					local pad = base.pads[padIndex]
					local glow = math.clamp(record.pending / 500, 0, 1)
					pad.Color = Color3.fromRGB(245, 245, 250):Lerp(Color3.fromRGB(255, 205, 40), glow)
				end
			end
		end
	end
end

-- Placed brainrots bob happily on their pads; carried and wild ones are
-- animated by their own systems.
local function bobPlaced()
	local t = tick()
	for _, player in ipairs(Players:GetPlayers()) do
		local state = PlayerState.get(player)
		if state then
			for _, record in pairs(state.placed) do
				if record.homeCFrame and record.model and record.model.PrimaryPart then
					local bob = math.sin(t * 2.2 + record.bobPhase) * 0.15
					record.model.PrimaryPart.CFrame = record.homeCFrame * CFrame.new(0, bob, 0)
						* CFrame.Angles(0, math.sin(t * 0.8 + record.bobPhase) * 0.2, 0)
				end
			end
		end
	end
end

function BaseManager.start()
	for _, base in ipairs(WorldBuilder.bases) do
		watchBase(base)
	end
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.5)
			if not PlayerState.get(player) then
				return
			end
			if not PlayerState.get(player).baseIndex then
				BaseManager.assignBase(player)
			end
		end)
		task.spawn(function()
			task.wait(0.5)
			if PlayerState.get(player) and not PlayerState.get(player).baseIndex then
				BaseManager.assignBase(player)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		BaseManager.releaseBase(player)
	end)
	task.spawn(function()
		while true do
			task.wait(GameConfig.INCOME_TICK_SECONDS)
			incomeTick()
		end
	end)
	RunService.Heartbeat:Connect(bobPlaced)
end

return BaseManager
