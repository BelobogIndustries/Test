--[[
    Aether UI Library
    Version: 1.0.0
    License: MIT

    A modern, animated, themeable UI library for Roblox.
      - Auto-detects mobile vs PC and reflows the layout
      - Smooth tween-based animations everywhere
      - 5 built-in themes + per-color overrides + live theme switching
      - Config save/load (writefile/readfile based)
      - QoL: tooltips, watermark, notifications, prompts, search, tab keybind,
        transparency slider, click sounds, hover scale, context close button

    Usage:
        local Library = loadstring(game:HttpGet('YOUR_RAW_URL'))()
        local Window = Library:CreateWindow({...})
        local Tab = Window:CreateTab({...})
        local Section = Tab:CreateSection("Player")
        Section:CreateToggle("Enabled", false, function(v) end)

    See README.md for full documentation.
]]

--================================================================
-- Services
--================================================================
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local CoreGui            = game:GetService("CoreGui")
local HttpService        = game:GetService("HttpService")

--================================================================
-- Compatibility shims (defensive against sandboxed/old executors)
--================================================================
-- task library (added to Roblox in 2020; some executors lack it)
local _task = task
if not _task then
    _task = {}
    _task.delay = function(t, f) delay(t, f) end
    _task.spawn = function(f) spawn(f) end
    _task.wait  = function(t) return wait(t) end
end

-- safe property setter (for properties that may not exist in all environments)
local function safeSet(obj, prop, val)
    pcall(function() obj[prop] = val end)
end

--================================================================
-- Constants & Platform Detection
--================================================================
local EASE       = Enum.EasingStyle.Quint
local DIR        = Enum.EasingDirection.Out
local T          = 0.18
local T_FAST     = 0.10
local T_SLOW     = 0.30
local Player     = Players.LocalPlayer
local IsMobile   = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)

local CLICK_SOUND_ID = "rbxassetid://6895086663"

--================================================================
-- Themes
--================================================================
local Themes = {
    Midnight = {
        Background       = Color3.fromRGB(18, 20, 28),
        Surface          = Color3.fromRGB(26, 28, 38),
        SurfaceHover     = Color3.fromRGB(34, 37, 50),
        Sidebar          = Color3.fromRGB(22, 24, 34),
        Element          = Color3.fromRGB(30, 33, 46),
        ElementHover     = Color3.fromRGB(40, 44, 60),
        Accent           = Color3.fromRGB(124, 134, 255),
        AccentText       = Color3.fromRGB(255, 255, 255),
        Text             = Color3.fromRGB(238, 240, 248),
        TextMuted        = Color3.fromRGB(150, 156, 175),
        Stroke           = Color3.fromRGB(48, 52, 70),
        StrokeStrong     = Color3.fromRGB(70, 75, 100),
        Notification     = Color3.fromRGB(30, 33, 46),
        TabActive        = Color3.fromRGB(34, 37, 52),
        Overlay          = Color3.fromRGB(0, 0, 0),
    },
    Aurora = {
        Background       = Color3.fromRGB(15, 18, 26),
        Surface          = Color3.fromRGB(22, 26, 36),
        SurfaceHover     = Color3.fromRGB(30, 36, 50),
        Sidebar          = Color3.fromRGB(18, 22, 32),
        Element          = Color3.fromRGB(26, 30, 42),
        ElementHover     = Color3.fromRGB(36, 42, 58),
        Accent           = Color3.fromRGB(94, 234, 212),
        AccentText       = Color3.fromRGB(10, 30, 28),
        Text             = Color3.fromRGB(236, 240, 246),
        TextMuted        = Color3.fromRGB(140, 150, 170),
        Stroke           = Color3.fromRGB(44, 50, 68),
        StrokeStrong     = Color3.fromRGB(64, 72, 96),
        Notification     = Color3.fromRGB(26, 30, 42),
        TabActive        = Color3.fromRGB(30, 36, 50),
        Overlay          = Color3.fromRGB(0, 0, 0),
    },
    Carbon = {
        Background       = Color3.fromRGB(12, 12, 12),
        Surface          = Color3.fromRGB(20, 20, 20),
        SurfaceHover     = Color3.fromRGB(28, 28, 28),
        Sidebar          = Color3.fromRGB(16, 16, 16),
        Element          = Color3.fromRGB(22, 22, 22),
        ElementHover     = Color3.fromRGB(30, 30, 30),
        Accent           = Color3.fromRGB(255, 255, 255),
        AccentText       = Color3.fromRGB(0, 0, 0),
        Text             = Color3.fromRGB(240, 240, 240),
        TextMuted        = Color3.fromRGB(140, 140, 140),
        Stroke           = Color3.fromRGB(38, 38, 38),
        StrokeStrong     = Color3.fromRGB(58, 58, 58),
        Notification     = Color3.fromRGB(22, 22, 22),
        TabActive        = Color3.fromRGB(28, 28, 28),
        Overlay          = Color3.fromRGB(0, 0, 0),
    },
    Crimson = {
        Background       = Color3.fromRGB(26, 16, 18),
        Surface          = Color3.fromRGB(36, 22, 24),
        SurfaceHover     = Color3.fromRGB(48, 30, 32),
        Sidebar          = Color3.fromRGB(30, 18, 20),
        Element          = Color3.fromRGB(40, 24, 26),
        ElementHover     = Color3.fromRGB(52, 32, 34),
        Accent           = Color3.fromRGB(255, 92, 110),
        AccentText       = Color3.fromRGB(255, 255, 255),
        Text             = Color3.fromRGB(244, 232, 234),
        TextMuted        = Color3.fromRGB(170, 140, 144),
        Stroke           = Color3.fromRGB(64, 36, 38),
        StrokeStrong     = Color3.fromRGB(90, 50, 52),
        Notification     = Color3.fromRGB(40, 24, 26),
        TabActive        = Color3.fromRGB(48, 30, 32),
        Overlay          = Color3.fromRGB(0, 0, 0),
    },
    Mint = {
        Background       = Color3.fromRGB(16, 24, 20),
        Surface          = Color3.fromRGB(22, 34, 28),
        SurfaceHover     = Color3.fromRGB(30, 46, 38),
        Sidebar          = Color3.fromRGB(18, 28, 24),
        Element          = Color3.fromRGB(26, 40, 32),
        ElementHover     = Color3.fromRGB(34, 52, 42),
        Accent           = Color3.fromRGB(110, 230, 140),
        AccentText       = Color3.fromRGB(8, 24, 12),
        Text             = Color3.fromRGB(236, 244, 240),
        TextMuted        = Color3.fromRGB(140, 168, 152),
        Stroke           = Color3.fromRGB(44, 64, 52),
        StrokeStrong     = Color3.fromRGB(64, 92, 74),
        Notification     = Color3.fromRGB(26, 40, 32),
        TabActive        = Color3.fromRGB(30, 46, 38),
        Overlay          = Color3.fromRGB(0, 0, 0),
    },
}

--================================================================
-- Utilities
--================================================================
local function tween(obj, time, props)
    local info = TweenInfo.new(time or T, EASE, DIR)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = parent
    return s
end

local function padding(parent, left, top, right, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, left)
    p.PaddingTop    = UDim.new(0, top)
    p.PaddingRight  = UDim.new(0, right or left)
    p.PaddingBottom = UDim.new(0, bottom or top)
    p.Parent = parent
    return p
end

local function playClick(volume)
    local snd = Instance.new("Sound")
    snd.SoundId = CLICK_SOUND_ID
    snd.Volume = volume or 0.25
    snd.PlayOnRemove = true
    snd.Parent = workspace
    snd:Play()
    game:GetService("Debris"):AddItem(snd, 2)
end

local function safeWrite(path, content)
    pcall(function() writefile(path, content) end)
end
local function safeRead(path)
    local ok, content = pcall(function() return readfile(path) end)
    if ok and content then return content end
    return nil
end
local function safeList(folder)
    local ok, files = pcall(function() return listfiles(folder) end)
    if ok and files then return files end
    return {}
end
local function safeDelete(path)
    pcall(function() delfile(path) end)
end
local function safeMakeFolder(folder)
    pcall(function() makefolder(folder) end)
end

local function round(n, decimals)
    local m = 10 ^ (decimals or 0)
    return math.floor(n * m + 0.5) / m
end

local function sanitize(str)
    return (tostring(str):gsub("[^%w%-_]", "_"))
end

--================================================================
-- Library Table
--================================================================
local AetherUI = {}
AetherUI.__index = AetherUI
AetherUI.Themes = Themes
AetherUI.IsMobile = IsMobile

-- registry of color-bound instances for live theme switching
-- entry: { Instance = inst, Property = "BackgroundColor3", Key = "Surface" }
local colorBindings = {}

local function bindColor(inst, property, themeKey)
    table.insert(colorBindings, { Instance = inst, Property = property, Key = themeKey })
end

--================================================================
-- Tooltip System
--================================================================
local TooltipController = {}
TooltipController.__index = TooltipController

function TooltipController.new(parentGui)
    local tip = Instance.new("Frame")
    tip.Name = "Tooltip"
    tip.AnchorPoint = Vector2.new(0, 0.5)
    tip.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    tip.Visible = false
    tip.ZIndex = 100
    tip.Parent = parentGui
    corner(tip, 6)
    stroke(tip, Color3.fromRGB(60, 64, 84), 1, 0)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextColor3 = Color3.fromRGB(235, 238, 245)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tip
    padding(label, 8, 4, 8, 4)

    local self = setmetatable({ frame = tip, label = label }, TooltipController)

    RunService.RenderStepped:Connect(function()
        if not tip.Visible then return end
        local mouse = UserInputService:GetMouseLocation()
        local vp = workspace.CurrentCamera.ViewportSize
        local x = mouse.X + 14
        local y = mouse.Y
        local w = tip.AbsoluteSize.X
        if x + w > vp.X then x = mouse.X - w - 14 end
        tip.Position = UDim2.fromOffset(x, y)
    end)

    return self
end

function TooltipController:Show(text)
    if not text or text == "" then return end
    self.label.Text = text
    local width = self.label.TextBounds.X + 16
    self.frame.Size = UDim2.fromOffset(width, self.label.TextBounds.Y + 8)
    self.frame.Visible = true
    tween(self.frame, T_FAST, { BackgroundTransparency = 0 })
end

function TooltipController:Hide()
    if not self.frame.Visible then return end
    tween(self.frame, T_FAST, { BackgroundTransparency = 1 })
    _task.delay(T_FAST, function() self.frame.Visible = false end)
end

--================================================================
-- Drag System
--================================================================
local function makeDraggable(dragHandle, target)
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--================================================================
-- Notification System
--================================================================
local NotificationStack = {}
NotificationStack.__index = NotificationStack

function NotificationStack.new(parentGui, theme)
    local container = Instance.new("Frame")
    container.Name = "Notifications"
    container.BackgroundTransparency = 1
    container.AnchorPoint = Vector2.new(1, 0)
    container.Position = UDim2.new(1, -12, 0, 12)
    container.Size = UDim2.new(0, 320, 1, -24)
    container.ZIndex = 80
    container.Parent = parentGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container

    return setmetatable({ container = container, layout = layout, theme = theme }, NotificationStack)
end

function NotificationStack:Push(opts)
    opts = opts or {}
    local theme = self.theme
    local title   = opts.Title or "Notification"
    local text    = opts.Text or ""
    local dur     = opts.Duration or 5
    local accent  = opts.Accent or theme.Accent

    local card = Instance.new("Frame")
    card.Name = "NotificationCard"
    card.BackgroundColor3 = theme.Notification
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AnchorPoint = Vector2.new(1, 0)
    card.Position = UDim2.new(1, 40, 0, 0)
    card.ClipsDescendants = true
    card.ZIndex = 81
    card.Parent = self.container
    corner(card, 8)
    local _stroke_card = stroke(card, theme.Stroke, 1, 0)

    local accentBar = Instance.new("Frame")
    accentBar.Name = "Accent"
    accentBar.BackgroundColor3 = accent
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card
    corner(accentBar, 2)

    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Position = UDim2.new(0, 12, 0, 10)
    inner.Size = UDim2.new(1, -24, 1, -20)
    inner.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = title
    titleLabel.TextColor3 = theme.Text
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.Size = UDim2.new(1, 0, 0, 16)
    titleLabel.Parent = inner

    local bodyLabel = Instance.new("TextLabel")
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.Text = text
    bodyLabel.TextColor3 = theme.TextMuted
    bodyLabel.TextSize = 12
    bodyLabel.TextWrapped = true
    bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
    bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
    bodyLabel.Position = UDim2.new(0, 0, 0, 20)
    bodyLabel.Size = UDim2.new(1, 0, 1, -20)
    bodyLabel.Parent = inner

    bindColor(card, "BackgroundColor3", "Notification")
    bindColor(_stroke_card, "Color", "Stroke")
    bindColor(titleLabel, "TextColor3", "Text")
    bindColor(bodyLabel, "TextColor3", "TextMuted")

    local bodyH = bodyLabel.TextBounds.Y
    local targetH = 16 + bodyH + 20

    _task.spawn(function()
        card.Position = UDim2.new(1, 40, 0, 0)
        tween(card, T, { Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(1, 0, 0, targetH) })
        _task.wait(dur)
        tween(card, T, { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(1, 40, 0, 0) })
        _task.wait(T + 0.05)
        card:Destroy()
    end)
end

--================================================================
-- Hover helper
--================================================================
local function applyHover(frame, normalColor, hoverColor, pressedScale)
    local scale = Instance.new("UIScale")
    scale.Parent = frame
    frame.MouseEnter:Connect(function()
        if UserInputService.MouseEnabled then
            tween(frame, T_FAST, { BackgroundColor3 = hoverColor })
        end
    end)
    frame.MouseLeave:Connect(function()
        tween(frame, T_FAST, { BackgroundColor3 = normalColor })
    end)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            tween(scale, 0.06, { Scale = pressedScale or 0.97 })
        end
    end)
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            tween(scale, 0.12, { Scale = 1 })
        end
    end)
    return scale
end

--================================================================
-- CreateWindow
--================================================================
function AetherUI:CreateWindow(opts)
    opts = opts or {}
    assert(typeof(opts.Title) == "string", "CreateWindow: Title (string) is required")

    local themeName = opts.Theme or "Midnight"
    local mobile = (opts.Mobile == nil) and IsMobile or (opts.Mobile == true)

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "AetherUI_" .. sanitize(opts.Title)
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = Player:WaitForChild("PlayerGui") end

    -- Window table (created early so closures can reference it)
    local Window = {}
    Window.__index = Window
    Window.Gui = gui
    Window.ThemeName = themeName
    Window.Theme = Themes[themeName] or Themes.Midnight
    Window.Mobile = mobile
    Window.Tabs = {}
    Window.ActiveTab = nil
    Window.ConfigFolder = opts.ConfigFolder or "AetherUIConfigs"
    Window.ConfigElements = {}
    Window.ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
    Window._visible = true
    Window._transparency = 0

    local function theme()
        return Window.Theme
    end

    local tooltipCtrl = TooltipController.new(gui)
    local notifStack = NotificationStack.new(gui, Window.Theme)

    -- Watermark
    local watermark = Instance.new("Frame")
    watermark.Name = "Watermark"
    watermark.AnchorPoint = Vector2.new(0, 0)
    watermark.Position = UDim2.new(0, 12, 0, 12)
    watermark.BackgroundColor3 = theme().Surface
    watermark.Size = UDim2.new(0, 0, 0, 30)
    watermark.ZIndex = 70
    watermark.Parent = gui
    corner(watermark, 8)
    local _stroke_watermark = stroke(watermark, theme().Stroke, 1, 0)
    bindColor(watermark, "BackgroundColor3", "Surface")
    bindColor(_stroke_watermark, "Color", "Stroke")

    local wmDot = Instance.new("Frame")
    wmDot.Name = "Dot"
    wmDot.AnchorPoint = Vector2.new(0, 0.5)
    wmDot.Position = UDim2.new(0, 10, 0.5, 0)
    wmDot.Size = UDim2.new(0, 6, 0, 6)
    wmDot.BackgroundColor3 = theme().Accent
    wmDot.BorderSizePixel = 0
    wmDot.Parent = watermark
    corner(wmDot, 3)
    bindColor(wmDot, "BackgroundColor3", "Accent")

    local wmText = Instance.new("TextLabel")
    wmText.BackgroundTransparency = 1
    wmText.Font = Enum.Font.GothamBold
    wmText.Text = (opts.Brand or "AetherUI") .. "  |  0 FPS"
    wmText.TextColor3 = theme().Text
    wmText.TextSize = 12
    wmText.AnchorPoint = Vector2.new(0, 0.5)
    wmText.Position = UDim2.new(0, 24, 0.5, 0)
    wmText.Size = UDim2.new(0, 200, 0, 16)
    wmText.TextXAlignment = Enum.TextXAlignment.Left
    wmText.Parent = watermark
    bindColor(wmText, "TextColor3", "Text")

    local fpsAccum, fpsCount = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        fpsAccum = fpsAccum + dt
        fpsCount = fpsCount + 1
        if fpsAccum >= 0.5 then
            local fps = math.floor(fpsCount / fpsAccum)
            wmText.Text = (opts.Brand or "AetherUI") .. "  |  " .. fps .. " FPS"
            watermark.Size = UDim2.new(0, wmText.TextBounds.X + 28, 0, 30)
            fpsAccum, fpsCount = 0, 0
        end
    end)

    -- Main Window frame
    local vp = workspace.CurrentCamera.ViewportSize
    local winWidth  = mobile and (vp.X - 24) or 640
    local winHeight = mobile and 380 or 460

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.AnchorPoint = mobile and Vector2.new(0.5, 1) or Vector2.new(0.5, 0.5)
    window.Position = mobile and UDim2.new(0.5, 0, 1, -12) or UDim2.new(0.5, 0, 0.5, 0)
    window.Size = UDim2.new(0, winWidth, 0, winHeight)
    window.BackgroundColor3 = theme().Background
    window.ZIndex = 10
    window.Parent = gui
    corner(window, 12)
    local _stroke_window = stroke(window, theme().StrokeStrong, 1, 0)
    bindColor(window, "BackgroundColor3", "Background")
    bindColor(_stroke_window, "Color", "StrokeStrong")

    local winScale = Instance.new("UIScale")
    winScale.Parent = window
    Window._winScale = winScale
    Window._window = window

    -- open animation
    winScale.Scale = 0.92
    window.BackgroundTransparency = 1
    _stroke_window.Transparency = 1
    _task.delay(0.02, function()
        tween(winScale, T_SLOW, { Scale = 1 })
        tween(window, T_SLOW, { BackgroundTransparency = 0 })
        tween(_stroke_window, T_SLOW, { Transparency = 0 })
    end)

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 48)
    titleBar.BackgroundColor3 = theme().Surface
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 11
    titleBar.Parent = window
    corner(titleBar, 12)
    bindColor(titleBar, "BackgroundColor3", "Surface")

    local mask = Instance.new("Frame")
    mask.Size = UDim2.new(1, 0, 0, 12)
    mask.Position = UDim2.new(0, 0, 1, -12)
    mask.BackgroundColor3 = theme().Surface
    mask.BorderSizePixel = 0
    mask.ZIndex = 11
    mask.Parent = titleBar
    bindColor(mask, "BackgroundColor3", "Surface")

    padding(titleBar, 14, 0, 8, 0)

    local titleIcon = Instance.new("ImageLabel")
    titleIcon.Name = "Icon"
    titleIcon.BackgroundTransparency = 1
    titleIcon.Size = UDim2.new(0, 22, 0, 22)
    titleIcon.Position = UDim2.new(0, 0, 0.5, -11)
    titleIcon.Image = opts.Icon or ""
    titleIcon.Visible = (opts.Icon ~= nil)
    titleIcon.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = opts.Title or "Aether UI"
    titleLabel.TextColor3 = theme().Text
    titleLabel.TextSize = 15
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.AnchorPoint = Vector2.new(0, 0.5)
    titleLabel.Position = UDim2.new(0, opts.Icon and 32 or 0, 0.5, 0)
    titleLabel.Size = UDim2.new(0, 300, 0, 18)
    titleLabel.Parent = titleBar
    bindColor(titleLabel, "TextColor3", "Text")

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.Text = opts.Subtitle or ""
    subtitleLabel.TextColor3 = theme().TextMuted
    subtitleLabel.TextSize = 12
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.AnchorPoint = Vector2.new(0, 0.5)
    subtitleLabel.Position = UDim2.new(0, opts.Icon and 32 or 0, 0.5, 16)
    subtitleLabel.Size = UDim2.new(0, 300, 0, 14)
    subtitleLabel.Visible = (opts.Subtitle ~= nil)
    subtitleLabel.Parent = titleBar
    bindColor(subtitleLabel, "TextColor3", "TextMuted")

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.AnchorPoint = Vector2.new(1, 0.5)
    closeBtn.Position = UDim2.new(1, 0, 0.5, 0)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.BackgroundColor3 = theme().Element
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.TextColor3 = theme().TextMuted
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = titleBar
    corner(closeBtn, 8)
    bindColor(closeBtn, "BackgroundColor3", "Element")
    bindColor(closeBtn, "TextColor3", "TextMuted")
    applyHover(closeBtn, theme().Element, theme().ElementHover, 0.9)

    makeDraggable(titleBar, window)

    -- Body
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.Position = UDim2.new(0, 0, 0, 48)
    body.Size = UDim2.new(1, 0, 1, -48)
    body.BackgroundTransparency = 1
    body.Parent = window

    local sidebarWidth = mobile and 0 or 180

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Position = UDim2.new(0, 12, 0, 12)
    sidebar.Size = UDim2.new(0, sidebarWidth - 12, 1, -24)
    sidebar.BackgroundColor3 = theme().Sidebar
    sidebar.ZIndex = 11
    sidebar.Visible = not mobile
    sidebar.Parent = body
    corner(sidebar, 10)
    local _stroke_sidebar = stroke(sidebar, theme().Stroke, 1, 0)
    bindColor(sidebar, "BackgroundColor3", "Sidebar")
    bindColor(_stroke_sidebar, "Color", "Stroke")

    local tabListParent  -- the scrolling frame that holds tab buttons
    local searchBox

    if not mobile then
        local sidebarScroll = Instance.new("ScrollingFrame")
        sidebarScroll.Name = "TabList"
        sidebarScroll.BackgroundTransparency = 1
        sidebarScroll.BorderSizePixel = 0
        sidebarScroll.Position = UDim2.new(0, 8, 0, 8)
        sidebarScroll.Size = UDim2.new(1, -16, 1, -16)
        sidebarScroll.ScrollBarThickness = 2
        sidebarScroll.ScrollBarImageColor3 = theme().Stroke
        sidebarScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        safeSet(sidebarScroll, "AutomaticCanvasSize", Enum.AutomaticSize.Y)
        sidebarScroll.ZIndex = 12
        sidebarScroll.Parent = sidebar
        bindColor(sidebarScroll, "ScrollBarImageColor3", "Stroke")

        local sidebarLayout = Instance.new("UIListLayout")
        sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
        sidebarLayout.Padding = UDim.new(0, 4)
        sidebarLayout.Parent = sidebarScroll

        searchBox = Instance.new("TextBox")
        searchBox.Name = "Search"
        searchBox.PlaceholderText = "Search tabs..."
        searchBox.Text = ""
        searchBox.Size = UDim2.new(1, -16, 0, 30)
        searchBox.BackgroundColor3 = theme().Element
        searchBox.Font = Enum.Font.Gotham
        searchBox.TextSize = 12
        searchBox.TextColor3 = theme().Text
        searchBox.PlaceholderColor3 = theme().TextMuted
        searchBox.ClearTextOnFocus = false
        searchBox.TextXAlignment = Enum.TextXAlignment.Left
        searchBox.LayoutOrder = 0
        searchBox.ZIndex = 12
        searchBox.Parent = sidebarScroll
        corner(searchBox, 6)
        padding(searchBox, 8, 0, 8, 0)
        bindColor(searchBox, "BackgroundColor3", "Element")
        bindColor(searchBox, "TextColor3", "Text")
        bindColor(searchBox, "PlaceholderColor3", "TextMuted")

        tabListParent = sidebarScroll
    else
        -- mobile: horizontal tab strip at top
        local strip = Instance.new("Frame")
        strip.Name = "TabStrip"
        strip.Position = UDim2.new(0, 12, 0, 12)
        strip.Size = UDim2.new(1, -24, 0, 38)
        strip.BackgroundColor3 = theme().Sidebar
        strip.ZIndex = 11
        strip.Parent = body
        corner(strip, 10)
        local _stroke_strip = stroke(strip, theme().Stroke, 1, 0)
        bindColor(strip, "BackgroundColor3", "Sidebar")
        bindColor(_stroke_strip, "Color", "Stroke")

        local stripScroll = Instance.new("ScrollingFrame")
        stripScroll.BackgroundTransparency = 1
        stripScroll.BorderSizePixel = 0
        stripScroll.Size = UDim2.new(1, -12, 1, -8)
        stripScroll.Position = UDim2.new(0, 6, 0, 4)
        stripScroll.ScrollBarThickness = 0
        stripScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        safeSet(stripScroll, "AutomaticCanvasSize", Enum.AutomaticSize.X)
        stripScroll.ScrollingDirection = Enum.ScrollingDirection.X
        stripScroll.ZIndex = 12
        stripScroll.Parent = strip

        local stripLayout = Instance.new("UIListLayout")
        stripLayout.FillDirection = Enum.FillDirection.Horizontal
        stripLayout.SortOrder = Enum.SortOrder.LayoutOrder
        stripLayout.Padding = UDim.new(0, 6)
        stripLayout.Parent = stripScroll

        tabListParent = stripScroll
    end

    -- Content area
    local contentArea = Instance.new("Frame")
    if mobile then
        contentArea.Position = UDim2.new(0, 12, 0, 56)
        contentArea.Size = UDim2.new(1, -24, 1, -68)
    else
        contentArea.Position = UDim2.new(0, sidebarWidth, 0, 12)
        contentArea.Size = UDim2.new(1, -(sidebarWidth + 12), 1, -24)
    end
    contentArea.BackgroundColor3 = theme().Surface
    contentArea.ZIndex = 11
    contentArea.Parent = body
    corner(contentArea, 10)
    local _stroke_contentArea = stroke(contentArea, theme().Stroke, 1, 0)
    bindColor(contentArea, "BackgroundColor3", "Surface")
    bindColor(_stroke_contentArea, "Color", "Stroke")

    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "Content"
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.Position = UDim2.new(0, 8, 0, 8)
    contentScroll.Size = UDim2.new(1, -16, 1, -16)
    contentScroll.ScrollBarThickness = 3
    contentScroll.ScrollBarImageColor3 = theme().Stroke
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    safeSet(contentScroll, "AutomaticCanvasSize", Enum.AutomaticSize.Y)
    contentScroll.ZIndex = 12
    contentScroll.Parent = contentArea
    bindColor(contentScroll, "ScrollBarImageColor3", "Stroke")

    local contentLayout = Instance.new("UIListLayout")
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    contentLayout.Padding = UDim.new(0, 10)
    contentLayout.Parent = contentScroll

    --========================
    -- Helpers for elements
    --========================
    local function addTooltip(row, tip)
        if not tip or tip == "" then return end
        row.MouseEnter:Connect(function() tooltipCtrl:Show(tip) end)
        row.MouseLeave:Connect(function() tooltipCtrl:Hide() end)
    end

    local function createElementRow(holder, label, rowHeight)
        local th = theme()
        local row = Instance.new("Frame")
        row.Name = "El_" .. sanitize(label)
        row.BackgroundColor3 = th.Element
        row.Size = UDim2.new(1, 0, 0, rowHeight or 38)
        row.ZIndex = 12
        row.Parent = holder
        corner(row, 6)
        local _stroke_row = stroke(row, th.Stroke, 1, 0)
        bindColor(row, "BackgroundColor3", "Element")
        bindColor(_stroke_row, "Color", "Stroke")

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.Text = label
        lbl.TextColor3 = th.Text
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Position = UDim2.new(0, 12, 0, 0)
        lbl.Size = UDim2.new(1, -24, 1, 0)
        lbl.ZIndex = 13
        lbl.Parent = row
        bindColor(lbl, "TextColor3", "Text")

        return row, lbl
    end

    --========================
    -- Section prototype
    --========================
    local SectionProto = {}
    SectionProto.__index = SectionProto

    -- Label
    function SectionProto:CreateLabel(text)
        local th = theme()
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamMedium
        lbl.Text = text or "Label"
        lbl.TextColor3 = th.Text
        lbl.TextSize = 13
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Size = UDim2.new(1, 0, 0, 0)
        lbl.AutomaticSize = Enum.AutomaticSize.Y
        lbl.ZIndex = 12
        lbl.Parent = self._holder
        bindColor(lbl, "TextColor3", "Text")

        local El = {}
        function El:Set(newText) lbl.Text = newText or "" end
        function El:Get() return lbl.Text end
        return El
    end

    -- Paragraph
    function SectionProto:CreateParagraph(title, body)
        local th = theme()
        local holder = Instance.new("Frame")
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.new(1, 0, 0, 0)
        holder.AutomaticSize = Enum.AutomaticSize.Y
        holder.ZIndex = 12
        holder.Parent = self._holder

        local titleL = Instance.new("TextLabel")
        titleL.BackgroundTransparency = 1
        titleL.Font = Enum.Font.GothamBold
        titleL.Text = title or ""
        titleL.TextColor3 = th.Text
        titleL.TextSize = 13
        titleL.TextXAlignment = Enum.TextXAlignment.Left
        titleL.Size = UDim2.new(1, 0, 0, 16)
        titleL.ZIndex = 12
        titleL.Parent = holder
        bindColor(titleL, "TextColor3", "Text")

        local bodyL = Instance.new("TextLabel")
        bodyL.BackgroundTransparency = 1
        bodyL.Font = Enum.Font.Gotham
        bodyL.Text = body or ""
        bodyL.TextColor3 = th.TextMuted
        bodyL.TextSize = 12
        bodyL.TextWrapped = true
        bodyL.TextXAlignment = Enum.TextXAlignment.Left
        bodyL.Position = UDim2.new(0, 0, 0, 18)
        bodyL.Size = UDim2.new(1, 0, 0, 0)
        bodyL.AutomaticSize = Enum.AutomaticSize.Y
        bodyL.ZIndex = 12
        bodyL.Parent = holder
        bindColor(bodyL, "TextColor3", "TextMuted")

        local El = {}
        function El:Set(newTitle, newBody)
            titleL.Text = newTitle or titleL.Text
            bodyL.Text = newBody or bodyL.Text
        end
        function El:Get() return titleL.Text, bodyL.Text end
        return El
    end

    -- Button
    function SectionProto:CreateButton(text, callback)
        local th = theme()
        callback = callback or function() end
        local row, lbl = createElementRow(self._holder, text, 38)
        applyHover(row, th.Element, th.ElementHover, 0.97)

        local El = {}
        function El:Set(newText) lbl.Text = newText end
        function El:Fire() callback() end

        row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                playClick(0.2)
                callback()
            end
        end)
        return El
    end

    -- Toggle
    function SectionProto:CreateToggle(text, default, callback, opts2)
        local th = theme()
        opts2 = opts2 or {}
        callback = callback or function() end
        local state = default and true or false

        local row, lbl = createElementRow(self._holder, text, 38)
        applyHover(row, th.Element, th.ElementHover, 1)

        local switch = Instance.new("TextButton")
        switch.Name = "Switch"
        switch.AnchorPoint = Vector2.new(1, 0.5)
        switch.Position = UDim2.new(1, -10, 0.5, 0)
        switch.Size = UDim2.new(0, 40, 0, 22)
        switch.BackgroundColor3 = state and th.Accent or th.SurfaceHover
        switch.Text = ""
        switch.AutoButtonColor = false
        switch.ZIndex = 14
        switch.Parent = row
        corner(switch, 11)
        bindColor(switch, "BackgroundColor3", state and "Accent" or "SurfaceHover")

        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.AnchorPoint = Vector2.new(0, 0.5)
        knob.Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 15
        knob.Parent = switch
        corner(knob, 9)

        local El = {}
        function El:Set(newVal, fire)
            state = newVal and true or false
            local t = theme()
            if state then
                tween(switch, T, { BackgroundColor3 = t.Accent })
                tween(knob, T, { Position = UDim2.new(1, -20, 0.5, 0) })
            else
                tween(switch, T, { BackgroundColor3 = t.SurfaceHover })
                tween(knob, T, { Position = UDim2.new(0, 2, 0.5, 0) })
            end
            for _, b in ipairs(colorBindings) do
                if b.Instance == switch and b.Property == "BackgroundColor3" then
                    b.Key = state and "Accent" or "SurfaceHover"
                end
            end
            if fire == true then callback(state) end
        end
        function El:Get() return state end

        switch.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                playClick(0.2)
                El:Set(not state)
            end
        end)
        addTooltip(row, opts2.Tooltip)

        if opts2.Flag then
            Window:_RegisterConfig(opts2.Flag, function() return state end, function(v) El:Set(v, false) end)
        end
        return El
    end

    -- Checkbox
    function SectionProto:CreateCheckbox(text, default, callback, opts2)
        local th = theme()
        opts2 = opts2 or {}
        callback = callback or function() end
        local state = default and true or false

        local row, lbl = createElementRow(self._holder, text, 38)
        applyHover(row, th.Element, th.ElementHover, 1)

        local box = Instance.new("TextButton")
        box.Name = "Box"
        box.AnchorPoint = Vector2.new(1, 0.5)
        box.Position = UDim2.new(1, -10, 0.5, 0)
        box.Size = UDim2.new(0, 22, 0, 22)
        box.BackgroundColor3 = state and th.Accent or th.SurfaceHover
        box.Text = state and "✓" or ""
        box.Font = Enum.Font.GothamBold
        box.TextSize = 14
        box.TextColor3 = th.AccentText
        box.AutoButtonColor = false
        box.ZIndex = 14
        box.Parent = row
        corner(box, 6)
        bindColor(box, "BackgroundColor3", state and "Accent" or "SurfaceHover")
        bindColor(box, "TextColor3", "AccentText")

        local El = {}
        function El:Set(newVal, fire)
            state = newVal and true or false
            local t = theme()
            if state then
                tween(box, T, { BackgroundColor3 = t.Accent })
                box.Text = "✓"
            else
                tween(box, T, { BackgroundColor3 = t.SurfaceHover })
                box.Text = ""
            end
            for _, b in ipairs(colorBindings) do
                if b.Instance == box and b.Property == "BackgroundColor3" then
                    b.Key = state and "Accent" or "SurfaceHover"
                end
            end
            if fire == true then callback(state) end
        end
        function El:Get() return state end

        box.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                playClick(0.2)
                El:Set(not state)
            end
        end)
        addTooltip(row, opts2.Tooltip)

        if opts2.Flag then
            Window:_RegisterConfig(opts2.Flag, function() return state end, function(v) El:Set(v, false) end)
        end
        return El
    end

    -- Slider
    function SectionProto:CreateSlider(text, min, max, default, callback, opts2)
        local th = theme()
        opts2 = opts2 or {}
        callback = callback or function() end
        local suffix = opts2.Suffix or ""
        local decimals = opts2.Decimals or 0
        local value = math.clamp(default or min, min, max)

        local row, lbl = createElementRow(self._holder, text, 42)
        applyHover(row, th.Element, th.ElementHover, 1)

        local valueLabel = Instance.new("TextLabel")
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = Enum.Font.GothamMedium
        valueLabel.Text = tostring(round(value, decimals)) .. suffix
        valueLabel.TextColor3 = th.TextMuted
        valueLabel.TextSize = 12
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.AnchorPoint = Vector2.new(1, 0.5)
        valueLabel.Position = UDim2.new(1, -10, 0.5, -7)
        valueLabel.Size = UDim2.new(0, 100, 0, 14)
        valueLabel.ZIndex = 13
        valueLabel.Parent = row
        bindColor(valueLabel, "TextColor3", "TextMuted")

        local track = Instance.new("Frame")
        track.Name = "Track"
        track.AnchorPoint = Vector2.new(0, 1)
        track.Position = UDim2.new(0, 12, 1, -7)
        track.Size = UDim2.new(1, -24, 0, 4)
        track.BackgroundColor3 = th.SurfaceHover
        track.BorderSizePixel = 0
        track.ZIndex = 13
        track.Parent = row
        corner(track, 2)
        bindColor(track, "BackgroundColor3", "SurfaceHover")

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = th.Accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 14
        fill.Parent = track
        corner(fill, 2)
        bindColor(fill, "BackgroundColor3", "Accent")

        local handle = Instance.new("Frame")
        handle.Name = "Handle"
        handle.AnchorPoint = Vector2.new(0.5, 0.5)
        handle.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
        handle.Size = UDim2.new(0, 14, 0, 14)
        handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        handle.BorderSizePixel = 0
        handle.ZIndex = 15
        handle.Parent = track
        corner(handle, 7)

        local dragging = false
        local function updateFromInput(input)
            local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
            rel = math.clamp(rel, 0, 1)
            local newVal = round(min + (max - min) * rel, decimals)
            value = newVal
            fill.Size = UDim2.new(rel, 0, 1, 0)
            handle.Position = UDim2.new(rel, 0, 0.5, 0)
            valueLabel.Text = tostring(newVal) .. suffix
            callback(newVal)
        end

        local El = {}
        function El:Set(newVal, fire)
            newVal = math.clamp(round(newVal, decimals), min, max)
            value = newVal
            local rel = (newVal - min) / (max - min)
            tween(fill, T_FAST, { Size = UDim2.new(rel, 0, 1, 0) })
            tween(handle, T_FAST, { Position = UDim2.new(rel, 0, 0.5, 0) })
            valueLabel.Text = tostring(newVal) .. suffix
            if fire == true then callback(newVal) end
        end
        function El:Get() return value end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                playClick(0.15)
                updateFromInput(input)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        addTooltip(row, opts2.Tooltip)

        if opts2.Flag then
            Window:_RegisterConfig(opts2.Flag, function() return value end, function(v) El:Set(v, false) end)
        end
        return El
    end

    -- Dropdown
    function SectionProto:CreateDropdown(text, options, default, callback, opts2)
        local th = theme()
        opts2 = opts2 or {}
        callback = callback or function() end
        local multi = opts2.Multi == true
        local values = {}
        local single = default
        if multi and type(default) == "table" then
            for _, v in ipairs(default) do values[v] = true end
        end

        local row, lbl = createElementRow(self._holder, text, 38)
        applyHover(row, th.Element, th.ElementHover, 1)

        local currentText = Instance.new("TextLabel")
        currentText.BackgroundTransparency = 1
        currentText.Font = Enum.Font.GothamMedium
        currentText.TextColor3 = th.TextMuted
        currentText.TextSize = 12
        currentText.TextXAlignment = Enum.TextXAlignment.Right
        currentText.AnchorPoint = Vector2.new(1, 0.5)
        currentText.Position = UDim2.new(1, -28, 0.5, 0)
        currentText.Size = UDim2.new(0, 160, 0, 14)
        currentText.ZIndex = 13
        currentText.Parent = row
        bindColor(currentText, "TextColor3", "TextMuted")

        local chevron = Instance.new("ImageLabel")
        chevron.BackgroundTransparency = 1
        chevron.AnchorPoint = Vector2.new(1, 0.5)
        chevron.Position = UDim2.new(1, -10, 0.5, 0)
        chevron.Size = UDim2.new(0, 14, 0, 14)
        chevron.Image = "rbxassetid://6031094670"
        chevron.ImageColor3 = th.TextMuted
        chevron.ZIndex = 13
        chevron.Parent = row
        bindColor(chevron, "ImageColor3", "TextMuted")

        local expanded = false
        local listFrame

        local function syncText()
            if multi then
                local picked = {}
                for _, opt in ipairs(options) do if values[opt] then table.insert(picked, opt) end end
                currentText.Text = (#picked == 0) and "Select..." or table.concat(picked, ", ")
            else
                currentText.Text = tostring(single or "Select...")
            end
        end

        local El = {}
        local function buildList()
            if listFrame then listFrame:Destroy() end
            local t = theme()
            listFrame = Instance.new("Frame")
            listFrame.Name = "List"
            listFrame.AnchorPoint = Vector2.new(1, 0)
            listFrame.Position = UDim2.new(1, -10, 1, 4)
            listFrame.Size = UDim2.new(0, 200, 0, 0)
            listFrame.BackgroundColor3 = t.Surface
            listFrame.ZIndex = 30
            listFrame.Parent = row
            corner(listFrame, 8)
            local _stroke_listFrame = stroke(listFrame, t.StrokeStrong, 1, 0)
            bindColor(listFrame, "BackgroundColor3", "Surface")
            bindColor(_stroke_listFrame, "Color", "StrokeStrong")

            local listScroll = Instance.new("ScrollingFrame")
            listScroll.BackgroundTransparency = 1
            listScroll.BorderSizePixel = 0
            listScroll.Size = UDim2.new(1, 0, 1, 0)
            listScroll.ScrollBarThickness = 2
            listScroll.ScrollBarImageColor3 = t.Stroke
            listScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
            safeSet(listScroll, "AutomaticCanvasSize", Enum.AutomaticSize.Y)
            listScroll.ZIndex = 31
            listScroll.Parent = listFrame
            bindColor(listScroll, "ScrollBarImageColor3", "Stroke")

            local ll = Instance.new("UIListLayout")
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Padding = UDim.new(0, 2)
            ll.Parent = listScroll

            local order = 0
            for _, opt in ipairs(options) do
                order = order + 1
                local item = Instance.new("TextButton")
                item.Name = "Item_" .. sanitize(opt)
                item.Size = UDim2.new(1, 0, 0, 28)
                item.BackgroundColor3 = t.Element
                item.Text = ""
                item.AutoButtonColor = false
                item.LayoutOrder = order
                item.ZIndex = 32
                item.Parent = listScroll
                corner(item, 6)
                bindColor(item, "BackgroundColor3", "Element")
                applyHover(item, t.Element, t.ElementHover, 0.98)

                local itemLbl = Instance.new("TextLabel")
                itemLbl.BackgroundTransparency = 1
                itemLbl.Font = Enum.Font.GothamMedium
                itemLbl.Text = tostring(opt)
                itemLbl.TextColor3 = t.Text
                itemLbl.TextSize = 12
                itemLbl.TextXAlignment = Enum.TextXAlignment.Left
                itemLbl.Position = UDim2.new(0, 8, 0, 0)
                itemLbl.Size = UDim2.new(1, -16, 1, 0)
                itemLbl.ZIndex = 33
                itemLbl.Parent = item
                bindColor(itemLbl, "TextColor3", "Text")

                if multi and values[opt] then
                    item.BackgroundColor3 = t.Accent
                    itemLbl.TextColor3 = t.AccentText
                    for _, b in ipairs(colorBindings) do
                        if b.Instance == item and b.Property == "BackgroundColor3" then b.Key = "Accent" end
                        if b.Instance == itemLbl and b.Property == "TextColor3" then b.Key = "AccentText" end
                    end
                end

                item.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        playClick(0.15)
                        if multi then
                            values[opt] = not values[opt]
                        else
                            single = opt
                        end
                        syncText()
                        if listFrame then
                            listFrame:Destroy()
                            listFrame = nil
                            buildList()
                            local h = math.min(#options, 6) * 30 + 8
                            listFrame.Size = UDim2.new(0, 200, 0, h)
                        end
                        if multi then
                            local picked = {}
                            for _, o in ipairs(options) do if values[o] then table.insert(picked, o) end end
                            callback(picked)
                        else
                            callback(single)
                            El:Collapse()
                        end
                    end
                end)
            end
        end

        function El:Expand()
            if expanded then return end
            expanded = true
            buildList()
            tween(chevron, T, { Rotation = 180 })
            local h = math.min(#options, 6) * 30 + 8
            tween(listFrame, T, { Size = UDim2.new(0, 200, 0, h) })
            playClick(0.15)
        end
        function El:Collapse()
            if not expanded then return end
            expanded = false
            tween(chevron, T, { Rotation = 0 })
            if listFrame then
                tween(listFrame, T, { Size = UDim2.new(0, 200, 0, 0) })
                _task.delay(T + 0.02, function()
                    if listFrame then listFrame:Destroy(); listFrame = nil end
                end)
            end
        end
        function El:Set(val, fire)
            if multi then
                values = {}
                if type(val) == "table" then
                    for _, v in ipairs(val) do values[v] = true end
                end
            else
                single = val
            end
            syncText()
            if fire == true then
                if multi then
                    local picked = {}
                    for _, o in ipairs(options) do if values[o] then table.insert(picked, o) end end
                    callback(picked)
                else
                    callback(single)
                end
            end
        end
        function El:Get()
            if multi then
                local p = {}
                for _, o in ipairs(options) do if values[o] then table.insert(p, o) end end
                return p
            end
            return single
        end
        function El:Refresh(newOptions, keepSelection)
            local oldSingle, oldValues = single, values
            options = newOptions
            values = {}
            single = nil
            if keepSelection then
                if multi then
                    for _, o in ipairs(newOptions) do if oldValues[o] then values[o] = true end end
                else
                    for _, o in ipairs(newOptions) do if o == oldSingle then single = o end end
                end
            end
            syncText()
            if expanded then
                El:Collapse()
                _task.delay(T + 0.05, function() El:Expand() end)
            end
        end

        row.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                if expanded then El:Collapse() else El:Expand() end
            end
        end)

        UserInputService.InputBegan:Connect(function(input)
            if expanded and input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mouse = UserInputService:GetMouseLocation()
                if listFrame then
                    local pos = listFrame.AbsolutePosition
                    local size = listFrame.AbsoluteSize
                    local inList = (mouse.X >= pos.X and mouse.X <= pos.X + size.X
                                and mouse.Y >= pos.Y and mouse.Y <= pos.Y + size.Y)
                    local inRow = (mouse.X >= row.AbsolutePosition.X and mouse.X <= row.AbsolutePosition.X + row.AbsoluteSize.X
                                and mouse.Y >= row.AbsolutePosition.Y and mouse.Y <= row.AbsolutePosition.Y + row.AbsoluteSize.Y)
                    if not inList and not inRow then
                        El:Collapse()
                    end
                end
            end
        end)

        syncText()
        addTooltip(row, opts2.Tooltip)

        if opts2.Flag then
            Window:_RegisterConfig(opts2.Flag, function() return El:Get() end, function(v) El:Set(v, false) end)
        end
        return El
    end

    -- Keybind
    function SectionProto:CreateKeybind(text, default, callback, opts2)
        local th = theme()
        opts2 = opts2 or {}
        callback = callback or function() end
        local current = default
        if typeof(current) == "string" then
            current = Enum.KeyCode[current]
        end
        local listening = false

        local row, lbl = createElementRow(self._holder, text, 38)
        applyHover(row, th.Element, th.ElementHover, 1)

        local display = Instance.new("TextButton")
        display.Name = "Key"
        display.AnchorPoint = Vector2.new(1, 0.5)
        display.Position = UDim2.new(1, -10, 0.5, 0)
        display.Size = UDim2.new(0, 80, 0, 24)
        display.BackgroundColor3 = th.SurfaceHover
        display.Text = current and current.Name or "None"
        display.Font = Enum.Font.GothamMedium
        display.TextSize = 12
        display.TextColor3 = th.Text
        display.AutoButtonColor = false
        display.ZIndex = 14
        display.Parent = row
        corner(display, 6)
        bindColor(display, "BackgroundColor3", "SurfaceHover")
        bindColor(display, "TextColor3", "Text")

        local El = {}
        function El:Set(key)
            if typeof(key) == "string" then key = Enum.KeyCode[key] end
            current = key
            display.Text = key and key.Name or "None"
        end
        function El:Get() return current end

        display.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                listening = true
                display.Text = "..."
                tween(display, T_FAST, { BackgroundColor3 = theme().Accent })
                playClick(0.2)
            end
        end)

        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if listening then
                if input.KeyCode == Enum.KeyCode.Unknown then return end
                if input.KeyCode == Enum.KeyCode.Escape then
                    listening = false
                    display.Text = current and current.Name or "None"
                    tween(display, T_FAST, { BackgroundColor3 = theme().SurfaceHover })
                    return
                end
                current = input.KeyCode
                display.Text = current.Name
                tween(display, T_FAST, { BackgroundColor3 = theme().SurfaceHover })
                listening = false
                return
            end
            if current and input.KeyCode == current then
                callback()
            end
        end)

        addTooltip(row, opts2.Tooltip)
        return El
    end

    -- ColorPicker
    function SectionProto:CreateColorPicker(text, default, callback, opts2)
        local th = theme()
        opts2 = opts2 or {}
        callback = callback or function() end
        local color = default or Color3.fromRGB(255, 255, 255)

        local row, lbl = createElementRow(self._holder, text, 38)
        applyHover(row, th.Element, th.ElementHover, 1)

        local swatch = Instance.new("TextButton")
        swatch.Name = "Swatch"
        swatch.AnchorPoint = Vector2.new(1, 0.5)
        swatch.Position = UDim2.new(1, -10, 0.5, 0)
        swatch.Size = UDim2.new(0, 30, 0, 22)
        swatch.BackgroundColor3 = color
        swatch.Text = ""
        swatch.AutoButtonColor = false
        swatch.ZIndex = 14
        swatch.Parent = row
        corner(swatch, 6)
        stroke(swatch, th.Stroke, 1, 0)

        local El = {}
        function El:Set(c, fire)
            color = c
            tween(swatch, T_FAST, { BackgroundColor3 = c })
            if fire == true then callback(c) end
        end
        function El:Get() return color end

        local popup
        local popupOpen = false

        local function buildPopup()
            if popup then popup:Destroy() end
            local t = theme()
            local hue, sat, val = Color3.toHSV(color)

            popup = Instance.new("Frame")
            popup.Name = "ColorPopup"
            popup.AnchorPoint = Vector2.new(1, 0)
            popup.Position = UDim2.new(1, -10, 1, 6)
            popup.Size = UDim2.new(0, 220, 0, 200)
            popup.BackgroundColor3 = t.Surface
            popup.ZIndex = 40
            popup.Parent = row
            corner(popup, 8)
            local _stroke_popup = stroke(popup, t.StrokeStrong, 1, 0)
            bindColor(popup, "BackgroundColor3", "Surface")
            bindColor(_stroke_popup, "Color", "StrokeStrong")

            local svArea = Instance.new("TextButton")
            svArea.Name = "SV"
            svArea.Position = UDim2.new(0, 8, 0, 8)
            svArea.Size = UDim2.new(1, -16, 0, 120)
            svArea.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
            svArea.Text = ""
            svArea.AutoButtonColor = false
            svArea.ZIndex = 41
            svArea.Parent = popup
            corner(svArea, 6)

            local svGrad = Instance.new("UIGradient")
            svGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
            })
            svGrad.Parent = svArea

            local svVert = Instance.new("UIGradient")
            svVert.Rotation = 90
            svVert.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            svVert.Parent = svArea

            local cursor = Instance.new("Frame")
            cursor.Name = "Cursor"
            cursor.AnchorPoint = Vector2.new(0.5, 0.5)
            cursor.Size = UDim2.new(0, 8, 0, 8)
            cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            cursor.BorderSizePixel = 0
            cursor.ZIndex = 42
            cursor.Parent = svArea
            corner(cursor, 4)
            stroke(cursor, Color3.fromRGB(0, 0, 0), 1, 0)
            cursor.Position = UDim2.new(sat, 0, 1 - val, 0)

            local svDragging = false
            local function svUpdate(input)
                local relX = math.clamp((input.Position.X - svArea.AbsolutePosition.X) / svArea.AbsoluteSize.X, 0, 1)
                local relY = math.clamp((input.Position.Y - svArea.AbsolutePosition.Y) / svArea.AbsoluteSize.Y, 0, 1)
                sat = relX
                val = 1 - relY
                color = Color3.fromHSV(hue, sat, val)
                swatch.BackgroundColor3 = color
                cursor.Position = UDim2.new(sat, 0, 1 - val, 0)
                callback(color)
            end
            svArea.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = true
                    svUpdate(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if svDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    svUpdate(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    svDragging = false
                end
            end)

            local hueBar = Instance.new("TextButton")
            hueBar.Name = "Hue"
            hueBar.Position = UDim2.new(0, 8, 0, 140)
            hueBar.Size = UDim2.new(1, -16, 0, 12)
            hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueBar.Text = ""
            hueBar.AutoButtonColor = false
            hueBar.ZIndex = 41
            hueBar.Parent = popup
            corner(hueBar, 6)

            local hueGrad = Instance.new("UIGradient")
            hueGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0/6, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1/6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2/6, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(3/6, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(4/6, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(5/6, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            })
            hueGrad.Parent = hueBar

            local hueCursor = Instance.new("Frame")
            hueCursor.Name = "HueCursor"
            hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hueCursor.Size = UDim2.new(0, 6, 0, 16)
            hueCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            hueCursor.BorderSizePixel = 0
            hueCursor.ZIndex = 42
            hueCursor.Parent = hueBar
            corner(hueCursor, 3)
            stroke(hueCursor, Color3.fromRGB(0, 0, 0), 1, 0)
            hueCursor.Position = UDim2.new(hue, 0, 0.5, 0)

            local hueDragging = false
            local function hueUpdate(input)
                local rel = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                hue = rel
                svArea.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                hueCursor.Position = UDim2.new(rel, 0, 0.5, 0)
                color = Color3.fromHSV(hue, sat, val)
                swatch.BackgroundColor3 = color
                callback(color)
            end
            hueBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    hueDragging = true
                    hueUpdate(input)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if hueDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    hueUpdate(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    hueDragging = false
                end
            end)

            local hex = Instance.new("TextBox")
            hex.Name = "Hex"
            hex.Position = UDim2.new(0, 8, 0, 164)
            hex.Size = UDim2.new(1, -16, 0, 26)
            hex.BackgroundColor3 = t.Element
            hex.Font = Enum.Font.GothamMedium
            hex.TextSize = 12
            hex.TextColor3 = t.Text
            hex.Text = string.format("#%02X%02X%02X", math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255))
            hex.TextXAlignment = Enum.TextXAlignment.Center
            hex.ClearTextOnFocus = false
            hex.ZIndex = 41
            hex.Parent = popup
            corner(hex, 6)
            bindColor(hex, "BackgroundColor3", "Element")
            bindColor(hex, "TextColor3", "Text")

            hex.FocusLost:Connect(function()
                local txt = hex.Text:gsub("#", ""):gsub(" ", "")
                if #txt == 6 then
                    local r = tonumber(txt:sub(1, 2), 16)
                    local g = tonumber(txt:sub(3, 4), 16)
                    local b = tonumber(txt:sub(5, 6), 16)
                    if r and g and b then
                        El:Set(Color3.fromRGB(r, g, b), true)
                        buildPopup()
                    end
                end
            end)
        end

        swatch.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                playClick(0.2)
                if popupOpen then
                    if popup then popup:Destroy(); popup = nil end
                    popupOpen = false
                else
                    buildPopup()
                    popupOpen = true
                end
            end
        end)
        UserInputService.InputBegan:Connect(function(input)
            if popupOpen and input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mouse = UserInputService:GetMouseLocation()
                if popup then
                    local p = popup.AbsolutePosition
                    local s = popup.AbsoluteSize
                    if mouse.X < p.X or mouse.X > p.X + s.X or mouse.Y < p.Y or mouse.Y > p.Y + s.Y then
                        if not (mouse.X >= swatch.AbsolutePosition.X and mouse.X <= swatch.AbsolutePosition.X + swatch.AbsoluteSize.X
                            and mouse.Y >= swatch.AbsolutePosition.Y and mouse.Y <= swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y) then
                            popup:Destroy()
                            popup = nil
                            popupOpen = false
                        end
                    end
                end
            end
        end)

        addTooltip(row, opts2.Tooltip)
        if opts2.Flag then
            Window:_RegisterConfig(opts2.Flag, function()
                return { R = color.R, G = color.G, B = color.B }
            end, function(v)
                if typeof(v) == "table" then
                    El:Set(Color3.new(v.R or 0, v.G or 0, v.B or 0), false)
                else
                    El:Set(v, false)
                end
            end)
        end
        return El
    end

    -- TextBox
    function SectionProto:CreateTextBox(text, placeholder, callback, opts2)
        local th = theme()
        opts2 = opts2 or {}
        callback = callback or function() end

        local row, lbl = createElementRow(self._holder, text, 38)
        applyHover(row, th.Element, th.ElementHover, 1)

        local input = Instance.new("TextBox")
        input.Name = "Input"
        input.AnchorPoint = Vector2.new(1, 0.5)
        input.Position = UDim2.new(1, -10, 0.5, 0)
        input.Size = UDim2.new(0, 160, 0, 26)
        input.BackgroundColor3 = th.SurfaceHover
        input.Font = Enum.Font.GothamMedium
        input.TextSize = 12
        input.TextColor3 = th.Text
        input.PlaceholderColor3 = th.TextMuted
        input.PlaceholderText = placeholder or "..."
        input.Text = ""
        input.TextXAlignment = Enum.TextXAlignment.Left
        input.ClearTextOnFocus = false
        input.ZIndex = 14
        input.Parent = row
        corner(input, 6)
        padding(input, 8, 0, 8, 0)
        bindColor(input, "BackgroundColor3", "SurfaceHover")
        bindColor(input, "TextColor3", "Text")
        bindColor(input, "PlaceholderColor3", "TextMuted")

        local El = {}
        function El:Set(v, fire)
            input.Text = v or ""
            if fire == true then callback(input.Text) end
        end
        function El:Get() return input.Text end

        input.FocusLost:Connect(function()
            playClick(0.15)
            callback(input.Text)
        end)

        addTooltip(row, opts2.Tooltip)
        if opts2.Flag then
            Window:_RegisterConfig(opts2.Flag, function() return input.Text end, function(v) El:Set(v, false) end)
        end
        return El
    end

    -- Image
    function SectionProto:CreateImage(assetId, size)
        local th = theme()
        assetId = assetId or ""
        size = size or UDim2.new(0, 200, 0, 120)

        local img = Instance.new("ImageLabel")
        img.Name = "Image"
        img.Image = assetId
        img.Size = size
        img.BackgroundColor3 = th.Element
        img.ZIndex = 12
        img.Parent = self._holder
        corner(img, 8)
        local _stroke_img = stroke(img, th.Stroke, 1, 0)
        bindColor(img, "BackgroundColor3", "Element")
        bindColor(_stroke_img, "Color", "Stroke")

        local El = {}
        function El:Set(newAsset, newSize)
            if newAsset then img.Image = newAsset end
            if newSize then img.Size = newSize end
        end
        function El:Get() return img.Image, img.Size end
        return El
    end

    --========================
    -- Tab prototype
    --========================
    local TabProto = {}
    TabProto.__index = TabProto

    function TabProto:CreateSection(title)
        local th = theme()
        local section = Instance.new("Frame")
        section.Name = "Section_" .. sanitize(title)
        section.BackgroundColor3 = th.Element
        section.Size = UDim2.new(1, 0, 0, 0)
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.ZIndex = 12
        section.Parent = self._container
        corner(section, 8)
        local _stroke_section = stroke(section, th.Stroke, 1, 0)
        bindColor(section, "BackgroundColor3", "Element")
        bindColor(_stroke_section, "Color", "Stroke")

        local header = Instance.new("TextLabel")
        header.BackgroundTransparency = 1
        header.Font = Enum.Font.GothamBold
        header.Text = title
        header.TextColor3 = th.Text
        header.TextSize = 13
        header.TextXAlignment = Enum.TextXAlignment.Left
        header.Size = UDim2.new(1, -24, 0, 18)
        header.Position = UDim2.new(0, 12, 0, 12)
        header.ZIndex = 13
        header.Parent = section
        bindColor(header, "TextColor3", "Text")

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.BackgroundColor3 = th.Accent
        accent.Size = UDim2.new(0, 3, 0, 14)
        accent.Position = UDim2.new(0, 0, 0, 13)
        accent.BorderSizePixel = 0
        accent.ZIndex = 13
        accent.Parent = section
        corner(accent, 2)
        bindColor(accent, "BackgroundColor3", "Accent")

        local elementsHolder = Instance.new("Frame")
        elementsHolder.Name = "Elements"
        elementsHolder.BackgroundTransparency = 1
        elementsHolder.Position = UDim2.new(0, 12, 0, 38)
        elementsHolder.Size = UDim2.new(1, -24, 0, 0)
        elementsHolder.AutomaticSize = Enum.AutomaticSize.Y
        elementsHolder.ZIndex = 12
        elementsHolder.Parent = section

        local eLayout = Instance.new("UIListLayout")
        eLayout.SortOrder = Enum.SortOrder.LayoutOrder
        eLayout.Padding = UDim.new(0, 6)
        eLayout.Parent = elementsHolder

        local self2 = setmetatable({
            _holder = elementsHolder,
            _section = section,
            _window = Window,
            Title = title,
        }, SectionProto)
        return self2
    end

    --========================
    -- Tab switching
    --========================
    local function selectTab(tab)
        if Window.ActiveTab == tab then return end
        local th = theme()
        if Window.ActiveTab then
            Window.ActiveTab._container.Visible = false
            tween(Window.ActiveTab._button, T_FAST, { BackgroundColor3 = th.Element })
            tween(Window.ActiveTab._label, T_FAST, { TextColor3 = th.TextMuted })
            if Window.ActiveTab._icon then
                tween(Window.ActiveTab._icon, T_FAST, { ImageColor3 = th.TextMuted })
            end
        end
        Window.ActiveTab = tab
        tab._container.Visible = true
        tween(tab._button, T_FAST, { BackgroundColor3 = th.TabActive })
        tween(tab._label, T_FAST, { TextColor3 = th.Text })
        if tab._icon then
            tween(tab._icon, T_FAST, { ImageColor3 = th.Accent })
        end
        playClick(0.15)
    end

    --========================
    -- Window:CreateTab
    --========================
    function Window:CreateTab(opts2)
        local th = theme()
        opts2 = (typeof(opts2) == "string") and { Name = opts2 } or (opts2 or {})
        local name = opts2.Name or "Tab"
        local icon = opts2.Icon
        local tip  = opts2.Tooltip

        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. sanitize(name)
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = th.Element
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 13
        btn.Parent = tabListParent
        corner(btn, 8)
        bindColor(btn, "BackgroundColor3", "Element")
        applyHover(btn, th.Element, th.ElementHover, 0.98)

        local lbl
        local iconRef
        if icon then
            iconRef = Instance.new("ImageLabel")
            iconRef.BackgroundTransparency = 1
            iconRef.Size = UDim2.new(0, 18, 0, 18)
            iconRef.Position = UDim2.new(0, 8, 0.5, -9)
            iconRef.Image = icon
            iconRef.ImageColor3 = th.TextMuted
            iconRef.ZIndex = 14
            iconRef.Parent = btn
            bindColor(iconRef, "ImageColor3", "TextMuted")

            lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamMedium
            lbl.Text = name
            lbl.TextColor3 = th.TextMuted
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Position = UDim2.new(0, 34, 0, 0)
            lbl.Size = UDim2.new(1, -34, 1, 0)
            lbl.ZIndex = 14
            lbl.Parent = btn
            bindColor(lbl, "TextColor3", "TextMuted")
        else
            lbl = Instance.new("TextLabel")
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.GothamMedium
            lbl.Text = name
            lbl.TextColor3 = th.TextMuted
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Position = UDim2.new(0, 10, 0, 0)
            lbl.Size = UDim2.new(1, -10, 1, 0)
            lbl.ZIndex = 14
            lbl.Parent = btn
            bindColor(lbl, "TextColor3", "TextMuted")
        end

        local container = Instance.new("Frame")
        container.Name = "TabContent_" .. sanitize(name)
        container.BackgroundTransparency = 1
        container.Size = UDim2.new(1, 0, 1, 0)
        container.Visible = false
        container.ZIndex = 12
        container.Parent = contentScroll

        local cLayout = Instance.new("UIListLayout")
        cLayout.SortOrder = Enum.SortOrder.LayoutOrder
        cLayout.Padding = UDim.new(0, 10)
        cLayout.Parent = container

        local self = setmetatable({
            _button = btn,
            _label = lbl,
            _icon = iconRef,
            _container = container,
            _layout = cLayout,
            Name = name,
            Sections = {},
        }, TabProto)

        btn.MouseButton1Click:Connect(function()
            selectTab(self)
        end)

        if tip then
            btn.MouseEnter:Connect(function() tooltipCtrl:Show(tip) end)
            btn.MouseLeave:Connect(function() tooltipCtrl:Hide() end)
        end

        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local q = searchBox.Text:lower()
                if q == "" then
                    btn.Visible = true
                else
                    btn.Visible = (name:lower():find(q, 1, true) ~= nil)
                end
            end)
        end

        table.insert(Window.Tabs, self)

        if not Window.ActiveTab then
            selectTab(self)
        end

        return self
    end

    --========================
    -- Window config registry
    --========================
    function Window:_RegisterConfig(flag, getValue, setValue)
        self.ConfigElements[flag] = { Get = getValue, Set = setValue }
    end

    --========================
    -- Window methods
    --========================
    function Window:SelectTab(tab)
        for _, t in ipairs(self.Tabs) do
            if t == tab or t.Name == tab then
                selectTab(t)
                return
            end
        end
    end

    function Window:Toggle()
        self._visible = not self._visible
        if self._visible then
            window.Visible = true
            tween(winScale, T, { Scale = 1 })
            tween(window, T, { BackgroundTransparency = self._transparency })
        else
            tween(winScale, T, { Scale = 0.9 })
            tween(window, T, { BackgroundTransparency = 1 })
            _task.delay(T + 0.02, function()
                if not self._visible then window.Visible = false end
            end)
        end
    end

    function Window:SetTransparency(amount)
        amount = math.clamp(amount, 0, 1)
        self._transparency = amount
        tween(window, T, { BackgroundTransparency = amount })
        tween(titleBar, T, { BackgroundTransparency = amount })
        tween(contentArea, T, { BackgroundTransparency = amount })
        if not mobile then tween(sidebar, T, { BackgroundTransparency = amount }) end
    end

    function Window:Notify(opts)
        notifStack.theme = self.Theme
        notifStack:Push(opts)
    end

    function Window:Prompt(opts)
        opts = opts or {}
        local th = self.Theme
        local title = opts.Title or "Prompt"
        local text  = opts.Text or ""
        local buttons = opts.Buttons or { { Text = "OK", Callback = function() end } }

        local overlay = Instance.new("TextButton")
        overlay.Name = "Overlay"
        overlay.Size = UDim2.new(1, 0, 1, 0)
        overlay.BackgroundColor3 = th.Overlay
        overlay.BackgroundTransparency = 1
        overlay.Text = ""
        overlay.AutoButtonColor = false
        overlay.ZIndex = 90
        overlay.Parent = gui

        local modal = Instance.new("Frame")
        modal.Name = "Modal"
        modal.AnchorPoint = Vector2.new(0.5, 0.5)
        modal.Position = UDim2.new(0.5, 0, 0.5, 0)
        modal.Size = UDim2.new(0, 380, 0, 0)
        modal.BackgroundColor3 = th.Surface
        modal.ZIndex = 91
        modal.Parent = overlay
        corner(modal, 10)
        local _stroke_modal = stroke(modal, th.StrokeStrong, 1, 0)
        bindColor(modal, "BackgroundColor3", "Surface")
        bindColor(_stroke_modal, "Color", "StrokeStrong")

        local titleL = Instance.new("TextLabel")
        titleL.BackgroundTransparency = 1
        titleL.Font = Enum.Font.GothamBold
        titleL.Text = title
        titleL.TextColor3 = th.Text
        titleL.TextSize = 15
        titleL.TextXAlignment = Enum.TextXAlignment.Left
        titleL.Position = UDim2.new(0, 16, 0, 16)
        titleL.Size = UDim2.new(1, -32, 0, 18)
        titleL.ZIndex = 92
        titleL.Parent = modal
        bindColor(titleL, "TextColor3", "Text")

        local bodyL = Instance.new("TextLabel")
        bodyL.BackgroundTransparency = 1
        bodyL.Font = Enum.Font.Gotham
        bodyL.Text = text
        bodyL.TextColor3 = th.TextMuted
        bodyL.TextSize = 13
        bodyL.TextWrapped = true
        bodyL.TextXAlignment = Enum.TextXAlignment.Left
        bodyL.Position = UDim2.new(0, 16, 0, 42)
        bodyL.Size = UDim2.new(1, -32, 0, 40)
        bodyL.ZIndex = 92
        bodyL.Parent = modal
        bindColor(bodyL, "TextColor3", "TextMuted")

        local btnHolder = Instance.new("Frame")
        btnHolder.BackgroundTransparency = 1
        btnHolder.AnchorPoint = Vector2.new(0, 1)
        btnHolder.Position = UDim2.new(0, 12, 1, -12)
        btnHolder.Size = UDim2.new(1, -24, 0, 32)
        btnHolder.ZIndex = 92
        btnHolder.Parent = modal

        local blayout = Instance.new("UIListLayout")
        blayout.FillDirection = Enum.FillDirection.Horizontal
        blayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        blayout.Padding = UDim.new(0, 8)
        blayout.Parent = btnHolder

        local function close()
            tween(modal, T, { Size = UDim2.new(0, 380, 0, 0) })
            tween(overlay, T, { BackgroundTransparency = 1 })
            _task.delay(T + 0.02, function() overlay:Destroy() end)
        end

        for _, b in ipairs(buttons) do
            local bb = Instance.new("TextButton")
            bb.Size = UDim2.new(0, 90, 0, 32)
            bb.BackgroundColor3 = th.Element
            bb.Text = b.Text or "OK"
            bb.Font = Enum.Font.GothamMedium
            bb.TextSize = 13
            bb.TextColor3 = th.Text
            bb.AutoButtonColor = false
            bb.ZIndex = 93
            bb.Parent = btnHolder
            corner(bb, 6)
            bindColor(bb, "BackgroundColor3", "Element")
            bindColor(bb, "TextColor3", "Text")
            applyHover(bb, th.Element, th.ElementHover, 0.96)
            bb.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    playClick(0.2)
                    if b.Callback then b.Callback() end
                    close()
                end
            end)
        end

        tween(overlay, T, { BackgroundTransparency = 0.5 })
        tween(modal, T, { Size = UDim2.new(0, 380, 0, 160) })
    end

    function Window:SetTheme(name)
        local newTheme = Themes[name]
        if not newTheme then return end
        self.Theme = newTheme
        self.ThemeName = name
        notifStack.theme = newTheme
        for _, b in ipairs(colorBindings) do
            local target = newTheme[b.Key]
            if target then
                tween(b.Instance, T, { [b.Property] = target })
            end
        end
    end

    function Window:GetThemes()
        local list = {}
        for k in pairs(Themes) do table.insert(list, k) end
        table.sort(list)
        return list
    end

    function Window:GetTheme()
        return self.Theme
    end

    function Window:SetColor(key, color)
        if not self.Theme[key] then return end
        self.Theme[key] = color
        for _, b in ipairs(colorBindings) do
            if b.Key == key then
                tween(b.Instance, T, { [b.Property] = color })
            end
        end
    end

    function Window:GetConfigs()
        safeMakeFolder(self.ConfigFolder)
        local files = safeList(self.ConfigFolder)
        local list = {}
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
        table.sort(list)
        return list
    end

    function Window:SaveConfig(name)
        if not name or name == "" then return end
        safeMakeFolder(self.ConfigFolder)
        local data = {}
        for flag, el in pairs(self.ConfigElements) do
            local v = el.Get()
            if typeof(v) == "Color3" then
                v = { R = v.R, G = v.G, B = v.B }
            end
            data[flag] = v
        end
        local json = HttpService:JSONEncode(data)
        safeWrite(self.ConfigFolder .. "/" .. sanitize(name) .. ".json", json)
        self:Notify({ Title = "Config Saved", Text = name, Duration = 3 })
    end

    function Window:LoadConfig(name)
        if not name or name == "" then return end
        local content = safeRead(self.ConfigFolder .. "/" .. sanitize(name) .. ".json")
        if not content then
            self:Notify({ Title = "Error", Text = "Config not found", Duration = 3 })
            return
        end
        local ok, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not ok or type(data) ~= "table" then
            self:Notify({ Title = "Error", Text = "Config corrupted", Duration = 3 })
            return
        end
        for flag, value in pairs(data) do
            local el = self.ConfigElements[flag]
            if el then el.Set(value) end
        end
        self:Notify({ Title = "Config Loaded", Text = name, Duration = 3 })
    end

    function Window:DeleteConfig(name)
        if not name or name == "" then return end
        safeDelete(self.ConfigFolder .. "/" .. sanitize(name) .. ".json")
        self:Notify({ Title = "Config Deleted", Text = name, Duration = 3 })
    end

    function Window:Destroy()
        tween(winScale, T, { Scale = 0.9 })
        tween(window, T, { BackgroundTransparency = 1 })
        tween(_stroke_window, T, { Transparency = 1 })
        _task.delay(T + 0.05, function()
            gui:Destroy()
        end)
    end

    --========================
    -- Wiring: toggle key + close button
    --========================
    if Window.ToggleKey then
        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Window.ToggleKey then
                Window:Toggle()
            end
        end)
    end

    closeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            Window:Toggle()
        end
    end)

    --========================
    -- Welcome notification
    --========================
    _task.delay(0.4, function()
        notifStack:Push({
            Title = opts.Brand or "AetherUI",
            Text = "Loaded. Press " .. (Window.ToggleKey and Window.ToggleKey.Name or "None") .. " to toggle.",
            Duration = 4,
        })
    end)

    return Window
end

--================================================================
-- Public helpers
--================================================================
function AetherUI:GetPlatform()
    return IsMobile and "Mobile" or "PC"
end

function AetherUI:AddTheme(name, themeTable)
    Themes[name] = themeTable
end

--================================================================
-- Return the library (loadstring(...)() returns this)
--================================================================
return AetherUI
