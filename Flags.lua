--[[
    Script: Universal FE GUI (Chat Sender + Flag Game) v2
    Description: A more robust, multi-tab GUI designed for maximum compatibility across Roblox experiences.
    - Tab 1: Send custom messages in chat.
    - Tab 2: Host a "Guess the Flag" game in Arabic.
    - Fully FE compatible and works with both new (TextChatService) and legacy chat systems.
    - Features enhanced error handling and a more efficient event-driven game loop.

    How to use:
    1. Copy this entire script.
    2. Open your script executor in a Roblox game.
    3. Paste the script and execute it.
    4. A GUI will appear. Use the tabs to switch between functions.
]]

local function CreateUniversalGui()
    
    -- // Services & Checks (wrapped for safety)
    local Players, UserInputService, TextChatService, ReplicatedStorage, CoreGui
    local servicesAvailable = pcall(function()
        Players = game:GetService("Players")
        UserInputService = game:GetService("UserInputService")
        TextChatService = game:GetService("TextChatService")
        ReplicatedStorage = game:GetService("ReplicatedStorage")
        CoreGui = game:GetService("CoreGui")
    end)
    
    if not servicesAvailable then
        warn("Universal GUI: Could not get essential services. The script may not function correctly.")
        return
    end

    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        warn("Universal GUI: Could not find LocalPlayer.")
        return
    end

    -- // Configuration
    local guiName = "UniversalGUI_" .. tostring(math.random(1000, 9999))
    
    -- // Smart GUI Parent determination
    local function getGuiParent()
        local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
        if success and coreGui then
            if coreGui:FindFirstChild(guiName) then coreGui[guiName]:Destroy() end
            return coreGui
        end
        -- Fallback for environments where CoreGui is not directly accessible
        warn("Universal GUI: Could not access CoreGui, falling back to PlayerGui. GUI may be removed on respawn.")
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if playerGui:FindFirstChild(guiName) then playerGui[guiName]:Destroy() end
        return playerGui
    end
    
    local guiParent = getGuiParent()
    if not guiParent then
        warn("Universal GUI: Could not find a suitable parent for the GUI. Aborting.")
        return
    end

    -- // Flag Game Data (in Arabic & English for wider matching)
    local flagsData = {
        { flag = "ðŸ‡¸ðŸ‡¦", answers = { "Ø§Ù„Ø³Ø¹ÙˆØ¯ÙŠØ©", "Ø§Ù„Ù…Ù…Ù„ÙƒØ© Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© Ø§Ù„Ø³Ø¹ÙˆØ¯ÙŠØ©", "saudi arabia", "ksa" } },
        { flag = "ðŸ‡ªðŸ‡¬", answers = { "Ù…ØµØ±", "Ø¬Ù…Ù‡ÙˆØ±ÙŠØ© Ù…ØµØ± Ø§Ù„Ø¹Ø±Ø¨ÙŠØ©", "egypt" } },
        { flag = "ðŸ‡¦ðŸ‡ª", answers = { "Ø§Ù„Ø§Ù…Ø§Ø±Ø§Øª", "Ø§Ù„Ø¥Ù…Ø§Ø±Ø§Øª Ø§Ù„Ø¹Ø±Ø¨ÙŠØ© Ø§Ù„Ù…ØªØ­Ø¯Ø©", "uae", "united arab emirates" } },
        { flag = "ðŸ‡¯ðŸ‡´", answers = { "Ø§Ù„Ø§Ø±Ø¯Ù†", "Ø§Ù„Ø£Ø±Ø¯Ù†", "jordan" } },
        { flag = "ðŸ‡µðŸ‡¸", answers = { "ÙÙ„Ø³Ø·ÙŠÙ†", "palestine" } },
        { flag = "ðŸ‡®ðŸ‡¶", answers = { "Ø§Ù„Ø¹Ø±Ø§Ù‚", "iraq" } },
        { flag = "ðŸ‡¸ðŸ‡¾", answers = { "Ø³ÙˆØ±ÙŠØ§", "Ø³ÙˆØ±ÙŠØ©", "syria" } },
        { flag = "ðŸ‡±ðŸ‡§", answers = { "Ù„Ø¨Ù†Ø§Ù†", "lebanon" } },
        { flag = "ðŸ‡°ðŸ‡¼", answers = { "Ø§Ù„ÙƒÙˆÙŠØª", "kuwait" } },
        { flag = "ðŸ‡¶ðŸ‡¦", answers = { "Ù‚Ø·Ø±", "qatar" } },
        { flag = "ðŸ‡§ðŸ‡­", answers = { "Ø§Ù„Ø¨Ø­Ø±ÙŠÙ†", "bahrain" } },
        { flag = "ðŸ‡´ðŸ‡²", answers = { "Ø¹Ù…Ø§Ù†", "Ø³Ù„Ø·Ù†Ø© Ø¹Ù…Ø§Ù†", "oman" } },
        { flag = "ðŸ‡¾ðŸ‡ª", answers = { "Ø§Ù„ÙŠÙ…Ù†", "yemen" } },
        { flag = "ðŸ‡©ðŸ‡¿", answers = { "Ø§Ù„Ø¬Ø²Ø§Ø¦Ø±", "algeria" } },
        { flag = "ðŸ‡²ðŸ‡¦", answers = { "Ø§Ù„Ù…ØºØ±Ø¨", "morocco" } },
        { flag = "ðŸ‡¹ðŸ‡³", answers = { "ØªÙˆÙ†Ø³", "tunisia" } },
        { flag = "ðŸ‡±ðŸ‡¾", answers = { "Ù„ÙŠØ¨ÙŠØ§", "libya" } },
        { flag = "ðŸ‡¸ðŸ‡©", answers = { "Ø§Ù„Ø³ÙˆØ¯Ø§Ù†", "sudan" } },
        { flag = "ðŸ‡¹ðŸ‡·", answers = { "ØªØ±ÙƒÙŠØ§", "turkey" } },
        { flag = "ðŸ‡ºðŸ‡¸", answers = { "Ø§Ù…Ø±ÙŠÙƒØ§", "Ø§Ù„ÙˆÙ„Ø§ÙŠØ§Øª Ø§Ù„Ù…ØªØ­Ø¯Ø©", "usa", "america" } },
        { flag = "ðŸ‡¬ðŸ‡§", answers = { "Ø¨Ø±ÙŠØ·Ø§Ù†ÙŠØ§", "Ø§Ù„Ù…Ù…Ù„ÙƒØ© Ø§Ù„Ù…ØªØ­Ø¯Ø©", "uk", "britain" } },
        { flag = "ðŸ‡«ðŸ‡·", answers = { "ÙØ±Ù†Ø³Ø§", "france" } },
        { flag = "ðŸ‡©ðŸ‡ª", answers = { "Ø§Ù„Ù…Ø§Ù†ÙŠØ§", "Ø£Ù„Ù…Ø§Ù†ÙŠØ§", "germany" } },
        { flag = "ðŸ‡®ðŸ‡¹", answers = { "Ø§ÙŠØ·Ø§Ù„ÙŠØ§", "Ø¥ÙŠØ·Ø§Ù„ÙŠØ§", "italy" } },
        { flag = "ðŸ‡ªðŸ‡¸", answers = { "Ø§Ø³Ø¨Ø§Ù†ÙŠØ§", "Ø¥Ø³Ø¨Ø§Ù†ÙŠØ§", "spain" } },
        { flag = "ðŸ‡·ðŸ‡º", answers = { "Ø±ÙˆØ³ÙŠØ§", "russia" } },
        { flag = "ðŸ‡¨ðŸ‡³", answers = { "Ø§Ù„ØµÙŠÙ†", "china" } },
        { flag = "ðŸ‡¯ðŸ‡µ", answers = { "Ø§Ù„ÙŠØ§Ø¨Ø§Ù†", "japan" } },
        { flag = "ðŸ‡§ðŸ‡·", answers = { "Ø§Ù„Ø¨Ø±Ø§Ø²ÙŠÙ„", "brazil" } },
        { flag = "ðŸ‡¦ðŸ‡·", answers = { "Ø§Ù„Ø§Ø±Ø¬Ù†ØªÙŠÙ†", "Ø§Ù„Ø£Ø±Ø¬Ù†ØªÙŠÙ†", "argentina" } }
    }

    -- // Game State Variables
    local gameRunning = false
    local currentFlagData = nil
    local timePerRound = 15 -- seconds
    local roundGuessedEvent = Instance.new("BindableEvent")

    ---------------------------------------------------------------------
    -- // CORE FUNCTIONS (CHAT SENDING & RECEIVING)
    ---------------------------------------------------------------------

    local function sendMessage(message)
        if not message or message:gsub("%s", "") == "" then return end
        
        local isNewChat = (TextChatService.ChatVersion == Enum.ChatVersion.TextChatService)
        
        if isNewChat then
            pcall(function()
                local generalChannel = TextChatService:FindFirstChild("TextChannels") and TextChatService.TextChannels:FindFirstChild("RBXGeneral")
                if generalChannel then
                    generalChannel:SendAsync(message)
                else
                    warn("Universal GUI: Could not find RBXGeneral channel in TextChatService.")
                end
            end)
        else
            -- Legacy Chat: This is the most common remote event. Wrap in pcall for safety.
            local success, err = pcall(function()
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
            end)
            if not success then
                warn("Universal GUI: Could not send message via standard legacy chat event. This game may use a custom chat system.")
            end
        end
    end
    
    local function onMessageReceived(player, message)
        if not gameRunning or not currentFlagData or player == LocalPlayer then return end

        local guess = message:lower():gsub("^%s*(.-)%s*$", "%1")

        for _, answer in ipairs(currentFlagData.answers) do
            if guess == answer:lower() then
                local flagEmoji = currentFlagData.flag
                local mainAnswer = currentFlagData.answers[1]
                
                sendMessage(`Ø§Ù„Ù„Ø§Ø¹Ø¨ {player.Name} Ø®Ù…Ù† Ø¨Ø´ÙƒÙ„ ØµØ­ÙŠØ­! âœ… `)
                
                -- Fire the event to signal the main game loop that the round is over.
                roundGuessedEvent:Fire()
                break
            end
        end
    end

    ---------------------------------------------------------------------
    -- // GUI CREATION
    ---------------------------------------------------------------------

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 120)
    MainFrame.BorderSizePixel = 2
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
    MainFrame.Size = UDim2.new(0, 400, 0, 250)
    MainFrame.Active = true
    MainFrame.Draggable = true

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Parent = MainFrame
    TitleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 30)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Parent = TitleBar
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Text = "Universal GUI"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16

    local TabFrame = Instance.new("Frame")
    TabFrame.Name = "TabFrame"
    TabFrame.Parent = MainFrame
    TabFrame.BackgroundTransparency = 1
    TabFrame.Position = UDim2.new(0, 0, 0, 30)
    TabFrame.Size = UDim2.new(1, 0, 0, 35)

    local ChatTabButton = Instance.new("TextButton")
    ChatTabButton.Name = "ChatTabButton"
    ChatTabButton.Parent = TabFrame
    ChatTabButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    ChatTabButton.BorderSizePixel = 0
    ChatTabButton.Position = UDim2.new(0, 5, 0, 0)
    ChatTabButton.Size = UDim2.new(0.5, -7.5, 1, 0)
    ChatTabButton.Font = Enum.Font.SourceSansBold
    ChatTabButton.Text = "Ù…Ø±Ø³Ù„ Ø§Ù„Ø¯Ø±Ø¯Ø´Ø©"
    ChatTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ChatTabButton.TextSize = 14

    local FlagGameTabButton = Instance.new("TextButton")
    FlagGameTabButton.Name = "FlagGameTabButton"
    FlagGameTabButton.Parent = TabFrame
    FlagGameTabButton.BackgroundColor3 = Color3.fromRGB(55, 55, 75)
    FlagGameTabButton.Position = UDim2.new(0.5, 2.5, 0, 0)
    FlagGameTabButton.Size = UDim2.new(0.5, -7.5, 1, 0)
    FlagGameTabButton.Font = Enum.Font.SourceSansBold
    FlagGameTabButton.Text = "Ù„Ø¹Ø¨Ø© ØªØ®Ù…ÙŠÙ† Ø§Ù„Ø£Ø¹Ù„Ø§Ù…"
    FlagGameTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    FlagGameTabButton.TextSize = 14

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = MainFrame
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 0, 0, 65)
    ContentFrame.Size = UDim2.new(1, 0, 1, -65)

    local ChatSenderPage = Instance.new("Frame")
    ChatSenderPage.Name = "ChatSenderPage"
    ChatSenderPage.Parent = ContentFrame
    ChatSenderPage.BackgroundTransparency = 1
    ChatSenderPage.Size = UDim2.new(1, 0, 1, 0)
    ChatSenderPage.Visible = true

    local MessageBox = Instance.new("TextBox")
    MessageBox.Parent = ChatSenderPage
    MessageBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    MessageBox.BorderColor3 = Color3.fromRGB(80, 80, 120)
    MessageBox.Position = UDim2.new(0.05, 0, 0.1, 0)
    MessageBox.Size = UDim2.new(0.9, 0, 0, 50)
    MessageBox.Font = Enum.Font.SourceSans
    MessageBox.PlaceholderText = "Ø§ÙƒØªØ¨ Ø±Ø³Ø§Ù„ØªÙƒ Ù‡Ù†Ø§..."
    MessageBox.TextColor3 = Color3.fromRGB(225, 225, 225)
    MessageBox.TextSize = 14
    MessageBox.ClearTextOnFocus = false

    local SendButton = Instance.new("TextButton")
    SendButton.Parent = ChatSenderPage
    SendButton.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    SendButton.Position = UDim2.new(0.05, 0, 0, 100)
    SendButton.Size = UDim2.new(0.9, 0, 0, 40)
    SendButton.Font = Enum.Font.SourceSansBold
    SendButton.Text = "Ø¥Ø±Ø³Ø§Ù„"
    SendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    SendButton.TextSize = 16

    local FlagGamePage = Instance.new("Frame")
    FlagGamePage.Parent = ContentFrame
    FlagGamePage.BackgroundTransparency = 1
    FlagGamePage.Size = UDim2.new(1, 0, 1, 0)
    FlagGamePage.Visible = false

    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Parent = FlagGamePage
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
    TimeLabel.Size = UDim2.new(0.9, 0, 0, 30)
    TimeLabel.Font = Enum.Font.SourceSansBold
    TimeLabel.Text = "Ø§Ø¶ØºØ· Ø§Ø¨Ø¯Ø£ Ù„Ø¨Ø¯Ø¡ Ø§Ù„Ù„Ø¹Ø¨Ø©"
    TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TimeLabel.TextSize = 18
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Center

    local StartGameButton = Instance.new("TextButton")
    StartGameButton.Parent = FlagGamePage
    StartGameButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    StartGameButton.Position = UDim2.new(0.05, 0, 0, 100)
    StartGameButton.Size = UDim2.new(0.9, 0, 0, 40)
    StartGameButton.Font = Enum.Font.SourceSansBold
    StartGameButton.Text = "Ø§Ø¨Ø¯Ø£"
    StartGameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartGameButton.TextSize = 16

    local StopGameButton = Instance.new("TextButton")
    StopGameButton.Parent = FlagGamePage
    StopGameButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    StopGameButton.Position = UDim2.new(0.05, 0, 0, 100)
    StopGameButton.Size = UDim2.new(0.9, 0, 0, 40)
    StopGameButton.Font = Enum.Font.SourceSansBold
    StopGameButton.Text = "Ø¥ÙŠÙ‚Ø§Ù"
    StopGameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopGameButton.TextSize = 16
    StopGameButton.Visible = false

    ScreenGui.Parent = guiParent

    ---------------------------------------------------------------------
    -- // EVENT CONNECTIONS & LOGIC
    ---------------------------------------------------------------------
    
    -- Tab Switching
    local function switchTab(tabName)
        ChatSenderPage.Visible = (tabName == "Chat")
        FlagGamePage.Visible = (tabName == "FlagGame")
        ChatTabButton.BackgroundColor3 = (tabName == "Chat") and Color3.fromRGB(80, 80, 120) or Color3.fromRGB(55, 55, 75)
        ChatTabButton.TextColor3 = (tabName == "Chat") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
        FlagGameTabButton.BackgroundColor3 = (tabName == "FlagGame") and Color3.fromRGB(80, 80, 120) or Color3.fromRGB(55, 55, 75)
        FlagGameTabButton.TextColor3 = (tabName == "FlagGame") and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
    end
    ChatTabButton.MouseButton1Click:Connect(function() switchTab("Chat") end)
    FlagGameTabButton.MouseButton1Click:Connect(function() switchTab("FlagGame") end)

    -- Chat Sender
    SendButton.MouseButton1Click:Connect(function() sendMessage(MessageBox.Text); MessageBox.Text = "" end)
    MessageBox.FocusLost:Connect(function(enterPressed) if enterPressed then sendMessage(MessageBox.Text); MessageBox.Text = "" end end)

    -- Flag Game Logic
    local function startGame()
        if gameRunning then return end
        gameRunning = true
        StartGameButton.Visible = false
        StopGameButton.Visible = true
        sendMessage("!Ø¨Ø¯Ø£Øª Ù„Ø¹Ø¨Ø© ØªØ®Ù…ÙŠÙ† Ø§Ù„Ø¹Ù„Ù…! Ø§ÙƒØªØ¨ Ø§Ø³Ù… Ø§Ù„Ø¯ÙˆÙ„Ø© ÙÙŠ Ø§Ù„Ø¯Ø±Ø¯Ø´Ø©")

        task.spawn(function()
            while gameRunning do
                currentFlagData = flagsData[math.random(#flagsData)]
                sendMessage("Ø®Ù…Ù† Ø§Ù„Ø¹Ù„Ù…: " .. currentFlagData.flag)
                
                local roundStartTime = tick()
                local guessedCorrectly = false
                
                -- Timer update loop
                task.spawn(function()
                    while gameRunning and currentFlagData and (tick() - roundStartTime) < timePerRound do
                        local timeElapsed = tick() - roundStartTime
                        TimeLabel.Text = "Ø§Ù„ÙˆÙ‚Øª Ø§Ù„Ù…ØªØ¨Ù‚ÙŠ: " .. math.max(0, math.floor(timePerRound - timeElapsed))
                        task.wait(0.1)
                    end
                end)
                
                -- Wait for the round to be guessed or for the time to run out
                local success = roundGuessedEvent.Event:Wait(timePerRound)
                
                if not gameRunning then break end -- Exit if the game was stopped manually

                if success then -- Player guessed correctly
                    guessedCorrectly = true
                else -- Time ran out
                    if currentFlagData then -- Make sure it wasn't already guessed in the same frame
                        local flagEmoji = currentFlagData.flag
                        local mainAnswer = currentFlagData.answers[1]
                        sendMessage(`Ø§Ù†ØªÙ‡Ù‰ Ø§Ù„ÙˆÙ‚Øª! ðŸ•” Ø§Ù„Ø¥Ø¬Ø§Ø¨Ø© Ø§Ù„ØµØ­ÙŠØ­Ø© ÙƒØ§Ù†Øª: {flagEmoji} ({mainAnswer})`)
                    end
                end
                
                currentFlagData = nil
                if gameRunning then
                    TimeLabel.Text = "Ø§Ù„Ø¬ÙˆÙ„Ø© Ø§Ù„ØªØ§Ù„ÙŠØ© Ø³ØªØ¨Ø¯Ø£ Ù‚Ø±ÙŠØ¨Ø§Ù‹..."
                    task.wait(5) -- Pause between rounds
                end
            end
            
            -- Cleanup after game stops
            gameRunning = false
            currentFlagData = nil
            StartGameButton.Visible = true
            StopGameButton.Visible = false
            TimeLabel.Text = "Ø§Ø¶ØºØ· Ø§Ø¨Ø¯Ø£ Ù„Ø¨Ø¯Ø¡ Ø§Ù„Ù„Ø¹Ø¨Ø©"
            sendMessage("!Ø§Ù†ØªÙ‡Øª Ù„Ø¹Ø¨Ø© ØªØ®Ù…ÙŠÙ† Ø§Ù„Ø¹Ù„Ù…")
        end)
    end
    
    local function stopGame()
        if not gameRunning then return end
        gameRunning = false
        -- Firing the event un-yields the main loop immediately
        roundGuessedEvent:Fire() 
    end

    StartGameButton.MouseButton1Click:Connect(startGame)
    StopGameButton.MouseButton1Click:Connect(stopGame)

    -- Universal Chat Listener
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        TextChatService.MessageReceived:Connect(function(messageObject)
            if messageObject.TextSource then
                onMessageReceived(Players:GetPlayerByUserId(messageObject.TextSource.UserId), messageObject.Text)
            end
        end)
        print("Universal GUI: Hooked into TextChatService.")
    else
        local function connectChatted(player)
            player.Chatted:Connect(function(message) onMessageReceived(player, message) end)
        end
        for _, player in ipairs(Players:GetPlayers()) do connectChatted(player) end
        Players.PlayerAdded:Connect(connectChatted)
        print("Universal GUI: Hooked into Legacy Chat (Player.Chatted).")
    end
    
    print("Universal GUI Loaded Successfully.")
end

-- Wrap the entire script in a protected call to catch any initialization errors.
pcall(CreateUniversalGui)
