local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/modern"))()
local Players, ReplicatedStorage, Workspace = game:GetService("Players"), game:GetService("ReplicatedStorage"), game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local autoTab = Lib:Tab("Auto")
local visualTab = Lib:Tab("Visual")
local miscTab = Lib:Tab("Misc")
local playerTab = Lib:Tab("Player")

-- Sky Platform
local platformPosition = Vector3.new(0, 400, 0)
local function createSkyPlatform()
	local old = Workspace:FindFirstChild("SafePlatform")
	if old then old:Destroy() end
	local platform = Instance.new("Part")
	platform.Name = "SafePlatform"
	platform.Size = Vector3.new(120, 1, 120)
	platform.Anchored = true
	platform.CanCollide = true
	platform.Position = platformPosition
	platform.Parent = Workspace
	return platform
end

-- Auto Escape
local autoEscape = false
local safePlatform = nil
local escaped, lastReturnTick = false, 0
local escapeDistance, returnDistance = 21.5, 35

autoTab:Toggle("Auto Escape", function(state)
	autoEscape = state
	if state and not safePlatform then
		safePlatform = createSkyPlatform()
	end
end)

task.spawn(function()
	while task.wait(10) do
		if autoEscape then
			safePlatform = createSkyPlatform()
		end
	end
end)

task.spawn(function()
	local originalCFrame
	while task.wait(0.25) do
		if not autoEscape then continue end
		local char = LocalPlayer.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") then continue end
		if char:FindFirstChild("Revives") then continue end

		local root = char.HumanoidRootPart
		local closest = math.huge
		for _, bot in ipairs(Workspace.Game.Players:GetChildren()) do
			if bot ~= char and bot:FindFirstChild("HumanoidRootPart") then
				if ReplicatedStorage.NPCs:FindFirstChild(bot.Name) then
					local dist = (root.Position - bot.HumanoidRootPart.Position).Magnitude
					if dist < closest then
						closest = dist
					end
				end
			end
		end

		if closest < escapeDistance and not escaped then
			originalCFrame = root.CFrame
			char:PivotTo(CFrame.new(safePlatform.Position + Vector3.new(0, 5, 0)))
			escaped = true
			lastReturnTick = tick()
		elseif escaped and closest > returnDistance and (tick() - lastReturnTick) >= 5 then
			if originalCFrame then
				char:PivotTo(originalCFrame)
			end
			escaped = false
		end
	end
end)

-- ESP Utils
local function highlightPlayer(char)
	local existing = char:FindFirstChild("PlayerESP")
	if existing then existing:Destroy() end
	local hl = Instance.new("Highlight")
	hl.Name = "PlayerESP"
	hl.FillColor = Color3.fromRGB(0, 200, 255)
	hl.OutlineColor = Color3.fromRGB(255, 255, 255)
	hl.FillTransparency = 0.4
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = char
end

local function addNextbotBox(part)
	local existing = part:FindFirstChild("BotESPBox")
	if existing then existing:Destroy() end
	local box = Instance.new("BoxHandleAdornment")
	box.Name = "BotESPBox"
	box.Size = Vector3.new(4.5, 6.5, 2.5)
	box.Adornee = part
	box.AlwaysOnTop = true
	box.ZIndex = 1
	box.Color3 = Color3.fromRGB(255, 0, 0)
	box.Transparency = 0.5
	box.Parent = part
end

local playerESPEnabled, nextbotESPEnabled = false, false

visualTab:Toggle("Player ESP (Chams)", function(state)
	playerESPEnabled = state
end)

visualTab:Toggle("Nextbot ESP (Boxes)", function(state)
	nextbotESPEnabled = state
end)

task.spawn(function()
	while true do
		if playerESPEnabled then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character then
					highlightPlayer(plr.Character)
				end
			end
		end
		if nextbotESPEnabled then
			for _, ent in ipairs(Workspace.Game.Players:GetChildren()) do
				if ent:FindFirstChild("HumanoidRootPart") and ReplicatedStorage.NPCs:FindFirstChild(ent.Name) then
					addNextbotBox(ent.HumanoidRootPart)
				end
			end
		end
		task.wait(13)
	end
end)

-- Fullbright
local fullBrightOn = false
local lighting = game:GetService("Lighting")
miscTab:Toggle("Fullbright", function(state)
	fullBrightOn = state
end)

task.spawn(function()
	while task.wait(1) do
		if fullBrightOn then
			lighting.Brightness = 3
			lighting.ClockTime = 14
			lighting.FogEnd = 100000
			lighting.GlobalShadows = false
		end
	end
end)

-- FPS Boost
miscTab:Button("FPS Boost", function()
	for _, v in ipairs(game:GetDescendants()) do
		if v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end
		if v:IsA("ParticleEmitter") or v:IsA("Trail") then v:Destroy() end
	end
	lighting.FogEnd = 100000
	lighting.GlobalShadows = false
	lighting.Brightness = 2
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
end)

-- Infinite Jump
local infJump = false
playerTab:Toggle("Infinite Jump", function(state)
	infJump = state
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
	if infJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character:FindFirstChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- Anti AFK
local antiAFK = false
miscTab:Toggle("Anti AFK", function(state)
	antiAFK = state
end)

task.spawn(function()
	while task.wait(60) do
		if antiAFK then
			for _, key in ipairs({"W", "A", "S", "D"}) do
				keypress(Enum.KeyCode[key])
				wait(0.1)
				keyrelease(Enum.KeyCode[key])
			end
			mouse1click()
			mouse2click()
		end
	end
end)

-- Server Hop
miscTab:Button("Server Hop", function()
	local tp = game:GetService("TeleportService")
	local placeId = game.PlaceId
	local servers = game:GetService("HttpService"):JSONDecode(
		game:HttpGet("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100")
	)
	for _, s in pairs(servers.data) do
		if s.playing < s.maxPlayers then
			tp:TeleportToPlaceInstance(placeId, s.id, LocalPlayer)
			break
		end
	end
end)
