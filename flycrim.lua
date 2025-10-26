local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local EventLoopManager = {
    IsRunning = false,
    TriggerCount = 0,
    FPS = 0,
    LastUpdate = tick()
}

local function getEvent()
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return nil end
    
    local event = events:FindFirstChild("__RZDONL")
    return event
end

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

local function updateFPS()
    local currentTime = tick()
    local deltaTime = currentTime - EventLoopManager.LastUpdate
    
    if deltaTime > 0.5 then
        EventLoopManager.FPS = math.floor(EventLoopManager.TriggerCount / deltaTime)
        EventLoopManager.TriggerCount = 0
        EventLoopManager.LastUpdate = currentTime
    end
end

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

local function createDummyModel()
    if FlightController.DummyModel then
        FlightController.DummyModel:Destroy()
        FlightController.DummyModel = nil
    end
    
    local dummy = Instance.new("Model")
    dummy.Name = "FlightDummy"
    
    
    local standPoseOffsets = {
        
        Torso = CFrame.new(0, 0, 0),
        
        Head = CFrame.new(0, 1.5, 0),
        
        ["Left Arm"] = CFrame.new(-1.5, 0, -0.2),
        
        ["Right Arm"] = CFrame.new(1.5, 0, -0.2),
        
        ["Left Leg"] = CFrame.new(-0.5, -2, 0),
        
        ["Right Leg"] = CFrame.new(0.5, -2, 0),
        
        HumanoidRootPart = CFrame.new(0, 0, 0)
    }
    
    
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
            
            
            dummyPart.Anchored = true
            dummyPart.Locked = true
            dummyPart.Massless = true
            
           
            for _, surface in pairs(Enum.NormalId:GetEnumItems()) do
                local originalSurface = originalPart[surface.Name .. "Surface"]
                if originalSurface then
                    dummyPart[surface.Name .. "Surface"] = originalSurface
                end
            end
            
            
            local specialMesh = originalPart:FindFirstChildOfClass("SpecialMesh")
            if specialMesh then
                local newMesh = specialMesh:Clone()
                newMesh.Parent = dummyPart
            end
            
            
            for _, child in pairs(originalPart:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") or child:IsA("SurfaceGui") then
                    local clone = child:Clone()
                    clone.Parent = dummyPart
                end
            end
            
           
            dummyPart.CFrame = HumanoidRootPart.CFrame:ToWorldSpace(offsetCFrame)
            dummyPart.Parent = dummy
        end
    end
    
   
    local primaryPart = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChildWhichIsA("BasePart")
    if primaryPart then
        dummy.PrimaryPart = primaryPart
    end
    
    
    dummy.Parent = workspace
    
    return dummy
end
    


local function showDummy()
    
    if Humanoid then
        local animator = Humanoid:FindFirstChildOfClass("Animator")
        if animator then
            for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                track:Stop(0.1) 
            end
        end
    end
    
    
    wait(0.1)
    
    
    FlightController.OriginalCharacterTransparency = {}
    for _, part in pairs(Character:GetChildren()) do
        if part:IsA("BasePart") then
            FlightController.OriginalCharacterTransparency[part] = part.Transparency
            part.Transparency = 1 
        end
    end
    
    
    FlightController.DummyModel = createDummyModel()
    
    if FlightController.DummyModel and FlightController.DummyModel.PrimaryPart then
        print
    else
        print
    end
end


local function hideDummy()
    
    for part, transparency in pairs(FlightController.OriginalCharacterTransparency) do
        if part and part.Parent then
            part.Transparency = transparency
        end
    end
    FlightController.OriginalCharacterTransparency = {}
    
    
    if FlightController.DummyUpdateConnection then
        FlightController.DummyUpdateConnection:Disconnect()
        FlightController.DummyUpdateConnection = nil
    end
    
    
    if FlightController.DummyModel then
        FlightController.DummyModel:Destroy()
        FlightController.DummyModel = nil
    end
end


local function setupDummyUpdate()
    if FlightController.DummyUpdateConnection then
        FlightController.DummyUpdateConnection:Disconnect()
    end
    
    FlightController.DummyUpdateConnection = RunService.RenderStepped:Connect(function()
        if not FlightController.IsFlying or not FlightController.DummyModel or not FlightController.DummyModel.PrimaryPart or not HumanoidRootPart then
            return
        end
        
        
        FlightController.DummyModel:SetPrimaryPartCFrame(HumanoidRootPart.CFrame)
    end)
end


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
