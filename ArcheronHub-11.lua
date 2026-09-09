-- ╔══════════════════════════════════════╗
-- ║        ARCHERON HUB v1.1             ║
-- ║     99 Nights in The Forest          ║
-- ╚══════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local lp = Players.LocalPlayer

-- ══════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════
local CONFIG = {
    farmDelay        = 0.15,
    teleportOffset   = CFrame.new(0, 0, -4),
    teleportWait     = 3.0,  -- detik tunggu setelah klik teleport
}

-- ══════════════════════════════════════
--  MAP DATA
--  worldIndex = index folder World0/World1/dst
--  npcs = list NPC di ClientEnemyVisuals untuk map ini
-- ══════════════════════════════════════
local MAPS = {
    [0] = {
        name       = "Lobby Arena",
        worldIndex = 0,
        npcs       = {},
    },
    [1] = {
        name       = "Ninja Village",
        worldIndex = 1,
        npcs       = {
            -- Ganti/tambah sesuai nama di ClientEnemyVisuals
            { name = "Sabuze", label = "Sabuze" },
            -- { name = "NinjaRed",  label = "Ninja Red"  },
            -- { name = "NinjaBoss", label = "Ninja Boss" },
        },
    },
    [2] = {
        name       = "Namek City",
        worldIndex = 2,
        npcs       = {
            -- { name = "NamekA", label = "Namek A" },
        },
    },
    [3] = {
        name       = "Wano Island",
        worldIndex = 3,
        npcs       = {
            -- { name = "SamuraiBlue", label = "Samurai Blue" },
            -- { name = "WanoBoss",    label = "Wano Boss"    },
        },
    },
}

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local State = {
    farmEnabled  = false,
    selectedMap  = 1,
    selectedNPC  = nil,
    targetMode   = "nearest",
    farmLoop     = nil,
    teleporting  = false,
}

-- ══════════════════════════════════════
--  HELPER: GET CHAR
-- ══════════════════════════════════════
local function getChar()
    local char = lp.Character
    if not char then return nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart")
end

-- ══════════════════════════════════════
--  DETECT ISLAND VIA GUI BUTTON
--  Cek WorldX > Teleport button text
--  "RESPAWN" = player sedang di island itu
-- ══════════════════════════════════════
local function getCurrentIsland()
    local ok, result = pcall(function()
        local worlds = lp.PlayerGui.Windows.Teleport.Main.Worlds
        for _, worldFolder in pairs(worlds:GetChildren()) do
            -- WorldFolder name = "World0", "World1", dst
            local teleBtn = worldFolder:FindFirstChild("Teleport")
            if teleBtn then
                local btnText = ""
                -- Cari TextLabel / TextButton di dalamnya
                for _, child in pairs(teleBtn:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        local t = child.Text:upper()
                        if t:find("RESPAWN") then
                            -- Ambil index dari nama folder (World0 -> 0)
                            local idx = tonumber(worldFolder.Name:match("%d+"))
                            return idx
                        end
                    end
                end
            end
        end
        return nil
    end)
    if ok then return result end
    return nil
end

-- ══════════════════════════════════════
--  CEK APAKAH PLAYER SUDAH DI ISLAND
-- ══════════════════════════════════════
local function isPlayerAtMap(mapID)
    local mapData = MAPS[mapID]
    if not mapData then return false end
    local current = getCurrentIsland()
    if current == nil then return false end
    return current == mapData.worldIndex
end

-- ══════════════════════════════════════
--  TELEPORT KE ISLAND VIA GUI BUTTON
--  Klik button "TELEPORT!" di WorldX
-- ══════════════════════════════════════
local function teleportToIsland(mapID)
    local mapData = MAPS[mapID]
    if not mapData then return false end

    print("[Archeron] Teleport ke " .. mapData.name)
    State.teleporting = true

    local ok = pcall(function()
        local worldFolder = lp.PlayerGui.Windows.Teleport.Main.Worlds
            :FindFirstChild("World" .. mapData.worldIndex)
        if not worldFolder then
            error("WorldFolder tidak ketemu: World" .. mapData.worldIndex)
        end

        -- Cari button teleport (bukan respawn)
        local teleBtn = worldFolder:FindFirstChild("Teleport")
        if not teleBtn then
            error("Teleport button tidak ketemu")
        end

        -- Klik button
        local fireBtn = teleBtn:FindFirstChildWhichIsA("TextButton", true)
            or teleBtn:FindFirstChildWhichIsA("ImageButton", true)
        if fireBtn then
            fireBtn.MouseButton1Click:Fire()
        else
            -- Fallback: fire click event langsung
            teleBtn:FindFirstChildOfClass("TextButton").MouseButton1Click:Fire()
        end
    end)

    if not ok then
        -- Fallback: pakai RemoteEvent asli
        warn("[Archeron] GUI teleport gagal, pakai RemoteEvent fallback")
        local Event = game:GetService("ReplicatedStorage"):FindFirstChild("BridgeNet2")
            and game:GetService("ReplicatedStorage").BridgeNet2.dataRemoteEvent
        if Event then
            Event:FireServer({mapData.worldIndex, "\xF5"})
        end
    end

    task.wait(CONFIG.teleportWait)
    State.teleporting = false

    -- Verifikasi apakah berhasil
    if isPlayerAtMap(mapID) then
        print("[Archeron] Berhasil di " .. mapData.name)
        return true
    else
        warn("[Archeron] Mungkin belum sampai, lanjut farm aja...")
        return true -- tetap lanjut
    end
end

-- ══════════════════════════════════════
--  AMBIL ENEMIES
--  Sumber: ClientEnemyVisuals (visual client)
--  Verifikasi model: Worlds[mapID].Enemies[npcName]
--  Kalau model gaada di Worlds = enemy mati, skip
-- ══════════════════════════════════════
local function getEnemies(mapID)
    local enemies = {}

    -- ClientEnemyVisuals = sumber CFrame (responsif, selalu update)
    local visualFolder = workspace:FindFirstChild("ClientEnemyVisuals")
    if not visualFolder then return enemies end

    -- Worlds[mapID].Enemies = sumber "masih hidup / ada" check
    local worldStr   = tostring(mapID)
    local worldFolder = workspace:FindFirstChild("Worlds")
        and workspace.Worlds:FindFirstChild(worldStr)
    local enemyFolder = worldFolder and worldFolder:FindFirstChild("Enemies")

    local mapData = MAPS[mapID]
    if not mapData then return enemies end

    for _, visualMob in pairs(visualFolder:GetChildren()) do
        -- Filter nama sesuai pilihan NPC / semua NPC map
        local matchNPC = false
        if State.selectedNPC and State.selectedNPC ~= "" then
            matchNPC = (visualMob.Name == State.selectedNPC)
        else
            for _, npcData in pairs(mapData.npcs) do
                if visualMob.Name == npcData.name then
                    matchNPC = true
                    break
                end
            end
        end

        if matchNPC then
            local visualHRP = visualMob:FindFirstChild("HumanoidRootPart")
            if visualHRP then
                -- Verifikasi enemy masih ada di server-side (Worlds folder)
                local serverAlive = false
                if enemyFolder then
                    -- Cek apakah ada model dengan nama sama di Worlds.Enemies
                    for _, serverMob in pairs(enemyFolder:GetChildren()) do
                        if serverMob.Name == visualMob.Name then
                            local hum = serverMob:FindFirstChildOfClass("Humanoid")
                            if hum and hum.Health > 0 then
                                serverAlive = true
                            end
                            break
                        end
                    end
                else
                    -- Kalau Worlds folder ga ketemu, fallback ke Humanoid di visual
                    local hum = visualMob:FindFirstChildOfClass("Humanoid")
                    serverAlive = (hum and hum.Health > 0)
                end

                if serverAlive then
                    table.insert(enemies, {
                        model = visualMob,
                        hrp   = visualHRP,
                    })
                end
            end
        end
    end

    return enemies
end

-- ══════════════════════════════════════
--  PILIH TARGET
-- ══════════════════════════════════════
local function selectTarget(enemies)
    if #enemies == 0 then return nil end
    local _, playerHRP = getChar()

    if State.targetMode == "nearest" and playerHRP then
        local closest, minDist = nil, math.huge
        for _, e in pairs(enemies) do
            local d = (e.hrp.Position - playerHRP.Position).Magnitude
            if d < minDist then minDist = d; closest = e end
        end
        return closest

    elseif State.targetMode == "lowestHP" then
        -- Ambil HP dari Worlds folder buat akurasi
        local worldStr    = tostring(State.selectedMap)
        local worldFolder = workspace:FindFirstChild("Worlds")
            and workspace.Worlds:FindFirstChild(worldStr)
        local enemyFolder = worldFolder and worldFolder:FindFirstChild("Enemies")

        local target, minHP = nil, math.huge
        for _, e in pairs(enemies) do
            local hp = math.huge
            if enemyFolder then
                local serverMob = enemyFolder:FindFirstChild(e.model.Name)
                local hum = serverMob and serverMob:FindFirstChildOfClass("Humanoid")
                if hum then hp = hum.Health end
            end
            if hp < minHP then minHP = hp; target = e end
        end
        return target

    elseif State.targetMode == "highestHP" then
        local worldStr    = tostring(State.selectedMap)
        local worldFolder = workspace:FindFirstChild("Worlds")
            and workspace.Worlds:FindFirstChild(worldStr)
        local enemyFolder = worldFolder and worldFolder:FindFirstChild("Enemies")

        local target, maxHP = nil, -math.huge
        for _, e in pairs(enemies) do
            local hp = 0
            if enemyFolder then
                local serverMob = enemyFolder:FindFirstChild(e.model.Name)
                local hum = serverMob and serverMob:FindFirstChildOfClass("Humanoid")
                if hum then hp = hum.Health end
            end
            if hp > maxHP then maxHP = hp; target = e end
        end
        return target
    end

    return enemies[1]
end

-- ══════════════════════════════════════
--  TELEPORT KE ENEMY (CFrame langsung)
-- ══════════════════════════════════════
local function teleportToEnemy(target)
    local _, hrp = getChar()
    if not hrp then return end
    -- Double check model masih ada sebelum teleport
    if not target or not target.hrp or not target.hrp.Parent then return end
    hrp.CFrame = target.hrp.CFrame * CONFIG.teleportOffset
end

-- ══════════════════════════════════════
--  FARM LOOP
--  Heartbeat = secepet mungkin
--  Kalau gaada target = skip (diem)
--  Kalau ada target = langsung CFrame
-- ══════════════════════════════════════
local function startFarmLoop()
    if State.farmLoop then State.farmLoop:Disconnect() end

    State.farmLoop = RunService.Heartbeat:Connect(function()
        if not State.farmEnabled or State.teleporting then return end
        local _, hrp = getChar()
        if not hrp then return end

        local enemies = getEnemies(State.selectedMap)
        local target  = selectTarget(enemies)

        if target then
            -- Ada target → langsung teleport CFrame
            teleportToEnemy(target)
        end
        -- Gaada target → diem, tunggu respawn, loop jalan terus
    end)
end

local function stopFarmLoop()
    if State.farmLoop then
        State.farmLoop:Disconnect()
        State.farmLoop = nil
    end
    State.farmEnabled = false
end

-- ══════════════════════════════════════
--  TOGGLE FARM (dipanggil GUI)
-- ══════════════════════════════════════
function ToggleFarm(enabled)
    State.farmEnabled = enabled
    if not enabled then
        stopFarmLoop()
        print("[Archeron] Farm stopped")
        return
    end

    local mapData = MAPS[State.selectedMap]
    print("[Archeron] Farm start | Map: " .. (mapData and mapData.name or "?") ..
          " | NPC: " .. (State.selectedNPC or "All") ..
          " | Mode: " .. State.targetMode)

    task.spawn(function()
        -- Cek dulu player di island mana
        local currentIsland = getCurrentIsland()
        print("[Archeron] Island saat ini: " .. tostring(currentIsland))

        if currentIsland ~= nil and currentIsland == (mapData and mapData.worldIndex) then
            print("[Archeron] Udah di island yang bener, langsung farm!")
            startFarmLoop()
        else
            print("[Archeron] Beda island, teleport dulu...")
            local success = teleportToIsland(State.selectedMap)
            if State.farmEnabled then
                startFarmLoop()
            end
        end
    end)
end

function SetMap(mapID)
    State.selectedMap = mapID
    State.selectedNPC = nil
end

function SetNPC(npcName)
    State.selectedNPC = (npcName ~= "" and npcName or nil)
end

function SetTargetMode(mode)
    State.targetMode = mode
end

function GetMapNPCs(mapID)
    return MAPS[mapID] and MAPS[mapID].npcs or {}
end

-- ══════════════════════════════════════
--  GUI BUILDER HELPERS
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ArcheronHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = lp.PlayerGui

-- MAIN HUB FRAME
local Hub = Instance.new("Frame")
Hub.Name = "Hub"
Hub.Size = UDim2.new(0, 360, 0, 430)
Hub.Position = UDim2.new(0.5, -180, 0.5, -215)
Hub.BackgroundColor3 = Color3.fromRGB(14, 18, 32)
Hub.BorderSizePixel = 0
Hub.Active = true
Hub.Parent = ScreenGui
Instance.new("UICorner", Hub).CornerRadius = UDim.new(0, 13)
local HubStroke = Instance.new("UIStroke", Hub)
HubStroke.Color = Color3.fromRGB(255,255,255)
HubStroke.Transparency = 0.88
HubStroke.Thickness = 1

-- TOPBAR
local Topbar = Instance.new("Frame")
Topbar.Size = UDim2.new(1, 0, 0, 40)
Topbar.BackgroundColor3 = Color3.fromRGB(255,255,255)
Topbar.BackgroundTransparency = 0.94
Topbar.BorderSizePixel = 0
Topbar.Active = true
Topbar.Parent = Hub
Instance.new("UICorner", Topbar).CornerRadius = UDim.new(0, 13)

local Logo = Instance.new("TextLabel", Topbar)
Logo.Size = UDim2.new(0, 28, 0, 28)
Logo.Position = UDim2.new(0, 8, 0.5, -14)
Logo.BackgroundColor3 = Color3.fromRGB(255,255,255)
Logo.BorderSizePixel = 0
Logo.Text = "Ar"
Logo.TextColor3 = Color3.fromRGB(14,18,32)
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 11
Instance.new("UICorner", Logo).CornerRadius = UDim.new(0, 8)

local HubTitle = Instance.new("TextLabel", Topbar)
HubTitle.Size = UDim2.new(0, 110, 0, 16)
HubTitle.Position = UDim2.new(0, 42, 0, 5)
HubTitle.BackgroundTransparency = 1
HubTitle.Text = "Archeron Hub"
HubTitle.TextColor3 = Color3.fromRGB(255,255,255)
HubTitle.Font = Enum.Font.GothamBold
HubTitle.TextSize = 12
HubTitle.TextXAlignment = Enum.TextXAlignment.Left

local HubSub = Instance.new("TextLabel", Topbar)
HubSub.Size = UDim2.new(0, 160, 0, 12)
HubSub.Position = UDim2.new(0, 42, 0, 22)
HubSub.BackgroundTransparency = 1
HubSub.Text = "99 Nights in The Forest"
HubSub.TextColor3 = Color3.fromRGB(255,255,255)
HubSub.TextTransparency = 0.65
HubSub.Font = Enum.Font.Gotham
HubSub.TextSize = 9
HubSub.TextXAlignment = Enum.TextXAlignment.Left

-- Island indicator di topbar
local IslandIndicator = Instance.new("TextLabel", Topbar)
IslandIndicator.Size = UDim2.new(0, 90, 0, 14)
IslandIndicator.Position = UDim2.new(1, -140, 0.5, -7)
IslandIndicator.BackgroundColor3 = Color3.fromRGB(74,158,255)
IslandIndicator.BackgroundTransparency = 0.85
IslandIndicator.BorderSizePixel = 0
IslandIndicator.Text = "📍 Detecting..."
IslandIndicator.TextColor3 = Color3.fromRGB(74,158,255)
IslandIndicator.Font = Enum.Font.GothamBold
IslandIndicator.TextSize = 8
Instance.new("UICorner", IslandIndicator).CornerRadius = UDim.new(0, 5)

local MinBtn = Instance.new("TextButton", Topbar)
MinBtn.Size = UDim2.new(0, 18, 0, 18)
MinBtn.Position = UDim2.new(1, -42, 0.5, -9)
MinBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
MinBtn.BackgroundTransparency = 0.82
MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.Text = "−"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 12
MinBtn.BorderSizePixel = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1,0)

local CloseBtn = Instance.new("TextButton", Topbar)
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Position = UDim2.new(1, -20, 0.5, -9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255,74,106)
CloseBtn.BackgroundTransparency = 0.7
CloseBtn.TextColor3 = Color3.fromRGB(255,106,133)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 10
CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1,0)

-- SIDEBAR
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 108, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(11,14,26)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Hub
local SideStroke = Instance.new("UIStroke", Sidebar)
SideStroke.Color = Color3.fromRGB(255,255,255)
SideStroke.Transparency = 0.94

local function makeNavBtn(icon, label)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = ""

    local bar = Instance.new("Frame", btn)
    bar.Size = UDim2.new(0, 2, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(74,158,255)
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0

    local ico = Instance.new("TextLabel", btn)
    ico.Size = UDim2.new(0, 18, 1, 0)
    ico.Position = UDim2.new(0, 10, 0, 0)
    ico.BackgroundTransparency = 1
    ico.Text = icon
    ico.TextColor3 = Color3.fromRGB(255,255,255)
    ico.TextTransparency = 0.55
    ico.Font = Enum.Font.Gotham
    ico.TextSize = 15

    local txt = Instance.new("TextLabel", btn)
    txt.Size = UDim2.new(1, -32, 1, 0)
    txt.Position = UDim2.new(0, 32, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = Color3.fromRGB(255,255,255)
    txt.TextTransparency = 0.55
    txt.Font = Enum.Font.Gotham
    txt.TextSize = 11
    txt.TextXAlignment = Enum.TextXAlignment.Left

    return btn, bar, txt, ico
end

local SidePadTop = Instance.new("Frame", Sidebar)
SidePadTop.Size = UDim2.new(1,0,0,6)
SidePadTop.BackgroundTransparency = 1
local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Padding = UDim.new(0,2)

local NavMain,     NavMainBar,     NavMainTxt,     NavMainIco     = makeNavBtn("⚔", "Main")
local NavGamemode, NavGamemodeBar, NavGamemodeTxt, NavGamemodeIco = makeNavBtn("🛡", "Gamemode")
local NavSettings, NavSettingsBar, NavSettingsTxt, NavSettingsIco = makeNavBtn("⚙", "Settings")

-- user frame
local UserFrame = Instance.new("Frame", Sidebar)
UserFrame.Size = UDim2.new(1,0,0,34)
UserFrame.BackgroundTransparency = 1
UserFrame.BorderSizePixel = 0
UserFrame.LayoutOrder = 99

local UAv = Instance.new("Frame", UserFrame)
UAv.Size = UDim2.new(0,22,0,22)
UAv.Position = UDim2.new(0,8,0.5,-11)
UAv.BackgroundColor3 = Color3.fromRGB(255,255,255)
UAv.BackgroundTransparency = 0.85
UAv.BorderSizePixel = 0
Instance.new("UICorner",UAv).CornerRadius = UDim.new(1,0)

local UName = Instance.new("TextLabel", UserFrame)
UName.Size = UDim2.new(1,-36,1,0)
UName.Position = UDim2.new(0,34,0,0)
UName.BackgroundTransparency = 1
UName.Text = lp.Name
UName.TextColor3 = Color3.fromRGB(255,255,255)
UName.TextTransparency = 0.6
UName.Font = Enum.Font.Gotham
UName.TextSize = 9
UName.TextXAlignment = Enum.TextXAlignment.Left
UName.TextTruncate = Enum.TextTruncate.AtEnd

-- PANEL
local Panel = Instance.new("ScrollingFrame")
Panel.Size = UDim2.new(1,-108,1,-40)
Panel.Position = UDim2.new(0,108,0,40)
Panel.BackgroundTransparency = 1
Panel.BorderSizePixel = 0
Panel.ScrollBarThickness = 2
Panel.ScrollBarImageColor3 = Color3.fromRGB(74,158,255)
Panel.Parent = Hub
local PanelLayout = Instance.new("UIListLayout", Panel)
PanelLayout.Padding = UDim.new(0,5)
PanelLayout.SortOrder = Enum.SortOrder.LayoutOrder
local PanelPad = Instance.new("UIPadding", Panel)
PanelPad.PaddingTop = UDim.new(0,10)
PanelPad.PaddingLeft = UDim.new(0,10)
PanelPad.PaddingRight = UDim.new(0,10)
PanelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Panel.CanvasSize = UDim2.new(0,0,0,PanelLayout.AbsoluteContentSize.Y+20)
end)

-- ══════════════════════════════════════
--  UI COMPONENT FACTORIES
-- ══════════════════════════════════════
local function makeLabel(parent, text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,0,14)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextTransparency = 0.72
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or 0
    lbl.Parent = parent
    return lbl
end

local function makeSep(parent, order)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1,0,0,1)
    s.BackgroundColor3 = Color3.fromRGB(255,255,255)
    s.BackgroundTransparency = 0.92
    s.BorderSizePixel = 0
    s.LayoutOrder = order or 0
    s.Parent = parent
    return s
end

local function makeToggleRow(parent, labelText, order, onToggle)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,32)
    row.BackgroundColor3 = Color3.fromRGB(255,255,255)
    row.BackgroundTransparency = 0.96
    row.BorderSizePixel = 0
    row.LayoutOrder = order or 0
    row.Parent = parent
    Instance.new("UICorner",row).CornerRadius = UDim.new(0,7)

    local lbl = Instance.new("TextLabel",row)
    lbl.Size = UDim2.new(1,-50,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextTransparency = 0.18
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame",row)
    track.Size = UDim2.new(0,30,0,16)
    track.Position = UDim2.new(1,-40,0.5,-8)
    track.BackgroundColor3 = Color3.fromRGB(255,255,255)
    track.BackgroundTransparency = 0.82
    track.BorderSizePixel = 0
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("Frame",track)
    knob.Size = UDim2.new(0,11,0,11)
    knob.Position = UDim2.new(0,2,0.5,-5.5)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BackgroundTransparency = 0.55
    knob.BorderSizePixel = 0
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local isOn = false
    local stroke = nil

    local function setToggle(v)
        isOn = v
        if isOn then
            track.BackgroundColor3 = Color3.fromRGB(74,158,255)
            track.BackgroundTransparency = 0.65
            if not stroke then
                stroke = Instance.new("UIStroke",track)
                stroke.Color = Color3.fromRGB(74,158,255)
                stroke.Transparency = 0.2
            end
            knob.Position = UDim2.new(1,-13,0.5,-5.5)
            knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            knob.BackgroundTransparency = 0
        else
            track.BackgroundColor3 = Color3.fromRGB(255,255,255)
            track.BackgroundTransparency = 0.82
            if stroke then stroke:Destroy(); stroke = nil end
            knob.Position = UDim2.new(0,2,0.5,-5.5)
            knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            knob.BackgroundTransparency = 0.55
        end
        if onToggle then onToggle(isOn) end
    end

    local btn = Instance.new("TextButton",row)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.MouseButton1Click:Connect(function() setToggle(not isOn) end)

    return row, setToggle, function() return isOn end
end

local function makeDropdown(parent, labelText, options, order, onChange)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1,0,0,32)
    wrap.BackgroundColor3 = Color3.fromRGB(255,255,255)
    wrap.BackgroundTransparency = 0.96
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = order or 0
    wrap.ClipsDescendants = false
    wrap.Parent = parent
    Instance.new("UICorner",wrap).CornerRadius = UDim.new(0,7)

    local lbl = Instance.new("TextLabel",wrap)
    lbl.Size = UDim2.new(0.45,0,1,0)
    lbl.Position = UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextTransparency = 0.18
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel",wrap)
    valLbl.Size = UDim2.new(0.45,-5,1,0)
    valLbl.Position = UDim2.new(0.5,0,0,0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = options[1] and options[1].label or "—"
    valLbl.TextColor3 = Color3.fromRGB(74,158,255)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 10
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    local arrow = Instance.new("TextLabel",wrap)
    arrow.Size = UDim2.new(0,18,1,0)
    arrow.Position = UDim2.new(1,-20,0,0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▾"
    arrow.TextColor3 = Color3.fromRGB(74,158,255)
    arrow.Font = Enum.Font.Gotham
    arrow.TextSize = 12

    local list = Instance.new("Frame",wrap)
    list.Size = UDim2.new(1,0,0,0)
    list.Position = UDim2.new(0,0,1,4)
    list.BackgroundColor3 = Color3.fromRGB(10,14,25)
    list.BorderSizePixel = 0
    list.Visible = false
    list.ZIndex = 20
    Instance.new("UICorner",list).CornerRadius = UDim.new(0,7)
    local listStroke = Instance.new("UIStroke",list)
    listStroke.Color = Color3.fromRGB(74,158,255)
    listStroke.Transparency = 0.55
    local listLayout = Instance.new("UIListLayout",list)

    local selectedVal = options[1] and options[1].value or nil
    local isOpen = false

    local function closeList()
        isOpen = false
        list.Visible = false
        arrow.Text = "▾"
    end

    local function buildList(opts)
        for _, c in pairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in pairs(opts) do
            local item = Instance.new("TextButton",list)
            item.Size = UDim2.new(1,0,0,28)
            item.BackgroundTransparency = 1
            item.BorderSizePixel = 0
            item.Text = opt.label
            item.TextColor3 = Color3.fromRGB(255,255,255)
            item.TextTransparency = 0.15
            item.Font = Enum.Font.Gotham
            item.TextSize = 10
            item.ZIndex = 21
            item.MouseEnter:Connect(function()
                item.BackgroundColor3 = Color3.fromRGB(74,158,255)
                item.BackgroundTransparency = 0.82
            end)
            item.MouseLeave:Connect(function()
                item.BackgroundTransparency = 1
            end)
            item.MouseButton1Click:Connect(function()
                selectedVal = opt.value
                valLbl.Text = opt.label
                closeList()
                if onChange then onChange(opt.value, opt.label) end
            end)
        end
        list.Size = UDim2.new(1,0,0,#opts*28)
    end

    buildList(options)

    local togBtn = Instance.new("TextButton",wrap)
    togBtn.Size = UDim2.new(1,0,1,0)
    togBtn.BackgroundTransparency = 1
    togBtn.Text = ""
    togBtn.ZIndex = 5
    togBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        list.Visible = isOpen
        arrow.Text = isOpen and "▴" or "▾"
    end)

    local function updateOptions(newOpts)
        buildList(newOpts)
        if newOpts[1] then
            selectedVal = newOpts[1].value
            valLbl.Text = newOpts[1].label
            if onChange then onChange(newOpts[1].value, newOpts[1].label) end
        else
            selectedVal = nil
            valLbl.Text = "—"
        end
    end

    return wrap, updateOptions, function() return selectedVal end
end

local function makeActionBtn(parent, text, color, order, onClick)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,30)
    btn.BackgroundColor3 = color
    btn.BackgroundTransparency = 0.87
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = color
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.LayoutOrder = order or 0
    btn.Parent = parent
    Instance.new("UICorner",btn).CornerRadius = UDim.new(0,7)
    local s = Instance.new("UIStroke",btn)
    s.Color = color
    s.Transparency = 0.55
    if onClick then btn.MouseButton1Click:Connect(onClick) end
    return btn
end

local function makeSliderRow(parent, labelText, minVal, maxVal, defaultVal, order, onChange)
    local wrap = Instance.new("Frame")
    wrap.Size = UDim2.new(1,0,0,44)
    wrap.BackgroundColor3 = Color3.fromRGB(255,255,255)
    wrap.BackgroundTransparency = 0.96
    wrap.BorderSizePixel = 0
    wrap.LayoutOrder = order or 0
    wrap.Parent = parent
    Instance.new("UICorner",wrap).CornerRadius = UDim.new(0,7)

    local lbl = Instance.new("TextLabel",wrap)
    lbl.Size = UDim2.new(1,-10,0,18)
    lbl.Position = UDim2.new(0,10,0,4)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255,255,255)
    lbl.TextTransparency = 0.18
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Text = labelText .. ": " .. tostring(defaultVal)

    local track = Instance.new("Frame",wrap)
    track.Size = UDim2.new(1,-20,0,5)
    track.Position = UDim2.new(0,10,0,30)
    track.BackgroundColor3 = Color3.fromRGB(255,255,255)
    track.BackgroundTransparency = 0.88
    track.BorderSizePixel = 0
    Instance.new("UICorner",track).CornerRadius = UDim.new(1,0)

    local pct = (defaultVal - minVal) / (maxVal - minVal)

    local fill = Instance.new("Frame",track)
    fill.Size = UDim2.new(pct,0,1,0)
    fill.BackgroundColor3 = Color3.fromRGB(74,158,255)
    fill.BorderSizePixel = 0
    Instance.new("UICorner",fill).CornerRadius = UDim.new(1,0)

    local knob = Instance.new("TextButton",track)
    knob.Size = UDim2.new(0,13,0,13)
    knob.Position = UDim2.new(pct,-6.5,0.5,-6.5)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.Text = ""
    Instance.new("UICorner",knob).CornerRadius = UDim.new(1,0)

    local dragging = false
    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or
           i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not dragging then return end
        local mouse = lp:GetMouse()
        local abs = track.AbsolutePosition
        local sz  = track.AbsoluteSize
        local p = math.clamp((mouse.X - abs.X) / sz.X, 0, 1)
        fill.Size = UDim2.new(p,0,1,0)
        knob.Position = UDim2.new(p,-6.5,0.5,-6.5)
        local v = math.floor((minVal + p*(maxVal-minVal))*100)/100
        lbl.Text = labelText .. ": " .. tostring(v)
        if onChange then onChange(v) end
    end)
end

-- ══════════════════════════════════════
--  PANEL BUILDERS
-- ══════════════════════════════════════
local setFarmToggleFn = nil

local function clearPanel()
    for _, c in pairs(Panel:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
            c:Destroy()
        end
    end
end

local function buildMainPanel()
    clearPanel()
    makeLabel(Panel, "⚔  AUTO FARM", 1)

    -- MAP dropdown
    local mapOptions = {}
    for id, data in pairs(MAPS) do
        if id > 0 then -- skip lobby
            table.insert(mapOptions, {label=data.name, value=id})
        end
    end
    table.sort(mapOptions, function(a,b) return a.value < b.value end)

    local npcUpdateFn

    local function buildNPCOptions(mapID)
        local npcs = GetMapNPCs(mapID)
        local opts = {{label="All NPC", value=""}}
        for _, n in pairs(npcs) do
            table.insert(opts, {label=n.label, value=n.name})
        end
        return opts
    end

    local _, _, mapGetVal = makeDropdown(Panel, "Map", mapOptions, 2, function(val)
        SetMap(val)
        if npcUpdateFn then npcUpdateFn(buildNPCOptions(val)) end
    end)
    SetMap(mapOptions[1] and mapOptions[1].value or 1)

    local npcWrap
    npcWrap, npcUpdateFn = makeDropdown(Panel, "NPC", buildNPCOptions(State.selectedMap), 3, function(val)
        SetNPC(val)
    end)
    npcWrap.Parent = Panel

    local targetOpts = {
        {label="Nearest",    value="nearest"},
        {label="Lowest HP",  value="lowestHP"},
        {label="Highest HP", value="highestHP"},
    }
    makeDropdown(Panel, "Mob target", targetOpts, 4, function(val)
        SetTargetMode(val)
    end)

    makeSep(Panel, 5)

    makeSliderRow(Panel, "Farm delay", 0.05, 0.5, 0.15, 6, function(v)
        CONFIG.farmDelay = v
    end)

    makeSep(Panel, 7)

    local _, setFT, getFT = makeToggleRow(Panel, "Enable auto farm", 8)
    setFarmToggleFn = setFT

    makeActionBtn(Panel, "▶  Start farm", Color3.fromRGB(34,197,94), 9, function()
        local newState = not getFT()
        setFT(newState)
        ToggleFarm(newState)
    end)

    makeActionBtn(Panel, "⬛  Stop all", Color3.fromRGB(255,74,106), 10, function()
        setFT(false)
        ToggleFarm(false)
    end)
end

local function buildGamemodePanel()
    clearPanel()
    makeLabel(Panel, "🛡  GAMEMODE", 1)
    makeToggleRow(Panel, "Godmode", 2)
    makeToggleRow(Panel, "Infinite health", 3)
    makeToggleRow(Panel, "No fall damage", 4)
    makeToggleRow(Panel, "ESP boxes", 5)
    makeSep(Panel, 6)
    makeActionBtn(Panel, "⟳  Rejoin", Color3.fromRGB(74,158,255), 7)
    makeActionBtn(Panel, "☠  Kill entity", Color3.fromRGB(255,74,106), 8)
end

local function buildSettingsPanel()
    clearPanel()
    makeLabel(Panel, "⚙  SETTINGS", 1)
    makeToggleRow(Panel, "Auto execute on join", 2)
    makeToggleRow(Panel, "Notifications", 3)
    makeToggleRow(Panel, "Anti-AFK", 4)
    makeToggleRow(Panel, "Transparent hub", 5)
    makeSep(Panel, 6)

    local infoCard = Instance.new("Frame")
    infoCard.Size = UDim2.new(1,0,0,76)
    infoCard.BackgroundColor3 = Color3.fromRGB(255,255,255)
    infoCard.BackgroundTransparency = 0.96
    infoCard.BorderSizePixel = 0
    infoCard.LayoutOrder = 7
    infoCard.Parent = Panel
    Instance.new("UICorner",infoCard).CornerRadius = UDim.new(0,9)

    local rows = {{"Hub","Archeron Hub"},{"Members","43,137"},{"Online","2,966"},{"Version","v1.1.0"}}
    for i, r in ipairs(rows) do
        local rFrame = Instance.new("Frame",infoCard)
        rFrame.Size = UDim2.new(1,0,0,18)
        rFrame.Position = UDim2.new(0,0,0,(i-1)*18+4)
        rFrame.BackgroundTransparency = 1
        local k = Instance.new("TextLabel",rFrame)
        k.Size = UDim2.new(0.5,0,1,0)
        k.Position = UDim2.new(0,10,0,0)
        k.BackgroundTransparency = 1
        k.Text = r[1]
        k.TextColor3 = Color3.fromRGB(255,255,255)
        k.TextTransparency = 0.65
        k.Font = Enum.Font.Gotham
        k.TextSize = 10
        k.TextXAlignment = Enum.TextXAlignment.Left
        local v = Instance.new("TextLabel",rFrame)
        v.Size = UDim2.new(0.5,-10,1,0)
        v.Position = UDim2.new(0.5,0,0,0)
        v.BackgroundTransparency = 1
        v.Text = r[2]
        v.TextColor3 = Color3.fromRGB(255,255,255)
        v.Font = Enum.Font.GothamBold
        v.TextSize = 10
        v.TextXAlignment = Enum.TextXAlignment.Right
    end

    makeActionBtn(Panel, "🔗  Join Discord", Color3.fromRGB(88,101,242), 8)
end

-- ══════════════════════════════════════
--  NAV SWITCHING
-- ══════════════════════════════════════
local navItems = {
    {btn=NavMain,     bar=NavMainBar,     txt=NavMainTxt,     ico=NavMainIco,     fn=buildMainPanel,     key="main"},
    {btn=NavGamemode, bar=NavGamemodeBar, txt=NavGamemodeTxt, ico=NavGamemodeIco, fn=buildGamemodePanel, key="gamemode"},
    {btn=NavSettings, bar=NavSettingsBar, txt=NavSettingsTxt, ico=NavSettingsIco, fn=buildSettingsPanel,  key="settings"},
}

local function setActiveNav(key)
    for _, n in pairs(navItems) do
        local active = n.key == key
        n.bar.BackgroundTransparency = active and 0 or 1
        n.txt.TextTransparency = active and 0 or 0.55
        n.ico.TextTransparency = active and 0 or 0.55
        n.btn.BackgroundColor3 = Color3.fromRGB(74,158,255)
        n.btn.BackgroundTransparency = active and 0.9 or 1
    end
end

for _, n in pairs(navItems) do
    n.btn.MouseButton1Click:Connect(function()
        setActiveNav(n.key)
        n.fn()
    end)
end

-- ══════════════════════════════════════
--  MINI HUB
-- ══════════════════════════════════════
local Mini = Instance.new("Frame")
Mini.Name = "Mini"
Mini.Size = UDim2.new(0,52,0,52)
Mini.Position = UDim2.new(0,20,0,20)
Mini.BackgroundColor3 = Color3.fromRGB(14,18,32)
Mini.BorderSizePixel = 0
Mini.Visible = false
Mini.Active = true
Mini.Parent = ScreenGui
Instance.new("UICorner",Mini).CornerRadius = UDim.new(0,16)
local MiniStroke = Instance.new("UIStroke",Mini)
MiniStroke.Color = Color3.fromRGB(74,158,255)
MiniStroke.Transparency = 0.55

local MiniLogo = Instance.new("TextLabel",Mini)
MiniLogo.Size = UDim2.new(0,36,0,36)
MiniLogo.Position = UDim2.new(0.5,-18,0.5,-18)
MiniLogo.BackgroundColor3 = Color3.fromRGB(255,255,255)
MiniLogo.BorderSizePixel = 0
MiniLogo.Text = "Ar"
MiniLogo.TextColor3 = Color3.fromRGB(14,18,32)
MiniLogo.Font = Enum.Font.GothamBold
MiniLogo.TextSize = 14
Instance.new("UICorner",MiniLogo).CornerRadius = UDim.new(0,10)

-- Farm indicator dot di mini
local MiniDot = Instance.new("Frame",Mini)
MiniDot.Size = UDim2.new(0,8,0,8)
MiniDot.Position = UDim2.new(1,-8,0,0)
MiniDot.BackgroundColor3 = Color3.fromRGB(34,197,94)
MiniDot.BackgroundTransparency = 1
MiniDot.BorderSizePixel = 0
Instance.new("UICorner",MiniDot).CornerRadius = UDim.new(1,0)

local MiniBtn = Instance.new("TextButton",Mini)
MiniBtn.Size = UDim2.new(1,0,1,0)
MiniBtn.BackgroundTransparency = 1
MiniBtn.Text = ""
MiniBtn.MouseButton1Click:Connect(function()
    Mini.Visible = false
    Hub.Visible = true
end)

-- ══════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════
local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(Hub, Topbar)
makeDraggable(Mini, Mini)

-- ══════════════════════════════════════
--  MINIMIZE / CLOSE
-- ══════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    Hub.Visible = false
    Mini.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    stopFarmLoop()
    ScreenGui:Destroy()
end)

-- ══════════════════════════════════════
--  ISLAND INDICATOR - UPDATE TIAP 3 DETIK
-- ══════════════════════════════════════
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        local current = getCurrentIsland()
        local islandName = "Unknown"
        if current ~= nil and MAPS[current] then
            islandName = MAPS[current].name
        end
        IslandIndicator.Text = "📍 " .. islandName

        -- Update mini dot warna kalau farm aktif
        MiniDot.BackgroundTransparency = State.farmEnabled and 0 or 1

        task.wait(3)
    end
end)

-- ══════════════════════════════════════
--  INIT
-- ══════════════════════════════════════
setActiveNav("main")
buildMainPanel()
print("[Archeron Hub v1.1] Loaded! Island detect: GUI-based")
