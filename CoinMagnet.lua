--!strict
-- CoinMagnet ModuleScript
-- Modern Luau, no globals, no wait(), cleans up connections.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local COIN_TAG = "CoinMagnet_Coin"

type Config = {
	magnetRadius: number?,
	magnetStrength: number?,
	maxCoinsPerPlayer: number?,
	coinRespawnCooldown: number?,
	updateInterval: number?,
}

type CoinState = {
	part: BasePart,
	originalParent: Instance?,
	originalCFrame: CFrame,
	collected: boolean,
	respawnAt: number?,
	owner: Player?,
}

type PlayerState = {
	collectedCount: number,
}

local CoinMagnet = {}
CoinMagnet.__index = CoinMagnet

local DEFAULTS: Config = {
	magnetRadius = 25,
	magnetStrength = 60,
	maxCoinsPerPlayer = 10,
	coinRespawnCooldown = 5,
	updateInterval = 0.1,
}

local function validateConfig(cfg: Config?): Config
	local out: Config = {}
	if cfg then
		for k, v in pairs(cfg) do
			if type(v) == "number" or type(v) == "boolean" then
				(out :: any)[k] = v
			end
		end
	end
	for k, v in pairs(DEFAULTS) do
		if (out :: any)[k] == nil then
			(out :: any)[k] = v
		end
	end
	return out
end

function CoinMagnet.new(config: Config?)
	local self = setmetatable({}, CoinMagnet)
	self._config = validateConfig(config)
	self._connections = {}
	self._coins = {} :: { [BasePart]: CoinState }
	self._playerStates = {} :: { [Player]: PlayerState }
	self._destroyed = false
	self._accum = 0

	self:_initCoins()

	table.insert(self._connections, CollectionService:GetInstanceAddedSignal(COIN_TAG):Connect(function(inst)
		self:_registerCoin(inst)
	end))
	table.insert(self._connections, CollectionService:GetInstanceRemovedSignal(COIN_TAG):Connect(function(inst)
		self:_unregisterCoin(inst)
	end))

	table.insert(self._connections, RunService.Heartbeat:Connect(function(dt)
		self:_step(dt)
	end))

	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		self._playerStates[player] = nil
		for _, state in pairs(self._coins) do
			if state.owner == player then
				state.owner = nil
			end
		end
	end))

	return self
end

function CoinMagnet:_registerCoin(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local part = inst :: BasePart
	if self._coins[part] then
		return
	end
	self._coins[part] = {
		part = part,
		originalParent = part.Parent,
		originalCFrame = part.CFrame,
		collected = false,
		respawnAt = nil,
		owner = nil,
	}
end

function CoinMagnet:_unregisterCoin(inst: Instance)
	if inst:IsA("BasePart") then
		self._coins[inst :: BasePart] = nil
	end
end

function CoinMagnet:_initCoins()
	for _, inst in ipairs(CollectionService:GetTagged(COIN_TAG)) do
		self:_registerCoin(inst)
	end
end

function CoinMagnet:_getPlayerState(player: Player): PlayerState
	local st = self._playerStates[player]
	if not st then
		st = { collectedCount = 0 }
		self._playerStates[player] = st
	end
	return st
end

function CoinMagnet:_step(dt: number)
	if self._destroyed then
		return
	end
	self._accum += dt
	local interval = self._config.updateInterval or DEFAULTS.updateInterval :: number
	if self._accum < interval then
		return
	end
	self._accum = 0

	local now = os.clock()

	-- Respawn collected coins
	for part, state in pairs(self._coins) do
		if state.collected and state.respawnAt and now >= state.respawnAt then
			if part.Parent == nil and state.originalParent then
				part.CFrame = state.originalCFrame
				part.Parent = state.originalParent
			end
			state.collected = false
			state.respawnAt = nil
			state.owner = nil
		end
	end

	-- Magnet each player's nearby coins
	local radius = self._config.magnetRadius or DEFAULTS.magnetRadius :: number
	local strength = self._config.magnetStrength or DEFAULTS.magnetStrength :: number
	local maxCoins = self._config.maxCoinsPerPlayer or DEFAULTS.maxCoinsPerPlayer :: number
	local cooldown = self._config.coinRespawnCooldown or DEFAULTS.coinRespawnCooldown :: number

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if not character then
			continue
		end
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if not hrp or not hrp:IsA("BasePart") then
			continue
		end
		local origin = hrp.Position
		local pstate = self:_getPlayerState(player)

		for part, state in pairs(self._coins) do
			if state.collected then
				continue
			end
			if part.Parent == nil then
				continue
			end
			if pstate.collectedCount >= maxCoins then
				break
			end

			local delta = origin - part.Position
			local dist = delta.Magnitude
			if dist > radius then
				continue
			end

			if dist < 3 then
				-- Collect
				state.collected = true
				state.owner = player
				state.respawnAt = now + cooldown
				state.originalCFrame = part.CFrame
				pstate.collectedCount += 1
				if state.originalParent then
					part.Parent = nil
				else
					part.CFrame = state.originalCFrame
				end
			else
				-- Attract
				local step = math.min(dist, strength * interval)
				local newPos = part.Position + delta.Unit * step
				part.CFrame = CFrame.new(newPos) * (part.CFrame - part.Position)
			end
		end
	end

	-- Decay collected count gradually when no longer collecting
	for _, player in ipairs(Players:GetPlayers()) do
		local pstate = self._playerStates[player]
		if pstate and pstate.collectedCount > 0 then
			local active = false
			for _, state in pairs(self._coins) do
				if state.owner == player and state.collected then
					active = true
					break
				end
			end
			if not active then
				pstate.collectedCount = math.max(0, pstate.collectedCount - 1)
			end
		end
	end
end

function CoinMagnet:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
	table.clear(self._coins)
	table.clear(self._playerStates)
	setmetatable(self, nil)
end

return CoinMagnet
