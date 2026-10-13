-- Archeron Hub v2.3 | World NPC Auto Farm
-- Sidebar layout + World Teleport (BridgeNet) + auto-TP on NPC miss
-- EnemyName attribute detection · Died attribute death check

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
-- DATA  (isi nama + rarity dari lo nanti)
-- rarity: 1=Easy  2=Medium  3=Hard  4=Insane  5=Boss  6=Secret
-- ════════════════════════════════════════════════════════
local WORLDS = {
    { name = "Heaven Island", enemies = {
        { name = "Kume", rarity = 1 },
        { name = "Robin Lucco", rarity = 2 },
        { name = "Buggo", rarity = 3 },
        { name = "Kuzon", rarity = 4 },
        { name = "Hawk Eyes", rarity = 5 },
        { name = "Anel", rarity = 6 },
    }},
    { name = "Slayers Village", enemies = {
        { name = "Kaigako", rarity = 1 },
        { name = "Gyotaro", rarity = 2 },
        { name = "Hantengue", rarity = 3 },
        { name = "Akeza", rarity = 4 },
        { name = "Doume", rarity = 5 },
        { name = "Kukushibe", rarity = 6 },
    }},
    { name = "Cursed Academy", enemies = {
        { name = "Jogu", rarity = 1 },
        { name = "Toje", rarity = 2 },
        { name = "Mahita", rarity = 3 },
        { name = "Lyu", rarity = 4 },
        { name = "Kashimu", rarity = 5 },
        { name = "Sokona", rarity = 6 },
    }},
    { name = "Sins Kingdom", enemies = {
        { name = "Melascule", rarity = 1 },
        { name = "Monspit", rarity = 2 },
        { name = "Derriere", rarity = 3 },
        { name = "Gloxine", rarity = 4 },
        { name = "Malel", rarity = 5 },
        { name = "Chaos Arthur", rarity = 6 },
    }},
}

local RARITY_COLOR = {
    Color3.fromRGB(80,  200,  80),   -- 1 Easy
    Color3.fromRGB(80,  140, 255),   -- 2 Medium
    Color3.fromRGB(255, 140,  40),   -- 3 Hard
    Color3.fromRGB(220,  50,  50),   -- 4 Insane
    Color3.fromRGB(200,  60, 255),   -- 5 Boss
    Color3.fromRGB(255, 210,   0),   -- 6 Secret
}

-- ════════════════════════════════════════════════════════
-- LOGIC
-- ════════════════════════════════════════════════════════
local farmActive     = false
local selectedWorld  = 1
local enabledEnemies = {}

local function resetEnemies()
    enabledEnemies = {}
    local w = WORLDS[selectedWorld]
    if w then for i = 1, #w.enemies do enabledEnemies[i] = true end end
end
resetEnemies()

local function clearMovers()
    local h = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    if not h then return end
    for _, v in pairs(h:GetChildren()) do
        if  v:IsA("BodyPosition")    or v:IsA("AlignPosition")
        or  v:IsA("BodyVelocity")    or v:IsA("BodyGyro")
        or  v:IsA("AlignOrientation") then v:Destroy() end
    end
end

local function tpWorld(worldName)
    local ok, bn = pcall(function() return RS:WaitForChild("BridgeNet", 5) end)
    if not ok or not bn then return end
    local ok2, ev = pcall(function() return bn:WaitForChild("dataRemoteEvent", 5) end)
    if not ok2 or not ev then return end
    ev:FireServer({
        {"\x01", "\xBE\x05\xDD\t\x01qC\x94\x82V\xEA]\xE2/@\xDF",
         {"General","Maps","Teleport", worldName, n=4}},
        "\x02"
    })
end

local function findNPC(enemy)
    local hits = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:GetAttribute("Died") then
            local en = v:GetAttribute("EnemyName")
            if en and en == enemy.name then table.insert(hits, v) end
        end
    end
    return #hits > 0 and hits[math.random(#hits)] or nil
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

local function farmLoop()
    local lastTpWorld = nil
    while farmActive do
        char = lp.Character
        if not char then task.wait(1); continue end
        hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1); continue end

        local pool = {}
        local w = WORLDS[selectedWorld]
        if w then
            for i, e in ipairs(w.enemies) do
                if enabledEnemies[i] then table.insert(pool, e) end
            end
        end

        if #pool == 0 then task.wait(1); continue end

        local enemy = pool[math.random(#pool)]
        local part  = findNPC(enemy)

        if part then
            lastTpWorld = nil
            clearMovers()
            hrp.CFrame = CFrame.new(part.Position)
            task.wait(0.05)
            waitDead(part, 15)
        else
            local wname = w and w.name or ""
            if lastTpWorld ~= wname then
                tpWorld(wname)
                lastTpWorld = wname
                task.wait(3.5)
            else
                task.wait(0.8)
            end
        end
        task.wait(0.05)
    end
end

-- ════════════════════════════════════════════════════════
-- GUI CONSTANTS
-- ════════════════════════════════════════════════════════
local C = {
    bg    = Color3.fromRGB(7,   4,  18),
    side  = Color3.fromRGB(10,  6,  24),
    panel = Color3.fromRGB(13,  9,  30),
    hdr   = Color3.fromRGB(9,   6,  22),
    acc   = Color3.fromRGB(95,  45, 205),
    accHi = Color3.fromRGB(135, 75, 255),
    txt   = Color3.fromRGB(210, 188, 255),
    sub   = Color3.fromRGB(95,  65, 155),
    tOn   = Color3.fromRGB(75,  28, 185),
    tOff  = Color3.fromRGB(32,  18,  58),
    kOn   = Color3.fromRGB(185, 135, 255),
    kOff  = Color3.fromRGB(110,  65, 175),
    red   = Color3.fromRGB(178,  32,  52),
    sep   = Color3.fromRGB(45,  22,  90),
    item  = Color3.fromRGB(9,    5,  21),
    sel   = Color3.fromRGB(23,  12,  52),
    bot   = Color3.fromRGB(8,    5,  20),
    actS  = Color3.fromRGB(120,  60, 240),
}

local GW        = 510
local SW        = 68
local CW        = GW - SW
local HDR_H     = 34
local BOT_H     = 48
local ROW_H     = 34
local ITEM_H    = 28
local CONTENT_H = 268
local TOTAL_H   = HDR_H + CONTENT_H + BOT_H   -- 350

-- ─── helpers ───
local function N(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function CR(r, p) N("UICorner",  {CornerRadius=UDim.new(0,r)}, p) end
local function ST(c, t, p) N("UIStroke",{Color=c, Thickness=t}, p) end

local function makeDrag(handle, target)
    local mv = target or handle
    local drag, s, o, li = false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; s = i.Position; o = mv.Position
        end
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

-- ════════════════════════════════════════════════════════
-- SCREEN GUI + MAIN FRAME
-- ════════════════════════════════════════════════════════
pcall(function()
    local old = lp.PlayerGui:FindFirstChild("ArcheronHub")
    if old then old:Destroy() end
end)

local gui = N("ScreenGui", {
    Name="ArcheronHub", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=(gethui and gethui()) or lp.PlayerGui,
})

local main = N("Frame", {
    Size=UDim2.new(0,GW,0,TOTAL_H),
    Position=UDim2.new(0.5,-GW/2,0.4,-TOTAL_H/2),
    BackgroundColor3=C.bg, BorderSizePixel=0,
    ClipsDescendants=true, Parent=gui,
})
CR(10, main)
ST(C.sep, 1.2, main)

-- ════════════════════════════════════════════════════════
-- HEADER
-- ════════════════════════════════════════════════════════
local hdr = N("Frame", {
    Size=UDim2.new(1,0,0,HDR_H),
    BackgroundColor3=C.hdr, BorderSizePixel=0,
    Active=true, Parent=main,
})
CR(10, hdr)
N("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),
    BackgroundColor3=C.hdr,BorderSizePixel=0,Parent=hdr})

local notch = N("Frame",{
    Size=UDim2.new(0,3,0,18),Position=UDim2.new(0,12,0.5,-9),
    BackgroundColor3=C.accHi,BorderSizePixel=0,Parent=hdr,
})
CR(2, notch)
N("TextLabel",{
    Size=UDim2.new(0,160,1,0),Position=UDim2.new(0,22,0,0),
    BackgroundTransparency=1, Text="ARCHERON  HUB",
    TextColor3=Color3.fromRGB(160,100,255),
    TextSize=12,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=hdr,
})
local vb = N("Frame",{
    Size=UDim2.new(0,32,0,15),Position=UDim2.new(0,186,0.5,-7),
    BackgroundColor3=C.acc,BackgroundTransparency=0.45,
    BorderSizePixel=0,Parent=hdr,
})
CR(4,vb)
N("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
    Text="v2.3",TextColor3=Color3.fromRGB(195,150,255),
    TextSize=8,Font=Enum.Font.GothamBold,Parent=vb})

local closeBtn = N("TextButton",{
    Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-28,0.5,-11),
    BackgroundColor3=C.red,Text="×",
    TextColor3=Color3.fromRGB(255,255,255),
    TextSize=15,Font=Enum.Font.GothamBold,
    BorderSizePixel=0,Parent=hdr,
})
CR(5,closeBtn)
makeDrag(hdr, main)

-- ════════════════════════════════════════════════════════
-- SIDEBAR
-- ════════════════════════════════════════════════════════
local sidebar = N("Frame",{
    Size=UDim2.new(0,SW,0,CONTENT_H),
    Position=UDim2.new(0,0,0,HDR_H),
    BackgroundColor3=C.side,BorderSizePixel=0,Parent=main,
})
N("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),
    BackgroundColor3=C.sep,BorderSizePixel=0,Parent=sidebar})

local TABS = {
    { label="▶", name="Main"     },
    { label="◈", name="Settings" },
}
local activeTab = 1
local tabBtns   = {}

for i, t in ipairs(TABS) do
    local yp = (i-1)*56 + 16
    local tb = N("Frame",{
        Size=UDim2.new(0,SW-2,0,48),Position=UDim2.new(0,1,0,yp),
        BackgroundColor3=i==1 and C.sel or C.side,BorderSizePixel=0,Parent=sidebar,
    })
    CR(6,tb)
    local strip = N("Frame",{
        Size=UDim2.new(0,3,0,28),Position=UDim2.new(0,0,0.5,-14),
        BackgroundColor3=i==1 and C.actS or C.side,BorderSizePixel=0,Parent=tb,
    })
    CR(2,strip)
    local iconLbl = N("TextLabel",{
        Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,0,6),
        BackgroundTransparency=1,Text=t.label,
        TextColor3=i==1 and Color3.fromRGB(185,130,255) or C.sub,
        TextSize=15,Font=Enum.Font.GothamBold,Parent=tb,
    })
    local nameLbl = N("TextLabel",{
        Size=UDim2.new(1,0,0,13),Position=UDim2.new(0,0,1,-16),
        BackgroundTransparency=1,Text=t.name,
        TextColor3=i==1 and C.txt or C.sub,
        TextSize=9,Font=Enum.Font.Gotham,Parent=tb,
    })
    tabBtns[i] = {frame=tb, strip=strip, icon=iconLbl, name=nameLbl}
    local idx = i
    N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=tb}
    ).MouseButton1Click:Connect(function()
        local prev = tabBtns[activeTab]
        if prev then
            prev.frame.BackgroundColor3 = C.side
            prev.strip.BackgroundColor3 = C.side
            prev.icon.TextColor3 = C.sub
            prev.name.TextColor3 = C.sub
        end
        activeTab = idx
        tb.BackgroundColor3    = C.sel
        strip.BackgroundColor3 = C.actS
        iconLbl.TextColor3     = Color3.fromRGB(185,130,255)
        nameLbl.TextColor3     = C.txt
    end)
end

-- ════════════════════════════════════════════════════════
-- CONTENT ScrollingFrame
-- ════════════════════════════════════════════════════════
local content = N("ScrollingFrame",{
    Size=UDim2.new(0,CW,0,CONTENT_H),
    Position=UDim2.new(0,SW,0,HDR_H),
    BackgroundColor3=C.panel,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=C.acc,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    ScrollingDirection=Enum.ScrollingDirection.Y,
    Parent=main,
})

-- ─── forward declarations ───
local doLayout, buildEnemyList
local worldListOpen  = false
local enemyListOpen  = false
local worldItemFrames = {}
local enemyCheckFrames = {}

-- ════════════════════════════════════════════════════════
-- WORLD ROW (dropdown trigger)  — sama persis gaya
-- ════════════════════════════════════════════════════════
local worldRow = N("Frame",{
    Size=UDim2.new(1,0,0,ROW_H),Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.panel,BorderSizePixel=0,Parent=content,
})
N("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,1,-1),
    BackgroundColor3=C.sep,BorderSizePixel=0,Parent=worldRow})
N("TextLabel",{
    Size=UDim2.new(0,46,1,0),Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1,Text="World",
    TextColor3=C.sub,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=worldRow,
})
local worldVal = N("TextLabel",{
    Size=UDim2.new(1,-70,1,0),Position=UDim2.new(0,58,0,0),
    BackgroundTransparency=1,Text=WORLDS[1].name,
    TextColor3=C.txt,TextSize=10,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=worldRow,
})
local worldArrow = N("TextLabel",{
    Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),
    BackgroundTransparency=1,Text="►",
    TextColor3=C.sub,TextSize=9,Font=Enum.Font.GothamBold,Parent=worldRow,
})
N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=worldRow}
).MouseButton1Click:Connect(function()
    worldListOpen = not worldListOpen
    worldArrow.Text = worldListOpen and "▾" or "►"
    doLayout()
end)

-- ─── World items frame (hidden until open) ───
local worldItemsFrame = N("Frame",{
    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,ROW_H),
    BackgroundColor3=C.item,BorderSizePixel=0,Visible=false,Parent=content,
})
for i, w in ipairs(WORLDS) do
    local item = N("Frame",{
        Size=UDim2.new(1,0,0,ITEM_H),
        Position=UDim2.new(0,0,0,(i-1)*ITEM_H),
        BackgroundColor3=i==1 and C.sel or C.item,
        BorderSizePixel=0,Parent=worldItemsFrame,
    })
    local wStrip = N("Frame",{
        Size=UDim2.new(0,2,0,14),Position=UDim2.new(0,6,0.5,-7),
        BackgroundColor3=i==1 and C.actS or C.item,BorderSizePixel=0,Parent=item,
    })
    CR(1,wStrip)
    local lbl = N("TextLabel",{
        Size=UDim2.new(1,-18,1,0),Position=UDim2.new(0,16,0,0),
        BackgroundTransparency=1,Text=w.name,
        TextColor3=i==1 and C.txt or C.sub,
        TextSize=10,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=item,
    })
    worldItemFrames[i] = {frame=item,label=lbl,strip=wStrip}
    local idx = i
    N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=item}
    ).MouseButton1Click:Connect(function()
        local old = worldItemFrames[selectedWorld]
        if old then
            old.frame.BackgroundColor3 = C.item
            old.label.TextColor3 = C.sub
            old.strip.BackgroundColor3 = C.item
        end
        selectedWorld = idx
        item.BackgroundColor3  = C.sel
        lbl.TextColor3         = C.txt
        wStrip.BackgroundColor3 = C.actS
        worldVal.Text = w.name
        worldListOpen = false; worldArrow.Text = "►"
        resetEnemies(); buildEnemyList(); doLayout()
    end)
end

-- ════════════════════════════════════════════════════════
-- ENEMY ROW (dropdown trigger) — sama persis gaya World
-- ════════════════════════════════════════════════════════
local enemyRow = N("Frame",{
    Size=UDim2.new(1,0,0,ROW_H),Position=UDim2.new(0,0,0,ROW_H),
    BackgroundColor3=C.panel,BorderSizePixel=0,Parent=content,
})
N("Frame",{Size=UDim2.new(1,-10,0,1),Position=UDim2.new(0,5,1,-1),
    BackgroundColor3=C.sep,BorderSizePixel=0,Parent=enemyRow})
N("TextLabel",{
    Size=UDim2.new(0,52,1,0),Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1,Text="Enemy",
    TextColor3=C.sub,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=enemyRow,
})
local enemyVal = N("TextLabel",{
    Size=UDim2.new(1,-76,1,0),Position=UDim2.new(0,64,0,0),
    BackgroundTransparency=1,Text="All",
    TextColor3=C.txt,TextSize=10,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=enemyRow,
})
local enemyArrow = N("TextLabel",{
    Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),
    BackgroundTransparency=1,Text="►",
    TextColor3=C.sub,TextSize=9,Font=Enum.Font.GothamBold,Parent=enemyRow,
})
N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=enemyRow}
).MouseButton1Click:Connect(function()
    enemyListOpen = not enemyListOpen
    enemyArrow.Text = enemyListOpen and "▾" or "►"
    doLayout()
end)

-- ─── Enemy items frame (hidden until open, built by buildEnemyList) ───
local enemyItemsFrame = N("Frame",{
    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,ROW_H*2),
    BackgroundColor3=C.item,BorderSizePixel=0,Visible=false,Parent=content,
})

-- ════════════════════════════════════════════════════════
-- BOTTOM BAR
-- ════════════════════════════════════════════════════════
local botBar = N("Frame",{
    Size=UDim2.new(1,0,0,BOT_H),
    Position=UDim2.new(0,0,0,HDR_H+CONTENT_H),
    BackgroundColor3=C.bot,BorderSizePixel=0,Parent=main,
})
N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.sep,BorderSizePixel=0,Parent=botBar})

local avatarBg = N("Frame",{
    Size=UDim2.new(0,32,0,32),Position=UDim2.new(0,10,0.5,-16),
    BackgroundColor3=C.acc,BackgroundTransparency=0.5,
    BorderSizePixel=0,Parent=botBar,
})
CR(999,avatarBg); ST(C.accHi,1,avatarBg)
local avatarImg = N("ImageLabel",{
    Size=UDim2.new(1,-4,1,-4),Position=UDim2.new(0,2,0,2),
    BackgroundTransparency=1,Image="",Parent=avatarBg,
})
CR(999,avatarImg)
task.spawn(function()
    local ok, url = pcall(function()
        return Players:GetUserThumbnailAsync(
            lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    end)
    if ok and url then avatarImg.Image = url end
end)

N("TextLabel",{
    Size=UDim2.new(0,120,1,0),Position=UDim2.new(0,48,0,0),
    BackgroundTransparency=1, Text=lp.DisplayName,
    TextColor3=C.txt,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=botBar,
})

N("Frame",{
    Size=UDim2.new(0,1,0,26),Position=UDim2.new(1,-94,0.5,-13),
    BackgroundColor3=C.sep,BorderSizePixel=0,Parent=botBar,
})
N("TextLabel",{
    Size=UDim2.new(0,52,1,0),Position=UDim2.new(1,-92,0,0),
    BackgroundTransparency=1,Text="Auto\nFarm",
    TextColor3=C.sub,TextSize=8,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Right,
    TextYAlignment=Enum.TextYAlignment.Center,Parent=botBar,
})

local pill = N("Frame",{
    Size=UDim2.new(0,40,0,20),Position=UDim2.new(1,-48,0.5,-10),
    BackgroundColor3=C.tOff,BorderSizePixel=0,Parent=botBar,
})
CR(999,pill)
local knob = N("Frame",{
    Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,2,0.5,-8),
    BackgroundColor3=C.kOff,BorderSizePixel=0,Parent=pill,
})
CR(999,knob)

local farmState = false
local ti = TweenInfo.new(0.14, Enum.EasingStyle.Quad)
N("TextButton",{
    Size=UDim2.new(0,96,1,0),Position=UDim2.new(1,-98,0,0),
    BackgroundTransparency=1,Text="",Parent=botBar,
}).MouseButton1Click:Connect(function()
    farmState = not farmState; farmActive = farmState
    TweenSvc:Create(pill, ti,{BackgroundColor3=farmState and C.tOn or C.tOff}):Play()
    TweenSvc:Create(knob, ti,{
        Position=farmState and UDim2.new(0,22,0.5,-8) or UDim2.new(0,2,0.5,-8),
        BackgroundColor3=farmState and C.kOn or C.kOff,
    }):Play()
    if farmState then task.spawn(farmLoop) end
end)

-- ════════════════════════════════════════════════════════
-- MINIMIZE DOT
-- ════════════════════════════════════════════════════════
local dot = N("Frame",{
    Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,10,0.5,-18),
    BackgroundColor3=C.side,BorderSizePixel=0,
    Active=true,Visible=false,Parent=gui,
})
CR(8,dot); ST(C.acc,1.2,dot)
N("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
    Text="✦",TextColor3=Color3.fromRGB(140,80,255),
    TextSize=16,Font=Enum.Font.GothamBold,Parent=dot})

closeBtn.MouseButton1Click:Connect(function()
    main.Visible=false; dot.Visible=true
end)

local dotDrag,dotS,dotO,dotMov,dotLi = false,nil,nil,false,nil
dot.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch then
        dotDrag=true; dotS=i.Position; dotO=dot.Position; dotMov=false
    end
end)
dot.InputChanged:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseMovement
    or i.UserInputType==Enum.UserInputType.Touch then dotLi=i end
end)
UIS.InputChanged:Connect(function(i)
    if i==dotLi and dotDrag then
        local d=i.Position-dotS
        if d.Magnitude>5 then dotMov=true end
        dot.Position=UDim2.new(dotO.X.Scale,dotO.X.Offset+d.X,dotO.Y.Scale,dotO.Y.Offset+d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if dotDrag and (i.UserInputType==Enum.UserInputType.MouseButton1
    or i.UserInputType==Enum.UserInputType.Touch) then
        dotDrag=false
        if not dotMov then main.Visible=true; dot.Visible=false end
    end
end)

-- ════════════════════════════════════════════════════════
-- LAYOUT ENGINE  (outer frame fixed, inner content scrolls)
-- ════════════════════════════════════════════════════════
doLayout = function()
    local y = ROW_H   -- below worldRow

    -- world dropdown items
    if worldListOpen then
        local h = #WORLDS * ITEM_H
        worldItemsFrame.Visible  = true
        worldItemsFrame.Size     = UDim2.new(1,0,0,h)
        worldItemsFrame.Position = UDim2.new(0,0,0,y)
        y = y + h
    else
        worldItemsFrame.Visible = false
    end

    -- enemy row
    enemyRow.Position = UDim2.new(0,0,0,y)
    y = y + ROW_H

    -- enemy dropdown items
    if enemyListOpen then
        enemyItemsFrame.Visible  = true
        enemyItemsFrame.Position = UDim2.new(0,0,0,y)
        -- size set by buildEnemyList
        y = y + enemyItemsFrame.Size.Y.Offset
    else
        enemyItemsFrame.Visible = false
    end
end

-- ════════════════════════════════════════════════════════
-- ENEMY LIST BUILDER  — flat list with checkbox + rarity dot
-- (same visual style as world items)
-- ════════════════════════════════════════════════════════
buildEnemyList = function()
    for _, c in ipairs(enemyItemsFrame:GetChildren()) do c:Destroy() end
    enemyCheckFrames = {}

    local w = WORLDS[selectedWorld]
    local enemies = w and w.enemies or {}

    -- update label on enemy row
    local enabled = 0
    for i = 1, #enemies do if enabledEnemies[i] then enabled = enabled + 1 end end
    if #enemies == 0 then
        enemyVal.Text = "—"
    elseif enabled == #enemies then
        enemyVal.Text = "All (" .. #enemies .. ")"
    else
        enemyVal.Text = enabled .. "/" .. #enemies
    end

    if #enemies == 0 then
        -- empty placeholder
        local ph = N("Frame",{
            Size=UDim2.new(1,0,0,ITEM_H),Position=UDim2.new(0,0,0,0),
            BackgroundColor3=C.item,BorderSizePixel=0,Parent=enemyItemsFrame,
        })
        N("TextLabel",{
            Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,
            Text="No enemies in data",TextColor3=C.sub,TextSize=9,
            Font=Enum.Font.Gotham,Parent=ph,
        })
        enemyItemsFrame.Size = UDim2.new(1,0,0,ITEM_H)
        return
    end

    for i, e in ipairs(enemies) do
        local item = N("Frame",{
            Size=UDim2.new(1,0,0,ITEM_H),
            Position=UDim2.new(0,0,0,(i-1)*ITEM_H),
            BackgroundColor3=C.item,BorderSizePixel=0,Parent=enemyItemsFrame,
        })
        -- rarity color dot (left strip, same as world strip)
        local rc = RARITY_COLOR[e.rarity or 1]
        local rStrip = N("Frame",{
            Size=UDim2.new(0,2,0,14),Position=UDim2.new(0,6,0.5,-7),
            BackgroundColor3=rc,BorderSizePixel=0,Parent=item,
        })
        CR(1,rStrip)
        -- checkbox
        local chk = N("Frame",{
            Size=UDim2.new(0,13,0,13),Position=UDim2.new(0,16,0.5,-6),
            BackgroundColor3=enabledEnemies[i] and C.acc or C.side,
            BorderSizePixel=0,Parent=item,
        })
        CR(3,chk)
        -- enemy name
        N("TextLabel",{
            Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,34,0,0),
            BackgroundTransparency=1,Text=e.name,
            TextColor3=C.txt,TextSize=10,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=item,
        })
        enemyCheckFrames[i] = chk
        local idx = i
        N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=item}
        ).MouseButton1Click:Connect(function()
            enabledEnemies[idx] = not enabledEnemies[idx]
            TweenSvc:Create(chk, TweenInfo.new(0.1),{
                BackgroundColor3=enabledEnemies[idx] and C.acc or C.side,
            }):Play()
            -- update counter label
            local en2 = 0
            for j = 1, #enemies do if enabledEnemies[j] then en2=en2+1 end end
            if en2 == #enemies then enemyVal.Text="All ("..#enemies..")"
            else enemyVal.Text=en2.."/"..#enemies end
        end)
    end

    enemyItemsFrame.Size = UDim2.new(1,0,0,#enemies*ITEM_H)
end

buildEnemyList()
doLayout()
