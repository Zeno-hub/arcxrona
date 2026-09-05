local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("ArcheronGUI")
if old then old:Destroy() end

-- ================= THEME =================
local COLOR_BG = Color3.fromRGB(15, 15, 20)
local COLOR_HEADER = Color3.fromRGB(35, 15, 60)
local COLOR_ACCENT = Color3.fromRGB(150, 60, 255)
local COLOR_PANEL = Color3.fromRGB(24, 24, 29)
local COLOR_TEXT = Color3.fromRGB(240, 240, 245)
local COLOR_SUBTEXT = Color3.fromRGB(180, 160, 220)

local function create(class, props)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	return obj
end

local function round(obj, r)
	create("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = obj })
end

-- ================= DATA / LOGIC =================
local DATA = { Maps = {} }
local selectedMap, selectedNPC
local farming = false

local function getRoot()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleport(pos)
	local root = getRoot()
	if root then root.CFrame = CFrame.new(pos) end
end

local function findMap(name)
	for _, m in ipairs(DATA.Maps) do
		if m.Name == name then return m end
	end
end

local function findNPC(map, name)
	if not map then return nil end
	for _, n in ipairs(map.NPCs) do
		if n.Name == name then return n end
	end
end

-- ================= ROOT GUI =================
local gui = create("ScreenGui", {
	Name = "ArcheronGUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = playerGui
})

-- ================= MAIN CONTAINER =================
local main = create("Frame", {
	Name = "Main",
	Size = UDim2.new(0, 380, 0, 480),
	Position = UDim2.new(0.5, -190, 0.5, -240),
	BackgroundColor3 = COLOR_BG,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = gui
})
round(main, 14)

-- ================= HEADER =================
local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 60),
	BackgroundColor3 = COLOR_HEADER,
	BorderSizePixel = 0,
	Active = true,
	ZIndex = 2,
	Parent = main
})
round(header, 14)
create("Frame", {
	Size = UDim2.new(1, 0, 0, 14),
	Position = UDim2.new(0, 0, 1, -14),
	BackgroundColor3 = COLOR_HEADER,
	BorderSizePixel = 0,
	ZIndex = 2,
	Parent = header
})

local icon = create("ImageLabel", {
	Size = UDim2.new(0, 40, 0, 40),
	Position = UDim2.new(0, 12, 0.5, -20),
	BackgroundColor3 = Color3.fromRGB(60, 30, 90),
	Image = "",
	ZIndex = 3,
	Parent = header
})
round(icon, 8)

create("TextLabel", {
	Size = UDim2.new(1, -170, 0, 22),
	Position = UDim2.new(0, 60, 0, 8),
	BackgroundTransparency = 1,
	Text = "Anime Swords",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = COLOR_TEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 3,
	Parent = header
})

create("TextLabel", {
	Size = UDim2.new(1, -170, 0, 16),
	Position = UDim2.new(0, 60, 0, 30),
	BackgroundTransparency = 1,
	Text = "Archeron",
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextColor3 = COLOR_SUBTEXT,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 3,
	Parent = header
})

-- Tombol Main / Admin (tab switch, BUKAN buka window baru)
local mainTabBtn = create("TextButton", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -76, 0, 8),
	BackgroundColor3 = COLOR_ACCENT,
	Text = "☰",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = COLOR_TEXT,
	ZIndex = 3,
	Parent = header
})
round(mainTabBtn, 8)

local adminTabBtn = create("TextButton", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -114, 0, 8),
	BackgroundColor3 = Color3.fromRGB(45, 45, 52),
	Text = "⚙",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = COLOR_TEXT,
	ZIndex = 3,
	Parent = header
})
round(adminTabBtn, 8)

local closeBtn = create("TextButton", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -38, 0, 8),
	BackgroundColor3 = Color3.fromRGB(60, 20, 30),
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = COLOR_TEXT,
	ZIndex = 3,
	Parent = header
})
round(closeBtn, 8)

-- drag via header
do
	local UIS = game:GetService("UserInputService")
	local dragging, dragInput, dragStart, startPos
	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ================= BODY =================
local body = create("Frame", {
	Size = UDim2.new(1, 0, 1, -60),
	Position = UDim2.new(0, 0, 0, 60),
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BackgroundTransparency = 0.4,
	BorderSizePixel = 0,
	Parent = main
})

local categoryFrame = create("Frame", {
	Size = UDim2.new(1, -20, 0, 34),
	Position = UDim2.new(0, 10, 0, 10),
	BackgroundTransparency = 1,
	Parent = body
})
create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), Parent = categoryFrame })

local mainTab = create("TextButton", {
	Size = UDim2.new(0, 90, 1, 0),
	BackgroundColor3 = COLOR_ACCENT,
	Text = "Main",
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = COLOR_TEXT,
	Parent = categoryFrame
})
round(mainTab, 8)

-- ================= MAIN PAGE =================
local mainPage = create("Frame", {
	Size = UDim2.new(1, -20, 1, -54),
	Position = UDim2.new(0, 10, 0, 54),
	BackgroundTransparency = 1,
	Visible = true,
	Parent = body
})

local function makeButton(parent, text, size, pos)
	local b = create("TextButton", {
		Parent = parent, Size = size, Position = pos,
		BackgroundColor3 = Color3.fromRGB(34, 34, 40),
		Text = text, TextColor3 = COLOR_TEXT,
		Font = Enum.Font.GothamMedium, TextSize = 11
	})
	round(b, 6)
	return b
end

local function makeBox(parent, placeholder, size, pos)
	local b = create("TextBox", {
		Parent = parent, Size = size, Position = pos,
		BackgroundColor3 = Color3.fromRGB(12, 12, 15),
		TextColor3 = COLOR_TEXT, PlaceholderColor3 = Color3.fromRGB(100, 100, 110),
		PlaceholderText = placeholder, Text = "", ClearTextOnFocus = false,
		Font = Enum.Font.Gotham, TextSize = 11
	})
	round(b, 6)
	return b
end

local mapBtn = makeButton(mainPage, "MAP: Select", UDim2.fromOffset(160, 32), UDim2.fromOffset(0, 0))
local npcBtn = makeButton(mainPage, "NPC: Select", UDim2.fromOffset(160, 32), UDim2.fromOffset(168, 0))

local mapList = create("ScrollingFrame", {
	Parent = mainPage, Size = UDim2.fromOffset(160, 110), Position = UDim2.fromOffset(0, 36),
	BackgroundColor3 = COLOR_PANEL, BorderSizePixel = 0, ScrollBarThickness = 3,
	CanvasSize = UDim2.new(), Visible = false
})
round(mapList, 6)
local mapLayout = create("UIListLayout", { Padding = UDim.new(0, 2), Parent = mapList })

local npcList = create("ScrollingFrame", {
	Parent = mainPage, Size = UDim2.fromOffset(160, 110), Position = UDim2.fromOffset(168, 36),
	BackgroundColor3 = COLOR_PANEL, BorderSizePixel = 0, ScrollBarThickness = 3,
	CanvasSize = UDim2.new(), Visible = false
})
round(npcList, 6)
local npcLayout = create("UIListLayout", { Padding = UDim.new(0, 2), Parent = npcList })

local status = create("TextLabel", {
	Parent = mainPage, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 155),
	BackgroundTransparency = 1, Text = "Map: -  |  NPC: -",
	TextColor3 = COLOR_SUBTEXT, Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left
})

local tpBtn = makeButton(mainPage, "TELEPORT", UDim2.fromOffset(105, 34), UDim2.fromOffset(0, 190))
local farmBtn = makeButton(mainPage, "FARM: OFF", UDim2.fromOffset(105, 34), UDim2.fromOffset(112, 190))
farmBtn.BackgroundColor3 = COLOR_ACCENT

-- ================= ADMIN PAGE (nempel di body yang sama, bukan window baru) =================
local adminPage = create("Frame", {
	Size = UDim2.new(1, -20, 1, -54),
	Position = UDim2.new(0, 10, 0, 54),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = body
})

local mapNameBox = makeBox(adminPage, "Map name", UDim2.fromOffset(150, 30), UDim2.fromOffset(0, 0))
local mapOrderBox = makeBox(adminPage, "Order", UDim2.fromOffset(55, 30), UDim2.fromOffset(156, 0))
local addMapBtn = makeButton(adminPage, "+ MAP", UDim2.fromOffset(61, 30), UDim2.fromOffset(217, 0))

local npcNameBox = makeBox(adminPage, "NPC / Mob", UDim2.fromOffset(150, 30), UDim2.fromOffset(0, 38))
local addNPCBtn = makeButton(adminPage, "+ NPC", UDim2.fromOffset(128, 30), UDim2.fromOffset(156, 38))

local adminStatus = create("TextLabel", {
	Parent = adminPage, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 74),
	BackgroundTransparency = 1, Text = "Pilih Map dan NPC", TextColor3 = COLOR_SUBTEXT,
	Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left
})

local positionList = create("ScrollingFrame", {
	Parent = adminPage, Size = UDim2.new(1, 0, 0, 145), Position = UDim2.fromOffset(0, 96),
	BackgroundColor3 = COLOR_PANEL, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new()
})
round(positionList, 6)
local positionLayout = create("UIListLayout", { Padding = UDim.new(0, 3), Parent = positionList })

local addPositionBtn = makeButton(adminPage, "+ POSITION", UDim2.fromOffset(92, 30), UDim2.fromOffset(0, 245))
local saveBtn = makeButton(adminPage, "SAVE", UDim2.fromOffset(92, 30), UDim2.fromOffset(98, 245))
local deleteBtn = makeButton(adminPage, "DELETE", UDim2.fromOffset(92, 30), UDim2.fromOffset(196, 245))

-- ================= FLOATING TOGGLE =================
local floatBtn = create("TextButton", {
	Size = UDim2.fromOffset(50, 50),
	Position = UDim2.new(0.5, -25, 0.9, -25),
	BackgroundColor3 = COLOR_HEADER,
	Text = "A", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = COLOR_ACCENT,
	Visible = false, ZIndex = 10, Parent = gui
})
round(floatBtn, 25)

do
	local UIS = game:GetService("UserInputService")
	local dragging, dragInput, dragStart, startPos
	floatBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = floatBtn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	floatBtn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			floatBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- ================= LOGIC =================
local function clearList(container, layout)
	for _, child in ipairs(container:GetChildren()) do
		if child ~= layout then child:Destroy() end
	end
end

local function updateStatus()
	local mapText = selectedMap and selectedMap.Name or "-"
	local npcText = selectedNPC and selectedNPC.Name or "-"
	status.Text = "Map: " .. mapText .. "  |  NPC: " .. npcText
	adminStatus.Text = "Map: " .. mapText .. "  |  NPC: " .. npcText
end

local function refreshPositions()
	clearList(positionList, positionLayout)
	if not selectedNPC then return end

	for index, position in ipairs(selectedNPC.Positions) do
		local row = create("Frame", {
			Parent = positionList, Size = UDim2.new(1, -6, 0, 40),
			BackgroundColor3 = Color3.fromRGB(30, 30, 36), BorderSizePixel = 0
		})
		round(row, 5)

		create("TextLabel", {
			Parent = row, Size = UDim2.fromOffset(20, 40), Position = UDim2.fromOffset(4, 0),
			BackgroundTransparency = 1, Text = tostring(index), TextColor3 = COLOR_SUBTEXT,
			Font = Enum.Font.GothamBold, TextSize = 10
		})

		local x = makeBox(row, "X", UDim2.fromOffset(68, 26), UDim2.fromOffset(27, 7))
		local y = makeBox(row, "Y", UDim2.fromOffset(68, 26), UDim2.fromOffset(99, 7))
		local z = makeBox(row, "Z", UDim2.fromOffset(68, 26), UDim2.fromOffset(171, 7))
		x.Text, y.Text, z.Text = tostring(position.X), tostring(position.Y), tostring(position.Z)

		local remove = makeButton(row, "×", UDim2.fromOffset(30, 26), UDim2.fromOffset(243, 7))
		remove.MouseButton1Click:Connect(function()
			if selectedNPC then
				table.remove(selectedNPC.Positions, index)
				refreshPositions()
			end
		end)
	end

	positionList.CanvasSize = UDim2.fromOffset(0, positionLayout.AbsoluteContentSize.Y + 5)
end

local function refreshNPCs()
	clearList(npcList, npcLayout)
	if not selectedMap then return end

	for _, npc in ipairs(selectedMap.NPCs) do
		local b = makeButton(npcList, npc.Name, UDim2.new(1, -5, 0, 28), UDim2.new())
		b.MouseButton1Click:Connect(function()
			selectedNPC = npc
			npcBtn.Text = "NPC: " .. npc.Name
			npcList.Visible = false
			updateStatus()
			refreshPositions()
		end)
	end

	npcList.CanvasSize = UDim2.fromOffset(0, npcLayout.AbsoluteContentSize.Y + 5)
	updateStatus()
end

local function refreshMaps()
	clearList(mapList, mapLayout)
	table.sort(DATA.Maps, function(a, b) return a.Order < b.Order end)

	for _, map in ipairs(DATA.Maps) do
		local b = makeButton(mapList, tostring(map.Order) .. "  " .. map.Name, UDim2.new(1, -5, 0, 28), UDim2.new())
		b.MouseButton1Click:Connect(function()
			selectedMap = map
			selectedNPC = nil
			mapBtn.Text = "MAP: " .. map.Name
			npcBtn.Text = "NPC: Select"
			mapList.Visible = false
			refreshNPCs()
			refreshPositions()
			updateStatus()
		end)
	end

	mapList.CanvasSize = UDim2.fromOffset(0, mapLayout.AbsoluteContentSize.Y + 5)
end

mapBtn.MouseButton1Click:Connect(function()
	npcList.Visible = false
	mapList.Visible = not mapList.Visible
end)

npcBtn.MouseButton1Click:Connect(function()
	mapList.Visible = false
	if selectedMap then npcList.Visible = not npcList.Visible end
end)

tpBtn.MouseButton1Click:Connect(function()
	if selectedNPC and selectedNPC.Positions[1] then
		teleport(selectedNPC.Positions[1])
	end
end)

farmBtn.MouseButton1Click:Connect(function()
	farming = not farming
	farmBtn.Text = farming and "FARM: ON" or "FARM: OFF"
	farmBtn.BackgroundColor3 = farming and Color3.fromRGB(60, 200, 100) or COLOR_ACCENT
	if not farming then return end

	task.spawn(function()
		local index = 1
		while farming do
			if not selectedNPC or #selectedNPC.Positions == 0 then
				task.wait(0.2)
				continue
			end
			if index > #selectedNPC.Positions then index = 1 end
			teleport(selectedNPC.Positions[index])
			task.wait(0.6)
			index += 1
		end
	end)
end)

addMapBtn.MouseButton1Click:Connect(function()
	local name = mapNameBox.Text:match("^%s*(.-)%s*$")
	local order = tonumber(mapOrderBox.Text)
	if name == "" or not order or findMap(name) then return end

	table.insert(DATA.Maps, { Name = name, Order = order, NPCs = {} })
	mapNameBox.Text = ""
	mapOrderBox.Text = ""
	refreshMaps()
end)

addNPCBtn.MouseButton1Click:Connect(function()
	if not selectedMap then return end
	local name = npcNameBox.Text:match("^%s*(.-)%s*$")
	if name == "" or findNPC(selectedMap, name) then return end

	local npc = { Name = name, Positions = {} }
	table.insert(selectedMap.NPCs, npc)
	selectedNPC = npc
	npcNameBox.Text = ""
	npcBtn.Text = "NPC: " .. name
	refreshNPCs()
	refreshPositions()
	updateStatus()
end)

addPositionBtn.MouseButton1Click:Connect(function()
	if not selectedNPC then return end
	table.insert(selectedNPC.Positions, Vector3.new(0, 0, 0))
	refreshPositions()
end)

saveBtn.MouseButton1Click:Connect(function()
	if not selectedNPC then return end
	local positions = {}

	for _, row in ipairs(positionList:GetChildren()) do
		if row:IsA("Frame") then
			local boxes = {}
			for _, child in ipairs(row:GetChildren()) do
				if child:IsA("TextBox") then table.insert(boxes, child) end
			end
			table.sort(boxes, function(a, b) return a.AbsolutePosition.X < b.AbsolutePosition.X end)
			local x = boxes[1] and tonumber(boxes[1].Text)
			local y = boxes[2] and tonumber(boxes[2].Text)
			local z = boxes[3] and tonumber(boxes[3].Text)
			if x and y and z then table.insert(positions, Vector3.new(x, y, z)) end
		end
	end

	selectedNPC.Positions = positions
	refreshPositions()
end)

deleteBtn.MouseButton1Click:Connect(function()
	if not selectedMap or not selectedNPC then return end
	for i, npc in ipairs(selectedMap.NPCs) do
		if npc == selectedNPC then
			table.remove(selectedMap.NPCs, i)
			break
		end
	end
	selectedNPC = nil
	npcBtn.Text = "NPC: Select"
	refreshNPCs()
	refreshPositions()
	updateStatus()
end)

-- ================= TAB & TOGGLE LOGIC =================
mainTabBtn.MouseButton1Click:Connect(function()
	mainPage.Visible = true
	adminPage.Visible = false
	mainTabBtn.BackgroundColor3 = COLOR_ACCENT
	adminTabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
end)

adminTabBtn.MouseButton1Click:Connect(function()
	mainPage.Visible = false
	adminPage.Visible = true
	adminTabBtn.BackgroundColor3 = COLOR_ACCENT
	mainTabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
end)

closeBtn.MouseButton1Click:Connect(function()
	main.Visible = false
	floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
	main.Visible = true
	floatBtn.Visible = false
end)

refreshMaps()
updateStatus()
