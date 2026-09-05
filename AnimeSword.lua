local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("AnimeSwordsUI")
if old then
    old:Destroy()
end

local DATA = {
    Maps = {}
}

local selectedMap
local selectedNPC
local farming = false

local function new(class, props)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        o[k] = v
    end
    return o
end

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = o
end

local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function tp(v)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(v)
    end
end

local function findMap(name)
    for _, map in ipairs(DATA.Maps) do
        if map.Name == name then
            return map
        end
    end
end

local function findNPC(map, name)
    if not map then return end
    for _, npc in ipairs(map.NPCs) do
        if npc.Name == name then
            return npc
        end
    end
end

local gui = new("ScreenGui", {
    Name = "AnimeSwordsUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    Parent = playerGui
})

local main = new("Frame", {
    Parent = gui,
    Size = UDim2.fromOffset(325, 360),
    Position = UDim2.new(0.5, -162, 0.5, -180),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true
})
corner(main, 10)

local top = new("Frame", {
    Parent = main,
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Color3.fromRGB(24, 24, 29),
    BorderSizePixel = 0
})
corner(top, 10)

local title = new("TextLabel", {
    Parent = top,
    Size = UDim2.new(1, -110, 1, 0),
    Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1,
    Text = "ANIME SWORDS",
    TextColor3 = Color3.fromRGB(245, 245, 245),
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
})

local mainTab = new("TextButton", {
    Parent = top,
    Size = UDim2.fromOffset(45, 28),
    Position = UDim2.new(1, -102, 0, 7),
    BackgroundColor3 = Color3.fromRGB(60, 60, 70),
    Text = "Main",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamMedium,
    TextSize = 11
})
corner(mainTab, 5)

local adminTab = new("TextButton", {
    Parent = top,
    Size = UDim2.fromOffset(45, 28),
    Position = UDim2.new(1, -52, 0, 7),
    BackgroundColor3 = Color3.fromRGB(38, 38, 44),
    Text = "Admin",
    TextColor3 = Color3.new(1,1,1),
    Font = Enum.Font.GothamMedium,
    TextSize = 11
})
corner(adminTab, 5)

local mainPage = new("Frame", {
    Parent = main,
    Size = UDim2.new(1, -16, 1, -52),
    Position = UDim2.fromOffset(8, 48),
    BackgroundTransparency = 1
})

local adminPage = new("Frame", {
    Parent = main,
    Size = UDim2.new(1, -16, 1, -52),
    Position = UDim2.fromOffset(8, 48),
    BackgroundTransparency = 1,
    Visible = false
})

local function button(parent, text, size, pos)
    local b = new("TextButton", {
        Parent = parent,
        Size = size,
        Position = pos,
        BackgroundColor3 = Color3.fromRGB(34, 34, 40),
        Text = text,
        TextColor3 = Color3.fromRGB(235, 235, 235),
        Font = Enum.Font.GothamMedium,
        TextSize = 12
    })
    corner(b, 6)
    return b
end

local function box(parent, placeholder, size, pos)
    local b = new("TextBox", {
        Parent = parent,
        Size = size,
        Position = pos,
        BackgroundColor3 = Color3.fromRGB(12, 12, 15),
        TextColor3 = Color3.fromRGB(240, 240, 240),
        PlaceholderColor3 = Color3.fromRGB(100, 100, 110),
        PlaceholderText = placeholder,
        Text = "",
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12
    })
    corner(b, 6)
    return b
end

local mapBtn = button(
    mainPage,
    "MAP: Select",
    UDim2.new(0.5, -5, 0, 34),
    UDim2.fromOffset(0, 4)
)

local npcBtn = button(
    mainPage,
    "NPC: Select",
    UDim2.new(0.5, -5, 0, 34),
    UDim2.new(0.5, 5, 0, 4)
)

local mapList = new("ScrollingFrame", {
    Parent = mainPage,
    Size = UDim2.fromOffset(150, 135),
    Position = UDim2.fromOffset(0, 42),
    BackgroundColor3 = Color3.fromRGB(23, 23, 28),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new()
})
corner(mapList, 6)

local mapLayout = Instance.new("UIListLayout")
mapLayout.Padding = UDim.new(0, 3)
mapLayout.Parent = mapList

local npcList = new("ScrollingFrame", {
    Parent = mainPage,
    Size = UDim2.fromOffset(150, 135),
    Position = UDim2.fromOffset(158, 42),
    BackgroundColor3 = Color3.fromRGB(23, 23, 28),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new()
})
corner(npcList, 6)

local npcLayout = Instance.new("UIListLayout")
npcLayout.Padding = UDim.new(0, 3)
npcLayout.Parent = npcList

local tpBtn = button(
    mainPage,
    "TELEPORT",
    UDim2.new(0.32, -4, 0, 36),
    UDim2.fromOffset(0, 290)
)

local farmBtn = button(
    mainPage,
    "FARM: OFF",
    UDim2.new(0.32, -4, 0, 36),
    UDim2.new(0.34, 0, 0, 290)
)

local adminOpenBtn = button(
    mainPage,
    "ADMIN",
    UDim2.new(0.32, -4, 0, 36),
    UDim2.new(0.68, 0, 0, 290)
)

local status = new("TextLabel", {
    Parent = mainPage,
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.fromOffset(0, 250),
    BackgroundTransparency = 1,
    Text = "No map selected",
    TextColor3 = Color3.fromRGB(130, 130, 140),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
})

local mapName = box(
    adminPage,
    "Nama Map",
    UDim2.fromOffset(180, 32),
    UDim2.fromOffset(0, 4)
)

local mapOrder = box(
    adminPage,
    "Urutan",
    UDim2.fromOffset(55, 32),
    UDim2.fromOffset(188, 4)
)

local addMap = button(
    adminPage,
    "+ MAP",
    UDim2.fromOffset(68, 32),
    UDim2.fromOffset(245, 4)
)

local npcName = box(
    adminPage,
    "Nama NPC / Mob",
    UDim2.fromOffset(237, 32),
    UDim2.fromOffset(0, 45)
)

local addNPC = button(
    adminPage,
    "+ NPC",
    UDim2.fromOffset(75, 32),
    UDim2.fromOffset(245, 45)
)

local adminStatus = new("TextLabel", {
    Parent = adminPage,
    Size = UDim2.new(1, 0, 0, 22),
    Position = UDim2.fromOffset(0, 82),
    BackgroundTransparency = 1,
    Text = "Pilih map + NPC",
    TextColor3 = Color3.fromRGB(140, 140, 150),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left
})

local positionList = new("ScrollingFrame", {
    Parent = adminPage,
    Size = UDim2.new(1, 0, 0, 185),
    Position = UDim2.fromOffset(0, 108),
    BackgroundColor3 = Color3.fromRGB(22, 22, 27),
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    CanvasSize = UDim2.new()
})
corner(positionList, 6)

local positionLayout = Instance.new("UIListLayout")
positionLayout.Padding = UDim.new(0, 4)
positionLayout.Parent = positionList

local addPosition = button(
    adminPage,
    "+ POSITION",
    UDim2.fromOffset(100, 34),
    UDim2.fromOffset(0, 300)
)

local saveNPC = button(
    adminPage,
    "SAVE",
    UDim2.fromOffset(100, 34),
    UDim2.fromOffset(108, 300)
)

local deleteNPC = button(
    adminPage,
    "DELETE",
    UDim2.fromOffset(100, 34),
    UDim2.fromOffset(216, 300)
)

local function clear(container, layout)
    for _, v in ipairs(container:GetChildren()) do
        if v ~= layout then
            v:Destroy()
        end
    end
end

local function refreshStatus()
    local m = selectedMap and selectedMap.Name or "-"
    local n = selectedNPC and selectedNPC.Name or "-"
    status.Text = "Map: " .. m .. "  |  NPC: " .. n
    adminStatus.Text = "Map: " .. m .. "  |  NPC: " .. n
end

local function refreshNPCs()
    clear(npcList, npcLayout)

    if not selectedMap then
        npcBtn.Text = "NPC: Select"
        selectedNPC = nil
        refreshStatus()
        return
    end

    for _, npc in ipairs(selectedMap.NPCs) do
        local b = button(
            npcList,
            npc.Name,
            UDim2.new(1, -6, 0, 30),
            UDim2.new()
        )

        b.MouseButton1Click:Connect(function()
            selectedNPC = npc
            npcBtn.Text = "NPC: " .. npc.Name
            npcList.Visible = false
            refreshStatus()
            refreshPositionRows()
        end)
    end

    npcList.CanvasSize = UDim2.fromOffset(
        0,
        npcLayout.AbsoluteContentSize.Y + 6
    )

    refreshStatus()
end

local function refreshMaps()
    clear(mapList, mapLayout)

    table.sort(DATA.Maps, function(a, b)
        return a.Order < b.Order
    end)

    for _, map in ipairs(DATA.Maps) do
        local b = button(
            mapList,
            tostring(map.Order) .. "  " .. map.Name,
            UDim2.new(1, -6, 0, 30),
            UDim2.new()
        )

        b.MouseButton1Click:Connect(function()
            selectedMap = map
            selectedNPC = nil
            mapBtn.Text = "MAP: " .. map.Name
            npcBtn.Text = "NPC: Select"
            mapList.Visible = false
            refreshNPCs()
            refreshPositionRows()
        end)
    end

    mapList.CanvasSize = UDim2.fromOffset(
        0,
        mapLayout.AbsoluteContentSize.Y + 6
    )
end

function refreshPositionRows()
    clear(positionList, positionLayout)

    if not selectedNPC then
        return
    end

    for i, pos in ipairs(selectedNPC.Positions) do
        local row = new("Frame", {
            Parent = positionList,
            Size = UDim2.new(1, -6, 0, 44),
            BackgroundColor3 = Color3.fromRGB(30, 30, 36),
            BorderSizePixel = 0
        })
        corner(row, 5)

        new("TextLabel", {
            Parent = row,
            Size = UDim2.fromOffset(24, 44),
            Position = UDim2.fromOffset(4, 0),
            BackgroundTransparency = 1,
            Text = tostring(i),
            TextColor3 = Color3.fromRGB(150, 150, 160),
            Font = Enum.Font.GothamBold,
            TextSize = 11
        })

        local x = box(row, "X", UDim2.fromOffset(82, 28), UDim2.fromOffset(30, 8))
        local y = box(row, "Y", UDim2.fromOffset(82, 28), UDim2.fromOffset(116, 8))
        local z = box(row, "Z", UDim2.fromOffset(82, 28), UDim2.fromOffset(202, 8))

        x.Text = tostring(pos.X)
        y.Text = tostring(pos.Y)
        z.Text = tostring(pos.Z)

        local remove = button(
            row,
            "X",
            UDim2.fromOffset(34, 28),
            UDim2.fromOffset(289, 8)
        )

        remove.MouseButton1Click:Connect(function()
            table.remove(selectedNPC.Positions, i)
            refreshPositionRows()
        end)
    end

    positionList.CanvasSize = UDim2.fromOffset(
        0,
        positionLayout.AbsoluteContentSize.Y + 6
    )
end

mapBtn.MouseButton1Click:Connect(function()
    npcList.Visible = false
    mapList.Visible = not mapList.Visible
end)

npcBtn.MouseButton1Click:Connect(function()
    mapList.Visible = false
    if selectedMap then
        npcList.Visible = not npcList.Visible
    end
end)

tpBtn.MouseButton1Click:Connect(function()
    if selectedNPC and selectedNPC.Positions[1] then
        tp(selectedNPC.Positions[1])
    end
end)

farmBtn.MouseButton1Click:Connect(function()
    farming = not farming
    farmBtn.Text = farming and "FARM: ON" or "FARM: OFF"

    if not farming then
        return
    end

    task.spawn(function()
        local index = 1

        while farming do
            if not selectedNPC or #selectedNPC.Positions == 0 then
                task.wait(0.2)
                continue
            end

            if index > #selectedNPC.Positions then
                index = 1
            end

            tp(selectedNPC.Positions[index])

            for _ = 1, 6 do
                if not farming then
                    break
                end

                local character = player.Character

                if character then
                    for _, tool in ipairs(character:GetChildren()) do
                        if tool:IsA("Tool") then
                            tool:Activate()
                        end
                    end
                end

                task.wait(0.12)
            end

            index += 1
        end
    end)
end)

adminOpenBtn.MouseButton1Click:Connect(function()
    mainPage.Visible = false
    adminPage.Visible = true
    mapList.Visible = false
    npcList.Visible = false
end)

mainTab.MouseButton1Click:Connect(function()
    mainPage.Visible = true
    adminPage.Visible = false
end)

adminTab.MouseButton1Click:Connect(function()
    mainPage.Visible = false
    adminPage.Visible = true
end)

addMap.MouseButton1Click:Connect(function()
    local name = mapName.Text:match("^%s*(.-)%s*$")
    local order = tonumber(mapOrder.Text)

    if name == "" or not order then
        return
    end

    if findMap(name) then
        return
    end

    table.insert(DATA.Maps, {
        Name = name,
        Order = order,
        NPCs = {}
    })

    mapName.Text = ""
    mapOrder.Text = ""

    refreshMaps()
end)

addNPC.MouseButton1Click:Connect(function()
    if not selectedMap then
        return
    end

    local name = npcName.Text:match("^%s*(.-)%s*$")

    if name == "" or findNPC(selectedMap, name) then
        return
    end

    selectedNPC = {
        Name = name,
        Positions = {}
    }

    table.insert(selectedMap.NPCs, selectedNPC)

    npcName.Text = ""
    npcBtn.Text = "NPC: " .. name

    refreshNPCs()
    refreshPositionRows()
    refreshStatus()
end)

addPosition.MouseButton1Click:Connect(function()
    if not selectedNPC then
        return
    end

    table.insert(
        selectedNPC.Positions,
        Vector3.new(0, 0, 0)
    )

    refreshPositionRows()
end)

saveNPC.MouseButton1Click:Connect(function()
    if not selectedNPC then
        return
    end

    local rows = positionList:GetChildren()
    local positions = {}

    for i, row in ipairs(rows) do
        if row:IsA("Frame") then
            local boxes = {}

            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextBox") then
                    table.insert(boxes, child)
                end
            end

            table.sort(boxes, function(a, b)
                return a.AbsolutePosition.X < b.AbsolutePosition.X
            end)

            local x = boxes[1] and tonumber(boxes[1].Text)
            local y = boxes[2] and tonumber(boxes[2].Text)
            local z = boxes[3] and tonumber(boxes[3].Text)

            if x and y and z then
                table.insert(positions, Vector3.new(x, y, z))
            end
        end
    end

    selectedNPC.Positions = positions
    refreshPositionRows()
end)

deleteNPC.MouseButton1Click:Connect(function()
    if not selectedMap or not selectedNPC then
        return
    end

    for i, npc in ipairs(selectedMap.NPCs) do
        if npc == selectedNPC then
            table.remove(selectedMap.NPCs, i)
            break
        end
    end

    selectedNPC = nil
    npcBtn.Text = "NPC: Select"
    refreshNPCs()
    refreshPositionRows()
    refreshStatus()
end)

refreshMaps()
refreshStatus()
