local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- 每帧事件循环管理器
local EventLoopManager = {
    IsRunning = false,
    TriggerCount = 0,
    FPS = 0,
    LastUpdate = tick()
}

-- 获取事件对象
local function getEvent()
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return nil end
    
    local event = events:FindFirstChild("__RZDONL")
    return event
end

-- 触发新的事件函数
local function fireEvent()
    local event = getEvent()
    if not event then return false end
    
    local success, errorMsg = pcall(function()
        local args = {
            "__---r",
            Vector3.zero,
            CFrame.new(-4574, 3, -443, 0, -0, 1, 0, 1, 0, -1, 0, 0),
            false
        }
        event:FireServer(unpack(args))
    end)
    
    if success then
        EventLoopManager.TriggerCount = EventLoopManager.TriggerCount + 1
    end
    
    return success
end

-- 计算FPS
local function updateFPS()
    local currentTime = tick()
    local deltaTime = currentTime - EventLoopManager.LastUpdate
    
    if deltaTime > 0.5 then
        EventLoopManager.FPS = math.floor(EventLoopManager.TriggerCount / deltaTime)
        EventLoopManager.TriggerCount = 0
        EventLoopManager.LastUpdate = currentTime
    end
end

-- 飞行控制器
local FlightController = {
    IsFlying = false,
    FlightSpeed = 1,
    VerticalSpeedMultiplier = 1.5,
    Connection = nil,
    IsMobile = UserInputService.TouchEnabled,
    OriginalGravity = workspace.Gravity,
    OriginalAnimateState = nil,
    AnimatorTracks = {},
    DummyModel = nil,
    OriginalCharacterTransparency = {},
    DummyUpdateConnection = nil
}

-- 创建静态自然站立姿势假身模型
local function createDummyModel()
    if FlightController.DummyModel then
        FlightController.DummyModel:Destroy()
        FlightController.DummyModel = nil
    end
    
    local dummy = Instance.new("Model")
    dummy.Name = "FlightDummy"
    
    -- 创建自然站立姿势部件位置（根据图片调整）
    local standPoseOffsets = {
        -- 躯干在中心
        Torso = CFrame.new(0, 0, 0),
        -- 头部在躯干上方
        Head = CFrame.new(0, 1.5, 0),
        -- 左臂自然下垂，稍微向前x.y.z 
        ["Left Arm"] = CFrame.new(-1.5, 0, -0.2),
        -- 右臂自然下垂，稍微向前
        ["Right Arm"] = CFrame.new(1.5, 0, -0.2),
        -- 左腿自然站立，稍微分开
        ["Left Leg"] = CFrame.new(-0.5, -2, 0),
        -- 右腿自然站立，稍微分开
        ["Right Leg"] = CFrame.new(0.5, -2, 0),
        -- HumanoidRootPart在躯干位置
        HumanoidRootPart = CFrame.new(0, 0, 0)
    }
    
    -- 创建假身部件（自然站立姿势）
    for partName, offsetCFrame in pairs(standPoseOffsets) do
        local originalPart = Character:FindFirstChild(partName)
        if originalPart and originalPart:IsA("BasePart") then
            local dummyPart = Instance.new("Part")
            dummyPart.Name = partName
            dummyPart.Size = originalPart.Size
            dummyPart.Shape = originalPart.Shape
            dummyPart.Material = originalPart.Material
            dummyPart.Color = originalPart.Color
            dummyPart.Transparency = 0
            dummyPart.Reflectance = originalPart.Reflectance
            dummyPart.CanCollide = false
            
            -- 关键：完全禁用物理
            dummyPart.Anchored = true
            dummyPart.Locked = true
            dummyPart.Massless = true
            
            -- 复制表面外观
            for _, surface in pairs(Enum.NormalId:GetEnumItems()) do
                local originalSurface = originalPart[surface.Name .. "Surface"]
                if originalSurface then
                    dummyPart[surface.Name .. "Surface"] = originalSurface
                end
            end
            
            -- 复制特殊网格（如果有）
            local specialMesh = originalPart:FindFirstChildOfClass("SpecialMesh")
            if specialMesh then
                local newMesh = specialMesh:Clone()
                newMesh.Parent = dummyPart
            end
            
            -- 复制纹理和装饰物
            for _, child in pairs(originalPart:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceGui") then
                    local clone = child:Clone()
                    clone.Parent = dummyPart
                end
            end
            
            -- 使用自然站立姿势位置
            dummyPart.CFrame = HumanoidRootPart.CFrame:ToWorldSpace(offsetCFrame)
            dummyPart.Parent = dummy
        end
    end
    
    -- 设置主部件
    local primaryPart = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        dummy.PrimaryPart = primaryPart
    end
    
    -- 不创建Humanoid，避免任何动画系统干扰
    dummy.Parent = workspace
    
    return dummy
end
    

-- 隐藏真实角色，显示假身
local function showDummy()
    -- 先停止所有动画
    if Humanoid then
        local animator = Humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0.1) -- 平滑停止动画
            end
        end
    end
    
    -- 等待一帧确保动画停止
    wait(0.1)
    
    -- 保存原始透明度
    FlightController.OriginalCharacterTransparency = {}
    for _, part in pairs(Character:GetChildren()) do
        if part:IsA("BasePart") then
            FlightController.OriginalCharacterTransparency[part] = part.Transparency
            part.Transparency = 1 -- 完全透明
        end
    end
    
    -- 创建假身（使用标准T-pose）
    FlightController.DummyModel = createDummyModel()
    
    if FlightController.DummyModel and FlightController.DummyModel.PrimaryPart then
        print("T-pose假身创建成功")
    else
        print("假身创建失败")
    end
end

-- 隐藏假身，显示真实角色
local function hideDummy()
    -- 恢复原始透明度
    for part, transparency in pairs(FlightController.OriginalCharacterTransparency) do
        if part and part.Parent then
            part.Transparency = transparency
        end
    end
    FlightController.OriginalCharacterTransparency = {}
    
    -- 删除假身更新连接
    if FlightController.DummyUpdateConnection then
        FlightController.DummyUpdateConnection:Disconnect()
        FlightController.DummyUpdateConnection = nil
    end
    
    -- 删除假身
    if FlightController.DummyModel then
        FlightController.DummyModel:Destroy()
        FlightController.DummyModel = nil
    end
end

-- 平滑更新假身位置
local function setupDummyUpdate()
    if FlightController.DummyUpdateConnection then
        FlightController.DummyUpdateConnection:Disconnect()
    end
    
    FlightController.DummyUpdateConnection = RunService.RenderStepped:Connect(function()
        if not FlightController.IsFlying or not FlightController.DummyModel or not FlightController.DummyModel.PrimaryPart or not HumanoidRootPart then
            return
        end
        
        -- 直接同步整个假身模型的位置和旋转
        FlightController.DummyModel:SetPrimaryPartCFrame(HumanoidRootPart.CFrame)
    end)
end

-- 创建UI界面
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MobileFlightGUI"
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
mainFrame.Size = UDim2.new(0, 200, 0, 80)
mainFrame.Active = true
mainFrame.Draggable = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- 标题
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = mainFrame
title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
title.BorderSizePixel = 0
title.Size = UDim2.new(1, 0, 0, 25)
title.Text = "fuckuccafuckuccafuckucca"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- 主控制按钮
local flyButton = Instance.new("TextButton")
flyButton.Name = "FlyButton"
flyButton.Parent = mainFrame
flyButton.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
flyButton.BorderSizePixel = 0
flyButton.Position = UDim2.new(0.05, 0, 0.35, 0)
flyButton.Size = UDim2.new(0.9, 0, 0, 40)
flyButton.Text = "fly"
flyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
flyButton.TextSize = 14
flyButton.Font = Enum.Font.GothamBold

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = flyButton

-- 状态指示器
local statusDot = Instance.new("Frame")
statusDot.Name = "StatusDot"
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(0.05, 0, 0.5, -5)
statusDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
statusDot.BorderSizePixel = 0

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot
statusDot.Parent = flyButton

-- FPS计数器
local fpsLabel = Instance.new("TextLabel")
fpsLabel.Name = "FPSLabel"
fpsLabel.Parent = mainFrame
fpsLabel.BackgroundTransparency = 1
fpsLabel.Position = UDim2.new(0.05, 0, 0.85, 0)
fpsLabel.Size = UDim2.new(0.9, 0, 0, 15)
fpsLabel.Text = "FPS: 0"
fpsLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
fpsLabel.TextSize = 10
fpsLabel.Font = Enum.Font.Gotham

-- 保存动画状态
local function saveAnimationState()
    FlightController.AnimatorTracks = {}
    
    if Humanoid then
        local animator = Humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                FlightController.AnimatorTracks[track.Animation.AnimationId] = {
                    TimePosition = track.TimePosition,
                    WeightCurrent = track.WeightCurrent
                }
            end
        end
    end
end

-- 恢复动画状态
local function restoreAnimationState()
    if Humanoid then
        local animator = Humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                local animationId = track.Animation.AnimationId
                if FlightController.AnimatorTracks[animationId] then
                    track:AdjustSpeed(0)
                    track.TimePosition = FlightController.AnimatorTracks[animationId].TimePosition
                    track:AdjustSpeed(1)
                end
            end
        end
    end
end

-- 飞行逻辑
function FlightController:Enable()
    if self.IsFlying then return end
    
    self.IsFlying = true
    EventLoopManager.IsRunning = true
    
    saveAnimationState()
    self.OriginalGravity = workspace.Gravity
    workspace.Gravity = 0
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    Humanoid.PlatformStand = true
    
    -- 停止所有动画
    if Humanoid then
        local animator = Humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0.1)
            end
        end
    end
    
    showDummy()
    setupDummyUpdate()
    
    self.Connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not self.IsFlying or not Character or not Humanoid then
            self:Disable()
            return
        end
        
        if EventLoopManager.IsRunning then
            fireEvent()
            updateFPS()
        end
        
        local camera = workspace.CurrentCamera
        if not camera then return end
        
        local cameraCFrame = camera.CFrame
        local lookVector = cameraCFrame.LookVector
        local uprightCFrame = CFrame.new(HumanoidRootPart.Position, HumanoidRootPart.Position + lookVector)
        HumanoidRootPart.CFrame = uprightCFrame
        
        if Humanoid.MoveDirection.Magnitude > 0 then
            local moveDirectionMagnitude = Humanoid.MoveDirection.Magnitude
            local localMoveDirection = HumanoidRootPart.CFrame:VectorToObjectSpace(Humanoid.MoveDirection)
            local horizontalMoveDirection = Vector3.new(localMoveDirection.X, 0, localMoveDirection.Z)
            
            if horizontalMoveDirection.Magnitude > 0 then
                horizontalMoveDirection = horizontalMoveDirection.Unit * moveDirectionMagnitude
            end
            
            local moveVector = horizontalMoveDirection * self.FlightSpeed * deltaTime * 50
            local worldMoveVector = HumanoidRootPart.CFrame:VectorToWorldSpace(moveVector)
            Character:TranslateBy(worldMoveVector)
        end
    end)
    
    flyButton.Text = "fly"
    flyButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    statusDot.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
    
    print("飞行+事件循环已启用")
    print("T-pose假身系统: 使用标准姿势而非动画姿势")
end

function FlightController:Disable()
    if not self.IsFlying then return end
    
    self.IsFlying = false
    EventLoopManager.IsRunning = false
    
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    
    hideDummy()
    workspace.Gravity = self.OriginalGravity or 196.2
    
    if Humanoid then
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        Humanoid.PlatformStand = false
        restoreAnimationState()
    end
    
    flyButton.Text = "fly"
    flyButton.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
    statusDot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    
    print("飞行+事件循环已禁用")
end

-- UI更新
local function updateUI()
    fpsLabel.Text = "FPS: " .. EventLoopManager.FPS
end

flyButton.MouseButton1Click:Connect(function()
    if FlightController.IsFlying then
        FlightController:Disable()
    else
        FlightController:Enable()
    end
    updateUI()
end)

RunService.Heartbeat:Connect(function()
    updateUI()
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
    Character = newCharacter
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    
    if FlightController.IsFlying then
        FlightController:Disable()
    end
end)
