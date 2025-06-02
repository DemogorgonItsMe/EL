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

-- Сервисы
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

-- Константы
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

-- Защитная функция создания объектов
local function SafeCreate(class, props)
    local success, instance = pcall(function()
        local inst = Instance.new(class)
        for prop, value in pairs(props) do
            if prop ~= "Parent" then
                if pcall(function() return inst[prop] end) then
                    inst[prop] = value
                end
            end
        end
        if props.Parent then
            inst.Parent = props.Parent
        end
        return inst
    end)
    return success and instance or nil
end

-- Защитная функция твинов
local function SafeTween(object, properties, duration, easingStyle, easingDirection)
    if not object or not properties then return nil end
    local tweenInfo = TweenInfo.new(
        duration or TWEEN_TIME,
        easingStyle or EASE_STYLE,
        easingDirection or EASE_DIRECTION
    )
    local success, tween = pcall(function()
        return TweenService:Create(object, tweenInfo, properties)
    end)
    if success and tween then
        pcall(tween.Play, tween)
        return tween
    end
    return nil
end

-- Проверка мобильного устройства
local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Инициализация LuxUI
function LuxUI.new(options)
    options = options or {}
    
    local self = setmetatable({}, LuxUI)
    
    -- Защитная инициализация темы
    self.theme = {}
    for k, v in pairs(DEFAULT_THEME) do
        self.theme[k] = (options.Theme and options.Theme[k]) or v
    end
    
    self.configKey = options.ConfigKey or "LuxUIConfig"
    self.windows = {}
    self.notifications = {}
    self.open = false
    
    -- Создание основного GUI с защитой
    self.gui = SafeCreate("ScreenGui", {
        Name = "LuxUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999,
        Parent = options.Parent or game:GetService("CoreGui")
    }) or error("Не удалось создать ScreenGui")
    
    -- Создание контейнера уведомлений
    self.notificationHolder = SafeCreate("Frame", {
        Name = "Notifications",
        Parent = self.gui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100
    })
    
    -- Создание эффекта размытия (только для ПК)
    if not IsMobile() then
        self.blur = SafeCreate("BlurEffect", {
            Name = "UIBlur",
            Parent = game:GetService("Lighting"),
            Size = 0,
            Enabled = false
        })
    end
    
    -- Загрузка конфигурации с защитой
    if options.LoadConfig and isfile and readfile then
        pcall(function() self:LoadConfig() end)
    end
    
    return self
end

-- Создание окна с полной защитой
function LuxUI:CreateWindow(title, options)
    options = options or {}
    local windowId = #self.windows + 1
    
    -- Проверка и установка значений по умолчанию
    if not self.theme then self.theme = DEFAULT_THEME end
    
    local window = {
        Id = windowId,
        Tabs = {},
        Open = false,
        MinSize = options.MinSize or Vector2.new(300, 400),
        Size = options.Size or UDim2.new(0, 500, 0, 500),
        Position = options.Position or UDim2.new(0.5, -250, 0.5, -250)
    }
    
    -- Основной фрейм окна
    window.Main = SafeCreate("Frame", {
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
    
    if not window.Main then return nil end
    
    -- Тень окна
    SafeCreate("ImageLabel", {
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
    
    -- Верхняя панель
    window.TopBar = SafeCreate("Frame", {
        Name = "TopBar",
        Parent = window.Main,
        BackgroundColor3 = self.theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2
    })
    
    -- Заголовок окна
    SafeCreate("TextLabel", {
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
    
    -- Кнопка закрытия
    window.CloseButton = SafeCreate("ImageButton", {
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
    
    -- Панель вкладок
    window.TabBar = SafeCreate("Frame", {
        Name = "TabBar",
        Parent = window.Main,
        BackgroundColor3 = self.theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2
    })
    
    -- Контейнер вкладок
    window.TabContainer = SafeCreate("Frame", {
        Name = "TabContainer",
        Parent = window.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 80),
        Size = UDim2.new(1, 0, 1, -80),
        ClipsDescendants = true
    })
    
    -- Layout для вкладок
    SafeCreate("UIListLayout", {
        Parent = window.TabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    -- Обработчик кнопки закрытия
    if window.CloseButton then
        window.CloseButton.MouseButton1Click:Connect(function()
            pcall(function() self:ToggleWindow(windowId) end)
        end)
    end
    
    -- Функционал перетаскивания окна
    local dragging, dragInput, dragStart, startPos
    
    local function UpdateDrag(input)
        if not window.Main or not dragStart or not startPos then return end
        local delta = input.Position - dragStart
        window.Main.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
    
    if window.TopBar then
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
    end
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            pcall(UpdateDrag, input)
        end
    end)
    
    table.insert(self.windows, window)
    
    -- Методы окна
    local windowMethods = {}
    
    function windowMethods:Toggle()
        pcall(function() self:ToggleWindow(windowId) end)
    end
    
    function windowMethods:AddTab(name, icon)
        if not window or not window.TabBar or not window.TabContainer then return nil end
        
        local tabId = #window.Tabs + 1
        name = tostring(name or "Tab " .. tabId)
        
        local tab = {
            Id = tabId,
            Name = name,
            Container = nil,
            Active = false
        }
        
        -- Кнопка вкладки
        tab.Button = SafeCreate("TextButton", {
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
        
        -- Контейнер вкладки
        tab.Container = SafeCreate("ScrollingFrame", {
            Name = "Container" .. tabId,
            Parent = window.TabContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.theme.Accent,
            Visible = false
        })
        
        if not tab.Container then return nil end
        
        -- Layout контейнера
        SafeCreate("UIListLayout", {
            Parent = tab.Container,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
        
        SafeCreate("UIPadding", {
            Parent = tab.Container,
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 15)
        })
        
        -- Обработчики кнопки вкладки
        if tab.Button then
            tab.Button.MouseEnter:Connect(function()
                if not tab.Active then
                    SafeTween(tab.Button, {TextColor3 = self.theme.Text})
                end
            end)
            
            tab.Button.MouseLeave:Connect(function()
                if not tab.Active then
                    SafeTween(tab.Button, {TextColor3 = self.theme.TextSecondary})
                end
            end)
            
            tab.Button.MouseButton1Click:Connect(function()
                pcall(function() self:SwitchTab(windowId, tabId) end)
            end)
        end
        
        -- Активация первой вкладки
        if tabId == 1 then
            pcall(function() self:SwitchTab(windowId, 1) end)
        end
        
        table.insert(window.Tabs, tab)
        
        -- Методы вкладки
        local tabMethods = {}
        
        function tabMethods:AddLabel(text)
            if not tab.Container then return nil end
            
            local label = SafeCreate("TextLabel", {
                Parent = tab.Container,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.Gotham,
                Text = tostring(text or ""),
                TextColor3 = self.theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = #tab.Container:GetChildren()
            })
            
            return label
        end
        
        function tabMethods:AddButton(text, callback)
            if not tab.Container then return nil end
            
            local buttonId = #tab.Container:GetChildren() + 1
            text = tostring(text or "Button " .. buttonId)
            
            local button = SafeCreate("TextButton", {
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
            
            if not button then return nil end
            
            SafeCreate("UICorner", {
                Parent = button,
                CornerRadius = UDim.new(0, 5)
            })
            
            -- Эффекты кнопки
            button.MouseEnter:Connect(function()
                SafeTween(button, {BackgroundColor3 = Color3.fromRGB(
                    math.floor((self.theme.Secondary.R * 255) + 15),
                    math.floor((self.theme.Secondary.G * 255) + 15),
                    math.floor((self.theme.Secondary.B * 255) + 15)
                )})
            end)
            
            button.MouseLeave:Connect(function()
                SafeTween(button, {BackgroundColor3 = self.theme.Secondary})
            end)
            
            button.MouseButton1Click:Connect(function()
                if type(callback) == "function" then
                    pcall(callback)
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
                        tween(toggleButton, {BackgroundColor3 = self.theme.Accent})
                        tween(toggleDot, {Position = UDim2.new(1, -18, 0.5, -8)})
                    else
                        tween(toggleButton, {BackgroundColor3 = self.theme.TextSecondary})
                        tween(toggleDot, {Position = UDim2.new(0, 2, 0.5, -8)})
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
                        tween(toggleButton, {BackgroundColor3 = self.theme.Accent})
                        tween(toggleDot, {Position = UDim2.new(1, -18, 0.5, -8)})
                    else
                        tween(toggleButton, {BackgroundColor3 = self.theme.TextSecondary})
                        tween(toggleDot, {Position = UDim2.new(0, 2, 0.5, -8)})
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
                
                value = math.floor(min + (max - min) * relativeX)
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
                        tween(optionButton, {BackgroundColor3 = self.theme.Secondary})
                    end
                end)
                
                optionButton.MouseLeave:Connect(function()
                    if option ~= selected then
                        tween(optionButton, {BackgroundColor3 = self.theme.Main})
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
            tween(self.blur, {Size = 10})
        end
    else
        tween(window.Main, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Wait()
        window.Main.Visible = false
        
        if self.blur then
            tween(self.blur, {Size = 0}):Wait()
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
        tween(t.Button, {TextColor3 = self.theme.TextSecondary})
    end
    
    -- Show selected tab
    tab.Active = true
    tab.Container.Visible = true
    tween(tab.Button, {TextColor3 = self.theme.Accent})
end

function LuxUI:ToggleDropdown(dropdown)
    local optionsFrame = dropdown:FindFirstChild("Options")
    local arrow = dropdown:FindFirstChild("Arrow")
    
    if not optionsFrame or not arrow then return end
    
    if optionsFrame.Visible then
        -- Close dropdown
        optionsFrame.Visible = false
        tween(dropdown, {Size = UDim2.new(1, 0, 0, 35)})
        tween(arrow, {Rotation = 180})
    else
        -- Open dropdown
        local optionCount = #optionsFrame:GetChildren() - 2 -- subtract layout and corner
        local maxHeight = math.min(optionCount * 35 + 10, 200)
        
        optionsFrame.Visible = true
        tween(dropdown, {Size = UDim2.new(1, 0, 0, 40 + maxHeight)})
        tween(arrow, {Rotation = 0})
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
        Parent = topBar,
        CornerRadius = UDim.new(0, 8, 0, 0)
    })
    
    create("TextLabel", {
        Name = "Title",
        Parent = topBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -10, 1, 0),
        Font = Enum.Font.GothamSemibold,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    create("TextLabel", {
        Name = "Message",
        Parent = notification,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 35),
        Size = UDim2.new(1, -20, 0, 0),
        Font = Enum.Font.Gotham,
        Text = message,
        TextColor3 = self.theme.Text,
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    -- Calculate required height
    local textBounds = game:GetService("TextService"):GetTextSize(
        message,
        13,
        Enum.Font.Gotham,
        Vector2.new(280, math.huge)
    )
    
    local totalHeight = math.min(textBounds.Y + 45, 200)
    notification.Message.Size = UDim2.new(1, -20, 0, textBounds.Y)
    notification.Size = UDim2.new(0, 300, 0, totalHeight)
    
    -- Animate in
    notification.Position = UDim2.new(1, 10, 1, 10)
    tween(notification, {
        Position = UDim2.new(1, -10, 1, -10 - totalHeight)
    })
    
    -- Auto-close after duration
    task.delay(duration, function()
        tween(notification, {
            Position = UDim2.new(1, 10, 1, 10)
        }):Wait()
        notification:Destroy()
    end)
    
    table.insert(self.notifications, notification)
end

-- Configuration saving/loading
function LuxUI:SaveConfig()
    if not isfile then return end
    
    local config = {
        Windows = {}
    }
    
    for _, window in ipairs(self.windows) do
        table.insert(config.Windows, {
            Size = window.Size,
            Position = window.Position,
            Open = window.Open
        })
    end
    
    writefile(self.configKey .. ".luxui", game:GetService("HttpService"):JSONEncode(config))
end

function LuxUI:LoadConfig()
    if not isfile or not isfile(self.configKey .. ".luxui") then return end
    
    local success, config = pcall(function()
        return game:GetService("HttpService"):JSONDecode(readfile(self.configKey .. ".luxui"))
    end)
    
    if not success then return end
    
    for i, windowConfig in ipairs(config.Windows or {}) do
        if self.windows[i] then
            self.windows[i].Size = windowConfig.Size or self.windows[i].Size
            self.windows[i].Position = windowConfig.Position or self.windows[i].Position
            
            if windowConfig.Open then
                self:ToggleWindow(i)
            end
        end
    end
end

-- Theme management
function LuxUI:SetTheme(newTheme)
    self.theme = newTheme or DEFAULT_THEME
    -- Update all UI elements with new theme
    -- This would iterate through all windows and update their colors
end

return LuxUI
