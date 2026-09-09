-- ╔══════════════════════════════════════╗
-- ║        ARCHERON HUB v1.2             ║
-- ║     99 Nights in The Forest          ║
-- ╚══════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp               = Players.LocalPlayer

-- ══════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════
local CONFIG = {
    teleportOffset = CFrame.new(0, 0, -4),
    teleportWait   = 3.0,
}

-- ══════════════════════════════════════
--  MAP DATA
-- ══════════════════════════════════════
local MAPS = {
    [0] = { name="Lobby Arena",  worldIndex=0, npcs={} },
    [1] = {
        name="Ninja Village", worldIndex=1,
        npcs={
            {name="Itache",  label="Itache"},
            {name="Kagoye",  label="Kagoye"},
            {name="Kesame",  label="Kesame"},
        },
    },
    [2] = {
        name="Namek City", worldIndex=2,
        npcs={},
    },
    [3] = {
        name="Wano Island", worldIndex=3,
        npcs={},
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
--  HELPERS
-- ══════════════════════════════════════
local function getChar()
    local c = lp.Character
    if not c then return nil,nil end
    return c, c:FindFirstChild("HumanoidRootPart")
end

-- ══════════════════════════════════════
--  DETECT ISLAND (via GUI button)
-- ══════════════════════════════════════
local function getCurrentIsland()
    local ok, result = pcall(function()
        local worlds = lp.PlayerGui.Windows.Teleport.Main.Worlds
        for _, wf in pairs(worlds:GetChildren()) do
            local tb = wf:FindFirstChild("Teleport")
            if tb then
                for _, c in pairs(tb:GetDescendants()) do
                    if (c:IsA("TextLabel") or c:IsA("TextButton"))
                    and c.Text:upper():find("RESPAWN") then
                        return tonumber(wf.Name:match("%d+"))
                    end
                end
            end
        end
        return nil
    end)
    return ok and result or nil
end

local function isPlayerAtMap(mapID)
    local cur = getCurrentIsland()
    return cur ~= nil and cur == (MAPS[mapID] and MAPS[mapID].worldIndex)
end

-- ══════════════════════════════════════
--  TELEPORT KE ISLAND
-- ══════════════════════════════════════
local function teleportToIsland(mapID)
    local md = MAPS[mapID]
    if not md then return end
    State.teleporting = true
    print("[Archeron] Teleport ke "..md.name)

    local ok = pcall(function()
        local wf = lp.PlayerGui.Windows.Teleport.Main.Worlds
            :FindFirstChild("World"..md.worldIndex)
        local tb = wf and wf:FindFirstChild("Teleport")
        local btn = tb and (tb:FindFirstChildWhichIsA("TextButton",true)
                         or tb:FindFirstChildWhichIsA("ImageButton",true))
        if btn then btn.MouseButton1Click:Fire()
        else error("btn ga ketemu") end
    end)

    if not ok then
        warn("[Archeron] GUI teleport gagal, fallback RemoteEvent")
        local RS = game:GetService("ReplicatedStorage")
        local ev = RS:FindFirstChild("BridgeNet2") and RS.BridgeNet2.dataRemoteEvent
        if ev then ev:FireServer({md.worldIndex, "\xF5"}) end
    end

    task.wait(CONFIG.teleportWait)
    State.teleporting = false
end

-- ══════════════════════════════════════
--  GET ENEMIES
--  - Sumber CFrame  : ClientEnemyVisuals
--  - Sumber alive   : Worlds[mapID].Enemies
--  - Fix duplikat   : cek SEMUA instance di Enemies, bukan FindFirstChild
-- ══════════════════════════════════════
local function getEnemies(mapID)
    local result = {}
    local visFolder = workspace:FindFirstChild("ClientEnemyVisuals")
    if not visFolder then return result end

    local md = MAPS[mapID]
    if not md then return result end

    -- Kumpulin semua server enemies yang masih hidup (handle duplikat)
    local aliveNames = {} -- set nama yang masih hidup di server
    local wf = workspace:FindFirstChild("Worlds")
             and workspace.Worlds:FindFirstChild(tostring(md.worldIndex))
    local ef = wf and wf:FindFirstChild("Enemies")
    if ef then
        for _, mob in pairs(ef:GetChildren()) do
            local hum = mob:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                -- Pakai counter biar bisa handle duplikat nama
                aliveNames[mob.Name] = (aliveNames[mob.Name] or 0) + 1
            end
        end
    end

    -- Sekarang scan ClientEnemyVisuals
    for _, vis in pairs(visFolder:GetChildren()) do
        -- Filter sesuai pilihan NPC
        local match = false
        if State.selectedNPC and State.selectedNPC ~= "" then
            match = (vis.Name == State.selectedNPC)
        else
            for _, nd in pairs(md.npcs) do
                if vis.Name == nd.name then match=true; break end
            end
        end

        if match then
            local visHRP = vis:FindFirstChild("HumanoidRootPart")
            if visHRP then
                -- Cek masih ada di server side (alive)
                local alive = false
                if ef then
                    -- Cek count, kalau masih ada yg hidup = valid
                    alive = (aliveNames[vis.Name] or 0) > 0
                else
                    -- Fallback: cek humanoid di visual
                    local hum = vis:FindFirstChildOfClass("Humanoid")
                    alive = hum and hum.Health > 0
                end

                if alive then
                    table.insert(result, {model=vis, hrp=visHRP})
                end
            end
        end
    end

    return result
end

-- ══════════════════════════════════════
--  PILIH TARGET
-- ══════════════════════════════════════
local function selectTarget(enemies)
    if #enemies == 0 then return nil end
    local _, phrp = getChar()

    if State.targetMode == "nearest" and phrp then
        local best, bd = nil, math.huge
        for _, e in pairs(enemies) do
            local d = (e.hrp.Position - phrp.Position).Magnitude
            if d < bd then bd=d; best=e end
        end
        return best
    end

    -- Untuk lowestHP/highestHP, ambil dari server folder
    local md = MAPS[State.selectedMap]
    local wf = workspace:FindFirstChild("Worlds")
             and workspace.Worlds:FindFirstChild(tostring(md and md.worldIndex or 0))
    local ef = wf and wf:FindFirstChild("Enemies")

    local function getHP(e)
        if ef then
            -- Cari instance dengan nama sama yang masih hidup
            for _, mob in pairs(ef:GetChildren()) do
                if mob.Name == e.model.Name then
                    local hum = mob:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then return hum.Health end
                end
            end
        end
        return 0
    end

    if State.targetMode == "lowestHP" then
        local best, bv = nil, math.huge
        for _, e in pairs(enemies) do
            local hp = getHP(e)
            if hp < bv then bv=hp; best=e end
        end
        return best
    elseif State.targetMode == "highestHP" then
        local best, bv = nil, -math.huge
        for _, e in pairs(enemies) do
            local hp = getHP(e)
            if hp > bv then bv=hp; best=e end
        end
        return best
    end

    return enemies[1]
end

-- ══════════════════════════════════════
--  FARM LOOP - Heartbeat (gercep)
--  Kalau gaada target = diem (skip)
--  Kalau ada = langsung CFrame
-- ══════════════════════════════════════
local function stopFarmLoop()
    if State.farmLoop then State.farmLoop:Disconnect(); State.farmLoop=nil end
    State.farmEnabled = false
end

local function startFarmLoop()
    if State.farmLoop then State.farmLoop:Disconnect() end
    State.farmLoop = RunService.Heartbeat:Connect(function()
        if not State.farmEnabled or State.teleporting then return end
        local _, hrp = getChar()
        if not hrp then return end

        local enemies = getEnemies(State.selectedMap)
        local target  = selectTarget(enemies)
        if target and target.hrp and target.hrp.Parent then
            hrp.CFrame = target.hrp.CFrame * CONFIG.teleportOffset
        end
        -- gaada target = diem, tunggu respawn otomatis
    end)
end

function ToggleFarm(on)
    State.farmEnabled = on
    if not on then stopFarmLoop(); return end

    local md = MAPS[State.selectedMap]
    print("[Archeron] Farm ON | "..md.name.." | NPC:"..(State.selectedNPC or "All").." | "..State.targetMode)

    task.spawn(function()
        local cur = getCurrentIsland()
        if cur ~= nil and cur == md.worldIndex then
            print("[Archeron] Udah di island, langsung farm")
            startFarmLoop()
        else
            teleportToIsland(State.selectedMap)
            if State.farmEnabled then startFarmLoop() end
        end
    end)
end

function SetMap(id)   State.selectedMap=id; State.selectedNPC=nil end
function SetNPC(n)    State.selectedNPC=(n~=""and n or nil) end
function SetTarget(m) State.targetMode=m end
function GetNPCs(id)  return MAPS[id] and MAPS[id].npcs or {} end

-- ══════════════════════════════════════
--  GUI
--  Compact kayak VexonHub:
--  Lebar 340, tinggi 400, fixed (bukan scrolling)
--  Sidebar 110px | Panel sisanya
-- ══════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name = "ArcheronHub"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.Parent = lp.PlayerGui

-- Warna
local C = {
    bg      = Color3.fromRGB(12,15,28),
    sidebar = Color3.fromRGB(9,12,22),
    topbar  = Color3.fromRGB(255,255,255),
    accent  = Color3.fromRGB(74,158,255),
    white   = Color3.fromRGB(255,255,255),
    red     = Color3.fromRGB(255,74,106),
    green   = Color3.fromRGB(34,197,94),
    row     = Color3.fromRGB(255,255,255),
}

-- ── MAIN FRAME ──
local Hub = Instance.new("Frame")
Hub.Name = "Hub"
Hub.Size = UDim2.new(0,340,0,400)
Hub.Position = UDim2.new(0.5,-170,0.5,-200)
Hub.BackgroundColor3 = C.bg
Hub.BorderSizePixel = 0
Hub.Active = true
Hub.Parent = SG
local hc = Instance.new("UICorner",Hub); hc.CornerRadius=UDim.new(0,12)
local hs = Instance.new("UIStroke",Hub); hs.Color=C.white; hs.Transparency=0.88; hs.Thickness=1

-- ── TOPBAR (drag handle) ──
local Top = Instance.new("Frame",Hub)
Top.Size = UDim2.new(1,0,0,36)
Top.BackgroundColor3 = C.topbar
Top.BackgroundTransparency = 0.94
Top.BorderSizePixel = 0
Top.Active = true
local tc = Instance.new("UICorner",Top); tc.CornerRadius=UDim.new(0,12)

-- Logo
local Logo = Instance.new("TextLabel",Top)
Logo.Size = UDim2.new(0,26,0,26)
Logo.Position = UDim2.new(0,7,0.5,-13)
Logo.BackgroundColor3 = C.white
Logo.BorderSizePixel = 0
Logo.Text = "Ar"
Logo.TextColor3 = C.bg
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 11
Instance.new("UICorner",Logo).CornerRadius=UDim.new(0,7)

local Ttl = Instance.new("TextLabel",Top)
Ttl.Size = UDim2.new(0,100,0,14)
Ttl.Position = UDim2.new(0,38,0,5)
Ttl.BackgroundTransparency=1
Ttl.Text="Archeron Hub"
Ttl.TextColor3=C.white
Ttl.Font=Enum.Font.GothamBold
Ttl.TextSize=11
Ttl.TextXAlignment=Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel",Top)
Sub.Size = UDim2.new(0,140,0,10)
Sub.Position = UDim2.new(0,38,0,20)
Sub.BackgroundTransparency=1
Sub.Text="99 Nights in The Forest"
Sub.TextColor3=C.white; Sub.TextTransparency=0.65
Sub.Font=Enum.Font.Gotham; Sub.TextSize=8
Sub.TextXAlignment=Enum.TextXAlignment.Left

-- Island indicator
local IslandLbl = Instance.new("TextLabel",Top)
IslandLbl.Size = UDim2.new(0,80,0,14)
IslandLbl.Position = UDim2.new(1,-130,0.5,-7)
IslandLbl.BackgroundColor3=C.accent; IslandLbl.BackgroundTransparency=0.85
IslandLbl.BorderSizePixel=0
IslandLbl.Text="📍 ..."
IslandLbl.TextColor3=C.accent
IslandLbl.Font=Enum.Font.GothamBold; IslandLbl.TextSize=8
Instance.new("UICorner",IslandLbl).CornerRadius=UDim.new(0,5)

-- Min / Close
local function makeTopBtn(pos, txt, col)
    local b = Instance.new("TextButton",Top)
    b.Size=UDim2.new(0,18,0,18); b.Position=pos
    b.BackgroundColor3=col; b.BackgroundTransparency=0.75
    b.TextColor3=col; b.Text=txt
    b.Font=Enum.Font.GothamBold; b.TextSize=10
    b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
    return b
end
local MinBtn   = makeTopBtn(UDim2.new(1,-40,0.5,-9),"−",C.white)
local CloseBtn = makeTopBtn(UDim2.new(1,-18,0.5,-9),"✕",C.red)

-- ── SIDEBAR ──
local SB = Instance.new("Frame",Hub)
SB.Size = UDim2.new(0,108,1,-36)
SB.Position = UDim2.new(0,0,0,36)
SB.BackgroundColor3=C.sidebar; SB.BorderSizePixel=0
local ss = Instance.new("UIStroke",SB); ss.Color=C.white; ss.Transparency=0.93

local SBLayout = Instance.new("UIListLayout",SB)
SBLayout.SortOrder=Enum.SortOrder.LayoutOrder
SBLayout.Padding=UDim.new(0,0)

-- Padding atas
local sp = Instance.new("Frame",SB); sp.Size=UDim2.new(1,0,0,6); sp.BackgroundTransparency=1; sp.LayoutOrder=0

local navData = {}
local function makeNav(icon, lbl, order)
    local btn = Instance.new("TextButton",SB)
    btn.Size=UDim2.new(1,0,0,38); btn.BackgroundTransparency=1
    btn.BorderSizePixel=0; btn.Text=""; btn.LayoutOrder=order

    local bar = Instance.new("Frame",btn)
    bar.Size=UDim2.new(0,2,1,0); bar.BackgroundColor3=C.accent; bar.BackgroundTransparency=1; bar.BorderSizePixel=0

    local ico = Instance.new("TextLabel",btn)
    ico.Size=UDim2.new(0,18,1,0); ico.Position=UDim2.new(0,8,0,0)
    ico.BackgroundTransparency=1; ico.Text=icon
    ico.TextColor3=C.white; ico.TextTransparency=0.55
    ico.Font=Enum.Font.Gotham; ico.TextSize=14

    local tx = Instance.new("TextLabel",btn)
    tx.Size=UDim2.new(1,-30,1,0); tx.Position=UDim2.new(0,30,0,0)
    tx.BackgroundTransparency=1; tx.Text=lbl
    tx.TextColor3=C.white; tx.TextTransparency=0.55
    tx.Font=Enum.Font.Gotham; tx.TextSize=11
    tx.TextXAlignment=Enum.TextXAlignment.Left

    return btn, bar, tx, ico
end

local NMain,    NMainBar,    NMainTx,    NMainIco    = makeNav("⚔","Main",1)
local NGame,    NGameBar,    NGameTx,    NGameIco    = makeNav("🛡","Gamemode",2)
local NSet,     NSetBar,     NSetTx,     NSetIco     = makeNav("⚙","Settings",3)

-- Spacer dorong user ke bawah
local spacer = Instance.new("Frame",SB); spacer.Size=UDim2.new(1,0,1,0); spacer.BackgroundTransparency=1; spacer.LayoutOrder=98

-- User
local UF = Instance.new("Frame",SB)
UF.Size=UDim2.new(1,0,0,32); UF.BackgroundTransparency=1; UF.LayoutOrder=99
local uDiv = Instance.new("Frame",UF)
uDiv.Size=UDim2.new(1,0,0,1); uDiv.BackgroundColor3=C.white; uDiv.BackgroundTransparency=0.92; uDiv.BorderSizePixel=0
local uAv = Instance.new("Frame",UF)
uAv.Size=UDim2.new(0,20,0,20); uAv.Position=UDim2.new(0,7,0.5,-10)
uAv.BackgroundColor3=C.white; uAv.BackgroundTransparency=0.85; uAv.BorderSizePixel=0
Instance.new("UICorner",uAv).CornerRadius=UDim.new(1,0)
local uTx = Instance.new("TextLabel",UF)
uTx.Size=UDim2.new(1,-34,1,0); uTx.Position=UDim2.new(0,32,0,0)
uTx.BackgroundTransparency=1; uTx.Text=lp.Name
uTx.TextColor3=C.white; uTx.TextTransparency=0.6
uTx.Font=Enum.Font.Gotham; uTx.TextSize=9
uTx.TextXAlignment=Enum.TextXAlignment.Left
uTx.TextTruncate=Enum.TextTruncate.AtEnd

-- ── PANEL (fixed frame, no scrolling) ──
local Panel = Instance.new("Frame",Hub)
Panel.Size = UDim2.new(1,-108,1,-36)
Panel.Position = UDim2.new(0,108,0,36)
Panel.BackgroundTransparency=1; Panel.BorderSizePixel=0; Panel.ClipsDescendants=true

-- ══════════════════════════════════════
--  KOMPONEN UI
-- ══════════════════════════════════════
local function newFrame(parent, sz, pos, bg, bgt)
    local f=Instance.new("Frame",parent)
    f.Size=sz; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=bg or C.row; f.BackgroundTransparency=bgt or 0
    f.BorderSizePixel=0
    return f
end

local function newText(parent, txt, sz, pos, fs, col, trans, align, bold)
    local l=Instance.new("TextLabel",parent)
    l.Text=txt; l.Size=sz; l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1
    l.TextColor3=col or C.white; l.TextTransparency=trans or 0
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=fs or 10
    l.TextXAlignment=align or Enum.TextXAlignment.Left
    return l
end

local function clearPanel()
    for _,c in pairs(Panel:GetChildren()) do c:Destroy() end
end

-- Section label
local function secLabel(parent, txt, y)
    local l=newText(parent,txt,UDim2.new(1,-16,0,12),UDim2.new(0,8,0,y),8,C.white,0.65,Enum.TextXAlignment.Left,true)
    return l
end

-- Row container
local function makeRow(parent, y, h)
    local f=newFrame(parent,UDim2.new(1,-16,0,h or 30),UDim2.new(0,8,0,y),C.row,0.96)
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,7)
    return f
end

-- Toggle
local function makeToggle(parent, lbl, y, cb)
    local row=makeRow(parent,y,30)
    newText(row,lbl,UDim2.new(1,-46,1,0),UDim2.new(0,9,0,0),10,C.white,0.15)

    local track=newFrame(row,UDim2.new(0,28,0,15),UDim2.new(1,-37,0.5,-7.5),C.white,0.82)
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local knob=newFrame(track,UDim2.new(0,10,0,10),UDim2.new(0,2,0.5,-5),C.white,0.55)
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local on=false; local stroke=nil
    local function set(v)
        on=v
        if on then
            track.BackgroundColor3=C.accent; track.BackgroundTransparency=0.65
            if not stroke then stroke=Instance.new("UIStroke",track); stroke.Color=C.accent; stroke.Transparency=0.2 end
            knob.Position=UDim2.new(1,-12,0.5,-5); knob.BackgroundTransparency=0
        else
            track.BackgroundColor3=C.white; track.BackgroundTransparency=0.82
            if stroke then stroke:Destroy(); stroke=nil end
            knob.Position=UDim2.new(0,2,0.5,-5); knob.BackgroundTransparency=0.55
        end
        if cb then cb(on) end
    end
    local b=Instance.new("TextButton",row); b.Size=UDim2.new(1,0,1,0); b.BackgroundTransparency=1; b.Text=""
    b.MouseButton1Click:Connect(function() set(not on) end)
    return row, set, function() return on end
end

-- Dropdown (compact)
local function makeDropdown(parent, lbl, opts, y, cb)
    local row=makeRow(parent,y,30)
    row.ClipsDescendants=false

    newText(row,lbl,UDim2.new(0.42,0,1,0),UDim2.new(0,9,0,0),10,C.white,0.15)
    local val=newText(row,"",UDim2.new(0.42,0,1,0),UDim2.new(0.45,0,0,0),10,C.accent,0,Enum.TextXAlignment.Right,true)
    val.Text=opts[1] and opts[1].label or "—"
    local arr=newText(row,"▾",UDim2.new(0,16,1,0),UDim2.new(1,-18,0,0),11,C.accent,0,Enum.TextXAlignment.Center)

    -- dropdown list
    local list=newFrame(row,UDim2.new(1,0,0,0),UDim2.new(0,0,1,4),Color3.fromRGB(10,14,25),0)
    list.Visible=false; list.ZIndex=30; list.ClipsDescendants=true
    Instance.new("UICorner",list).CornerRadius=UDim.new(0,7)
    local ls=Instance.new("UIStroke",list); ls.Color=C.accent; ls.Transparency=0.55

    local selVal=opts[1] and opts[1].value or nil
    local open=false

    local function closeList() open=false; list.Visible=false; arr.Text="▾" end

    local function buildList(o)
        for _,c in pairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i,opt in ipairs(o) do
            local item=Instance.new("TextButton",list)
            item.Size=UDim2.new(1,0,0,26); item.Position=UDim2.new(0,0,0,(i-1)*26)
            item.BackgroundTransparency=1; item.BorderSizePixel=0
            item.Text=opt.label; item.TextColor3=C.white; item.TextTransparency=0.15
            item.Font=Enum.Font.Gotham; item.TextSize=10; item.ZIndex=31
            item.MouseEnter:Connect(function() item.BackgroundColor3=C.accent; item.BackgroundTransparency=0.82 end)
            item.MouseLeave:Connect(function() item.BackgroundTransparency=1 end)
            item.MouseButton1Click:Connect(function()
                selVal=opt.value; val.Text=opt.label; closeList()
                if cb then cb(opt.value,opt.label) end
            end)
        end
        list.Size=UDim2.new(1,0,0,#o*26)
    end
    buildList(opts)

    local tb=Instance.new("TextButton",row); tb.Size=UDim2.new(1,0,1,0); tb.BackgroundTransparency=1; tb.Text=""; tb.ZIndex=5
    tb.MouseButton1Click:Connect(function()
        open=not open; list.Visible=open; arr.Text=open and "▴" or "▾"
    end)

    local function update(newOpts)
        buildList(newOpts)
        selVal=newOpts[1] and newOpts[1].value or nil
        val.Text=newOpts[1] and newOpts[1].label or "—"
        if cb and selVal~=nil then cb(selVal,val.Text) end
    end

    return row, update, function() return selVal end
end

-- Action button
local function makeBtn(parent, txt, col, y, cb)
    local b=Instance.new("TextButton",parent)
    b.Size=UDim2.new(1,-16,0,28); b.Position=UDim2.new(0,8,0,y)
    b.BackgroundColor3=col; b.BackgroundTransparency=0.87
    b.BorderSizePixel=0; b.Text=txt
    b.TextColor3=col; b.Font=Enum.Font.GothamBold; b.TextSize=10
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    local s=Instance.new("UIStroke",b); s.Color=col; s.Transparency=0.55
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

-- Sep
local function makeSep(parent, y)
    local s=newFrame(parent,UDim2.new(1,-16,0,1),UDim2.new(0,8,0,y),C.white,0.92)
    return s
end

-- ══════════════════════════════════════
--  PANEL BUILDERS
-- ══════════════════════════════════════
local farmToggleSetFn = nil

local function buildMain()
    clearPanel()

    secLabel(Panel,"⚔  AUTO FARM",8)

    -- MAP
    local mapOpts={}
    for id,d in pairs(MAPS) do
        if id>0 then table.insert(mapOpts,{label=d.name,value=id}) end
    end
    table.sort(mapOpts,function(a,b) return a.value<b.value end)

    local npcUpdateFn
    local function npcOpts(id)
        local npcs=GetNPCs(id)
        local o={{label="All NPC",value=""}}
        for _,n in pairs(npcs) do table.insert(o,{label=n.label,value=n.name}) end
        return o
    end

    local mapRow,_,_ = makeDropdown(Panel,"Map",mapOpts,26,function(v)
        SetMap(v)
        if npcUpdateFn then npcUpdateFn(npcOpts(v)) end
    end)
    SetMap(mapOpts[1] and mapOpts[1].value or 1)

    local npcRow; npcRow,npcUpdateFn,_ = makeDropdown(Panel,"NPC",npcOpts(State.selectedMap),62,function(v)
        SetNPC(v)
    end)

    local targetOpts={{label="Nearest",value="nearest"},{label="Lowest HP",value="lowestHP"},{label="Highest HP",value="highestHP"}}
    makeDropdown(Panel,"Mob target",targetOpts,98,function(v) SetTarget(v) end)

    makeSep(Panel,134)

    local _,setFT,getFT = makeToggle(Panel,"Enable auto farm",142)
    farmToggleSetFn=setFT

    makeSep(Panel,178)

    makeBtn(Panel,"▶  Start farm",C.green,186,function()
        local newState = not getFT()
        setFT(newState)
        ToggleFarm(newState)
    end)

    makeBtn(Panel,"⬛  Stop all",C.red,220,function()
        setFT(false)
        ToggleFarm(false)
    end)
end

local function buildGamemode()
    clearPanel()
    secLabel(Panel,"🛡  GAMEMODE",8)
    makeToggle(Panel,"Godmode",26)
    makeToggle(Panel,"Infinite health",62)
    makeToggle(Panel,"No fall damage",98)
    makeToggle(Panel,"ESP boxes",134)
    makeSep(Panel,170)
    makeBtn(Panel,"⟳  Rejoin",C.accent,178)
    makeBtn(Panel,"☠  Kill entity",C.red,212)
end

local function buildSettings()
    clearPanel()
    secLabel(Panel,"⚙  SETTINGS",8)
    makeToggle(Panel,"Auto execute on join",26)
    makeToggle(Panel,"Notifications",62)
    makeToggle(Panel,"Anti-AFK",98)
    makeSep(Panel,134)

    -- Info card
    local card=makeRow(Panel,142,70)
    card.Size=UDim2.new(1,-16,0,70)
    local rows={{"Hub","Archeron Hub"},{"Members","43,137"},{"Online","2,966"},{"Ver","v1.2.0"}}
    for i,r in ipairs(rows) do
        newText(card,r[1],UDim2.new(0.5,0,0,14),UDim2.new(0,8,0,(i-1)*16),9,C.white,0.65)
        newText(card,r[2],UDim2.new(0.5,-8,0,14),UDim2.new(0.5,0,0,(i-1)*16),9,C.white,0,Enum.TextXAlignment.Right,true)
    end

    makeBtn(Panel,"🔗  Join Discord",Color3.fromRGB(88,101,242),220)
end

-- ══════════════════════════════════════
--  NAV ACTIVE STATE
-- ══════════════════════════════════════
local navItems={
    {btn=NMain,  bar=NMainBar,  tx=NMainTx,  ico=NMainIco,  fn=buildMain,     key="main"},
    {btn=NGame,  bar=NGameBar,  tx=NGameTx,  ico=NGameIco,  fn=buildGamemode, key="gamemode"},
    {btn=NSet,   bar=NSetBar,   tx=NSetTx,   ico=NSetIco,   fn=buildSettings, key="settings"},
}

local function setNav(key)
    for _,n in pairs(navItems) do
        local a=n.key==key
        n.bar.BackgroundTransparency=a and 0 or 1
        n.tx.TextTransparency=a and 0 or 0.55
        n.ico.TextTransparency=a and 0 or 0.55
        n.btn.BackgroundColor3=C.accent
        n.btn.BackgroundTransparency=a and 0.9 or 1
    end
end

for _,n in pairs(navItems) do
    n.btn.MouseButton1Click:Connect(function() setNav(n.key); n.fn() end)
end

-- ══════════════════════════════════════
--  MINI HUB
-- ══════════════════════════════════════
local Mini=Instance.new("Frame",SG)
Mini.Name="Mini"; Mini.Size=UDim2.new(0,50,0,50)
Mini.Position=UDim2.new(0,20,0,80)
Mini.BackgroundColor3=C.bg; Mini.BorderSizePixel=0; Mini.Visible=false; Mini.Active=true
Instance.new("UICorner",Mini).CornerRadius=UDim.new(0,15)
local ms=Instance.new("UIStroke",Mini); ms.Color=C.accent; ms.Transparency=0.45; ms.Thickness=1.5

local ML=Instance.new("TextLabel",Mini)
ML.Size=UDim2.new(0,34,0,34); ML.Position=UDim2.new(0.5,-17,0.5,-17)
ML.BackgroundColor3=C.white; ML.BorderSizePixel=0
ML.Text="Ar"; ML.TextColor3=C.bg; ML.Font=Enum.Font.GothamBold; ML.TextSize=13
Instance.new("UICorner",ML).CornerRadius=UDim.new(0,9)

-- Farm dot
local Dot=Instance.new("Frame",Mini)
Dot.Size=UDim2.new(0,9,0,9); Dot.Position=UDim2.new(1,-9,0,-1)
Dot.BackgroundColor3=C.green; Dot.BackgroundTransparency=1; Dot.BorderSizePixel=0
Instance.new("UICorner",Dot).CornerRadius=UDim.new(1,0)

local MiniClickBtn=Instance.new("TextButton",Mini)
MiniClickBtn.Size=UDim2.new(1,0,1,0); MiniClickBtn.BackgroundTransparency=1; MiniClickBtn.Text=""
MiniClickBtn.ZIndex=5
MiniClickBtn.MouseButton1Click:Connect(function()
    Mini.Visible=false; Hub.Visible=true
end)

-- ══════════════════════════════════════
--  DRAG (handle = topbar untuk Hub, seluruh frame untuk Mini)
-- ══════════════════════════════════════
local function makeDraggable(frame, handle)
    local drag=false; local dInput; local dStart; local dPos

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            drag=true; dStart=inp.Position; dPos=frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState==Enum.UserInputState.End then drag=false end
            end)
        end
    end)

    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseMovement
        or inp.UserInputType==Enum.UserInputType.Touch then
            dInput=inp
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if drag and inp==dInput then
            local d=inp.Position-dStart
            frame.Position=UDim2.new(
                dPos.X.Scale, dPos.X.Offset+d.X,
                dPos.Y.Scale, dPos.Y.Offset+d.Y
            )
        end
    end)
end

makeDraggable(Hub, Top)
makeDraggable(Mini, Mini)  -- Mini bisa drag dari seluruh frame

-- ══════════════════════════════════════
--  MINIMIZE / CLOSE
-- ══════════════════════════════════════
MinBtn.MouseButton1Click:Connect(function()
    Hub.Visible=false; Mini.Visible=true
end)

CloseBtn.MouseButton1Click:Connect(function()
    stopFarmLoop(); SG:Destroy()
end)

-- ══════════════════════════════════════
--  ISLAND INDICATOR UPDATE
-- ══════════════════════════════════════
task.spawn(function()
    while SG and SG.Parent do
        local cur=getCurrentIsland()
        local name="Unknown"
        if cur~=nil and MAPS[cur] then name=MAPS[cur].name end
        IslandLbl.Text="📍 "..name
        Dot.BackgroundTransparency=State.farmEnabled and 0 or 1
        task.wait(3)
    end
end)

-- ══════════════════════════════════════
--  INIT
-- ══════════════════════════════════════
setNav("main")
buildMain()
print("[Archeron Hub v1.2] Loaded!")
