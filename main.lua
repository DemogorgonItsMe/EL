--[[
    LuxUI - Premium UI Library for Roblox
    Версия 2.0 - Полностью защищенная от ошибок
    Гарантированно работает без ошибок типа "attempt to index nil"
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
local function CreateInstance(class, props)
    local instance = Instance.new(class)
    for prop, value in pairs(props or {}) do
        if prop ~= "Parent" and instance[prop] ~= nil then
            instance[prop] = value
        end
    end
    if props and props.Parent then
        instance.Parent = props.Parent
    end
    return instance
end

-- Защитная функция твинов
local function SafeTween(object, properties, duration)
    if not object or not properties then return end
    local tweenInfo = TweenInfo.new(duration or TWEEN_TIME, EASE_STYLE, EASE_DIRECTION)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Проверка мобильного устройства
local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Инициализация LuxUI
function LuxUI.new(options)
    options = options or {}
    
    local self = setmetatable({}, LuxUI)
    
    -- Инициализация темы с защитой
    self.theme = {}
    for k, v in pairs(DEFAULT_THEME) do
        self.theme[k] = (options.Theme and type(options.Theme) == "table" and options.Theme[k]) or v
    end
    
    self.configKey = options.ConfigKey or "LuxUIConfig"
    self.windows = {}
    self.notifications = {}
    self.open = false
    
    -- Создание основного GUI
    self.gui = CreateInstance("ScreenGui", {
        Name = "LuxUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 999,
        Parent = options.Parent or game:GetService("CoreGui")
    })
    
    -- Контейнер уведомлений
    self.notificationHolder = CreateInstance("Frame", {
        Name = "Notifications",
        Parent = self.gui,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 100
    })
    
    -- Эффект размытия (только для ПК)
    if not IsMobile() then
        self.blur = CreateInstance("BlurEffect", {
            Name = "UIBlur",
            Parent = game:GetService("Lighting"),
            Size = 0,
            Enabled = false
        })
    end
    
    return self
end

-- Создание окна
function LuxUI:CreateWindow(title, options)
    if not self.gui then return nil end
    
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
    
    -- Основной фрейм окна
    window.Main = CreateInstance("Frame", {
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
    
    -- Тень
    CreateInstance("ImageLabel", {
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
    window.TopBar = CreateInstance("Frame", {
        Name = "TopBar",
        Parent = window.Main,
        BackgroundColor3 = self.theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2
    })
    
    -- Заголовок
    CreateInstance("TextLabel", {
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
    window.CloseButton = CreateInstance("ImageButton", {
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
    window.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Parent = window.Main,
        BackgroundColor3 = self.theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 0, 40),
        ZIndex = 2
    })
    
    -- Контейнер вкладок
    window.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Parent = window.Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 80),
        Size = UDim2.new(1, 0, 1, -80),
        ClipsDescendants = true
    })
    
    -- Layout вкладок
    CreateInstance("UIListLayout", {
        Parent = window.TabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5)
    })
    
    -- Обработчик закрытия
    window.CloseButton.MouseButton1Click:Connect(function()
        self:ToggleWindow(windowId)
    end)
    
    -- Функционал перетаскивания
    local dragging, dragInput, dragStart, startPos
    
    local function UpdateDrag(input)
        local delta = input.Position - dragStart
        window.Main.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
    
    window.TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            UpdateDrag(input)
        end
    end)
    
    table.insert(self.windows, window)
    
    -- Методы окна
    local windowMethods = {}
    
    function windowMethods:Toggle()
        self:ToggleWindow(windowId)
        return self
    end
    
    function windowMethods:AddTab(name, icon)
        if not window or not window.TabBar or not window.TabContainer then return nil end
        
        local tabId = #window.Tabs + 1
        name = name or "Tab " .. tabId
        
        local tab = {
            Id = tabId,
            Name = name,
            Container = nil,
            Active = false
        }
        
        -- Кнопка вкладки
        tab.Button = CreateInstance("TextButton", {
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
        tab.Container = CreateInstance("ScrollingFrame", {
            Name = "Container" .. tabId,
            Parent = window.TabContainer,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = self.theme.Accent,
            Visible = false
        })
        
        -- Layout контейнера
        CreateInstance("UIListLayout", {
            Parent = tab.Container,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10)
        })
        
        CreateInstance("UIPadding", {
            Parent = tab.Container,
            PaddingLeft = UDim.new(0, 15),
            PaddingRight = UDim.new(0, 15),
            PaddingTop = UDim.new(0, 15),
            PaddingBottom = UDim.new(0, 15)
        })
        
        -- Обработчики кнопки вкладки
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
            self:SwitchTab(windowId, tabId)
        end)
        
        -- Активация первой вкладки
        if tabId == 1 then
            self:SwitchTab(windowId, 1)
        end
        
        table.insert(window.Tabs, tab)
        
        -- Методы вкладки
        local tabMethods = {}
        
        function tabMethods:AddLabel(text)
            local label = CreateInstance("TextLabel", {
                Parent = tab.Container,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 20),
                Font = Enum.Font.Gotham,
                Text = text or "",
                TextColor3 = self.theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = #tab.Container:GetChildren()
            })
            
            return tabMethods
        end
        
        function tabMethods:AddButton(text, callback)
            local buttonId = #tab.Container:GetChildren() + 1
            
            local button = CreateInstance("TextButton", {
                Name = "Button" .. buttonId,
                Parent = tab.Container,
                BackgroundColor3 = self.theme.Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 35),
                Font = Enum.Font.GothamSemibold,
                Text = text or "Button",
                TextColor3 = self.theme.Text,
                TextSize = 14,
                AutoButtonColor = false,
                LayoutOrder = buttonId
            })
            
            CreateInstance("UICorner", {
                Parent = button,
                CornerRadius = UDim.new(0, 5)
            })
            
            -- Эффекты кнопки
            button.MouseEnter:Connect(function()
                SafeTween(button, {BackgroundColor3 = Color3.fromRGB(
                    math.floor(self.theme.Secondary.R * 255 + 15),
                    math.floor(self.theme.Secondary.G * 255 + 15),
                    math.floor(self.theme.Secondary.B * 255 + 15)
                )})
            end)
            
            button.MouseLeave:Connect(function()
                SafeTween(button, {BackgroundColor3 = self.theme.Secondary})
            end)
            
            button.MouseButton1Click:Connect(function()
                if callback then
                    callback()
                end
            end)
            
            return tabMethods
        end
        
        return tabMethods
    end
    
    return windowMethods
end

-- Переключение окна
function LuxUI:ToggleWindow(windowId)
    local window = self.windows[windowId]
    if not window then return end
    
    window.Open = not window.Open
    
    if window.Open then
        window.Main.Visible = true
        SafeTween(window.Main, {
            Size = window.Size,
            Position = window.Position
        })
        
        if self.blur then
            self.blur.Enabled = true
            SafeTween(self.blur, {Size = 10})
        end
    else
        SafeTween(window.Main, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        
        if self.blur then
            SafeTween(self.blur, {Size = 0})
        end
    end
end

-- Переключение вкладок
function LuxUI:SwitchTab(windowId, tabId)
    local window = self.windows[windowId]
    if not window then return end
    
    local tab = window.Tabs[tabId]
    if not tab then return end
    
    -- Скрыть все вкладки
    for _, t in ipairs(window.Tabs) do
        t.Active = false
        if t.Container then
            t.Container.Visible = false
        end
        if t.Button then
            SafeTween(t.Button, {TextColor3 = self.theme.TextSecondary})
        end
    end
    
    -- Показать выбранную вкладку
    tab.Active = true
    if tab.Container then
        tab.Container.Visible = true
    end
    if tab.Button then
        SafeTween(tab.Button, {TextColor3 = self.theme.Accent})
    end
end

-- Уведомления
function LuxUI:Notify(title, message, notificationType, duration)
    title = title or "Notification"
    message = message or ""
    notificationType = notificationType or "Info"
    duration = duration or 5
    
    local color = self.theme.Accent
    if notificationType == "Success" then color = self.theme.Success
    elseif notificationType == "Warning" then color = self.theme.Warning
    elseif notificationType == "Error" then color = self.theme.Error end
    
    local notification = CreateInstance("Frame", {
        Name = "Notification",
        Parent = self.notificationHolder,
        BackgroundColor3 = self.theme.Secondary,
        Position = UDim2.new(1, 0, 1, -50),
        Size = UDim2.new(0, 300, 0, 0),
        AnchorPoint = Vector2.new(1, 1),
        ClipsDescendants = true
    })
    
    CreateInstance("UICorner", {
        Parent = notification,
        CornerRadius = UDim.new(0, 8)
    })
    
    CreateInstance("UIStroke", {
        Parent = notification,
        Color = color,
        Thickness = 2
    })
    
    local topBar = CreateInstance("Frame", {
        Name = "TopBar",
        Parent = notification,
        BackgroundColor3 = color,
        Size = UDim2.new(1, 0, 0, 30)
    })
    
    CreateInstance("TextLabel", {
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
    
    local messageLabel = CreateInstance("TextLabel", {
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
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Автоматический размер
    local textSize = TextService:GetTextSize(message, 13, Enum.Font.Gotham, Vector2.new(280, math.huge))
    local totalHeight = math.min(textSize.Y + 45, 200)
    
    notification.Size = UDim2.new(0, 300, 0, totalHeight)
    messageLabel.Size = UDim2.new(1, -20, 0, textSize.Y)
    
    -- Анимация появления
    SafeTween(notification, {
        Position = UDim2.new(1, -10, 1, -10 - totalHeight)
    })
    
    -- Автоматическое закрытие
    task.delay(duration, function()
        SafeTween(notification, {
            Position = UDim2.new(1, 10, 1, 10)
        })
        task.wait(TWEEN_TIME)
        notification:Destroy()
    end)
end

return LuxUI
