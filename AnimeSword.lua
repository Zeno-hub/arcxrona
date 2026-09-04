local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer

local DATA = {
    Maps = {}
}

local CONFIG = {
    PositionDelay = 0.8,
    AttackDelay = 0.12,
    Offset = Vector3.new(0, 3, 0)
}

local selectedMap nil
local selectedNPC nil
local farming = false

local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function corner(obj)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = obj
end

local function getRoot()
    local character = Player.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function teleport(position)
    local root = getRoot()
    if root then
        root.CFrame = CFrame.new(position + CONFIG.Offset)
    end
end

local function attack()
    local character = Player.Character
    if not character then
        return
    end

    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Tool") then
            obj:Activate()
            return
        end
    end
end

local Gui = create("ScreenGui", {
    Name = "AnimeSwords",
    ResetOnSpawn = false,
    Parent = Player:WaitForChild("PlayerGui")
})

local Main = create("Frame", {
    Parent = Gui,
    Size = UDim2.fromOffset(430, 500),
    Position = UDim2.new(0, 25, 0.5, -250),
    BackgroundColor3 = Color3.fromRGB(18, 18, 23)
})
corner(Main)

local Title = create("TextLabel", {
    Parent = Main,
    Size = UDim2.new(1, -20, 0, 45),
    Position = UDim2.fromOffset(15, 0),
    BackgroundTransparency = 1,
    Text = "ANIME SWORDS AUTO FARM",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
})

local MapButton = create("TextButton", {
    Parent = Main,
    Size = UDim2.fromOffset(250, 40),
    Position = UDim2.fromOffset(15, 60),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    Text = "SELECT MAP",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamMedium
})
corner(MapButton)

local MapList = create("Frame", {
    Parent = Main,
    Size = UDim2.fromOffset(250, 150),
    Position = UDim2.fromOffset(15, 103),
    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
    Visible = false
})
corner(MapList)

local MapLayout = Instance.new("UIListLayout")
MapLayout.Padding = UDim.new(0, 3)
MapLayout.Parent = MapList

local NPCButton = create("TextButton", {
    Parent = Main,
    Size = UDim2.fromOffset(250, 40),
    Position = UDim2.fromOffset(15, 190),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    Text = "SELECT NPC",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamMedium
})
corner(NPCButton)

local NPCList = create("Frame", {
    Parent = Main,
    Size = UDim2.fromOffset(250, 150),
    Position = UDim2.fromOffset(15, 233),
    BackgroundColor3 = Color3.fromRGB(25, 25, 30),
    Visible = false
})
corner(NPCList)

local NPCLayout = Instance.new("UIListLayout")
NPCLayout.Padding = UDim.new(0, 3)
NPCLayout.Parent = NPCList

local TeleportButton = create("TextButton", {
    Parent = Main,
    Size = UDim2.fromOffset(120, 40),
    Position = UDim2.fromOffset(15, 400),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    Text = "TELEPORT",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamMedium
})
corner(TeleportButton)

local FarmButton = create("TextButton", {
    Parent = Main,
    Size = UDim2.fromOffset(120, 40),
    Position = UDim2.fromOffset(145, 400),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    Text = "AUTO FARM: OFF",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamMedium
})
corner(FarmButton)

local AdminButton = create("TextButton", {
    Parent = Main,
    Size = UDim2.fromOffset(120, 40),
    Position = UDim2.fromOffset(275, 400),
    BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    Text = "ADMIN",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamMedium
})
corner(AdminButton)

local function clear(container, layout)
    for _, obj in ipairs(container:GetChildren()) do
        if obj ~= layout then
            obj:Destroy()
        end
    end
end

local function refreshNPCs()
    clear(NPCList, NPCLayout)

    if not selectedMap then
        return
    end

    for _, npc in ipairs(selectedMap.NPCs) do
        local b = create("TextButton", {
            Parent = NPCList,
            Size = UDim2.new(1, -8, 0, 32),
            BackgroundColor3 = Color3.fromRGB(35, 35, 42),
            Text = npc.Name,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 13,
            Font = Enum.Font.Gotham
        })

        corner(b)

        b.MouseButton1Click:Connect(function()
            selectedNPC = npc
            NPCButton.Text = npc.Name
            NPCList.Visible = false
        end)
    end
end

local function refreshMaps()
    clear(MapList, MapLayout)

    for _, map in ipairs(DATA.Maps) do
        local b = create("TextButton", {
            Parent = MapList,
            Size = UDim2.new(1, -8, 0, 32),
            BackgroundColor3 = Color3.fromRGB(35, 35, 42),
            Text = map.Name,
            TextColor3 = Color3.new(1, 1, 1),
            TextSize = 13,
            Font = Enum.Font.Gotham
        })

        corner(b)

        b.MouseButton1Click:Connect(function()
            selectedMap = map
            selectedNPC = nil
            MapButton.Text = map.Name
            NPCButton.Text = "SELECT NPC"
            MapList.Visible = false
            refreshNPCs()
        end)
    end
end

MapButton.MouseButton1Click:Connect(function()
    NPCList.Visible = false
    MapList.Visible = not MapList.Visible
end)

NPCButton.MouseButton1Click:Connect(function()
    if selectedMap then
        MapList.Visible = false
        NPCList.Visible = not NPCList.Visible
    end
end)

TeleportButton.MouseButton1Click:Connect(function()
    if selectedNPC and selectedNPC.Positions[1] then
        teleport(selectedNPC.Positions[1])
    end
end)

FarmButton.MouseButton1Click:Connect(function()
    farming = not farming
    FarmButton.Text = farming and "AUTO FARM: ON" or "AUTO FARM: OFF"

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

            local positions = selectedNPC.Positions

            if #positions == 0 then
                task.wait()
                continue
            end

            if index > #positions then
                index = 1
            end

            teleport(positions[index])

            local start = os.clock()

            while farming and os.clock() - start < CONFIG.PositionDelay do
                attack()
                task.wait(CONFIG.AttackDelay)
            end

            index += 1
        end
    end)
end)

refreshMaps()

selectedMap = DATA.Maps[1]

if selectedMap then
    MapButton.Text = selectedMap.Name
    refreshNPCs()
end
