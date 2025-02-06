local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Highlights = {}

-- Function to check if a player is an enemy (not on the same team)
local function isEnemy(player)
    if LocalPlayer.Team == nil or player.Team == nil then
        return true -- If teams don't exist, highlight everyone
    end
    return LocalPlayer.Team ~= player.Team
end

-- Function to create highlight effect for an enemy
local function createHighlight(player)
    if player == LocalPlayer or not player.Character or not isEnemy(player) then return end

    -- Remove old highlight if it exists (prevents duplicates)
    if Highlights[player] then
        Highlights[player]:Destroy()
        Highlights[player] = nil
    end

    -- Create new highlight
    local highlight = Instance.new("Highlight")
    highlight.Parent = player.Character
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    Highlights[player] = highlight

    -- Increase hitbox size for the player by scaling the HumanoidRootPart to 3x
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.Size = humanoidRootPart.Size * 3 -- Increase size by 3x
        humanoidRootPart.CanCollide = true -- Ensure it can still collide
    end
end

-- Function to remove ESP when a player dies
local function removeHighlight(player)
    if Highlights[player] then
        Highlights[player]:Destroy()
        Highlights[player] = nil
    end

    -- Reset hitbox size if needed
    local humanoidRootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.Size = humanoidRootPart.Size / 3 -- Reset size to original
    end
end

-- Function to update highlight colors with a rainbow effect
local function updateRainbowEffect()
    local hue = 0
    while true do
        hue = (hue + 10) % 360 -- Faster color shift
        local color = Color3.fromHSV(hue / 360, 1, 1)

        -- Update the color of highlights for enemies
        for player, highlight in pairs(Highlights) do
            if player and player.Character and isEnemy(player) then
                highlight.FillColor = color
                highlight.OutlineColor = color
                highlight.Enabled = true -- Keep ESP for enemies
            else
                highlight.Enabled = false -- Hide ESP for teammates
            end
        end
        task.wait(0.03) -- Faster color cycling
    end
end

-- Function to refresh ESP every second (detects respawns)
local function refreshESP()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and isEnemy(player) then
                createHighlight(player)
            end
        end
        task.wait(1) -- Refresh every second
    end
end

-- Function to disconnect connections to avoid memory leaks
local function cleanUpPlayer(player)
    -- Disconnect the player's death event to avoid memory leaks
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Disconnect()
    end

    -- Clean up highlights and other objects when the player leaves
    removeHighlight(player)
end

-- Detect player respawns and handle cleanup when they leave
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5) -- Short delay to ensure character loads
        createHighlight(player)

        -- Detect if player dies and remove ESP
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local diedConnection
            diedConnection = humanoid.Died:Connect(function()
                removeHighlight(player)
                diedConnection:Disconnect() -- Disconnect to prevent memory leaks
            end)
        end
    end)

    -- Clean up when player leaves
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            cleanUpPlayer(player)
        end
    end)
end)

-- Start the rainbow effect and refresh loop
task.spawn(updateRainbowEffect)
task.spawn(refreshESP)
