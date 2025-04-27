local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local ESP_ENABLED = true
local TOGGLE_KEY = Enum.KeyCode.T
local ESP_COLOR = Color3.fromRGB(255, 255, 255)
local ESP_THICKNESS = 2
local ESP_OPACITY = 0.8
local BOX_FILLED = false
local SHOW_NAMES = true
local SHOW_HEALTH = true
local SHOW_DISTANCE = true
local NAME_SIZE = 16
local NAME_FONT = "Monospace"
local NAME_OUTLINE_COLOR = Color3.fromRGB(0, 0, 0)

local espObjects = {}
local connections = {}

local function calculateDistance(position1, position2)
    return (position1 - position2).Magnitude
end

local function abbreviateNumber(number)
    local abbreviations = {
        ["K"] = 10^3,
        ["M"] = 10^6,
        ["B"] = 10^9,
        ["T"] = 10^12
    }

    for suffix, value in pairs(abbreviations) do
        if number >= value then
            return string.format("%.1f%s", number/value, suffix)
        end
    end
    return tostring(math.floor(number))
end

local function createESP(player)
    if not player or not player.Character then return end

    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not head or not rootPart then return end

    local esp = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        health = Drawing.new("Text"),
        distance = Drawing.new("Text")
    }

    esp.box.Visible = false
    esp.box.Color = ESP_COLOR
    esp.box.Thickness = ESP_THICKNESS
    esp.box.Filled = BOX_FILLED
    esp.box.Transparency = ESP_OPACITY

    esp.name.Visible = SHOW_NAMES
    esp.name.Color = ESP_COLOR
    esp.name.Outline = true
    esp.name.OutlineColor = NAME_OUTLINE_COLOR
    esp.name.Size = NAME_SIZE
    esp.name.Font = Drawing.Fonts[NAME_FONT]
    esp.name.Text = "@"..player.Name

    esp.health.Visible = SHOW_HEALTH
    esp.health.Color = ESP_COLOR
    esp.health.Outline = true
    esp.health.OutlineColor = NAME_OUTLINE_COLOR
    esp.health.Size = NAME_SIZE
    esp.health.Font = Drawing.Fonts[NAME_FONT]

    esp.distance.Visible = SHOW_DISTANCE
    esp.distance.Color = ESP_COLOR
    esp.distance.Outline = true
    esp.distance.OutlineColor = NAME_OUTLINE_COLOR
    esp.distance.Size = NAME_SIZE
    esp.distance.Font = Drawing.Fonts[NAME_FONT]

    espObjects[player] = esp

    connections[player] = character.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if espObjects[player] then
                for _, obj in pairs(espObjects[player]) do
                    if obj then obj:Remove() end
                end
                espObjects[player] = nil
            end
            if connections[player] then
                connections[player]:Disconnect()
                connections[player] = nil
            end
        end
    end)
end

local function updateESP()
    for player, esp in pairs(espObjects) do
        if not player or not player.Character then
            for _, obj in pairs(esp) do
                if obj then obj:Remove() end
            end
            espObjects[player] = nil
            if connections[player] then
                connections[player]:Disconnect()
                connections[player] = nil
            end
        else
            local character = player.Character
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local head = character:FindFirstChild("Head")
            local rootPart = character:FindFirstChild("HumanoidRootPart")

            if humanoid and head and rootPart then
                local headPos, headVisible = Workspace.CurrentCamera:WorldToViewportPoint(head.Position)
                local rootPos = Workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)

                if headVisible then

                    local topPos = Workspace.CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                    local bottomPos = Workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

                    local boxSize = Vector2.new(2350 / rootPos.Z, topPos.Y - bottomPos.Y)
                    local boxPosition = Vector2.new(rootPos.X - boxSize.X / 2, rootPos.Y - boxSize.Y / 2)

                    esp.box.Size = boxSize
                    esp.box.Position = boxPosition
                    esp.box.Visible = ESP_ENABLED

                    esp.name.Position = Vector2.new(rootPos.X, rootPos.Y + boxSize.Y / 2 - 25)
                    esp.name.Visible = ESP_ENABLED and SHOW_NAMES

                    esp.health.Text = string.format("[%s%%]", math.floor(humanoid.Health))
                    esp.health.Position = Vector2.new(rootPos.X, headPos.Y)
                    esp.health.Visible = ESP_ENABLED and SHOW_HEALTH

                    local localPlayer = Players.LocalPlayer
                    if localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        local distance = calculateDistance(
                            rootPart.Position,
                            localPlayer.Character.HumanoidRootPart.Position
                        )
                        esp.distance.Text = string.format("[%sm]", abbreviateNumber(distance))
                        esp.distance.Position = Vector2.new(rootPos.X, rootPos.Y)
                        esp.distance.Visible = ESP_ENABLED and SHOW_DISTANCE
                    end
                else

                    esp.box.Visible = false
                    esp.name.Visible = false
                    esp.health.Visible = false
                    esp.distance.Visible = false
                end
            end
        end
    end
end

local function initializeESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            createESP(player)
        end
    end
end

local function setupConnections()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            createESP(player)
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if espObjects[player] then
            for _, obj in pairs(espObjects[player]) do
                if obj then obj:Remove() end
            end
            espObjects[player] = nil
        end
        if connections[player] then
            connections[player]:Disconnect()
            connections[player] = nil
        end
    end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == TOGGLE_KEY then
        ESP_ENABLED = not ESP_ENABLED
        for _, esp in pairs(espObjects) do
            esp.box.Visible = ESP_ENABLED
            esp.name.Visible = ESP_ENABLED and SHOW_NAMES
            esp.health.Visible = ESP_ENABLED and SHOW_HEALTH
            esp.distance.Visible = ESP_ENABLED and SHOW_DISTANCE
        end
    end
end)

initializeESP()
setupConnections()

RunService.Heartbeat:Connect(function()
    if ESP_ENABLED then
        updateESP()
    end
end)