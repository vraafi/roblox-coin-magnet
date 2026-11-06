-- CoinMagnet.lua
-- ModuleScript for Roblox Coin Magnet power-up

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- Default configuration (can be overridden by config.json)
local defaultConfig = {
    radius = 20,            -- Radius within which coins are attracted
    cooldown = 5,           -- Seconds before a collected coin respawns
    maxPerPlayer = 3,       -- Max number of coins a player can hold at once
    attractionSpeed = 50,   -- Speed at which coins move towards the player
    enabled = true          -- Global toggle for the module
}

local CoinMagnet = {}
CoinMagnet.__index = CoinMagnet

-- Helper to find all coins in the workspace
local function getAllCoins()
    local coins = {}
    for _, part in ipairs(workspace:GetDescendants()) do
        if part:IsA("BasePart") and CollectionService:HasTag(part, "Coin") then
            table.insert(coins, part)
        end
    end
    return coins
end

-- Helper to move a coin towards a target position
local function moveCoinTowards(coin, targetPos, speed, deltaTime)
    local direction = (targetPos - coin.Position).Unit
    local newPos = coin.Position + direction * speed * deltaTime
    coin.CFrame = CFrame.new(newPos)
end

-- CoinMagnet constructor
function CoinMagnet.new(config)
    local self = setmetatable({}, CoinMagnet)
    self.config = config or {}
    for k, v in pairs(defaultConfig) do
        if self.config[k] == nil then
            self.config[k] = v
        end
    end

    self.players = {}
    self.connections = {}
    self.active = self.config.enabled

    -- Heartbeat loop
    local heartbeatConn = RunService.Heartbeat:Connect(function(dt)
        if not self.active then return end
        for player, data in pairs(self.players) do
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                local coins = getAllCoins()
                for _, coin in ipairs(coins) do
                    if not coin:GetAttribute("Collected") then
                        local dist = (coin.Position - hrp.Position).Magnitude
                        if dist <= self.config.radius then
                            moveCoinTowards(coin, hrp.Position, self.config.attractionSpeed, dt)
                        end
                    end
                end
            end
        end
    end)
    table.insert(self.connections, heartbeatConn)

    return self
end

-- Activate magnet for a player
function CoinMagnet:AddPlayer(player)
    if not player or self.players[player] then return end
    self.players[player] = {coinsHeld = 0}

    -- Listen for coin collection via tag
    local collectConn = CollectionService:GetInstanceAddedSignal("CoinCollected"):Connect(function(coin, collector)
        if collector == player then
            if self.players[player].coinsHeld < self.config.maxPerPlayer then
                self.players[player].coinsHeld = self.players[player].coinsHeld + 1
                coin:SetAttribute("Collected", true)
                -- Disable coin physics
                coin.CanCollide = false
                coin.Anchored = true
                -- Respawn after cooldown
                task.delay(self.config.cooldown, function()
                    if coin then
                        coin.Position = coin:GetAttribute("OriginalPosition") or coin.Position
                        coin.CanCollide = true
                        coin.Anchored = false
                        coin:SetAttribute("Collected", false)
                    end
                end)
            end
        end
    end)
    table.insert(self.connections, collectConn)
end

-- Deactivate magnet for a player
function CoinMagnet:RemovePlayer(player)
    if not player or not self.players[player] then return end
    self.players[player] = nil
end

-- Destroy the module and clean up connections
function CoinMagnet:Destroy()
    for _, conn in ipairs(self.connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    self.connections = {}
    self.players = {}
    self.active = false
end

return CoinMagnet
