-- Effects.client.luau
-- The tide, felt on the client: a siren banner counts the warning down in
-- the middle of the screen, the edges of the world tint blue as the wave
-- sweeps, and a calm note tells you when it is safe to hunt again. It only
-- listens to the server's TideUpdate events — the wave itself, and who it
-- catches, is always the server's word.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local tideRemote = remotes:WaitForChild("TideUpdate")

local gui = Instance.new("ScreenGui")
gui.Name = "TideEffects"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

-- Blue wash over the whole screen while the wave is on the island.
local wash = Instance.new("Frame")
wash.Name = "Wash"
wash.Size = UDim2.fromScale(1, 1)
wash.BackgroundColor3 = Color3.fromRGB(40, 130, 230)
wash.BackgroundTransparency = 1
wash.BorderSizePixel = 0
wash.Parent = gui

-- The siren banner: impossible to miss, counts down, then shouts.
local banner = Instance.new("Frame")
banner.Name = "TideBanner"
banner.Size = UDim2.fromOffset(720, 84)
banner.Position = UDim2.new(0.5, -360, 0, 150)
banner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel = 0
banner.Visible = false
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = banner
banner.Parent = gui

local bannerText = Instance.new("TextLabel")
bannerText.Name = "BannerText"
bannerText.Size = UDim2.fromScale(1, 1)
bannerText.BackgroundTransparency = 1
bannerText.Font = Enum.Font.FredokaOne
bannerText.TextSize = 40
bannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
bannerText.TextStrokeTransparency = 0.3
bannerText.Text = ""
bannerText.Parent = banner

local function flashBanner()
	for _ = 1, 2 do
		banner.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
		task.wait(0.18)
		banner.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
		task.wait(0.18)
	end
end

local function onTideUpdate(phase, seconds)
	if phase == "incoming" then
		banner.Visible = true
		bannerText.Text = "🌊 THE TIDE STIRS…"
	elseif phase == "warning" then
		banner.Visible = true
		bannerText.Text = string.format("🌊 TSUNAMI TIDE IN %d — RUN HOME OR CLIMB THE HILL!", seconds)
		if seconds == 10 then
			task.spawn(flashBanner)
		end
	elseif phase == "sweep" then
		banner.Visible = true
		bannerText.Text = "🌊🌊 THE TIDE IS HERE! 🌊🌊"
		TweenService:Create(wash, TweenInfo.new(0.8), { BackgroundTransparency = 0.75 }):Play()
	elseif phase == "calm" then
		bannerText.Text = "The tide is gone. Back to the lane!"
		TweenService:Create(wash, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
		task.delay(2.5, function()
			banner.Visible = false
		end)
	end
end
tideRemote.OnClientEvent:Connect(onTideUpdate)
