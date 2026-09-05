local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("ArcheronGUI")
if old then
	old:Destroy()
end

local COLOR_BG = Color3.fromRGB(15, 15, 20)
local COLOR_HEADER = Color3.fromRGB(35, 15, 60)
local COLOR_ACCENT = Color3.fromRGB(150, 60, 255)
local COLOR_TEXT = Color3.fromRGB(240, 240, 245)
local COLOR_SUBTEXT = Color3.fromRGB(180, 160, 220)
local COLOR_CARD = Color3.fromRGB(30, 20, 45)

local DATA = {
	Maps = {}
}

local selectedMap = nil
local selectedNPC = nil
local farming = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ArcheronGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 380, 0, 460)
main.Position = UDim2.new(0.5, -190, 0.5, -230)
main.BackgroundColor3 = COLOR_BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = COLOR_HEADER
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 14)
headerFix.Position = UDim2.new(0, 0, 1, -14)
headerFix.BackgroundColor3 = COLOR_HEADER
headerFix.BorderSizePixel = 0
headerFix.ZIndex = 2
headerFix.Parent = header

local icon = Instance.new("ImageLabel")
icon.Name = "GameIcon"
icon.Size = UDim2.new(0, 40, 0, 40)
icon.Position = UDim2.new(0, 12, 0.5, -20)
icon.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
icon.Image = ""
icon.ZIndex = 3
icon.Parent = header

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = icon

local gameName = Instance.new("TextLabel")
gameName.Name = "GameName"
gameName.Size = UDim2.new(1, -170, 0, 22)
gameName.Position = UDim2.new(0, 60, 0, 8)
gameName.BackgroundTransparency = 1
gameName.Text = "Anime Swords"
gameName.Font = Enum.Font.GothamBold
gameName.TextSize = 16
gameName.TextColor3 = COLOR_TEXT
gameName.TextXAlignment = Enum.TextXAlignment.Left
gameName.ZIndex = 3
gameName.Parent = header

local brand = Instance.new("TextLabel")
brand.Name = "Brand"
brand.Size = UDim2.new(1, -170, 0, 16)
brand.Position = UDim2.new(0, 60, 0, 30)
brand.BackgroundTransparency = 1
brand.Text = "Archeron"
brand.Font = Enum.Font.Gotham
brand.TextSize = 12
brand.TextColor3 = COLOR_SUBTEXT
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.ZIndex = 3
brand.Parent = header

local adminBtn = Instance.new("TextButton")
adminBtn.Name = "AdminButton"
adminBtn.Size = UDim2.new(0, 30, 0, 30)
adminBtn.Position = UDim2.new(1, -76, 0, 8)
adminBtn.BackgroundColor3 = COLOR_ACCENT
adminBtn.Text = "⚙"
adminBtn.Font = Enum.Font.GothamBold
adminBtn.TextSize = 18
adminBtn.TextColor3 = COLOR_TEXT
adminBtn.ZIndex = 3
adminBtn.Parent = header

local adminCorner = Instance.new("UICorner")
adminCorner.CornerRadius = UDim.new(0, 8)
adminCorner.Parent = adminBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(60, 20, 30)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.TextColor3 = COLOR_TEXT
closeBtn.ZIndex = 3
closeBtn.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -60)
body.Position = UDim2.new(0, 0, 0, 60)
body.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
body.BackgroundTransparency = 0.4
body.BorderSizePixel = 0
body.Parent = main

local categoryFrame = Instance.new("Frame")
categoryFrame.Name = "CategoryFrame"
categoryFrame.Size = UDim2.new(1, -20, 0, 34)
categoryFrame.Position = UDim2.new(0, 10, 0, 10)
categoryFrame.BackgroundTransparency = 1
categoryFrame.Parent = body

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0, 8)
categoryLayout.Parent = categoryFrame

local mainTab = Instance.new("TextButton")
mainTab.Name = "Tab_Main"
mainTab.Size = UDim2.new(0, 90, 1, 0)
mainTab.BackgroundColor3 = COLOR_ACCENT
mainTab.Text = "Main"
mainTab.Font = Enum.Font.GothamBold
mainTab.TextSize = 14
mainTab.TextColor3 = COLOR_TEXT
mainTab.Parent = categoryFrame

local mainTabCorner = Instance.new("UICorner")
mainTabCorner.CornerRadius = UDim.new(0, 8)
mainTabCorner.Parent = mainTab

local adminTab = Instance.new("TextButton")
adminTab.Name = "Tab_Admin"
adminTab.Size = UDim2.new(0, 90, 1, 0)
adminTab.BackgroundColor3 = Color3.fromRGB(45, 30, 60)
adminTab.Text = "Admin"
adminTab.Font = Enum.Font.GothamBold
adminTab.TextSize = 14
adminTab.TextColor3 = COLOR_TEXT
adminTab.Parent = categoryFrame

local adminTabCorner = Instance.new("UICorner")
adminTabCorner.CornerRadius = UDim.new(0, 8)
adminTabCorner.Parent = adminTab

local featureArea = Instance.new("ScrollingFrame")
featureArea.Name = "FeatureArea"
featureArea.Size = UDim2.new(1, -20, 1, -54)
featureArea.Position = UDim2.new(0, 10, 0, 54)
featureArea.BackgroundTransparency = 1
featureArea.BorderSizePixel = 0
featureArea.ScrollBarThickness = 4
featureArea.ScrollBarImageColor3 = COLOR_ACCENT
featureArea.CanvasSize = UDim2.new(0, 0, 0, 0)
featureArea.AutomaticCanvasSize = Enum.AutomaticSize.Y
featureArea.Parent = body

local featureLayout = Instance.new("UIListLayout")
featureLayout.Padding = UDim.new(0, 8)
featureLayout.Parent = featureArea

local function corner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
end

local function makeButton(parent, text, height)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, height or 36)
	b.BackgroundColor3 = COLOR_CARD
	b.Text = text
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 13
	b.TextColor3 = COLOR_TEXT
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b)
	return b
end

local function makeLabel(parent, text, height)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 0, height or 25)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = COLOR_TEXT
	l.Font = Enum.Font.GothamBold
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function makeBox(parent, placeholder, height)
	local b = Instance.new("TextBox")
	b.Size = UDim2.new(1, 0, 0, height or 34)
	b.BackgroundColor3 = Color3.fromRGB(18, 15, 23)
	b.TextColor3 = COLOR_TEXT
	b.PlaceholderColor3 = Color3.fromRGB(110, 100, 125)
	b.PlaceholderText = placeholder
	b.Text = ""
	b.ClearTextOnFocus = false
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = parent
	corner(b)
	return b
end

local mainContent = Instance.new("Frame")
mainContent.Name = "MainContent"
mainContent.Size = UDim2.new(1, 0, 0, 300)
mainContent.BackgroundTransparency = 1
mainContent.Parent = featureArea

local mainLayout = Instance.new("UIListLayout")
mainLayout.Padding = UDim.new(0, 8)
mainLayout.Parent = mainContent

local mapButton = makeButton(mainContent, "MAP  •  Select")
local npcButton = makeButton(mainContent, "NPC / MOB  •  Select")

local mapList = Instance.new("ScrollingFrame")
mapList.Size = UDim2.new(1, 0, 0, 100)
mapList.BackgroundColor3 = Color3.fromRGB(20, 16, 25)
mapList.BorderSizePixel = 0
mapList.ScrollBarThickness = 3
mapList.AutomaticCanvasSize = Enum.AutomaticSize.Y
mapList.CanvasSize = UDim2.new()
mapList.Visible = false
mapList.Parent = mainContent
corner(mapList)

local mapListLayout = Instance.new("UIListLayout")
mapListLayout.Padding = UDim.new(0, 4)
mapListLayout.Parent = mapList

local npcList = Instance.new("ScrollingFrame")
npcList.Size = UDim2.new(1, 0, 0, 100)
npcList.BackgroundColor3 = Color3.fromRGB(20, 16, 25)
npcList.BorderSizePixel = 0
npcList.ScrollBarThickness = 3
npcList.AutomaticCanvasSize = Enum.AutomaticSize.Y
npcList.CanvasSize = UDim2.new()
npcList.Visible = false
npcList.Parent = mainContent
corner(npcList)

local npcListLayout = Instance.new("UIListLayout")
npcListLayout.Padding = UDim.new(0, 4)
npcListLayout.Parent = npcList

local status = makeLabel(mainContent, "Map: -  |  NPC: -", 24)
status.TextColor3 = COLOR_SUBTEXT
status.Font = Enum.Font.Gotham
status.TextSize = 11

local teleportButton = makeButton(mainContent, "TELEPORT", 36)

local farmButton = makeButton(mainContent, "AUTO FARM  •  OFF", 36)

local adminShortcut = makeButton(mainContent, "OPEN ADMIN", 36)

local adminContent = Instance.new("Frame")
adminContent.Name = "AdminContent"
adminContent.Size = UDim2.new(1, 0, 0, 450)
adminContent.BackgroundTransparency = 1
adminContent.Visible = false
adminContent.Parent = featureArea

local adminLayout = Instance.new("UIListLayout")
adminLayout.Padding = UDim.new(0, 7)
adminLayout.Parent = adminContent

makeLabel(adminContent, "MAP MANAGER", 22)

local mapRow = Instance.new("Frame")
mapRow.Size = UDim2.new(1, 0, 0, 34)
mapRow.BackgroundTransparency = 1
mapRow.Parent = adminContent

local mapNameBox = makeBox(mapRow, "Map name", 34)
mapNameBox.Size = UDim2.new(0.60, -4, 1, 0)
mapNameBox.Position = UDim2.new(0, 0, 0, 0)

local mapOrderBox = makeBox(mapRow, "No.", 34)
mapOrderBox.Size = UDim2.new(0.16, -4, 1, 0)
mapOrderBox.Position = UDim2.new(0.62, 0, 0, 0)

local addMapButton = Instance.new("TextButton")
addMapButton.Size = UDim2.new(0.22, 0, 1, 0)
addMapButton.Position = UDim2.new(0.78, 0, 0, 0)
addMapButton.BackgroundColor3 = COLOR_ACCENT
addMapButton.Text = "+ MAP"
addMapButton.TextColor3 = COLOR_TEXT
addMapButton.Font = Enum.Font.GothamBold
addMapButton.TextSize = 11
addMapButton.Parent = mapRow
corner(addMapButton)

makeLabel(adminContent, "NPC / MOB", 22)

local npcRow = Instance.new("Frame")
npcRow.Size = UDim2.new(1, 0, 0, 34)
npcRow.BackgroundTransparency = 1
npcRow.Parent = adminContent

local npcNameBox = makeBox(npcRow, "NPC / Mob name", 34)
npcNameBox.Size = UDim2.new(0.74, -4, 1, 0)
npcNameBox.Position = UDim2.new(0, 0, 0, 0)

local addNPCButton = Instance.new("TextButton")
addNPCButton.Size = UDim2.new(0.24, 0, 1, 0)
addNPCButton.Position = UDim2.new(0.76, 0, 0, 0)
addNPCButton.BackgroundColor3 = COLOR_ACCENT
addNPCButton.Text = "+ NPC"
addNPCButton.TextColor3 = COLOR_TEXT
addNPCButton.Font = Enum.Font.GothamBold
addNPCButton.TextSize = 11
addNPCButton.Parent = npcRow
corner(addNPCButton)

local adminStatus = makeLabel(adminContent, "Map: -  |  NPC: -", 22)
adminStatus.TextColor3 = COLOR_SUBTEXT
adminStatus.Font = Enum.Font.Gotham
adminStatus.TextSize = 10

makeLabel(adminContent, "POSITIONS", 22)

local positionList = Instance.new("ScrollingFrame")
positionList.Size = UDim2.new(1, 0, 0, 160)
positionList.BackgroundColor3 = Color3.fromRGB(20, 16, 25)
positionList.BorderSizePixel = 0
positionList.ScrollBarThickness = 3
positionList.AutomaticCanvasSize = Enum.AutomaticSize.Y
positionList.CanvasSize = UDim2.new()
positionList.Parent = adminContent
corner(positionList)

local positionLayout = Instance.new("UIListLayout")
positionLayout.Padding = UDim.new(0, 5)
positionLayout.Parent = positionList

local addPositionButton = makeButton(adminContent, "+ ADD POSITION", 34)
local saveButton = makeButton(adminContent, "SAVE NPC", 34)
local deleteButton = makeButton(adminContent, "DELETE NPC", 34)

local function clear(container, layout)
	for _, child in ipairs(container:GetChildren()) do
		if child ~= layout then
			child:Destroy()
		end
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
	if not map then
		return nil
	end

	for _, npc in ipairs(map.NPCs) do
		if npc.Name == name then
			return npc
		end
	end
end

local function updateStatus()
	local mapName = selectedMap and selectedMap.Name or "-"
	local npcName = selectedNPC and selectedNPC.Name or "-"

	status.Text = "Map: " .. mapName .. "  |  NPC: " .. npcName
	adminStatus.Text = "Map: " .. mapName .. "  |  NPC: " .. npcName
end

local function refreshMaps()
	clear(mapList, mapListLayout)

	table.sort(DATA.Maps, function(a, b)
		return a.Order < b.Order
	end)

	for _, map in ipairs(DATA.Maps) do
		local b = makeButton(
			mapList,
			tostring(map.Order) .. "  •  " .. map.Name,
			30
		)

		b.MouseButton1Click:Connect(function()
			selectedMap = map
			selectedNPC = nil

			mapButton.Text = "MAP  •  " .. map.Name
			npcButton.Text = "NPC / MOB  •  Select"

			mapList.Visible = false

			refreshNPCs()
			refreshPositions()
			updateStatus()
		end)
	end
end

function refreshNPCs()
	clear(npcList, npcListLayout)

	if not selectedMap then
		return
	end

	for _, npc in ipairs(selectedMap.NPCs) do
		local b = makeButton(npcList, npc.Name, 30)

		b.MouseButton1Click:Connect(function()
			selectedNPC = npc
			npcButton.Text = "NPC / MOB  •  " .. npc.Name
			npcList.Visible = false

			refreshPositions()
			updateStatus()
		end)
	end
end

function refreshPositions()
	clear(positionList, positionLayout)

	if not selectedNPC then
		return
	end

	for index, position in ipairs(selectedNPC.Positions) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 38)
		row.BackgroundColor3 = Color3.fromRGB(30, 25, 38)
		row.BorderSizePixel = 0
		row.Parent = positionList
		corner(row, 6)

		local number = Instance.new("TextLabel")
		number.Size = UDim2.fromOffset(24, 38)
		number.Position = UDim2.fromOffset(3, 0)
		number.BackgroundTransparency = 1
		number.Text = tostring(index)
		number.TextColor3 = COLOR_SUBTEXT
		number.Font = Enum.Font.GothamBold
		number.TextSize = 11
		number.Parent = row

		local input = Instance.new("TextBox")
		input.Size = UDim2.new(1, -65, 0, 28)
		input.Position = UDim2.fromOffset(30, 5)
		input.BackgroundColor3 = Color3.fromRGB(15, 12, 20)
		input.TextColor3 = COLOR_TEXT
		input.Text = string.format(
			"%.3f, %.3f, %.3f",
			position.X,
			position.Y,
			position.Z
		)
		input.Font = Enum.Font.Code
		input.TextSize = 11
		input.ClearTextOnFocus = false
		input.TextXAlignment = Enum.TextXAlignment.Left
		input.Parent = row
		corner(input, 5)

		input.FocusLost:Connect(function()
			local x, y, z = input.Text:match(
				"^%s*([%-+]?[%d%.]+)%s*,%s*([%-+]?[%d%.]+)%s*,%s*([%-+]?[%d%.]+)%s*$"
			)

			x = tonumber(x)
			y = tonumber(y)
			z = tonumber(z)

			if x and y and z then
				selectedNPC.Positions[index] = Vector3.new(x, y, z)

				input.Text = string.format(
					"%.3f, %.3f, %.3f",
					x,
					y,
					z
				)
			end
		end)

		local remove = Instance.new("TextButton")
		remove.Size = UDim2.fromOffset(28, 28)
		remove.Position = UDim2.new(1, -32, 0, 5)
		remove.BackgroundColor3 = Color3.fromRGB(80, 25, 35)
		remove.Text = "×"
		remove.TextColor3 = COLOR_TEXT
		remove.Font = Enum.Font.GothamBold
		remove.TextSize = 15
		remove.Parent = row
		corner(remove, 5)

		remove.MouseButton1Click:Connect(function()
			if selectedNPC then
				table.remove(selectedNPC.Positions, index)
				refreshPositions()
			end
		end)
	end
end

mapButton.MouseButton1Click:Connect(function()
	npcList.Visible = false
	mapList.Visible = not mapList.Visible
end)

npcButton.MouseButton1Click:Connect(function()
	mapList.Visible = false

	if selectedMap then
		npcList.Visible = not npcList.Visible
	end
end)

teleportButton.MouseButton1Click:Connect(function()
	if not selectedNPC then
		return
	end

	local position = selectedNPC.Positions[1]

	if not position then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root then
		root.CFrame = CFrame.new(position)
	end
end)

farmButton.MouseButton1Click:Connect(function()
	farming = not farming

	farmButton.Text = farming
		and "AUTO FARM  •  ON"
		or "AUTO FARM  •  OFF"

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

			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")

			if root then
				root.CFrame = CFrame.new(
					selectedNPC.Positions[index]
				)
			end

			task.wait(0.7)

			index += 1
		end
	end)
end)

addMapButton.MouseButton1Click:Connect(function()
	local name = mapNameBox.Text:match("^%s*(.-)%s*$")
	local order = tonumber(mapOrderBox.Text)

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

	mapNameBox.Text = ""
	mapOrderBox.Text = ""

	refreshMaps()
end)

addNPCButton.MouseButton1Click:Connect(function()
	if not selectedMap then
		return
	end

	local name = npcNameBox.Text:match("^%s*(.-)%s*$")

	if name == "" then
		return
	end

	if findNPC(selectedMap, name) then
		return
	end

	local npc = {
		Name = name,
		Positions = {}
	}

	table.insert(selectedMap.NPCs, npc)

	selectedNPC = npc
	npcNameBox.Text = ""

	npcButton.Text = "NPC / MOB  •  " .. name

	refreshNPCs()
	refreshPositions()
	updateStatus()
end)

addPositionButton.MouseButton1Click:Connect(function()
	if not selectedNPC then
		return
	end

	table.insert(
		selectedNPC.Positions,
		Vector3.new(0, 0, 0)
	)

	refreshPositions()
end)

saveButton.MouseButton1Click:Connect(function()
	if not selectedNPC then
		return
	end

	local rows = {}

	for _, child in ipairs(positionList:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(rows, child)
		end
	end

	table.sort(rows, function(a, b)
		return (a:FindFirstChildWhichIsA("TextLabel").Text or 0)
			< (b:FindFirstChildWhichIsA("TextLabel").Text or 0)
	end)

	local positions = {}

	for _, row in ipairs(rows) do
		local input = row:FindFirstChildWhichIsA("TextBox")

		if input then
			local x, y, z = input.Text:match(
				"^%s*([%-+]?[%d%.]+)%s*,%s*([%-+]?[%d%.]+)%s*,%s*([%-+]?[%d%.]+)%s*$"
			)

			x = tonumber(x)
			y = tonumber(y)
			z = tonumber(z)

			if x and y and z then
				table.insert(
					positions,
					Vector3.new(x, y, z)
				)
			end
		end
	end

	selectedNPC.Positions = positions

	refreshPositions()
end)

deleteButton.MouseButton1Click:Connect(function()
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
	npcButton.Text = "NPC / MOB  •  Select"

	refreshNPCs()
	refreshPositions()
	updateStatus()
end)

local function openMain()
	mainContent.Visible = true
	adminContent.Visible = false

	mainTab.BackgroundColor3 = COLOR_ACCENT
	adminTab.BackgroundColor3 = Color3.fromRGB(45, 30, 60)
end

local function openAdmin()
	mainContent.Visible = false
	adminContent.Visible = true

	mainTab.BackgroundColor3 = Color3.fromRGB(45, 30, 60)
	adminTab.BackgroundColor3 = COLOR_ACCENT

	mapList.Visible = false
	npcList.Visible = false

	refreshPositions()
end

mainTab.MouseButton1Click:Connect(openMain)
adminTab.MouseButton1Click:Connect(openAdmin)
adminBtn.MouseButton1Click:Connect(openAdmin)
adminShortcut.MouseButton1Click:Connect(openAdmin)

local floatBtn = Instance.new("TextButton")
floatBtn.Name = "FloatToggle"
floatBtn.Size = UDim2.new(0, 50, 0, 50)
floatBtn.Position = UDim2.new(0.5, -25, 0.9, -25)
floatBtn.BackgroundColor3 = COLOR_HEADER
floatBtn.Text = "A"
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 20
floatBtn.TextColor3 = COLOR_ACCENT
floatBtn.Visible = false
floatBtn.ZIndex = 10
floatBtn.Parent = screenGui
corner(floatBtn, 25)

local function makeDraggable(frame)
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart

			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(header)
makeDraggable(floatBtn)

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
openMain()
