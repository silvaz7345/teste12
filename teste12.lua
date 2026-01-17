-- MAGNET BLOCKS - Dois anéis abertos (horizontal + vertical)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- GUI
local gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MagnetRingsGUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 160)
frame.Position = UDim2.new(0.05,0,0.3,0)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,35)
title.Text = "MAGNET RINGS"
title.TextColor3 = Color3.new(1,1,1)
title.BackgroundColor3 = Color3.fromRGB(45,45,45)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local btn = Instance.new("TextButton", frame)
btn.Size = UDim2.new(0.85,0,0,40)
btn.Position = UDim2.new(0.075,0,0.45,0)
btn.Text = "ATIVAR"
btn.Font = Enum.Font.Gotham
btn.TextSize = 14
btn.BackgroundColor3 = Color3.fromRGB(60,60,60)
btn.TextColor3 = Color3.new(1,1,1)

-- CONFIG
local magnet = false
local safeHeight = 3
local horizontalRadius = 10 -- aumentado
local verticalRadius = 10 -- aumentado
local pointsPerRing = 12

-- Pega todos os blocos do mapa
local function getAllBlocks()
    local list = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v.Anchored and not v:IsDescendantOf(character) and v.Size.Magnitude < 50 then
            table.insert(list, v)
        end
    end
    return list
end

-- Calcula offsets para os dois aneis
local function getRingOffsets()
    local offsets = {}
    -- Anel horizontal (XZ)
    for i = 0, pointsPerRing-1 do
        local angle = (i / pointsPerRing) * math.pi * 2
        table.insert(offsets, Vector3.new(math.cos(angle)*horizontalRadius, 0, math.sin(angle)*horizontalRadius))
    end
    -- Anel vertical (YZ)
    for i = 0, pointsPerRing-1 do
        local angle = (i / pointsPerRing) * math.pi * 2
        table.insert(offsets, Vector3.new(0, math.cos(angle)*verticalRadius, math.sin(angle)*verticalRadius))
    end
    return offsets
end

-- Move o bloco para targetPos
local function controlBlock(block, targetPos)
    if not block or not block.Parent then return end
    pcall(function() block:SetNetworkOwner(player) end)
    block.CanCollide = false
    block.Massless = true
    block.AssemblyLinearVelocity = Vector3.zero
    block.AssemblyAngularVelocity = Vector3.zero

    -- Evita atravessar o chão
    local ray = Ray.new(targetPos, Vector3.new(0,-100,0))
    local hit, pos = workspace:FindPartOnRay(ray)
    if hit then
        targetPos = Vector3.new(targetPos.X, math.max(pos.Y + safeHeight, targetPos.Y), targetPos.Z)
    end

    local bp = block:FindFirstChild("BP")
    local bg = block:FindFirstChild("BG")
    if not bp then
        bp = Instance.new("BodyPosition")
        bp.Name = "BP"
        bp.MaxForce = Vector3.new(1e9,1e9,1e9)
        bp.P = 50000
        bp.D = 500
        bp.Position = targetPos
        bp.Parent = block
    else
        bp.Position = bp.Position:Lerp(targetPos, 0.3)
    end

    if not bg then
        bg = Instance.new("BodyGyro")
        bg.Name = "BG"
        bg.MaxTorque = Vector3.new(1e9,1e9,1e9)
        bg.P = 5000
        bg.CFrame = CFrame.new(block.Position)
        bg.Parent = block
    else
        bg.CFrame = CFrame.new(block.Position)
    end
end

-- Loop principal
RunService.Heartbeat:Connect(function()
    if magnet then
        local list = getAllBlocks()
        local offsets = getRingOffsets()
        for i, offset in ipairs(offsets) do
            local block = list[i]
            if block then
                local targetPos = hrp.Position + offset + Vector3.new(0, safeHeight,0)
                controlBlock(block, targetPos)
            end
        end
    end
end)

-- Botão ativar/desativar
btn.MouseButton1Click:Connect(function()
    magnet = not magnet
    btn.Text = magnet and "DESATIVAR" or "ATIVAR"
    if not magnet then
        local list = getAllBlocks()
        for _, part in ipairs(list) do
            if part and part.Parent then
                part.CanCollide = true
                if part:FindFirstChild("BP") then part.BP:Destroy() end
                if part:FindFirstChild("BG") then part.BG:Destroy() end
            end
        end
    end
end)
