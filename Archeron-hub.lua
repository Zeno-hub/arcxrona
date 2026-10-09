-- language: Lua (Roblox exploit)
-- Archeron Hub v1.2 | drag fix + enemy detection via parent nil

local Players  = game:GetService("Players")
local TweenSvc = game:GetService("TweenService")
local UIS      = game:GetService("UserInputService")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
end)

-- ═══════════════════════ LOGIC ══════════════════════════

local farmActive = false
local statusText = "Idle"

local function getEnemyFolder()
    local s = workspace:FindFirstChild("Server")
    if not s then return end
    local e = s:FindFirstChild("Enemies")
    if not e then return end
    local g = e:FindFirstChild("Gamemodes")
    if not g then return end
    local d = g:FindFirstChild("Dungeon Easy")
    if not d then return end
    return d:FindFirstChild("Global")
end

-- GetChildren langsung, bukan Descendants
local function getEnemies()
    local folder = getEnemyFolder()
    local list = {}
    if not folder then return list end
    for _, v in ipairs(folder:GetChildren()) do
        if v:IsA("Model") then
            table.insert(list, v)
        end
    end
    return list
end

-- aggressive root finder
local function getRoot(model)
    if model.PrimaryPart then return model.PrimaryPart end
    for _, name in ipairs({"HumanoidRootPart","RootPart","Root","Torso","UpperTorso","Head"}) do
        local p = model:FindFirstChild(name)
        if p and p:IsA("BasePart") then return p end
    end
    return model:FindFirstChildWhichIsA("BasePart")
end

-- pilih enemy terdekat dari HRP
local function getNearestEnemy()
    local enemies = getEnemies()
    local best, bestDist = nil, math.huge
    for _, model in ipairs(enemies) do
        local root = getRoot(model)
        if root then
            local d = (hrp.Position - root.Position).Magnitude
            if d < bestDist then
                best = model
                bestDist = d
            end
        end
    end
    return best
end

-- door: ProximityPrompt terdekat → fallback touch
local function findAndOpenDoor()
    local best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local part = v.Parent:IsA("BasePart") and v.Parent
                or v.Parent:FindFirstChildWhichIsA("BasePart")
            if part then
                local d = (hrp.Position - part.Position).Magnitude
                if d < bestDist then best = v; bestDist = d end
            end
        end
    end
    if best then
        local part = best.Parent:IsA("BasePart") and best.Parent
            or best.Parent:FindFirstChildWhichIsA("BasePart")
        if part then
            hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 2))
            task.wait(0.15)
        end
        pcall(function() fireproximityprompt(best) end)
        statusText = "Door triggered"
        return true
    end

    -- fallback nama door
    best, bestDist = nil, math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Name:lower():find("door") then
            local d = (hrp.Position - v.Position).Magnitude
            if d < bestDist then best = v; bestDist = d end
        end
    end
    if best then
        hrp.CFrame = CFrame.new(best.Position + Vector3.new(0, 4, 0))
        task.wait(0.1)
        pcall(function() firetouchinterest(hrp, best, 0) end)
        task.wait(0.05)
        pcall(function() firetouchinterest(hrp, best, 1) end)
        statusText = "Door touched"
        return true
    end

    statusText = "No door found"
    return false
end

local function farmLoop()
    while farmActive do
        char = lp.Character
        if not char then task.wait(1); continue end
        hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then task.wait(1); continue end

        local enemies = getEnemies()

        if #enemies == 0 then
            -- folder kosong → buka door
            statusText = "Opening door..."
            local ok = findAndOpenDoor()
            task.wait(ok and 2.5 or 2)
        else
            -- ambil enemy terdekat
            local enemy = getNearestEnemy()
            if not enemy then task.wait(0.5); continue end

            local root = getRoot(enemy)
            if root then
                statusText = "Farming: " .. enemy.Name
                hrp.CFrame = root.CFrame
                task.wait(0.05)

                -- tunggu enemy mati = parent jadi nil
                local t = 0
                while enemy.Parent ~= nil and t < 12 do
                    -- cek health attribute juga (kalau ada)
                    local hp = enemy:GetAttribute("Health")
                    if hp and hp <= 0 then break end
                    task.wait(0.05)
                    t = t + 0.05
                end
                task.wait(0.1)
            end
        end

        task.wait(0.05)
    end
    statusText = "Idle"
end

-- ═══════════════════════ GUI ════════════════════════════

local C = {
    bg    = Color3.fromRGB(8,   5,   20),
    panel = Color3.fromRGB(16,  10,  38),
    hdr   = Color3.fromRGB(22,  13,  50),
    acc   = Color3.fromRGB(95,  45,  205),
    txt   = Color3.fromRGB(215, 195, 255),
    sub   = Color3.fromRGB(110, 80,  170),
    tOn   = Color3.fromRGB(85,  30,  195),
    tOff  = Color3.fromRGB(38,  22,  68),
    kOn   = Color3.fromRGB(200, 156, 255),
    kOff  = Color3.fromRGB(125, 80,  190),
    red   = Color3.fromRGB(185, 35,  60),
    sep   = Color3.fromRGB(60,  30,  120),
}

local function N(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function CR(r, p) N("UICorner", {CornerRadius = UDim.new(0, r)}, p) end
local function ST(c, t, p) N("UIStroke", {Color = c, Thickness = t}, p) end

-- FIX: handle = input source, target = frame yang digerakin
local function makeDrag(handle, target)
    local mv = target or handle
    local dragging, start, origin, lastInp = false, nil, nil, nil
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start    = inp.Position
            origin   = mv.Position
        end
    end)
    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            lastInp = inp
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == lastInp and dragging then
            local d = inp.Position - start
            mv.Position = UDim2.new(
                origin.X.Scale, origin.X.Offset + d.X,
                origin.Y.Scale, origin.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local gui = N("ScreenGui", {
    Name = "ArcheronHub",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = (gethui and gethui()) or lp.PlayerGui
})

-- DOT
local dot = N("Frame", {
    Size = UDim2.new(0, 44, 0, 44),
    Position = UDim2.new(0, 14, 0.5, -22),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    Active = true,
    Parent = gui
})
CR(10, dot); ST(C.acc, 1.5, dot)
N("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "✦",
    TextColor3 = Color3.fromRGB(155, 95, 255),
    TextSize = 19,
    Font = Enum.Font.GothamBold,
    Parent = dot
})

local isOpen = false
local dotDrag, dotStart, dotOrigin, dotMoved = false, nil, nil, false
local dotLastInp

dot.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dotDrag = true; dotStart = inp.Position
        dotOrigin = dot.Position; dotMoved = false
    end
end)
dot.InputChanged:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then dotLastInp = inp end
end)
UIS.InputChanged:Connect(function(inp)
    if inp == dotLastInp and dotDrag then
        local d = inp.Position - dotStart
        if d.Magnitude > 5 then dotMoved = true end
        dot.Position = UDim2.new(
            dotOrigin.X.Scale, dotOrigin.X.Offset + d.X,
            dotOrigin.Y.Scale, dotOrigin.Y.Offset + d.Y)
    end
end)

-- MAIN
local main = N("Frame", {
    Size = UDim2.new(0, 260, 0, 310),
    Position = UDim2.new(0, 66, 0.5, -155),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Visible = false,
    Parent = gui
})
CR(12, main); ST(C.acc, 1.5, main)

UIS.InputEnded:Connect(function(inp)
    if dotDrag and (inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch) then
        dotDrag = false
        if not dotMoved then
            isOpen = not isOpen
            main.Visible = isOpen
        end
    end
end)

-- HEADER — drag handle untuk main
local hdr = N("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = C.hdr,
    BorderSizePixel = 0,
    Active = true,
    Parent = main
})
CR(12, hdr)
N("Frame", { -- fix bottom radius
    Size = UDim2.new(1, 0, 0.5, 0),
    Position = UDim2.new(0, 0, 0.5, 0),
    BackgroundColor3 = C.hdr,
    BorderSizePixel = 0,
    Parent = hdr
})

-- FIX: hdr sebagai handle, main sebagai target yang digerakin
makeDrag(hdr, main)

N("TextLabel", {
    Size = UDim2.new(1, -48, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "✦  ARCHERON HUB",
    TextColor3 = Color3.fromRGB(175, 125, 255),
    TextSize = 13,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = hdr
})

local closeBtn = N("TextButton", {
    Size = UDim2.new(0, 26, 0, 26),
    Position = UDim2.new(1, -34, 0.5, -13),
    BackgroundColor3 = C.red,
    Text = "✕",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 11,
    Font = Enum.Font.GothamBold,
    BorderSizePixel = 0,
    Parent = hdr
})
CR(6, closeBtn)
closeBtn.MouseButton1Click:Connect(function()
    isOpen = false; main.Visible = false
end)

-- CONTENT
local content = N("Frame", {
    Size = UDim2.new(1, -20, 1, -50),
    Position = UDim2.new(0, 10, 0, 46),
    BackgroundTransparency = 1,
    Parent = main
})
N("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 6),
    Parent = content
})

-- STATUS
local statBar = N("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = Color3.fromRGB(13, 8, 30),
    BorderSizePixel = 0,
    LayoutOrder = 0,
    Parent = content
})
CR(6, statBar); ST(C.sep, 1, statBar)

local statLbl = N("TextLabel", {
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 8, 0, 0),
    BackgroundTransparency = 1,
    Text = "● Idle",
    TextColor3 = C.sub,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = statBar
})
task.spawn(function()
    while task.wait(0.5) do statLbl.Text = "● " .. statusText end
end)

local ord = 0
local function section(title)
    ord = ord + 1
    local f = N("Frame", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        LayoutOrder = ord,
        Parent = content
    })
    N("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = C.sep,
        BorderSizePixel = 0,
        Parent = f
    })
    N("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 0),
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        Text = "  " .. title .. "  ",
        TextColor3 = C.sub,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        Parent = f
    })
end

local function toggle(label, callback)
    ord = ord + 1
    local row = N("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        LayoutOrder = ord,
        Parent = content
    })
    CR(8, row)
    N("TextLabel", {
        Size = UDim2.new(1, -56, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = C.txt,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row
    })
    local pill = N("Frame", {
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -44, 0.5, -9),
        BackgroundColor3 = C.tOff,
        BorderSizePixel = 0,
        Parent = row
    })
    CR(999, pill)
    local knob = N("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = C.kOff,
        BorderSizePixel = 0,
        Parent = pill
    })
    CR(999, knob)
    local state = false
    local btn = N("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row
    })
    local ti = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenSvc:Create(pill, ti, {BackgroundColor3 = state and C.tOn or C.tOff}):Play()
        TweenSvc:Create(knob, ti, {
            Position = state and UDim2.new(0, 20, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = state and C.kOn or C.kOff
        }):Play()
        callback(state)
    end)
end

section("DUNGEON")
toggle("Auto Farm Easy", function(on)
    farmActive = on
    if on then task.spawn(farmLoop) end
end)

section("MISC")
toggle("Anti AFK", function(on)
    if on then
        task.spawn(function()
            while on do
                pcall(function()
                    local va = workspace:FindFirstChildOfClass("VirtualUser")
                    if va then va:CaptureController(); va:ClickButton2(Vector2.new()) end
                end)
                task.wait(20)
            end
        end)
    end
end)

print("[Archeron Hub] v1.2 ready")
