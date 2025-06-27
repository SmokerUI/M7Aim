--[[
    s.ick Aimbot & Utilities
    Credits: s.ick2 (tiktok)
    Enhanced and modularized for stability and features.
    -- FIXED by providing the corrected script --
]]

--// Services //--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Local Player & Camera //--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

--// GUI Singleton Check: Prevent multiple GUIs from running //--
if PlayerGui:FindFirstChild("s_ick_AimbotGUI") then
	print("s.ick Aimbot: GUI already exists. Halting execution of new script.")
	return
end

--// Configuration //--
-- Aimbot Default Settings
local AIMBOT_SMOOTHNESS = 50
local MAX_DISTANCE = 500
local AIMBOT_FOV = 150
local AIM_PART_NAME = "Head"
local REQUIRE_VISIBILITY_AIM = true

-- Highlight Settings
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 50, 50)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.6
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0
local HIGHLIGHT_DEPTH_MODE = Enum.HighlightDepthMode.Occluded

-- Hitbox Expander Settings
local HITBOX_EXPANSION_SIZE = 0.5 -- Additional size in studs on each axis
local HITBOX_PARTS_TO_EXPAND = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart"}

--// State //--
local aimbotEnabled = false
local highlightEnabled = false
local hitboxExpanderEnabled = false
local guiMinimized = false

local playerHighlights = {}
local playerHitboxParts = {} -- Stores created hitbox parts for cleanup
local playerConnections = {} -- Centralized connections per player
local playerAddedConnection, playerRemovingConnection -- <<-- [FIX] Variables to hold the main connections

--// Main GUI Creation //--
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "s_ick_AimbotGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = false -- Start disabled until loading is done

--// Loading Screen //--
local loadingGui = Instance.new("ScreenGui", PlayerGui)
loadingGui.Name = "s_ick_LoadingGUI"
loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local loadingBg = Instance.new("Frame", loadingGui)
loadingBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
loadingBg.Size = UDim2.new(1, 0, 1, 0)

local loadingFrame = Instance.new("Frame", loadingBg)
loadingFrame.Size = UDim2.new(0, 300, 0, 100)
loadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
loadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
loadingFrame.BackgroundTransparency = 1

local loadingTitle = Instance.new("TextLabel", loadingFrame)
loadingTitle.Text = "s.ick"
loadingTitle.Font = Enum.Font.GothamBlack
loadingTitle.TextColor3 = Color3.new(1, 1, 1)
loadingTitle.TextSize = 40
loadingTitle.Size = UDim2.new(1, 0, 0, 40)
loadingTitle.BackgroundTransparency = 1

local loadingSubtitle = Instance.new("TextLabel", loadingFrame)
loadingSubtitle.Text = "Loading Utilities..."
loadingSubtitle.Font = Enum.Font.SourceSans
loadingSubtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
loadingSubtitle.TextSize = 16
loadingSubtitle.Size = UDim2.new(1, 0, 0, 20)
loadingSubtitle.Position = UDim2.new(0, 0, 0, 45)
loadingSubtitle.BackgroundTransparency = 1

local progressBarBg = Instance.new("Frame", loadingFrame)
progressBarBg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
progressBarBg.BorderSizePixel = 0
progressBarBg.Size = UDim2.new(1, 0, 0, 8)
progressBarBg.Position = UDim2.new(0, 0, 0, 75)
local barBgCorner = Instance.new("UICorner", progressBarBg)
barBgCorner.CornerRadius = UDim.new(1, 0)

local progressBarFill = Instance.new("Frame", progressBarBg)
progressBarFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
progressBarFill.BorderSizePixel = 0
progressBarFill.Size = UDim2.new(0, 0, 1, 0) -- Starts at 0 width
local barFillCorner = Instance.new("UICorner", progressBarFill)
barFillCorner.CornerRadius = UDim.new(1, 0)


--// Main UI Structure (build it while loading screen is up) //--
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 300, 0, 470) -- Increased height for new option
mainFrame.Position = UDim2.new(0.05, 0, 0.5, -235)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(55, 55, 65)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
local frameCorner = Instance.new("UICorner", mainFrame)
frameCorner.CornerRadius = UDim.new(0, 8)

-- Header
local header = Instance.new("Frame", mainFrame)
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
header.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Text = "s.ick Aimbot" -- UPDATED TITLE
titleLabel.Font = Enum.Font.GothamSemibold
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 18
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Size = UDim2.new(0, 200, 1, 0)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local headerAccent = Instance.new("Frame", header)
headerAccent.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
headerAccent.BorderSizePixel = 0
headerAccent.Size = UDim2.new(1, 0, 0, 2)
headerAccent.Position = UDim2.new(0, 0, 1, -2)

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Name = "MinimizeButton"
minimizeBtn.Size = UDim2.new(0, 25, 0, 25)
minimizeBtn.Position = UDim2.new(1, -65, 0.5, -12.5)
minimizeBtn.Text = "_"
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 20
minimizeBtn.TextColor3 = Color3.new(1, 1, 1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
local minimizeCorner = Instance.new("UICorner", minimizeBtn)
minimizeCorner.CornerRadius = UDim.new(0, 4)

local closeBtn = Instance.new("TextButton", header)
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -35, 0.5, -12.5)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0, 4)

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, 0, 1, -40)
contentFrame.Position = UDim2.new(0, 0, 0, 40)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true

local creditsLabel = Instance.new("TextLabel", contentFrame)
creditsLabel.Name = "Credits"
creditsLabel.Size = UDim2.new(1, -20, 0, 20)
creditsLabel.Position = UDim2.new(0, 10, 1, -25)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Font = Enum.Font.SourceSans
creditsLabel.Text = "Credits: s.ick2 (tiktok)"
creditsLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
creditsLabel.TextSize = 14
creditsLabel.TextXAlignment = Enum.TextXAlignment.Right

local fovCircle = Instance.new("Frame", screenGui)
fovCircle.Name = "FOVCircle"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
fovCircle.Size = UDim2.new(0, AIMBOT_FOV * 2, 0, AIMBOT_FOV * 2)
fovCircle.BackgroundTransparency = 0.9
fovCircle.BorderMode = Enum.BorderMode.Outline
fovCircle.BorderSizePixel = 1
fovCircle.BorderColor3 = Color3.fromRGB(255, 255, 255)
fovCircle.Visible = false
local fovUICorner = Instance.new("UICorner", fovCircle)
fovUICorner.CornerRadius = UDim.new(1, 0)

--// UI Helper Functions //--
local function createToggleButton(parent, name, text, position)
	local btn = Instance.new("TextButton", parent)
	btn.Name = name
	btn.Size = UDim2.new(1, -20, 0, 35)
	btn.Position = position
	btn.Font = Enum.Font.SourceSansSemibold
	btn.TextSize = 18
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	btn.Text = text
	local btnCorner = Instance.new("UICorner", btn)
	btnCorner.CornerRadius = UDim.new(0, 6)
	return btn
end

local function createSlider(parent, name, minVal, maxVal, defaultVal, position, callback)
	local container = Instance.new("Frame", parent)
	container.Name = name .. "SliderContainer"
	container.Size = UDim2.new(1, -20, 0, 50)
	container.Position = position
	container.BackgroundTransparency = 1

	local label = Instance.new("TextLabel", container)
	label.Size = UDim2.new(0.5, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 14
	label.TextXAlignment = Enum.TextXAlignment.Left

	local valueLabel = Instance.new("TextLabel", container)
	valueLabel.Size = UDim2.new(0.5, -5, 0, 20)
    valueLabel.Position = UDim2.new(0.5, 5, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.SourceSans
	valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local track = Instance.new("Frame", container)
	track.Size = UDim2.new(1, 0, 0, 8)
	track.Position = UDim2.new(0, 0, 0, 25)
	track.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	local trackCorner = Instance.new("UICorner", track)
	trackCorner.CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", track)
	fill.BackgroundColor3 = Color3.fromRGB(220, 70, 70) -- Red accent
	local fillCorner = Instance.new("UICorner", fill)
	fillCorner.CornerRadius = UDim.new(1, 0)

	local handle = Instance.new("TextButton", track)
	handle.Size = UDim2.new(0, 16, 0, 16)
	handle.AnchorPoint = Vector2.new(0.5, 0.5)
	handle.Position = UDim2.new(0, 0, 0.5, 0)
	handle.BackgroundColor3 = Color3.new(1, 1, 1)
	handle.Text = ""
    handle.ZIndex = 2
	local handleCorner = Instance.new("UICorner", handle)
	handleCorner.CornerRadius = UDim.new(1, 0)
    local handleStroke = Instance.new("UIStroke", handle)
    handleStroke.Color = Color3.fromRGB(80, 80, 90)
    handleStroke.Thickness = 1

	local function updateSlider(percent)
		percent = math.clamp(percent, 0, 1)
		handle.Position = UDim2.new(percent, 0, 0.5, 0)
		fill.Size = UDim2.new(percent, 0, 1, 0)
		local value = minVal + (maxVal - minVal) * percent
		label.Text = name
		valueLabel.Text = string.format("%.1f", value)
		if callback then callback(value) end
	end
	
	updateSlider((defaultVal - minVal) / (maxVal - minVal))

	handle.MouseButton1Down:Connect(function()
		local mouseMoveConn, mouseUpConn
		mouseMoveConn = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local mousePos = UserInputService:GetMouseLocation()
				local trackStartPos = track.AbsolutePosition.X
				local trackWidth = track.AbsoluteSize.X
				local percent = math.clamp((mousePos.X - trackStartPos) / trackWidth, 0, 1)
				updateSlider(percent)
			end
		end)
		mouseUpConn = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				mouseMoveConn:Disconnect()
				mouseUpConn:Disconnect()
			end
		end)
	end)

	return container
end


--// UI Element Creation & Connections //--
local currentY = 10

-- Toggles
local aimBtn = createToggleButton(contentFrame, "AimbotButton", "Aimbot: Off", UDim2.new(0, 10, 0, currentY))
currentY = currentY + 45
local highlightBtn = createToggleButton(contentFrame, "HighlightButton", "Highlight: Off", UDim2.new(0, 10, 0, currentY))
currentY = currentY + 45
local hitboxBtn = createToggleButton(contentFrame, "HitboxButton", "Hitbox Expander: Off", UDim2.new(0, 10, 0, currentY)) -- NEW
currentY = currentY + 55

-- Sliders
local fovSlider = createSlider(contentFrame, "FOV", 10, 500, AIMBOT_FOV, UDim2.new(0, 10, 0, currentY), function(val)
	AIMBOT_FOV = val; fovCircle.Size = UDim2.new(0, AIMBOT_FOV * 2, 0, AIMBOT_FOV * 2)
end)
currentY = currentY + 50
local smoothnessSlider = createSlider(contentFrame, "Smoothness", 1, 100, AIMBOT_SMOOTHNESS, UDim2.new(0, 10, 0, currentY), function(val)
	AIMBOT_SMOOTHNESS = val
end)
currentY = currentY + 50
local distanceSlider = createSlider(contentFrame, "Distance", 50, 2000, MAX_DISTANCE, UDim2.new(0, 10, 0, currentY), function(val)
	MAX_DISTANCE = val
end)
currentY = currentY + 50
local hitboxSizeSlider = createSlider(contentFrame, "Hitbox Size", 0.1, 5, HITBOX_EXPANSION_SIZE, UDim2.new(0, 10, 0, currentY), function(val) -- NEW
	HITBOX_EXPANSION_SIZE = val
    if hitboxExpanderEnabled then -- Re-apply to all players with new size
        for player, _ in pairs(playerConnections) do
            if player ~= LocalPlayer then
                removeHitboxExpansion(player)
                applyHitboxExpansion(player)
            end
        end
    end
end)


--// Core Feature Functions //--

-- Hitbox Expander Functions
function removeHitboxExpansion(player)
	if playerHitboxParts[player] then
		for _, part in ipairs(playerHitboxParts[player]) do
			part:Destroy()
		end
		playerHitboxParts[player] = nil
	end
end

function applyHitboxExpansion(player)
	if not hitboxExpanderEnabled or player == LocalPlayer then return end
	removeHitboxExpansion(player) -- Clear old ones first
	
	local character = player.Character
	if not character then return end
	
	playerHitboxParts[player] = {}
	
	for _, partName in ipairs(HITBOX_PARTS_TO_EXPAND) do
		local originalPart = character:FindFirstChild(partName)
		if originalPart and originalPart:IsA("BasePart") then
			local expander = Instance.new("Part")
			expander.Name = "s_ick_HitboxExpander"
			expander.Size = originalPart.Size + Vector3.new(HITBOX_EXPANSION_SIZE, HITBOX_EXPANSION_SIZE, HITBOX_EXPANSION_SIZE)
			expander.CanCollide = false
			expander.CanTouch = false
			expander.CanQuery = true -- Important for raycasting
			expander.Transparency = 1
			expander.Anchored = false
			expander.Parent = character
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = expander
			weld.Part1 = originalPart
			weld.Parent = expander
			
			table.insert(playerHitboxParts[player], expander)
		end
	end
end

function setHitboxExpanderState(enabled)
	hitboxExpanderEnabled = enabled
	hitboxBtn.Text = enabled and "Hitbox Expander: On" or "Hitbox Expander: Off"
	hitboxBtn.BackgroundColor3 = enabled and Color3.fromRGB(220, 70, 70) or Color3.fromRGB(70, 70, 80)
	
	for player, _ in pairs(playerConnections) do
		if enabled then
			applyHitboxExpansion(player)
		else
			removeHitboxExpansion(player)
		end
	end
end

-- Highlight Functions
function removeHighlight(player) if playerHighlights[player] then playerHighlights[player]:Destroy(); playerHighlights[player] = nil end end
function applyHighlight(player) if not highlightEnabled or player == LocalPlayer then return end; removeHighlight(player); local character = player.Character; if character then local h = Instance.new("Highlight", character); h.FillColor = HIGHLIGHT_FILL_COLOR; h.OutlineColor = HIGHLIGHT_OUTLINE_COLOR; h.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY; h.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY; h.DepthMode = HIGHLIGHT_DEPTH_MODE; playerHighlights[player] = h end end
function setHighlightState(enabled) highlightEnabled = enabled; highlightBtn.Text = enabled and "Highlight: On" or "Highlight: Off"; highlightBtn.BackgroundColor3 = enabled and Color3.fromRGB(220, 70, 70) or Color3.fromRGB(70, 70, 80); for player, _ in pairs(playerConnections) do if enabled then applyHighlight(player) else removeHighlight(player) end end end

-- Player State Management
function onPlayerAdded(player)
	playerConnections[player] = {}
	playerConnections[player].CharacterAdded = player.CharacterAdded:Connect(function(character)
		task.wait(0.1) -- Wait for character to fully load
		applyHighlight(player)
		applyHitboxExpansion(player)
	end)
	
	if player.Character then
		applyHighlight(player)
		applyHitboxExpansion(player)
	end
end

function onPlayerRemoving(player)
	removeHighlight(player)
	removeHitboxExpansion(player)
	
	if playerConnections[player] then
		for _, conn in pairs(playerConnections[player]) do
			conn:Disconnect()
		end
		playerConnections[player] = nil
	end
end

-- Aimbot Function
function getClosestTarget()
	local closestTargetPart, minScreenDist = nil, AIMBOT_FOV
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
	raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
	
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for player, _ in pairs(playerConnections) do
        if player == LocalPlayer then continue end
		local char = player.Character
		local targetPart = char and char:FindFirstChild(AIM_PART_NAME)
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if targetPart and hum and hum.Health > 0 then
			local distance = (char.PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
			if distance < MAX_DISTANCE then
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
					if screenDist < minScreenDist then
						local isVisible = true
						if REQUIRE_VISIBILITY_AIM then
							local rayResult = workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * distance, raycastParams)
							isVisible = (not rayResult) or (rayResult.Instance:IsDescendantOf(char))
						end
						if isVisible then minScreenDist = screenDist; closestTargetPart = targetPart end
					end
				end
			end
		end
	end
	return closestTargetPart
end


--// Event Connections & Loops //--

aimBtn.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimBtn.Text = aimbotEnabled and "Aimbot: On" or "Aimbot: Off"
	aimBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(220, 70, 70) or Color3.fromRGB(70, 70, 80)
    fovCircle.Visible = aimbotEnabled
end)
highlightBtn.MouseButton1Click:Connect(function() setHighlightState(not highlightEnabled) end)
hitboxBtn.MouseButton1Click:Connect(function() setHitboxExpanderState(not hitboxExpanderEnabled) end)

RunService.RenderStepped:Connect(function(deltaTime)
	if aimbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") then
		local targetPart = getClosestTarget()
		if targetPart then
			local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
			local smoothingFactor = 1 - math.exp(-AIMBOT_SMOOTHNESS * deltaTime)
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, smoothingFactor)
		end
	end
end)

--// Finalization and Cleanup //--

function toggleGuiVisibility(minimized)
	guiMinimized = minimized
	local targetSize = minimized and UDim2.new(0, 300, 0, 40) or UDim2.new(0, 300, 0, 470)
	local contentTransparency = minimized and 1 or 0
    minimizeBtn.Text = minimized and "O" or "_"

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(mainFrame, tweenInfo, {Size = targetSize}):Play()
	
    -- <<-- [FIX] Correctly tween transparency of children elements
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("GuiObject") then
            -- This will tween the background
            TweenService:Create(child, tweenInfo, {BackgroundTransparency = contentTransparency}):Play()
            -- For elements with text, also tween the text
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				TweenService:Create(child, tweenInfo, {TextTransparency = contentTransparency}):Play()
			end
            -- Also fade the children of the sliders (text, handles etc)
            for _, descendant in ipairs(child:GetDescendants()) do
                if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                    TweenService:Create(descendant, tweenInfo, {TextTransparency = contentTransparency, BackgroundTransparency = contentTransparency}):Play()
                elseif descendant:IsA("Frame") then
                     TweenService:Create(descendant, tweenInfo, {BackgroundTransparency = contentTransparency}):Play()
                end
            end
		end
	end
end
minimizeBtn.MouseButton1Click:Connect(function() toggleGuiVisibility(not guiMinimized) end)

function cleanup()
    -- <<-- [FIX] Disconnect the stored connections correctly
	if playerAddedConnection then
		playerAddedConnection:Disconnect()
		playerAddedConnection = nil
	end
	if playerRemovingConnection then
		playerRemovingConnection:Disconnect()
		playerRemovingConnection = nil
	end

	for player, _ in pairs(Players:GetPlayers()) do onPlayerRemoving(player) end
    playerConnections = {}
	if screenGui then screenGui:Destroy() end
end
closeBtn.MouseButton1Click:Connect(cleanup)
screenGui.Destroying:Connect(cleanup)


--// Start Execution //--

-- Initial Player Scan
-- <<-- [FIX] Store the connections in the variables
playerAddedConnection = Players.PlayerAdded:Connect(onPlayerAdded)
playerRemovingConnection = Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
	    onPlayerAdded(player)
    end
end

-- Loading Animation
task.wait(0.5) -- Small delay for effect
local loadingTween = TweenService:Create(progressBarFill, TweenInfo.new(1.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0)})
loadingTween:Play()
loadingTween.Completed:Wait()
task.wait(0.3)

-- Transition
local fadeOutTween = TweenService:Create(loadingBg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
fadeOutTween:Play()
screenGui.Enabled = true
fadeOutTween.Completed:Connect(function()
	loadingGui:Destroy()
end)

print("s.ick Aimbot: Loaded successfully.")
