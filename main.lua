-- ============================================
-- DIUARY HUB - VERSÃO OTIMIZADA (SEM LAG)
-- ============================================

local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ============================================
-- VARIAVEIS
-- ============================================

local AutoPetActive = false
local SpeedActive = false
local NoclipActive = false
local NoWaveActive = false
local AutoPetLoop = nil
local SpeedLoop = nil
local NoclipConnection = nil
local NoWaveLoop = nil
local COLLECT_DISTANCE = 25
local healthConnection = nil

-- ============================================
-- ICONE FLUTUANTE
-- ============================================

local iconGui = Instance.new("ScreenGui")
iconGui.Name = "DiuaryIcon"
iconGui.Parent = game:GetService("CoreGui")
iconGui.ResetOnSpawn = false

local iconButton = Instance.new("TextButton")
iconButton.Size = UDim2.new(0, 60, 0, 60)
iconButton.Position = UDim2.new(1, -75, 0.85, -35)
iconButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
iconButton.BackgroundTransparency = 0.3
iconButton.Text = "💛"
iconButton.TextColor3 = Color3.fromRGB(255, 255, 0)
iconButton.TextSize = 35
iconButton.Font = Enum.Font.GothamBold
iconButton.Parent = iconGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = iconButton

-- Menu flutuante (arrastável)
local menuGui = Instance.new("ScreenGui")
menuGui.Name = "DiuaryMenu"
menuGui.Parent = game:GetService("CoreGui")
menuGui.ResetOnSpawn = false
menuGui.Enabled = true

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 250, 0, 310)
menuFrame.Position = UDim2.new(0.5, -125, 0.3, 0)
menuFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0
menuFrame.Parent = menuGui
menuFrame.Active = true
menuFrame.Draggable = true

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menuFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Diuary Hub"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = menuFrame

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundTransparency = 1
titleBar.Parent = menuFrame

local function createButton(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = menuFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggle(text, yPos, getState, setState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Position = UDim2.new(0.05, 0, 0, yPos)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = menuFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = btn
    
    local function update()
        if getState() then
            btn.Text = text .. ": ON"
            btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
        else
            btn.Text = text .. ": OFF"
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        setState(not getState())
        update()
    end)
    
    update()
    return btn
end

-- ============================================
-- AUTO PET (OTIMIZADO PARA MOBILE)
-- ============================================

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

-- Press E com delay maior para mobile
local function pressE()
    local virtualInput = game:GetService("VirtualInputManager")
    virtualInput:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(1.2)  -- Aumentado para mobile
    virtualInput:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    task.wait(0.3)  -- Delay extra
end

local function autoCollectPet(pet, folderName)
    if not pet or not pet.Parent then return false end
    if not player or not player.Character then return false end
    
    -- Tenta coletar com E
    pressE()
    
    -- Tenta outros métodos
    for _, prompt in ipairs(pet:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            pcall(function() prompt:PromptButtonHold(player) end)
        end
    end
    
    local clickDetector = pet:FindFirstChildWhichIsA("ClickDetector")
    if clickDetector then
        pcall(function() clickDetector:Click() end)
    end
    
    local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local touchInterest = pet:FindFirstChild("TouchInterest")
        if touchInterest then
            pcall(function()
                firetouchinterest(pet, humanoidRootPart, 0)
                firetouchinterest(pet, humanoidRootPart, 1)
            end)
        end
    end
    
    for _, remote in ipairs(pet:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (remote.Name:lower():find("collect") or remote.Name:lower():find("click")) then
            pcall(function() remote:FireServer() end)
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
                    task.wait(0.5) -- Delay maior para mobile
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
    while AutoPetActive do
        pcall(function()
            collectAllNearbyPets()
        end)
        task.wait(0.5) -- Delay do loop aumentado
    end
end

function SetAutoPet(active)
    AutoPetActive = active
    if AutoPetActive then
        if AutoPetLoop then coroutine.close(AutoPetLoop) end
        AutoPetLoop = coroutine.create(autoCollectLoop)
        coroutine.resume(AutoPetLoop)
        print("✅ Auto Pet: ON")
    else
        if AutoPetLoop then coroutine.close(AutoPetLoop) end
        AutoPetLoop = nil
        print("❌ Auto Pet: OFF")
    end
end

-- ============================================
-- SPEED
-- ============================================

function SetSpeed(active)
    SpeedActive = active
    if SpeedActive then
        local Character = player.Character
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = 450
        end
        if SpeedLoop then return end
        SpeedLoop = RunService.Heartbeat:Connect(function()
            if SpeedActive then
                local Character = player.Character
                if Character and Character:FindFirstChild("Humanoid") then
                    if Character.Humanoid.WalkSpeed ~= 450 then
                        Character.Humanoid.WalkSpeed = 450
                    end
                end
            end
        end)
        print("✅ Speed: ON (450)")
    else
        if SpeedLoop then
            SpeedLoop:Disconnect()
            SpeedLoop = nil
        end
        local Character = player.Character
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = 16
        end
        print("❌ Speed: OFF")
    end
end

-- ============================================
-- NOCLIP
-- ============================================

function SetNoclip(active)
    NoclipActive = active
    if NoclipActive then
        if NoclipConnection then return end
        NoclipConnection = RunService.Stepped:Connect(function()
            if NoclipActive then
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
        print("✅ Noclip: ON")
    else
        if NoclipConnection then
            NoclipConnection:Disconnect()
            NoclipConnection = nil
        end
        local Character = player.Character
        if Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
        print("❌ Noclip: OFF")
    end
end

-- ============================================
-- NO WAVE OTIMIZADO (SEM LAG)
-- ============================================

local lastWaveClean = 0

local function destroyWaves()
    local now = tick()
    if now - lastWaveClean < 1.5 then return end
    lastWaveClean = now
    
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

local function protectPlayer()
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            if healthConnection then
                healthConnection:Disconnect()
            end
            healthConnection = humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                if NoWaveActive and humanoid.Health < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
        end
    end
end

local function noWaveLoop()
    while NoWaveActive do
        pcall(function()
            destroyWaves()
        end)
        task.wait(1.5)
    end
end

player.CharacterAdded:Connect(function()
    task.wait(0.5)
    if NoWaveActive then
        protectPlayer()
    end
end)

function SetNoWave(active)
    NoWaveActive = active
    if NoWaveActive then
        if NoWaveLoop then coroutine.close(NoWaveLoop) end
        NoWaveLoop = coroutine.create(noWaveLoop)
        coroutine.resume(NoWaveLoop)
        protectPlayer()
        destroyWaves()
        print("✅ No Wave: ON")
    else
        if NoWaveLoop then 
            coroutine.close(NoWaveLoop) 
            NoWaveLoop = nil
        end
        if healthConnection then
            healthConnection:Disconnect()
            healthConnection = nil
        end
        print("❌ No Wave: OFF")
    end
end

-- ============================================
-- CRIAR BOTOES DO MENU
-- ============================================

createToggle("Auto Pet", 50, function() return AutoPetActive end, SetAutoPet)
createToggle("Speed 450", 100, function() return SpeedActive end, SetSpeed)
createToggle("Noclip", 150, function() return NoclipActive end, SetNoclip)
createToggle("No Wave", 200, function() return NoWaveActive end, SetNoWave)

local closeBtn = createButton("Fechar", 260, function()
    menuGui.Enabled = false
end)

-- Fechar menu com o ícone
local menuVisible = true

-- Arrastar ícone
local dragging = false
local dragStart = nil
local startPos = nil

iconButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = iconButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging then
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then
                local screenSize = workspace.CurrentCamera.ViewportSize
                local newX = startPos.X.Scale + (delta.X / screenSize.X)
                local newY = startPos.Y.Scale + (delta.Y / screenSize.Y)
                newX = math.clamp(newX, 0, 0.88)
                newY = math.clamp(newY, 0, 0.88)
                iconButton.Position = UDim2.new(newX, 0, newY, 0)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging then
            local wasDragged = false
            if dragStart and input.Position then
                local delta = input.Position - dragStart
                if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then
                    wasDragged = true
                end
            end
            if not wasDragged then
                if menuVisible then
                    menuGui.Enabled = false
                    menuVisible = false
                    iconButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                else
                    menuGui.Enabled = true
                    menuVisible = true
                    iconButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                end
            end
        end
        dragging = false
        dragStart = nil
        startPos = nil
    end
end)

print("✅ Diuary Hub Carregado!")
print("💛 Clique no ícone para abrir/fechar o menu")
print("📱 Versão otimizada para mobile!")
