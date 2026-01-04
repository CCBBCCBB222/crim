local ESPModule = {}

local ESPConfig = {
    normalTransparency = 0.85,
    neonColor = Color3.fromRGB(0, 255, 255),
    glowColor = Color3.fromRGB(255, 215, 0),
    enabled = true,
    showBox = true,
    showGlow = true,
    showLight = true,
    bodyTransparency = 0.9
}

function ESPModule.createPlayerESP()
    local playerESPData = {}
    local camera = workspace.CurrentCamera
    
    local bodyPartsToHighlight = {
        "Head",
        "Torso",
        "Left Arm",
        "Right Arm",
        "Left Leg",
        "Right Leg"
    }
    
    local alternativeBodyParts = {
        Head = {"Head"},
        Torso = {"Torso", "UpperTorso", "LowerTorso"},
        LeftArm = {"Left Arm", "LeftUpperArm", "LeftLowerArm"},
        RightArm = {"Right Arm", "RightUpperArm", "RightLowerArm"},
        LeftLeg = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg"},
        RightLeg = {"Right Leg", "RightUpperLeg", "RightLowerLeg"}
    }
    
    local function isTool(part)
        local parent = part.Parent
        if not parent then
            return false
        end
        return parent:IsA("Tool")
    end
    
    local function isAccessory(part)
        local parent = part.Parent
        if not parent then
            return false
        end
        return parent:IsA("Accessory")
    end
    
    local function setPlayerPartsTransparency(character)
        if not character or not character.Parent then
            return
        end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                local isBodyPart = false
                
                for _, partName in ipairs(bodyPartsToHighlight) do
                    if part.Name == partName then
                        isBodyPart = true
                        break
                    end
                end
                
                for _, altNames in pairs(alternativeBodyParts) do
                    for _, partName in ipairs(altNames) do
                        if part.Name == partName then
                            isBodyPart = true
                            break
                        end
                    end
                end
                
                if isBodyPart then
                    part.Transparency = ESPConfig.bodyTransparency
                elseif isAccessory(part) then
                    part.Transparency = 1
                elseif isTool(part) then
                    continue
                end
            end
        end
    end
    
    local function removeESPForPlayer(player)
        local data = playerESPData[player]
        if data then
            if data.Character and data.Character.Parent then
                for _, part in ipairs(data.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local isBodyPart = false
                        
                        for _, partName in ipairs(bodyPartsToHighlight) do
                            if part.Name == partName then
                                isBodyPart = true
                                break
                            end
                        end
                        
                        for _, altNames in pairs(alternativeBodyParts) do
                            for _, partName in ipairs(altNames) do
                                if part.Name == partName then
                                    isBodyPart = true
                                    break
                                end
                            end
                        end
                        
                        if isBodyPart then
                            part.Transparency = 0
                        end
                    end
                end
            end
            
            for _, highlightData in ipairs(data.Highlights or {}) do
                if highlightData.Highlight and highlightData.Highlight.Parent then
                    highlightData.Highlight:Destroy()
                end
                
                if highlightData.GlowPart and highlightData.GlowPart.Parent then
                    highlightData.GlowPart:Destroy()
                end
                
                if highlightData.SurfaceLight and highlightData.SurfaceLight.Parent then
                    highlightData.SurfaceLight:Destroy()
                end
                
                if highlightData.WeldConstraint and highlightData.WeldConstraint.Parent then
                    highlightData.WeldConstraint:Destroy()
                end
            end
            
            if data.Character and data.Character.Parent then
                for _, descendant in ipairs(data.Character:GetDescendants()) do
                    if descendant.Name == "ESP_Highlight" or 
                       descendant.Name == "ESP_GlowPart" or 
                       descendant.Name == "ESP_SurfaceLight" then
                        descendant:Destroy()
                    end
                end
            end
            
            playerESPData[player] = nil
        end
    end
    
    local function createESPForPlayer(player)
        if player == game.Players.LocalPlayer then return end
        
        local character = player.Character
        if not character then return end
        
        character:WaitForChild("Humanoid")
        character:WaitForChild("HumanoidRootPart")
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then
            return
        end
        
        if ESPConfig.enabled then
            setPlayerPartsTransparency(character)
        end
        
        local highlightParts = {}
        
        local function findAndHighlightBodyPart(partNames)
            for _, partName in ipairs(partNames) do
                local part = character:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    local originalTransparency = part.Transparency
                    
                    local highlight
                    if ESPConfig.showBox then
                        highlight = Instance.new("BoxHandleAdornment")
                        highlight.Name = "ESP_Highlight"
                        highlight.Adornee = part
                        highlight.AlwaysOnTop = true
                        highlight.ZIndex = 10
                        highlight.Size = part.Size
                        highlight.Color3 = ESPConfig.neonColor
                        highlight.Transparency = ESPConfig.normalTransparency
                        highlight.Parent = part
                    end
                    
                    local glowPart, weldConstraint, surfaceLight
                    if ESPConfig.showGlow then
                        glowPart = Instance.new("Part")
                        glowPart.Name = "ESP_GlowPart"
                        glowPart.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
                        glowPart.CFrame = part.CFrame
                        glowPart.Color = ESPConfig.glowColor
                        glowPart.Material = Enum.Material.Neon
                        glowPart.Transparency = 0.3
                        glowPart.CanCollide = false
                        glowPart.Anchored = false
                        glowPart.CastShadow = false
                        
                        weldConstraint = Instance.new("WeldConstraint")
                        weldConstraint.Part0 = part
                        weldConstraint.Part1 = glowPart
                        weldConstraint.Parent = glowPart
                        
                        glowPart.Parent = character
                        
                        if ESPConfig.showLight then
                            surfaceLight = Instance.new("SurfaceLight")
                            surfaceLight.Name = "ESP_SurfaceLight"
                            surfaceLight.Brightness = 5
                            surfaceLight.Range = 0
                            surfaceLight.Color = ESPConfig.glowColor
                            surfaceLight.Angle = 180
                            surfaceLight.Face = Enum.NormalId.Front
                            surfaceLight.Enabled = true
                            surfaceLight.Parent = glowPart
                        end
                    end
                    
                    table.insert(highlightParts, {
                        Highlight = highlight, 
                        GlowPart = glowPart,
                        SurfaceLight = surfaceLight,
                        WeldConstraint = weldConstraint,
                        Part = part,
                        OriginalTransparency = originalTransparency
                    })
                    return true
                end
            end
            return false
        end
        
        for _, partName in ipairs(bodyPartsToHighlight) do
            findAndHighlightBodyPart({partName})
        end
        
        for partType, altNames in pairs(alternativeBodyParts) do
            if not findAndHighlightBodyPart(altNames) then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local size = part.Size
                        local position = part.Position
                        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
                        
                        if humanoidRootPart then
                            local relativePosition = position - humanoidRootPart.Position
                            
                            if partType == "Head" and relativePosition.Y > 2 then
                                local originalTransparency = part.Transparency
                                
                                local highlight
                                if ESPConfig.showBox then
                                    highlight = Instance.new("BoxHandleAdornment")
                                    highlight.Name = "ESP_Highlight"
                                    highlight.Adornee = part
                                    highlight.AlwaysOnTop = true
                                    highlight.ZIndex = 10
                                    highlight.Size = part.Size
                                    highlight.Color3 = ESPConfig.neonColor
                                    highlight.Transparency = ESPConfig.normalTransparency
                                    highlight.Parent = part
                                end
                                
                                local glowPart, weldConstraint
                                if ESPConfig.showGlow then
                                    glowPart = Instance.new("Part")
                                    glowPart.Name = "ESP_GlowPart"
                                    glowPart.Size = part.Size + Vector3.new(0.2, 0.2, 0.2)
                                    glowPart.CFrame = part.CFrame
                                    glowPart.Color = ESPConfig.glowColor
                                    glowPart.Material = Enum.Material.Neon
                                    glowPart.Transparency = 0.7
                                    glowPart.CanCollide = false
                                    glowPart.Anchored = false
                                    glowPart.CastShadow = false
                                    
                                    weldConstraint = Instance.new("WeldConstraint")
                                    weldConstraint.Part0 = part
                                    weldConstraint.Part1 = glowPart
                                    weldConstraint.Parent = glowPart
                                    
                                    glowPart.Parent = character
                                end
                                
                                table.insert(highlightParts, {
                                    Highlight = highlight, 
                                    GlowPart = glowPart,
                                    WeldConstraint = weldConstraint,
                                    Part = part,
                                    OriginalTransparency = originalTransparency
                                })
                                break
                            end
                        end
                    end
                end
            end
        end
        
        playerESPData[player] = {
            Character = character,
            Highlights = highlightParts
        }
    end
    
    local function updateESP()
        for player, data in pairs(playerESPData) do
            if not data.Character or not data.Character.Parent then
                removeESPForPlayer(player)
            else
                local humanoid = data.Character:FindFirstChildOfClass("Humanoid")
                if not humanoid or humanoid.Health <= 0 then
                    removeESPForPlayer(player)
                else
                    for _, highlightData in ipairs(data.Highlights or {}) do
                        if highlightData.Highlight and highlightData.Highlight.Parent then
                            highlightData.Highlight.Transparency = ESPConfig.normalTransparency
                        end
                        
                        if highlightData.GlowPart and highlightData.Part and highlightData.Part.Parent then
                            if not highlightData.GlowPart:FindFirstChild("WeldConstraint") then
                                local weldConstraint = Instance.new("WeldConstraint")
                                weldConstraint.Part0 = highlightData.Part
                                weldConstraint.Part1 = highlightData.GlowPart
                                weldConstraint.Parent = highlightData.GlowPart
                            end
                        end
                    end
                end
            end
        end
    end
    
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and ESPConfig.enabled then
                createESPForPlayer(player)
            end
        end
        
        player.CharacterAdded:Connect(function(character)
            wait(0.5)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and ESPConfig.enabled then
                createESPForPlayer(player)
            end
        end)
        
        player.CharacterRemoving:Connect(function()
            removeESPForPlayer(player)
        end)
    end
    
    game.Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            wait(0.5)
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 and ESPConfig.enabled then
                createESPForPlayer(player)
            end
        end)
        
        player.CharacterRemoving:Connect(function()
            removeESPForPlayer(player)
        end)
    end)
    
    local espConnection
    espConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if ESPConfig.enabled then
            updateESP()
        end
    end)
    
    local function toggleESP(value)
        ESPConfig.enabled = value
        
        if not ESPConfig.enabled then
            for player, _ in pairs(playerESPData) do
                removeESPForPlayer(player)
            end
        else
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player ~= game.Players.LocalPlayer then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        createESPForPlayer(player)
                    end
                end
            end
        end
    end
    
    local function destroyESP()
        toggleESP(false)
        if espConnection then
            espConnection:Disconnect()
        end
    end
    
    local function updateAllESPColors()
        for player, data in pairs(playerESPData) do
            if data.Character and data.Character.Parent then
                for _, highlightData in ipairs(data.Highlights or {}) do
                    if highlightData.Highlight and highlightData.Highlight.Parent then
                        highlightData.Highlight.Color3 = ESPConfig.neonColor
                    end
                    
                    if highlightData.GlowPart and highlightData.GlowPart.Parent then
                        highlightData.GlowPart.Color = ESPConfig.glowColor
                        
                        if highlightData.SurfaceLight and highlightData.SurfaceLight.Parent then
                            highlightData.SurfaceLight.Color = ESPConfig.glowColor
                        end
                    end
                end
            end
        end
    end
    
    local function updateConfig(newConfig)
        for key, value in pairs(newConfig) do
            if ESPConfig[key] ~= nil then
                ESPConfig[key] = value
            end
        end
        
        if ESPConfig.enabled then
            updateAllESPColors()
        end
        
        return true
    end
    
    return {
        Toggle = toggleESP,
        Destroy = destroyESP,
        Update = updateConfig,
        UpdateColors = updateAllESPColors,
        GetConfig = function() return ESPConfig end
    }
end

function ESPModule.getConfig()
    return ESPConfig
end

function ESPModule.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if ESPConfig[key] ~= nil then
            ESPConfig[key] = value
        end
    end
    return true
end

return ESPModule
