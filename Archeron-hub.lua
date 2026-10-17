-- Archeron Hub v2.5 | World Farm + Dungeon/Trial Auto + Priority + Shield Skip + Auto-Detect
-- Horizontal tabs · Rounded cards · BridgeNet TP

-- kill semua loop dari eksekusi sebelumnya
if _G.__archeronStop then _G.__archeronStop() end
local _SESSION = {}
_G.__archeronStop = function() _SESSION = nil end
local function alive() return _SESSION ~= nil end

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

-- difficulty → sort order & color (untuk auto-detect dari Maps)
local DIFFICULTY_ORDER = {Easy=1, Medium=2, Hard=3, Insane=4, Boss=5, Secret=6}
local DIFFICULTY_COLOR = {
    Easy   = Color3.fromRGB( 80,200, 80),
    Medium = Color3.fromRGB( 80,140,255),
    Hard   = Color3.fromRGB(255,140, 40),
    Insane = Color3.fromRGB(220, 50, 50),
    Boss   = Color3.fromRGB(200, 60,255),
    Secret = Color3.fromRGB(255,210,  0),
}

-- auto-detect world enemies dari workspace.Server.Enemies.Maps
-- hasilnya digabung ke WORLDS (append world baru, skip kalau nama sudah ada)
local function autoDetectWorlds()
    local ok, mapsFolder = pcall(function()
        return workspace:WaitForChild("Server",3):WaitForChild("Enemies",3):WaitForChild("Maps",3)
    end)
    if not ok or not mapsFolder then return end

    -- index existing world names
    local existing = {}
    for _, w in ipairs(WORLDS) do existing[w.name] = true end

    for _, worldFolder in ipairs(mapsFolder:GetChildren()) do
        local wName = worldFolder.Name
        -- scan descendants untuk BaseParts dengan EnemyName + Difficulty
        local seen = {}   -- dedup by EnemyName
        local enemies = {}
        for _, v in ipairs(worldFolder:GetDescendants()) do
            if v:IsA("BasePart") then
                local en   = v:GetAttribute("EnemyName")
                local diff = v:GetAttribute("Difficulty")
                if en and diff and not seen[en] then
                    seen[en] = true
                    local order = DIFFICULTY_ORDER[diff] or 99
                    local col   = DIFFICULTY_COLOR[diff] or Color3.fromRGB(150,150,150)
                    table.insert(enemies, {name=en, rarity=order, rarityColor=col, difficulty=diff})
                end
            end
        end
        -- sort easy → hard
        table.sort(enemies, function(a,b) return a.rarity < b.rarity end)

        if #enemies > 0 then
            if existing[wName] then
                -- merge: tambah enemy yang belum ada di world yang sudah exist
                for _, w in ipairs(WORLDS) do
                    if w.name == wName then
                        local existEn = {}
                        for _, e in ipairs(w.enemies) do existEn[e.name] = true end
                        for _, e in ipairs(enemies) do
                            if not existEn[e.name] then
                                table.insert(w.enemies, e)
                            end
                        end
                        -- re-sort
                        table.sort(w.enemies, function(a,b) return (a.rarity or 1) < (b.rarity or 1) end)
                        break
                    end
                end
            else
                table.insert(WORLDS, {name=wName, enemies=enemies, autoDetected=true})
            end
        end
    end
end
task.spawn(autoDetectWorlds)

-- ── PRIORITY SYSTEM ─────────────────────────────────────────
local PRIORITY_FEATURES = {"Mob Farm","Dungeon Easy","Trial Easy","Culling Game","World Boss","Bounty","Quest"}
local priorities = {
    ["Mob Farm"]    = 3,
    ["Dungeon Easy"]= 1,
    ["Trial Easy"]  = 2,
    ["Culling Game"]= 4,
    ["World Boss"]  = 5,
    ["Bounty"]      = 6,
    ["Quest"]       = 7,
}

-- ── WORLD BOSS ───────────────────────────────────────────────
local worldBossActive = false
local wbList = {}      -- {name="Demon Melyode", world="Sins Kingdom"}
local selectedBoss = 1
local wbListOpen = false
local wbItemFrames = {}

local function scanWorldBosses()
    local ok, wbRoot = pcall(function()
        return workspace:WaitForChild("Server",3):WaitForChild("WorldBosses",3)
    end)
    wbList = {}
    if not ok or not wbRoot then return end
    for _, wf in ipairs(wbRoot:GetChildren()) do
        for _, bf in ipairs(wf:GetChildren()) do
            table.insert(wbList, {name=bf.Name, world=wf.Name})
        end
    end
end
task.spawn(scanWorldBosses)

local function detectWorldBoss()
    local wb = wbList[selectedBoss]
    if not wb then return nil end
    local ok, bossF = pcall(function()
        return workspace.Server.WorldBosses[wb.world][wb.name]
    end)
    if not ok or not bossF then return nil end
    for _, v in ipairs(bossF:GetDescendants()) do
        if v:IsA("BasePart") and not v:GetAttribute("Died") then return v end
    end
    return nil
end

local function worldBossLoop()
    while worldBossActive and alive() do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end
        local wbp = priorities["World Boss"] or 5
        local higher = (dungeonRunning and (priorities["Dungeon Easy"] or 1) < wbp)
            or (trialRunning   and (priorities["Trial Easy"]   or 2) < wbp)
            or ((cullingActive or cullingRunning) and (priorities["Culling Game"] or 4) < wbp)
        if higher then task.wait(1); continue end
        if not isBossActive() then task.wait(2); continue end
        local boss = detectWorldBoss()
        if boss and not isDead(boss) then
            spamTP(boss, function()
                return worldBossActive and alive() and not isDead(boss)
            end)
        else
            local wb = wbList[selectedBoss]
            if wb then tpWorld(wb.world) end
            task.wait(3)
        end
    end
end

-- ════════════════════════════════════════════════════════
-- SHARED LOGIC
-- ════════════════════════════════════════════════════════
local function tpFighters()
    local pos = hrp and hrp.Position
    if not pos then return end
    local cf = CFrame.new(pos + Vector3.new(0, 3, 0))
    local ok, ff = pcall(function() return workspace.Client.Fighters end)
    if not ok or not ff then return end
    for _, f in ipairs(ff:GetChildren()) do
        pcall(function()
            local root = f:FindFirstChild("HumanoidRootPart")
            if root then root.CFrame = cf end
        end)
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

local function isDead(part)
    return not part or part.Parent == nil or part:GetAttribute("Died")
end

-- spam CFrame ke enemy sampai mati
local function spamTP(part, activeCheck)
    local timeout = 0
    while timeout < 20 do
        if isDead(part) then break end
        if activeCheck and not activeCheck() then break end
        clearMovers()
        if hrp then hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0)) end
        tpFighters()
        task.wait(0.05); timeout = timeout + 0.05
    end
    task.wait(0.1)
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

-- helper: cek apakah farm harus pause (NPC kill berhenti)
-- dungeon/trial: pakai *Running — farm boleh jalan saat waiting phase (bisa 30 menit)
--   tapi *Running di-set SEBELUM task.wait(4) supaya ga ada gap saat join
-- culling: pakai *Active OR *Running — culling langsung start, tidak ada waiting phase
local function farmShouldPause()
    local p = priorities["Mob Farm"] or 3
    if dungeonRunning and (priorities["Dungeon Easy"] or 1) < p then return true end
    if trialRunning   and (priorities["Trial Easy"]   or 2) < p then return true end
    if (cullingActive or cullingRunning) and (priorities["Culling Game"] or 4) < p then return true end
    if worldBossActive then
        local boss = detectWorldBoss()
        if boss and (priorities["World Boss"] or 5) < p then return true end
    end
    return false
end

-- helper: cek apakah farm boleh tpWorld
-- lebih ketat: blokir tpWorld kalau ada gamemode AKTIF (Active) prioritas lebih tinggi,
-- supaya farm tidak teleport player keluar saat dungeon/trial/culling sedang loading/waiting
local function farmCanTpWorld()
    local p = priorities["Mob Farm"] or 3
    if dungeonActive  and (priorities["Dungeon Easy"] or 1) < p then return false end
    if trialActive    and (priorities["Trial Easy"]   or 2) < p then return false end
    if cullingActive  and (priorities["Culling Game"] or 4) < p then return false end
    if worldBossActive then
        local boss = detectWorldBoss()
        if boss and (priorities["World Boss"] or 5) < p then return false end
    end
    return true
end

local function farmLoop()
    local lastTpW = nil
    while farmActive and alive() do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end

        if farmShouldPause() then task.wait(1); continue end

        local pool = {}; local w = WORLDS[selectedWorld]
        if w then for i,e in ipairs(w.enemies) do
            if enabledEnemies[i] then table.insert(pool, e) end
        end end
        if #pool == 0 then task.wait(1); continue end
        local enemy = pool[math.random(#pool)]
        local part  = findNPC(enemy)
        if part then
            lastTpW = nil
            -- pass farmShouldPause ke activeCheck: kalau priority berubah mid-TP langsung berhenti
            spamTP(part, function() return farmActive and alive() and not farmShouldPause() end)
        else
            if farmShouldPause() then task.wait(1); continue end
            if not farmCanTpWorld() then task.wait(1); continue end
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
-- "Running" = sudah beneran join gamemode (bukan sekadar toggle ON)
local dungeonRunning   = false
local trialRunning     = false
local cullingRunning   = false
local dungeonLeaveRoom = 10
local trialLeaveWave   = 10
local cullingLeaveRoom = 10
local cullingDifficulty = "Easy"
local CULLING_DIFFS = {"Easy","Medium","Hard"}

-- ── SCHEDULE HELPERS ────────────────────────────────────
-- Dungeon :00 & :30 WIB | Trial :15 & :45 WIB
local WIB_OFFSET = 25200  -- UTC+7

local function secsUntilDungeon()
    local hoursecs = (os.time() + WIB_OFFSET) % 3600
    local shifted  = hoursecs % 1800
    return (1800 - shifted) % 1800
end

local function secsUntilTrial()
    local hoursecs = (os.time() + WIB_OFFSET) % 3600
    local shifted  = ((hoursecs - 900) % 3600) % 1800
    return (1800 - shifted) % 1800
end

-- filter by RoomIndex (nil = semua enemy)
local function findEnemiesInRoom(folderName, roomIdx)
    local list = {}
    local ok, folder = pcall(function()
        return workspace.Server.Enemies.Gamemodes[folderName]
    end)
    if not ok or not folder then return list end
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") and not v:GetAttribute("Died")
        and v:GetAttribute("EnemyName") then
            if roomIdx == nil then
                table.insert(list, v)
            else
                local ri = v:GetAttribute("RoomIndex")
                if ri == roomIdx then table.insert(list, v) end
            end
        end
    end
    return list
end

-- RoomIndex terendah yang masih ada enemy = room yang harus di-clear sekarang
local function getLowestRoomIndex(folderName)
    local ok, folder = pcall(function()
        return workspace.Server.Enemies.Gamemodes[folderName]
    end)
    if not ok or not folder then return nil end
    local minRI = nil
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") and not v:GetAttribute("Died")
        and v:GetAttribute("EnemyName") then
            local ri = v:GetAttribute("RoomIndex")
            if ri and (minRI == nil or ri < minRI) then minRI = ri end
        end
    end
    return minRI
end

-- alias untuk trial/culling yang tidak pakai RoomIndex
local function findEnemiesInArea(folderName)
    return findEnemiesInRoom(folderName, nil)
end

-- cek apakah enemy punya Shield model (skip kalau ada)
local function hasShield(part)
    local model = part.Parent
    if not model then return false end
    for _, v in ipairs(model:GetChildren()) do
        if v:IsA("Model") and v.Name:lower():find("shield") then return true end
    end
    return false
end

-- cari enemy terdekat dari hrp dalam list, skip yang bershield
local function nearestEnemy(list)
    if #list == 0 then return nil end
    if not hrp then
        for _, e in ipairs(list) do
            if not hasShield(e) then return e end
        end
        return nil
    end
    local best, bestD = nil, math.huge
    for _, e in ipairs(list) do
        if not hasShield(e) then
            local d = (e.Position - hrp.Position).Magnitude
            if d < bestD then bestD = d; best = e end
        end
    end
    return best
end

local function findNearestDoor()
    local hrpPos = (hrp and hrp.Position) or Vector3.new()
    local best, bestD, bestPP = nil, math.huge, nil
    local ok, mapFolder = pcall(function()
        return workspace.Client.Maps["Dungeon Easy"].Map
    end)
    if not ok or not mapFolder then return nil, nil end
    for _, room in ipairs(mapFolder:GetChildren()) do
        local doors = room:FindFirstChild("Doors")
        if doors then
            for _, doorPart in ipairs(doors:GetChildren()) do
                local openPP = doorPart:FindFirstChild("OpenDoor")
                if doorPart:IsA("BasePart") and openPP and openPP:IsA("ProximityPrompt") then
                    local d = (doorPart.Position - hrpPos).Magnitude
                    if d < bestD then bestD = d; best = doorPart; bestPP = openPP end
                end
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

-- cek apakah dungeon/trial sudah open sekarang (ada enemy di folder)
-- gamemodeIsOpen: cek workspace.Server.Teleport[folderName] punya Part "Spawn"
-- folder itu HANYA muncul (atau isinya muncul) saat session aktif dan bisa di-join
local function gamemodeIsOpen(folderName)
    local ok, folder = pcall(function()
        return workspace.Server.Teleport[folderName]
    end)
    if not ok or not folder then return false end
    if folder:FindFirstChild("Spawn") then return true end
    return folder:FindFirstChildWhichIsA("BasePart") ~= nil
end

-- isBossActive: Sins Kingdom di Teleport punya Spawn = World Boss lagi aktif
local function isBossActive()
    local ok, folder = pcall(function()
        return workspace.Server.Teleport["Sins Kingdom"]
    end)
    if not ok or not folder then return false end
    return folder:FindFirstChild("Spawn") ~= nil
        or folder:FindFirstChildWhichIsA("BasePart") ~= nil
end

-- gamemodeHasEnemies: ada enemy di folder = session sedang berjalan dengan musuh
-- dipakai untuk kill loop (apakah ada yang perlu dibunuh sekarang)
local function gamemodeHasEnemies(folderName)
    local ok, f = pcall(function()
        return workspace.Server.Enemies.Gamemodes[folderName]
    end)
    if not ok or not f then return false end
    for _, v in ipairs(f:GetDescendants()) do
        if v:IsA("BasePart") and v:GetAttribute("EnemyName") then return true end
    end
    return false
end

local function dungeonLoop()
  while dungeonActive and alive() do
    -- tunggu dungeon open: Spawn muncul di workspace.Server.Teleport["Dungeon Easy"]
    while dungeonActive and alive() do
        if gamemodeIsOpen("Dungeon Easy") then break end
        task.wait(1)
    end
    if not dungeonActive or not alive() then return end

    joinGamemode("Dungeon Easy")
    dungeonRunning = true  -- set sebelum wait supaya farm pause langsung, tanpa 4s gap
    if dungDot then TweenSvc:Create(dungDot,dti,{BackgroundColor3=C.dotG}):Play() end
    task.wait(4)
    local lastRoom = getDungeonRoom()

    while dungeonActive and alive() do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end

        -- world boss interrupt: kalau world boss prioritynya lebih tinggi (angka lebih kecil)
        local myDungPrio = priorities["Dungeon Easy"] or 1
        local wbPrio     = priorities["World Boss"]   or 5
        if worldBossActive and wbPrio < myDungPrio then
            local boss = detectWorldBoss()
            if boss then
                dungeonRunning = false
                if dungDot then TweenSvc:Create(dungDot,dti,{BackgroundColor3=C.dotY}):Play() end
                leaveGamemode(); task.wait(1)
                while dungeonActive and alive() do
                    local b = detectWorldBoss()
                    if not b or isDead(b) then break end
                    if not worldBossActive or (priorities["World Boss"] or 5) >= myDungPrio then break end
                    spamTP(b, function() return dungeonActive and alive() and worldBossActive end)
                end
                if dungeonActive and alive() and gamemodeHasEnemies("Dungeon Easy") then
                    joinGamemode("Dungeon Easy")
                    dungeonRunning = true
                    if dungDot then TweenSvc:Create(dungDot,dti,{BackgroundColor3=C.dotG}):Play() end
                    task.wait(4)
                end
                continue
            end
        end

        -- tentukan RoomIndex room saat ini (terendah yang ada enemy)
        local currentRI = getLowestRoomIndex("Dungeon Easy")

        if currentRI then
            -- spam TP ke enemy di room ini satu-satu sampai semua mati
            local tries = 80
            while dungeonActive and alive() and tries > 0 do
                local en = findEnemiesInRoom("Dungeon Easy", currentRI)
                if #en == 0 then break end  -- room cleared
                local t = nearestEnemy(en)
                if t then
                    spamTP(t, function() return dungeonActive and alive() end)
                end
                tries = tries - 1
            end
        else
            -- belum ada enemy (transisi / loading)
            task.wait(0.4)
        end

        if not dungeonActive then break end

        -- cek kondisi keluar
        local curRoom = getDungeonRoom()
        if curRoom >= dungeonLeaveRoom then
            leaveGamemode(); break  -- toggle tetap ON, outer loop tunggu dungeon berikutnya
        end

        -- cari door terdekat & buka
        local door, doorPP = findNearestDoor()
        if door and doorPP then
            clearMovers()
            if hrp then hrp.CFrame = CFrame.new(door.Position + Vector3.new(0, 2, 0)) end
            tpFighters()
            task.wait(0.3)
            pcall(fireproximityprompt, doorPP)
            -- tunggu RoomsCleared berubah (room baru terbuka)
            local wc = 0
            while dungeonActive and wc < 20 do
                local r = getDungeonRoom()
                if r ~= lastRoom then lastRoom = r; break end
                task.wait(0.5); wc = wc + 1
            end
            -- tunggu enemy pertama muncul di room baru
            local spawnWait = 0
            while dungeonActive and spawnWait < 15 do
                if getLowestRoomIndex("Dungeon Easy") then break end
                task.wait(0.3); spawnWait = spawnWait + 1
            end
        else
            task.wait(1)
        end
    end
    dungeonRunning = false
    if dungDot then TweenSvc:Create(dungDot,dti,{BackgroundColor3=C.dotY}):Play() end
    task.wait(3)  -- jeda sebelum nunggu dungeon berikutnya
  end
end

local function getCullingWave()
    local ok, v = pcall(function()
        local sessions = workspace.Client.Maps["Culling Game"].GamemodeSessions
        local session  = sessions:GetChildren()[1]
        return session.StateManager.CurrentWave.Value
    end)
    return ok and tonumber(v) or 0
end

local function cullingLoop()
  local function cullShouldWait()
      local p = priorities["Culling Game"] or 4
      if dungeonRunning and (priorities["Dungeon Easy"] or 1) < p then return true end
      if trialRunning   and (priorities["Trial Easy"]   or 2) < p then return true end
      if farmActive     and (priorities["Mob Farm"]     or 3) < p then return true end
      if worldBossActive and detectWorldBoss() and (priorities["World Boss"] or 5) < p then return true end
      return false
  end
  while cullingActive and alive() do
    -- tunggu kalau ada fitur prio lebih tinggi yang aktif
    while cullingActive and alive() and cullShouldWait() do task.wait(1) end
    if not cullingActive or not alive() then return end

    -- buat party → set difficulty → start
    fireBridgeNet({{"General","Parties","Create","Culling Game",n=4},"\x02"})
    task.wait(1)
    fireBridgeNet({{"General","Parties","SetDifficulty",cullingDifficulty,n=4},"\x02"})
    task.wait(0.5)
    fireBridgeNet({{"General","Parties","Start",n=3},"\x02"})
    task.wait(5)
    cullingRunning = true
    local lastWave = getCullingWave()
    while cullingActive and alive() do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end
        local tries = 80
        while cullingActive and alive() and tries > 0 do
            local en = findEnemiesInArea("Culling Game")
            if #en == 0 then break end
            local t = nearestEnemy(en)
            if t then spamTP(t, function() return cullingActive and alive() end) end
            tries = tries - 1
        end
        if not cullingActive then break end
        local curWave = getCullingWave()
        if curWave >= cullingLeaveRoom then leaveGamemode(); break end  -- toggle tetap ON
        local waitCycles = 0
        while cullingActive and waitCycles < 60 do
            local cw = getCullingWave()
            if cw >= cullingLeaveRoom then leaveGamemode(); break end
            local en = findEnemiesInArea("Culling Game")
            if #en > 0 then break end
            if cw ~= lastWave then lastWave = cw; break end
            task.wait(0.5); waitCycles = waitCycles + 1
        end
    end
    cullingRunning = false
    task.wait(3)
  end
end

local function trialLoop()
    local myPrio = function() return priorities["Trial Easy"] or 2 end

    local function trialHigherActive()
        local p = myPrio()
        if dungeonRunning  and (priorities["Dungeon Easy"] or 1) < p then return true end
        if worldBossActive and detectWorldBoss() and (priorities["World Boss"] or 5) < p then return true end
        return false
    end

  while trialActive and alive() do
    -- tunggu trial open: Spawn muncul di workspace.Server.Teleport["Trial Easy"]
    while trialActive and alive() do
        if gamemodeIsOpen("Trial Easy") then break end
        task.wait(1)
    end
    if not trialActive or not alive() then return end

    joinGamemode("Trial Easy")
    trialRunning = true  -- set sebelum wait supaya farm pause langsung
    if trialDot then TweenSvc:Create(trialDot,dti,{BackgroundColor3=C.dotG}):Play() end
    task.wait(4)
    local lastWave = getTrialWave()

    while trialActive and alive() do
        char = lp.Character; if not char then task.wait(1); continue end
        hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then task.wait(1); continue end

        -- cek priority: kalau ada yang lebih tinggi, keluar trial sementara dan tunggu
        if trialHigherActive() then
            trialRunning = false
            if trialDot then TweenSvc:Create(trialDot,dti,{BackgroundColor3=C.dotY}):Play() end
            leaveGamemode(); task.wait(1)
            while trialActive and alive() and trialHigherActive() do
                task.wait(1)
            end
            if trialActive and alive() and gamemodeHasEnemies("Trial Easy") then
                joinGamemode("Trial Easy")
                trialRunning = true
                if trialDot then TweenSvc:Create(trialDot,dti,{BackgroundColor3=C.dotG}):Play() end
                task.wait(4)
                lastWave = getTrialWave()
            end
            continue
        end

        -- bunuh semua enemy di wave sekarang
        local tries = 100
        while trialActive and alive() and tries > 0 do
            if trialHigherActive() then break end
            local en = findEnemiesInArea("Trial Easy")
            if #en == 0 then break end
            local t = nearestEnemy(en)
            if t then
                spamTP(t, function()
                    return trialActive and alive() and not trialHigherActive()
                end)
            end
            tries = tries - 1
        end

        if not trialActive then leaveGamemode(); break end
        local curWave = getTrialWave()
        if curWave >= trialLeaveWave then leaveGamemode(); break end  -- toggle tetap ON

        -- tunggu wave berikutnya
        local waitCycles = 0
        while trialActive and waitCycles < 120 do
            if trialHigherActive() then break end
            local cw = getTrialWave()
            if cw >= trialLeaveWave then leaveGamemode(); break end
            local en = findEnemiesInArea("Trial Easy")
            if #en > 0 then break end
            if cw ~= lastWave then lastWave = cw; break end
            task.wait(0.5); waitCycles = waitCycles + 1
        end
    end
    trialRunning = false
    if trialDot then TweenSvc:Create(trialDot,dti,{BackgroundColor3=C.dotY}):Play() end
    task.wait(3)
  end
end

-- ════════════════════════════════════════════════════════
-- GUI CONSTANTS
-- ════════════════════════════════════════════════════════
local C = {
    bg    = Color3.fromRGB( 9,  7, 20),      -- deep void
    side  = Color3.fromRGB(13, 10, 30),
    panel = Color3.fromRGB(15, 11, 34),
    card  = Color3.fromRGB(19, 14, 42),
    hdr   = Color3.fromRGB(11,  8, 26),
    acc   = Color3.fromRGB( 90, 55,215),     -- electric purple
    accHi = Color3.fromRGB(150,100,255),
    acc2  = Color3.fromRGB(  0,200,175),     -- teal glow
    txt   = Color3.fromRGB(230,215,255),
    sub   = Color3.fromRGB(125, 95,185),
    tOn   = Color3.fromRGB( 30,185,145),     -- teal ON
    tOff  = Color3.fromRGB( 38, 22, 68),
    kOn   = Color3.fromRGB(195,255,240),
    kOff  = Color3.fromRGB(110, 72,178),
    red   = Color3.fromRGB(205, 42, 65),
    sep   = Color3.fromRGB( 52, 28,100),
    item  = Color3.fromRGB( 11,  7, 26),
    bot   = Color3.fromRGB(  9,  6, 22),
    actS  = Color3.fromRGB(115, 65,235),
    tabAct= Color3.fromRGB( 65, 38,175),
    input = Color3.fromRGB( 21, 14, 48),
    dotG  = Color3.fromRGB( 60,220,145),     -- status: running
    dotY  = Color3.fromRGB(230,175, 40),     -- status: waiting
    dotD  = Color3.fromRGB( 45, 28, 75),     -- status: off
}

-- adaptive width so it fits on any mobile screen
local vp   = workspace.CurrentCamera.ViewportSize
local GW   = math.min(460, math.floor(vp.X) - 16)

local HDR_H    = 38
local SIDEBAR_W= 82
local BODY_H   = 236
local BOT_H    = 42
local TOTAL_H  = HDR_H + BODY_H + BOT_H  -- 316
local ROW_H    = 34
local ITEM_H   = 28
local CARD_M   = 5
local CARD_R   = 7
local PAD      = 4

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

-- status dot: bulat kecil di kiri toggle row; warna berubah live
local function makeStatusDot(parent)
    local dot = N("Frame",{
        Size=UDim2.new(0,8,0,8), Position=UDim2.new(0,6,0.5,-4),
        BackgroundColor3=C.dotD, BorderSizePixel=0, Parent=parent,
    })
    CR(999, dot)
    return dot
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

-- subtle glow line di bawah header
N("Frame",{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
    BackgroundColor3=C.acc, BorderSizePixel=0, Parent=hdr})
-- left: dua accent bar (teal + purple)
local nb1 = N("Frame",{Size=UDim2.new(0,3,0,20), Position=UDim2.new(0,10,0.5,-10),
    BackgroundColor3=C.acc2, BorderSizePixel=0, Parent=hdr})
CR(2, nb1)
local nb2 = N("Frame",{Size=UDim2.new(0,3,0,14), Position=UDim2.new(0,15,0.5,-7),
    BackgroundColor3=C.accHi, BorderSizePixel=0, Parent=hdr})
CR(2, nb2)
-- "ARCHERON" putih + "HUB" teal, centered-ish
N("TextLabel",{Size=UDim2.new(0,90,1,0), Position=UDim2.new(0,24,0,0),
    BackgroundTransparency=1, Text="ARCHERON",
    TextColor3=Color3.fromRGB(235,220,255),
    TextSize=13, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr})
N("TextLabel",{Size=UDim2.new(0,36,1,0), Position=UDim2.new(0,121,0,0),
    BackgroundTransparency=1, Text="HUB",
    TextColor3=C.acc2,
    TextSize=13, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=hdr})
-- badge v2.5
local vb = N("Frame",{Size=UDim2.new(0,30,0,15), Position=UDim2.new(0,160,0.5,-7.5),
    BackgroundColor3=C.acc, BackgroundTransparency=0.4, BorderSizePixel=0, Parent=hdr})
CR(4, vb); ST(C.accHi, 0.6, vb)
N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
    Text="v2.5", TextColor3=Color3.fromRGB(200,160,255),
    TextSize=8, Font=Enum.Font.GothamBold, Parent=vb})

local closeBtn = N("TextButton",{
    Size=UDim2.new(0,22,0,22), Position=UDim2.new(1,-28,0.5,-11),
    BackgroundColor3=C.red, Text="×", TextColor3=Color3.fromRGB(255,255,255),
    TextSize=15, Font=Enum.Font.GothamBold, BorderSizePixel=0, Parent=hdr,
})
CR(5, closeBtn)
makeDrag(hdr, main)

-- ── LEFT SIDEBAR ────────────────────────────────────────
local sidebar = N("Frame",{
    Size=UDim2.new(0,SIDEBAR_W,0,BODY_H),
    Position=UDim2.new(0,0,0,HDR_H),
    BackgroundColor3=C.side, BorderSizePixel=0, Parent=main,
})
-- right separator line
N("Frame",{Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0),
    BackgroundColor3=C.sep, BorderSizePixel=0, Parent=sidebar})
-- top separator line
N("Frame",{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.sep, BorderSizePixel=0, Parent=sidebar})

-- category data: {label, icon}
local CATS       = {{"Main","⚡"},{"Mode","⚔"},{"Config","⚙"}}
local activeTab  = 1
local tabPills   = {}   -- sidebar row frames
local tabContents= {}
local ti05       = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
local CAT_H      = 58   -- height per category row
local CAT_PAD    = 8    -- top padding

for i, cat in ipairs(CATS) do
    local rowY = CAT_PAD + (i-1) * (CAT_H + 4)
    local row = N("Frame",{
        Size=UDim2.new(1,0,0,CAT_H),
        Position=UDim2.new(0,0,0,rowY),
        BackgroundColor3 = i==1 and C.tabAct or Color3.fromRGB(0,0,0),
        BackgroundTransparency = i==1 and 0 or 1,
        BorderSizePixel=0, Parent=sidebar,
    })
    -- active left accent bar
    local acBar = N("Frame",{
        Size=UDim2.new(0,3,0,CAT_H-12),
        Position=UDim2.new(0,0,0.5,-(CAT_H-12)/2),
        BackgroundColor3=C.acc, BorderSizePixel=0,
        Visible=(i==1), Parent=row,
    })
    CR(2, acBar)
    -- icon
    N("TextLabel",{
        Size=UDim2.new(1,0,0,24), Position=UDim2.new(0,0,0,10),
        BackgroundTransparency=1, Text=cat[2],
        TextColor3= i==1 and C.accHi or C.sub,
        TextSize=16, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center, Parent=row,
    })
    -- label
    N("TextLabel",{
        Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,0,0,34),
        BackgroundTransparency=1, Text=cat[1],
        TextColor3= i==1 and C.txt or C.sub,
        TextSize=9, Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Center, Parent=row,
    })
    tabPills[i] = row
    local acRef = acBar
    local idx = i
    N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=row}
    ).MouseButton1Click:Connect(function()
        if activeTab == idx then return end
        -- deactivate old
        local oldRow = tabPills[activeTab]
        TweenSvc:Create(oldRow, ti05, {BackgroundTransparency=1}):Play()
        for _,ch in ipairs(oldRow:GetChildren()) do
            if ch:IsA("TextLabel") then TweenSvc:Create(ch,ti05,{TextColor3=C.sub}):Play() end
            if ch:IsA("Frame") and ch ~= oldRow then ch.Visible=false end
        end
        if tabContents[activeTab] then tabContents[activeTab].Visible = false end
        -- activate new
        activeTab = idx
        TweenSvc:Create(row, ti05, {BackgroundColor3=C.tabAct, BackgroundTransparency=0}):Play()
        for _,ch in ipairs(row:GetChildren()) do
            if ch:IsA("TextLabel") then
                local col = ch.TextSize >= 14 and C.accHi or C.txt
                TweenSvc:Create(ch,ti05,{TextColor3=col}):Play()
            end
            if ch:IsA("Frame") then ch.Visible=true end
        end
        if tabContents[idx] then tabContents[idx].Visible = true end
    end)
end

-- ── SCROLL HELPER (right panel) ─────────────────────────
local function makeScroll(visible)
    return N("ScrollingFrame",{
        Size=UDim2.new(1,-SIDEBAR_W,0,BODY_H),
        Position=UDim2.new(0,SIDEBAR_W,0,HDR_H),
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
-- left accent strip
N("Frame",{Size=UDim2.new(0,3,0,ROW_H-8), Position=UDim2.new(0,0,0.5,-(ROW_H-8)/2),
    BackgroundColor3=C.acc2, BorderSizePixel=0, Parent=farmCard})
local farmDot = makeStatusDot(farmCard)
N("TextLabel",{Size=UDim2.new(0,100,1,0), Position=UDim2.new(0,18,0,0),
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
    TweenSvc:Create(farmDot, fti, {BackgroundColor3=farmState and C.dotY or C.dotD}):Play()
end)

-- ── WORLD BOSS (Main tab) ────────────────────────────────────
local wbCard = makeCard(scrollMain, 0, ROW_H)
N("Frame",{Size=UDim2.new(0,3,0,ROW_H-8), Position=UDim2.new(0,0,0.5,-(ROW_H-8)/2),
    BackgroundColor3=Color3.fromRGB(220,80,80), BorderSizePixel=0, Parent=wbCard})
local wbDot = makeStatusDot(wbCard)
local wbVal = N("TextLabel",{Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,18,0,0),
    BackgroundTransparency=1, Text="— select boss —",
    TextColor3=C.sub, TextSize=10, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=wbCard})
local wbPill, wbKnob = makePill(wbCard, -48)
local wbState = false
local wbArrow = N("TextLabel",{Size=UDim2.new(0,16,1,0), Position=UDim2.new(1,-64,0,0),
    BackgroundTransparency=1, Text="►",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.GothamBold, Parent=wbCard})
-- label kecil "World Boss"
N("TextLabel",{Size=UDim2.new(0,72,0,12), Position=UDim2.new(0,18,0,2),
    BackgroundTransparency=1, Text="WORLD BOSS",
    TextColor3=C.sub, TextSize=7, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=wbCard})
-- geser wbVal ke bawah label kecil
wbVal.Position = UDim2.new(0,12,0,13)
wbVal.Size     = UDim2.new(1,-100,0,16)

local wbti = TweenInfo.new(0.14, Enum.EasingStyle.Quad)
-- dropdown open toggle
N("TextButton",{Size=UDim2.new(1,-52,1,0), BackgroundTransparency=1, Text="", Parent=wbCard}
).MouseButton1Click:Connect(function()
    wbListOpen = not wbListOpen
    wbArrow.Text = wbListOpen and "▾" or "►"
    doMainLayout()
end)
-- on/off toggle
N("TextButton",{Size=UDim2.new(0,52,1,0), Position=UDim2.new(1,-52,0,0),
    BackgroundTransparency=1, Text="", Parent=wbCard}
).MouseButton1Click:Connect(function()
    wbState = not wbState
    worldBossActive = wbState
    TweenSvc:Create(wbPill, wbti, {BackgroundColor3=wbState and C.tOn or C.tOff}):Play()
    TweenSvc:Create(wbKnob, wbti, {
        Position=wbState and UDim2.new(0,22,0.5,-8) or UDim2.new(0,2,0.5,-8),
        BackgroundColor3=wbState and C.kOn or C.kOff,
    }):Play()
    if wbState then task.spawn(worldBossLoop) end
    TweenSvc:Create(wbDot, wbti, {BackgroundColor3=wbState and C.dotY or C.dotD}):Play()
end)

-- dropdown list card
local wbItemsCard = N("Frame",{
    Size=UDim2.new(1,-(CARD_M*2),0,0),
    Position=UDim2.new(0,CARD_M,0,0),
    BackgroundColor3=C.card, BorderSizePixel=0, Visible=false, Parent=scrollMain,
})
CR(CARD_R, wbItemsCard); ST(C.sep, 0.8, wbItemsCard)

local function buildWbList()
    for _,c in ipairs(wbItemsCard:GetChildren()) do c:Destroy() end
    wbItemFrames = {}
    if #wbList == 0 then
        local ph = N("Frame",{Size=UDim2.new(1,0,0,ITEM_H), Position=UDim2.new(0,0,0,0),
            BackgroundTransparency=1, BorderSizePixel=0, Parent=wbItemsCard})
        N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text="No boss found", TextColor3=C.sub, TextSize=9,
            Font=Enum.Font.Gotham, Parent=ph})
        wbItemsCard.Size = UDim2.new(1,-(CARD_M*2),0,ITEM_H)
        return
    end
    for i, wb in ipairs(wbList) do
        local item = N("Frame",{
            Size=UDim2.new(1,0,0,ITEM_H), Position=UDim2.new(0,0,0,(i-1)*ITEM_H),
            BackgroundTransparency=1, BorderSizePixel=0, Parent=wbItemsCard})
        local strip = N("Frame",{Size=UDim2.new(0,2,0,14), Position=UDim2.new(0,8,0.5,-7),
            BackgroundColor3=i==selectedBoss and C.actS or C.sep, BorderSizePixel=0, Parent=item})
        CR(1, strip)
        local lbl = N("TextLabel",{Size=UDim2.new(1,-22,1,0), Position=UDim2.new(0,18,0,0),
            BackgroundTransparency=1, Text=wb.name.." - "..wb.world,
            TextColor3=i==selectedBoss and C.txt or C.sub,
            TextSize=10, Font=Enum.Font.Gotham,
            TextXAlignment=Enum.TextXAlignment.Left, Parent=item})
        wbItemFrames[i] = {frame=item, label=lbl, strip=strip}
        local idx = i
        N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=item}
        ).MouseButton1Click:Connect(function()
            local old = wbItemFrames[selectedBoss]
            if old then old.label.TextColor3=C.sub; old.strip.BackgroundColor3=C.sep end
            selectedBoss = idx
            lbl.TextColor3 = C.txt; strip.BackgroundColor3 = C.actS
            wbVal.Text = wb.name.." - "..wb.world
            wbListOpen = false; wbArrow.Text = "►"
            doMainLayout()
        end)
    end
    wbItemsCard.Size = UDim2.new(1,-(CARD_M*2),0,#wbList*ITEM_H)
end

-- rescan + rebuild saat pertama kali wbItemsCard dibuka
task.spawn(function()
    task.wait(5)  -- tunggu scanWorldBosses selesai
    if #wbList > 0 then
        local wb = wbList[selectedBoss]
        if wb then wbVal.Text = wb.name.." - "..wb.world end
    end
end)

-- ── PRIORITY TABLE (sortable list) ──────────────────────────
local PRIO_ROW_H = 26
local PRIO_HDR_H = 20
local PRIO_BTN_H = 32
local prioCardH  = PRIO_HDR_H + #PRIORITY_FEATURES * PRIO_ROW_H + PRIO_BTN_H + 6
local prioCard   = makeCard(scrollMain, 0, prioCardH)

-- build sorted order list (sorted by current priority value)
local prioOrder = {}  -- prioOrder[rank] = featureName
do
    local temp = {}
    for _, fn in ipairs(PRIORITY_FEATURES) do
        table.insert(temp, {name=fn, p=priorities[fn] or 99})
    end
    table.sort(temp, function(a,b) return a.p < b.p end)
    for i,t in ipairs(temp) do prioOrder[i] = t.name end
end
local prioSelected = 1  -- row yang dipilih (1-based rank)

-- header
N("TextLabel",{Size=UDim2.new(1,-8,0,PRIO_HDR_H), Position=UDim2.new(0,10,0,0),
    BackgroundTransparency=1, Text="PRIORITY  (pilih fitur → ▲ UP / ▼ DOWN)",
    TextColor3=C.sub, TextSize=8, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=prioCard})

-- row frames & labels
local prioRowFrames = {}
local prioNumLabels  = {}
local prioNameLabels = {}

local function prioRefresh()
    for rank = 1, #prioOrder do
        local fn = prioOrder[rank]
        local sel = (rank == prioSelected)
        local rf = prioRowFrames[rank]
        if rf then
            rf.BackgroundColor3 = sel and Color3.fromRGB(60,25,120) or Color3.fromRGB(0,0,0)
            rf.BackgroundTransparency = sel and 0 or 1
        end
        if prioNumLabels[rank] then
            prioNumLabels[rank].Text      = tostring(rank)
            prioNumLabels[rank].TextColor3 = sel and C.accHi or C.sub
        end
        if prioNameLabels[rank] then
            prioNameLabels[rank].Text      = prioOrder[rank]
            prioNameLabels[rank].TextColor3 = sel and C.txt or Color3.fromRGB(160,130,210)
        end
    end
    -- sync priorities table
    for i, fn in ipairs(prioOrder) do priorities[fn] = i end
end

for rank = 1, #PRIORITY_FEATURES do
    local ry = PRIO_HDR_H + (rank-1)*PRIO_ROW_H
    local rf = N("Frame",{
        Size=UDim2.new(1,-8,0,PRIO_ROW_H-2), Position=UDim2.new(0,4,0,ry+1),
        BackgroundTransparency=1, BorderSizePixel=0, Parent=prioCard,
    })
    CR(5, rf)
    prioRowFrames[rank] = rf

    -- rank badge
    local badge = N("Frame",{
        Size=UDim2.new(0,20,0,20), Position=UDim2.new(0,4,0.5,-10),
        BackgroundColor3=C.hdr, BorderSizePixel=0, Parent=rf,
    })
    CR(4, badge)
    local numLbl = N("TextLabel",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        Text=tostring(rank), TextColor3=C.sub,
        TextSize=9, Font=Enum.Font.GothamBold, Parent=badge})
    prioNumLabels[rank] = numLbl

    -- name
    local nameLbl = N("TextLabel",{
        Size=UDim2.new(1,-34,1,0), Position=UDim2.new(0,30,0,0),
        BackgroundTransparency=1, Text=PRIORITY_FEATURES[rank],
        TextColor3=Color3.fromRGB(160,130,210), TextSize=10, Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left, Parent=rf})
    prioNameLabels[rank] = nameLbl

    -- separator
    if rank < #PRIORITY_FEATURES then
        N("Frame",{Size=UDim2.new(1,-8,0,1), Position=UDim2.new(0,4,1,-1),
            BackgroundColor3=C.sep, BackgroundTransparency=0.6, BorderSizePixel=0, Parent=rf})
    end

    -- click to select
    local r = rank
    N("TextButton",{Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=rf}
    ).MouseButton1Click:Connect(function()
        prioSelected = r; prioRefresh()
    end)
end

-- UP / DOWN buttons
local btnY = PRIO_HDR_H + #PRIORITY_FEATURES * PRIO_ROW_H + 4
local upBtn = N("TextButton",{
    Size=UDim2.new(0.45,0,0,24), Position=UDim2.new(0.05,0,0,btnY),
    BackgroundColor3=C.acc, Text="▲  UP",
    TextColor3=Color3.fromRGB(220,200,255), TextSize=10, Font=Enum.Font.GothamBold,
    BorderSizePixel=0, Parent=prioCard,
})
CR(6, upBtn)
local dnBtn = N("TextButton",{
    Size=UDim2.new(0.45,0,0,24), Position=UDim2.new(0.5,4,0,btnY),
    BackgroundColor3=C.hdr, Text="▼  DOWN",
    TextColor3=Color3.fromRGB(180,150,230), TextSize=10, Font=Enum.Font.GothamBold,
    BorderSizePixel=0, Parent=prioCard,
})
CR(6, dnBtn); ST(C.sep, 0.8, dnBtn)

upBtn.MouseButton1Click:Connect(function()
    if prioSelected <= 1 then return end
    prioOrder[prioSelected], prioOrder[prioSelected-1] = prioOrder[prioSelected-1], prioOrder[prioSelected]
    prioSelected = prioSelected - 1
    prioRefresh()
end)
dnBtn.MouseButton1Click:Connect(function()
    if prioSelected >= #prioOrder then return end
    prioOrder[prioSelected], prioOrder[prioSelected+1] = prioOrder[prioSelected+1], prioOrder[prioSelected]
    prioSelected = prioSelected + 1
    prioRefresh()
end)

prioRefresh()

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
    farmCard.Position = UDim2.new(0,CARD_M,0,y); y = y + ROW_H + PAD + 4
    -- World Boss dropdown
    wbCard.Position = UDim2.new(0,CARD_M,0,y); y = y + ROW_H + 2
    if wbListOpen then
        buildWbList()
        local h = wbItemsCard.Size.Y.Offset
        wbItemsCard.Visible  = true
        wbItemsCard.Position = UDim2.new(0,CARD_M,0,y)
        y = y + h + PAD
    else
        wbItemsCard.Visible = false
        y = y + PAD
    end
    prioCard.Position = UDim2.new(0,CARD_M,0,y + 4)
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
N("Frame",{Size=UDim2.new(0,3,0,ROW_H-8), Position=UDim2.new(0,0,0.5,-(ROW_H-8)/2),
    BackgroundColor3=Color3.fromRGB(80,140,255), BorderSizePixel=0, Parent=dungCard})
local dungDot = makeStatusDot(dungCard)
N("TextLabel",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,18,0,0),
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
    TweenSvc:Create(dungDot, dti, {BackgroundColor3=dungState and C.dotY or C.dotD}):Play()
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
gmy = gmy + ROW_H + PAD

-- countdown dungeon
local dungCountLabel = N("TextLabel",{
    Size=UDim2.new(1,-(CARD_M*2),0,14),
    Position=UDim2.new(0,CARD_M,0,gmy),
    BackgroundTransparency=1, Text="",
    TextColor3=C.sub, TextSize=8, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=scrollGM,
})
gmy = gmy + 16 + PAD

-- TRIAL EASY
secLabel(scrollGM, gmy, "TRIAL EASY"); gmy = gmy + 18

local trialCard = makeCard(scrollGM, gmy, ROW_H)
N("Frame",{Size=UDim2.new(0,3,0,ROW_H-8), Position=UDim2.new(0,0,0.5,-(ROW_H-8)/2),
    BackgroundColor3=Color3.fromRGB(200,120,255), BorderSizePixel=0, Parent=trialCard})
local trialDot = makeStatusDot(trialCard)
N("TextLabel",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,18,0,0),
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
    TweenSvc:Create(trialDot, dti, {BackgroundColor3=trialState and C.dotY or C.dotD}):Play()
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
gmy = gmy + ROW_H + PAD

-- countdown trial
local trialCountLabel = N("TextLabel",{
    Size=UDim2.new(1,-(CARD_M*2),0,14),
    Position=UDim2.new(0,CARD_M,0,gmy),
    BackgroundTransparency=1, Text="",
    TextColor3=C.sub, TextSize=8, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=scrollGM,
})
gmy = gmy + 16 + PAD + 4

-- CULLING GAME
secLabel(scrollGM, gmy, "CULLING GAME"); gmy = gmy + 18

local cullCard = makeCard(scrollGM, gmy, ROW_H)
N("Frame",{Size=UDim2.new(0,3,0,ROW_H-8), Position=UDim2.new(0,0,0.5,-(ROW_H-8)/2),
    BackgroundColor3=Color3.fromRGB(255,180,60), BorderSizePixel=0, Parent=cullCard})
local cullDot = makeStatusDot(cullCard)
N("TextLabel",{Size=UDim2.new(0,160,1,0), Position=UDim2.new(0,18,0,0),
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
    TweenSvc:Create(cullDot, dti, {BackgroundColor3=cullState and C.dotY or C.dotD}):Play()
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
    BackgroundTransparency=1, Text="Auto leave at wave",
    TextColor3=C.sub, TextSize=9, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=cullLeaveCard})
makeNumInput(cullLeaveCard, -50, cullingLeaveRoom, 1, 51, function(v)
    cullingLeaveRoom = v
end)
gmy = gmy + ROW_H + PAD + 4

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
    Position=UDim2.new(0,0,0,HDR_H+BODY_H),
    BackgroundColor3=C.bot, BorderSizePixel=0, Parent=main,
})
N("Frame",{Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.sep, BorderSizePixel=0, Parent=botBar})

-- avatar circle
local avatarBg = N("Frame",{Size=UDim2.new(0,28,0,28), Position=UDim2.new(0,10,0.5,-14),
    BackgroundColor3=C.acc, BackgroundTransparency=0.4, BorderSizePixel=0, Parent=botBar})
CR(999, avatarBg); ST(C.accHi, 0.8, avatarBg)
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
-- display name
N("TextLabel",{Size=UDim2.new(0,130,0,14), Position=UDim2.new(0,44,0,7),
    BackgroundTransparency=1, Text=lp.DisplayName,
    TextColor3=C.txt, TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=botBar})
-- @username sub
N("TextLabel",{Size=UDim2.new(0,130,0,11), Position=UDim2.new(0,44,0,21),
    BackgroundTransparency=1, Text="@"..lp.Name,
    TextColor3=C.sub, TextSize=8, Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=botBar})

-- divider line between profile and clock
N("Frame",{Size=UDim2.new(0,1,0,22), Position=UDim2.new(0.5,0,0.5,-11),
    BackgroundColor3=C.sep, BorderSizePixel=0, Parent=botBar})

-- live clock (right side)
local clockLabel = N("TextLabel",{
    Size=UDim2.new(0.5,-10,1,0), Position=UDim2.new(0.5,6,0,0),
    BackgroundTransparency=1, Text="",
    TextColor3=Color3.fromRGB(170,130,255), TextSize=10, Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left, Parent=botBar,
})
task.spawn(function()
    while alive() do
        -- jam WIB live
        local wib = os.time() + WIB_OFFSET
        local h = math.floor(wib / 3600) % 24
        local m = math.floor(wib / 60)  % 60
        local s = wib % 60
        clockLabel.Text = string.format("%02d:%02d:%02d WIB", h, m, s)

        -- countdown di bawah tiap gamemode
        local rd = secsUntilDungeon()
        local rt = secsUntilTrial()
        dungCountLabel.Text  = string.format("⏱ dungeon open in %dm %02ds", math.floor(rd/60), rd%60)
        trialCountLabel.Text = string.format("⏱ trial open in %dm %02ds",   math.floor(rt/60), rt%60)
        task.wait(1)
    end
end)

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
