local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local targetPlayer
local isResettingManually = Instance.new("BoolValue")
isResettingManually.Name = "IsResettingManually"
isResettingManually.Value = false
isResettingManually.Parent = player

local spinSpeed = 30 -- This variable holds the current spin speed
local radius = 5
local angle = 0
local spinningConnection -- This will hold the connection for the spinning effect

-- Function to find a player by part of their username or display name
local function findPlayerByName(partialName)
    partialName = string.lower(partialName)
    for _, otherPlayer in pairs(Players:GetPlayers()) do
        -- Compare both username and display name
        if string.find(string.lower(otherPlayer.Name), partialName) or string.find(string.lower(otherPlayer.DisplayName), partialName) then
            return otherPlayer
        end
    end
    return nil -- Return nil if no player found
end

-- Function to make accessories spin around the target player
local function spinAccessoriesAroundPlayer(targetPlayer)
    if spinningConnection then
        spinningConnection:Disconnect() -- Stop previous spinning effect
    end

    local accessories = {}

    -- Collect all hats and hairs (accessories)
    for _, accessory in ipairs(character:GetChildren()) do
        if accessory:IsA("Accessory") then
            table.insert(accessories, accessory)
        end
    end

    -- Set up the spinning effect
    spinningConnection = RunService.Heartbeat:Connect(function(deltaTime)
        -- Update angle based on spinSpeed
        angle = angle + (spinSpeed * deltaTime)

        for i, accessory in ipairs(accessories) do
            local offsetAngle = angle + (math.pi * 2 / #accessories) * i
            local offsetX = math.cos(offsetAngle) * radius
            local offsetZ = math.sin(offsetAngle) * radius

            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local targetPosition = targetPlayer.Character.HumanoidRootPart.Position + Vector3.new(offsetX, 2, offsetZ)
                accessory.Handle.CFrame = CFrame.new(targetPosition) * CFrame.Angles(0, offsetAngle, 0)
            end
        end
    end)
end

-- Function to force the player to reset
local function forceReset()
    if player.Character and player.Character:FindFirstChild("Humanoid") then
        player.Character.Humanoid:TakeDamage(player.Character.Humanoid.MaxHealth)
    end
end

-- Function to initialize and start the reset loop
local function startResetLoop()
    while true do
        if isResettingManually.Value then
            forceReset()
        end
        wait(1)
    end
end

-- Event listener for when the player dies (resets)
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    wait(1)
    if targetPlayer then
        spinAccessoriesAroundPlayer(targetPlayer) -- Spin accessories with the last set speed
    end
end)

-- Function to handle chat messages
local function handleChatMessage(message, player)
    -- Check for ";speed" command
    if string.sub(message.Text, 1, 6) == ";speed" then
        local newSpeed = tonumber(string.sub(message.Text, 8))
        if newSpeed then
            spinSpeed = newSpeed -- Update spinSpeed with the new value
            print("Spin speed set to " .. newSpeed)
        end
    end

    -- Check for ";ra" (radius) command
    if string.sub(message.Text, 1, 3) == ";ra" then
        local newRadius = tonumber(string.sub(message.Text, 5))
        if newRadius then
            radius = newRadius
            print("Radius set to " .. newRadius)
        end
    end

    -- Check for ";a" (angle) command
    if string.sub(message.Text, 1, 2) == ";a" then
        local newAngle = tonumber(string.sub(message.Text, 4))
        if newAngle then
            angle = newAngle
            print("Angle set to " .. newAngle)
        end
    end

    -- Check for ";h" command (find player by partial name)
    if string.sub(message.Text, 1, 2) == ";h" then
        local partialName = string.sub(message.Text, 4)
        if partialName then
            local foundPlayer = findPlayerByName(partialName)
            if foundPlayer then
                targetPlayer = foundPlayer
                isResettingManually.Value = true -- Set to true to enable continuous resetting
                print("Target player set to " .. foundPlayer.Name)
                spinAccessoriesAroundPlayer(targetPlayer) -- Start spinning with the current speed
            else
                print("No player found with name part: " .. partialName)
            end
        end
    end
end

-- Connect to the new TextChatService
TextChatService.OnIncomingMessage = function(message)
    if message.TextSource and message.TextSource.UserId == player.UserId then
        handleChatMessage(message, player)
    end
end

-- Start the reset loop in a separate coroutine
coroutine.wrap(startResetLoop)()
