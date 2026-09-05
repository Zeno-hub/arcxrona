-- LocalScript, taro di StarterGui
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

-- ================= COLORS =================
local COLOR_BG = Color3.fromRGB(15, 15, 20)
local COLOR_HEADER = Color3.fromRGB(35, 15, 60)
local COLOR_ACCENT = Color3.fromRGB(150, 60, 255)
local COLOR_TEXT = Color3.fromRGB(240, 240, 245)
local COLOR_SUBTEXT = Color3.fromRGB(180, 160, 220)

-- ================= ROOT =================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ArcheronGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

-- ================= MAIN CONTAINER =================
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

-- ================= HEADER =================
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = COLOR_HEADER
header.BorderSizePixel = 0
header.ZIndex = 2
header.Parent = main

-- header cuma corner atas yg bulat, bawah lurus (biar nyatu sama body)
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

-- Icon placeholder
local icon = Instance.new("ImageLabel")
icon.Name = "GameIcon"
icon.Size = UDim2.new(0, 40, 0, 40)
icon.Position = UDim2.new(0, 12, 0.5, -20)
icon.BackgroundColor3 = Color3.fromRGB(60, 30, 90)
icon.Image = "" -- taro image id lu di sini
icon.ZIndex = 3
icon.Parent = header

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 8)
iconCorner.Parent = icon

-- Nama Game
local gameName = Instance.new("TextLabel")
gameName.Name = "GameName"
gameName.Size = UDim2.new(1, -170, 0, 22)
gameName.Position = UDim2.new(0, 60, 0, 8)
gameName.BackgroundTransparency = 1
gameName.Text = "Nama Game"
gameName.Font = Enum.Font.GothamBold
gameName.TextSize = 16
gameName.TextColor3 = COLOR_TEXT
gameName.TextXAlignment = Enum.TextXAlignment.Left
gameName.ZIndex = 3
gameName.Parent = header

-- Branding "Archeron"
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

-- Admin Panel Button (gear icon)
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

-- Close Button
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

-- ================= BODY =================
local body = Instance.new("Frame")
body.Name = "Body"
body.Size = UDim2.new(1, 0, 1, -60)
body.Position = UDim2.new(0, 0, 0, 60)
body.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
body.BackgroundTransparency = 0.4
body.BorderSizePixel = 0
body.Parent = main

-- Category Tabs
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

-- Feature Area (scroll)
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

-- contoh tombol fitur (hapus/ganti sesuai kebutuhan)
local function createFeatureButton(name)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(30, 20, 45)
	btn.Text = name
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 14
	btn.TextColor3 = COLOR_TEXT
	btn.Parent = featureArea

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = btn

	return btn
end

createFeatureButton("Fitur 1")
createFeatureButton("Fitur 2")
createFeatureButton("Fitur 3")

-- ================= FLOATING TOGGLE BUTTON =================
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

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(0, 25)
floatCorner.Parent = floatBtn

-- ================= DRAG FUNCTION =================
local UserInputService = game:GetService("UserInputService")

local function makeDraggable(frame)
	local dragging, dragInput, dragStart, startPos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(header) -- drag main lewat header
makeDraggable(floatBtn) -- drag floating button

-- ================= TOGGLE LOGIC =================
closeBtn.MouseButton1Click:Connect(function()
	main.Visible = false
	floatBtn.Visible = true
end)

floatBtn.MouseButton1Click:Connect(function()
	main.Visible = true
	floatBtn.Visible = false
end)

-- ================= ADMIN PANEL PLACEHOLDER =================
adminBtn.MouseButton1Click:Connect(function()
	print("Admin panel dibuka") -- ganti sesuai logic admin panel lu
end)
