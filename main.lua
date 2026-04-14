local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Diuary Hub",
    SubTitle = "OG",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local player = game.Players.LocalPlayer

-- ============================================
-- ICONE FLUTUANTE (CORRIGIDO)
-- ============================================

local iconGui = Instance.new("ScreenGui")
iconGui.Name = "DiuaryIcon"
iconGui.Parent = game:GetService("CoreGui")
iconGui.ResetOnSpawn = false
iconGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local iconButton = Instance.new("TextButton")
iconButton.Size = UDim2.new(0, 55, 0, 55)
iconButton.Position = UDim2.new(1, -65, 0.85, -30)
iconButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
iconButton.BackgroundTransparency = 0.3
iconButton.Text = "💛"
iconButton.TextColor3 = Color3.fromRGB(255, 255, 0)
iconButton.TextSize = 35
iconButton.Font = Enum.Font.GothamBold
iconButton.BorderSizePixel = 0
iconButton.Parent = iconGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = iconButton

local dragging = false
local dragStart = nil
local startPos = nil
local wasDragged = false
local uiVisible = true
local UserInputService = game:GetService("UserInputService")

iconButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        wasDragged = false
        dragStart = input.Position
        startPos = iconButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then
            wasDragged = true
        end
        local screenSize = workspace.CurrentCamera.ViewportSize
        local newX = startPos.X.Scale + (delta.X / screenSize.X)
        local newY = startPos.Y.Scale + (delta.Y / screenSize.Y)
        newX = math.clamp(newX, 0, 0.88)
        newY = math.clamp(newY, 0, 0.88)
        iconButton.Position = UDim2.new(newX, 0, newY, 0)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

iconButton.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not wasDragged then
            if uiVisible then
                Window:SetVisible(false)
                uiVisible = false
            else
                Window:SetVisible(true)
                uiVisible = true
            end
        end
        wasDragged = false
    end
end)

-- ============================================
-- AUTO PET
-- ============================================

local isActive = false
local collectingLock = false
local AutoPetLoop = nil
local COLLECT_DISTANCE = 25
local CHECK_INTERVAL = 0.1

local petFolders = {
    {path = {"Tsunami", "Gen", "R7"}, name = "R7"},
    {path = {"Tsunami", "Gen", "R8"}, name = "R8"}
}

local function getPlayerPosition()
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character.HumanoidRootPart.Position
    end
    return nil
end

local function getPetFolder(folderPath)
    local current = workspace
    for _, folderName in ipairs(folderPath) do
        current = current:FindFirstChild(folderName)
        if not current then
            return nil
        end
    end
    return current
end

local function pressE()
    local virtualInput = game:GetService("VirtualInputManager")
    virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.9)
    virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function autoCollectPet(pet, folderName)
    if not pet or not pet.Parent then return false end
    if not player or not player.Character then return false end

    pressE()

    for _, prompt in ipairs(pet:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            prompt:PromptButtonHold(player)
        end
    end

    local clickDetector = pet:FindFirstChildWhichIsA("ClickDetector")
    if clickDetector then
        clickDetector:Click()
    end

    local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local touchInterest = pet:FindFirstChild("TouchInterest")
        if touchInterest then
            firetouchinterest(pet, humanoidRootPart, 0)
            firetouchinterest(pet, humanoidRootPart, 1)
        end
    end

    for _, remote in ipairs(pet:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("collect") or remote.Name:lower():find("click")) then
            remote:FireServer()
        end
    end

    local petPart = pet:IsA("BasePart") and pet or pet:FindFirstChildWhichIsA("BasePart")
    if petPart then
        local mouse = player:GetMouse()
        if mouse then
            mouse.Target = petPart
            mouse.Button1Click:Fire()
        end
    end

    return true
end

local function collectPetsInFolder(folder, folderName)
    if not folder then return false end

    local playerPos = getPlayerPosition()
    if not playerPos then return false end

    for _, pet in ipairs(folder:GetChildren()) do
        if pet and pet.Parent then
            local petPart = pet:FindFirstChild("PrimaryPart") or
                            pet:FindFirstChild("HumanoidRootPart") or
                            (pet:IsA("BasePart") and pet) or
                            pet:FindFirstChildWhichIsA("BasePart")

            if petPart and petPart.Parent then
                local distance = (playerPos - petPart.Position).Magnitude
                if distance <= COLLECT_DISTANCE then
                    autoCollectPet(pet, folderName)
                    task.wait(0.05)
                end
            end
        end
    end

    return false
end

local function collectAllNearbyPets()
    for _, folderInfo in ipairs(petFolders) do
        local folder = getPetFolder(folderInfo.path)
        if folder then
            collectPetsInFolder(folder, folderInfo.name)
        end
    end
end

local function autoCollectLoop()
    while isActive do
        if not collectingLock then
            collectingLock = true
            pcall(function()
                collectAllNearbyPets()
            end)
            collectingLock = false
        end
        task.wait(CHECK_INTERVAL)
    end
end

local function StartAutoPet()
    if AutoPetLoop then return end
    isActive = true
    AutoPetLoop = task.spawn(autoCollectLoop)
    Fluent:Notify({
        Title = "Auto Pet",
        Content = "Ligado",
        Duration = 2
    })
end

local function StopAutoPet()
    isActive = false
    if AutoPetLoop then
        coroutine.close(AutoPetLoop)
        AutoPetLoop = nil
    end
    Fluent:Notify({
        Title = "Auto Pet",
        Content = "Desligado",
        Duration = 2
    })
end

local AutoPetToggle = Tabs.Main:AddToggle("AutoPetToggle", {
    Title = "Auto Pet",
    Default = false
})

AutoPetToggle:OnChanged(function()
    if Options.AutoPetToggle.Value then
        StartAutoPet()
    else
        StopAutoPet()
    end
end)

-- ============================================
-- SPEED (WALKSPEED)
-- ============================================

local SpeedEnabled = false
local SpeedLoop = nil

local function SetSpeed(Speed)
    local Character = player.Character
    if Character and Character:FindFirstChild("Humanoid") then
        local Humanoid = Character.Humanoid
        if Humanoid.Health > 0 then
            Humanoid.WalkSpeed = Speed
        end
    end
end

local function StartSpeedLoop()
    if SpeedLoop then return end
    SpeedLoop = game:GetService("RunService").Heartbeat:Connect(function()
        if SpeedEnabled then
            local Character = player.Character
            if Character and Character:FindFirstChild("Humanoid") then
                local Humanoid = Character.Humanoid
                if Humanoid.WalkSpeed ~= 450 and Humanoid.Health > 0 then
                    Humanoid.WalkSpeed = 450
                end
            end
        end
    end)
end

local function StopSpeedLoop()
    if SpeedLoop then
        SpeedLoop:Disconnect()
        SpeedLoop = nil
    end
end

local SpeedToggle = Tabs.Main:AddToggle("SpeedToggle", {
    Title = "Speed",
    Default = false
})

SpeedToggle:OnChanged(function()
    SpeedEnabled = Options.SpeedToggle.Value
    if SpeedEnabled then
        SetSpeed(450)
        StartSpeedLoop()
    else
        SetSpeed(16)
        StopSpeedLoop()
    end
end)

player.CharacterAdded:Connect(function(Character)
    Character:WaitForChild("Humanoid")
    task.wait(0.5)
    if SpeedEnabled then
        SetSpeed(450)
    end
end)

-- ============================================
-- NOCLIP
-- ============================================

local NoclipEnabled = false
local NoclipConnection = nil
local OriginalCollision = {}

local function SaveOriginalCollision()
    local Character = player.Character
    if Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                OriginalCollision[part] = part.CanCollide
            end
        end
    end
end

local function RestoreCollision()
    for part, value in pairs(OriginalCollision) do
        if part and part.Parent then
            part.CanCollide = value
        end
    end
    OriginalCollision = {}
end

local function StartNoclip()
    if NoclipConnection then return end
    SaveOriginalCollision()
    NoclipConnection = game:GetService("RunService").Stepped:Connect(function()
        if NoclipEnabled then
            local Character = player.Character
            if Character then
                for _, part in pairs(Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end

local function StopNoclip()
    if NoclipConnection then
        NoclipConnection:Disconnect()
        NoclipConnection = nil
    end
    RestoreCollision()
end

local NoclipToggle = Tabs.Main:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Default = false
})

NoclipToggle:OnChanged(function()
    NoclipEnabled = Options.NoclipToggle.Value
    if NoclipEnabled then
        StartNoclip()
    else
        StopNoclip()
    end
end)

-- ============================================
-- NO WAVE (ANTI-TSUNAMI)
-- ============================================

local NoWaveEnabled = false
local NoWaveLoop = nil

local function destroyWaves()
    local tsunami = workspace:FindFirstChild("Tsunami")
    if tsunami then
        local waves = tsunami:FindFirstChild("Waves")
        if waves then
            for _, wave in pairs(waves:GetChildren()) do
                pcall(function() wave:Destroy() end)
            end
        end
    end
end

local function hideWaves()
    local tsunami = workspace:FindFirstChild("Tsunami")
    if tsunami then
        local waves = tsunami:FindFirstChild("Waves")
        if waves then
            for _, wave in pairs(waves:GetChildren()) do
                pcall(function()
                    if wave:IsA("BasePart") then
                        wave.Transparency = 1
                        wave.CanCollide = false
                    elseif wave:IsA("Model") then
                        for _, part in pairs(wave:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Transparency = 1
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            end
        end
    end
end

local function removeWaveDamage()
    local tsunami = workspace:FindFirstChild("Tsunami")
    if tsunami then
        local waves = tsunami:FindFirstChild("Waves")
        if waves then
            for _, wave in pairs(waves:GetChildren()) do
                pcall(function()
                    for _, obj in pairs(wave:GetDescendants()) do
                        if obj:IsA("Script") or obj:IsA("LocalScript") then
                            if obj.Name:lower():find("damage") or
                               obj.Name:lower():find("kill") or
                               obj.Name:lower():find("hurt") then
                                obj.Disabled = true
                            end
                        end
                        if obj:IsA("TouchInterest") then
                            obj:Destroy()
                        end
                    end
                end)
            end
        end
    end
end

local function blockWaveSpawn()
    local tsunami = workspace:FindFirstChild("Tsunami")
    if tsunami then
        for _, script in pairs(tsunami:GetDescendants()) do
            if script:IsA("Script") or script:IsA("LocalScript") then
                local scriptName = script.Name:lower()
                if scriptName:find("wave") or
                   scriptName:find("spawn") or
                   scriptName:find("tsunami") then
                    pcall(function() script.Disabled = true end)
                end
            end
        end
    end
end

local function protectPlayer()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if NoWaveEnabled then
                    if humanoid.Health < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end
            end)
        end
    end
end

local function NoWaveLoopFunction()
    while NoWaveEnabled do
        pcall(function()
            destroyWaves()
            hideWaves()
            removeWaveDamage()
            blockWaveSpawn()
            protectPlayer()
        end)
        task.wait(0.3)
    end
end

local function StartNoWave()
    if NoWaveLoop then return end
    NoWaveEnabled = true
    NoWaveLoop = task.spawn(NoWaveLoopFunction)
    Fluent:Notify({
        Title = "No Wave",
        Content = "Ligado",
        Duration = 2
    })
end

local function StopNoWave()
    NoWaveEnabled = false
    if NoWaveLoop then
        coroutine.close(NoWaveLoop)
        NoWaveLoop = nil
    end
    Fluent:Notify({
        Title = "No Wave",
        Content = "Desligado",
        Duration = 2
    })
end

local NoWaveToggle = Tabs.Main:AddToggle("NoWaveToggle", {
    Title = "No Wave",
    Default = false
})

NoWaveToggle:OnChanged(function()
    if Options.NoWaveToggle.Value then
        StartNoWave()
    else
        StopNoWave()
    end
end)

-- ============================================
-- SETTINGS
-- ============================================

Tabs.Settings:AddButton({
    Title = "Fechar UI",
    Callback = function()
        Window:Destroy()
        iconGui:Destroy()
    end
})

Tabs.Settings:AddButton({
    Title = "Resetar Tudo",
    Callback = function()
        if Options.AutoPetToggle.Value then Options.AutoPetToggle:SetValue(false) end
        if Options.SpeedToggle.Value then Options.SpeedToggle:SetValue(false) end
        if Options.NoclipToggle.Value then Options.NoclipToggle:SetValue(false) end
        if Options.NoWaveToggle.Value then Options.NoWaveToggle:SetValue(false) end
        Fluent:Notify({
            Title = "Resetado",
            Content = "Todas funcoes desativadas",
            Duration = 2
        })
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Diuary Hub",
    Content = "Clique no icone 💛 para minimizar",
    Duration = 5
})
