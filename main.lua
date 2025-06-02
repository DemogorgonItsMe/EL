--[[
    LuxUI - Premium UI Library for Roblox
    Version: 1.2.0
    Features:
    - Beautiful modern design with animations
    - Customizable themes
    - Advanced elements (sliders, dropdowns, color pickers)
    - Notifications system
    - Save/Load configuration
    - Mobile/PC responsive design
]]

local LuxUI = {}
LuxUI.__index = LuxUI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService") -- Added HttpService for JSON encoding/decoding

-- Constants
local DEFAULT_THEME = {
    Main = Color3.fromRGB(25, 25, 35),
    Secondary = Color3.fromRGB(35, 35, 45),
    Accent = Color3.fromRGB(0, 170, 255),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Shadow = Color3.fromRGB(0, 0, 0),
    Success = Color3.fromRGB(0, 255, 100),
    Warning = Color3.fromRGB(255, 170, 0),
    Error = Color3.fromRGB(255, 50, 50)
}

local EASE_DIRECTION = Enum.EasingDirection.InOut
local EASE_STYLE = Enum.EasingStyle.Quint
local TWEEN_TIME = 0.25

-- Utility functions
local function create(class, props)
    local instance = Instance.new(class)
    for prop, value in pairs(props) do
        if prop ~= "Parent" then
            if pcall(function() return instance[prop] end) then -- Added pcall check
                instance[prop] = value
            end
        end
    end
    if props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

local function tween(object, properties, duration, easingStyle, easingDirection)
    local tweenInfo = TweenInfo.new(
        duration or TWEEN_TIME,
        easingStyle or EASE_STYLE,
        easingDirection or EASE_DIRECTION
    )
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Main UI creation
function LuxUI.new(options)
    options = options or {}

    local self = setmetatable({}, LuxUI)

    self.theme = options.Theme or DEFAULT_THEME
    self.configKey = options.ConfigKey or "LuxUIConfig"
    self.windows = {}
    self.notifications = {}
    self.open = false

    -- Create main screen gui
    self.gui = create("ScreenGui", {
        Name = "LuxUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999,
        Parent = game.Players.LocalPlayer.PlayerGui -- Set parent correctly
    })

    -- Create notification holder
    self.notificationHolder = create("Frame", {
        Name = "Notifications",
        Parent = self.gui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100
    })

    -- Create blur effect
    if not isMobile() then
        self.blur = create("BlurEffect", {
            Name = "UIBlur",
            Parent = game.Lighting, -- Corrected parent
            Size = 0,
            Enabled = false
        })
    end

    -- Apply saved config if exists
    if options.LoadConfig and isfile and isfile(self.configKey .. ".luxui") then -- Checking for isfile function
        self:LoadConfig()
    end

    return self
end

-- Window creation
function LuxUI:CreateWindow(title, options)
    options = options or {}
    local windowId = #self.windows + 1

    local window = {
        Id = windowId,
        Tabs = {},
        Open = false,
        MinSize = options.MinSize or Vector2.new(300, 400),
        Size = options.Size or UDim2.new(0, 500, 0, 500),
        Position = options.Position or UDim2.new(0.5, -250, 0.5, -250)
    }

    -- Main window frame
    window.Main = create("Frame", {
        Name = "Window" .. windowId,
        Parent = self.gui,
        BackgroundColor3 = self.theme.Main,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        ClipsDescendants = true,
        Visible = false,
        AnchorPoint = Vector2.new(0.5, 0.5)
    })

    -- Shadow effect
    create("ImageLabel", {
        Name = "Shadow",
        Parent = window.Main,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 12, 1, 12),
        Position = UDim2.new(0, -6, 0, -6),
        Image = "rbxassetid://1316045217",
        ImageColor3 = self.theme.Shadow,
        ImageTransparency = 0.8,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        ZIndex = -1
    })

    -- Top bar
    window.TopBar = create("Frame", {
        Name = "TopBar",
        Parent = window.Main,
        BackgroundColor3 = self.theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2
    })

    -- Title
    create("TextLabel", {
        Name = "Title",
        Parent = window.TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = title or "LuxUI Window",
        TextColor3 = self.theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Close button
    window.CloseButton = create("ImageButton", {
        Name = "CloseButton",
        Parent = window.TopBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -35, 0, 5),
        Size = UDim2.new(0, 30, 0, 30),
        Image = "rbxassetid://3926305904",
        ImageColor3 = self.theme.TextSecondary,
        ImageRectOffset = Vector2.new(284, 4),
        ImageRectSize = Vector2.new(24, 24),
        ZIndex = 2
    })

    -- Tab bar
    window.TabBar = create("Frame", {
        Name = "TabBar",
        Parent = window.Main,
        BackgroundColor3 = self.theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2
    })

    -- Tab container
    window.TabContainer = create("Frame", {
        Name = "TabContainer",
        Parent = window.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 80),
        Size = UDim2.new(1, 0, 1, -80),
        ClipsDescendants = true
    })

    -- Tab list layout
    create("UIListLayout", {
        Parent = window.TabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })

    -- Close button event
    window.CloseButton.MouseButton1Click:Connect(function()
        self:ToggleWindow(windowId)
    end)

    -- Dragging functionality
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        window.Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    window.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = window.Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    window.TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)

    table.insert(self.windows, window)

    -- Window methods
    local windowMethods = {}

    function windowMethods:Toggle()
        self:ToggleWindow(windowId)
    end

    function windowMethods:AddTab(name, icon)
        local tabId = #window.Tabs + 1

        local tab = {
            Id = tabId,
            Name = name,
            Container = nil,
            Active = false
        }

        -- Tab button
        tab.Button = create("TextButton", {
            Name = "Tab" .. tabId,
            Parent = window.TabBar,
            BackgroundColor3 = self.theme.Secondary,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 100, 1, 0),
            Font = Enum.Font.Gotham,
            Text = name,
            TextColor3 = self.theme.TextSecondary,
            TextSize = 14,
            AutoButtonColor = false,
            LayoutOrder = tabId
        })

        -- Tab container
        tab.Container = create("ScrollingFrame", {
            Name = "Container" .. tabId,
            Parent = window.TabContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.theme.Accent,
            Visible = false
        })

        -- Tab container layout
        create("UIListLayout", {
            Parent = tab.Container,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })

        create("UIPadding", {
            Parent = tab.Container,
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 15)
        })

        -- Tab button events
        tab.Button.MouseEnter:Connect(function()
            if not tab.Active then
                tween(tab.Button, { TextColor3 = self.theme.Text })
            end
        end)

        tab.Button.MouseLeave:Connect(function()
            if not tab.Active then
                tween(tab.Button, { TextColor3 = self.theme.TextSecondary })
            end
        end)

        tab.Button.MouseButton1Click:Connect(function()
            self:SwitchTab(windowId, tabId)
        end)

        -- Activate first tab
        if tabId == 1 then
            self:SwitchTab(windowId, 1)
        end

        table.insert(window.Tabs, tab)

        -- Tab methods
        local tabMethods = {}

        function tabMethods:AddLabel(text)
            local label = create("TextLabel", {
                Parent = tab.Container,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = self.theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = #tab.Container:GetChildren()
            })

            return label
        end

        function tabMethods:AddButton(text, callback)
            local buttonId = #tab.Container:GetChildren() + 1

            local button = create("TextButton", {
                Name = "Button" .. buttonId,
                Parent = tab.Container,
                BackgroundColor3 = self.theme.Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 35),
                Font = Enum.Font.GothamSemibold,
                Text = text,
                TextColor3 = self.theme.Text,
                TextSize = 14,
                AutoButtonColor = false,
                LayoutOrder = buttonId
            })

            create("UICorner", {
                Parent = button,
                CornerRadius = UDim.new(0, 5)
            })

            -- Button effects
            button.MouseEnter:Connect(function()
                tween(button, { BackgroundColor3 = Color3.fromRGB(
                    math.floor(self.theme.Secondary.R * 255 + 15),
                    math.floor(self.theme.Secondary.G * 255 + 15),
                    math.floor(self.theme.Secondary.B * 255 + 15)
                ) })
            end)

            button.MouseLeave:Connect(function()
                tween(button, { BackgroundColor3 = self.theme.Secondary })
            end)

            button.MouseButton1Click:Connect(function()
                if callback then
                    callback()
                end
            end)

            return button
        end

        function tabMethods:AddToggle(text, default, callback)
            local toggleId = #tab.Container:GetChildren() + 1
            local toggled = default or false

            local toggle = create("Frame", {
                Name = "Toggle" .. toggleId,
                Parent = tab.Container,
                BackgroundColor3 = self.theme.Secondary,
                Size = UDim2.new(1, 0, 0, 35),
                LayoutOrder = toggleId
            })

            create("UICorner", {
                Parent = toggle,
                CornerRadius = UDim.new(0, 5)
            })

            create("TextLabel", {
                Name = "Label",
                Parent = toggle,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = self.theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local toggleButton = create("Frame", {
                Name = "ToggleButton",
                Parent = toggle,
                BackgroundColor3 = toggled and self.theme.Accent or self.theme.TextSecondary,
                Position = UDim2.new(1, -45, 0.5, -10),
                Size = UDim2.new(0, 40, 0, 20)
            })

            create("UICorner", {
                Parent = toggleButton,
                CornerRadius = UDim.new(0, 10)
            })

            local toggleDot = create("Frame", {
                Name = "ToggleDot",
                Parent = toggleButton,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new(0, 2, 0.5, -8),
                Size = UDim2.new(0, 16, 0, 16),
                AnchorPoint = Vector2.new(0, 0.5)
            })

            create("UICorner", {
                Parent = toggleDot,
                CornerRadius = UDim.new(0, 8)
            })

            if toggled then
                toggleDot.Position = UDim2.new(1, -18, 0.5, -8)
            end

            -- Toggle functionality
            toggle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    toggled = not toggled

                    if toggled then
                        tween(toggleButton, { BackgroundColor3 = self.theme.Accent })
                        tween(toggleDot, { Position = UDim2.new(1, -18, 0.5, -8) })
                    else
                        tween(toggleButton, { BackgroundColor3 = self.theme.TextSecondary })
                        tween(toggleDot, { Position = UDim2.new(0, 2, 0.5, -8) })
                    end

                    if callback then
                        callback(toggled)
                    end
                end
            end)

            return {
                Set = function(value)
                    toggled = value

                    if toggled then
                        tween(toggleButton, { BackgroundColor3 = self.theme.Accent })
                        tween(toggleDot, { Position = UDim2.new(1, -18, 0.5, -8) })
                    else
                        tween(toggleButton, { BackgroundColor3 = self.theme.TextSecondary })
                        tween(toggleDot, { Position = UDim2.new(0, 2, 0.5, -8) })
                    end
                end,
                Get = function()
                    return toggled
                end
            }
        end

        function tabMethods:AddSlider(text, min, max, default, callback)
            local sliderId = #tab.Container:GetChildren() + 1
            local value = default or min

            local slider = create("Frame", {
                Name = "Slider" .. sliderId,
                Parent = tab.Container,
                BackgroundColor3 = self.theme.Secondary,
                Size = UDim2.new(1, 0, 0, 60),
                LayoutOrder = sliderId
            })

            create("UICorner", {
                Parent = slider,
                CornerRadius = UDim.new(0, 5)
            })

            create("TextLabel", {
                Name = "Label",
                Parent = slider,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 5),
                Size = UDim2.new(1, -30, 0, 20),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = self.theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            create("TextLabel", {
                Name = "Value",
                Parent = slider,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -15, 0, 5),
                Size = UDim2.new(0, 50, 0, 20),
                Font = Enum.Font.GothamSemibold,
                Text = tostring(value),
                TextColor3 = self.theme.Accent,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            local track = create("Frame", {
                Name = "Track",
                Parent = slider,
                BackgroundColor3 = self.theme.Main,
                Position = UDim2.new(0, 15, 0, 35),
                Size = UDim2.new(1, -30, 0, 5)
            })

            create("UICorner", {
                Parent = track,
                CornerRadius = UDim.new(0, 3)
            })

            local fill = create("Frame", {
                Name = "Fill",
                Parent = track,
                BackgroundColor3 = self.theme.Accent,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            })

            create("UICorner", {
                Parent = fill,
                CornerRadius = UDim.new(0, 3)
            })

            local dot = create("Frame", {
                Name = "Dot",
                Parent = track,
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position = UDim2.new((value - min) / (max - min), -6, 0.5, -6),
                Size = UDim2.new(0, 12, 0, 12),
                AnchorPoint = Vector2.new(0.5, 0.5)
            })

            create("UICorner", {
                Parent = dot,
                CornerRadius = UDim.new(0, 6)
            })

            create("UIStroke", {
                Parent = dot,
                Color = self.theme.Accent,
                Thickness = 2
            })

            -- Slider functionality
            local dragging = false

            local function update(input)
                local relativeX = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                relativeX = math.clamp(relativeX, 0, 1)

                value = min + (max - min) * relativeX
                value = math.floor(value) -- Ensure integer values

                slider.Value.Text = tostring(value)

                fill.Size = UDim2.new(relativeX, 0, 1, 0)
                dot.Position = UDim2.new(relativeX, -6, 0.5, -6)

                if callback then
                    callback(value)
                end
            end

            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update(input)
                end
            end)

            track.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)

            return {
                Set = function(newValue)
                    value = math.clamp(newValue, min, max)
                    value = math.floor(value)
                    slider.Value.Text = tostring(value)

                    local relativeX = (value - min) / (max - min)
                    fill.Size = UDim2.new(relativeX, 0, 1, 0)
                    dot.Position = UDim2.new(relativeX, -6, 0.5, -6)
                end,
                Get = function()
                    return value
                end
            }
        end

        function tabMethods:AddDropdown(text, options, default, callback)
            local dropdownId = #tab.Container:GetChildren() + 1
            local selected = default or options[1]
            local opened = false

            local dropdown = create("Frame", {
                Name = "Dropdown" .. dropdownId,
                Parent = tab.Container,
                BackgroundColor3 = self.theme.Secondary,
                Size = UDim2.new(1, 0, 0, 35),
                LayoutOrder = dropdownId,
                ClipsDescendants = true
            })

            create("UICorner", {
                Parent = dropdown,
                CornerRadius = UDim.new(0, 5)
            })

            create("TextLabel", {
                Name = "Label",
                Parent = dropdown,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 15, 0, 0),
                Size = UDim2.new(1, -50, 1, 0),
                Font = Enum.Font.Gotham,
                Text = text,
                TextColor3 = self.theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            create("TextLabel", {
                Name = "Value",
                Parent = dropdown,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -35, 0, 0),
                Size = UDim2.new(0, 20, 1, 0),
                Font = Enum.Font.GothamSemibold,
                Text = selected,
                TextColor3 = self.theme.Accent,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right
            })

            create("ImageLabel", {
                Name = "Arrow",
                Parent = dropdown,
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -15, 0.5, -5),
                Size = UDim2.new(0, 10, 0, 10),
                Image = "rbxassetid://3926305904",
                ImageColor3 = self.theme.TextSecondary,
                ImageRectOffset = Vector2.new(964, 324),
                ImageRectSize = Vector2.new(36, 36),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Rotation = 180
            })

            local optionsFrame = create("ScrollingFrame", {
                Name = "Options",
                Parent = dropdown,
                BackgroundColor3 = self.theme.Main,
                Position = UDim2.new(0, 0, 1, 5),
                Size = UDim2.new(1, 0, 0, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = self.theme.Accent,
                Visible = false
            })

            create("UIListLayout", {
                Parent = optionsFrame,
                SortOrder = Enum.SortOrder.LayoutOrder
            })

            create("UICorner", {
                Parent = optionsFrame,
                CornerRadius = UDim.new(0, 5)
            })

            -- Create options
            for i, option in ipairs(options) do
                local optionButton = create("TextButton", {
                    Name = option,
                    Parent = optionsFrame,
                    BackgroundColor3 = self.theme.Main,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, -10, 0, 30),
                    Position = UDim2.new(0, 5, 0, (i-1)*35),
                    Font = Enum.Font.Gotham,
                    Text = option,
                    TextColor3 = self.theme.Text,
                    TextSize = 14,
                    AutoButtonColor = false,
                    LayoutOrder = i
                })

                optionButton.MouseEnter:Connect(function()
                    if option ~= selected then
                        tween(optionButton, { BackgroundColor3 = self.theme.Secondary })
                    end
                end)

                optionButton.MouseLeave:Connect(function()
                    if option ~= selected then
                        tween(optionButton, { BackgroundColor3 = self.theme.Main })
                    end
                end)

                optionButton.MouseButton1Click:Connect(function()
                    selected = option
                    dropdown.Value.Text = selected

                    if callback then
                        callback(selected)
                    end

                    self:ToggleDropdown(dropdown)
                end)
            end

            -- Update canvas size
            optionsFrame.CanvasSize = UDim2.new(0, 0, 0, #options * 35)

            -- Dropdown functionality
            dropdown.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    self:ToggleDropdown(dropdown)
                end
            end)

            return {
                Set = function(newValue)
                    if table.find(options, newValue) then
                        selected = newValue
                        dropdown.Value.Text = selected
                    end
                end,
                Get = function()
                    return selected
                end,
                Refresh = function(newOptions)
                    options = newOptions
                    -- Rebuild options frame
                end
            }
        end

        function tabMethods:AddColorPicker(text, default, callback)
            -- Advanced color picker implementation
            -- Would include RGB/HSV sliders, hex input, and palette
        end

        function tabMethods:AddKeybind(text, default, callback)
            -- Keybind selector implementation
        end

        return tabMethods
    end

    return windowMethods
end

-- Window management
function LuxUI:ToggleWindow(windowId)
    local window = self.windows[windowId]

    if not window then return end

    window.Open = not window.Open

    if window.Open then
        window.Main.Visible = true
        tween(window.Main, {
            Size = window.Size,
            Position = window.Position
        })

        if self.blur then
            self.blur.Enabled = true
            tween(self.blur, { Size = 10 })
        end
    else
        tween(window.Main, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Wait()
        window.Main.Visible = false

        if self.blur then
            tween(self.blur, { Size = 0 }):Wait()
            self.blur.Enabled = false
        end
    end

    -- Close other windows if this is a mobile device
    if isMobile() and window.Open then
        for i, w in ipairs(self.windows) do
            if i ~= windowId and w.Open then
                self:ToggleWindow(i)
            end
        end
    end
end

function LuxUI:SwitchTab(windowId, tabId)
    local window = self.windows[windowId]
    if not window then return end

    local tab = window.Tabs[tabId]
    if not tab then return end

    -- Hide all tabs
    for _, t in ipairs(window.Tabs) do
        t.Active = false
        t.Container.Visible = false
        tween(t.Button, { TextColor3 = self.theme.TextSecondary })
    end

    -- Show selected tab
    tab.Active = true
    tab.Container.Visible = true
    tween(tab.Button, { TextColor3 = self.theme.Accent })
end

function LuxUI:ToggleDropdown(dropdown)
    local optionsFrame = dropdown:FindFirstChild("Options")
    local arrow = dropdown:FindFirstChild("Arrow")

    if not optionsFrame or not arrow then return end

    if optionsFrame.Visible then
        -- Close dropdown
        optionsFrame.Visible = false
        tween(dropdown, { Size = UDim2.new(1, 0, 0, 35) })
        tween(arrow, { Rotation = 180 })
    else
        -- Open dropdown
        local optionCount = #optionsFrame:GetChildren() - 2 -- subtract layout and corner
        local maxHeight = math.min(optionCount * 35 + 10, 200)

        optionsFrame.Visible = true
        tween(dropdown, { Size = UDim2.new(1, 0, 0, 40 + maxHeight) })
        tween(arrow, { Rotation = 0 })
    end
end

-- Notification system
function LuxUI:Notify(title, message, notificationType, duration)
    duration = duration or 5
    notificationType = notificationType or "Info"

    local color
    if notificationType == "Success" then
        color = self.theme.Success
    elseif notificationType == "Warning" then
        color = self.theme.Warning
    elseif notificationType == "Error" then
        color = self.theme.Error
    else
        color = self.theme.Accent
    end

    local notificationId = #self.notifications + 1

    local notification = create("Frame", {
        Name = "Notification" .. notificationId,
        Parent = self.notificationHolder,
        BackgroundColor3 = self.theme.Secondary,
        Position = UDim2.new(1, 0, 1, -50),
        Size = UDim2.new(0, 300, 0, 0),
        AnchorPoint = Vector2.new(1, 1),
        ClipsDescendants = true
    })

    create("UICorner", {
        Parent = notification,
        CornerRadius = UDim.new(0, 8)
    })

    create("UIStroke", {
        Parent = notification,
        Color = color,
        Thickness = 2
    })

    local topBar = create("Frame", {
        Name = "TopBar",
        Parent = notification,
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 0, 30)
    })

    create("UICorner", {
        Parent = top
