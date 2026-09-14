
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Platform gate: silent aim and fire-only aim live on desktop only
local isPC = UserInputService.MouseEnabled and not UserInputService.TouchEnabled

-- Fire state tracking (MouseButton1 held)
local firing = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end -- UI clicks are not shots
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        firing = false
    end
end)

-- Cleanup previous instances
if game.CoreGui:FindFirstChild("Delta_Mobile_Hack") then
    game.CoreGui.Delta_Mobile_Hack:Destroy()
end

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "Delta_Mobile_Hack"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.IgnoreGuiInset = true -- viewport coords == gui coords, no topbar offset
MainGui.Parent = game.CoreGui

-- State
local Settings = {
    ESP = {
        Enabled = false,
        Box = false,
        Health = false,
        Name = false,
        Line = false
    },
    Aimbot = {
        Enabled = false,
        Smoother = 0.3, -- 0.1 to 1.0 (lower is smoother/slower)
        FOV = 150,
        TargetPart = "Head",
        SilentAim = false,
        VisibleCheck = false,
        TeamCheck = false,
        ShowFOV = false,
        FireOnly = false
    }
}

-- UI Library (Mobile Friendly)
local MenuFrame = Instance.new("Frame")
MenuFrame.Size = UDim2.new(0, 280, 0, 350)
MenuFrame.Position = UDim2.new(0.5, -140, 0.5, -175)
MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MenuFrame.BorderSizePixel = 0
MenuFrame.ZIndex = 2
MenuFrame.Parent = MainGui

local MenuCorner = Instance.new("UICorner")
MenuCorner.CornerRadius = UDim.new(0, 8)
MenuCorner.Parent = MenuFrame

local MenuTitle = Instance.new("TextLabel")
MenuTitle.Size = UDim2.new(1, 0, 0, 40)
MenuTitle.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
MenuTitle.Text = "ESP + AIMBOT"
MenuTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuTitle.Font = Enum.Font.GothamBold
MenuTitle.TextSize = 16
MenuTitle.Parent = MenuFrame

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 30)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
TabContainer.Parent = MenuFrame

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -10, 1, -80)
ContentContainer.Position = UDim2.new(0, 5, 0, 75)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MenuFrame

local function createTab(name, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, 0, 1, 0)
    btn.Position = UDim2.new(xPos, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = TabContainer

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.Visible = false
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollBarThickness = 4
    content.Parent = ContentContainer

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = content

    btn.MouseButton1Click:Connect(function()
        for _, child in ipairs(ContentContainer:GetChildren()) do
            if child:IsA("ScrollingFrame") then child.Visible = false end
        end
        for _, child in ipairs(TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = Color3.fromRGB(150, 150, 150)
                child.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            end
        end
        content.Visible = true
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end)
    return content
end

local function createToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 30, 0, 16)
    toggleBtn.Position = UDim2.new(1, -30, 0.5, -8)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(100, 100, 100)
    toggleBtn.Text = ""
    toggleBtn.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        default = not default
        toggleBtn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(100, 100, 100)
        callback(default)
    end)
end

local function createSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, 0, 0, 10)
    sliderBg.Position = UDim2.new(0, 0, 1, -10)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    sliderBg.Parent = frame

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    sliderFill.Parent = sliderBg

    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local xPos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            local value = min + (max - min) * xPos
            sliderFill.Size = UDim2.new(xPos, 0, 1, 0)
            label.Text = text .. ": " .. math.floor(value)
            callback(value)
        end
    end)
end

local function createCycle(parent, text, options, defaultIndex, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -95, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local index = defaultIndex
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 22)
    btn.Position = UDim2.new(1, -90, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.Text = options[index].label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        index = index % #options + 1
        btn.Text = options[index].label
        callback(options[index].value)
    end)
end

-- Build UI
local espTab = createTab("ESP", 0)
local aimTab = createTab("Aimbot", 0.5)

createToggle(espTab, "Enable ESP", Settings.ESP.Enabled, function(v) Settings.ESP.Enabled = v end)
createToggle(espTab, "Box", Settings.ESP.Box, function(v) Settings.ESP.Box = v end)
createToggle(espTab, "Health", Settings.ESP.Health, function(v) Settings.ESP.Health = v end)
createToggle(espTab, "Name", Settings.ESP.Name, function(v) Settings.ESP.Name = v end)
createToggle(espTab, "Line", Settings.ESP.Line, function(v) Settings.ESP.Line = v end)

createToggle(aimTab, "Enable Aimbot", Settings.Aimbot.Enabled, function(v) Settings.Aimbot.Enabled = v end)
createSlider(aimTab, "Smoothness", 1, 20, 10, function(v) Settings.Aimbot.Smoother = v / 10 end)
createSlider(aimTab, "FOV Radius", 50, 300, 150, function(v) Settings.Aimbot.FOV = v end)
createCycle(aimTab, "Target Part", {
    {label = "Head", value = "Head"},
    {label = "Torso", value = "Torso"},
    {label = "Root", value = "HumanoidRootPart"}
}, 1, function(v) Settings.Aimbot.TargetPart = v end)
if isPC then
    createToggle(aimTab, "Silent Aim", Settings.Aimbot.SilentAim, function(v) Settings.Aimbot.SilentAim = v end)
    createToggle(aimTab, "Aim On Fire", Settings.Aimbot.FireOnly, function(v) Settings.Aimbot.FireOnly = v end)
end
createToggle(aimTab, "Visible Check", Settings.Aimbot.VisibleCheck, function(v) Settings.Aimbot.VisibleCheck = v end)
createToggle(aimTab, "Team Check", Settings.Aimbot.TeamCheck, function(v) Settings.Aimbot.TeamCheck = v end)
createToggle(aimTab, "FOV Circle", Settings.Aimbot.ShowFOV, function(v) Settings.Aimbot.ShowFOV = v end)

-- Floating Hide/Show Button (below topbar so it stays tappable)
local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 50, 0, 30)
HideBtn.Position = UDim2.new(1, -60, 0, 44)
HideBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
HideBtn.Text = "HIDE"
HideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 12
HideBtn.BorderSizePixel = 0
HideBtn.ZIndex = 2
HideBtn.Parent = MainGui

local HideBtnCorner = Instance.new("UICorner")
HideBtnCorner.CornerRadius = UDim.new(0, 6)
HideBtnCorner.Parent = HideBtn

local menuVisible = true
HideBtn.MouseButton1Click:Connect(function()
    menuVisible = not menuVisible
    MenuFrame.Visible = menuVisible
    HideBtn.Text = menuVisible and "HIDE" or "SHOW"
end)

-- FOV Circle
local FOVCircle = Instance.new("Frame")
FOVCircle.AnchorPoint = Vector2.new(0.5, 0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
FOVCircle.Size = UDim2.new(0, Settings.Aimbot.FOV * 2, 0, Settings.Aimbot.FOV * 2)
FOVCircle.Visible = false
FOVCircle.Parent = MainGui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOVCircle

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.5
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Transparency = 0.4
FOVStroke.Parent = FOVCircle

-- ESP Storage
local ESP_Objects = {}
local SilentTarget = nil

local function getTeamColor(player)
    if player.Team and player.Team.TeamColor then
        return player.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 50, 50)
end

-- Team Check
local function isSameTeam(player)
    if not Settings.Aimbot.TeamCheck then return false end
    if not LocalPlayer.Team or not player.Team then return false end
    return LocalPlayer.Team == player.Team
end

-- Target Part resolver (handles R6 "Torso" vs R15 "UpperTorso")
local function getAimPart(character)
    local partName = Settings.Aimbot.TargetPart
    if partName == "Torso" then
        return character:FindFirstChild("Torso")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild(partName) or character:FindFirstChild("HumanoidRootPart")
end

local function updateESP()
    if not Settings.ESP.Enabled then
        for _, obj in pairs(ESP_Objects) do
            if obj.Box then obj.Box.Visible = false end
            if obj.Health then obj.Health.Visible = false end
            if obj.Name then obj.Name.Visible = false end
            if obj.Line then obj.Line.Visible = false end
        end
        return
    end

    local centerX = Camera.ViewportSize.X / 2
    local centerY = Camera.ViewportSize.Y / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local humanoid = char:FindFirstChild("Humanoid")
            local head = char:FindFirstChild("Head")

            if not ESP_Objects[player] then
                ESP_Objects[player] = {
                    Box = Instance.new("Frame"),
                    Stroke = Instance.new("UIStroke"),
                    Health = Instance.new("TextLabel"),
                    Name = Instance.new("TextLabel"),
                    Line = Instance.new("Frame")
                }
                local espObj = ESP_Objects[player]

                espObj.Box.BackgroundTransparency = 1
                espObj.Box.BorderSizePixel = 0
                espObj.Box.Visible = false
                espObj.Box.Parent = MainGui

                espObj.Stroke.Thickness = 2
                espObj.Stroke.Color = Color3.new(1, 1, 1)
                espObj.Stroke.Parent = espObj.Box

                espObj.Health.BackgroundTransparency = 1
                espObj.Health.TextSize = 12
                espObj.Health.Font = Enum.Font.GothamBold
                espObj.Health.Visible = false
                espObj.Health.Parent = MainGui

                espObj.Name.BackgroundTransparency = 1
                espObj.Name.TextSize = 12
                espObj.Name.Font = Enum.Font.GothamBold
                espObj.Name.Visible = false
                espObj.Name.Parent = MainGui

                espObj.Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                espObj.Line.BorderSizePixel = 0
                espObj.Line.AnchorPoint = Vector2.new(0.5, 0.5)
                espObj.Line.Visible = false
                espObj.Line.Parent = MainGui
            end

            local espObj = ESP_Objects[player]
            local color = getTeamColor(player)

            if hrp and humanoid then
                -- Project head (top) and feet (bottom) for accurate box positioning
                local topPos = head and (head.Position + Vector3.new(0, 0.5, 0)) or (hrp.Position + Vector3.new(0, 2.5, 0))
                local bottomPos = hrp.Position - Vector3.new(0, 3, 0)

                local topScreen, topOnScreen = Camera:WorldToViewportPoint(topPos)
                local bottomScreen, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)

                if topOnScreen and topScreen.Z > 0 and bottomScreen.Z > 0 then
                    local boxHeight = math.abs(bottomScreen.Y - topScreen.Y)
                    local boxWidth = boxHeight * 0.65
                    local boxX = topScreen.X - boxWidth / 2
                    local boxY = topScreen.Y

                    if Settings.ESP.Box then
                        espObj.Box.Visible = true
                        espObj.Box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
                        espObj.Box.Position = UDim2.new(0, boxX, 0, boxY)
                        espObj.Stroke.Color = color
                    else
                        espObj.Box.Visible = false
                    end

                    if Settings.ESP.Health then
                        espObj.Health.Visible = true
                        espObj.Health.Text = math.floor(humanoid.Health) .. "%"
                        espObj.Health.TextColor3 = humanoid.Health > 50 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                        espObj.Health.Position = UDim2.new(0, boxX, 0, boxY - 15)
                    else
                        espObj.Health.Visible = false
                    end

                    if Settings.ESP.Name then
                        espObj.Name.Visible = true
                        espObj.Name.Text = player.Name
                        espObj.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
                        espObj.Name.Position = UDim2.new(0, boxX, 0, boxY + boxHeight + 5)
                    else
                        espObj.Name.Visible = false
                    end

                    if Settings.ESP.Line then
                        espObj.Line.Visible = true
                        espObj.Line.BackgroundColor3 = color
                        -- Tracer terminates at the bottom edge of the ESP box (feet)
                        local targetX = boxX + boxWidth / 2
                        local targetY = boxY + boxHeight
                        local dx = targetX - centerX
                        local dy = targetY - centerY
                        local distance = math.sqrt(dx^2 + dy^2)
                        local angle = math.atan2(dy, dx)
                        espObj.Line.Size = UDim2.new(0, distance, 0, 2)
                        espObj.Line.Position = UDim2.new(0, centerX + dx/2, 0, centerY + dy/2)
                        espObj.Line.Rotation = math.deg(angle)
                    else
                        espObj.Line.Visible = false
                    end
                else
                    espObj.Box.Visible = false
                    espObj.Health.Visible = false
                    espObj.Name.Visible = false
                    espObj.Line.Visible = false
                end
            end
        end
    end
end

-- Visible Check
local visibilityParams = RaycastParams.new()
visibilityParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(targetCharacter, targetPart)
    if not Settings.Aimbot.VisibleCheck then return true end

    local filterList = {}
    if LocalPlayer.Character then
        table.insert(filterList, LocalPlayer.Character)
    end
    visibilityParams.FilterDescendantsInstances = filterList

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    if direction.Magnitude < 0.1 then return true end

    local result = workspace:Raycast(origin, direction, visibilityParams)
    if result then
        return result.Instance:IsDescendantOf(targetCharacter)
    end
    return true
end

-- Aimbot Logic (screen-center based, works on both platforms)
local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Settings.Aimbot.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if isSameTeam(player) then continue end

            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            if hrp and humanoid and humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dx = pos.X - (Camera.ViewportSize.X / 2)
                    local dy = pos.Y - (Camera.ViewportSize.Y / 2)
                    local distance = math.sqrt(dx^2 + dy^2)

                    if distance < shortestDistance then
                        local aimPart = getAimPart(player.Character)
                        if isVisible(player.Character, aimPart) then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Silent Aim target pick (PC only): closest valid player to the mouse cursor
local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = Settings.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if isSameTeam(player) then continue end

            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character:FindFirstChild("Humanoid")

            if hrp and humanoid and humanoid.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen and pos.Z > 0 then
                    local dx = pos.X - mousePos.X
                    local dy = pos.Y - mousePos.Y
                    local distance = math.sqrt(dx^2 + dy^2)

                    if distance < shortestDistance then
                        local aimPart = getAimPart(player.Character)
                        if isVisible(player.Character, aimPart) then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Silent Aim Hook (PC only, crash-fixed)
-- Never installs on touch devices — mobile stays clean.
-- Early return for non-raycast methods prevents performance crash.
-- pcall guards against character destruction race conditions.
if isPC and hookmetamethod and getnamecallmethod then
    local oldNamecall

    local function silentAimHandler(self, ...)
        local method = getnamecallmethod()

        -- Early return for non-raycast methods (performance critical)
        if method ~= "Raycast" and method ~= "FindPartOnRay" and method ~= "FindPartOnRayWithIgnoreList" and method ~= "FindPartOnRayWithWhitelist" and method ~= "FindPartOnRayWithFilter" then
            return oldNamecall(self, ...)
        end

        if not Settings.Aimbot.SilentAim then
            return oldNamecall(self, ...)
        end

        if checkcaller and checkcaller() then
            return oldNamecall(self, ...)
        end

        if not SilentTarget or not SilentTarget.Character then
            return oldNamecall(self, ...)
        end

        local args = table.pack(...)
        local char = SilentTarget.Character

        local ok, part = pcall(function()
            return getAimPart(char)
        end)

        if not ok or not part then
            return oldNamecall(self, ...)
        end

        if method == "Raycast" then
            local origin = args[1]
            local direction = args[2]
            if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" and direction.Magnitude > 0 then
                local diff = part.Position - origin
                if diff.Magnitude > 0.1 then
                    local newDirection = diff.Unit * direction.Magnitude
                    return oldNamecall(self, origin, newDirection, table.unpack(args, 3, args.n))
                end
            end
        else
            local ray = args[1]
            if typeof(ray) == "Ray" and ray.Direction.Magnitude > 0 then
                local diff = part.Position - ray.Origin
                if diff.Magnitude > 0.1 then
                    local newRay = Ray.new(ray.Origin, diff.Unit * ray.Direction.Magnitude)
                    args[1] = newRay
                    return oldNamecall(self, table.unpack(args, 1, args.n))
                end
            end
        end

        return oldNamecall(self, ...)
    end

    local hookFunc = silentAimHandler
    if newcclosure then
        hookFunc = newcclosure(silentAimHandler)
    end

    oldNamecall = hookmetamethod(game, "__namecall", hookFunc)
end

RunService.RenderStepped:Connect(function()
    updateESP()

    if Settings.Aimbot.ShowFOV then
        FOVCircle.Visible = true
        local diameter = Settings.Aimbot.FOV * 2
        FOVCircle.Size = UDim2.new(0, diameter, 0, diameter)
    else
        FOVCircle.Visible = false
    end

    if isPC and Settings.Aimbot.SilentAim then
        SilentTarget = getClosestPlayerToMouse()
    else
        SilentTarget = nil
    end

    if Settings.Aimbot.Enabled then
        -- Fire-Only gate: on PC with the toggle on, camera locks only while MouseButton1 is held
        local shouldAim = not Settings.Aimbot.FireOnly or firing
        if shouldAim then
            local target = getClosestPlayer()
            if target and target.Character then
                local part = getAimPart(target.Character)
                if part then
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, part.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, Settings.Aimbot.Smoother)
                end
            end
        end
    end
end)

-- Cleanup on death/leave
Players.PlayerRemoving:Connect(function(player)
    if ESP_Objects[player] then
        for _, obj in pairs(ESP_Objects[player]) do
            if typeof(obj) == "Instance" then
                obj:Destroy()
            end
        end
        ESP_Objects[player] = nil
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    for _, objTable in pairs(ESP_Objects) do
        for _, v in pairs(objTable) do
            if typeof(v) == "Instance" then
                v:Destroy()
            end
        end
    end
    table.clear(ESP_Objects)
end)
