
local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")
local lp       = Players.LocalPlayer

local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
lp.CharacterAdded:Connect(function(c)
    char = c; hrp = c:WaitForChild("HumanoidRootPart")
end)

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

local RARITY_NAME  = { "Easy","Medium","Hard","Insane","Boss","Secret" }
local RARITY_COLOR = {
    Color3.fromRGB(80,  200, 80),
    Color3.fromRGB(80,  140, 255),
    Color3.fromRGB(255, 140, 40),
    Color3.fromRGB(220, 50,  50),
    Color3.fromRGB(200, 60,  255),
    Color3.fromRGB(255, 210, 0),
}


local farmActive     = false
local statusText     = "Idle"
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
        if v:IsA("BodyPosition") or v:IsA("AlignPosition")
        or v:IsA("BodyVelocity") or v:IsA("BodyGyro")
        or v:IsA("AlignOrientation") then v:Destroy() end
    end
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

        if #pool == 0 then statusText = "No enemies"; task.wait(1); continue end

        local enemy = pool[math.random(#pool)]
        local part  = findNPC(enemy)

        if part then
            statusText = "→ " .. enemy.name
            clearMovers()
            hrp.CFrame = CFrame.new(part.Position)
            task.wait(0.05)
            waitDead(part, 15)
        else
            statusText = "Cari: " .. enemy.name
            task.wait(0.8)
        end
        task.wait(0.05)
    end
    statusText = "Idle"
end

local C = {
    bg   = Color3.fromRGB(8,   5,   20),
    panel= Color3.fromRGB(16,  10,  38),
    hdr  = Color3.fromRGB(22,  13,  50),
    acc  = Color3.fromRGB(95,  45,  205),
    txt  = Color3.fromRGB(215, 195, 255),
    sub  = Color3.fromRGB(110, 80,  170),
    tOn  = Color3.fromRGB(85,  30,  195),
    tOff = Color3.fromRGB(38,  22,  68),
    kOn  = Color3.fromRGB(200, 156, 255),
    kOff = Color3.fromRGB(125, 80,  190),
    red  = Color3.fromRGB(185, 35,  60),
    sep  = Color3.fromRGB(60,  30,  120),
    stat = Color3.fromRGB(13,  8,   30),
    item = Color3.fromRGB(11,  6,   26),
    sel  = Color3.fromRGB(30,  16,  65),
}

local GW     = 310
local HDR_H  = 34
local ROW_H  = 30
local ITEM_H = 24
local BOT_H  = 30
local MAXVIS = 4

local function N(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function CR(r,p) N("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function ST(c,t,p) N("UIStroke",{Color=c,Thickness=t},p) end

local function makeDrag(handle, target)
    local mv = target or handle
    local drag,s,o,li = false,nil,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; s=i.Position; o=mv.Position
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch then li=i end
    end)
    UIS.InputChanged:Connect(function(i)
        if i==li and drag then
            local d=i.Position-s
            mv.Position=UDim2.new(o.X.Scale,o.X.Offset+d.X,o.Y.Scale,o.Y.Offset+d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
end

pcall(function()
    local old = lp.PlayerGui:FindFirstChild("ArcheronHub")
    if old then old:Destroy() end
end)

local gui = N("ScreenGui",{
    Name="ArcheronHub", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
    Parent=(gethui and gethui()) or lp.PlayerGui
})

local doLayout, buildEnemyList
local worldListOpen = false
local enemyListOpen = false
local worldItemFrames = {}

local baseH = HDR_H + ROW_H + ROW_H + BOT_H
local main = N("Frame",{
    Size=UDim2.new(0,GW,0,baseH),
    Position=UDim2.new(0.5,-GW/2,0.5,-baseH/2),
    BackgroundColor3=C.bg, BorderSizePixel=0,
    ClipsDescendants=true, Parent=gui
})
CR(10,main); ST(C.acc,1.5,main)

local hdr = N("Frame",{
    Size=UDim2.new(1,0,0,HDR_H), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.hdr, BorderSizePixel=0, Active=true, Parent=main
})
CR(10,hdr)
N("Frame",{Size=UDim2.new(1,0,0.5,0),Position=UDim2.new(0,0,0.5,0),
    BackgroundColor3=C.hdr,BorderSizePixel=0,Parent=hdr})
N("TextLabel",{
    Size=UDim2.new(1,-42,1,0),Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1,Text="✦  ARCHERON HUB",
    TextColor3=Color3.fromRGB(175,125,255),TextSize=12,
    Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,Parent=hdr
})
local closeBtn = N("TextButton",{
    Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-28,0.5,-11),
    BackgroundColor3=C.red,Text="✕",TextColor3=Color3.fromRGB(255,255,255),
    TextSize=10,Font=Enum.Font.GothamBold,BorderSizePixel=0,Parent=hdr
})
CR(5,closeBtn)
makeDrag(hdr,main)

local worldRow = N("Frame",{
    Size=UDim2.new(1,0,0,ROW_H),Position=UDim2.new(0,0,0,HDR_H),
    BackgroundColor3=C.panel,BorderSizePixel=0,Parent=main
})
N("TextLabel",{
    Size=UDim2.new(0,54,1,0),Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,Text="World",
    TextColor3=C.sub,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=worldRow
})
local worldVal = N("TextLabel",{
    Size=UDim2.new(1,-76,1,0),Position=UDim2.new(0,56,0,0),
    BackgroundTransparency=1,Text=WORLDS[1].name,
    TextColor3=C.txt,TextSize=10,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=worldRow
})
local worldArrow = N("TextLabel",{
    Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),
    BackgroundTransparency=1,Text="▾",
    TextColor3=C.sub,TextSize=9,Font=Enum.Font.GothamBold,Parent=worldRow
})
N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=worldRow}
).MouseButton1Click:Connect(function()
    worldListOpen = not worldListOpen
    worldArrow.Text = worldListOpen and "▴" or "▾"
    doLayout()
end)

local worldList = N("ScrollingFrame",{
    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,HDR_H+ROW_H),
    BackgroundColor3=C.item,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=C.acc,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    Visible=false,Parent=main
})
N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},worldList)

for i, w in ipairs(WORLDS) do
    local item = N("Frame",{
        Size=UDim2.new(1,0,0,ITEM_H),
        BackgroundColor3=i==1 and C.sel or C.item,
        BorderSizePixel=0,LayoutOrder=i,Parent=worldList
    })
    local lbl = N("TextLabel",{
        Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,Text=w.name,
        TextColor3=i==1 and C.txt or C.sub,
        TextSize=10,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,Parent=item
    })
    worldItemFrames[i] = {frame=item, label=lbl}
    local idx = i
    N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=item}
    ).MouseButton1Click:Connect(function()
        local old = worldItemFrames[selectedWorld]
        if old then old.frame.BackgroundColor3=C.item; old.label.TextColor3=C.sub end
        selectedWorld = idx
        item.BackgroundColor3 = C.sel; lbl.TextColor3 = C.txt
        worldVal.Text = w.name
        worldListOpen = false; worldArrow.Text = "▾"
        enemyListOpen = false
        resetEnemies(); buildEnemyList(); doLayout()
    end)
end

local enemyRow = N("Frame",{
    Size=UDim2.new(1,0,0,ROW_H),Position=UDim2.new(0,0,0,HDR_H+ROW_H),
    BackgroundColor3=C.panel,BorderSizePixel=0,Parent=main
})
N("TextLabel",{
    Size=UDim2.new(0,56,1,0),Position=UDim2.new(0,8,0,0),
    BackgroundTransparency=1,Text="Enemies",
    TextColor3=C.sub,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=enemyRow
})
local enemyVal = N("TextLabel",{
    Size=UDim2.new(1,-78,1,0),Position=UDim2.new(0,62,0,0),
    BackgroundTransparency=1,Text="All",
    TextColor3=C.txt,TextSize=10,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=enemyRow
})
local enemyArrow = N("TextLabel",{
    Size=UDim2.new(0,16,1,0),Position=UDim2.new(1,-18,0,0),
    BackgroundTransparency=1,Text="▾",
    TextColor3=C.sub,TextSize=9,Font=Enum.Font.GothamBold,Parent=enemyRow
})
N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=enemyRow}
).MouseButton1Click:Connect(function()
    local w = WORLDS[selectedWorld]
    if not w or #w.enemies==0 then return end
    enemyListOpen = not enemyListOpen
    enemyArrow.Text = enemyListOpen and "▴" or "▾"
    doLayout()
end)

local enemyList = N("ScrollingFrame",{
    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,HDR_H+ROW_H+ROW_H),
    BackgroundColor3=C.item,BorderSizePixel=0,
    ScrollBarThickness=3,ScrollBarImageColor3=C.acc,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,
    Visible=false,Parent=main
})
N("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,0)},enemyList)

local botBar = N("Frame",{
    Size=UDim2.new(1,0,0,BOT_H),Position=UDim2.new(0,0,0,HDR_H+ROW_H+ROW_H),
    BackgroundColor3=C.stat,BorderSizePixel=0,Parent=main
})
N("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.sep,BorderSizePixel=0,Parent=botBar})

local pill = N("Frame",{
    Size=UDim2.new(0,36,0,18),Position=UDim2.new(0,8,0.5,-9),
    BackgroundColor3=C.tOff,BorderSizePixel=0,Parent=botBar
})
CR(999,pill)
local knob = N("Frame",{
    Size=UDim2.new(0,14,0,14),Position=UDim2.new(0,2,0.5,-7),
    BackgroundColor3=C.kOff,BorderSizePixel=0,Parent=pill
})
CR(999,knob)
N("TextLabel",{
    Size=UDim2.new(0,60,1,0),Position=UDim2.new(0,50,0,0),
    BackgroundTransparency=1,Text="Auto Farm",
    TextColor3=C.txt,TextSize=10,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left,Parent=botBar
})
local statLbl = N("TextLabel",{
    Size=UDim2.new(1,-115,1,0),Position=UDim2.new(0,115,0,0),
    BackgroundTransparency=1,Text="● Idle",
    TextColor3=C.sub,TextSize=9,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Right,Parent=botBar
})
task.spawn(function()
    while task.wait(0.5) do statLbl.Text="● "..statusText end
end)

local farmState = false
local ti = TweenInfo.new(0.15,Enum.EasingStyle.Quad)
N("TextButton",{
    Size=UDim2.new(0,115,1,0),BackgroundTransparency=1,Text="",Parent=botBar
}).MouseButton1Click:Connect(function()
    farmState = not farmState; farmActive = farmState
    TweenSvc:Create(pill,ti,{BackgroundColor3=farmState and C.tOn or C.tOff}):Play()
    TweenSvc:Create(knob,ti,{
        Position=farmState and UDim2.new(0,20,0.5,-7) or UDim2.new(0,2,0.5,-7),
        BackgroundColor3=farmState and C.kOn or C.kOff
    }):Play()
    if farmState then task.spawn(farmLoop) end
end)

local dot = N("Frame",{
    Size=UDim2.new(0,32,0,32),Position=UDim2.new(0,10,0.5,-16),
    BackgroundColor3=C.panel,BorderSizePixel=0,
    Active=true,Visible=false,Parent=gui
})
CR(8,dot); ST(C.acc,1.5,dot)
N("TextLabel",{
    Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="✦",
    TextColor3=Color3.fromRGB(155,95,255),TextSize=14,Font=Enum.Font.GothamBold,Parent=dot
})

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

doLayout = function()
    local y = HDR_H
    worldRow.Position = UDim2.new(0,0,0,y); y = y + ROW_H
    if worldListOpen then
        local cnt = math.min(#WORLDS, MAXVIS)
        worldList.Visible=true
        worldList.Size=UDim2.new(1,0,0,cnt*ITEM_H)
        worldList.Position=UDim2.new(0,0,0,y)
        y = y + cnt*ITEM_H
    else
        worldList.Visible=false
    end
    enemyRow.Position = UDim2.new(0,0,0,y); y = y + ROW_H
    local w = WORLDS[selectedWorld]
    local ecnt = w and #w.enemies or 0
    if enemyListOpen and ecnt>0 then
        local vcnt = math.min(ecnt, MAXVIS)
        enemyList.Visible=true
        enemyList.Size=UDim2.new(1,0,0,vcnt*ITEM_H)
        enemyList.Position=UDim2.new(0,0,0,y)
        y = y + vcnt*ITEM_H
    else
        enemyList.Visible=false
    end
    botBar.Position=UDim2.new(0,0,0,y); y = y + BOT_H
    TweenSvc:Create(main,TweenInfo.new(0.16,Enum.EasingStyle.Quad),
        {Size=UDim2.new(0,GW,0,y)}):Play()
end

local function updateEnemyVal()
    local w = WORLDS[selectedWorld]
    if not w then enemyVal.Text="All"; return end
    local on=0
    for i=1,#w.enemies do if enabledEnemies[i] then on=on+1 end end
    enemyVal.Text = on==#w.enemies and "All" or on==0 and "None" or on.."/"..#w.enemies
end

buildEnemyList = function()
    for _, c in ipairs(enemyList:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    local w = WORLDS[selectedWorld]
    if not w then return end
    for i, e in ipairs(w.enemies) do
        local item = N("Frame",{
            Size=UDim2.new(1,0,0,ITEM_H),BackgroundColor3=C.item,
            BorderSizePixel=0,LayoutOrder=i,Parent=enemyList
        })
        local chk = N("Frame",{
            Size=UDim2.new(0,12,0,12),Position=UDim2.new(0,8,0.5,-6),
            BackgroundColor3=enabledEnemies[i] and C.acc or C.panel,
            BorderSizePixel=0,Parent=item
        })
        CR(3,chk)
        N("TextLabel",{
            Size=UDim2.new(1,-88,1,0),Position=UDim2.new(0,26,0,0),
            BackgroundTransparency=1,Text=e.name,
            TextColor3=C.txt,TextSize=10,Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left,Parent=item
        })
        local rc = RARITY_COLOR[e.rarity] or C.sub
        local rb = N("Frame",{
            Size=UDim2.new(0,0,0,14),AutomaticSize=Enum.AutomaticSize.X,
            Position=UDim2.new(1,-4,0.5,-7),AnchorPoint=Vector2.new(1,0),
            BackgroundColor3=rc,BackgroundTransparency=0.55,
            BorderSizePixel=0,Parent=item
        })
        CR(4,rb)
        N("TextLabel",{
            Size=UDim2.new(0,0,1,0),AutomaticSize=Enum.AutomaticSize.X,
            BackgroundTransparency=1,
            Text=" "..(RARITY_NAME[e.rarity] or "?").." ",
            TextColor3=rc,TextSize=8,Font=Enum.Font.GothamBold,Parent=rb
        })
        local idx=i
        N("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Parent=item}
        ).MouseButton1Click:Connect(function()
            enabledEnemies[idx] = not enabledEnemies[idx]
            TweenSvc:Create(chk,TweenInfo.new(0.1),{
                BackgroundColor3=enabledEnemies[idx] and C.acc or C.panel
            }):Play()
            updateEnemyVal()
        end)
    end
    updateEnemyVal()
end

buildEnemyList()
doLayout()
