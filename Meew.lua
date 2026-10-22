-- ==========================================
-- MEEW-SCRIPT v39 (Binds Update - Fixed)
-- ==========================================

for _, v in pairs(game.CoreGui:GetChildren()) do
    if v.Name:match("PianoAutoPlayer") or v.Name == "MeewScript" then v:Destroy() end
end

local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local TempoValue = 0.140
local HoldTime = 0.02
local isPlaying = false
local stopRequested = false

-- Текущие бинды
local currentPlayBind = Enum.KeyCode.RightShift
local currentGuiBind = Enum.KeyCode.RightControl

-- Список доступных клавиш для переключения
local bindableKeys = {
    Enum.KeyCode.RightShift,
    Enum.KeyCode.RightControl,
    Enum.KeyCode.Insert,
    Enum.KeyCode.Home,
    Enum.KeyCode.Delete,
    Enum.KeyCode.End,
    Enum.KeyCode.Z,
    Enum.KeyCode.X,
    Enum.KeyCode.C,
    Enum.KeyCode.V,
    Enum.KeyCode.B,
    Enum.KeyCode.N,
    Enum.KeyCode.M
}

-- ===== ЦВЕТА =====
local C_BG        = Color3.fromRGB(10, 10, 12)
local C_PANEL     = Color3.fromRGB(18, 18, 22)
local C_BOX       = Color3.fromRGB(8, 8, 10)
local C_ACCENT    = Color3.fromRGB(0, 170, 255)
local C_ACCENT_D  = Color3.fromRGB(0, 120, 200)
local C_TEXT      = Color3.fromRGB(255, 255, 255)
local C_TEXT_DIM  = Color3.fromRGB(140, 140, 150)
local C_BLACK_TXT = Color3.fromRGB(0, 0, 0)
local C_DANGER    = Color3.fromRGB(180, 40, 40)
local C_SIDEBAR   = Color3.fromRGB(14, 14, 18)

-- Цвета для градиентов
local C_GRADIENT_DARK = Color3.fromRGB(0, 40, 80)
local C_RED_GRADIENT  = Color3.fromRGB(20, 0, 0)

-- ===== ПРОЗРАЧНОСТЬ =====
local T_MAIN   = 0.15
local T_PANEL  = 0.25
local T_BOX    = 0.15
local T_SCROLL = 0.25
local T_BTN    = 0.10
local T_ROW    = 0.30
local T_SIDE   = 0.15

-- ===== ФАЙЛОВОЕ ХРАНИЛИЩЕ =====
local SAVE_FOLDER = "PianoAutoPlayer_Notes"
local TXT_FOLDER = "txtpiano"
local HAS_FS = (typeof(writefile) == "function") and (typeof(readfile) == "function") and (typeof(isfile) == "function") and (typeof(listfiles) == "function")
local memoryStore = {}

local function ensureFolders()
    if not HAS_FS then return end
    if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
        if not isfolder(SAVE_FOLDER) then pcall(makefolder, SAVE_FOLDER) end
        if not isfolder(TXT_FOLDER) then pcall(makefolder, TXT_FOLDER) end
    end
end

local function sanitizeName(name)
    return (name:gsub("[^%w_%-%s%.]", ""))
end

local function saveNote(name, text)
    name = sanitizeName(name)
    if name == "" then return false, "Empty name" end
    if HAS_FS then
        ensureFolders()
        local ok, err = pcall(writefile, SAVE_FOLDER .. "/" .. name .. ".txt", text)
        if not ok then return false, tostring(err) end
        return true
    else
        memoryStore[name] = text
        return true
    end
end

local function listNotes()
    local names = {}
    if HAS_FS then
        ensureFolders()
        local ok, files = pcall(listfiles, SAVE_FOLDER)
        if ok and files then
            for _, f in ipairs(files) do
                local n = f:match("([^/\\]+)%.txt$")
                if n then table.insert(names, n) end
            end
        end
    else
        for n in pairs(memoryStore) do table.insert(names, n) end
    end
    table.sort(names)
    return names
end

local function loadNote(name)
    name = sanitizeName(name)
    if HAS_FS then
        local ok, data = pcall(readfile, SAVE_FOLDER .. "/" .. name .. ".txt")
        if ok then return data end
        return nil
    else
        return memoryStore[name]
    end
end

local function deleteNote(name)
    name = sanitizeName(name)
    if HAS_FS then pcall(delfile, SAVE_FOLDER .. "/" .. name .. ".txt")
    else memoryStore[name] = nil end
end

-- ===== ХЕЛПЕРЫ =====
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C_ACCENT_D
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- ===== АНИМИРОВАННЫЕ ГРАДИЕНТЫ =====
local animatedGradients = {}
local animatedStrokes = {}

local function addAnimatedGradient(guiObject)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, C_ACCENT),
        ColorSequenceKeypoint.new(0.5, C_GRADIENT_DARK),
        ColorSequenceKeypoint.new(1.0, C_ACCENT)
    })
    grad.Rotation = 0
    grad.Parent = guiObject
    table.insert(animatedGradients, grad)
    return grad
end

local function addAnimatedRedGradient(guiObject)
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, C_DANGER),
        ColorSequenceKeypoint.new(0.5, C_RED_GRADIENT),
        ColorSequenceKeypoint.new(1.0, C_DANGER)
    })
    grad.Rotation = 0
    grad.Parent = guiObject
    table.insert(animatedGradients, grad)
    return grad
end

local function addAnimatedStroke(guiObject, thickness)
    local s = Instance.new("UIStroke")
    s.Color = C_ACCENT
    s.Thickness = thickness or 2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = guiObject
    
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, C_ACCENT),
        ColorSequenceKeypoint.new(0.5, C_ACCENT_D),
        ColorSequenceKeypoint.new(1.0, C_ACCENT)
    })
    grad.Rotation = 0
    grad.Parent = s
    table.insert(animatedStrokes, grad)
    return s
end

-- Цикл анимации
RunService.RenderStepped:Connect(function()
    local t = tick() * 0.8
    local offset = (math.sin(t) + 1) / 2
    local finalOffset = offset * 2 - 1

    for _, grad in ipairs(animatedGradients) do
        if grad.Parent then
            grad.Offset = Vector2.new(finalOffset, 0)
        end
    end
    
    for _, grad in ipairs(animatedStrokes) do
        if grad.Parent then
            grad.Offset = Vector2.new(finalOffset, 0)
        end
    end
end)

-- ===== GUI =====
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MeewScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

-- ===== GUI M =====
local MiniButton = Instance.new("TextButton")
MiniButton.Size = UDim2.new(0, 44, 0, 44)
MiniButton.Position = UDim2.new(0, 20, 0, 20) 
MiniButton.BackgroundColor3 = C_BG
MiniButton.BackgroundTransparency = 0.1
MiniButton.Text = "M"
MiniButton.TextColor3 = C_ACCENT
MiniButton.Font = Enum.Font.GothamBold
MiniButton.TextSize = 22
MiniButton.BorderSizePixel = 0
MiniButton.Visible = true
MiniButton.Active = true
MiniButton.Draggable = true
MiniButton.Parent = ScreenGui
corner(MiniButton, 8)
addAnimatedStroke(MiniButton, 1.5)
addAnimatedGradient(MiniButton)

-- ===== GUI B =====
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 620, 0, 700)
MainFrame.Position = UDim2.new(0.5, -310, 0.5, -350)
MainFrame.BackgroundColor3 = C_BG
MainFrame.BackgroundTransparency = T_MAIN
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false 
MainFrame.Parent = ScreenGui
corner(MainFrame, 12)
addAnimatedStroke(MainFrame, 2)

-- === ЗАГОЛОВОК ===
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 38)
Title.BackgroundTransparency = 1
Title.Text = "Meew-Script (v39)"
Title.TextColor3 = C_ACCENT
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

-- ===== КНОПКА СВОРАЧИВАНИЯ =====
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -76, 0, 4)
MinimizeBtn.BackgroundColor3 = C_ACCENT
MinimizeBtn.BackgroundTransparency = 0.2
MinimizeBtn.Text = "─"
MinimizeBtn.TextColor3 = C_BLACK_TXT 
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextSize = 18
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = MainFrame 
corner(MinimizeBtn, 6)
addAnimatedGradient(MinimizeBtn)

-- ===== КНОПКА ЗАКРЫТИЯ =====
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 4)
CloseBtn.BackgroundColor3 = C_DANGER
CloseBtn.BackgroundTransparency = 0.2
CloseBtn.Text = "X"
CloseBtn.TextColor3 = C_BLACK_TXT 
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = MainFrame
corner(CloseBtn, 6)
addAnimatedRedGradient(CloseBtn)

-- ===== ЛОГИКА ОТКРЫТИЯ / СВОРАЧИВАНИЯ =====
local isOpen = false

MiniButton.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        MainFrame.Position = UDim2.new(0.5, -310, 0.5, -350)
        MainFrame.Visible = true
    else
        MainFrame.Visible = false
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    isOpen = false
    MainFrame.Visible = false
end)

CloseBtn.MouseButton1Click:Connect(function()
    stopRequested = true
    isPlaying = false
    if ScreenGui then ScreenGui:Destroy() end
    print("Meew-Script closed.")
end)

-- ===== САЙДБАР =====
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 110, 1, -60)
Sidebar.Position = UDim2.new(0, 8, 0, 46)
Sidebar.BackgroundColor3 = C_SIDEBAR
Sidebar.BackgroundTransparency = T_SIDE
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
corner(Sidebar, 10)
stroke(Sidebar, C_ACCENT_D, 1)

local SideLayout = Instance.new("UIListLayout")
SideLayout.Padding = UDim.new(0, 6)
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.Parent = Sidebar

local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 8)
SidePad.PaddingLeft = UDim.new(0, 6)
SidePad.PaddingRight = UDim.new(0, 6)
SidePad.Parent = Sidebar

-- ===== КОНТЕНТ =====
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -134, 1, -68)
Content.Position = UDim2.new(0, 126, 0, 50)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- ===== СИСТЕМА СТРАНИЦ =====
local pages = {}
local sideButtons = {}
local activePage = nil

local function registerPage(name)
    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = Content
    pages[name] = page
    return page
end

local function showPage(name)
    for pname, page in pairs(pages) do
        page.Visible = (pname == name)
    end
    for bname, btn in pairs(sideButtons) do
        if bname == name then
            btn.BackgroundColor3 = C_ACCENT
            btn.BackgroundTransparency = 0.05
            btn.TextColor3 = C_BLACK_TXT 
            if not btn:FindFirstChild("UIGradient") then
                addAnimatedGradient(btn)
            end
        else
            btn.BackgroundColor3 = C_PANEL
            btn.BackgroundTransparency = 0.3
            btn.TextColor3 = C_TEXT_DIM
            local grad = btn:FindFirstChild("UIGradient")
            if grad then grad:Destroy() end
        end
    end
    activePage = name
end

local function addSideButton(name, label, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = C_PANEL
    btn.BackgroundTransparency = 0.3
    btn.Text = label
    btn.TextColor3 = C_TEXT_DIM
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order or 1
    btn.AutoButtonColor = false
    btn.Parent = Sidebar
    corner(btn, 8)
    stroke(btn, C_ACCENT_D, 1)
    
    btn.MouseButton1Click:Connect(function()
        showPage(name)
    end)
    sideButtons[name] = btn
    return btn
end

-- =====================================================================
-- СТРАНИЦА: PLAY
-- =====================================================================
local PlayPage = registerPage("Play")

local NotesScroll = Instance.new("ScrollingFrame")
NotesScroll.Size = UDim2.new(1, 0, 0, 240)
NotesScroll.Position = UDim2.new(0, 0, 0, 0)
NotesScroll.BackgroundColor3 = C_BOX
NotesScroll.BackgroundTransparency = T_BOX
NotesScroll.BorderSizePixel = 0
NotesScroll.ScrollBarThickness = 6
NotesScroll.ScrollBarImageColor3 = C_ACCENT
NotesScroll.ScrollingDirection = Enum.ScrollingDirection.Y
NotesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
NotesScroll.Parent = PlayPage
corner(NotesScroll, 8)
stroke(NotesScroll, C_ACCENT_D, 1)

local NotesContainer = Instance.new("Frame")
NotesContainer.Size = UDim2.new(1, -12, 0, 0)
NotesContainer.Position = UDim2.new(0, 6, 0, 6)
NotesContainer.BackgroundTransparency = 1
NotesContainer.Parent = NotesScroll

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, 0, 1, 0)
TextBox.Position = UDim2.new(0, 0, 0, 0)
TextBox.BackgroundTransparency = 1
TextBox.BorderSizePixel = 0
TextBox.TextColor3 = C_TEXT
TextBox.PlaceholderText = "Paste notes here..."
TextBox.PlaceholderColor3 = C_TEXT_DIM
TextBox.Text = ""
TextBox.TextWrapped = true
TextBox.TextXAlignment = Enum.TextXAlignment.Left
TextBox.TextYAlignment = Enum.TextYAlignment.Top
TextBox.Font = Enum.Font.Code
TextBox.TextSize = 12
TextBox.ClearTextOnFocus = false
TextBox.MultiLine = true
TextBox.Parent = NotesContainer

local function updateTextBoxHeight()
    local h = math.max(TextBox.TextBounds.Y + 16, 100)
    NotesContainer.Size = UDim2.new(1, -12, 0, h)
    TextBox.Size = UDim2.new(1, 0, 0, h)
    NotesScroll.CanvasSize = UDim2.new(0, 0, 0, h + 12)
end

TextBox:GetPropertyChangedSignal("Text"):Connect(updateTextBoxHeight)
task.defer(updateTextBoxHeight)

NotesScroll.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        local newY = NotesScroll.CanvasPosition.Y - input.Position.Z * 25
        NotesScroll.CanvasPosition = Vector2.new(0, math.clamp(newY, 0, NotesScroll.AbsoluteCanvasSize.Y - NotesScroll.AbsoluteSize.Y))
    end
end)

-- ===== ТЕМП =====
local SpeedFrame = Instance.new("Frame")
SpeedFrame.Size = UDim2.new(1, 0, 0, 50)
SpeedFrame.Position = UDim2.new(0, 0, 0, 250)
SpeedFrame.BackgroundColor3 = C_PANEL
SpeedFrame.BackgroundTransparency = T_PANEL
SpeedFrame.BorderSizePixel = 0
SpeedFrame.Parent = PlayPage
corner(SpeedFrame, 8)
stroke(SpeedFrame, C_ACCENT_D, 1)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 20)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "⚡ Tempo (sec): 0.140"
SpeedLabel.TextColor3 = C_ACCENT
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 12
SpeedLabel.Parent = SpeedFrame

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0.25, 0, 0, 25)
MinusBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
MinusBtn.BackgroundColor3 = C_DANGER
MinusBtn.BackgroundTransparency = T_BTN
MinusBtn.Text = "−"
MinusBtn.TextColor3 = C_BLACK_TXT
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 18
MinusBtn.BorderSizePixel = 0
MinusBtn.Parent = SpeedFrame
corner(MinusBtn, 6)
addAnimatedRedGradient(MinusBtn)

local SpeedBox = Instance.new("TextBox")
SpeedBox.Size = UDim2.new(0.35, 0, 0, 25)
SpeedBox.Position = UDim2.new(0.32, 0, 0.45, 0)
SpeedBox.BackgroundColor3 = C_BOX
SpeedBox.BackgroundTransparency = T_BOX
SpeedBox.TextColor3 = C_ACCENT
SpeedBox.Text = string.format("%.3f", TempoValue)
SpeedBox.Font = Enum.Font.Code
SpeedBox.TextSize = 16
SpeedBox.BorderSizePixel = 0
SpeedBox.Parent = SpeedFrame
corner(SpeedBox, 6)
stroke(SpeedBox, C_ACCENT_D, 1)

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0.25, 0, 0, 25)
PlusBtn.Position = UDim2.new(0.70, 0, 0.45, 0)
PlusBtn.BackgroundColor3 = C_ACCENT
PlusBtn.BackgroundTransparency = T_BTN
PlusBtn.Text = "+"
PlusBtn.TextColor3 = C_BLACK_TXT
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 18
PlusBtn.BorderSizePixel = 0
PlusBtn.Parent = SpeedFrame
corner(PlusBtn, 6)
addAnimatedGradient(PlusBtn)

-- Play / Stop
local PlayBtn = Instance.new("TextButton")
PlayBtn.Size = UDim2.new(0.48, 0, 0, 42)
PlayBtn.Position = UDim2.new(0, 0, 0, 310)
PlayBtn.BackgroundColor3 = C_ACCENT
PlayBtn.BackgroundTransparency = T_BTN
PlayBtn.Text = "▶ Play"
PlayBtn.TextColor3 = C_BLACK_TXT
PlayBtn.Font = Enum.Font.GothamBold
PlayBtn.TextSize = 16
PlayBtn.BorderSizePixel = 0
PlayBtn.Parent = PlayPage
corner(PlayBtn, 8)
addAnimatedGradient(PlayBtn) 

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.48, 0, 0, 42)
StopBtn.Position = UDim2.new(0.52, 0, 0, 310)
StopBtn.BackgroundColor3 = C_DANGER
StopBtn.BackgroundTransparency = T_BTN
StopBtn.Text = "■ Stop"
StopBtn.TextColor3 = C_BLACK_TXT
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 16
StopBtn.BorderSizePixel = 0
StopBtn.Parent = PlayPage
corner(StopBtn, 8)
addAnimatedRedGradient(StopBtn)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 18)
Status.Position = UDim2.new(0, 0, 0, 360)
Status.BackgroundTransparency = 1
Status.Text = "Ready to start"
Status.TextColor3 = C_TEXT_DIM
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.Parent = PlayPage

-- =====================================================================
-- СТРАНИЦА: SAVE
-- =====================================================================
local SavePage = registerPage("Save")

local SaveFrame = Instance.new("Frame")
SaveFrame.Size = UDim2.new(1, 0, 1, 0)
SaveFrame.BackgroundColor3 = C_PANEL
SaveFrame.BackgroundTransparency = T_PANEL
SaveFrame.BorderSizePixel = 0
SaveFrame.Parent = SavePage
corner(SaveFrame, 10)
stroke(SaveFrame, C_ACCENT_D, 1)

local SaveTitle = Instance.new("TextLabel")
SaveTitle.Size = UDim2.new(1, 0, 0, 26)
SaveTitle.Position = UDim2.new(0, 0, 0, 6)
SaveTitle.BackgroundTransparency = 1
SaveTitle.Text = "💾 Save Notes"
SaveTitle.TextColor3 = C_ACCENT
SaveTitle.Font = Enum.Font.GothamBold
SaveTitle.TextSize = 15
SaveTitle.Parent = SaveFrame

local NameBox = Instance.new("TextBox")
NameBox.Size = UDim2.new(0.55, 0, 0, 30)
NameBox.Position = UDim2.new(0.03, 0, 0, 40)
NameBox.BackgroundColor3 = C_BOX
NameBox.BackgroundTransparency = T_BOX
NameBox.TextColor3 = C_TEXT
NameBox.PlaceholderText = "Notes name..."
NameBox.PlaceholderColor3 = C_TEXT_DIM
NameBox.Text = ""
NameBox.Font = Enum.Font.Gotham
NameBox.TextSize = 13
NameBox.ClearTextOnFocus = false
NameBox.BorderSizePixel = 0
NameBox.Parent = SaveFrame
corner(NameBox, 6)
stroke(NameBox, C_ACCENT_D, 1)

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0.37, 0, 0, 30)
SaveBtn.Position = UDim2.new(0.60, 0, 0, 40)
SaveBtn.BackgroundColor3 = C_ACCENT
SaveBtn.BackgroundTransparency = T_BTN
SaveBtn.Text = "💾 Save"
SaveBtn.TextColor3 = C_BLACK_TXT
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 13
SaveBtn.BorderSizePixel = 0
SaveBtn.Parent = SaveFrame
corner(SaveBtn, 6)
addAnimatedGradient(SaveBtn)

local SaveStatus = Instance.new("TextLabel")
SaveStatus.Size = UDim2.new(1, 0, 0, 16)
SaveStatus.Position = UDim2.new(0, 0, 0, 74)
SaveStatus.BackgroundTransparency = 1
SaveStatus.Text = ""
SaveStatus.TextColor3 = C_TEXT_DIM
SaveStatus.Font = Enum.Font.Gotham
SaveStatus.TextSize = 11
SaveStatus.Parent = SaveFrame

local ListLabel = Instance.new("TextLabel")
ListLabel.Size = UDim2.new(1, 0, 0, 18)
ListLabel.Position = UDim2.new(0, 0, 0, 96)
ListLabel.BackgroundTransparency = 1
ListLabel.Text = "📁 Saved Notes:"
ListLabel.TextColor3 = C_ACCENT
ListLabel.TextXAlignment = Enum.TextXAlignment.Left
ListLabel.Font = Enum.Font.GothamBold
ListLabel.TextSize = 12
ListLabel.Parent = SaveFrame

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(0.94, 0, 1, -130)
Scroll.Position = UDim2.new(0.03, 0, 0, 118)
Scroll.BackgroundColor3 = C_BOX
Scroll.BackgroundTransparency = T_SCROLL
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 5
Scroll.ScrollBarImageColor3 = C_ACCENT
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = SaveFrame
corner(Scroll, 6)

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = Scroll

local function setSaveStatus(txt, ok)
    SaveStatus.Text = txt
    SaveStatus.TextColor3 = ok and C_ACCENT or Color3.fromRGB(255, 100, 100)
    task.delay(3, function()
        if SaveStatus.Text == txt then SaveStatus.Text = "" end
    end)
end

local function refreshList()
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") or child:IsA("TextLabel") then
            if not child:IsA("UIListLayout") then child:Destroy() end
        end
    end
    local names = listNotes()
    if #names == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "(empty — save something)"
        empty.TextColor3 = C_TEXT_DIM
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.Parent = Scroll
        return
    end
    for i, name in ipairs(names) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 34)
        row.BackgroundColor3 = C_PANEL
        row.BackgroundTransparency = T_ROW
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = Scroll
        corner(row, 6)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.66, 0, 1, 0)
        nameLbl.Position = UDim2.new(0, 8, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = name
        nameLbl.TextColor3 = C_TEXT
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextSize = 13
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row

        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0.13, 0, 0, 26)
        loadBtn.Position = UDim2.new(0.68, 0, 0, 4)
        loadBtn.BackgroundColor3 = C_ACCENT
        loadBtn.BackgroundTransparency = T_BTN
        loadBtn.Text = "📂"
        loadBtn.TextColor3 = C_BLACK_TXT
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 13
        loadBtn.BorderSizePixel = 0
        loadBtn.Parent = row
        corner(loadBtn, 5)
        addAnimatedGradient(loadBtn)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0.13, 0, 0, 26)
        delBtn.Position = UDim2.new(0.83, 0, 0, 4)
        delBtn.BackgroundColor3 = C_DANGER
        delBtn.BackgroundTransparency = T_BTN
        delBtn.Text = "🗑"
        delBtn.TextColor3 = C_BLACK_TXT
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 13
        delBtn.BorderSizePixel = 0
        delBtn.Parent = row
        corner(delBtn, 5)
        addAnimatedRedGradient(delBtn)

        loadBtn.MouseButton1Click:Connect(function()
            local data = loadNote(name)
            if data then
                TextBox.Text = data
                task.defer(updateTextBoxHeight)
                showPage("Play")
                Status.Text = "📂 Loaded: " .. name
            else
                setSaveStatus("Failed to load", false)
            end
        end)

        delBtn.MouseButton1Click:Connect(function()
            deleteNote(name)
            setSaveStatus("Deleted: " .. name, true)
            refreshList()
        end)
    end
end

SaveBtn.MouseButton1Click:Connect(function()
    local name = NameBox.Text
    if name:gsub("%s", "") == "" then
        setSaveStatus("Enter a name!", false)
        return
    end
    local ok, err = saveNote(name, TextBox.Text)
    if ok then
        setSaveStatus("Saved: " .. sanitizeName(name), true)
        NameBox.Text = ""
        refreshList()
    else
        setSaveStatus("Error: " .. tostring(err), false)
    end
end)

-- =====================================================================
-- СТРАНИЦА: ADD (Авто-загрузка TXT)
-- =====================================================================
local AddPage = registerPage("Add")

local AddFrame = Instance.new("Frame")
AddFrame.Size = UDim2.new(1, 0, 1, 0)
AddFrame.BackgroundColor3 = C_PANEL
AddFrame.BackgroundTransparency = T_PANEL
AddFrame.BorderSizePixel = 0
AddFrame.Parent = AddPage
corner(AddFrame, 10)
stroke(AddFrame, C_ACCENT_D, 1)

-- Заголовок
local AddTitle = Instance.new("TextLabel")
AddTitle.Size = UDim2.new(1, 0, 0, 26)
AddTitle.Position = UDim2.new(0, 0, 0, 6)
AddTitle.BackgroundTransparency = 1
AddTitle.Text = "📂 " .. TXT_FOLDER .. " Folder"
AddTitle.TextColor3 = C_ACCENT
AddTitle.Font = Enum.Font.GothamBold
AddTitle.TextSize = 15
AddTitle.Parent = AddFrame

-- Кнопка обновления
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0.3, 0, 0, 24)
RefreshBtn.Position = UDim2.new(0.67, 0, 0, 4)
RefreshBtn.BackgroundColor3 = C_ACCENT
RefreshBtn.BackgroundTransparency = T_BTN
RefreshBtn.Text = "↻ Refresh"
RefreshBtn.TextColor3 = C_BLACK_TXT
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 11
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Parent = AddFrame
corner(RefreshBtn, 4)
addAnimatedGradient(RefreshBtn)

-- ОПИСАНИЕ
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -12, 0, 46)
InfoLabel.Position = UDim2.new(0.03, 0, 0, 35)
InfoLabel.BackgroundColor3 = C_BOX
InfoLabel.BackgroundTransparency = 0.3
InfoLabel.Text = "Где брать файлы?\nСоздай папку 'txtpiano' в папке 'workspace' твоего экзекутора и закинь туда txt файлы с нотами."
InfoLabel.TextColor3 = C_TEXT_DIM
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextSize = 11
InfoLabel.TextWrapped = true
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = AddFrame
corner(InfoLabel, 6)
stroke(InfoLabel, C_ACCENT_D, 0.5)

-- Внутренние отступы
local InfoPad = Instance.new("UIPadding")
InfoPad.PaddingTop = UDim.new(0, 6)
InfoPad.PaddingLeft = UDim.new(0, 8)
InfoPad.PaddingRight = UDim.new(0, 8)
InfoPad.Parent = InfoLabel

-- Скролл для списка файлов
local TxtScroll = Instance.new("ScrollingFrame")
TxtScroll.Size = UDim2.new(0.94, 0, 1, -115)
TxtScroll.Position = UDim2.new(0.03, 0, 0, 88)
TxtScroll.BackgroundColor3 = C_BOX
TxtScroll.BackgroundTransparency = T_SCROLL
TxtScroll.BorderSizePixel = 0
TxtScroll.ScrollBarThickness = 5
TxtScroll.ScrollBarImageColor3 = C_ACCENT
TxtScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
TxtScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
TxtScroll.Parent = AddFrame
corner(TxtScroll, 6)

local TxtListLayout = Instance.new("UIListLayout")
TxtListLayout.Padding = UDim.new(0, 4)
TxtListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TxtListLayout.Parent = TxtScroll

local function refreshTxtFiles()
    for _, child in ipairs(TxtScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    
    if not HAS_FS then
        local err = Instance.new("TextLabel")
        err.Size = UDim2.new(1, 0, 0, 30)
        err.BackgroundTransparency = 1
        err.Text = "FS not supported!"
        err.TextColor3 = C_DANGER
        err.Font = Enum.Font.Gotham
        err.TextSize = 12
        err.Parent = TxtScroll
        return
    end
    
    ensureFolders()
    local ok, files = pcall(listfiles, TXT_FOLDER)
    local txtFiles = {}
    
    if ok and files then
        for _, f in ipairs(files) do
            local n = f:match("([^/\\]+)%.txt$")
            if n then table.insert(txtFiles, n) end
        end
    end
    
    if #txtFiles == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 30)
        empty.BackgroundTransparency = 1
        empty.Text = "(no .txt files found in folder)"
        empty.TextColor3 = C_TEXT_DIM
        empty.Font = Enum.Font.Gotham
        empty.TextSize = 12
        empty.Parent = TxtScroll
        
        task.spawn(function()
            task.wait(2)
            if empty and empty.Parent then
                local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                local tween = TweenService:Create(empty, tweenInfo, {TextTransparency = 1})
                tween:Play()
                tween.Completed:Wait()
                if empty then empty:Destroy() end
            end
        end)
        return
    end
    
    table.sort(txtFiles)
    
    for i, name in ipairs(txtFiles) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -6, 0, 34)
        row.BackgroundColor3 = C_PANEL
        row.BackgroundTransparency = T_ROW
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = TxtScroll
        corner(row, 6)
        
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.7, 0, 1, 0)
        nameLbl.Position = UDim2.new(0, 8, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = name .. ".txt"
        nameLbl.TextColor3 = C_TEXT
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.Font = Enum.Font.Gotham
        nameLbl.TextSize = 13
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row
        
        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0.2, 0, 0, 26)
        loadBtn.Position = UDim2.new(0.77, 0, 0, 4)
        loadBtn.BackgroundColor3 = C_ACCENT
        loadBtn.BackgroundTransparency = T_BTN
        loadBtn.Text = "Load"
        loadBtn.TextColor3 = C_BLACK_TXT
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 13
        loadBtn.BorderSizePixel = 0
        loadBtn.Parent = row
        corner(loadBtn, 5)
        addAnimatedGradient(loadBtn)
        
        loadBtn.MouseButton1Click:Connect(function()
            local path = TXT_FOLDER .. "/" .. name .. ".txt"
            local success, content = pcall(readfile, path)
            if success and content then
                TextBox.Text = content
                task.defer(updateTextBoxHeight)
                showPage("Play")
                Status.Text = "✅ Loaded: " .. name
            else
                Status.Text = "❌ Error loading " .. name
            end
        end)
    end
end

RefreshBtn.MouseButton1Click:Connect(refreshTxtFiles)

-- =====================================================================
-- СТРАНИЦА: ADDITIONALLY
-- =====================================================================
local AddlPage = registerPage("Additionally")

local AddlFrame = Instance.new("Frame")
AddlFrame.Size = UDim2.new(1, 0, 1, 0)
AddlFrame.BackgroundColor3 = C_PANEL
AddlFrame.BackgroundTransparency = T_PANEL
AddlFrame.BorderSizePixel = 0
AddlFrame.Parent = AddlPage
corner(AddlFrame, 10)
stroke(AddlFrame, C_ACCENT_D, 1)

local AddlTitle = Instance.new("TextLabel")
AddlTitle.Size = UDim2.new(1, 0, 0, 30)
AddlTitle.Position = UDim2.new(0, 0, 0, 10)
AddlTitle.BackgroundTransparency = 1
AddlTitle.Text = "⚙️ Additionally (Scripts)"
AddlTitle.TextColor3 = C_ACCENT
AddlTitle.Font = Enum.Font.GothamBold
AddlTitle.TextSize = 16
AddlTitle.Parent = AddlFrame

local InfBtn = Instance.new("TextButton")
InfBtn.Size = UDim2.new(0.9, 0, 0, 50)
InfBtn.Position = UDim2.new(0.05, 0, 0, 60)
InfBtn.BackgroundColor3 = C_ACCENT
InfBtn.BackgroundTransparency = 0.1
InfBtn.Text = "Infinity"
InfBtn.TextColor3 = C_BLACK_TXT
InfBtn.Font = Enum.Font.GothamBold
InfBtn.TextSize = 18
InfBtn.BorderSizePixel = 0
InfBtn.Parent = AddlFrame
corner(InfBtn, 8)
addAnimatedGradient(InfBtn)

local EmoteBtn = Instance.new("TextButton")
EmoteBtn.Size = UDim2.new(0.9, 0, 0, 50)
EmoteBtn.Position = UDim2.new(0.05, 0, 0, 125)
EmoteBtn.BackgroundColor3 = C_ACCENT
EmoteBtn.BackgroundTransparency = 0.1
EmoteBtn.Text = "Emotes"
EmoteBtn.TextColor3 = C_BLACK_TXT
EmoteBtn.Font = Enum.Font.GothamBold
EmoteBtn.TextSize = 18
EmoteBtn.BorderSizePixel = 0
EmoteBtn.Parent = AddlFrame
corner(EmoteBtn, 8)
addAnimatedGradient(EmoteBtn)

local LoadStatus = Instance.new("TextLabel")
LoadStatus.Size = UDim2.new(0.9, 0, 0, 20)
LoadStatus.Position = UDim2.new(0.05, 0, 0, 190)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = ""
LoadStatus.TextColor3 = C_ACCENT
LoadStatus.Font = Enum.Font.Gotham
LoadStatus.TextSize = 12
LoadStatus.Parent = AddlFrame

InfBtn.MouseButton1Click:Connect(function()
    LoadStatus.Text = "Loading Infinity..."
    local success, err = pcall(function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end)
    if success then
        LoadStatus.Text = "✅ Infinity Loaded"
    else
        LoadStatus.Text = "❌ Error loading Infinity"
        warn(err)
    end
end)

EmoteBtn.MouseButton1Click:Connect(function()
    LoadStatus.Text = "Loading Emotes..."
    local success, err = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Emotes.lua"))()
    end)
    if success then
        LoadStatus.Text = "✅ Emotes Loaded"
    else
        LoadStatus.Text = "❌ Error loading Emotes"
        warn(err)
    end
end)

-- =====================================================================
-- СТРАНИЦА: BINDS
-- =====================================================================
local BindsPage = registerPage("Binds")

local BindsFrame = Instance.new("Frame")
BindsFrame.Size = UDim2.new(1, 0, 1, 0)
BindsFrame.BackgroundColor3 = C_PANEL
BindsFrame.BackgroundTransparency = T_PANEL
BindsFrame.BorderSizePixel = 0
BindsFrame.Parent = BindsPage
corner(BindsFrame, 10)
stroke(BindsFrame, C_ACCENT_D, 1)

local BindsTitle = Instance.new("TextLabel")
BindsTitle.Size = UDim2.new(1, 0, 0, 30)
BindsTitle.Position = UDim2.new(0, 0, 0, 10)
BindsTitle.BackgroundTransparency = 1
BindsTitle.Text = "⌨️ Binds"
BindsTitle.TextColor3 = C_ACCENT
BindsTitle.Font = Enum.Font.GothamBold
BindsTitle.TextSize = 16
BindsTitle.Parent = BindsFrame

-- --- БИНД НА PLAY/STOP ---
local PlayBindBtn = Instance.new("TextButton")
PlayBindBtn.Size = UDim2.new(0.9, 0, 0, 45)
PlayBindBtn.Position = UDim2.new(0.05, 0, 0, 50)
PlayBindBtn.BackgroundColor3 = C_BOX
PlayBindBtn.BackgroundTransparency = 0.2
PlayBindBtn.Text = "▶ Toggle Play/Stop: " .. tostring(currentPlayBind.Name)
PlayBindBtn.TextColor3 = C_TEXT
PlayBindBtn.Font = Enum.Font.GothamBold
PlayBindBtn.TextSize = 15
PlayBindBtn.BorderSizePixel = 0
PlayBindBtn.Parent = BindsFrame
corner(PlayBindBtn, 6)
stroke(PlayBindBtn, C_ACCENT_D, 1)

-- --- БИНД НА GUI ---
local GuiBindBtn = Instance.new("TextButton")
GuiBindBtn.Size = UDim2.new(0.9, 0, 0, 45)
GuiBindBtn.Position = UDim2.new(0.05, 0, 0, 110)
GuiBindBtn.BackgroundColor3 = C_BOX
GuiBindBtn.BackgroundTransparency = 0.2
GuiBindBtn.Text = "🖥 Toggle GUI: " .. tostring(currentGuiBind.Name)
GuiBindBtn.TextColor3 = C_TEXT
GuiBindBtn.Font = Enum.Font.GothamBold
GuiBindBtn.TextSize = 15
GuiBindBtn.BorderSizePixel = 0
GuiBindBtn.Parent = BindsFrame
corner(GuiBindBtn, 6)
stroke(GuiBindBtn, C_ACCENT_D, 1)

local BindHint = Instance.new("TextLabel")
BindHint.Size = UDim2.new(0.9, 0, 0, 30)
BindHint.Position = UDim2.new(0.05, 0, 0, 170)
BindHint.BackgroundTransparency = 1
BindHint.Text = "Click the buttons above to change the bind."
BindHint.TextColor3 = C_TEXT_DIM
BindHint.Font = Enum.Font.Gotham
BindHint.TextSize = 11
BindHint.TextWrapped = true
BindHint.Parent = BindsFrame

-- Логика смены биндов по клику
local playKeyIndex = 1
local guiKeyIndex = 2

PlayBindBtn.MouseButton1Click:Connect(function()
    playKeyIndex = playKeyIndex + 1
    if playKeyIndex > #bindableKeys then playKeyIndex = 1 end
    currentPlayBind = bindableKeys[playKeyIndex]
    PlayBindBtn.Text = "▶ Toggle Play/Stop: " .. tostring(currentPlayBind.Name)
end)

GuiBindBtn.MouseButton1Click:Connect(function()
    guiKeyIndex = guiKeyIndex + 1
    if guiKeyIndex > #bindableKeys then guiKeyIndex = 1 end
    currentGuiBind = bindableKeys[guiKeyIndex]
    GuiBindBtn.Text = "🖥 Toggle GUI: " .. tostring(currentGuiBind.Name)
end)

-- ===== ЛОГИКА ПЛЕЕРА =====
local function updateSpeedDisplay()
    SpeedBox.Text = string.format("%.3f", TempoValue)
    SpeedLabel.Text = "⚡ Tempo (sec): " .. SpeedBox.Text
end

MinusBtn.MouseButton1Click:Connect(function()
    TempoValue = math.clamp(TempoValue + 0.01, 0.02, 0.50); updateSpeedDisplay()
end)
PlusBtn.MouseButton1Click:Connect(function()
    TempoValue = math.clamp(TempoValue - 0.01, 0.02, 0.50); updateSpeedDisplay()
end)
SpeedBox.FocusLost:Connect(function()
    local v = tonumber(SpeedBox.Text)
    if v then TempoValue = math.clamp(v, 0.01, 0.50) end
    updateSpeedDisplay()
end)

local function charToKey(char)
    local upper = string.upper(char)
    local shift = (char ~= upper) and (char:match("%a") ~= nil)
    local map = {
        A=Enum.KeyCode.A,B=Enum.KeyCode.B,C=Enum.KeyCode.C,D=Enum.KeyCode.D,E=Enum.KeyCode.E,
        F=Enum.KeyCode.F,G=Enum.KeyCode.G,H=Enum.KeyCode.H,I=Enum.KeyCode.I,J=Enum.KeyCode.J,
        K=Enum.KeyCode.K,L=Enum.KeyCode.L,M=Enum.KeyCode.M,N=Enum.KeyCode.N,O=Enum.KeyCode.O,
        P=Enum.KeyCode.P,Q=Enum.KeyCode.Q,R=Enum.KeyCode.R,S=Enum.KeyCode.S,T=Enum.KeyCode.T,
        U=Enum.KeyCode.U,V=Enum.KeyCode.V,W=Enum.KeyCode.W,X=Enum.KeyCode.X,Y=Enum.KeyCode.Y,
        Z=Enum.KeyCode.Z,
        ["0"]=Enum.KeyCode.Zero,["1"]=Enum.KeyCode.One,["2"]=Enum.KeyCode.Two,
        ["3"]=Enum.KeyCode.Three,["4"]=Enum.KeyCode.Four,["5"]=Enum.KeyCode.Five,
        ["6"]=Enum.KeyCode.Six,["7"]=Enum.KeyCode.Seven,["8"]=Enum.KeyCode.Eight,
        ["9"]=Enum.KeyCode.Nine,
    }
    return map[upper], shift
end

local function pressKey(char)
    local keyCode, shift = charToKey(char)
    if not keyCode then return end
    if shift then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end
    VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
    task.wait(HoldTime)
    VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    if shift then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end
end

local function pressChord(chars)
    local keyCodes, shifts = {}, {}
    for _, c in ipairs(chars) do
        local kc, sh = charToKey(c)
        if kc then table.insert(keyCodes, kc); table.insert(shifts, sh) end
    end
    if #keyCodes == 0 then return end
    for i, kc in ipairs(keyCodes) do
        if shifts[i] then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game) end
        VirtualInputManager:SendKeyEvent(true, kc, false, game)
    end
    task.wait(HoldTime + 0.01)
    for i, kc in ipairs(keyCodes) do
        VirtualInputManager:SendKeyEvent(false, kc, false, game)
        if shifts[i] then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game) end
    end
end

local function parseNotes(str)
    local tokens, i, len = {}, 1, #str
    while i <= len do
        local c = string.sub(str, i, i)
        if c == "[" then
            local close = string.find(str, "]", i, true)
            if close then
                local inside = string.sub(str, i + 1, close - 1):gsub("%s", "")
                local chars = {}
                for ch in inside:gmatch(".") do table.insert(chars, ch) end
                table.insert(tokens, {type = "chord", chars = chars})
                i = close + 1
            else
                table.insert(tokens, {type = "note", char = c}); i = i + 1
            end
        elseif c == "-" or c == "_" then
            table.insert(tokens, {type = "pause"}); i = i + 1
        elseif c == " " or c == "\n" or c == "\r" or c == "\t" or c == "|" then
            i = i + 1
        else
            table.insert(tokens, {type = "note", char = c}); i = i + 1
        end
    end
    return tokens
end

local function playNotes()
    local tokens = parseNotes(TextBox.Text)
    if #tokens == 0 then return end
    isPlaying = true; stopRequested = false
    Status.Text = "🎵 Playing... (" .. #tokens .. " notes)"
    for _, token in ipairs(tokens) do
        if stopRequested then break end
        if token.type == "note" then
            pressKey(token.char); task.wait(TempoValue)
        elseif token.type == "chord" then
            pressChord(token.chars); task.wait(TempoValue)
        elseif token.type == "pause" then
            task.wait(TempoValue * 1.5)
        end
    end
    isPlaying = false
    Status.Text = "✅ Done"
end

local function stopPlayer()
    stopRequested = true
    isPlaying = false
    Status.Text = "⏹ Stopped"
end

PlayBtn.MouseButton1Click:Connect(function()
    if not isPlaying then task.spawn(playNotes) end
end)

StopBtn.MouseButton1Click:Connect(function()
    stopPlayer()
end)

-- ===== СИСТЕМА БИНДОВ =====
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    -- Бинд на Play/Stop
    if input.KeyCode == currentPlayBind then
        if isPlaying then
            stopPlayer()
        else
            task.spawn(playNotes)
        end
    end
    
    -- Бинд на открытие/закрытие GUI
    if input.KeyCode == currentGuiBind then
        isOpen = not isOpen
        if isOpen then
            MainFrame.Position = UDim2.new(0.5, -310, 0.5, -350)
            MainFrame.Visible = true
        else
            MainFrame.Visible = false
        end
    end
end)

-- =====================================================================
-- РЕГИСТРАЦИЯ КНОПОК САЙДБАРА
-- =====================================================================
addSideButton("Play", "🎵 Play", 1)
addSideButton("Save", "💾 Save", 2)
addSideButton("Add", "📂 Add", 3)
addSideButton("Additionally", "⚙️ Additionally", 4)
addSideButton("Binds", "⌨️ Binds", 5)

-- =====================================================================
ensureFolders()
refreshList()
refreshTxtFiles()
showPage("Play")
task.wait(0.1)
updateTextBoxHeight()
print("Meew-Script v39 (Binds Update - Fixed) loaded! FS:", HAS_FS)
