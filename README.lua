--[[
    Bike Scanner Pro v23 (LocalScript)
    ÐžÐ½Ð¾Ð²Ð»ÐµÐ½Ð¾: BOOST SPEED Ñ‚ÐµÐ¿ÐµÑ€ Ð¿Ñ€Ð°Ñ†ÑŽÑ” ÑÐº ON/OFF Ð¿ÐµÑ€ÐµÐ¼Ð¸ÐºÐ°Ñ‡.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")

-- === GUI ===
local gui = Instance.new("ScreenGui")
gui.Name = "BikeScannerPro"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local panel = Instance.new("ScrollingFrame")
panel.Size = UDim2.new(0, 300, 0, 480)
panel.Position = UDim2.new(1, -310, 0.5, -240) 
panel.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel = 0
panel.ScrollBarThickness = 4
panel.CanvasSize = UDim2.new(0, 0, 0, 950)
panel.Active = true
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(0, 255, 200)
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.5
panelStroke.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 44)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "ðŸ” BIKE SCANNER PRO"
title.TextColor3 = Color3.fromRGB(0, 255, 200)
title.Font = Enum.Font.GothamBlack
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

-- === Ð¢Ð•Ð›Ð•ÐœÐ•Ð¢Ð Ð†Ð¯ ===
local telemetry = Instance.new("TextLabel")
telemetry.Size = UDim2.new(1, -20, 0, 20)
telemetry.Position = UDim2.new(0, 10, 0, 50)
telemetry.BackgroundTransparency = 1
telemetry.Text = "ðŸ“¡ SYSTEM: ONLINE | TILT: 0Â°"
telemetry.TextColor3 = Color3.fromRGB(0, 255, 0)
telemetry.Font = Enum.Font.Code
telemetry.TextSize = 12
telemetry.TextXAlignment = Enum.TextXAlignment.Left
telemetry.Parent = panel

-- Dragging Logic
local dragging, dragInput, dragStart, startPos
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = panel.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
    end
end)
title.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- === VIEWPORT ===
local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1, -20, 0, 160)
viewport.Position = UDim2.new(0, 10, 0, 75)
viewport.BackgroundColor3 = Color3.fromRGB(3, 3, 8)
viewport.BorderSizePixel = 0
viewport.Ambient = Color3.fromRGB(150, 150, 150)
viewport.Parent = panel

local camera = Instance.new("Camera")
camera.FieldOfView = 40
camera.Parent = viewport
viewport.CurrentCamera = camera

-- === STATE ===
local bikeClone = nil
local realBike = nil
local angle = 0
local autoRotate = true
local myPointLight = nil
local mySpotLight = nil
local autoAlign = true
local antiFly = false
local crouchSpoof = false
local originalBikePosition = nil
local isBoostActive = false
local currentBoostForce = nil -- Ð—Ð±ÐµÑ€Ñ–Ð³Ð°Ñ”Ð¼Ð¾ ÑÐ¸Ð»Ñƒ Ð±ÑƒÑÑ‚Ñƒ, Ñ‰Ð¾Ð± Ð²Ð¸Ð¼ÐºÐ½ÑƒÑ‚Ð¸

local function findBike()
    local char = player.Character
    if not char then return nil end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid and humanoid.SeatPart then
        return humanoid.SeatPart.Parent
    end
    local seat = char:FindFirstChildWhichIsA("VehicleSeat")
    if seat then return seat.Parent end
    return nil
end

-- === ÐÐ’Ð¢Ðž-ÐŸÐ•Ð Ð•Ð¡Ð†Ð”ÐÐÐÐ¯ ===
local function forceSit()
    local char = player.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    if humanoid.SeatPart then return end
    
    local closestSeat = nil
    local shortestDist = 10
    
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Model") then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("VehicleSeat") then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (part.Position - root.Position).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            closestSeat = part
                        end
                    end
                end
            end
        end
    end
    if closestSeat then closestSeat:Sit(humanoid) end
end

task.spawn(function()
    while task.wait(0.2) do forceSit() end
end)

-- PAINTING
local function paintBike(model, color)
    if not model then return end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            local nameLower = string.lower(part.Name)
            local isWheelName = string.find(nameLower, "wheel") or string.find(nameLower, "tire") or string.find(nameLower, "rim") or string.find(nameLower, "spoke") or string.find(nameLower, "guma") or string.find(nameLower, "koleso") or string.find(nameLower, "disc")
            local isWheelMaterial = part.Material == Enum.Material.Rubber or part.Material == Enum.Material.Glass or part.Material == Enum.Material.Neon
            local parentIsWheel = false
            local parent = part.Parent
            if parent and parent:IsA("Model") then
                local pName = string.lower(parent.Name)
                if string.find(pName, "wheel") or string.find(pName, "tire") then parentIsWheel = true end
            end
            if not isWheelName and not isWheelMaterial and not parentIsWheel then
                part.Color = color
            end
        end
    end
end

-- LIGHTS
local function setupLights()
    if not realBike then return end
    if myPointLight then myPointLight:Destroy() end
    if mySpotLight then mySpotLight:Destroy() end
    local root = realBike.PrimaryPart or realBike:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    myPointLight = Instance.new("PointLight")
    myPointLight.Color = Color3.fromRGB(0, 255, 150)
    myPointLight.Range = 12
    myPointLight.Brightness = 2
    myPointLight.Enabled = false
    myPointLight.Parent = root

    mySpotLight = Instance.new("SpotLight")
    mySpotLight.Color = Color3.fromRGB(255, 255, 220)
    mySpotLight.Range = 30
    mySpotLight.Brightness = 3
    mySpotLight.Angle = 60
    mySpotLight.Face = Enum.NormalId.Front
    mySpotLight.Enabled = false
    mySpotLight.Parent = root
end

-- CROUCH SPOOF
local function updateCrouchSpoof(state)
    crouchSpoof = state
    if not realBike then return end
    local root = realBike.PrimaryPart or realBike:FindFirstChildWhichIsA("BasePart")
    if not root then return end

    if crouchSpoof then
        if not originalBikePosition then originalBikePosition = root.Position end
        for _, part in ipairs(realBike:GetDescendants()) do
            if part:IsA("BasePart") then
                local nameLower = string.lower(part.Name)
                if string.find(nameLower, "wheel") or string.find(nameLower, "tire") or part.Name == "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
        end
        root.CFrame = root.CFrame * CFrame.new(0, -1.5, 0)
    else
        if originalBikePosition then root.CFrame = CFrame.new(originalBikePosition) * root.CFrame.Rotation end
        for _, part in ipairs(realBike:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

-- AUTO ALIGN & TELEMETRY
RunService.Heartbeat:Connect(function(dt)
    if realBike then
        local root = realBike.PrimaryPart or realBike:FindFirstChildWhichIsA("BasePart")
        if root then
            local upVector = root.CFrame.UpVector
            local angleDeg = math.deg(math.acos(math.clamp(upVector.Y, -1, 1)))
            
            if angleDeg > 90 then
                telemetry.Text = string.format("âš ï¸ SYSTEM: RECOVERY | TILT: %dÂ°", angleDeg)
                telemetry.TextColor3 = Color3.fromRGB(255, 0, 0)
            else
                telemetry.Text = string.format("ðŸ“¡ SYSTEM: ONLINE | TILT: %dÂ°", angleDeg)
                telemetry.TextColor3 = Color3.fromRGB(0, 255, 0)
            end

            -- ÐžÐ½Ð¾Ð²Ð»ÑŽÑ”Ð¼Ð¾ ÑÐ¸Ð»Ñƒ Ð±ÑƒÑÑ‚Ñƒ, ÑÐºÑ‰Ð¾ Ð²Ñ–Ð½ Ð°ÐºÑ‚Ð¸Ð²Ð½Ð¸Ð¹ (Ñ‰Ð¾Ð± Ð²Ñ–Ð½ Ð·Ð°Ð²Ð¶Ð´Ð¸ ÑˆÑ‚Ð¾Ð²Ñ…Ð°Ð² Ð²Ð¿ÐµÑ€ÐµÐ´)
            if isBoostActive and currentBoostForce then
                local lookDir = root.CFrame.LookVector
                currentBoostForce.VectorVelocity = Vector3.new(lookDir.X, 0, lookDir.Z).Unit * 150
            end

            if antiFly then
                if root.Velocity.Y > 0 then
                    root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
                end
            end

            if autoAlign then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {realBike, player.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                local ray = workspace:Raycast(root.Position, Vector3.new(0, -15, 0), raycastParams)
                
                if not ray then
                    if angleDeg > 90 then 
                        local currentLook = root.CFrame.LookVector
                        local flatLook = Vector3.new(currentLook.X, 0, currentLook.Z)
                        if flatLook.Magnitude > 0.1 then flatLook = flatLook.Unit else flatLook = Vector3.new(0, 0, -1) end
                        local targetCFrame = CFrame.lookAt(root.Position, root.Position + flatLook, Vector3.new(0, 1, 0))
                        local newCFrame = root.CFrame:Lerp(targetCFrame, 0.1)
                        root.CFrame = CFrame.new(root.Position) * newCFrame.Rotation
                    end
                end
            end
        end
    end
end)

local function scanBike()
    if bikeClone then bikeClone:Destroy() end
    realBike = findBike()
    if not realBike then
        title.Text = "âŒ Ð¡Ð¯Ð”Ð¬ ÐÐ Ð‘ÐÐ™Ðš!"
        task.wait(1.5)
        title.Text = "ðŸ” BIKE SCANNER PRO"
        return
    end

    title.Text = "â³ SCANNING..."
    task.wait(0.5)
    
    setupLights()
    originalBikePosition = nil

    bikeClone = realBike:Clone()
    bikeClone.Parent = viewport
    for _, obj in ipairs(bikeClone:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("Light") then obj:Destroy() end
    end

    bikeClone:PivotTo(CFrame.new(0, 0, 0))
    camera.CFrame = CFrame.new(0, 2, 7) * CFrame.Angles(math.rad(-15), 0, 0)
    
    title.Text = "âœ… Ð‘ÐÐ™Ðš Ð’Ð†Ð”Ð¡ÐšÐÐÐžÐ’ÐÐÐž"
    task.wait(1.2)
    title.Text = "ðŸ” BIKE SCANNER PRO"
end

RunService.RenderStepped:Connect(function(dt)
    if bikeClone and autoRotate then
        angle = angle + dt * 0.8
        bikeClone:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, angle, 0))
    end
end)

-- Scan Button
local scanBtn = Instance.new("TextButton")
scanBtn.Size = UDim2.new(1, -20, 0, 38)
scanBtn.Position = UDim2.new(0, 10, 0, 245)
scanBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 140)
scanBtn.Text = "ðŸ”„ SCAN BIKE"
scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
scanBtn.Font = Enum.Font.GothamBold
scanBtn.BorderSizePixel = 0
scanBtn.Parent = panel
Instance.new("UICorner", scanBtn).CornerRadius = UDim.new(0, 10)
scanBtn.MouseButton1Click:Connect(scanBike)

-- BOOST BUTTON (ON/OFF)
local boostBtn = Instance.new("TextButton")
boostBtn.Size = UDim2.new(1, -20, 0, 38)
boostBtn.Position = UDim2.new(0, 10, 0, 290)
boostBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0) -- Ð§ÐµÑ€Ð²Ð¾Ð½Ð¸Ð¹ Ð·Ð° Ð·Ð°Ð¼Ð¾Ð²Ñ‡ÑƒÐ²Ð°Ð½Ð½ÑÐ¼
boostBtn.Text = "ðŸš€ BOOST SPEED: OFF"
boostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
boostBtn.Font = Enum.Font.GothamBlack
boostBtn.TextSize = 14
boostBtn.BorderSizePixel = 0
boostBtn.Parent = panel
Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0, 10)

boostBtn.MouseButton1Click:Connect(function()
    isBoostActive = not isBoostActive
    
    local char = player.Character
    if not char then return end
    local seat = char:FindFirstChildWhichIsA("VehicleSeat") or (char.Humanoid and char.Humanoid.SeatPart)
    
    if isBoostActive then
        -- Ð’ÐœÐ˜ÐšÐÐ„ÐœÐž Ð‘Ð£Ð¡Ð¢
        if seat and seat:IsA("VehicleSeat") then
            local root = seat.Parent.PrimaryPart or seat.Parent:FindFirstChildWhichIsA("BasePart")
            if root then
                boostBtn.Text = "ðŸš€ BOOST SPEED: ON"
                boostBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
                
                -- Ð¡Ñ‚Ð²Ð¾Ñ€ÑŽÑ”Ð¼Ð¾ Ð¿Ð¾ÑÑ‚Ñ–Ð¹Ð½Ñƒ ÑÐ¸Ð»Ñƒ
                currentBoostForce = Instance.new("LinearVelocity")
                currentBoostForce.MaxForce = math.huge
                local att = Instance.new("Attachment", root)
                currentBoostForce.Attachment0 = att
                
                local lookDir = root.CFrame.LookVector
                currentBoostForce.VectorVelocity = Vector3.new(lookDir.X, 0, lookDir.Z).Unit * 150
                currentBoostForce.Parent = root
            end
        end
    else
        -- Ð’Ð˜ÐœÐ˜ÐšÐÐ„ÐœÐž Ð‘Ð£Ð¡Ð¢
        boostBtn.Text = "ðŸš€ BOOST SPEED: OFF"
        boostBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
        
        if currentBoostForce then
            currentBoostForce:Destroy()
            if currentBoostForce.Parent and currentBoostForce.Parent:FindFirstChildOfClass("Attachment") then
                currentBoostForce.Parent:FindFirstChildOfClass("Attachment"):Destroy()
            end
            currentBoostForce = nil
        end
    end
end)

-- ðŸ¦† CROUCH SPOOF BUTTON
local crouchBtn = Instance.new("TextButton")
crouchBtn.Size = UDim2.new(1, -20, 0, 38)
crouchBtn.Position = UDim2.new(0, 10, 0, 335)
crouchBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
crouchBtn.Text = "ðŸ¦† CROUCH SPOOF: OFF"
crouchBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
crouchBtn.Font = Enum.Font.GothamBlack
crouchBtn.TextSize = 14
crouchBtn.BorderSizePixel = 0
crouchBtn.Parent = panel
Instance.new("UICorner", crouchBtn).CornerRadius = UDim.new(0, 10)

crouchBtn.MouseButton1Click:Connect(function()
    local newState = not crouchSpoof
    updateCrouchSpoof(newState)
    
    if crouchSpoof then
        crouchBtn.Text = "ðŸ¦† CROUCH SPOOF: ON"
        crouchBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        crouchBtn.Text = "ðŸ¦† CROUCH SPOOF: OFF"
        crouchBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- ðŸ§² ANTI-BIKE FLY BUTTON
local antiFlyBtn = Instance.new("TextButton")
antiFlyBtn.Size = UDim2.new(1, -20, 0, 38)
antiFlyBtn.Position = UDim2.new(0, 10, 0, 380)
antiFlyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
antiFlyBtn.Text = "ðŸ§² ANTI-BIKE FLY: OFF"
antiFlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
antiFlyBtn.Font = Enum.Font.GothamBlack
antiFlyBtn.TextSize = 14
antiFlyBtn.BorderSizePixel = 0
antiFlyBtn.Parent = panel
Instance.new("UICorner", antiFlyBtn).CornerRadius = UDim.new(0, 10)

antiFlyBtn.MouseButton1Click:Connect(function()
    antiFly = not antiFly
    if antiFly then
        antiFlyBtn.Text = "ðŸ§² ANTI-BIKE FLY: ON"
        antiFlyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        antiFlyBtn.Text = "ðŸ§² ANTI-BIKE FLY: OFF"
        antiFlyBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- AUTO ALIGN TOGGLE BUTTON
local alignBtn = Instance.new("TextButton")
alignBtn.Size = UDim2.new(1, -20, 0, 38)
alignBtn.Position = UDim2.new(0, 10, 0, 425)
alignBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
alignBtn.Text = "ðŸ”„ AUTO-ALIGN: ON"
alignBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
alignBtn.Font = Enum.Font.GothamBlack
alignBtn.TextSize = 14
alignBtn.BorderSizePixel = 0
alignBtn.Parent = panel
Instance.new("UICorner", alignBtn).CornerRadius = UDim.new(0, 10)

alignBtn.MouseButton1Click:Connect(function()
    autoAlign = not autoAlign
    if autoAlign then
        alignBtn.Text = "ðŸ”„ AUTO-ALIGN: ON"
        alignBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    else
        alignBtn.Text = "ðŸ”„ AUTO-ALIGN: OFF"
        alignBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    end
end)

-- Colors
local colors = {
    {color = Color3.fromRGB(255, 60, 60)}, {color = Color3.fromRGB(255, 200, 60)},
    {color = Color3.fromRGB(60, 255, 120)}, {color = Color3.fromRGB(60, 160, 255)},
    {color = Color3.fromRGB(255, 255, 255)}, {color = Color3.fromRGB(80, 80, 80)}
}

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, -20, 0, 80)
grid.Position = UDim2.new(0, 10, 0, 475)
grid.BackgroundTransparency = 1
grid.Parent = panel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 40, 0, 40)
gridLayout.CellPadding = UDim2.new(0, 4, 0, 4)
gridLayout.Parent = grid

for i, c in ipairs(colors) do
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = c.color
    btn.BorderSizePixel = 0
    btn.LayoutOrder = i
    btn.Parent = grid
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function()
        paintBike(realBike, c.color)
        if bikeClone then paintBike(bikeClone, c.color) end
    end)
end

-- Sliders Base Function
local function makeSlider(labelText, yPos, minVal, maxVal, defaultVal, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ": " .. defaultVal
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = panel

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 8)
    sliderBg.Position = UDim2.new(0, 10, 0, yPos + 20)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = panel
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local draggingSlider = false
    local function update(input)
        local relX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
        local alpha = relX / sliderBg.AbsoluteSize.X
        local value = math.floor(minVal + (maxVal - minVal) * alpha)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        label.Text = labelText .. ": " .. value
        callback(value)
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true; update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            update(input)
        end
    end)
