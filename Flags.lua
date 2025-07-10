--[[
    Script: Flag Game GUI v3 (Arabic)
    Description: A specialized GUI to host a "Guess the Flag" game in Arabic.
    - Features a larger library of flags with more answer variations.
    - Includes a toggle button to hide/show the GUI, compatible with both PC and mobile.
    - Fully FE compatible and works with both new (TextChatService) and legacy chat systems.
    - Features an efficient event-driven game loop.

    How to use:
    1. Copy this entire script.
    2. Open your script executor in a Roblox game.
    3. Paste the script and execute it.
    4. A GUI will appear. Use the "Start" button to begin the game. Use the "Hide/Show" button in the top-right to toggle the GUI's visibility.
]]

local function CreateFlagGameGui()
    
    -- // Services & Checks (wrapped for safety)
    local Players, UserInputService, TextChatService, ReplicatedStorage
    local servicesAvailable = pcall(function()
        Players = game:GetService("Players")
        UserInputService = game:GetService("UserInputService")
        TextChatService = game:GetService("TextChatService")
        ReplicatedStorage = game:GetService("ReplicatedStorage")
    end)
    
    if not servicesAvailable then
        warn("Flag Game GUI: Could not get essential services. The script may not function correctly.")
        return
    end

    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        warn("Flag Game GUI: Could not find LocalPlayer.")
        return
    end

    -- // Configuration
    local mainGuiName = "FlagGameGUI_" .. tostring(math.random(1000, 9999))
    local toggleGuiName = "ToggleGUI_" .. tostring(math.random(1000, 9999))
    
    -- // Smart GUI Parent determination
    local function getGuiParent()
        local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
        if success and coreGui then
            if coreGui:FindFirstChild(mainGuiName) then coreGui[mainGuiName]:Destroy() end
            if coreGui:FindFirstChild(toggleGuiName) then coreGui[toggleGuiName]:Destroy() end
            return coreGui
        end
        -- Fallback for environments where CoreGui is not directly accessible
        warn("Flag Game GUI: Could not access CoreGui, falling back to PlayerGui. GUI may be removed on respawn.")
        local playerGui = LocalPlayer:WaitForChild("PlayerGui")
        if playerGui:FindFirstChild(mainGuiName) then playerGui[mainGuiName]:Destroy() end
        if playerGui:FindFirstChild(toggleGuiName) then playerGui[toggleGuiName]:Destroy() end
        return playerGui
    end
    
    local guiParent = getGuiParent()
    if not guiParent then
        warn("Flag Game GUI: Could not find a suitable parent for the GUI. Aborting.")
        return
    end

    -- // Flag Game Data (Expanded List in Arabic & English)
    local flagsData = {
        { flag = "🇸🇦", answers = { "السعودية", "المملكة العربية السعودية", "saudi arabia", "ksa" } },
        { flag = "🇪🇬", answers = { "مصر", "جمهورية مصر العربية", "egypt" } },
        { flag = "🇦🇪", answers = { "الامارات", "الإمارات العربية المتحدة", "uae", "united arab emirates" } },
        { flag = "🇯🇴", answers = { "الاردن", "الأردن", "jordan" } },
        { flag = "🇵🇸", answers = { "فلسطين", "palestine" } },
        { flag = "🇮🇶", answers = { "العراق", "iraq" } },
        { flag = "🇸🇾", answers = { "سوريا", "سورية", "syria" } },
        { flag = "🇱🇧", answers = { "لبنان", "lebanon" } },
        { flag = "🇰🇼", answers = { "الكويت", "kuwait" } },
        { flag = "🇶🇦", answers = { "قطر", "qatar" } },
        { flag = "🇧🇭", answers = { "البحرين", "bahrain" } },
        { flag = "🇴🇲", answers = { "عمان", "سلطنة عمان", "oman" } },
        { flag = "🇾🇪", answers = { "اليمن", "yemen" } },
        { flag = "🇩🇿", answers = { "الجزائر", "algeria" } },
        { flag = "🇲🇦", answers = { "المغرب", "morocco" } },
        { flag = "🇹🇳", answers = { "تونس", "tunisia" } },
        { flag = "🇱🇾", answers = { "ليبيا", "libya" } },
        { flag = "🇸🇩", answers = { "السودان", "sudan" } },
        { flag = "🇹🇷", answers = { "تركيا", "turkey" } },
        { flag = "🇺🇸", answers = { "امريكا", "الولايات المتحدة", "الولايات المتحدة الامريكية", "usa", "america", "united states" } },
        { flag = "🇬🇧", answers = { "بريطانيا", "المملكة المتحدة", "uk", "britain", "united kingdom" } },
        { flag = "🇫🇷", answers = { "فرنسا", "france" } },
        { flag = "🇩🇪", answers = { "المانيا", "ألمانيا", "germany" } },
        { flag = "🇮🇹", answers = { "ايطاليا", "إيطاليا", "italy" } },
        { flag = "🇪🇸", answers = { "اسبانيا", "إسبانيا", "spain" } },
        { flag = "🇷🇺", answers = { "روسيا", "russia" } },
        { flag = "🇨🇳", answers = { "الصين", "china" } },
        { flag = "🇯🇵", answers = { "اليابان", "japan" } },
        { flag = "🇧🇷", answers = { "البرازيل", "brazil" } },
        { flag = "🇦🇷", answers = { "الارجنتين", "الأرجنتين", "argentina" } },
        { flag = "🇨🇦", answers = { "كندا", "canada" } },
        { flag = "🇦🇺", answers = { "استراليا", "أستراليا", "australia" } },
        { flag = "🇮🇳", answers = { "الهند", "india" } },
        { flag = "🇵🇰", answers = { "باكستان", "pakistan" } },
        { flag = "🇰🇷", answers = { "كوريا الجنوبية", "south korea" } },
        { flag = "🇲🇽", answers = { "المكسيك", "mexico" } },
        { flag = "🇳🇬", answers = { "نيجيريا", "nigeria" } },
        { flag = "🇿🇦", answers = { "جنوب افريقيا", "south africa" } },
        { flag = "🇳🇱", answers = { "هولندا", "netherlands" } },
        { flag = "🇵🇹", answers = { "البرتغال", "portugal" } },
        { flag = "🇸🇪", answers = { "السويد", "sweden" } },
        { flag = "🇨🇭", answers = { "سويسرا", "switzerland" } },
        { flag = "🇬🇷", answers = { "اليونان", "greece" } },
        { flag = "🇮🇪", answers = { "ايرلندا", "ireland" } }
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
                    warn("Flag Game GUI: Could not find RBXGeneral channel in TextChatService.")
                end
            end)
        else
            -- Legacy Chat: This is the most common remote event. Wrap in pcall for safety.
            local success, err = pcall(function()
                ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
            end)
            if not success then
                warn("Flag Game GUI: Could not send message via standard legacy chat event. This game may use a custom chat system.")
            end
        end
    end
    
    local function onMessageReceived(player, message)
        if not gameRunning or not currentFlagData or player == LocalPlayer then return end

        -- Normalize the guess: lowercase and remove leading/trailing whitespace
        local guess = message:lower():gsub("^%s*(.-)%s*$", "%1")

        for _, answer in ipairs(currentFlagData.answers) do
            if guess == answer:lower() then
                sendMessage(`اللاعب {player.Name} خمن بشكل صحيح! ✅`)
                
                -- Fire the event to signal the main game loop that the round is over.
                roundGuessedEvent:Fire()
                break
            end
        end
    end

    ---------------------------------------------------------------------
    -- // GUI CREATION
    ---------------------------------------------------------------------

    -- Main GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = mainGuiName
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.ResetOnSpawn = false

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    MainFrame.BorderColor3 = Color3.fromRGB(80, 80, 120)
    MainFrame.BorderSizePixel = 2
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -110)
    MainFrame.Size = UDim2.new(0, 350, 0, 220)
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Visible = true -- Starts visible

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
    TitleLabel.Text = "لعبة تخمين الأعلام"
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 16

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Parent = MainFrame
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Position = UDim2.new(0, 0, 0, 30) -- Position right below the title bar
    ContentFrame.Size = UDim2.new(1, 0, 1, -30) -- Fill the rest of the frame

    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Parent = ContentFrame
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Position = UDim2.new(0.05, 0, 0.1, 0)
    TimeLabel.Size = UDim2.new(0.9, 0, 0, 30)
    TimeLabel.Font = Enum.Font.SourceSansBold
    TimeLabel.Text = "اضغط ابدأ لبدء اللعبة"
    TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TimeLabel.TextSize = 18
    TimeLabel.TextXAlignment = Enum.TextXAlignment.Center

    local StartGameButton = Instance.new("TextButton")
    StartGameButton.Parent = ContentFrame
    StartGameButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    StartGameButton.Position = UDim2.new(0.05, 0, 0.5, 0) -- Centered vertically
    StartGameButton.Size = UDim2.new(0.9, 0, 0, 40)
    StartGameButton.Font = Enum.Font.SourceSansBold
    StartGameButton.Text = "ابدأ"
    StartGameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartGameButton.TextSize = 16

    local StopGameButton = Instance.new("TextButton")
    StopGameButton.Parent = ContentFrame
    StopGameButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    StopGameButton.Position = UDim2.new(0.05, 0, 0.5, 0)
    StopGameButton.Size = UDim2.new(0.9, 0, 0, 40)
    StopGameButton.Font = Enum.Font.SourceSansBold
    StopGameButton.Text = "إيقاف"
    StopGameButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopGameButton.TextSize = 16
    StopGameButton.Visible = false

    ScreenGui.Parent = guiParent

    -- Toggle Button GUI (Separate for independent visibility)
    local ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = toggleGuiName
    ToggleGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ToggleGui.ResetOnSpawn = false
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Parent = ToggleGui
    ToggleButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    ToggleButton.BorderColor3 = Color3.fromRGB(80, 80, 120)
    ToggleButton.Position = UDim2.new(1, -110, 0, 10) -- Top-right corner
    ToggleButton.Size = UDim2.new(0, 100, 0, 30)
    ToggleButton.Font = Enum.Font.SourceSansBold
    ToggleButton.Text = "إخفاء الواجهة"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 14
    
    ToggleGui.Parent = guiParent

    ---------------------------------------------------------------------
    -- // EVENT CONNECTIONS & LOGIC
    ---------------------------------------------------------------------

    -- GUI Toggle Logic
    ToggleButton.MouseButton1Click:Connect(function()
        MainFrame.Visible = not MainFrame.Visible
        if MainFrame.Visible then
            ToggleButton.Text = "إخفاء الواجهة"
        else
            ToggleButton.Text = "إظهار الواجهة"
        end
    end)
    
    -- Flag Game Logic
    local function startGame()
        if gameRunning then return end
        gameRunning = true
        StartGameButton.Visible = false
        StopGameButton.Visible = true
        sendMessage("!بدأت لعبة تخمين العلم! اكتب اسم الدولة في الدردشة")

        task.spawn(function()
            while gameRunning do
                currentFlagData = flagsData[math.random(#flagsData)]
                sendMessage("خمن العلم: " .. currentFlagData.flag)
                
                local roundStartTime = tick()
                
                -- Timer update loop
                task.spawn(function()
                    while gameRunning and currentFlagData and (tick() - roundStartTime) < timePerRound do
                        local timeElapsed = tick() - roundStartTime
                        TimeLabel.Text = "الوقت المتبقي: " .. math.max(0, math.floor(timePerRound - timeElapsed))
                        task.wait(0.1)
                    end
                end)
                
                -- Wait for the round to be guessed or for the time to run out
                roundGuessedEvent.Event:Wait(timePerRound)
                
                if not gameRunning then break end -- Exit if the game was stopped manually

                if currentFlagData then -- If it hasn't been set to nil by a correct guess
                    -- This means time ran out
                    local flagEmoji = currentFlagData.flag
                    local mainAnswer = currentFlagData.answers[1]
                    sendMessage(`انتهى الوقت! ⏳ الإجابة الصحيحة كانت: {flagEmoji} ({mainAnswer})`)
                end
                
                currentFlagData = nil
                if gameRunning then
                    TimeLabel.Text = "الجولة التالية ستبدأ قريباً..."
                    task.wait(5) -- Pause between rounds
                end
            end
            
            -- Cleanup after game stops
            gameRunning = false
            currentFlagData = nil
            StartGameButton.Visible = true
            StopGameButton.Visible = false
         TimeLabel.Text = "اضغط ابدأ لبدء اللعبة"
            sendMessage("!انتهت لعبة تخمين العلم")
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
        print("Flag Game GUI: Hooked into TextChatService.")
    else
        local function connectChatted(player)
            player.Chatted:Connect(function(message) onMessageReceived(player, message) end)
        end
        for _, player in ipairs(Players:GetPlayers()) do connectChatted(player) end
        Players.PlayerAdded:Connect(connectChatted)
        print("Flag Game GUI: Hooked into Legacy Chat (Player.Chatted).")
    end
    
    print("Flag Game GUI Loaded Successfully.")
end

-- Wrap the entire script in a protected call to catch any initialization errors.
pcall(CreateFlagGameGui)
