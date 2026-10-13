-- Archeron Hub v2.5 | World Farm + Dungeon/Trial Auto
-- Horizontal tabs · Rounded cards · BridgeNet TP

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local RS       = game:GetService("ReplicatedStorage")
local lp       = Players.LocalPlayer

local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
lp.CharacterAdded:Connect(function(c)
    char = c; hrp = c:WaitForChild("HumanoidRootPart")
end)

-- ════════════════════════════════════════════════════════
-- DATA
-- ════════════════════════════════════════════════════════
local WORLDS = {
    { name = "Heaven Island", enemies = {
        { name = "Kume",       rarity = 1 },
        { name = "Robin Lucco",rarity = 2 },
        { name = "Buggo",      rarity = 3 },
        { name = "Kuzon",      rarity = 4 },
        { name = "Hawk Eyes",  rarity = 5 },
        { name = "Anel",       rarity = 6 },
    }},
    { name = "Slayers Village", enemies = {
        { name = "Kaigako",    rarity = 1 },
        { name = "Gyotaro",    rarity = 2 },
        { name = "Hantengue",  rarity = 3 },
        { name = "Akeza",      rarity = 4 },
        { name = "Doume",      rarity = 5 },
        { name = "Kukushibe",  rarity = 6 },
    }},
    { name = "Cursed Academy", enemies = {
        { name = "Jogu",       rarity = 1 },
        { name = "Toje",       rarity = 2 },
        { name = "Mahita",     rarity = 3 },
        { name = "Lyu",        rarity = 4 },
        { name = "Kashimu",    rarity = 5 },
        { name = "Sokona",     rarity = 6 },
    }},
    { name = "Sins Kingdom", enemies = {
        { name = "Melascule",  rarity = 1 },
        { name = "Monspit",    rarity = 2 },
        { name = "Derriere",   rarity = 3 },
        { name = "Gloxine",    rarity = 4 },
        { name = "Malel",      rarity = 5 },
        { name = "Chaos Arthur",rarity = 6 },
    }},
}
local RARITY_COLOR = {
    Color3.fromRGB( 80,200, 80),
    Color3.fromRGB( 80,140,255),
    Color3.fromRGB(255,140, 40),
    Color3.fromRGB(220, 50, 50),
    Color3.fromRGB(200, 60,255),
    Color3.fromRGB(255,210,  0),
}

-- ════════════════════════════════════════════════════════
-- SHARED LOGIC
-- ════════════════════════════════════════════════════════
local function tpFighters()
    local pos = hrp and hrp.Position
    if not pos then return end
    local ok, ff = pcall(function() return workspace.Client.Fighters end)
    if not ok or not ff then return end
    for _, f in ipairs(ff:GetChildren()) do
        local root = f:FindFirstChild("HumanoidRootPart")
            or (f:IsA("Model") and f.PrimaryPart)
            or f:FindFirstChildWhichIsA("BasePart")
        if root then pcall(function() root.CFrame = CFrame.new(pos) end) end
    end
end

local function clearMovers()
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    for _,v in pairs(h:GetChildren()) do
        if v:IsA("BodyPosition") or v:IsA("AlignPosition")
        or v:IsA("BodyVelocity") or v:IsA("BodyGyro")
        or v:IsA("AlignOrientation") then v:Destroy() end
    end
end

local function waitDead(part, timeout)
    local t = 0
    while t < (timeout or 15) do
        if not part or part.Parent == nil then break end
        if part:GetAttribute("Died") then break end
        task.wait(0.1); t = t + 0.1
    end
    task.wait(0.15)
end

local function fireBridgeNet(payload)
    local ok, bn = pcall(function() return RS:WaitForChild("BridgeNet",5) end)
    if not ok or not bn then return end
    local ok2, ev = pcall(function() return bn:WaitForChild("dataRemoteEvent",5) end)
    if not ok2 or not ev then return end
    ev:FireServer(payload)
end

-- ── WORLD FARM ──────────────────────────────────────────
local farmActive     = false
local selectedWorld  = 1
local enabledEnemies = {}

local function resetEnemies()
    enabledEnemies = {}
    local w = WORLDS[selectedWorld]
    if w then for i = 1, #w.enemies do enabledEnemies[i] = false end end
end
resetEnemies()

local function tpWorld(name)
    fireBridgeNet({
        {"\x01","\xBE\x05\xDD\t\x01qC\x94\x82V\xEA]\xE2/@\xDF",
         {"General","Maps","Teleport",name,n=4}},"\x02"
    })
end

local function findNPC(enemy)
    local hits = {}
    for _,v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:GetAttribute("Died") then
            local en = v:GetAttribute("EnemyName")
            if en and en == enemy.name then table.insert(hits, v) end
        end
    end
    return #hits > 0 and hits[math.random(#hits)] or nil
end

local function farmLoop()
    local lastTpW = nil
    while farmActive do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end
        local pool = {}; local w = WORLDS[selectedWorld]
        if w then for i,e in ipairs(w.enemies) do
            if enabledEnemies[i] then table.insert(pool, e) end
        end end
        if #pool == 0 then task.wait(1); continue end
        local enemy = pool[math.random(#pool)]
        local part  = findNPC(enemy)
        if part then
            lastTpW = nil; clearMovers()
            hrp.CFrame = CFrame.new(part.Position); tpFighters()
            task.wait(0.05); waitDead(part, 15)
        else
            local wn = w and w.name or ""
            if lastTpW ~= wn then tpWorld(wn); lastTpW = wn; task.wait(3.5)
            else task.wait(0.8) end
        end
        task.wait(0.05)
    end
end

-- ── DUNGEON / TRIAL ─────────────────────────────────────
local dungeonActive    = false
local trialActive      = false
local cullingActive    = false
local dungeonLeaveRoom = 10
local trialLeaveWave   = 10
local cullingLeaveRoom = 10
local cullingDifficulty = "Easy"
local CULLING_DIFFS = {"Easy","Medium","Hard"}

local function findEnemiesInArea(folderName)
    local list = {}
    local ok, folder = pcall(function()
        return workspace.Server.Enemies.Gamemodes[folderName]
    end)
    if not ok or not folder then return list end
    for _,v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") and not v:GetAttribute("Died")
        and v:GetAttribute("EnemyName") then
            table.insert(list, v)
        end
    end
    return list
end

local function findNearestDoor()
    local hrpPos = (hrp and hrp.Position) or Vector3.new()
    local best, bestD, bestPP = nil, math.huge, nil
    local ok, mapFolder = pcall(function()
        return workspace.Client.Maps["Dungeon Easy"].Map
    end)
    if not ok or not mapFolder then return nil, nil end
    for _,v in ipairs(mapFolder:GetDescendants()) do
        if v:IsA("Model") and v.Parent and v.Parent.Name == "Doors" then
            local mainPart = v:FindFirstChild("Main")
            local openPP   = v:FindFirstChild("OpenDoor")
            if mainPart and mainPart:IsA("BasePart")
            and openPP and openPP:IsA("ProximityPrompt") then
                local d = (mainPart.Position - hrpPos).Magnitude
                if d < bestD then bestD = d; best = mainPart; bestPP = openPP end
            end
        end
    end
    return best, bestPP
end

local function triggerDoor(doorPart)
    local mdl = doorPart.Parent
    local pp = nil
    for _,v in ipairs(mdl:GetDescendants()) do
        if v:IsA("ProximityPrompt") then pp = v; break end
    end
    if pp and fireproximityprompt then
        pcall(fireproximityprompt, pp)
    elseif firetouchinterest then
        pcall(firetouchinterest, hrp, doorPart, 0)
        task.wait(0.1)
        pcall(firetouchinterest, hrp, doorPart, 1)
    end
end

local function joinGamemode(name)
    fireBridgeNet({
        {"\x01","\xE8]d\xCCs7I\x05\x83!\xB6\xCF+<\xD5F",
         {"General","Gamemodes","Join",name,n=4}},"\x02"
    })
end

local function leaveGamemode()
    fireBridgeNet({
        {"General","Gamemodes","Leave",n=3},"\x02"
    })
end

local function getTrialWave()
    local ok, v = pcall(function()
        return workspace.Client.Maps["Trial Easy"]
            .GamemodeSessions.Global.StateManager.CurrentWave.Value
    end)
    return ok and tonumber(v) or 0
end

local function getDungeonRoom()
    local ok, v = pcall(function()
        return workspace.Client.Maps["Dungeon Easy"]
            .GamemodeSessions.Global.StateManager.RoomsCleared.Value
    end)
    return ok and tonumber(v) or 0
end

local function dungeonLoop()
    joinGamemode("Dungeon Easy"); task.wait(4)
    local lastRoom = getDungeonRoom()
    while dungeonActive do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end
        local tries = 40
        while dungeonActive and tries > 0 do
            local en = findEnemiesInArea("Dungeon Easy")
            if #en == 0 then break end
            local t = en[math.random(#en)]
            clearMovers(); hrp.CFrame = CFrame.new(t.Position); tpFighters()
            task.wait(0.05); waitDead(t, 15); tries = tries - 1
        end
        if not dungeonActive then break end
        task.wait(1.5)
        local curRoom = getDungeonRoom()
        if curRoom >= dungeonLeaveRoom then dungeonActive = false; leaveGamemode(); break end
        task.wait(0.4)
        local door, doorPP = findNearestDoor()
        if door and doorPP then
            clearMovers(); hrp.CFrame = CFrame.new(door.Position); tpFighters()
            task.wait(0.3); pcall(fireproximityprompt, doorPP)
            local wc = 0
            while dungeonActive and wc < 20 do
                local r = getDungeonRoom()
                if r ~= lastRoom then lastRoom = r; break end
                task.wait(0.5); wc = wc + 1
            end
        else task.wait(1) end
    end
end

local function joinCullingGame()
    local ok, pp = pcall(function()
        return workspace.Server.ProximityPrompts["Cursed Academy"]["Culling Game"]
    end)
    if ok and pp and fireproximityprompt then
        pcall(fireproximityprompt, pp)
        task.wait(1.5)
    end
    fireBridgeNet({
        {"General","Parties","SetDifficulty",cullingDifficulty,n=4},"\x02"
    })
end

local function getCullingWave()
    local ok, v = pcall(function()
        local sessions = workspace.Client.Maps["Culling Game"].GamemodeSessions
        local session  = sessions:GetChildren()[1]
        return session.StateManager.CurrentWave.Value
    end)
    return ok and tonumber(v) or 0
end

local function findNearestCullingDoor()
    local hrpPos = (hrp and hrp.Position) or Vector3.new()
    local best, bestD, bestPP = nil, math.huge, nil
    local ok, mapFolder = pcall(function()
        return workspace.Client.Maps["Culling Game"].Map
    end)
    if not ok or not mapFolder then return nil, nil end
    for _,v in ipairs(mapFolder:GetDescendants()) do
        if v:IsA("Model") and v.Parent and v.Parent.Name == "Doors" then
            local mainPart = v:FindFirstChild("Main")
            local openPP   = v:FindFirstChild("OpenDoor")
            if mainPart and mainPart:IsA("BasePart")
            and openPP and openPP:IsA("ProximityPrompt") then
                local d = (mainPart.Position - hrpPos).Magnitude
                if d < bestD then bestD = d; best = mainPart; bestPP = openPP end
            end
        end
    end
    return best, bestPP
end

local function cullingLoop()
    joinCullingGame(); task.wait(4)
    local lastWave = getCullingWave()
    while cullingActive do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end
        local tries = 40
        while cullingActive and tries > 0 do
            local en = findEnemiesInArea("Culling Game")
            if #en == 0 then break end
            local t = en[math.random(#en)]
            clearMovers(); hrp.CFrame = CFrame.new(t.Position); tpFighters()
            task.wait(0.05); waitDead(t, 15); tries = tries - 1
        end
        if not cullingActive then break end
        task.wait(1.5)
        local curWave = getCullingWave()
        if curWave >= cullingLeaveRoom then cullingActive = false; leaveGamemode(); break end
        local door, doorPP = findNearestCullingDoor()
        if door and doorPP then
            clearMovers(); hrp.CFrame = CFrame.new(door.Position); tpFighters()
            task.wait(0.3); pcall(fireproximityprompt, doorPP)
            local wc = 0
            while cullingActive and wc < 20 do
                local w = getCullingWave()
                if w ~= lastWave then lastWave = w; break end
                task.wait(0.5); wc = wc + 1
            end
        else task.wait(1) end
    end
end

local function trialLoop()
    joinGamemode("Trial Easy"); task.wait(4)
    local lastWave = getTrialWave()
    while trialActive do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end
        local tries = 40
        while trialActive and tries > 0 do
            local en = findEnemiesInArea("Trial Easy")
            if #en == 0 then break end
            local t = en[math.random(#en)]
            clearMovers(); hrp.CFrame = CFrame.new(t.Position); tpFighters()
            task.wait(0.05); waitDead(t, 15); tries = tries - 1
        end
        if not trialActive then break end
        local curWave = getTrialWave()
        if curWave >= trialLeaveWave then trialActive = false; leaveGamemode(); break end
        -- wait for CurrentWave to increment
        local waitCycles = 0
        while trialActive and waitCycles < 60 do
            local w = getTrialWave()
            if w ~= lastWave then lastWave = w; break end
            task.wait(0.5); waitCycles = waitCycles + 1
        end
    end
end

-- ════════════════════════════════════════════════════════
-- GUI CONSTANTS
-- ════════════════════════════════════════════════════════
local C = {
    bg    = Color3.fromRGB( 7,  4, 18),
    side  = Color3.fromRGB(10,  6, 24),
    panel = Color3.fromRGB(13,  9, 30),
    card  = Color3.fromRGB(16, 11, 36),
    hdr   = Color3.fromRGB( 9,  6, 22),
    acc   = Color3.fromRGB(95, 45,205),
    accHi = Color3.fromRGB(135,75,255),
    txt   = Color3.fromRGB(210,188,255),
    sub   = Color3.fromRGB(95, 65,155),
    tOn   = Color3.fromRGB(75, 28,185),
    tOff  = Color3.fromRGB(32, 18, 58),
    kOn   = Color3.fromRGB(185,135,255),
    kOff  = Color3.fromRGB(110, 65,175),
    red   = Color3.fromRGB(178, 32, 52),
    sep   = Color3.fromRGB(45,  22, 90),
    item  = Color3.fromRGB( 9,  5, 21),
    bot   = Color3.fromRGB( 8,  5, 20),
    actS  = Color3.fromRGB(120,60,240),
    tabAct= Color3.fromRGB(80, 35,180),
    input = Color3.fromRGB(18, 11, 40),
}

-- adaptive width so it fits on any mobile screen
local vp   = workspace.CurrentCamera.ViewportSize
local GW   = math.min(460, math.floor(vp.X) - 16)

local HDR_H  = 34
local TBAR_H = 34
local BOT_H  = 48
local CONT_H = 200
local TOTAL_H= HDR_H + TBAR_H + CONT_H + BOT_H  -- 316
local ROW_H  = 34
local ITEM_H = 28
local CARD_M = 6
local CARD_R = 8
local PAD    = 4

local function N(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function CR(r,p) N("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function ST(c,t,p) N("UIStroke",{Color=c,Thickness=t},p) end

local function makeDrag(handle, target)
    local mv = target or handle
    local drag, s, o, li = false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; s = i.Position; o = mv.Position end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch then li = i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i == li and drag then
            local d = i.Position - s
            mv.Position = UDim2.new(o.X.Scale, o.X.Offset+d.X, o.Y.Scale, o.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

local function makePill(parent, xRight)
    local pill = N("Frame",{
        Size=UDim2.new(0,40,0,20),
        Position=UDim2.new(1,xRight,0.5,-10),
        BackgroundColor3=C.tOff, BorderSizePixel=0, Parent=parent,
    })
    CR(999, pill)
    local knob = N("Frame",{
        Size=UDim2.new(0,16,0,16), Position=UDim2.new(0,2,0.5,-8),
        BackgroundColor3=C.kOff, BorderSizePixel=0, Parent=pill,
    })
    CR(999, knob)
    return pill, knob
end

local function makeCard(parent, y, h)
    local f = N("Frame",{
        Size=UDim2.new(1,-(CARD_M*2),0,h),
        Position=UDim2.new(0,CARD_M,0,y),
        BackgroundColor3=C.card, BorderSizePixel=0, Parent=parent,
    })
    CR(CARD_R, f); ST(C.sep, 0.8, f)
    return f
end

-- ════════════════════════════════════════════════════════
-- SCREEN GUI
-- ════════════════════════════════════════════════════════
pcall(function()
    local old = lp.PlayerGui:FindFirstChild("ArcheronHub")
    if old then old:Destroy() end
end)

local gui = N("ScreenGui",{
    Name="ArcheronHub", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=(gethui and gethui()) or lp.PlayerGui,
})

local main = N("Frame",{
    Size=UDim2.new(0,GW,0,TOTAL_H),
    Position=UDim2.new(0.5,-GW/2,0.32,-TOTAL_H/2),
    BackgroundColor3=C.bg, BorderSizePixel=0,
    ClipsDescendants=true, Parent=gui,
})
CR(10, main); ST(C.sep, 1.2, main)

-- ── HEADER ──────────────────────────────────────────────
local hdr = N("Frame",{
    Size=UDim2.new(1,0,0,HDR_H),
    BackgroundColor3=C.hdr, BorderSizePixel=0, Active=true, Parent=main,
})
CR(10, hdr)
N("Frame",{Size=UDim2.new(1,0,0,10), Position=UDim2.new(0,0,1,-10),
    BackgroundColor3=C.hdr, BorderSizePixel=0, Parent=hdr})

local notch = N("Frame",{Size=UDim2.new(0,3,0,18), Position=UDim2.new(0,12,0.5,-9),
    BackgroundColor3=C.accHi, BorderSizePixel=0, Parent=hdr})
CR(2, notch)
N("TextLabel",{Size=UDim2.new(0,170,1,0), Position=UDim2.new(0,22,0,0),
    BackgroundTransparency=1, Text="ARCHERON  HUB",
    TextColor3=Color3.fromRGB(160,100,255),
    TextSize=12, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr})
local vb = N("Frame",{Size=UDim2.new(0,32,0,15), Position=UDim2.new(0,196,0.5,-7),
    BackgroundColor3=C.acc, BackgroundTransparency=0.45, BorderSizePixel=0, Parent=hdr})
CR(4, vb)
N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="v2.5", TextColor3=Color3.fromRGB(195,150,255),
    TextSize=8, Font=Enum.Font.GothamBold, Parent=vb})

local closeBtn = N("TextButton",{
    Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-28,0.5,-11),
    BackgroundColor3=C.red, Text="×", TextColor3=Color3.fromRGB(255,255,255),
    TextSize=15, Font=Enum.Font.GothamBold, BorderSizePixel=0, Parent=hdr,
})
CR(5, closeBtn)
makeDrag(hdr, main)

-- ── TAB BAR ─────────────────────────────────────────────
local tabBar = N("Frame",{
    Size=UDim2.new(1,0,0,TBAR_H), Position=UDim2.new(0,0,0,HDR_H),
    BackgroundColor3=C.side, BorderSizePixel=0, Parent=main,
})
N("Frame",{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=C.sep, BorderSizePixel=0, Parent=tabBar})

local TABS       = {"Main","Gamemode","Settings"}
local activeTab  = 1
local tabPills   = {}
local tabContents= {}
local tabW       = math.floor((GW - 16) / #TABS)
local ti05       = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

for i, name in ipairs(TABS) do
    local pill = N("Frame",{
        Size=UDim2.new(0,tabW-4,0,22),
        Position=UDim2.new(0, 8+(i-1)*tabW, 0.5,-11),
        BackgroundColor3 = i==1 and C.tabAct or C.side,
        BorderSizePixel=0, Parent=tabBar,
    })
    CR(999, pill)
    if i == 1 then ST(C.accHi, 0.8, pill) end
    N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=name, TextColor3=i==1 and C.txt or C.sub,
        TextSize=10, Font=Enum.Font.GothamBold, Parent=pill})
    tabPills[i] = pill
    local idx = i
    N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=pill}
    ).MouseButton1Click:Connect(function()
        if activeTab == idx then return end
        local oldP = tabPills[activeTab]
        TweenSvc:Create(oldP, ti05, {BackgroundColor3=C.side}):Play()
        for _,ch in ipairs(oldP:GetChildren()) do
            if ch:IsA("TextLabel") then
                TweenSvc:Create(ch, ti05, {TextColor3=C.sub}):Play()
            end
        end
        pcall(function() oldP:FindFirstChildOfClass("UIStroke"):Destroy() end)
        if tabContents[activeTab] then tabContents[activeTab].Visible = false end
        activeTab = idx
        TweenSvc:Create(pill, ti05, {BackgroundColor3=C.tabAct}):Play()
        for _,ch in ipairs(pill:GetChildren()) do
            if ch:IsA("TextLabel") then
                TweenSvc:Create(ch, ti05, {TextColor3=C.txt}):Play()
            end
        end
        ST(C.accHi, 0.8, pill)
        if tabContents[idx] then tabContents[idx].Visible = true end
    end)
end

-- ── SCROLL HELPER ───────────────────────────────────────
local function makeScroll(visible)
    return N("ScrollingFrame",{
        Size=UDim2.new(1,0,0,CONT_H),
        Position=UDim2.new(0,0,0,HDR_H+TBAR_H),
        BackgroundColor3=C.panel, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=C.acc,
        CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        Visible=visible, Parent=main,
    })
end

-- ════════════════════════════════════════════════════════
-- TAB 1: MAIN
-- ════════════════════════════════════════════════════════
local scrollMain = makeScroll(true)
tabContents[1]   = scrollMain

-- forward declarations
local buildEnemyList, doMainLayout
local worldListOpen = false
local enemyListOpen = false
local worldItemFrames = {}

-- World card
local worldCard = makeCard(scrollMain, PAD, ROW_H)
N("TextLabel",{Size=UDim2.new(0,52,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="World",
    TextColor3=C.sub, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=worldCard})
local worldVal = N("TextLabel",{Size=UDim2.new(1,-80,1,0), Position=UDim2.new(0,64,0,0),
    BackgroundTransparency=1, Text=WORLDS[1].name,
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=worldCard})
local worldArrow = N("TextLabel",{Size=UDim2.new(0,16,1,0), Position=UDim2.new(1,-18,0,0),
    BackgroundTransparency=1, Text="►",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.GothamBold, Parent=worldCard})
N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=worldCard}
).MouseButton1Click:Connect(function()
    worldListOpen = not worldListOpen
    worldArrow.Text = worldListOpen and "▾" or "►"
    doMainLayout()
end)

-- World items card
local worldItemsCard = N("Frame",{
    Size=UDim2.new(1,-(CARD_M*2),0,0),
    Position=UDim2.new(0,CARD_M,0,PAD+ROW_H+2),
    BackgroundColor3=C.card, BorderSizePixel=0, Visible=false, Parent=scrollMain,
})
CR(CARD_R, worldItemsCard); ST(C.sep, 0.8, worldItemsCard)

for i,w in ipairs(WORLDS) do
    local item = N("Frame",{
        Size=UDim2.new(1,0,0,ITEM_H), Position=UDim2.new(0,0,0,(i-1)*ITEM_H),
        BackgroundTransparency=1, BorderSizePixel=0, Parent=worldItemsCard,
    })
    local wStrip = N("Frame",{Size=UDim2.new(0,2,0,14), Position=UDim2.new(0,8,0.5,-7),
        BackgroundColor3=i==1 and C.actS or C.sep, BorderSizePixel=0, Parent=item})
    CR(1, wStrip)
    local lbl = N("TextLabel",{Size=UDim2.new(1,-22,1,0), Position=UDim2.new(0,18,0,0),
        BackgroundTransparency=1, Text=w.name,
        TextColor3=i==1 and C.txt or C.sub,
        TextSize=10, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=item})
    worldItemFrames[i] = {frame=item, label=lbl, strip=wStrip}
    local idx = i
    N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=item}
    ).MouseButton1Click:Connect(function()
        local old = worldItemFrames[selectedWorld]
        if old then old.label.TextColor3=C.sub; old.strip.BackgroundColor3=C.sep end
        selectedWorld = idx
        lbl.TextColor3 = C.txt; wStrip.BackgroundColor3 = C.actS
        worldVal.Text  = w.name
        worldListOpen  = false; worldArrow.Text = "►"
        resetEnemies(); buildEnemyList(); doMainLayout()
    end)
end

-- Enemy card
local enemyCard = makeCard(scrollMain, 0, ROW_H)  -- y set by doMainLayout
N("TextLabel",{Size=UDim2.new(0,56,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Enemy",
    TextColor3=C.sub, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=enemyCard})
local enemyVal = N("TextLabel",{Size=UDim2.new(1,-82,1,0), Position=UDim2.new(0,68,0,0),
    BackgroundTransparency=1, Text="0/0",
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=enemyCard})
local enemyArrow = N("TextLabel",{Size=UDim2.new(0,16,1,0), Position=UDim2.new(1,-18,0,0),
    BackgroundTransparency=1, Text="►",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.GothamBold, Parent=enemyCard})
N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=enemyCard}
).MouseButton1Click:Connect(function()
    enemyListOpen = not enemyListOpen
    enemyArrow.Text = enemyListOpen and "▾" or "►"
    doMainLayout()
end)

local enemyItemsCard = N("Frame",{
    Size=UDim2.new(1,-(CARD_M*2),0,0),
    Position=UDim2.new(0,CARD_M,0,0),
    BackgroundColor3=C.card, BorderSizePixel=0, Visible=false, Parent=scrollMain,
})
CR(CARD_R, enemyItemsCard); ST(C.sep, 0.8, enemyItemsCard)

-- Auto Farm card  (declared BEFORE doMainLayout/buildEnemyList are called)
local farmCard = makeCard(scrollMain, 0, ROW_H)
N("TextLabel",{Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Auto Farm",
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=farmCard})
local fPill, fKnob = makePill(farmCard, -48)
local farmState = false
local fti = TweenInfo.new(0.14, Enum.EasingStyle.Quad)
N("TextButton",{Size=UDim2.new(0,96,1,0), Position=UDim2.new(1,-100,0,0),
    BackgroundTransparency=1, Text="", Parent=farmCard}
).MouseButton1Click:Connect(function()
    farmState  = not farmState; farmActive = farmState
    TweenSvc:Create(fPill, fti, {BackgroundColor3=farmState and C.tOn or C.tOff}):Play()
    TweenSvc:Create(fKnob, fti, {
        Position=farmState and UDim2.new(0,22,0.5,-8) or UDim2.new(0,2,0.5,-8),
        BackgroundColor3=farmState and C.kOn or C.kOff,
    }):Play()
    if farmState then task.spawn(farmLoop) end
end)

-- Layout engine
doMainLayout = function()
    local y = PAD
    worldCard.Position = UDim2.new(0,CARD_M,0,y); y = y + ROW_H + 2
    if worldListOpen then
        local h = #WORLDS * ITEM_H
        worldItemsCard.Visible = true
        worldItemsCard.Size    = UDim2.new(1,-(CARD_M*2),0,h)
        worldItemsCard.Position= UDim2.new(0,CARD_M,0,y)
        y = y + h + PAD
    else
        worldItemsCard.Visible = false
        y = y + PAD
    end
    enemyCard.Position = UDim2.new(0,CARD_M,0,y); y = y + ROW_H + 2
    if enemyListOpen then
        enemyItemsCard.Visible  = true
        enemyItemsCard.Position = UDim2.new(0,CARD_M,0,y)
        y = y + enemyItemsCard.Size.Y.Offset + PAD
    else
        enemyItemsCard.Visible = false
        y = y + PAD
    end
    farmCard.Position = UDim2.new(0,CARD_M,0,y)
end

buildEnemyList = function()
    for _,c in ipairs(enemyItemsCard:GetChildren()) do c:Destroy() end
    local w       = WORLDS[selectedWorld]
    local enemies = w and w.enemies or {}
    local enabled = 0
    for i = 1,#enemies do if enabledEnemies[i] then enabled = enabled+1 end end
    if #enemies == 0 then
        enemyVal.Text = "—"
    elseif enabled == #enemies then
        enemyVal.Text = "All ("..#enemies..")"
    else
        enemyVal.Text = enabled.."/"..#enemies
    end

    if #enemies == 0 then
        local ph = N("Frame",{Size=UDim2.new(1,0,0,ITEM_H), Position=UDim2.new(0,0,0,0),
            BackgroundTransparency=1, BorderSizePixel=0, Parent=enemyItemsCard})
        N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="No enemies", TextColor3=C.sub, TextSize=9,
            Font=Enum.Font.Gotham, Parent=ph})
        enemyItemsCard.Size = UDim2.new(1,-(CARD_M*2),0,ITEM_H)
        return
    end

    for i,e in ipairs(enemies) do
        local item = N("Frame",{
            Size=UDim2.new(1,0,0,ITEM_H), Position=UDim2.new(0,0,0,(i-1)*ITEM_H),
            BackgroundTransparency=1, BorderSizePixel=0, Parent=enemyItemsCard})
        local rc = RARITY_COLOR[e.rarity or 1]
        local rs = N("Frame",{Size=UDim2.new(0,2,0,14), Position=UDim2.new(0,8,0.5,-7),
            BackgroundColor3=rc, BorderSizePixel=0, Parent=item})
        CR(1, rs)
        local chk = N("Frame",{Size=UDim2.new(0,13,0,13), Position=UDim2.new(0,18,0.5,-6),
            BackgroundColor3=enabledEnemies[i] and C.acc or C.item,
            BorderSizePixel=0, Parent=item})
        CR(3, chk)
        N("TextLabel",{Size=UDim2.new(1,-38,1,0), Position=UDim2.new(0,36,0,0),
            BackgroundTransparency=1, Text=e.name,
            TextColor3=C.txt, TextSize=10, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=item})
        local idx = i
        N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=item}
        ).MouseButton1Click:Connect(function()
            enabledEnemies[idx] = not enabledEnemies[idx]
            TweenSvc:Create(chk, TweenInfo.new(0.1),{
                BackgroundColor3=enabledEnemies[idx] and C.acc or C.item
            }):Play()
            local en2 = 0
            for j = 1,#enemies do if enabledEnemies[j] then en2=en2+1 end end
            if en2 == #enemies then enemyVal.Text = "All ("..#enemies..")"
            else enemyVal.Text = en2.."/"..#enemies end
        end)
    end
    enemyItemsCard.Size = UDim2.new(1,-(CARD_M*2),0,#enemies*ITEM_H)
end

buildEnemyList(); doMainLayout()

-- ════════════════════════════════════════════════════════
-- TAB 2: GAMEMODE
-- ════════════════════════════════════════════════════════
local scrollGM  = makeScroll(false)
tabContents[2]  = scrollGM

local function secLabel(parent, y, txt)
    N("TextLabel",{
        Size=UDim2.new(1,-(CARD_M*2),0,16), Position=UDim2.new(0,CARD_M,0,y),
        BackgroundTransparency=1, Text=txt,
        TextColor3=C.sub, TextSize=8, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=parent,
    })
end

local function makeNumInput(parent, xRight, defaultVal, minV, maxV, onChange)
    local box = N("Frame",{
        Size=UDim2.new(0,44,0,22), Position=UDim2.new(1,xRight,0.5,-11),
        BackgroundColor3=C.input, BorderSizePixel=0, Parent=parent,
    })
    CR(6, box); ST(C.sep, 0.8, box)
    local tb = N("TextBox",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=tostring(defaultVal),
        TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
        ClearTextOnFocus=false, Parent=box,
    })
    tb.FocusLost:Connect(function()
        local v = tonumber(tb.Text)
        if not v then v = defaultVal end
        v = math.clamp(math.floor(v), minV, maxV)
        tb.Text = tostring(v); onChange(v)
    end)
    return box, tb
end

local gmy = PAD

-- DUNGEON EASY
secLabel(scrollGM, gmy, "DUNGEON EASY"); gmy = gmy + 18

local dungCard = makeCard(scrollGM, gmy, ROW_H)
N("TextLabel",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Auto Dungeon Easy",
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=dungCard})
local dungPill, dungKnob = makePill(dungCard, -48)
local dungState = false
local dti = TweenInfo.new(0.14, Enum.EasingStyle.Quad)
N("TextButton",{Size=UDim2.new(0,96,1,0), Position=UDim2.new(1,-100,0,0),
    BackgroundTransparency=1, Text="", Parent=dungCard}
).MouseButton1Click:Connect(function()
    dungState    = not dungState; dungeonActive = dungState
    TweenSvc:Create(dungPill, dti, {BackgroundColor3=dungState and C.tOn or C.tOff}):Play()
    TweenSvc:Create(dungKnob, dti, {
        Position=dungState and UDim2.new(0,22,0.5,-8) or UDim2.new(0,2,0.5,-8),
        BackgroundColor3=dungState and C.kOn or C.kOff,
    }):Play()
    if dungState then task.spawn(dungeonLoop) end
end)
gmy = gmy + ROW_H + PAD

local leaveRoomCard = makeCard(scrollGM, gmy, ROW_H)
N("TextLabel",{Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Auto leave at room",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=leaveRoomCard})
makeNumInput(leaveRoomCard, -50, dungeonLeaveRoom, 1, 51, function(v)
    dungeonLeaveRoom = v
end)
gmy = gmy + ROW_H + PAD + 4

-- TRIAL EASY
secLabel(scrollGM, gmy, "TRIAL EASY"); gmy = gmy + 18

local trialCard = makeCard(scrollGM, gmy, ROW_H)
N("TextLabel",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Auto Trial Easy",
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=trialCard})
local trialPill, trialKnob = makePill(trialCard, -48)
local trialState = false
N("TextButton",{Size=UDim2.new(0,96,1,0), Position=UDim2.new(1,-100,0,0),
    BackgroundTransparency=1, Text="", Parent=trialCard}
).MouseButton1Click:Connect(function()
    trialState  = not trialState; trialActive = trialState
    TweenSvc:Create(trialPill, dti, {BackgroundColor3=trialState and C.tOn or C.tOff}):Play()
    TweenSvc:Create(trialKnob, dti, {
        Position=trialState and UDim2.new(0,22,0.5,-8) or UDim2.new(0,2,0.5,-8),
        BackgroundColor3=trialState and C.kOn or C.kOff,
    }):Play()
    if trialState then task.spawn(trialLoop) end
end)
gmy = gmy + ROW_H + PAD

local leaveWaveCard = makeCard(scrollGM, gmy, ROW_H)
N("TextLabel",{Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Auto leave at wave",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=leaveWaveCard})
makeNumInput(leaveWaveCard, -50, trialLeaveWave, 1, 51, function(v)
    trialLeaveWave = v
end)
gmy = gmy + ROW_H + PAD + 4

-- CULLING GAME
secLabel(scrollGM, gmy, "CULLING GAME"); gmy = gmy + 18

local cullCard = makeCard(scrollGM, gmy, ROW_H)
N("TextLabel",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Auto Culling Game",
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=cullCard})
local cullPill, cullKnob = makePill(cullCard, -48)
local cullState = false
N("TextButton",{Size=UDim2.new(0,96,1,0), Position=UDim2.new(1,-100,0,0),
    BackgroundTransparency=1, Text="", Parent=cullCard}
).MouseButton1Click:Connect(function()
    cullState    = not cullState; cullingActive = cullState
    TweenSvc:Create(cullPill, dti, {BackgroundColor3=cullState and C.tOn or C.tOff}):Play()
    TweenSvc:Create(cullKnob, dti, {
        Position=cullState and UDim2.new(0,22,0.5,-8) or UDim2.new(0,2,0.5,-8),
        BackgroundColor3=cullState and C.kOn or C.kOff,
    }):Play()
    if cullState then task.spawn(cullingLoop) end
end)
gmy = gmy + ROW_H + PAD

-- Difficulty picker
local diffCard = makeCard(scrollGM, gmy, ROW_H)
N("TextLabel",{Size=UDim2.new(0,80,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Difficulty",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=diffCard})
local diffIdx = 1
local diffVal = N("TextLabel",{Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,90,0,0),
    BackgroundTransparency=1, Text=CULLING_DIFFS[1],
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=diffCard})
local diffArrows = N("TextLabel",{Size=UDim2.new(0,30,1,0), Position=UDim2.new(1,-34,0,0),
    BackgroundTransparency=1, Text="◀▶",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.GothamBold, Parent=diffCard})
N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=diffCard}
).MouseButton1Click:Connect(function()
    diffIdx = (diffIdx % #CULLING_DIFFS) + 1
    cullingDifficulty = CULLING_DIFFS[diffIdx]
    diffVal.Text = cullingDifficulty
end)
gmy = gmy + ROW_H + PAD

local cullLeaveCard = makeCard(scrollGM, gmy, ROW_H)
N("TextLabel",{Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="Auto leave at room",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=cullLeaveCard})
makeNumInput(cullLeaveCard, -50, cullingLeaveRoom, 1, 51, function(v)
    cullingLeaveRoom = v
end)

-- ════════════════════════════════════════════════════════
-- TAB 3: SETTINGS
-- ════════════════════════════════════════════════════════
local scrollSet = makeScroll(false)
tabContents[3]  = scrollSet
local sc = makeCard(scrollSet, PAD, ROW_H)
N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="Settings (coming soon)", TextColor3=C.sub,
    TextSize=10, Font=Enum.Font.Gotham, Parent=sc})

-- ════════════════════════════════════════════════════════
-- BOTTOM BAR  (avatar + name only)
-- ════════════════════════════════════════════════════════
local botBar = N("Frame",{
    Size=UDim2.new(1,0,0,BOT_H),
    Position=UDim2.new(0,0,0,HDR_H+TBAR_H+CONT_H),
    BackgroundColor3=C.bot, BorderSizePixel=0, Parent=main,
})
N("Frame",{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.sep, BorderSizePixel=0, Parent=botBar})

local avatarBg = N("Frame",{Size=UDim2.new(0,32,0,32), Position=UDim2.new(0,10,0.5,-16),
    BackgroundColor3=C.acc, BackgroundTransparency=0.5, BorderSizePixel=0, Parent=botBar})
CR(999, avatarBg); ST(C.accHi, 1, avatarBg)
local avatarImg = N("ImageLabel",{Size=UDim2.new(1,-4,1,-4), Position=UDim2.new(0,2,0,2),
    BackgroundTransparency=1, Image="", Parent=avatarBg})
CR(999, avatarImg)
task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(lp.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    if ok and url then avatarImg.Image = url end
end)

N("TextLabel",{Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,48,0,0),
    BackgroundTransparency=1, Text=lp.DisplayName,
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=botBar})

-- ════════════════════════════════════════════════════════
-- MINIMIZE DOT
-- ════════════════════════════════════════════════════════
local dot = N("Frame",{Size=UDim2.new(0,36,0,36), Position=UDim2.new(0,10,0.5,-18),
    BackgroundColor3=C.side, BorderSizePixel=0, Active=true, Visible=false, Parent=gui})
CR(8, dot); ST(C.acc, 1.2, dot)
N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="✦", TextColor3=Color3.fromRGB(140,80,255),
    TextSize=16, Font=Enum.Font.GothamBold, Parent=dot})

closeBtn.MouseButton1Click:Connect(function() main.Visible=false; dot.Visible=true end)

local dotDrag, dotS, dotO, dotMov, dotLi = false, nil, nil, false, nil
dot.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        dotDrag=true; dotS=i.Position; dotO=dot.Position; dotMov=false end
end)
dot.InputChanged:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseMovement
    or i.UserInputType==Enum.UserInputType.Touch then dotLi=i end
end)
UIS.InputChanged:Connect(function(i)
    if i==dotLi and dotDrag then
        local d = i.Position - dotS
        if d.Magnitude > 5 then dotMov = true end
        dot.Position = UDim2.new(dotO.X.Scale,dotO.X.Offset+d.X,dotO.Y.Scale,dotO.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if dotDrag and (i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch) then
        dotDrag = false
        if not dotMov then main.Visible=true; dot.Visible=false end
    end
end)
