-- ═══════════════════════════════════════════════════════════
--  MAJESTY v5.0 — FULL SCRIPT
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local UserSettings = UserSettings()
local UserGameSettings = UserSettings:GetService("UserGameSettings")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera

local LP = Players.LocalPlayer

local CONFIG = {
    Rights = "حقوق Majesty",
    QualityEnabled = true,
    HitboxEnabled = true,
    HitboxSize = Vector3.new(30, 40, 30),
    PulseEnabled = true,
    PulseSpeed = 0.08,
    PulseAmount = 0.04,
    Smoothness = 0.35,
    LabelEnabled = true,
    LabelText = "Majesty",
    FollowEnabled = false,
    FollowDistance = 8,
    FollowSpeed = 0.4,
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(180, 100, 255),
    FPSEnabled = true,
    ShiftLockEnabled = true,
}

local function notify(t, x)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = t or "Majesty", Text = x or "", Duration = 2,
        })
    end)
end

-- QUALITY
local originalLighting = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows, FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart, ExposureCompensation = Lighting.ExposureCompensation,
}

local function applyQuality()
    pcall(function()
        UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        UserGameSettings.GraphicsQualityLevel = 1
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    Lighting.Ambient = Color3.fromRGB(180, 180, 180)
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 160, 160)
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 500
    Lighting.FogStart = 100
    Lighting.FogColor = Color3.fromRGB(180, 180, 180)
    Lighting.ExposureCompensation = -0.3
    for _, c in pairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then c.Density = 0.15; c.Haze = 0; c.Glare = 0
        elseif c:IsA("Clouds") then c.Cover = 0.1; c.Density = 0.1
        elseif c:IsA("BloomEffect") or c:IsA("BlurEffect")
            or c:IsA("ColorCorrectionEffect") or c:IsA("SunRaysEffect")
            or c:IsA("DepthOfFieldEffect") then c.Enabled = false
        end
    end
    task.spawn(function()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CastShadow = false
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                if obj:IsA("MeshPart") then obj.TextureID = "" end
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire")
                or obj:IsA("Smoke") or obj:IsA("Sparkles")
                or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = false
            end
        end
    end)
end

local function removeQuality()
    pcall(function() UserGameSettings.GraphicsQualityLevel = 10 end)
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.FogStart = originalLighting.FogStart
    Lighting.ExposureCompensation = originalLighting.ExposureCompensation
end

-- HITBOX
local hitboxes = {}

local function createHitbox(char, player)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hb = Instance.new("Part")
    hb.Name = "MajestyHB"
    hb.Shape = Enum.PartType.Block
    hb.Size = Vector3.new(1, 1, 1)
    hb.Transparency = 1
    hb.CanCollide = false
    hb.CanTouch = true
    hb.CanQuery = true
    hb.Massless = true
    hb.Anchored = true
    hb.CastShadow = false
    hb.Material = Enum.Material.SmoothPlastic
    hb.CFrame = hrp.CFrame
    hb.Parent = Workspace
    hb.Touched:Connect(function(other)
        if other and other.Parent and other.Parent ~= char then
            local orig = hb.Size
            TweenService:Create(hb, TweenInfo.new(0.08), {Size = orig * 1.3}):Play()
            task.delay(0.15, function()
                if hb and hb.Parent then
                    TweenService:Create(hb, TweenInfo.new(0.12), {Size = orig}):Play()
                end
            end)
        end
    end)
    hitboxes[player] = {part = hb, phase = math.random() * math.pi * 2}
end

local function updateHitbox(player)
    local data = hitboxes[player]
    if not data then return end
    local hb = data.part
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then hb.CanTouch = false return end
    local size = Vector3.new(
        hrp.Size.X + CONFIG.HitboxSize.X,
        hrp.Size.Y + CONFIG.HitboxSize.Y,
        hrp.Size.Z + CONFIG.HitboxSize.Z
    )
    if CONFIG.PulseEnabled then
        data.phase = data.phase + CONFIG.PulseSpeed
        size = size * (1 + math.sin(data.phase) * CONFIG.PulseAmount)
    end
    hb.CFrame = hb.CFrame:Lerp(CFrame.new(hrp.Position), CONFIG.Smoothness)
    hb.Size = hb.Size:Lerp(size, CONFIG.Smoothness)
    hb.CanTouch = true
end

local function removeHitbox(player)
    if hitboxes[player] then hitboxes[player].part:Destroy() hitboxes[player] = nil end
end

local function setupPlayer(p)
    if p == LP then return end
    if p.Character then createHitbox(p.Character, p) end
    p.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        removeHitbox(p)
        createHitbox(c, p)
    end)
end

local function enableAllHitboxes()
    for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
end

local function disableAllHitboxes()
    for p, _ in pairs(hitboxes) do removeHitbox(p) end
end

enableAllHitboxes()
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removeHitbox)

RunService.RenderStepped:Connect(function()
    if not CONFIG.HitboxEnabled then return end
    for p in pairs(hitboxes) do pcall(updateHitbox, p) end
end)

-- ESP BOX
local espGui = Instance.new("ScreenGui")
espGui.Name = "MajestyESP"
espGui.ResetOnSpawn = false
espGui.IgnoreGuiInset = true
espGui.Parent = LP:WaitForChild("PlayerGui")

local espBoxes = {}

local function createESPBox(player)
    local frame = Instance.new("Frame")
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = espGui

    local function line(name)
        local l = Instance.new("Frame")
        l.Name = name
        l.BackgroundColor3 = CONFIG.ESPColor
        l.BorderSizePixel = 0
        l.Parent = frame
        return l
    end

    local top = line("Top")
    local bottom = line("Bottom")
    local left = line("Left")
    local right = line("Right")

    espBoxes[player] = {frame = frame, top = top, bottom = bottom, left = left, right = right}
end

local function updateESPBox(player)
    local data = espBoxes[player]
    if not data then return end
    if not CONFIG.ESPEnabled then data.frame.Visible = false return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then data.frame.Visible = false return end
    local head = char:FindFirstChild("Head")
    if not head then data.frame.Visible = false return end

    local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
    local rootPos, rootOnScreen = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

    if not headOnScreen or not rootOnScreen then data.frame.Visible = false return end

    local topY = headPos.Y
    local botY = rootPos.Y
    local x = headPos.X
    local h = botY - topY
    local w = h * 0.5

    data.frame.Visible = true
    data.frame.Position = UDim2.new(0, x - w / 2, 0, topY)
    data.frame.Size = UDim2.new(0, w, 0, h)

    local thickness = 1.5
    data.top.Size = UDim2.new(1, 0, 0, thickness)
    data.top.Position = UDim2.new(0, 0, 0, 0)
    data.bottom.Size = UDim2.new(1, 0, 0, thickness)
    data.bottom.Position = UDim2.new(0, 0, 1, -thickness)
    data.left.Size = UDim2.new(0, thickness, 1, 0)
    data.left.Position = UDim2.new(0, 0, 0, 0)
    data.right.Size = UDim2.new(0, thickness, 1, 0)
    data.right.Position = UDim2.new(1, -thickness, 0, 0)

    for _, l in pairs({data.top, data.bottom, data.left, data.right}) do
        l.BackgroundColor3 = CONFIG.ESPColor
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP then createESPBox(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LP then createESPBox(p) end end)
Players.PlayerRemoving:Connect(function(p)
    if espBoxes[p] then espBoxes[p].frame:Destroy() espBoxes[p] = nil end
end)

RunService.RenderStepped:Connect(function()
    for p in pairs(espBoxes) do pcall(updateESPBox, p) end
end)

-- AUTO FOLLOW
local currentTarget = nil
local lastTargetSearch = 0
local savedWalkSpeed = nil

local function getMyChar()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return char, hrp, hum
end

local function getPlayerRoot(player)
    if not player or player == LP then return nil end
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end
    return hrp, hum
end

local function findNearestEnemy()
    local _, myHrp = getMyChar()
    if not myHrp then return nil end
    local nearest, nd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local root = getPlayerRoot(p)
            if root then
                local d = (root.Position - myHrp.Position).Magnitude
                if d < nd then nd = d nearest = p end
            end
        end
    end
    return nearest
end

local function isMoving()
    local _, _, hum = getMyChar()
    if not hum then return false end
    return hum.MoveDirection.Magnitude > 0.1
end

task.spawn(function()
    task.wait(2)
    local _, _, hum = getMyChar()
    if hum then savedWalkSpeed = hum.WalkSpeed end
end)

RunService.Heartbeat:Connect(function()
    local myChar, myHrp, myHum = getMyChar()
    if not myChar then return end
    if not CONFIG.FollowEnabled then
        if savedWalkSpeed and myHum.WalkSpeed ~= savedWalkSpeed then
            myHum.WalkSpeed = savedWalkSpeed
        end
        return
    end
    if isMoving() then
        if savedWalkSpeed then myHum.WalkSpeed = savedWalkSpeed end
        return
    end
    local now = tick()
    if now - lastTargetSearch > 0.4 or not currentTarget then
        lastTargetSearch = now
        currentTarget = findNearestEnemy()
    end
    if not currentTarget then return end
    local targetRoot = getPlayerRoot(currentTarget)
    if not targetRoot then currentTarget = nil return end
    local myPos = myHrp.Position
    local targetPos = targetRoot.Position
    local dir = targetPos - myPos
    local flatDir = Vector3.new(dir.X, 0, dir.Z)
    local dist = flatDir.Magnitude
    if savedWalkSpeed then
        myHum.WalkSpeed = savedWalkSpeed * 2
    else
        myHum.WalkSpeed = math.max(myHum.WalkSpeed, 30)
    end
    if dist <= CONFIG.FollowDistance then
        myHum:Move(Vector3.new(0, 0, 0), false)
        return
    end
    myHum:Move(flatDir.Unit, false)
    local lookCF = CFrame.new(myPos, myPos + flatDir.Unit)
    myHrp.CFrame = myHrp.CFrame:Lerp(lookCF, CONFIG.FollowSpeed)
end)

-- LABEL
local labelGui = Instance.new("ScreenGui")
labelGui.Name = "MajestyLabel"
labelGui.ResetOnSpawn = false
labelGui.IgnoreGuiInset = true
labelGui.Parent = LP:WaitForChild("PlayerGui")

local labelFrame = Instance.new("Frame")
labelFrame.Size = UDim2.new(0, 300, 0, 60)
labelFrame.Position = UDim2.new(0.5, 0, 0, 15)
labelFrame.AnchorPoint = Vector2.new(0.5, 0)
labelFrame.BackgroundTransparency = 1
labelFrame.Parent = labelGui

local glow2 = Instance.new("TextLabel")
glow2.Size = UDim2.new(1, 0, 1, 0)
glow2.BackgroundTransparency = 1
glow2.Text = CONFIG.LabelText
glow2.TextColor3 = Color3.fromRGB(180, 100, 255)
glow2.TextSize = 40
glow2.Font = Enum.Font.GothamBlack
glow2.TextTransparency = 0.8
glow2.TextXAlignment = Enum.TextXAlignment.Center
glow2.TextYAlignment = Enum.TextYAlignment.Center
glow2.Parent = labelFrame

local glow1 = Instance.new("TextLabel")
glow1.Size = UDim2.new(1, 0, 1, 0)
glow1.BackgroundTransparency = 1
glow1.Text = CONFIG.LabelText
glow1.TextColor3 = Color3.fromRGB(180, 100, 255)
glow1.TextSize = 34
glow1.Font = Enum.Font.GothamBlack
glow1.TextTransparency = 0.5
glow1.TextXAlignment = Enum.TextXAlignment.Center
glow1.TextYAlignment = Enum.TextYAlignment.Center
glow1.Parent = labelFrame

local mainText = Instance.new("TextLabel")
mainText.Size = UDim2.new(1, 0, 1, 0)
mainText.BackgroundTransparency = 1
mainText.Text = CONFIG.LabelText
mainText.TextColor3 = Color3.fromRGB(255, 255, 255)
mainText.TextSize = 28
mainText.Font = Enum.Font.GothamBlack
mainText.TextXAlignment = Enum.TextXAlignment.Center
mainText.TextYAlignment = Enum.TextYAlignment.Center
mainText.Parent = labelFrame

local labelStroke = Instance.new("UIStroke")
labelStroke.Color = Color3.fromRGB(0, 0, 0)
labelStroke.Thickness = 2
labelStroke.Parent = mainText

task.spawn(function()
    while labelGui and labelGui.Parent do
        local t = (math.sin(tick() * 2) + 1) / 2
        glow2.TextTransparency = 0.6 + t * 0.3
        glow1.TextTransparency = 0.3 + t * 0.3
        task.wait(0.03)
    end
end)

-- FPS
local fpsGui = Instance.new("ScreenGui")
fpsGui.Name = "MajestyFPS"
fpsGui.ResetOnSpawn = false
fpsGui.IgnoreGuiInset = true
fpsGui.Parent = LP:WaitForChild("PlayerGui")

local fpsFrame = Instance.new("Frame")
fpsFrame.Size = UDim2.new(0, 80, 0, 30)
fpsFrame.Position = UDim2.new(1, -90, 0, 15)
fpsFrame.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
fpsFrame.BackgroundTransparency = 0.3
fpsFrame.BorderSizePixel = 0
fpsFrame.Active = true
fpsFrame.Draggable = true
fpsFrame.Visible = CONFIG.FPSEnabled
fpsFrame.Parent = fpsGui

local fpsCorner = Instance.new("UICorner")
fpsCorner.CornerRadius = UDim.new(0, 8)
fpsCorner.Parent = fpsFrame

local fpsStroke = Instance.new("UIStroke")
fpsStroke.Color = Color3.fromRGB(140, 80, 240)
fpsStroke.Thickness = 1.5
fpsStroke.Transparency = 0.2
fpsStroke.Parent = fpsFrame

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(1, 0, 1, 0)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "FPS: 60"
fpsLabel.TextColor3 = Color3.fromRGB(200, 180, 240)
fpsLabel.TextSize = 14
fpsLabel.Font = Enum.Font.GothamBold
fpsLabel.Parent = fpsFrame

task.spawn(function()
    local frames = 0
    local lastTime = tick()
    while fpsGui and fpsGui.Parent do
        RunService.RenderStepped:Wait()
        frames = frames + 1
        local now = tick()
        if now - lastTime >= 1 then
            local fps = math.floor(frames / (now - lastTime))
            fpsLabel.Text = "FPS: " .. fps
            if fps >= 50 then
                fpsLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
            elseif fps >= 30 then
                fpsLabel.TextColor3 = Color3.fromRGB(255, 200, 60)
            else
                fpsLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
            frames = 0
            lastTime = now
        end
    end
end)

-- SHIFT LOCK
local shiftGui = Instance.new("ScreenGui")
shiftGui.Name = "MajestyShift"
shiftGui.ResetOnSpawn = false
shiftGui.IgnoreGuiInset = true
shiftGui.Parent = LP:WaitForChild("PlayerGui")

local shiftBtn = Instance.new("TextButton")
shiftBtn.Size = UDim2.new(0, 60, 0, 60)
shiftBtn.Position = UDim2.new(0.5, 0, 0.5, 0)
shiftBtn.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
shiftBtn.BackgroundTransparency = 0.3
shiftBtn.BorderSizePixel = 0
shiftBtn.Text = "🔒"
shiftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
shiftBtn.TextSize = 24
shiftBtn.Font = Enum.Font.GothamBold
shiftBtn.Active = true
shiftBtn.Draggable = true
shiftBtn.Visible = CONFIG.ShiftLockEnabled
shiftBtn.Parent = shiftGui

local shiftCorner = Instance.new("UICorner")
shiftCorner.CornerRadius = UDim.new(1, 0)
shiftCorner.Parent = shiftBtn

local shiftStroke = Instance.new("UIStroke")
shiftStroke.Color = Color3.fromRGB(140, 80, 240)
shiftStroke.Thickness = 2
shiftStroke.Transparency = 0.2
shiftStroke.Parent = shiftBtn

local shiftActive = false

shiftBtn.MouseButton1Click:Connect(function()
    shiftActive = not shiftActive
    if shiftActive then
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        shiftBtn.BackgroundColor3 = Color3.fromRGB(140, 80, 240)
    else
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        shiftBtn.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
    end
end)

-- HEADLESS + KORBLOX + CHARME
local function applyHeadless(enable)
    local char = LP.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    if enable then
        head.Transparency = 1
        for _, d in pairs(head:GetChildren()) do
            if d:IsA("Decal") then d.Transparency = 1 end
        end
    else
        head.Transparency = 0
        for _, d in pairs(head:GetChildren()) do
            if d:IsA("Decal") then d.Transparency = 0 end
        end
    end
end

local function applyKorblox(enable)
    local char = LP.Character
    if not char then return end
    local rightLeg = char:FindFirstChild("Right Leg")
    if not rightLeg then return end
    if enable then
        rightLeg.Transparency = 1
    else
        rightLeg.Transparency = 0
    end
end

local function applyCharMe()
    local char = LP.Character
    if not char then return end
    char.Archivable = true
    local clone = char:Clone()
    clone.Name = "MajestyClone"
    clone.Parent = Workspace
    clone:MoveTo(char.HumanoidRootPart.Position + Vector3.new(3, 0, 0))
    task.delay(3, function()
        if clone then clone:Destroy() end
    end)
end

-- MENU
local gui = Instance.new("ScreenGui")
gui.Name = "MajestyMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LP:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Size = UDim2.new(0.9, 0, 0.85, 0)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3 = Color3.fromRGB(15, 10, 25)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Visible = false
panel.Parent = gui

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 14)
pc.Parent = panel

local ps = Instance.new("UIStroke")
ps.Color = Color3.fromRGB(140, 80, 240)
ps.Thickness = 1.5
ps.Transparency = 0.2
ps.Parent = panel

local pg = Instance.new("UIGradient")
pg.Rotation = 135
pg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 12, 45)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 5, 18)),
})
pg.Parent = panel

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 44)
topBar.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.Parent = panel

local tbc = Instance.new("UICorner")
tbc.CornerRadius = UDim.new(0, 14)
tbc.Parent = topBar

local logoBox = Instance.new("Frame")
logoBox.Size = UDim2.new(0, 28, 0, 28)
logoBox.Position = UDim2.new(0, 12, 0.5, -14)
logoBox.BackgroundColor3 = Color3.fromRGB(140, 80, 240)
logoBox.BorderSizePixel = 0
logoBox.Parent = topBar

local lc = Instance.new("UICorner")
lc.CornerRadius = UDim.new(0, 6)
lc.Parent = logoBox

local logoText = Instance.new("TextLabel")
logoText.Size = UDim2.new(1, 0, 1, 0)
logoText.BackgroundTransparency = 1
logoText.Text = "M"
logoText.TextColor3 = Color3.fromRGB(255, 255, 255)
logoText.TextSize = 14
logoText.Font = Enum.Font.GothamBlack
logoText.Parent = logoBox

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -160, 0, 20)
titleLbl.Position = UDim2.new(0, 48, 0, 5)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "MAJESTY v5.0"
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.TextSize = 14
titleLbl.Font = Enum.Font.GothamBlack
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topBar

local subLbl = Instance.new("TextLabel")
subLbl.Size = UDim2.new(1, -160, 0, 14)
subLbl.Position = UDim2.new(0, 48, 0, 24)
subLbl.BackgroundTransparency = 1
subLbl.Text = CONFIG.Rights
subLbl.TextColor3 = Color3.fromRGB(160, 120, 240)
subLbl.TextSize = 10
subLbl.Font = Enum.Font.Gotham
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.Parent = topBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 80)
closeBtn.BackgroundTransparency = 0.2
closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 12
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = topBar

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 6)
cc.Parent = closeBtn

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 32)
tabBar.Position = UDim2.new(0, 8, 0, 50)
tabBar.BackgroundColor3 = Color3.fromRGB(12, 8, 22)
tabBar.BackgroundTransparency = 0.4
tabBar.BorderSizePixel = 0
tabBar.Parent = panel

local tabBarCorner = Instance.new("UICorner")
tabBarCorner.CornerRadius = UDim.new(0, 8)
tabBarCorner.Parent = tabBar

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Parent = tabBar

local tabPad = Instance.new("UIPadding")
tabPad.PaddingLeft = UDim.new(0, 4)
tabPad.PaddingRight = UDim.new(0, 4)
tabPad.Parent = tabBar

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -16, 1, -94)
content.Position = UDim2.new(0, 8, 0, 88)
content.BackgroundTransparency = 1
content.Parent = panel

local tabButtons = {}
local activePage = nil

local function switchPage(page)
    if activePage then activePage.Visible = false end
    page.Visible = true
    activePage = page
end

local function createPage()
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(140, 80, 240)
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = content
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = page
    return page
end

local function createTabButton(text, page)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.19, 0, 0, 26)
    btn.BackgroundColor3 = Color3.fromRGB(30, 18, 50)
    btn.BackgroundTransparency = 0.4
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 180, 240)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = tabBar
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = btn
    table.insert(tabButtons, { btn = btn, page = page })
    return btn
end

local function highlightTab(active)
    for _, item in ipairs(tabButtons) do
        if item.btn == active then
            TweenService:Create(item.btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(140, 80, 240),
                BackgroundTransparency = 0.1,
                TextColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        else
            TweenService:Create(item.btn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(30, 18, 50),
                BackgroundTransparency = 0.4,
                TextColor3 = Color3.fromRGB(200, 180, 240)
            }):Play()
        end
    end
end

local pageMain = createPage()
local pageVisual = createPage()
local pageHitbox = createPage()
local pageFollow = createPage()
local pageSettings = createPage()

local btnMain = createTabButton("الرئيسية", pageMain)
local btnVisual = createTabButton("المظهر", pageVisual)
local btnHitbox = createTabButton("الهيتبوكس", pageHitbox)
local btnFollow = createTabButton("المتابعة", pageFollow)
local btnSettings = createTabButton("إعدادات", pageSettings)

btnMain.MouseButton1Click:Connect(function() switchPage(pageMain) highlightTab(btnMain) end)
btnVisual.MouseButton1Click:Connect(function() switchPage(pageVisual) highlightTab(btnVisual) end)
btnHitbox.MouseButton1Click:Connect(function() switchPage(pageHitbox) highlightTab(btnHitbox) end)
btnFollow.MouseButton1Click:Connect(function() switchPage(pageFollow) highlightTab(btnFollow) end)
btnSettings.MouseButton1Click:Connect(function() switchPage(pageSettings) highlightTab(btnSettings) end)

switchPage(pageMain)
highlightTab(btnMain)

local function makeSection(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(160, 110, 240)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.Parent = parent
end

local function makeToggle(parent, text, default, callback, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = Color3.fromRGB(22, 14, 40)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Color = default and Color3.fromRGB(140, 80, 240) or Color3.fromRGB(60, 40, 100)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(230, 220, 255)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 36, 0, 20)
    box.Position = UDim2.new(1, -50, 0.5, -10)
    box.BackgroundColor3 = default and Color3.fromRGB(140, 80, 240) or Color3.fromRGB(40, 28, 65)
    box.BorderSizePixel = 0
    box.Parent = btn

    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = box

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 14, 0, 14)
    dot.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    dot.BorderSizePixel = 0
    dot.Parent = box

    local dc2 = Instance.new("UICorner")
    dc2.CornerRadius = UDim.new(1, 0)
    dc2.Parent = dot

    local state = default

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(box, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(140, 80, 240) or Color3.fromRGB(40, 28, 65)
        }):Play()
        TweenService:Create(dot, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        TweenService:Create(stroke, TweenInfo.new(0.15), {
            Color = state and Color3.fromRGB(140, 80, 240) or Color3.fromRGB(60, 40, 100)
        }):Play()
        pcall(callback, state)
    end)
end

local function makeSlider(parent, text, default, minV, maxV, callback, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 54)
    container.BackgroundColor3 = Color3.fromRGB(22, 14, 40)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.LayoutOrder = order
    container.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = container

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 40, 100)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 20)
    lbl.Position = UDim2.new(0, 14, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(230, 220, 255)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = container

    local val = Instance.new("TextLabel")
    val.Size = UDim2.new(0, 40, 0, 20)
    val.Position = UDim2.new(1, -50, 0, 4)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.TextColor3 = Color3.fromRGB(160, 110, 240)
    val.TextSize = 12
    val.Font = Enum.Font.GothamBold
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.Parent = container

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -28, 0, 6)
    bg.Position = UDim2.new(0, 14, 0, 34)
    bg.BackgroundColor3 = Color3.fromRGB(40, 28, 65)
    bg.BorderSizePixel = 0
    bg.Parent = container

    local bgc = Instance.new("UICorner")
    bgc.CornerRadius = UDim.new(1, 0)
    bgc.Parent = bg

    local ratio = (default - minV) / (maxV - minV)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(ratio, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(140, 80, 240)
    fill.BorderSizePixel = 0
    fill.Parent = bg

    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = fill

    local dragging = false

    local function update()
        local mx = UserInputService:GetMouseLocation().X
        local px = bg.AbsolutePosition.X
        local w = bg.AbsoluteSize.X
        local r = math.clamp((mx - px) / w, 0, 1)
        local v = math.floor(minV + r * (maxV - minV))
        fill.Size = UDim2.new(r, 0, 1, 0)
        val.Text = tostring(v)
        pcall(callback, v)
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update()
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            update()
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local function makeButton(parent, text, callback, order, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 30, 110)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.LayoutOrder = order
    btn.Parent = parent

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(140, 80, 240)
    s.Thickness = 1.5
    s.Transparency = 0.3
    s.Parent = btn

    btn.MouseButton1Click:Connect(function() pcall(callback) end)
end

-- PAGE MAIN
makeSection(pageMain, "الحالة العامة", 1)
makeToggle(pageMain, "الجودة المنخفضة", CONFIG.QualityEnabled, function(s)
    CONFIG.QualityEnabled = s
    if s then applyQuality() else removeQuality() end
    notify("Majesty", s and "الجودة: شغال" or "الجودة: موقف")
end, 2)
makeToggle(pageMain, "الهيتبوكس", CONFIG.HitboxEnabled, function(s)
    CONFIG.HitboxEnabled = s
    if s then enableAllHitboxes() else disableAllHitboxes() end
end, 3)
makeToggle(pageMain, "النبض", CONFIG.PulseEnabled, function(s) CONFIG.PulseEnabled = s end, 4)
makeToggle(pageMain, "الاسم", CONFIG.LabelEnabled, function(s)
    CONFIG.LabelEnabled = s
    labelGui.Enabled = s
end, 5)
makeSection(pageMain, "إضافات", 6)
makeToggle(pageMain, "FPS Counter", CONFIG.FPSEnabled, function(s)
    CONFIG.FPSEnabled = s
    fpsFrame.Visible = s
end, 7)
makeToggle(pageMain, "ESP Box", CONFIG.ESPEnabled, function(s)
    CONFIG.ESPEnabled = s
    notify("Majesty", s and "ESP: شغال" or "ESP: موقف")
end, 8)
makeToggle(pageMain, "ShiftLock Button", CONFIG.ShiftLockEnabled, function(s)
    CONFIG.ShiftLockEnabled = s
    shiftBtn.Visible = s
end, 9)

-- PAGE VISUAL
makeSection(pageVisual, "المظهر", 1)
makeToggle(pageVisual, "Headless", false, function(s)
    applyHeadless(s)
end, 2)
makeToggle(pageVisual, "Korblox", false, function(s)
    applyKorblox(s)
end, 3)
makeButton(pageVisual, "CharMe (نسخة من شخصيتي)", function()
    applyCharMe()
    notify("Majesty", "CharMe: شغال")
end, 4, Color3.fromRGB(80, 50, 140))
makeButton(pageVisual, "إظهار اسمي", function()
    notify("Majesty", "اسمك: " .. LP.Name)
end, 5, Color3.fromRGB(60, 40, 120))

-- PAGE HITBOX
makeSection(pageHitbox, "حجم الهيتبوكس", 1)
makeSlider(pageHitbox, "العرض", CONFIG.HitboxSize.X, 0, 100, function(v)
    CONFIG.HitboxSize = Vector3.new(v, CONFIG.HitboxSize.Y, CONFIG.HitboxSize.Z)
end, 2)
makeSlider(pageHitbox, "الطول", CONFIG.HitboxSize.Y, 0, 100, function(v)
    CONFIG.HitboxSize = Vector3.new(CONFIG.HitboxSize.X, v, CONFIG.HitboxSize.Z)
end, 3)
makeSlider(pageHitbox, "العمق", CONFIG.HitboxSize.Z, 0, 100, function(v)
    CONFIG.HitboxSize = Vector3.new(CONFIG.HitboxSize.X, CONFIG.HitboxSize.Y, v)
end, 4)
makeSection(pageHitbox, "الحركة", 5)
makeSlider(pageHitbox, "سرعة النبض", 8, 1, 20, function(v) CONFIG.PulseSpeed = v / 100 end, 6)
makeSlider(pageHitbox, "قوة النبض", 4, 1, 20, function(v) CONFIG.PulseAmount = v / 100 end, 7)
makeSlider(pageHitbox, "النعومة", 35, 5, 95, function(v) CONFIG.Smoothness = v / 100 end, 8)

-- PAGE FOLLOW
makeSection(pageFollow, "المتابعة التلقائية", 1)
makeToggle(pageFollow, "تفعيل المتابعة", CONFIG.FollowEnabled, function(s)
    CONFIG.FollowEnabled = s
    if not s then currentTarget = nil end
    notify("Majesty", s and "المتابعة: شغال" or "المتابعة: موقف")
end, 2)
makeSection(pageFollow, "الإعدادات", 3)
makeSlider(pageFollow, "المسافة", CONFIG.FollowDistance, 2, 30, function(v)
    CONFIG.FollowDistance = v
end, 4)
makeSlider(pageFollow, "سرعة الالتفاف", 40, 10, 100, function(v)
    CONFIG.FollowSpeed = v / 100
end, 5)
makeSection(pageFollow, "أوضاع جاهزة", 6)
makeButton(pageFollow, "الوضع العادي", function()
    CONFIG.FollowDistance = 10
    CONFIG.FollowSpeed = 0.3
    notify("Majesty", "الوضع: عادي")
end, 7, Color3.fromRGB(80, 40, 140))
makeButton(pageFollow, "الوضع السريع", function()
    CONFIG.FollowDistance = 6
    CONFIG.FollowSpeed = 0.5
    notify("Majesty", "الوضع: سريع")
end, 8, Color3.fromRGB(100, 50, 160))
makeButton(pageFollow, "الوضع فلك", function()
    CONFIG.FollowDistance = 4
    CONFIG.FollowSpeed = 0.7
    notify("Majesty", "الوضع: فلك")
end, 9, Color3.fromRGB(120, 60, 180))

-- PAGE SETTINGS
makeSection(pageSettings, "الإعدادات", 1)
makeButton(pageSettings, "إعادة تعيين الكل", function()
    CONFIG.HitboxSize = Vector3.new(30, 40, 30)
    CONFIG.PulseSpeed = 0.08
    CONFIG.PulseAmount = 0.04
    CONFIG.Smoothness = 0.35
    CONFIG.FollowDistance = 8
    CONFIG.FollowSpeed = 0.4
    notify("Majesty", "تم إعادة التعيين")
end, 2, Color3.fromRGB(120, 40, 60))
makeButton(pageSettings, "إخفاء المنيو", function()
    panel.Visible = false
end, 3, Color3.fromRGB(50, 40, 70))
makeSection(pageSettings, "ESP Color", 4)
makeButton(pageSettings, "ESP بنفسجي", function()
    CONFIG.ESPColor = Color3.fromRGB(180, 100, 255)
end, 5, Color3.fromRGB(100, 50, 180))
makeButton(pageSettings, "ESP أحمر", function()
    CONFIG.ESPColor = Color3.fromRGB(255, 60, 60)
end, 6, Color3.fromRGB(180, 50, 50))
makeButton(pageSettings, "ESP أخضر", function()
    CONFIG.ESPColor = Color3.fromRGB(60, 255, 60)
end, 7, Color3.fromRGB(50, 180, 50))

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 70)
info.BackgroundColor3 = Color3.fromRGB(22, 14, 40)
info.BackgroundTransparency = 0.3
info.BorderSizePixel = 0
info.Text = "Majesty v5.0\n" .. CONFIG.Rights .. "\nاضغط M لفتح القائمة"
info.TextColor3 = Color3.fromRGB(180, 140, 240)
info.TextSize = 12
info.Font = Enum.Font.Gotham
info.LayoutOrder = 8
info.Parent = pageSettings

local ic = Instance.new("UICorner")
ic.CornerRadius = UDim.new(0, 8)
ic.Parent = info

-- OPEN BUTTON
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(0, 15, 0.5, -25)
openBtn.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
openBtn.BorderSizePixel = 0
openBtn.Text = "M"
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.TextSize = 18
openBtn.Font = Enum.Font.GothamBlack
openBtn.Active = true
openBtn.Draggable = true
openBtn.Parent = gui

local os2 = Instance.new("UIStroke")
os2.Color = Color3.fromRGB(140, 80, 240)
os2.Thickness = 2
os2.Transparency = 0.1
os2.Parent = openBtn

local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(1, 0)
oc.Parent = openBtn

local og = Instance.new("UIGradient")
og.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 100, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 40, 180)),
})
og.Rotation = 45
og.Parent = openBtn

local isOpen = false

openBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    panel.Visible = isOpen
end)

closeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    panel.Visible = false
end)

if CONFIG.QualityEnabled then applyQuality() end

notify("Majesty v5.0", "اضغط M لفتح القائمة")
