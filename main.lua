-- ============================================
-- DIUARY HUB - VERSÃO OTIMIZADA (SEM LAG)
-- ============================================

local player = game.Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ============================================
-- VARIAVEIS
-- ============================================

local SpeedActive = false
local NoclipActive = false
local NoWaveActive = false
local DivinoActive = false
local PrismaticoActive = false
local AntiAFKActive = false
local SpeedLoop = nil
local NoclipConnection = nil
local NoWaveLoop = nil
local DivinoLoop = nil
local PrismaticoLoop = nil
local AntiAFKConnection = nil
local healthConnection = nil

-- POSICOES FIXAS
local R7_POSITION = Vector3.new(-959.887451171875, 21.7581787109375, 4061.0625)
local R8_POSITION = Vector3.new(-1593.5523681640625, -70.22384643554688, 4064.4248046875)
local BASE_POSITION = Vector3.new(905.006103515625, -23.359270095825195, 4066.5439453125)

-- ============================================
-- ICONE FLUTUANTE
-- ============================================

local iconGui = Instance.new("ScreenGui")
iconGui.Name = "DiuaryIcon"
iconGui.Parent = game:GetService("CoreGui")
iconGui.ResetOnSpawn = false

local iconButton = Instance.new("TextButton")
iconButton.Size = UDim2.new(0, 55, 0, 55)
iconButton.Position = UDim2.new(1, -65, 0.85, -30)
iconButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
iconButton.BackgroundTransparency = 0.3
iconButton.Text = "💛"
iconButton.TextColor3 = Color3.fromRGB(255, 255, 0)
iconButton.TextSize = 30
iconButton.Font = Enum.Font.GothamBold
iconButton.Parent = iconGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = iconButton

-- ============================================
-- MENU PRINCIPAL
-- ============================================

local menuGui = Instance.new("ScreenGui")
menuGui.Name = "DiuaryMenu"
menuGui.Parent = game:GetService("CoreGui")
menuGui.ResetOnSpawn = false
menuGui.Enabled = true

local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 220, 0, 370)
menuFrame.Position = UDim2.new(0.5, -110, 0.35, 0)
menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
menuFrame.BackgroundTransparency = 0.15
menuFrame.BorderSizePixel = 0
menuFrame.Parent = menuGui
menuFrame.Active = true
menuFrame.Draggable = true

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = menuFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Diuary Hub"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = menuFrame

local line = Instance.new("Frame")
line.Size = UDim2.new(0.9, 0, 0, 1)
line.Position = UDim2.new(0.05, 0, 0, 35)
line.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
line.BorderSizePixel = 0
line.Parent = menuFrame

-- ============================================
-- FUNCOES DOS BOTOES
-- ============================================

local function createToggle(text, yPos, getState, setState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 38)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.Text = text .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = menuFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    local function update()
        if getState() then
            btn.Text = text .. ": ON"
            btn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            btn.Text = text .. ": OFF"
            btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        end
    end
    
    btn.MouseButton1Click:Connect(function()
        setState(not getState())
        update()
    end)
    
    update()
    return btn
end

local function createButton(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 38)
    btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Parent = menuFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ============================================
-- FUNCOES GERAIS
-- ============================================

local function teleport(pos)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos)
        task.wait(0.05)
    end
end

local function findPets(folderName)
    local pets = {}
    local tsunami = workspace:FindFirstChild("Tsunami")
    if tsunami and tsunami:FindFirstChild("Gen") then
        local gen = tsunami.Gen
        local folder = gen:FindFirstChild(folderName)
        if folder then
            for _, p in pairs(folder:GetChildren()) do
                if p and p.Parent then
                    table.insert(pets, p)
                end
            end
        end
    end
    return pets
end

local function getPetPos(pet)
    local part = pet:FindFirstChild("PrimaryPart") or 
                 pet:FindFirstChild("HumanoidRootPart") or 
                 (pet:IsA("BasePart") and pet) or
                 pet:FindFirstChildWhichIsA("BasePart")
    return part and part.Position or nil
end

-- Coleta rapida otimizada
local function quickCollect()
    local vm = game:GetService("VirtualInputManager")
    vm:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    task.wait(0.2)
    vm:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    task.wait(0.1)
end

-- ============================================
-- ANTI-AFK
-- ============================================

local VirtualUser = game:GetService("VirtualUser")

local function AntiAFKLoop()
    while AntiAFKActive do
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        task.wait(60)
    end
end

function SetAntiAFK(active)
    AntiAFKActive = active
    if AntiAFKActive then
        if AntiAFKConnection then coroutine.close(AntiAFKConnection) end
        AntiAFKConnection = coroutine.create(AntiAFKLoop)
        coroutine.resume(AntiAFKConnection)
        print("Anti-AFK: ON")
    else
        if AntiAFKConnection then coroutine.close(AntiAFKConnection) end
        AntiAFKConnection = nil
        print("Anti-AFK: OFF")
    end
end

-- ============================================
-- DIVINO - R7 (OTIMIZADO)
-- ============================================

local function divinoLoop()
    while DivinoActive do
        teleport(R7_POSITION)
        task.wait(0.3)
        
        local pets = findPets("R7")
        if #pets > 0 then
            for _, pet in pairs(pets) do
                local petPos = getPetPos(pet)
                if petPos then
                    teleport(petPos)
                    task.wait(0.15)
                    quickCollect()
                    task.wait(0.15)
                end
            end
        end
        
        teleport(BASE_POSITION)
        task.wait(2)
    end
end

function SetDivino(active)
    DivinoActive = active
    if DivinoActive then
        if DivinoLoop then coroutine.close(DivinoLoop) end
        DivinoLoop = coroutine.create(divinoLoop)
        coroutine.resume(DivinoLoop)
        print("Divino: ON")
    else
        if DivinoLoop then coroutine.close(DivinoLoop) end
        DivinoLoop = nil
        print("Divino: OFF")
    end
end

-- ============================================
-- PRISMATICO - R8 (OTIMIZADO)
-- ============================================

local function prismaticoLoop()
    while PrismaticoActive do
        teleport(R8_POSITION)
        task.wait(0.3)
        
        local pets = findPets("R8")
        if #pets > 0 then
            for _, pet in pairs(pets) do
                local petPos = getPetPos(pet)
                if petPos then
                    teleport(petPos)
                    task.wait(0.15)
                    quickCollect()
                    task.wait(0.15)
                end
            end
        end
        
        teleport(BASE_POSITION)
        task.wait(2)
    end
end

function SetPrismatico(active)
    PrismaticoActive = active
    if PrismaticoActive then
        if PrismaticoLoop then coroutine.close(PrismaticoLoop) end
        PrismaticoLoop = coroutine.create(prismaticoLoop)
        coroutine.resume(PrismaticoLoop)
        print("Prismatico: ON")
    else
        if PrismaticoLoop then coroutine.close(PrismaticoLoop) end
        PrismaticoLoop = nil
        print("Prismatico: OFF")
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
        print("Speed: ON (450)")
    else
        if SpeedLoop then
            SpeedLoop:Disconnect()
            SpeedLoop = nil
        end
        local Character = player.Character
        if Character and Character:FindFirstChild("Humanoid") then
            Character.Humanoid.WalkSpeed = 16
        end
        print("Speed: OFF")
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
        print("Noclip: ON")
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
        print("Noclip: OFF")
    end
end

-- ============================================
-- NO WAVE
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
        print("No Wave: ON")
    else
        if NoWaveLoop then 
            coroutine.close(NoWaveLoop) 
            NoWaveLoop = nil
        end
        if healthConnection then
            healthConnection:Disconnect()
            healthConnection = nil
        end
        print("No Wave: OFF")
    end
end

-- ============================================
-- CRIAR BOTOES DO MENU
-- ============================================

createToggle("Divino", 45, function() return DivinoActive end, SetDivino)
createToggle("Prismatico", 88, function() return PrismaticoActive end, SetPrismatico)
createToggle("Speed 450", 131, function() return SpeedActive end, SetSpeed)
createToggle("Noclip", 174, function() return NoclipActive end, SetNoclip)
createToggle("No Wave", 217, function() return NoWaveActive end, SetNoWave)
createToggle("Anti-AFK", 260, function() return AntiAFKActive end, SetAntiAFK)

local closeBtn = createButton("Fechar", 315, function()
    menuGui.Enabled = false
end)

-- ============================================
-- CONTROLE DO ICONE
-- ============================================

local menuVisible = true
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
                    iconButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
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

print("Diuary Hub Carregado!")
