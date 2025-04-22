--// Services //--
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

--// Local Player & Camera //--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse() -- Needed for simulating center click

--// Configuration //--
-- Aimbot Settings
local AIMBOT_SMOOTHNESS = 50
local MAX_DISTANCE = 1000
local AIM_PART_NAME = "Head"
local REQUIRE_VISIBILITY_AIM = true

-- Highlight Settings
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(255, 0, 0)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(255, 255, 255)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.4
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0
local HIGHLIGHT_DEPTH_MODE = Enum.HighlightDepthMode.Occluded

-- Mobile Center Lock Settings
local CROSSHAIR_TEXT = "X"
local CROSSHAIR_SIZE = 30
local CROSSHAIR_COLOR = Color3.fromRGB(255, 255, 255)
local CROSSHAIR_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)
local CENTER_LOCK_RAY_DISTANCE = 500 -- How far to project the center point for Mouse.Hit

--// State //--
local aimbotEnabled = false
local highlightEnabled = false
local mobileCenterLockEnabled = false -- <<< NEW STATE
local currentTargetPlayer = nil -- Keep track of aimbot target for potential future use

local playerHighlights = {}
local highlightConnections = {}
local centerLockInputConnection = nil -- Connection for the mobile lock input

--// GUI Setup //--
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "AimbotHighlightMobileGui" -- Renamed
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 300, 0, 250) -- Adjusted height for 3 buttons
frame.Position = UDim2.new(0.5, -150, 0.5, -125) -- Centered
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Visible = true

-- Crosshair Label (for Mobile Center Lock) <<< NEW >>>
local crosshairLabel = Instance.new("TextLabel", screenGui)
crosshairLabel.Name = "CenterLockCrosshair"
crosshairLabel.Size = UDim2.new(0, CROSSHAIR_SIZE, 0, CROSSHAIR_SIZE)
crosshairLabel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Center of screen
crosshairLabel.AnchorPoint = Vector2.new(0.5, 0.5) -- Anchor at center
crosshairLabel.BackgroundTransparency = 1
crosshairLabel.Font = Enum.Font.SourceSansBold
crosshairLabel.Text = CROSSHAIR_TEXT
crosshairLabel.TextColor3 = CROSSHAIR_COLOR
crosshairLabel.TextSize = CROSSHAIR_SIZE - 4
crosshairLabel.TextScaled = false
crosshairLabel.TextStrokeColor3 = CROSSHAIR_OUTLINE_COLOR
crosshairLabel.TextStrokeTransparency = 0
crosshairLabel.Visible = false -- Initially hidden
crosshairLabel.ZIndex = 10 -- Ensure it's above most other elements

-- زر إغلاق (Close Button)
local closeBtn = Instance.new("TextButton", frame)
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 0.3, 0.3)
closeBtn.BackgroundTransparency = 1
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 20
-- Click connection at the end

-- زر Aimbot (Aimbot Toggle Button)
local aimBtn = Instance.new("TextButton", frame)
aimBtn.Name = "AimbotButton"
aimBtn.Size = UDim2.new(1, -20, 0, 40)
aimBtn.Position = UDim2.new(0, 10, 0, 45)
aimBtn.TextColor3 = Color3.new(1, 1, 1)
aimBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
aimBtn.Font = Enum.Font.SourceSans
aimBtn.TextSize = 20
aimBtn.BorderSizePixel = 0
aimBtn.Text = "Aimbot: Off"

aimBtn.MouseButton1Click:Connect(function()
	aimbotEnabled = not aimbotEnabled
	aimBtn.Text = aimbotEnabled and "Aimbot: On" or "Aimbot: Off"
	aimBtn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(150, 50, 50) or Color3.fromRGB(70, 70, 70)
    if not aimbotEnabled then
        currentTargetPlayer = nil
    end
end)

-- زر Highlight (Highlight Toggle Button)
local highlightBtn = Instance.new("TextButton", frame)
highlightBtn.Name = "HighlightButton"
highlightBtn.Size = UDim2.new(1, -20, 0, 40)
highlightBtn.Position = UDim2.new(0, 10, 0, 95)
highlightBtn.TextColor3 = Color3.new(1, 1, 1)
highlightBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
highlightBtn.Font = Enum.Font.SourceSans
highlightBtn.TextSize = 20
highlightBtn.BorderSizePixel = 0
highlightBtn.Text = "Highlight: Off"
-- Click connection at the end

-- زر Mobile Center Lock (Mobile Only) <<< NEW >>>
local mobileLockBtn = Instance.new("TextButton", frame)
mobileLockBtn.Name = "MobileCenterLockButton"
mobileLockBtn.Size = UDim2.new(1, -20, 0, 40)
mobileLockBtn.Position = UDim2.new(0, 10, 0, 145) -- Position below Highlight
mobileLockBtn.TextColor3 = Color3.new(1, 1, 1)
mobileLockBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
mobileLockBtn.Font = Enum.Font.SourceSans
mobileLockBtn.TextSize = 20
mobileLockBtn.BorderSizePixel = 0
mobileLockBtn.Text = "Center Lock: Off"
mobileLockBtn.Visible = UserInputService.TouchEnabled -- Only visible on touch devices
mobileLockBtn.Active = UserInputService.TouchEnabled -- Only interactable on touch devices
-- Click connection at the end

--// Highlight Functions (Unchanged) //--
local function applyHighlight(player) if player == LocalPlayer then return end; if not highlightEnabled then return end; local character = player.Character; if not character then if playerHighlights[player] then playerHighlights[player]:Destroy(); playerHighlights[player] = nil end; return end; local existingHighlight = playerHighlights[player]; if existingHighlight then if existingHighlight.Parent ~= character then existingHighlight.Parent = character; existingHighlight.FillColor = HIGHLIGHT_FILL_COLOR; existingHighlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR; existingHighlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY; existingHighlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY; existingHighlight.DepthMode = HIGHLIGHT_DEPTH_MODE; end; existingHighlight.Enabled = true; else local newHighlight = Instance.new("Highlight", character); newHighlight.Name = "PlayerESP_Highlight"; newHighlight.FillColor = HIGHLIGHT_FILL_COLOR; newHighlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR; newHighlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY; newHighlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY; newHighlight.DepthMode = HIGHLIGHT_DEPTH_MODE; newHighlight.Enabled = true; playerHighlights[player] = newHighlight; end end
local function removeHighlight(player, skipDestroy) if playerHighlights[player] then if skipDestroy then playerHighlights[player].Enabled = false else playerHighlights[player]:Destroy(); playerHighlights[player] = nil end end end
local function setHighlightState(enabled) highlightEnabled = enabled; highlightBtn.Text = enabled and "Highlight: On" or "Highlight: Off"; highlightBtn.BackgroundColor3 = enabled and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(70, 70, 70); if enabled then for _, player in ipairs(Players:GetPlayers()) do applyHighlight(player); if not highlightConnections[player] then highlightConnections[player] = {}; highlightConnections[player].CharacterAdded = player.CharacterAdded:Connect(function(character) task.wait(0.1); applyHighlight(player) end); highlightConnections[player].CharacterRemoving = player.CharacterRemoving:Connect(function(character) removeHighlight(player, false) end); end end; if not highlightConnections.PlayerAdded then highlightConnections.PlayerAdded = Players.PlayerAdded:Connect(function(player) applyHighlight(player); if not highlightConnections[player] then highlightConnections[player] = {}; highlightConnections[player].CharacterAdded = player.CharacterAdded:Connect(function(character) task.wait(0.1); applyHighlight(player) end); highlightConnections[player].CharacterRemoving = player.CharacterRemoving:Connect(function(character) removeHighlight(player, false) end); end end) end; if not highlightConnections.PlayerRemoving then highlightConnections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player) removeHighlight(player, false); if highlightConnections[player] then if highlightConnections[player].CharacterAdded then highlightConnections[player].CharacterAdded:Disconnect() end; if highlightConnections[player].CharacterRemoving then highlightConnections[player].CharacterRemoving:Disconnect() end; highlightConnections[player] = nil end end) end; else for player, highlight in pairs(playerHighlights) do removeHighlight(player, true) end; if highlightConnections.PlayerAdded then highlightConnections.PlayerAdded:Disconnect(); highlightConnections.PlayerAdded = nil end; if highlightConnections.PlayerRemoving then highlightConnections.PlayerRemoving:Disconnect(); highlightConnections.PlayerRemoving = nil end; for player, conns in pairs(highlightConnections) do if typeof(conns) == "table" then if conns.CharacterAdded then conns.CharacterAdded:Disconnect() end; if conns.CharacterRemoving then conns.CharacterRemoving:Disconnect() end; end end; for k, v in pairs(highlightConnections) do if typeof(v) == "table" then highlightConnections[k] = nil end end end end

--// Mobile Center Lock Functions <<< NEW >>> //--

-- Handles touch input when center lock is active
local function centerLockInputHandler(input, gameProcessedEvent)
	if not mobileCenterLockEnabled then return end -- Should not happen if connection is managed properly, but safety check

	-- Check if it's a touch tap and not already handled by GUI
	if input.UserInputType == Enum.UserInputType.TouchTap and not gameProcessedEvent then
		-- Calculate the center of the viewport
		local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

		-- Create a ray from the camera center
		local unitRay = Camera:ViewportPointToRay(viewportCenter.X, viewportCenter.Y)

		-- Find the point in 3D space where the center ray hits (or projects to)
        -- We'll set Mouse.Hit to this position
		local targetPosition = unitRay.Origin + unitRay.Direction * CENTER_LOCK_RAY_DISTANCE

        -- Optional: Perform a short raycast to find the actual hit point if needed
        -- local raycastParams = RaycastParams.new()
        -- raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        -- raycastParams.FilterDescendantsInstances = {LocalPlayer.Character} -- Ignore self
        -- local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * CENTER_LOCK_RAY_DISTANCE, raycastParams)
        -- if raycastResult then
        --     targetPosition = raycastResult.Position
        -- else
        --     targetPosition = unitRay.Origin + unitRay.Direction * CENTER_LOCK_RAY_DISTANCE
        -- end

		-- *** Simulate the click originating from the center ***
        -- By setting Mouse.Hit.p, scripts checking the mouse position shortly after
        -- the touch input may read this centered position instead of the actual touch location.
        -- This is the closest we can get to Shift Lock behavior in a LocalScript.
		Mouse.Hit.p = targetPosition -- Update the CFrame position component

        -- Print for debugging / confirmation
		-- print(string.format("Center Lock: Touch detected. Simulating click at world position: %s", tostring(targetPosition)))

        -- We don't explicitly "sink" the input here, but by modifying Mouse.Hit,
        -- we influence how subsequent game logic might interpret the input.
	end
end

-- Manages the state and event connection for Mobile Center Lock
local function setMobileCenterLockState(enabled)
    if not UserInputService.TouchEnabled then return end -- Extra safety check

    mobileCenterLockEnabled = enabled

    -- Update button appearance
    mobileLockBtn.Text = enabled and "Center Lock: On" or "Center Lock: Off"
    mobileLockBtn.BackgroundColor3 = enabled and Color3.fromRGB(50, 100, 150) or Color3.fromRGB(70, 70, 70) -- Blue when active

    -- Show/hide crosshair
    crosshairLabel.Visible = enabled

    -- Connect/disconnect the input listener
    if enabled then
        if not centerLockInputConnection then
            centerLockInputConnection = UserInputService.InputBegan:Connect(centerLockInputHandler)
        end
    else
        if centerLockInputConnection then
            centerLockInputConnection:Disconnect()
            centerLockInputConnection = nil
        end
    end
end


--// Aimbot Functions (Unchanged, returns player object) //--
local function getClosestTarget() local closestTargetPart = nil; local closestTargetPlayer = nil; local minDistance = MAX_DISTANCE; local localCharacter = LocalPlayer.Character; if not localCharacter then return nil, nil end; local localRootPart = localCharacter:FindFirstChild("HumanoidRootPart"); if not localRootPart then return nil, nil end; local localRootPos = localRootPart.Position; local raycastParams = RaycastParams.new(); raycastParams.FilterType = Enum.RaycastFilterType.Blacklist; raycastParams.FilterDescendantsInstances = {localCharacter}; raycastParams.IgnoreWater = true; for _, player in ipairs(Players:GetPlayers()) do if player ~= LocalPlayer then local targetCharacter = player.Character; local targetPart = targetCharacter and targetCharacter:FindFirstChild(AIM_PART_NAME); local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid"); local targetRootPart = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart"); if targetPart and targetHumanoid and targetHumanoid.Health > 0 and targetRootPart then local targetPos = targetPart.Position; local targetDistPos = targetRootPart.Position; local distance = (targetDistPos - localRootPos).Magnitude; if distance < minDistance then local isVisible = true; if REQUIRE_VISIBILITY_AIM then local camPos = Camera.CFrame.Position; local direction = (targetPos - camPos); local rayDist = math.max(0, distance - 0.5); local raycastResult = workspace:Raycast(camPos, direction.Unit * rayDist, raycastParams); isVisible = (not raycastResult) or (raycastResult.Instance:IsDescendantOf(targetCharacter)) end; if isVisible then minDistance = distance; closestTargetPart = targetPart; closestTargetPlayer = player; end end end end end; return closestTargetPart, closestTargetPlayer end

--// Core Loops / Event Connections //--

-- Aimbot Loop (Unchanged)
local aimbotConnection = RunService.RenderStepped:Connect(function(deltaTime)
	if aimbotEnabled then
        local localCharacter = LocalPlayer.Character
        local localHead = localCharacter and localCharacter:FindFirstChild("Head")
        if localCharacter and localHead then
            local targetPart, targetPlayer = getClosestTarget()
            currentTargetPlayer = targetPlayer
            if targetPart then
                local targetCFrame = CFrame.new(localHead.Position, targetPart.Position)
                local smoothingFactor = 1 - math.exp(-AIMBOT_SMOOTHNESS * deltaTime)
                smoothingFactor = math.clamp(smoothingFactor, 0, 1)
                local newCFrame = Camera.CFrame:Lerp(targetCFrame, smoothingFactor)
                Camera.CFrame = newCFrame
            end
        else
            currentTargetPlayer = nil
        end
	else
         currentTargetPlayer = nil
    end
end)

-- ربط وظيفة النقر بزر Highlight
highlightBtn.MouseButton1Click:Connect(function()
	setHighlightState(not highlightEnabled)
end)

-- ربط وظيفة النقر بزر Mobile Center Lock (فقط إذا كان مرئيًا/مفعلًا)
if UserInputService.TouchEnabled then
    mobileLockBtn.MouseButton1Click:Connect(function()
        setMobileCenterLockState(not mobileCenterLockEnabled) -- Toggle the state
    end)
end

-- وظيفة التنظيف
local function cleanup()
	print("Cleaning up GUI script resources...")
	-- إيقاف Aimbot
	if aimbotConnection then
		aimbotConnection:Disconnect()
		aimbotConnection = nil
	end
    aimbotEnabled = false
    currentTargetPlayer = nil

	-- تعطيل وتنظيف Highlights
	setHighlightState(false) -- Disable first to disconnect listeners
	for player, highlight in pairs(playerHighlights) do
		removeHighlight(player, false) -- Destroy instances
	end
	playerHighlights = {}
    -- Clear highlight connections table
    highlightConnections = {} -- Already cleared inside setHighlightState(false)

    -- إيقاف وتنظيف Mobile Center Lock <<< NEW >>>
    if UserInputService.TouchEnabled then
        setMobileCenterLockState(false) -- Disable and disconnect listener
    end
    if crosshairLabel and crosshairLabel.Parent then -- Hide crosshair just in case
        crosshairLabel.Visible = false
    end

	print("Cleanup complete.")
end

-- ربط وظيفة النقر بزر الإغلاق
closeBtn.MouseButton1Click:Connect(function()
	cleanup()
	if screenGui and screenGui.Parent then
		 screenGui:Destroy()
	end
end)

-- ربط حدث تدمير الواجهة الرسومية بوظيفة التنظيف
screenGui.Destroying:Connect(cleanup)

print("Aimbot/Highlight/Mobile GUI Loaded.")
if UserInputService.TouchEnabled then
    print("Mobile device detected. Center Lock option enabled.")
end
