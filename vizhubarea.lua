--============================================================
--  VizHub v8.0 | Area 51 Cheat Menu
--  Hotkey: RightShift - menu | Space - infinite jump
--============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

if _G.VizHub_Unload then pcall(_G.VizHub_Unload) end

--============================================================
--  SETTINGS
--============================================================
local Settings = {
    InfiniteAmmo = false,
    RapidFire = false,
    SpeedForce = false,
    SpeedValue = 100,
    JumpHack = false,
    JumpValue = 100,
    InfiniteJump = false,
    ESP_Players = false,
    ESP_Monsters = false,
    ESP_HealthPlayers = false,
    ESP_HealthMonsters = false,
    ESP_Weapons = false,
    NoClip = false,
    Fullbright = false,
    NoFog = false,
    NoShadows = false,
    NoParticles = false,
    NoTextures = false,
    NoPostFX = false,
    NoClouds = false,
    NoGrass = false,
    LowQuality = false,
    ToggleKey = Enum.KeyCode.RightShift
}

local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50

local Connections = {}
local Unloaded = false
local IntroFinished = false

local savedRespawnCFrame = nil
local respawnPending = false

local function Track(conn)
    table.insert(Connections, conn)
    return conn
end

local function isPlayerCharacter(model)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character == model then return true end
    end
    return false
end

local function clearPlayerESP(character)
    if not character then return end
    local h = character:FindFirstChild("ESP_Highlight")
    if h then h:Destroy() end
end

--============================================================
--  KNOWN WEAPONS
--============================================================
local KNOWN_WEAPONS = {
    "m1911", "m14", "desert eagle", "deagle", "colt anaconda", "anaconda",
    "mp5k", "mp5", "p90", "uzi", "uzi1",
    "r870", "m1014", "db shotgun", "spas-12", "spas12", "shotgun",
    "ak-47", "ak47", "ak 47", "m16a2", "m16", "m4a1", "m4", "g36c", "g36",
    "an-94", "an94", "svd", "awp", "sniper",
    "raygun", "ray gun", "mg-42", "mg42", "mg 42", "crossbow",
    "flamethrower", "freeze gun", "freezegun",
    "laser x 1", "laser x 2", "laser x 3", "lx1", "lx2", "lx3",
    "laser x dark", "lxd",
    "rocket launcher", "rpg", "grenade launcher", "m203",
    "gun_gun", "gungun", "mystery box", "weapon", "gun", "knife", "sword",
    "monkey bomb", "ice tripmine", "jack-o' bomb", "landmine"
}

local function isWeaponName(name)
    local n = name:lower()
    for _, w in ipairs(KNOWN_WEAPONS) do
        if n == w or n:find(w, 1, true) then return true end
    end
    return false
end

local MANAGER_WEAPONS = {
    "M14", "MP5K", "R870", "M1014", "M16A2", "AN-94", "G36C", "M4A1",
    "DB Shotgun", "P90", "Desert Eagle", "Colt Anaconda",
    "Flamethrower", "M16A2/M203"
}

--============================================================
--  HEALTH ESP
--============================================================
local espHealthPlayers = {}
local espHealthMonsters = {}

local function removeHealthBar(model, store)
    if not model then return end
    local bar = store[model]
    if bar then bar:Destroy() end
    store[model] = nil
end

local function createHealthBar(model, store, textColor)
    if not model or store[model] then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not hum or not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "VizHub_HealthBar"
    billboard.Size = UDim2.new(0, 140, 0, 34)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 500
    billboard.Adornee = head
    billboard.Parent = head

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0.5, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = textColor
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
    label.Parent = billboard

    local barBG = Instance.new("Frame")
    barBG.Name = "BarBG"
    barBG.Size = UDim2.new(0.9, 0, 0.25, 0)
    barBG.Position = UDim2.new(0.05, 0, 0.6, 0)
    barBG.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    barBG.BorderSizePixel = 0
    barBG.Parent = billboard
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = barBG

    local barFill = Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.new(1, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(30, 220, 30)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBG
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = barFill

    store[model] = billboard
end

local function updateHealthBar(model, store)
    local billboard = store[model]
    if not billboard or not billboard.Parent then return end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local label = billboard:FindFirstChild("Label")
    if label then
        label.Text = "HP: " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
    end
    local barBG = billboard:FindFirstChild("BarBG")
    if barBG then
        local fill = barBG:FindFirstChild("Fill")
        if fill then
            local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            if ratio > 0.5 then
                local t = (ratio - 0.5) * 2
                fill.BackgroundColor3 = Color3.fromRGB(220, 180, 30):Lerp(Color3.fromRGB(30, 220, 30), t)
            else
                local t = ratio * 2
                fill.BackgroundColor3 = Color3.fromRGB(220, 30, 30):Lerp(Color3.fromRGB(220, 180, 30), t)
            end
        end
    end
end

local function clearAllHealthBars(store)
    for model, bar in pairs(store) do
        if bar then bar:Destroy() end
    end
    if store == espHealthPlayers then
        espHealthPlayers = {}
    else
        espHealthMonsters = {}
    end
end

--============================================================
--  WEAPON ESP
--============================================================
local espWeapons = {}

local function isHeldWeapon(obj)
    local parent = obj.Parent
    if parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then
        return true
    end
    if parent and parent:IsA("Backpack") then return true end
    return false
end

local function isWeaponModel(obj)
    if not obj or not obj.Parent then return false end
    if not (obj:IsA("Model") or obj:IsA("Tool") or obj:IsA("Folder")) then return false end
    if isHeldWeapon(obj) then return false end
    if isWeaponName(obj.Name) then
        if obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") then return true end
        if obj:IsA("Tool") then return true end
    end
    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("ClickDetector") then
        if obj:FindFirstChild("Handle") then return true end
    end
    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("ProximityPrompt") then
        if obj:FindFirstChild("Handle") then return true end
    end
    return false
end

local function addWeaponESP(obj)
    if espWeapons[obj] then return end
    local h = Instance.new("Highlight")
    h.Name = "ESP_Weapon"
    h.FillColor = Color3.fromRGB(0, 200, 255)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.4
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = obj
    espWeapons[obj] = h
end

local function removeWeaponESP(obj)
    local h = espWeapons[obj]
    if h then h:Destroy() end
    espWeapons[obj] = nil
end

local function clearAllWeaponESP()
    for obj, h in pairs(espWeapons) do
        if h then h:Destroy() end
    end
    espWeapons = {}
end

local function scanWeapons()
    local seen = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if isWeaponModel(obj) then
            seen[obj] = true
            if not espWeapons[obj] then addWeaponESP(obj) end
        end
    end
    for obj in pairs(espWeapons) do
        if not seen[obj] or not obj.Parent then removeWeaponESP(obj) end
    end
end

Track(workspace.DescendantAdded:Connect(function(obj)
    if not Settings.ESP_Weapons then return end
    task.defer(function()
        if isWeaponModel(obj) then addWeaponESP(obj) end
    end)
end))

Track(workspace.DescendantRemoving:Connect(function(obj)
    if espWeapons[obj] then removeWeaponESP(obj) end
end))

task.spawn(function()
    while not Unloaded do
        task.wait(2)
        if Settings.ESP_Weapons then scanWeapons() end
    end
end)

--============================================================
--  GRAPHICS STORAGE
--============================================================
local gfx = {
    lightingSnapshot = nil,
    shadowOriginals = {},
    hiddenObjects = {},
    originalFogEnd = nil,
    originalFogStart = nil,
    terrainDecoration = nil
}

local function snapshotLighting()
    if gfx.lightingSnapshot then return end
    gfx.lightingSnapshot = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        GlobalShadows = Lighting.GlobalShadows,
        ExposureCompensation = Lighting.ExposureCompensation,
    }
    gfx.originalFogEnd = Lighting.FogEnd
    gfx.originalFogStart = Lighting.FogStart
end

local function restoreLighting()
    if not gfx.lightingSnapshot then return end
    pcall(function()
        Lighting.Brightness = gfx.lightingSnapshot.Brightness
        Lighting.Ambient = gfx.lightingSnapshot.Ambient
        Lighting.OutdoorAmbient = gfx.lightingSnapshot.OutdoorAmbient
        Lighting.ClockTime = gfx.lightingSnapshot.ClockTime
        Lighting.GlobalShadows = gfx.lightingSnapshot.GlobalShadows
        Lighting.ExposureCompensation = gfx.lightingSnapshot.ExposureCompensation
        Lighting.FogEnd = gfx.originalFogEnd or 100000
        Lighting.FogStart = gfx.originalFogStart or 0
    end)
end

local function hideMatching(predicate)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if predicate(obj) and obj.Parent then
            local plr = Players:GetPlayerFromCharacter(obj:FindFirstAncestorOfClass("Model") or obj)
            if not plr or plr == LocalPlayer then
                gfx.hiddenObjects[obj] = obj.Parent
                obj.Parent = nil
            end
        end
    end
end

local function unhideByFilter(filter)
    for obj, parent in pairs(gfx.hiddenObjects) do
        if filter(obj) then
            pcall(function()
                if parent then obj.Parent = parent end
            end)
            gfx.hiddenObjects[obj] = nil
        end
    end
end

--============================================================
--  GUI ROOT
--============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VizHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = game.CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

--============================================================
--  INTRO SPLASH SCREEN
--============================================================
local IntroFrame = Instance.new("Frame")
IntroFrame.Name = "VizHubIntro"
IntroFrame.Size = UDim2.new(1, 0, 1, 0)
IntroFrame.Position = UDim2.new(0, 0, 0, 0)
IntroFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
IntroFrame.BackgroundTransparency = 0
IntroFrame.BorderSizePixel = 0
IntroFrame.ZIndex = 100
IntroFrame.Parent = ScreenGui

-- Огромный логотип VizHub
local IntroLogo = Instance.new("TextLabel")
IntroLogo.Name = "Logo"
IntroLogo.Size = UDim2.new(1, 0, 0, 120)
IntroLogo.Position = UDim2.new(0, 0, 0.35, -60)
IntroLogo.BackgroundTransparency = 1
IntroLogo.Text = "VizHub"
IntroLogo.TextColor3 = Color3.fromRGB(180, 0, 0)
IntroLogo.TextStrokeTransparency = 0
IntroLogo.TextStrokeColor3 = Color3.fromRGB(255, 50, 50)
IntroLogo.Font = Enum.Font.GothamBlack
IntroLogo.TextSize = 96
IntroLogo.TextTransparency = 1
IntroLogo.ZIndex = 101
IntroLogo.Parent = IntroFrame

-- Подзаголовок
local IntroSub = Instance.new("TextLabel")
IntroSub.Name = "Sub"
IntroSub.Size = UDim2.new(1, 0, 0, 30)
IntroSub.Position = UDim2.new(0, 0, 0.35, 65)
IntroSub.BackgroundTransparency = 1
IntroSub.Text = "Area 51  |  Survive & Kill the Killers"
IntroSub.TextColor3 = Color3.fromRGB(220, 220, 220)
IntroSub.Font = Enum.Font.Gotham
IntroSub.TextSize = 18
IntroSub.TextTransparency = 1
IntroSub.ZIndex = 101
IntroSub.Parent = IntroFrame

-- Полоса загрузки (фон)
local IntroBarBG = Instance.new("Frame")
IntroBarBG.Name = "BarBG"
IntroBarBG.Size = UDim2.new(0, 420, 0, 6)
IntroBarBG.Position = UDim2.new(0.5, -210, 0.62, 0)
IntroBarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
IntroBarBG.BorderSizePixel = 0
IntroBarBG.BackgroundTransparency = 1
IntroBarBG.ZIndex = 101
IntroBarBG.Parent = IntroFrame
local introBgCorner = Instance.new("UICorner")
introBgCorner.CornerRadius = UDim.new(1, 0)
introBgCorner.Parent = IntroBarBG

-- Полоса загрузки (заполнение)
local IntroBarFill = Instance.new("Frame")
IntroBarFill.Name = "BarFill"
IntroBarFill.Size = UDim2.new(0, 0, 1, 0)
IntroBarFill.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
IntroBarFill.BorderSizePixel = 0
IntroBarFill.ZIndex = 102
IntroBarFill.Parent = IntroBarBG
local introFillCorner = Instance.new("UICorner")
introFillCorner.CornerRadius = UDim.new(1, 0)
introFillCorner.Parent = IntroBarFill

-- Текст "Loading..."
local IntroLoadText = Instance.new("TextLabel")
IntroLoadText.Name = "LoadText"
IntroLoadText.Size = UDim2.new(1, 0, 0, 20)
IntroLoadText.Position = UDim2.new(0, 0, 0.62, 15)
IntroLoadText.BackgroundTransparency = 1
IntroLoadText.Text = "Loading 0%"
IntroLoadText.TextColor3 = Color3.fromRGB(180, 180, 180)
IntroLoadText.Font = Enum.Font.Gotham
IntroLoadText.TextSize = 14
IntroLoadText.TextTransparency = 1
IntroLoadText.ZIndex = 101
IntroLoadText.Parent = IntroFrame

-- Подсказка "Press any key to skip"
local IntroSkip = Instance.new("TextLabel")
IntroSkip.Name = "Skip"
IntroSkip.Size = UDim2.new(1, 0, 0, 20)
IntroSkip.Position = UDim2.new(0, 0, 0.9, 0)
IntroSkip.BackgroundTransparency = 1
IntroSkip.Text = "Press any key to skip"
IntroSkip.TextColor3 = Color3.fromRGB(120, 120, 120)
IntroSkip.Font = Enum.Font.Gotham
IntroSkip.TextSize = 13
IntroSkip.TextTransparency = 1
IntroSkip.ZIndex = 101
IntroSkip.Parent = IntroFrame

--============================================================
--  Вступление (intro animation)
--============================================================
local introSkipped = false

local function skipIntro()
    if introSkipped or IntroFinished then return end
    introSkipped = true
end

-- Слушатель любой клавиши / клика для пропуска
local skipConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if IntroFinished then return end
    if input.UserInputType == Enum.UserInputType.Keyboard
    or input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        skipIntro()
    end
end)

local function playIntro()
    -- Шаг 1: плавно показываем логотип
    local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    TweenService:Create(IntroLogo, tweenInfo, {
        TextTransparency = 0,
        TextStrokeTransparency = 0,
    }):Play()

    task.wait(0.15)

    TweenService:Create(IntroSub, tweenInfo, {
        TextTransparency = 0,
    }):Play()

    task.wait(0.2)

    TweenService:Create(IntroBarBG, tweenInfo, {
        BackgroundTransparency = 0,
    }):Play()

    task.wait(0.1)

    TweenService:Create(IntroLoadText, tweenInfo, {
        TextTransparency = 0,
    }):Play()

    TweenService:Create(IntroSkip, tweenInfo, {
        TextTransparency = 0,
    }):Play()

    -- Шаг 2: заполняем полосу загрузки
    local duration = 1.6
    local steps = 32
    local stepTime = duration / steps

    for i = 0, steps do
        if introSkipped or Unloaded then break end
        local p = i / steps
        IntroBarFill.Size = UDim2.new(p, 0, 1, 0)
        IntroLoadText.Text = string.format("Loading %d%%", math.floor(p * 100))
        task.wait(stepTime)
    end

    if not introSkipped then
        IntroBarFill.Size = UDim2.new(1, 0, 1, 0)
        IntroLoadText.Text = "Loading 100%"
    end

    task.wait(0.2)

    -- Шаг 3: fade out всего интро
    local fadeOut = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    TweenService:Create(IntroFrame, fadeOut, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(IntroLogo, fadeOut, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
    TweenService:Create(IntroSub, fadeOut, { TextTransparency = 1 }):Play()
    TweenService:Create(IntroBarBG, fadeOut, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(IntroLoadText, fadeOut, { TextTransparency = 1 }):Play()
    TweenService:Create(IntroSkip, fadeOut, { TextTransparency = 1 }):Play()

    task.wait(0.55)

    if not Unloaded then
        IntroFrame:Destroy()
        IntroFinished = true
        if skipConn then
            pcall(function() skipConn:Disconnect() end)
        end
    end
end

-- Запускаем интро в отдельном потоке
task.spawn(playIntro)

--============================================================
--  MAIN MENU GUI
--============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 550, 0, 820)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -410)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BackgroundTransparency = 1
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(180, 0, 0)
MainStroke.Thickness = 2
MainStroke.Transparency = 1
MainStroke.Parent = MainFrame

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -30, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "VizHub  |  Area 51"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 24
TitleLabel.Parent = TitleBar

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, -30, 0, 18)
SubLabel.Position = UDim2.new(0, 20, 0, 34)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "Survive & Kill the Killers"
SubLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 13
SubLabel.Parent = TitleBar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -30, 0, 42)
TabContainer.Position = UDim2.new(0, 15, 0, 70)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.Parent = TabContainer

local function CreateTab(name)
    local Tab = Instance.new("TextButton")
    Tab.Size = UDim2.new(0, 78, 1, 0)
    Tab.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Tab.Text = name
    Tab.TextColor3 = Color3.fromRGB(255, 255, 255)
    Tab.Font = Enum.Font.GothamBold
    Tab.TextSize = 13
    Tab.AutoButtonColor = false
    Tab.Parent = TabContainer
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = Tab
    return Tab
end

local function CreateToggle(parent, text, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    ToggleFrame.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = ToggleFrame

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(0.72, -15, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 15, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = text
    ToggleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.TextSize = 15
    ToggleLabel.Parent = ToggleFrame

    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(0, 80, 0, 30)
    ToggleButton.Position = UDim2.new(1, -95, 0.5, -15)
    ToggleButton.BackgroundColor3 = default and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(60, 60, 60)
    ToggleButton.Text = default and "ON" or "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.TextSize = 14
    ToggleButton.AutoButtonColor = false
    ToggleButton.Parent = ToggleFrame
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = ToggleButton

    local state = default
    Track(ToggleButton.MouseButton1Click:Connect(function()
        state = not state
        ToggleButton.BackgroundColor3 = state and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(60, 60, 60)
        ToggleButton.Text = state and "ON" or "OFF"
        if callback then callback(state) end
    end))
    return ToggleFrame
end

local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 42)
    Btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 15
    Btn.AutoButtonColor = false
    Btn.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = Btn
    Track(Btn.MouseButton1Click:Connect(callback))
    return Btn
end

local function CreateSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 58)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -30, 0, 20)
    label.Position = UDim2.new(0, 15, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Parent = frame

    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, -30, 0, 8)
    barBG.Position = UDim2.new(0, 15, 0, 38)
    barBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barBG.BorderSizePixel = 0
    barBG.Parent = frame
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = barBG

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    fill.BorderSizePixel = 0
    fill.Parent = barBG
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 16, 0, 16)
    handle.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.Text = ""
    handle.AutoButtonColor = false
    handle.Parent = barBG
    local handleCorner = Instance.new("UICorner")
    handleCorner.CornerRadius = UDim.new(1, 0)
    handleCorner.Parent = handle

    local value = default
    local dragging = false

    local function setValue(v)
        v = math.clamp(v, min, max)
        v = math.floor(v * 10 + 0.5) / 10
        value = v
        local p = (v - min) / (max - min)
        fill.Size = UDim2.new(p, 0, 1, 0)
        handle.Position = UDim2.new(p, -8, 0.5, -8)
        label.Text = text .. ": " .. v
        if callback then callback(v) end
    end

    Track(handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end))
    Track(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    Track(UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local mouseX = input.Position.X
            local barAbs = barBG.AbsolutePosition.X
            local barSize = barBG.AbsoluteSize.X
            local p = math.clamp((mouseX - barAbs) / barSize, 0, 1)
            setValue(min + p * (max - min))
        end
    end))

    return {Frame = frame, SetValue = setValue}
end

local Tabs = {
    Player   = CreateTab("Player"),
    Visuals  = CreateTab("Visuals"),
    Manager  = CreateTab("Manager"),
    Admin    = CreateTab("Admin"),
    Graphics = CreateTab("Graphics"),
    Settings = CreateTab("Settings")
}

local ContentY = 125
local ContentH = 820 - ContentY - 20

local function NewContent()
    local f = Instance.new("ScrollingFrame")
    f.Size = UDim2.new(1, -30, 0, ContentH)
    f.Position = UDim2.new(0, 15, 0, ContentY)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.CanvasSize = UDim2.new(0, 0, 0, 0)
    f.AutomaticCanvasSize = Enum.AutomaticSize.Y
    f.ScrollBarThickness = 5
    f.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 0)
    f.Visible = false
    f.Parent = MainFrame
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 10)
    l.Parent = f
    return f
end

local PlayerContent   = NewContent()
local VisualsContent  = NewContent()
local ManagerContent  = NewContent()
local AdminContent    = NewContent()
local GraphicsContent = NewContent()
local SettingsContent = NewContent()

--============================================================
--  INFINITE AMMO V3
--============================================================
local AMMO_KEYWORDS = {
    "ammo", "clip", "mag", "bullet", "reserve",
    "count", "rounds", "shots", "left"
}

local ammoHooked = {}
local ammoConns = {}
local ammoAttrs = {}
local ammoValues = {}

local function isAmmoName(n)
    n = tostring(n):lower()
    for _, k in ipairs(AMMO_KEYWORDS) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function forceAmmoValue(v)
    if not v or not v.Parent then return end
    pcall(function()
        if v:IsA("IntValue") or v:IsA("NumberValue") then
            if v.Value < 999 then v.Value = 999 end
        elseif v:IsA("StringValue") then
            local cur, max = v.Value:match("(%d+)[^%d]+(%d+)")
            if cur then
                if tonumber(cur) and tonumber(cur) < 999 then
                    v.Value = "999/" .. max
                end
            else
                local n = tonumber(v.Value)
                if n and n < 999 then v.Value = "999" end
            end
        end
    end)
end

local function hookAmmoValue(v)
    if ammoHooked[v] then return end
    ammoHooked[v] = true
    table.insert(ammoValues, v)
    local c1 = v:GetPropertyChangedSignal("Value"):Connect(function()
        if Unloaded or not Settings.InfiniteAmmo then return end
        forceAmmoValue(v)
    end)
    ammoConns[v] = {c1}
end

local function hookAmmoAttributes(obj)
    if not obj or ammoAttrs[obj] then return end
    local names = {}
    pcall(function()
        for name, _ in pairs(obj:GetAttributes()) do
            if isAmmoName(name) then
                table.insert(names, name)
            end
        end
    end)
    if #names == 0 then return end
    ammoAttrs[obj] = names
    for _, name in ipairs(names) do
        local c = obj:GetAttributeChangedSignal(name):Connect(function()
            if Unloaded or not Settings.InfiniteAmmo then return end
            pcall(function()
                local val = obj:GetAttribute(name)
                if type(val) == "number" and val < 999 then
                    obj:SetAttribute(name, 999)
                end
            end)
        end)
        table.insert(ammoConns, c)
        pcall(function()
            local val = obj:GetAttribute(name)
            if type(val) == "number" and val < 999 then
                obj:SetAttribute(name, 999)
            end
        end)
    end
end

local function scanAmmoIn(container, depth)
    if not container or depth > 5 then return end
    for _, obj in ipairs(container:GetChildren()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
            if isAmmoName(obj.Name) then
                forceAmmoValue(obj)
                hookAmmoValue(obj)
            end
        end
        pcall(function() hookAmmoAttributes(obj) end)

        if obj:IsA("Tool") or obj:IsA("Folder") or obj:IsA("Model")
        or obj:IsA("ScreenGui") or obj:IsA("Frame") then
            scanAmmoIn(obj, depth + 1)
        end
    end
end

local function runInfiniteAmmo()
    local char = LocalPlayer.Character
    if char then scanAmmoIn(char, 0) end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then scanAmmoIn(bp, 0) end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then scanAmmoIn(pg, 0) end

    for _, obj in ipairs(LocalPlayer:GetChildren()) do
        if obj:IsA("IntValue") or obj:IsA("NumberValue") or obj:IsA("StringValue") then
            if isAmmoName(obj.Name) then
                forceAmmoValue(obj)
                hookAmmoValue(obj)
            end
        end
    end
end

local function clearAmmoHooks()
    for v, conns in pairs(ammoConns) do
        for _, c in ipairs(conns) do
            pcall(function() c:Disconnect() end)
        end
    end
    ammoConns = {}
    ammoHooked = {}
    ammoAttrs = {}
    ammoValues = {}
end

local function hookToolsContainer(container)
    if not container then return end
    Track(container.ChildAdded:Connect(function(child)
        if Unloaded or not Settings.InfiniteAmmo then return end
        if child:IsA("Tool") then
            task.wait(0.05)
            scanAmmoIn(child, 0)
        end
    end))
end

hookToolsContainer(LocalPlayer:FindFirstChild("Backpack"))

Track(LocalPlayer.ChildAdded:Connect(function(child)
    if child.Name == "Backpack" then
        hookToolsContainer(child)
    end
end))

--============================================================
--  RAPID FIRE V2
--============================================================
local rapidFireMouseDown = false
local rapidFireLoopRunning = false
local RAPID_FIRE_INTERVAL = 0.045

local function startRapidFireLoop()
    if rapidFireLoopRunning then return end
    rapidFireLoopRunning = true
    task.spawn(function()
        while not Unloaded and Settings.RapidFire do
            if rapidFireMouseDown then
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChildWhichIsA("Tool")
                    if tool then
                        pcall(function() tool:Activate() end)
                    end
                end
            end
            task.wait(RAPID_FIRE_INTERVAL)
        end
        rapidFireLoopRunning = false
    end)
end

Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rapidFireMouseDown = true
    end
end))

Track(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        rapidFireMouseDown = false
    end
end))

--============================================================
--  WEAPON TELEPORT
--============================================================
local function getWeaponCFrame(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("Model") and obj.PrimaryPart then return obj.PrimaryPart.CFrame end
    local handle = obj:FindFirstChild("Handle")
    if handle and handle:IsA("BasePart") then return handle.CFrame end
    if obj:IsA("Model") then
        local part = obj:FindFirstChildWhichIsA("BasePart")
        if part then return part.CFrame end
    end
    if obj:IsA("Tool") then
        local h = obj:FindFirstChild("Handle")
        if h and h:IsA("BasePart") then return h.CFrame end
    end
    return nil
end

local function findWeaponByName(name)
    local target = name:lower()
    local matches = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Tool")) and not isHeldWeapon(obj) then
            local n = obj.Name:lower()
            if n == target or n:find(target, 1, true) then
                if getWeaponCFrame(obj) then
                    table.insert(matches, obj)
                end
            end
        end
    end
    if #matches == 0 then return nil end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root and #matches > 1 then
        local playerPos = root.Position
        table.sort(matches, function(a, b)
            local ca = getWeaponCFrame(a)
            local cb = getWeaponCFrame(b)
            if not ca then return false end
            if not cb then return true end
            return (ca.Position - playerPos).Magnitude < (cb.Position - playerPos).Magnitude
        end)
    end
    return matches[1]
end

local function teleportToWeapon(weaponName)
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local weapon = findWeaponByName(weaponName)
    if not weapon then return false end
    local cf = getWeaponCFrame(weapon)
    if not cf then return false end
    root.CFrame = CFrame.new(cf.Position + Vector3.new(0, 3, 0))
    return true
end

--============================================================
--  ADMIN
--============================================================
local spectateTarget = nil
local spectateConn = nil

local function getPlayerRoot(plr)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChild("HumanoidRootPart")
end

local function getPlayerHumanoid(plr)
    if not plr or not plr.Character then return nil end
    return plr.Character:FindFirstChildOfClass("Humanoid")
end

local function teleportToPlayer(plr)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return false end
    local targetRoot = getPlayerRoot(plr)
    if not targetRoot then return false end
    myRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(3, 3, 0))
    return true
end

local function stopSpectate()
    local cam = workspace.CurrentCamera
    if cam then
        local myHum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if myHum then cam.CameraSubject = myHum end
    end
    spectateTarget = nil
    if spectateConn then
        pcall(function() spectateConn:Disconnect() end)
        spectateConn = nil
    end
end

local function startSpectate(plr)
    local cam = workspace.CurrentCamera
    if not cam then return false end
    local targetHum = getPlayerHumanoid(plr)
    if not targetHum then return false end
    stopSpectate()
    spectateTarget = plr
    cam.CameraSubject = targetHum
    cam.CameraType = Enum.CameraType.Custom
    spectateConn = RunService.Heartbeat:Connect(function()
        if Unloaded then stopSpectate() return end
        if not spectateTarget or not spectateTarget.Parent then
            stopSpectate() return
        end
        local h = getPlayerHumanoid(spectateTarget)
        if not h or h.Health <= 0 then stopSpectate() end
    end)
    return true
end

local adminPlayerRows = {}
local adminListFrame = nil

local function rebuildAdminList()
    if adminListFrame then adminListFrame:Destroy() end
    adminPlayerRows = {}

    adminListFrame = Instance.new("Frame")
    adminListFrame.Size = UDim2.new(1, 0, 0, 30 + #Players:GetPlayers() * 44)
    adminListFrame.BackgroundTransparency = 1
    adminListFrame.Parent = AdminContent

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.Parent = adminListFrame

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.Text = "Players online: " .. #Players:GetPlayers()
    header.TextColor3 = Color3.fromRGB(255, 100, 100)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Font = Enum.Font.GothamBold
    header.TextSize = 15
    header.Parent = adminListFrame

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 40)
            row.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
            row.Parent = adminListFrame
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(0, 8)
            rc.Parent = row

            local nameLabel = Instance.new("TextLabel")
            nameLabel.Size = UDim2.new(0.45, -10, 1, 0)
            nameLabel.Position = UDim2.new(0, 10, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = plr.Name
            nameLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Font = Enum.Font.Gotham
            nameLabel.TextSize = 14
            nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
            nameLabel.Parent = row

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0, 60, 1, -10)
            tpBtn.Position = UDim2.new(1, -135, 0, 5)
            tpBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 13
            tpBtn.AutoButtonColor = false
            tpBtn.Parent = row
            local tc = Instance.new("UICorner")
            tc.CornerRadius = UDim.new(0, 6)
            tc.Parent = tpBtn

            Track(tpBtn.MouseButton1Click:Connect(function()
                teleportToPlayer(plr)
            end))

            local specBtn = Instance.new("TextButton")
            specBtn.Size = UDim2.new(0, 60, 1, -10)
            specBtn.Position = UDim2.new(1, -70, 0, 5)
            specBtn.BackgroundColor3 = (spectateTarget == plr)
                and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(60, 60, 60)
            specBtn.Text = (spectateTarget == plr) and "Stop" or "Watch"
            specBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            specBtn.Font = Enum.Font.GothamBold
            specBtn.TextSize = 13
            specBtn.AutoButtonColor = false
            specBtn.Parent = row
            local sc = Instance.new("UICorner")
            sc.CornerRadius = UDim.new(0, 6)
            sc.Parent = specBtn

            Track(specBtn.MouseButton1Click:Connect(function()
                if spectateTarget == plr then
                    stopSpectate()
                    for _, r in pairs(adminPlayerRows) do
                        if r.SpecBtn then
                            r.SpecBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                            r.SpecBtn.Text = "Watch"
                        end
                    end
                else
                    if startSpectate(plr) then
                        for _, r in pairs(adminPlayerRows) do
                            if r.SpecBtn then
                                r.SpecBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                                r.SpecBtn.Text = "Watch"
                            end
                        end
                        specBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
                        specBtn.Text = "Stop"
                    end
                end
            end))

            adminPlayerRows[plr] = {Row = row, SpecBtn = specBtn, TpBtn = tpBtn}
        end
    end
end

CreateButton(AdminContent, "Refresh Player List", function()
    rebuildAdminList()
end)

CreateButton(AdminContent, "Stop Spectating", function()
    stopSpectate()
    for _, r in pairs(adminPlayerRows) do
        if r.SpecBtn then
            r.SpecBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            r.SpecBtn.Text = "Watch"
        end
    end
end)

local sepAdmin = Instance.new("Frame")
sepAdmin.Size = UDim2.new(1, 0, 0, 2)
sepAdmin.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
sepAdmin.BorderSizePixel = 0
sepAdmin.Parent = AdminContent

CreateButton(AdminContent, "Kill All Monsters", function()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not isPlayerCharacter(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then hum.Health = 0 end
        end
    end
end)

task.defer(function()
    task.wait(0.5)
    rebuildAdminList()
end)

Track(Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    if Unloaded then return end
    rebuildAdminList()
end))

Track(Players.PlayerRemoving:Connect(function(plr)
    if spectateTarget == plr then stopSpectate() end
    task.wait(0.3)
    if Unloaded then return end
    rebuildAdminList()
end))

--============================================================
--  ESP MONSTERS
--============================================================
local espMonsters = {}

local function isMonster(obj)
    if not obj or not obj.Parent then return false end
    if not obj:IsA("Model") then return false end
    if obj == LocalPlayer.Character then return false end
    if isPlayerCharacter(obj) then return false end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not (obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")) then
        return false
    end
    return true
end

local function addMonsterESP(model)
    if espMonsters[model] then return end
    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight_M"
    h.FillColor = Color3.fromRGB(255, 80, 80)
    h.OutlineColor = Color3.fromRGB(255, 200, 0)
    h.FillTransparency = 0.45
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = model
    espMonsters[model] = h
end

local function removeMonsterESP(model)
    local h = espMonsters[model]
    if h then h:Destroy() end
    espMonsters[model] = nil
end

local function clearAllMonsterESP()
    for model, h in pairs(espMonsters) do
        if h then h:Destroy() end
    end
    espMonsters = {}
end

local function scanMonsters()
    local seen = {}
    for _, obj in ipairs(workspace:GetChildren()) do
        if isMonster(obj) then
            seen[obj] = true
            if not espMonsters[obj] then addMonsterESP(obj) end
        end
        if obj:IsA("Folder") or obj:IsA("Model") then
            for _, c in ipairs(obj:GetChildren()) do
                if isMonster(c) then
                    seen[c] = true
                    if not espMonsters[c] then addMonsterESP(c) end
                end
            end
        end
    end
    for model in pairs(espMonsters) do
        if not seen[model] or not model.Parent then
            removeMonsterESP(model)
        end
    end
end

Track(workspace.DescendantAdded:Connect(function(obj)
    if not Settings.ESP_Monsters then return end
    if obj:IsA("Humanoid") and obj.Parent and isMonster(obj.Parent) then
        addMonsterESP(obj.Parent)
    elseif obj:IsA("Model") and isMonster(obj) then
        addMonsterESP(obj)
    end
end))

Track(workspace.DescendantRemoving:Connect(function(obj)
    if obj:IsA("Model") and espMonsters[obj] then
        removeMonsterESP(obj)
    elseif obj:IsA("Humanoid") and obj.Parent and espMonsters[obj.Parent] then
        removeMonsterESP(obj.Parent)
    end
end))

task.spawn(function()
    while not Unloaded do
        task.wait(1)
        if Settings.ESP_Monsters then scanMonsters() end
    end
end)

--============================================================
--  HEALTH BARS LOOP
--============================================================
task.spawn(function()
    while not Unloaded do
        task.wait(0.5)
        if Settings.ESP_HealthPlayers then
            local alive = {}
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        alive[plr.Character] = true
                        if not espHealthPlayers[plr.Character] then
                            createHealthBar(plr.Character, espHealthPlayers,
                                Color3.fromRGB(100, 255, 100))
                        end
                    end
                end
            end
            for model in pairs(espHealthPlayers) do
                if not alive[model] or not model.Parent then
                    removeHealthBar(model, espHealthPlayers)
                end
            end
        end
        if Settings.ESP_HealthMonsters then
            local alive = {}
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj:IsA("Model") and obj ~= LocalPlayer.Character
                and not isPlayerCharacter(obj) then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        alive[obj] = true
                        if not espHealthMonsters[obj] then
                            createHealthBar(obj, espHealthMonsters,
                                Color3.fromRGB(255, 100, 100))
                        end
                    end
                end
                if obj:IsA("Folder") or obj:IsA("Model") then
                    for _, c in ipairs(obj:GetChildren()) do
                        if c:IsA("Model") and c ~= LocalPlayer.Character
                        and not isPlayerCharacter(c) then
                            local hum = c:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                alive[c] = true
                                if not espHealthMonsters[c] then
                                    createHealthBar(c, espHealthMonsters,
                                        Color3.fromRGB(255, 100, 100))
                                end
                            end
                        end
                    end
                end
            end
            for model in pairs(espHealthMonsters) do
                if not alive[model] or not model.Parent then
                    removeHealthBar(model, espHealthMonsters)
                end
            end
        end
    end
end)

--============================================================
--  FORCE SPEED
--============================================================
local speedVelocity = nil

local function destroySpeedVelocity()
    if speedVelocity then
        pcall(function() speedVelocity:Destroy() end)
        speedVelocity = nil
    end
end

local function updateSpeedVelocity()
    local char = LocalPlayer.Character
    if not char then destroySpeedVelocity() return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then destroySpeedVelocity() return end
    if Settings.SpeedForce then
        if not speedVelocity or speedVelocity.Parent ~= root then
            destroySpeedVelocity()
            speedVelocity = Instance.new("BodyVelocity")
            speedVelocity.Name = "VizHub_Speed"
            speedVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
            speedVelocity.Velocity = Vector3.zero
            speedVelocity.Parent = root
        end
        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0 then
            speedVelocity.Velocity = moveDir * Settings.SpeedValue
        else
            speedVelocity.Velocity = Vector3.zero
        end
    else
        destroySpeedVelocity()
    end
end

--============================================================
--  NOCLIP
--============================================================
local noclipConn = nil
local noclipDescConn = nil
local originalCollide = {}

local function applyNoClipRecursive(character)
    if not character then return end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if part.Name == "HumanoidRootPart" then
                if part.CanCollide then part.CanCollide = false end
            else
                if originalCollide[part] == nil then
                    originalCollide[part] = part.CanCollide
                end
                if part.CanCollide then part.CanCollide = false end
            end
        end
    end
end

local function startNoClip()
    local char = LocalPlayer.Character
    if not char then return end
    originalCollide = {}
    applyNoClipRecursive(char)
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if Unloaded or not Settings.NoClip then return end
        local c = LocalPlayer.Character
        if c then applyNoClipRecursive(c) end
    end)
    if noclipDescConn then noclipDescConn:Disconnect() end
    noclipDescConn = char.DescendantAdded:Connect(function(part)
        if Unloaded or not Settings.NoClip then return end
        if part:IsA("BasePart") then
            if part.Name == "HumanoidRootPart" then
                part.CanCollide = false
            else
                if originalCollide[part] == nil then
                    originalCollide[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    end)
end

local function stopNoClip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    if noclipDescConn then noclipDescConn:Disconnect() noclipDescConn = nil end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.Name == "HumanoidRootPart" then
                    part.CanCollide = false
                elseif originalCollide[part] ~= nil then
                    part.CanCollide = originalCollide[part]
                end
            end
        end
    end
    originalCollide = {}
end

--============================================================
--  INFINITE JUMP
--============================================================
local function tryInfiniteJump()
    if not Settings.InfiniteJump then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.Freefall
    or state == Enum.HumanoidStateType.Jumping
    or state == Enum.HumanoidStateType.Landed then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

--============================================================
--  PLAYER TAB
--============================================================
CreateToggle(PlayerContent, "Infinite Ammo", false, function(s)
    Settings.InfiniteAmmo = s
    if s then
        runInfiniteAmmo()
    else
        clearAmmoHooks()
    end
end)

CreateToggle(PlayerContent, "Rapid Fire (hold LMB)", false, function(s)
    Settings.RapidFire = s
    if s then
        startRapidFireLoop()
    else
        rapidFireMouseDown = false
    end
end)

CreateToggle(PlayerContent, "Force Speed", false, function(s)
    Settings.SpeedForce = s
    if not s then
        destroySpeedVelocity()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = DEFAULT_WALKSPEED end
        end
    end
end)

local speedSlider = CreateSlider(PlayerContent, "Speed", 16, 500, 100, function(v)
    Settings.SpeedValue = v
end)

CreateToggle(PlayerContent, "Jump Power", false, function(s)
    Settings.JumpHack = s
    if not s then
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if not hum.UseJumpPower then hum.UseJumpPower = true end
                hum.JumpPower = DEFAULT_JUMPPOWER
            end
        end
    end
end)

local jumpSlider = CreateSlider(PlayerContent, "Jump", 50, 500, 100, function(v)
    Settings.JumpValue = v
end)

CreateToggle(PlayerContent, "Infinite Jump (Space)", false, function(s)
    Settings.InfiniteJump = s
end)

CreateToggle(PlayerContent, "No Clip", false, function(s)
    Settings.NoClip = s
    if s then startNoClip() else stopNoClip() end
end)

CreateButton(PlayerContent, "Respawn Here", function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    savedRespawnCFrame = root.CFrame
    respawnPending = true
    hum.Health = 0
end)

--============================================================
--  VISUALS TAB
--============================================================
CreateToggle(VisualsContent, "ESP Players", false, function(s)
    Settings.ESP_Players = s
    if not s then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character then clearPlayerESP(plr.Character) end
        end
    end
end)

CreateToggle(VisualsContent, "ESP Monsters", false, function(s)
    Settings.ESP_Monsters = s
    if s then scanMonsters() else clearAllMonsterESP() end
end)

CreateToggle(VisualsContent, "ESP Health Players", false, function(s)
    Settings.ESP_HealthPlayers = s
    if not s then clearAllHealthBars(espHealthPlayers) end
end)

CreateToggle(VisualsContent, "ESP Health Monsters", false, function(s)
    Settings.ESP_HealthMonsters = s
    if not s then clearAllHealthBars(espHealthMonsters) end
end)

CreateToggle(VisualsContent, "ESP Weapons", false, function(s)
    Settings.ESP_Weapons = s
    if s then scanWeapons() else clearAllWeaponESP() end
end)

--============================================================
--  MANAGER TAB
--============================================================
CreateButton(ManagerContent, "Find Nearest Weapon", function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Tool")) and not isHeldWeapon(obj) then
            if isWeaponName(obj.Name) then
                local cf = getWeaponCFrame(obj)
                if cf then
                    local d = (cf.Position - root.Position).Magnitude
                    if d < nearestDist then
                        nearestDist = d
                        nearest = obj
                    end
                end
            end
        end
    end
    if nearest then
        local cf = getWeaponCFrame(nearest)
        if cf then
            root.CFrame = CFrame.new(cf.Position + Vector3.new(0, 3, 0))
        end
    end
end)

local sepM = Instance.new("Frame")
sepM.Size = UDim2.new(1, 0, 0, 2)
sepM.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
sepM.BorderSizePixel = 0
sepM.Parent = ManagerContent

for _, weaponName in ipairs(MANAGER_WEAPONS) do
    CreateButton(ManagerContent, weaponName, function()
        teleportToWeapon(weaponName)
    end)
end

--============================================================
--  GRAPHICS TAB
--============================================================
CreateToggle(GraphicsContent, "Fullbright", false, function(s)
    Settings.Fullbright = s
    if s then
        snapshotLighting()
        Lighting.Brightness = 3
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.ExposureCompensation = 0.2
        Lighting.GlobalShadows = false
    else
        restoreLighting()
    end
end)

CreateToggle(GraphicsContent, "No Fog", false, function(s)
    Settings.NoFog = s
    if s then
        snapshotLighting()
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        if gfx.originalFogEnd then Lighting.FogEnd = gfx.originalFogEnd end
        if gfx.originalFogStart then Lighting.FogStart = gfx.originalFogStart end
    end
end)

CreateToggle(GraphicsContent, "No Shadows", false, function(s)
    Settings.NoShadows = s
    if s then
        pcall(function() Lighting.GlobalShadows = false end)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local parentModel = obj:FindFirstAncestorOfClass("Model")
                if not (parentModel and Players:GetPlayerFromCharacter(parentModel)) then
                    if gfx.shadowOriginals[obj] == nil then
                        gfx.shadowOriginals[obj] = obj.CastShadow
                    end
                    obj.CastShadow = false
                end
            end
        end
    else
        for obj, orig in pairs(gfx.shadowOriginals) do
            if obj and obj.Parent then
                pcall(function() obj.CastShadow = orig end)
            end
        end
        gfx.shadowOriginals = {}
        if gfx.lightingSnapshot then
            pcall(function() Lighting.GlobalShadows = gfx.lightingSnapshot.GlobalShadows end)
        end
    end
end)

CreateToggle(GraphicsContent, "No Particles (FPS Boost)", false, function(s)
    Settings.NoParticles = s
    if s then
        hideMatching(function(obj)
            return obj:IsA("ParticleEmitter")
                or obj:IsA("Smoke")
                or obj:IsA("Fire")
                or obj:IsA("Sparkles")
                or obj:IsA("Trail")
        end)
    else
        unhideByFilter(function(obj)
            return obj:IsA("ParticleEmitter")
                or obj:IsA("Smoke")
                or obj:IsA("Fire")
                or obj:IsA("Sparkles")
                or obj:IsA("Trail")
        end)
    end
end)

CreateToggle(GraphicsContent, "No Textures/Decals (FPS Boost)", false, function(s)
    Settings.NoTextures = s
    if s then
        hideMatching(function(obj)
            return obj:IsA("Decal") or obj:IsA("Texture")
        end)
    else
        unhideByFilter(function(obj)
            return obj:IsA("Decal") or obj:IsA("Texture")
        end)
    end
end)

CreateToggle(GraphicsContent, "No Post-FX (Bloom/Blur/DOF)", false, function(s)
    Settings.NoPostFX = s
    if s then
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("PostEffect")
            or obj:IsA("Atmosphere")
            or obj:IsA("Sky") then
                gfx.hiddenObjects[obj] = obj.Parent
                obj.Parent = nil
            end
        end
    else
        unhideByFilter(function(obj)
            return obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky")
        end)
    end
end)

CreateToggle(GraphicsContent, "No Clouds", false, function(s)
    Settings.NoClouds = s
    if s then
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Clouds") then
                gfx.hiddenObjects[obj] = obj.Parent
                obj.Parent = nil
            end
        end
    else
        unhideByFilter(function(obj)
            return obj:IsA("Clouds")
        end)
    end
end)

CreateToggle(GraphicsContent, "No Grass (Terrain)", false, function(s)
    Settings.NoGrass = s
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    if s then
        if gfx.terrainDecoration == nil then
            pcall(function() gfx.terrainDecoration = terrain.Decoration end)
        end
        pcall(function() terrain.Decoration = false end)
    else
        if gfx.terrainDecoration ~= nil then
            pcall(function() terrain.Decoration = gfx.terrainDecoration end)
        end
    end
end)

CreateToggle(GraphicsContent, "FPS Boost (Low Quality)", false, function(s)
    Settings.LowQuality = s
    pcall(function()
        local UserGameSettings = UserSettings():GetService("UserGameSettings")
        if s then
            UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        else
            UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
        end
    end)
    if s then
        pcall(function() Lighting.GlobalShadows = false end)
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local parentModel = obj:FindFirstAncestorOfClass("Model")
                if not (parentModel and Players:GetPlayerFromCharacter(parentModel)) then
                    if gfx.shadowOriginals[obj] == nil then
                        gfx.shadowOriginals[obj] = obj.CastShadow
                    end
                    obj.CastShadow = false
                end
            end
        end
        hideMatching(function(obj)
            return obj:IsA("ParticleEmitter") or obj:IsA("Smoke")
                or obj:IsA("Fire") or obj:IsA("Sparkles")
        end)
    end
end)

local brightnessSlider = CreateSlider(GraphicsContent, "Brightness", 0, 10, 2, function(v)
    snapshotLighting()
    pcall(function() Lighting.Brightness = v end)
end)

local timeSlider = CreateSlider(GraphicsContent, "Time of Day", 0, 24, 14, function(v)
    snapshotLighting()
    pcall(function() Lighting.ClockTime = v end)
end)

CreateButton(GraphicsContent, "Reset All Graphics", function()
    for obj, parent in pairs(gfx.hiddenObjects) do
        pcall(function()
            if parent then obj.Parent = parent end
        end)
    end
    gfx.hiddenObjects = {}

    for obj, orig in pairs(gfx.shadowOriginals) do
        if obj and obj.Parent then
            pcall(function() obj.CastShadow = orig end)
        end
    end
    gfx.shadowOriginals = {}

    restoreLighting()

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and gfx.terrainDecoration ~= nil then
        pcall(function() terrain.Decoration = gfx.terrainDecoration end)
    end
    gfx.terrainDecoration = nil

    pcall(function()
        local UserGameSettings = UserSettings():GetService("UserGameSettings")
        UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
    end)

    Settings.Fullbright = false
    Settings.NoFog = false
    Settings.NoShadows = false
    Settings.NoParticles = false
    Settings.NoTextures = false
    Settings.NoPostFX = false
    Settings.NoClouds = false
    Settings.NoGrass = false
    Settings.LowQuality = false

    print("[VizHub Graphics] All graphics reset.")
end)

--============================================================
--  UNLOAD HACK
--============================================================
local function UnloadHack()
    if Unloaded then return end
    Unloaded = true

    for _, conn in ipairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}

    if noclipConn then
        pcall(function() noclipConn:Disconnect() end)
        noclipConn = nil
    end
    if noclipDescConn then
        pcall(function() noclipDescConn:Disconnect() end)
        noclipDescConn = nil
    end

    destroySpeedVelocity()
    clearAmmoHooks()
    rapidFireMouseDown = false

    if spectateConn then
        pcall(function() spectateConn:Disconnect() end)
        spectateConn = nil
    end
    spectateTarget = nil
    local cam = workspace.CurrentCamera
    if cam and LocalPlayer.Character then
        local myHum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if myHum then cam.CameraSubject = myHum end
    end

    for obj, parent in pairs(gfx.hiddenObjects) do
        pcall(function()
            if parent then obj.Parent = parent end
        end)
    end
    gfx.hiddenObjects = {}
    for obj, orig in pairs(gfx.shadowOriginals) do
        if obj and obj.Parent then
            pcall(function() obj.CastShadow = orig end)
        end
    end
    gfx.shadowOriginals = {}
    restoreLighting()
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain and gfx.terrainDecoration ~= nil then
        pcall(function() terrain.Decoration = gfx.terrainDecoration end)
    end
    gfx.terrainDecoration = nil
    pcall(function()
        local UserGameSettings = UserSettings():GetService("UserGameSettings")
        UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.Automatic
    end)

    local function cleanContainer(container)
        if not container then return end
        for _, obj in ipairs(container:GetDescendants()) do
            pcall(function()
                if obj:IsA("Highlight") and (obj.Name == "ESP_Highlight"
                or obj.Name == "ESP_Highlight_M"
                or obj.Name == "ESP_Weapon") then
                    obj:Destroy()
                elseif obj:IsA("BillboardGui") and obj.Name == "VizHub_HealthBar" then
                    obj:Destroy()
                elseif obj:IsA("BodyVelocity") and obj.Name == "VizHub_Speed" then
                    obj:Destroy()
                elseif obj:IsA("ScreenGui") and obj.Name == "VizHub" then
                    obj:Destroy()
                end
            end)
        end
    end

    local char = LocalPlayer.Character
    if char then cleanContainer(char) end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then cleanContainer(bp) end
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then cleanContainer(pg) end
    end)
    pcall(function()
        local cg = game:GetService("CoreGui")
        if cg then cleanContainer(cg) end
    end)
    pcall(function() cleanContainer(workspace) end)

    espMonsters = {}
    espHealthPlayers = {}
    espHealthMonsters = {}
    espWeapons = {}

    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            pcall(function()
                hum.WalkSpeed = DEFAULT_WALKSPEED
                if not hum.UseJumpPower then hum.UseJumpPower = true end
                hum.JumpPower = DEFAULT_JUMPPOWER
            end)
        end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function()
                    if part.Name == "HumanoidRootPart" then
                        part.CanCollide = false
                    elseif originalCollide[part] ~= nil then
                        part.CanCollide = originalCollide[part]
                    end
                end)
            end
        end
    end

    originalCollide = {}
    savedRespawnCFrame = nil
    respawnPending = false
    speedVelocity = nil

    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
        ScreenGui = nil
    end

    _G.VizHub_Unload = nil
    print("[VizHub] Fully unloaded - 100% cleanup.")
end

_G.VizHub_Unload = UnloadHack

--============================================================
--  SETTINGS TAB
--============================================================
CreateButton(SettingsContent, "Unload Hack", function() UnloadHack() end)

--============================================================
--  TAB SWITCHING
--============================================================
local tabList = {
    {Tab = Tabs.Player,   Content = PlayerContent},
    {Tab = Tabs.Visuals,  Content = VisualsContent},
    {Tab = Tabs.Manager,  Content = ManagerContent},
    {Tab = Tabs.Admin,    Content = AdminContent},
    {Tab = Tabs.Graphics, Content = GraphicsContent},
    {Tab = Tabs.Settings, Content = SettingsContent}
}

local function SelectTab(index)
    for i, t in ipairs(tabList) do
        t.Content.Visible = (i == index)
        t.Tab.BackgroundColor3 = (i == index) and Color3.fromRGB(180, 0, 0) or Color3.fromRGB(40, 40, 40)
    end
end

for i, t in ipairs(tabList) do
    Track(t.Tab.MouseButton1Click:Connect(function() SelectTab(i) end))
end
SelectTab(1)

--============================================================
--  FADE-IN AFTER INTRO
--============================================================
task.spawn(function()
    while not IntroFinished and not Unloaded do
        task.wait(0.1)
    end
    if Unloaded then return end
    -- Плавно показываем меню
    MainFrame.Visible = true
    local fadeIn = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(MainFrame, fadeIn, { BackgroundTransparency = 0 }):Play()
    TweenService:Create(MainStroke, fadeIn, { Transparency = 0 }):Play()
    task.wait(0.6)
end)

--============================================================
--  RIGHT SHIFT + SPACE
--============================================================
local MenuVisible = true

Track(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if Unloaded then return end
    if not gameProcessed and input.KeyCode == Settings.ToggleKey then
        MenuVisible = not MenuVisible
        ScreenGui.Enabled = MenuVisible
        return
    end
    if input.KeyCode == Enum.KeyCode.Space and Settings.InfiniteJump then
        task.spawn(tryInfiniteJump)
    end
end))

--============================================================
--  MAIN LOOP
--============================================================
Track(RunService.Heartbeat:Connect(function()
    if Unloaded then return end
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    updateSpeedVelocity()

    if Settings.JumpHack then
        if not humanoid.UseJumpPower then humanoid.UseJumpPower = true end
        if humanoid.JumpPower ~= Settings.JumpValue then
            humanoid.JumpPower = Settings.JumpValue
        end
    else
        if not humanoid.UseJumpPower then humanoid.UseJumpPower = true end
        if humanoid.JumpPower ~= DEFAULT_JUMPPOWER then
            humanoid.JumpPower = DEFAULT_JUMPPOWER
        end
    end

    if Settings.InfiniteAmmo then
        for _, v in ipairs(ammoValues) do
            if v.Parent then forceAmmoValue(v) end
        end
    end

    if Settings.ESP_HealthPlayers then
        for model in pairs(espHealthPlayers) do
            if model.Parent then updateHealthBar(model, espHealthPlayers) end
        end
    end

    if Settings.ESP_HealthMonsters then
        for model in pairs(espHealthMonsters) do
            if model.Parent then updateHealthBar(model, espHealthMonsters) end
        end
    end

    if Settings.ESP_Players then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if not plr.Character:FindFirstChild("ESP_Highlight") then
                    local h = Instance.new("Highlight")
                    h.Name = "ESP_Highlight"
                    h.FillColor = Color3.fromRGB(255, 0, 0)
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.FillTransparency = 0.4
                    h.OutlineTransparency = 0
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = plr.Character
                end
            end
        end
    end
end))

--============================================================
--  RESPAWN
--============================================================
Track(LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.5)
    if Unloaded then return end

    if respawnPending and savedRespawnCFrame then
        local root = newChar:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = savedRespawnCFrame
            task.wait(0.2)
            if root.Parent then
                root.CFrame = savedRespawnCFrame
            end
        end
        respawnPending = false
        savedRespawnCFrame = nil
    end

    if spectateTarget then
        local cam = workspace.CurrentCamera
        if cam and newChar then
            local myHum = newChar:FindFirstChildOfClass("Humanoid")
            if myHum then cam.CameraSubject = myHum end
        end
        spectateTarget = nil
        if spectateConn then
            pcall(function() spectateConn:Disconnect() end)
            spectateConn = nil
        end
    end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr.Character then clearPlayerESP(plr.Character) end
    end
    clearAllMonsterESP()
    espHealthPlayers = {}
    espHealthMonsters = {}
    espWeapons = {}
    destroySpeedVelocity()
    originalCollide = {}
    if Settings.NoClip then startNoClip() end
    if Settings.ESP_Weapons then scanWeapons() end
    if Settings.InfiniteAmmo then runInfiniteAmmo() end
end))

print("[VizHub v8.0] Loaded. RightShift - menu, Space - infinite jump.")