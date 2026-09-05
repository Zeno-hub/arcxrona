local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DATA = {
    Maps = {}
}

local selectedMap = nil
local selectedNPC = nil
local farming = false

local function new(class, props)
    local x = Instance.new(class)
    for k, v in pairs(props) do
        x[k] = v
    end
    return x
end

local function round(x, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = x
end

local function findMap(name)
    for _, map in ipairs(DATA.Maps) do
        if map.Name == name then
            return map
        end
    end
end

local function sortMaps()
    table.sort(DATA.Maps, function(a, b)
        return a.Order < b.Order
    end)
end

local function findNPC(map, name)
    if not map then
        return
    end

    for _, npc in ipairs(map.NPCs) do
        if npc.Name == name then
            return npc
        end
    end
end

local function getRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleport(position)
    local root = getRoot()

    if root then
        root.CFrame = CFrame.new(position)
    end
end

local gui = new("ScreenGui", {
    Name = "AnimeSwordAutoFarm",
    ResetOnSpawn = false,
    Parent = playerGui
})

local main = new("Frame", {
    Parent = gui,
    Size = UDim2.fromOffset(430, 430),
    Position = UDim2.new(0.5, -215, 0.5, -215),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BorderSizePixel = 0,
    Active = true,
    Draggable = true
})
round(main, 8)

local title = new("TextLabel", {
    Parent = main,
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
    Text = "ANIME SWORDS AUTO FARM",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 16
})
round(title, 8)

local mapButton = new("TextButton", {
    Parent = main,
    Size = UDim2.fromOffset(190, 38),
    Position = UDim2.fromOffset(10, 55),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    Text = "MAP",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14
})
round(mapButton)

local npcButton = new("TextButton", {
    Parent = main,
    Size = UDim2.fromOffset(190, 38),
    Position = UDim2.fromOffset(210, 55),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    Text = "NPC / MOB",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14
})
round(npcButton)

local mapList = new("ScrollingFrame", {
    Parent = main,
    Size = UDim2.fromOffset(190, 170),
    Position = UDim2.fromOffset(10, 98),
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    Visible = false,
    CanvasSize = UDim2.new()
})
round(mapList)

local mapLayout = new("UIListLayout", {
    Parent = mapList,
    Padding = UDim.new(0, 3)
})

local npcList = new("ScrollingFrame", {
    Parent = main,
    Size = UDim2.fromOffset(190, 170),
    Position = UDim2.fromOffset(210, 98),
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    Visible = false,
    CanvasSize = UDim2.new()
})
round(npcList)

local npcLayout = new("UIListLayout", {
    Parent = npcList,
    Padding = UDim.new(0, 3)
})

local teleportButton = new("TextButton", {
    Parent = main,
    Size = UDim2.fromOffset(125, 40),
    Position = UDim2.fromOffset(10, 350),
    BackgroundColor3 = Color3.fromRGB(0, 160, 90),
    Text = "TELEPORT",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14
})
round(teleportButton)

local farmButton = new("TextButton", {
    Parent = main,
    Size = UDim2.fromOffset(125, 40),
    Position = UDim2.fromOffset(145, 350),
    BackgroundColor3 = Color3.fromRGB(50, 50, 55),
    Text = "AUTO FARM: OFF",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 13
})
round(farmButton)

local adminButton = new("TextButton", {
    Parent = main,
    Size = UDim2.fromOffset(125, 40),
    Position = UDim2.fromOffset(280, 350),
    BackgroundColor3 = Color3.fromRGB(70, 70, 150),
    Text = "ADMIN",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 14
})
round(adminButton)

local admin = new("Frame", {
    Parent = gui,
    Size = UDim2.fromOffset(540, 600),
    Position = UDim2.new(0.5, -270, 0.5, -300),
    BackgroundColor3 = Color3.fromRGB(25, 25, 25),
    BorderSizePixel = 0,
    Visible = false,
    Active = true,
    Draggable = true
})
round(admin, 8)

local adminTitle = new("TextLabel", {
    Parent = admin,
    Size = UDim2.new(1, -50, 0, 40),
    BackgroundColor3 = Color3.fromRGB(35, 35, 35),
    Text = "ADMIN PANEL",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 16
})
round(adminTitle, 8)

local closeAdmin = new("TextButton", {
    Parent = admin,
    Size = UDim2.fromOffset(40, 40),
    Position = UDim2.new(1, -40, 0, 0),
    BackgroundColor3 = Color3.fromRGB(160, 40, 40),
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 15
})
round(closeAdmin, 8)

local mapName = new("TextBox", {
    Parent = admin,
    Size = UDim2.fromOffset(300, 35),
    Position = UDim2.fromOffset(10, 55),
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    TextColor3 = Color3.new(1, 1, 1),
    PlaceholderText = "Nama Map",
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 14,
    ClearTextOnFocus = false
})
round(mapName)

local mapOrder = new("TextBox", {
    Parent = admin,
    Size = UDim2.fromOffset(90, 35),
    Position = UDim2.fromOffset(320, 55),
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    TextColor3 = Color3.new(1, 1, 1),
    PlaceholderText = "Urutan",
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 14,
    ClearTextOnFocus = false
})
round(mapOrder)

local addMap = new("TextButton", {
    Parent = admin,
    Size = UDim2.fromOffset(110, 35),
    Position = UDim2.fromOffset(420, 55),
    BackgroundColor3 = Color3.fromRGB(0, 150, 90),
    Text = "ADD MAP",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12
})
round(addMap)

local npcName = new("TextBox", {
    Parent = admin,
    Size = UDim2.fromOffset(410, 35),
    Position = UDim2.fromOffset(10, 105),
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    TextColor3 = Color3.new(1, 1, 1),
    PlaceholderText = "Nama NPC / Mob",
    Text = "",
    Font = Enum.Font.Gotham,
    TextSize = 14,
    ClearTextOnFocus = false
})
round(npcName)

local addNPC = new("TextButton", {
    Parent = admin,
    Size = UDim2.fromOffset(110, 35),
    Position = UDim2.fromOffset(420, 105),
    BackgroundColor3 = Color3.fromRGB(0, 150, 90),
    Text = "ADD NPC",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 12
})
round(addNPC)

local selectedLabel = new("TextLabel", {
    Parent = admin,
    Size = UDim2.new(1, -20, 0, 30),
    Position = UDim2.fromOffset(10, 150),
    BackgroundTransparency = 1,
    Text = "Map: - | NPC: -",
    TextColor3 = Color3.fromRGB(200, 200, 200),
    Font = Enum.Font.Gotham,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left
})

local positionList = new("ScrollingFrame", {
    Parent = admin,
    Size = UDim2.fromOffset(520, 330),
    Position = UDim2.fromOffset(10, 185),
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    CanvasSize = UDim2.new()
})
round(positionList)

local positionLayout = new("UIListLayout", {
    Parent = positionList,
    Padding = UDim.new(0, 5)
})

local addPosition = new("TextButton", {
    Parent = admin,
    Size = UDim2.fromOffset(160, 40),
    Position = UDim2.fromOffset(10, 535),
    BackgroundColor3 = Color3.fromRGB(0, 150, 90),
    Text = "+ POSITION",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 13
})
round(addPosition)

local saveNPC = new("TextButton", {
    Parent = admin,
    Size = UDim2.fromOffset(160, 40),
    Position = UDim2.fromOffset(190, 535),
    BackgroundColor3 = Color3.fromRGB(70, 70, 160),
    Text = "SAVE NPC",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 13
})
round(saveNPC)

local deleteNPC = new("TextButton", {
    Parent = admin,
    Size = UDim2.fromOffset(160, 40),
    Position = UDim2.fromOffset(370, 535),
    BackgroundColor3 = Color3.fromRGB(160, 40, 40),
    Text = "DELETE NPC",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold,
    TextSize = 13
})
round(deleteNPC)

local function updatePositionCanvas()
    positionList.CanvasSize = UDim2.fromOffset(
        0,
        positionLayout.AbsoluteContentSize.Y + 10
    )
end

local function clearList(container, layout)
    for _, child in ipairs(container:GetChildren()) do
        if child ~= layout then
            child:Destroy()
        end
    end
end

local function refreshMaps()
    clearList(mapList, mapLayout)

    sortMaps()

    for _, map in ipairs(DATA.Maps) do
        local b = new("TextButton", {
            Parent = mapList,
            Size = UDim2.new(1, -8, 0, 34),
            BackgroundColor3 = Color3.fromRGB(40, 40, 45),
            Text = tostring(map.Order) .. "  •  " .. map.Name,
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamMedium,
            TextSize = 13
        })

        round(b)

        b.MouseButton1Click:Connect(function()
            selectedMap = map
            selectedNPC = nil
            mapButton.Text = tostring(map.Order) .. " • " .. map.Name
            npcButton.Text = "NPC / MOB"
            mapList.Visible = false
            refreshNPCs()
        end)
    end

    mapList.CanvasSize = UDim2.fromOffset(
        0,
        mapLayout.AbsoluteContentSize.Y + 10
    )
end

function refreshNPCs()
    clearList(npcList, npcLayout)

    if not selectedMap then
        return
    end

    for _, npc in ipairs(selectedMap.NPCs) do
        local b = new("TextButton", {
            Parent = npcList,
            Size = UDim2.new(1, -8, 0, 34),
            BackgroundColor3 = Color3.fromRGB(40, 40, 45),
            Text = npc.Name,
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamMedium,
            TextSize = 13
        })

        round(b)

        b.MouseButton1Click:Connect(function()
            selectedNPC = npc
            npcButton.Text = npc.Name
            npcList.Visible = false

            selectedLabel.Text =
                "Map: " .. selectedMap.Name ..
                " | NPC: " .. selectedNPC.Name

            refreshPositionRows()
        end)
    end

    npcList.CanvasSize = UDim2.fromOffset(
        0,
        npcLayout.AbsoluteContentSize.Y + 10
    )
end

function refreshPositionRows()
    clearList(positionList, positionLayout)

    if not selectedNPC then
        return
    end

    for index, position in ipairs(selectedNPC.Positions) do
        local row = new("Frame", {
            Parent = positionList,
            Size = UDim2.new(1, -10, 0, 48),
            BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        })

        round(row)

        local number = new("TextLabel", {
            Parent = row,
            Size = UDim2.fromOffset(30, 48),
            Position = UDim2.fromOffset(5, 0),
            BackgroundTransparency = 1,
            Text = tostring(index),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.GothamBold,
            TextSize = 13
        })

        local x = new("TextBox", {
            Parent = row,
            Size = UDim2.fromOffset(145, 32),
            Position = UDim2.fromOffset(38, 8),
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            Text = tostring(position.X),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.Code,
            TextSize = 13,
            ClearTextOnFocus = false
        })
        round(x)

        local y = new("TextBox", {
            Parent = row,
            Size = UDim2.fromOffset(145, 32),
            Position = UDim2.fromOffset(190, 8),
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            Text = tostring(position.Y),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.Code,
            TextSize = 13,
            ClearTextOnFocus = false
        })
        round(y)

        local z = new("TextBox", {
            Parent = row,
            Size = UDim2.fromOffset(145, 32),
            Position = UDim2.fromOffset(342, 8),
            BackgroundColor3 = Color3.fromRGB(15, 15, 15),
            Text = tostring(position.Z),
            TextColor3 = Color3.new(1, 1, 1),
            Font = Enum.Font.Code,
            TextSize = 13,
            ClearTextOnFocus = false
        })
        round(z)

        row:SetAttribute("Index", index)
        row:SetAttribute("X", 0)

        x:GetPropertyChangedSignal("Text"):Connect(function()
            row:SetAttribute("X", 1)
        end)

        y:GetPropertyChangedSignal("Text"):Connect(function()
            row:SetAttribute("X", 1)
        end)

        z:GetPropertyChangedSignal("Text"):Connect(function()
            row:SetAttribute("X", 1)
        end)

        row:SetAttribute("XText", "")
        row:SetAttribute("YText", "")
        row:SetAttribute("ZText", "")

        x:SetAttribute("Axis", "X")
        y:SetAttribute("Axis", "Y")
        z:SetAttribute("Axis", "Z")

        local function saveRow()
            local xv = tonumber(x.Text)
            local yv = tonumber(y.Text)
            local zv = tonumber(z.Text)

            if xv and yv and zv then
                selectedNPC.Positions[index] =
                    Vector3.new(xv, yv, zv)
            end
        end

        x.FocusLost:Connect(saveRow)
        y.FocusLost:Connect(saveRow)
        z.FocusLost:Connect(saveRow)
    end

    updatePositionCanvas()
end

mapButton.MouseButton1Click:Connect(function()
    npcList.Visible = false
    mapList.Visible = not mapList.Visible
end)

npcButton.MouseButton1Click:Connect(function()
    if selectedMap then
        mapList.Visible = false
        npcList.Visible = not npcList.Visible
    end
end)

teleportButton.MouseButton1Click:Connect(function()
    if selectedNPC and selectedNPC.Positions[1] then
        teleport(selectedNPC.Positions[1])
    end
end)

farmButton.MouseButton1Click:Connect(function()
    farming = not farming
    farmButton.Text = farming and "AUTO FARM: ON" or "AUTO FARM: OFF"

    if not farming then
        return
    end

    task.spawn(function()
        local index = 1

        while farming do
            if not selectedNPC then
                task.wait()
                continue
            end

            if #selectedNPC.Positions == 0 then
                task.wait()
                continue
            end

            if index > #selectedNPC.Positions then
                index = 1
            end

            teleport(selectedNPC.Positions[index])

            local start = os.clock()

            while farming and os.clock() - start < 0.8 do
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

adminButton.MouseButton1Click:Connect(function()
    admin.Visible = not admin.Visible
end)

closeAdmin.MouseButton1Click:Connect(function()
    admin.Visible = false
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

    if name == "" then
        return
    end

    if findNPC(selectedMap, name) then
        return
    end

    selectedNPC = {
        Name = name,
        Positions = {}
    }

    table.insert(selectedMap.NPCs, selectedNPC)

    npcName.Text = ""

    refreshNPCs()
    refreshPositionRows()

    selectedLabel.Text =
        "Map: " .. selectedMap.Name ..
        " | NPC: " .. selectedNPC.Name
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

    refreshPositionRows()
    refreshNPCs()
    refreshMaps()
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
    npcButton.Text = "NPC / MOB"

    selectedLabel.Text =
        "Map: " .. selectedMap.Name ..
        " | NPC: -"

    refreshNPCs()
    refreshPositionRows()
end)

refreshMaps()
