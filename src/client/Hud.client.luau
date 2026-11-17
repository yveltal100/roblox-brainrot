-- Hud.client.luau
-- Brainrot Bay's ScreenGui, drawn over the 3D world: cash and income up
-- top (clear of Roblox's own menu in the top-left corner), the carried
-- brainrot's name under it, action buttons along the bottom — place,
-- collect, lock, drop, rebirth — and a slide-in upgrade shop. Everything
-- it shows comes from the server's StateSync snapshots; every button is a
-- RemoteEvent the server checks again, so the HUD can ask but never grant.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local notifyRemote = remotes:WaitForChild("Notify")
local stateRemote = remotes:WaitForChild("StateSync")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, size, position, text, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.FredokaOne
	label.TextSize = textSize
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = parent
	return label
end

local function makePill(parent, name, size, position, bg)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = bg
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	frame.Parent = parent
	return frame
end

local function makeButton(parent, name, size, position, text, bg)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = size
	button.Position = position
	button.BackgroundColor3 = bg
	button.Font = Enum.Font.FredokaOne
	button.TextSize = 20
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextStrokeTransparency = 0.5
	button.Text = text
	button.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = button
	button.Parent = parent
	return button
end

-- Top centre: the wallet and what the base earns while you watch.
local cashPill = makePill(gui, "CashPill", UDim2.fromOffset(300, 54), UDim2.new(0.5, -310, 0, 14), Color3.fromRGB(30, 34, 44))
local cashLabel = makeLabel(cashPill, "CashText", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), "$250", 30, Color3.fromRGB(120, 255, 140))
cashLabel.TextXAlignment = Enum.TextXAlignment.Center

local incomePill = makePill(gui, "IncomePill", UDim2.fromOffset(300, 54), UDim2.new(0.5, 10, 0, 14), Color3.fromRGB(30, 34, 44))
local incomeLabel = makeLabel(incomePill, "IncomeText", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), "$0/s", 24, Color3.fromRGB(255, 220, 90))
incomeLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Top right: lifetime flavour — rebirths and successful steals.
local statsLabel = makeLabel(gui, "StatsText", UDim2.fromOffset(260, 30), UDim2.new(1, -270, 0, 16), "", 18, Color3.fromRGB(230, 240, 255))
statsLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Under the wallet: what is riding on your head right now.
local carriedLabel = makeLabel(gui, "CarriedText", UDim2.fromOffset(620, 34), UDim2.new(0.5, -310, 0, 76), "", 22, Color3.fromRGB(255, 170, 220))
carriedLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Toasts: server messages stack here and fade away.
local toastFrame = Instance.new("Frame")
toastFrame.Name = "Toasts"
toastFrame.Size = UDim2.fromOffset(560, 200)
toastFrame.Position = UDim2.new(0.5, -280, 0, 118)
toastFrame.BackgroundTransparency = 1
toastFrame.Parent = gui
local toastLayout = Instance.new("UIListLayout")
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 4)
toastLayout.Parent = toastFrame

local function showToast(message)
	local label = makeLabel(toastFrame, "Toast", UDim2.fromOffset(560, 30), UDim2.fromScale(0, 0), message, 20, Color3.fromRGB(255, 255, 255))
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextStrokeTransparency = 0.25
	task.delay(3.2, function()
		local tween = TweenService:Create(label, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 })
		tween:Play()
		tween.Completed:Connect(function()
			label:Destroy()
		end)
	end)
end
notifyRemote.OnClientEvent:Connect(showToast)

-- Bottom action bar: the verbs of the game, always one tap away.
local bar = Instance.new("Frame")
bar.Name = "ActionBar"
bar.Size = UDim2.fromOffset(760, 64)
bar.Position = UDim2.new(0.5, -380, 1, -78)
bar.BackgroundTransparency = 1
bar.Parent = gui
local barLayout = Instance.new("UIListLayout")
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.Padding = UDim.new(0, 10)
barLayout.Parent = bar

local placeButton = makeButton(bar, "PlaceButton", UDim2.fromOffset(170, 60), UDim2.new(), "PLACE IT!", Color3.fromRGB(64, 180, 90))
local collectButton = makeButton(bar, "CollectButton", UDim2.fromOffset(190, 60), UDim2.new(), "COLLECT $0", Color3.fromRGB(230, 165, 30))
local lockButton = makeButton(bar, "LockButton", UDim2.fromOffset(170, 60), UDim2.new(), "LOCK BASE", Color3.fromRGB(70, 130, 220))
local dropButton = makeButton(bar, "DropButton", UDim2.fromOffset(150, 60), UDim2.new(), "DROP", Color3.fromRGB(150, 90, 90))

placeButton.MouseButton1Click:Connect(function()
	remotes.RequestPlace:FireServer()
end)
collectButton.MouseButton1Click:Connect(function()
	remotes.RequestCollect:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	remotes.RequestLock:FireServer()
end)
dropButton.MouseButton1Click:Connect(function()
	remotes.RequestDrop:FireServer()
end)

-- Bottom right: the rebirth button, priced on its face.
local rebirthButton = makeButton(gui, "RebirthButton", UDim2.fromOffset(230, 64), UDim2.new(1, -244, 1, -78), "REBIRTH", Color3.fromRGB(150, 70, 220))
rebirthButton.MouseButton1Click:Connect(function()
	remotes.RequestRebirth:FireServer()
end)

-- Bottom left: base summary and the shop toggle.
local baseLabel = makeLabel(gui, "BaseText", UDim2.fromOffset(300, 30), UDim2.new(0, 14, 1, -112), "", 19, Color3.fromRGB(230, 240, 255))
local shopButton = makeButton(gui, "ShopButton", UDim2.fromOffset(170, 60), UDim2.new(0, 14, 1, -78), "UPGRADES", Color3.fromRGB(120, 80, 200))

-- The upgrade shop panel: one row per upgrade, price or OWNED on the right.
local shopPanel = makePill(gui, "ShopPanel", UDim2.fromOffset(430, 240), UDim2.new(0, 14, 1, -330), Color3.fromRGB(24, 26, 36))
shopPanel.Visible = false
makeLabel(shopPanel, "ShopTitle", UDim2.fromOffset(400, 36), UDim2.fromOffset(15, 8), "UPGRADE STALL", 24, Color3.fromRGB(255, 220, 120))
local shopRows = {}
for i, upgrade in ipairs(GameConfig.UPGRADES) do
	local row = makeButton(shopPanel, "Buy_" .. upgrade.id, UDim2.fromOffset(400, 56), UDim2.fromOffset(15, 52 + (i - 1) * 62),
		"", Color3.fromRGB(52, 56, 72))
	row.TextSize = 17
	row.TextXAlignment = Enum.TextXAlignment.Left
	shopRows[upgrade.id] = row
	row.MouseButton1Click:Connect(function()
		remotes.RequestUpgrade:FireServer(upgrade.id)
	end)
end
shopButton.MouseButton1Click:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
end)

-- Every snapshot redraws the numbers; buttons enable by what makes sense.
local function renderSnapshot(s)
	cashLabel.Text = "$" .. BrainrotData.formatMoney(s.cash)
	incomeLabel.Text = "$" .. BrainrotData.formatMoney(s.incomePerSecond) .. "/s"
	statsLabel.Text = string.format("Rebirths: %d   Steals: %d", s.rebirths, s.steals)
	if s.carriedName then
		carriedLabel.Text = "Carrying: " .. s.carriedName .. " — get it HOME!"
	else
		carriedLabel.Text = ""
	end
	collectButton.Text = "COLLECT $" .. BrainrotData.formatMoney(s.pending)
	placeButton.Visible = s.carriedName ~= nil
	dropButton.Visible = s.carriedName ~= nil
	if s.baseLocked then
		lockButton.Text = string.format("LOCKED %ds", s.lockSecondsLeft)
		lockButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	else
		lockButton.Text = "LOCK BASE"
		lockButton.BackgroundColor3 = Color3.fromRGB(70, 130, 220)
	end
	rebirthButton.Text = string.format("REBIRTH $%s", BrainrotData.formatMoney(s.rebirthCost))
	baseLabel.Text = string.format("Base: %d/%d brainrots • $%s waiting", s.placedCount, s.maxPads, BrainrotData.formatMoney(s.pending))
	for _, upgrade in ipairs(GameConfig.UPGRADES) do
		local row = shopRows[upgrade.id]
		if row then
			if s.upgrades[upgrade.id] then
				row.Text = string.format("  %s — OWNED", upgrade.name)
				row.BackgroundColor3 = Color3.fromRGB(40, 90, 60)
			else
				row.Text = string.format("  %s — $%s\n  %s", upgrade.name, BrainrotData.formatMoney(upgrade.price), upgrade.blurb)
				row.BackgroundColor3 = Color3.fromRGB(52, 56, 72)
			end
		end
	end
end
stateRemote.OnClientEvent:Connect(renderSnapshot)

showToast("Welcome to Brainrot Bay! Buy a brainrot from the lane and carry it home.")
