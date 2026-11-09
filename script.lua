local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local function ProtectGui(gui)
    local success = pcall(function()
        gui.Parent = CoreGui
    end)
    if not success then
        pcall(function()
            gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end
end

-- TELA PRINCIPAL
local Screen = Instance.new("ScreenGui")
Screen.Name = "CustomModMenu"
Screen.ResetOnSpawn = false
ProtectGui(Screen)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromOffset(280, 400) -- Aumentado para caber o novo botão de farm
MainFrame.Position = UDim2.new(0.5, -140, 0.4, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = Screen

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 6)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopBarCorner = Instance.new("UICorner")
TopBarCorner.CornerRadius = UDim.new(0, 6)
TopBarCorner.Parent = TopBar

local FixBar = Instance.new("Frame")
FixBar.Size = UDim2.new(1, 0, 0, 6)
FixBar.Position = UDim2.new(0, 0, 1, -6)
FixBar.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
FixBar.BorderSizePixel = 0
FixBar.Parent = TopBar

-- PAINEL MÓVEL
local dragging, dragStart, startPos

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

TopBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
end)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -70, 1, 0)
TitleLabel.Position = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Painel de Veículos & Auto Farm"
TitleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
TitleLabel.TextSize = 12
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

-- BOTÃO DE FECHAR (✕)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -30, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CloseBtn.TextSize = 13
CloseBtn.Parent = TopBar

CloseBtn.MouseButton1Click:Connect(function()
    pcall(function() Screen:Destroy() end)
end)

-- BOTÃO DE MINIMIZAR
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.fromOffset(30, 30)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "▼"
MinimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
MinimizeBtn.TextSize = 12
MinimizeBtn.Parent = TopBar

local ContentContainer = Instance.new("ScrollingFrame")
ContentContainer.Size = UDim2.new(1, -16, 1, -45)
ContentContainer.Position = UDim2.new(0, 8, 0, 38)
ContentContainer.BackgroundTransparency = 1
ContentContainer.BorderSizePixel = 0
ContentContainer.CanvasSize = UDim2.new(0, 0, 0, 370)
ContentContainer.ScrollBarThickness = 3
ContentContainer.Parent = MainFrame

local MenuMinimized = false
MinimizeBtn.MouseButton1Click:Connect(function()
    MenuMinimized = not MenuMinimized
    local targetSize = MenuMinimized and UDim2.fromOffset(280, 30) or UDim2.fromOffset(280, 400)
    MinimizeBtn.Text = MenuMinimized and "▲" or "▼"
    ContentContainer.Visible = not MenuMinimized
    TweenService:Create(MainFrame, TweenInfo.new(0.25), {Size = targetSize}):Play()
end)

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.Parent = ContentContainer

-- VARIÁVEIS DE CONTROLE
local CurrentMultiplier = 1
local IsFrozen = false
local AutoFarmAtivo = false

local function GetVehicleRoot()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.SeatPart then
        local seat = humanoid.SeatPart
        local model = seat.Parent
        local rootPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("PrimaryPart") or seat
        return rootPart, model, seat
    end
    return nil, nil, nil
end

-- FUNÇÃO DE AUTO FARM DE CAMINHÃO (Loop de Entrega e Direção)
local function IniciarAutoFarmCaminhao(btnRef)
    AutoFarmAtivo = not AutoFarmAtivo
    btnRef.BackgroundColor3 = AutoFarmAtivo and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(30, 30, 42)
    btnRef.Text = AutoFarmAtivo and "Auto Farm: ATIVO" or "Auto Farm Caminhão"

    task.spawn(function()
        while AutoFarmAtivo do
            pcall(function()
                local rootPart, model, seat = GetVehicleRoot()
                if rootPart and seat and seat:IsA("VehicleSeat") then
                    -- Simula aceleração automática para frente na rota do caminhão
                    seat.Throttle = 1
                    
                    -- Exemplo de lógica de estabilização e direção automática
                    -- Mantém o caminhão alinhado para frente e livre de travamentos
                    rootPart.AssemblyLinearVelocity = rootPart.CFrame.LookVector * 50
                end
            end)
            task.wait(0.5)
        end
        
        -- Para o veículo ao desativar
        pcall(function()
            local _, _, seat = GetVehicleRoot()
            if seat and seat:IsA("VehicleSeat") then
                seat.Throttle = 0
            end
        end)
    end)
end

-- CRIAÇÃO DOS BOTÕES NO PAINEL
local function CreateVisualButton(text, order, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamMedium
    btn.AutoButtonColor = true
    btn.LayoutOrder = order
    btn.Parent = ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return btn
end

-- ADICIONANDO AS FUNÇÕES AO MENU
CreateVisualButton("Congelar", 1, function(btn)
    IsFrozen = not IsFrozen
    local _, model = GetVehicleRoot()
    if model then
        for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = IsFrozen end end
    end
    btn.BackgroundColor3 = IsFrozen and Color3.fromRGB(0, 80, 140) or Color3.fromRGB(30, 30, 42)
end)

CreateVisualButton("Impulso", 2, function()
    local root = GetVehicleRoot()
    if root then root.AssemblyLinearVelocity = root.CFrame.LookVector * (CurrentMultiplier * 100) end
end)

CreateVisualButton("Super Pulo", 3, function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local jh = CurrentMultiplier * 10
        local jv = math.sqrt(2 * workspace.Gravity * jh)
        char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, jv, 0)
    end
end)

CreateVisualButton("Parar na Hora", 4, function()
    local root = GetVehicleRoot()
    if root then root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
end)

CreateVisualButton("Endireitar", 5, function()
    local root = GetVehicleRoot()
    if root then root.CFrame = CFrame.new(root.Position + Vector3.new(0, 3, 0)) end
end)

-- BOTÃO DE AUTO FARM DE CAMINHÃO COM TOGGLE
CreateVisualButton("Auto Farm Caminhão", 6, function(btn)
    IniciarAutoFarmCaminhao(btn)
end)

-- SLIDER DE FORÇA / MULTIPLICADOR (1 a 20)
local function CreateDisabledButton(text, order)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 34)
    container.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    container.LayoutOrder = order
    container.Parent = ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(110, 110, 120)
    label.TextSize = 13
    label.Font = Enum.Font.GothamMedium
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "ValueDisplay"
    valueLabel.Size = UDim2.new(0, 40, 1, 0)
    valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "1"
    valueLabel.TextColor3 = Color3.fromRGB(220, 30, 30)
    valueLabel.TextSize = 13
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    return container
end

local function CreateImpulseSlider(order, valueDisplayContainer)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 45)
    container.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    container.LayoutOrder = order
    container.Parent = ContentContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local sliderBg = Instance.new("TextButton")
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0.5, -3)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    sliderBg.AutoButtonColor = false
    sliderBg.Text = ""
    sliderBg.Parent = container

    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = sliderBg

    local redCircle = Instance.new("Frame")
    redCircle.Size = UDim2.fromOffset(14, 14)
    redCircle.AnchorPoint = Vector2.new(0.5, 0.5)
    redCircle.Position = UDim2.new(0, 0, 0.5, 0)
    redCircle.BackgroundColor3 = Color3.fromRGB(220, 30, 30)
    redCircle.BorderSizePixel = 0
    redCircle.Parent = sliderBg

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = redCircle

    local sliding = false

    local function UpdateSlide(input)
        pcall(function()
            local absPos = sliderBg.AbsolutePosition.X
            local absSize = sliderBg.AbsoluteSize.X
            local percent = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
            redCircle.Position = UDim2.new(percent, 0, 0.5, 0)
            
            local calculatedValue = math.floor(1 + (19 * percent))
            CurrentMultiplier = calculatedValue
            
            local valLabel = valueDisplayContainer:FindFirstChild("ValueDisplay")
            if valLabel then valLabel.Text = tostring(calculatedValue) end
        end)
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            UpdateSlide(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlide(input)
        end
    end)
    return container
end

local impulseFrame = CreateDisabledButton("Força / Multiplicador", 7)
CreateImpulseSlider(8, impulseFrame)
