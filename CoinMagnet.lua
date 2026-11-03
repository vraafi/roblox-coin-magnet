--!strict
-- CoinMagnet: collectible coins with magnet power-up
-- Clean, leak-free Luau module for Roblox

local CoinMagnet = {}
CoinMagnet.__index = CoinMagnet

export type Config = {
	magnetRadius: number,
	magnetDuration: number,
	magnetStrength: number,
	maxCoinsPerPlayer: number,
	coinCooldown: number,
	collectRadius: number,
	spawnInterval: number,
	autoSpawn: boolean,
	maxActiveCoins: number,
}

export type Coin = {
	model: Model,
	position: Vector3,
	player: Player?,
	collected: boolean,
	timeCollected: number,
	connection: RBXScriptConnection?,
}

export type CoinMagnetClass = {
	__index: any,
	new: (config: Config?) -> any,
	Destroy: (self: any) -> (),
	SetupCoin: (self: any, model: Model) -> (),
	AddCoin: (self: any, position: Vector3, parent: Instance?) -> Model,
	GrantMagnet: (self: any, player: Player) -> (),
	Start: (self: any) -> (),
	Stop: (self: any) -> (),
}

local DEFAULT_CONFIG: Config = {
	magnetRadius = 25,
	magnetDuration = 8,
	magnetStrength = 60,
	maxCoinsPerPlayer = 100,
	coinCooldown = 5,
	collectRadius = 4,
	spawnInterval = 3,
	autoSpawn = true,
	maxActiveCoins = 50,
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local function deepMerge(base: Config, override: Config?): Config
	if not override then
		return table.clone(base)
	end
	local result: any = table.clone(base)
	for k, v in pairs(override) do
		if type(v) == "number" or type(v) == "boolean" then
			result[k] = v
		elseif type(v) == "table" and type(result[k]) == "table" then
			result[k] = deepMerge(result[k], v)
		end
	end
	return result
end

function CoinMagnet.new(config: Config?)
	local self = setmetatable({}, CoinMagnet)
	self._config = deepMerge(DEFAULT_CONFIG, config)
	self._coins = {} :: { [Model]: Coin }
	self._coinOrder = {} :: { Model }
	self._conns = {} :: { RBXScriptConnection }
	self._tweens = {} :: { Tween }
	self._magnets = {} :: { [Player]: { expiresAt: number, active: boolean } }
	self._playerCounts = {} :: { [Player]: number }
	self._destroyed = false
	self._heartbeat = nil
	self._spawnAccum = 0
	self._coinsFolder = nil
	self._started = false

	self:_setupPlayersEvents()
	return self
end

function CoinMagnet:_createCoinsFolder()
	local folder = Workspace:FindFirstChild("CoinMagnetCoins")
	if folder and not folder:IsA("Folder") then
		folder:Destroy()
		folder = nil
	end
	if not folder then
		local f = Instance.new("Folder")
		f.Name = "CoinMagnetCoins"
		f.Parent = Workspace
		folder = f
	end
	return folder :: Folder
end

function CoinMagnet:_setupPlayersEvents()
	table.insert(self._conns, Players.PlayerRemoving:Connect(function(player: Player)
		self._magnets[player] = nil
		self._playerCounts[player] = nil
	end))
end

function CoinMagnet:_activeMagnetCount(): number
	local n = 0
	for _ in pairs(self._magnets) do
		n += 1
	end
	return n
end

function CoinMagnet:SetupCoin(model: Model)
	if self._destroyed then return end
	if self._coins[model] then return end
	local coin: Coin = {
		model = model,
		position = model:GetPivot().Position,
		player = nil,
		collected = false,
		timeCollected = 0,
		connection = nil,
	}
	local handle = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") :: BasePart?
	if handle then
		coin.connection = handle.Touched:Connect(function(hit: BasePart)
			self:_tryCollect(coin, hit)
		end)
	end
	self._coins[model] = coin
	table.insert(self._coinOrder, model)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(Workspace) then
			self:_removeCoin(model)
		end
	end)
end

function CoinMagnet:_removeCoin(model: Model)
	local coin = self._coins[model]
	if not coin then return end
	if coin.connection then
		coin.connection:Disconnect()
		coin.connection = nil
	end
	self._coins[model] = nil
	for i, m in ipairs(self._coinOrder) do
		if m == model then
			table.remove(self._coinOrder, i)
			break
		end
	end
end

function CoinMagnet:_tryCollect(coin: Coin, hit: BasePart)
	if self._destroyed or coin.collected then return end
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then return end
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end
	local count = self._playerCounts[player] or 0
	if count >= self._config.maxCoinsPerPlayer then return end
	coin.collected = true
	coin.player = player
	coin.timeCollected = os.clock()
	self._playerCounts[player] = count + 1
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local targetPos = (player.Character and player.Character:GetPivot().Position) or coin.position
	if coin.model.PrimaryPart then
		local t = TweenService:Create(coin.model.PrimaryPart, tweenInfo, {
			CFrame = CFrame.new(targetPos),
			Transparency = 0.5,
		})
		t.Completed:Once(function()
			if coin.model and coin.model.Parent then
				coin.model:Destroy()
			end
			self:_removeCoin(coin.model)
		end)
		table.insert(self._tweens, t)
		t:Play()
		if #self._tweens > 256 then
			table.remove(self._tweens, 1)
		end
	else
		coin.model:Destroy()
		self:_removeCoin(coin.model)
	end
end

function CoinMagnet:AddCoin(position: Vector3, parent: Instance?): Model
	if self._destroyed then
		return nil :: any
	end
	local folder = self._coinsFolder or self:_createCoinsFolder()
	self._coinsFolder = folder
	local part = Instance.new("Part")
	part.Name = "Coin"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.4, 1.6, 1.6)
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 200, 40)
	part.Parent = folder
	local model = Instance.new("Model")
	model.Name = "CoinModel"
	part.Parent = model
	model.PrimaryPart = part
	model.Parent = parent or folder
	self:SetupCoin(model)
	local spinTween = TweenService:Create(part, TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
		CFrame = part.CFrame * CFrame.Angles(0, math.pi * 2, 0),
	})
	table.insert(self._tweens, spinTween)
	spinTween:Play()
	return model
end

function CoinMagnet:GrantMagnet(player: Player)
	if self._destroyed or not player or not player.Parent then return end
	self._magnets[player] = {
		expiresAt = os.clock() + self._config.magnetDuration,
		active = true,
	}
end

function CoinMagnet:_attractCoin(coin: Coin, targetPos: Vector3, dt: number)
	local handle = coin.model.PrimaryPart
	if not handle then return end
	local current = handle.Position
	local diff = targetPos - current
	local dist = diff.Magnitude
	if dist < self._config.collectRadius then return end
	local step = math.min(self._config.magnetStrength * dt, dist)
	local newPos = current + diff.Unit * step
	handle.CFrame = CFrame.new(newPos) * handle.CFrame.Rotation
end

function CoinMagnet:_updateMagnets()
	local now = os.clock()
	for player, state in pairs(self._magnets) do
		if not player.Parent then
			self._magnets[player] = nil
			continue
		end
		if now >= state.expiresAt then
			self._magnets[player] = nil
			continue
		end
		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then continue end
		local rootPos = root.Position
		for _, model in ipairs(self._coinOrder) do
			local coin = self._coins[model]
			if not coin or coin.collected then continue end
			local dist = (coin.position - rootPos).Magnitude
			if dist <= self._config.magnetRadius then
				self:_attractCoin(coin, rootPos, 1 / 60)
			end
		end
	end
end

function CoinMagnet:_tryRespawn()
	local now = os.clock()
	for _, model in ipairs(self._coinOrder) do
		local coin = self._coins[model]
		if coin and coin.collected then
			if now - coin.timeCollected >= self._config.coinCooldown then
				if coin.player then
					self._playerCounts[coin.player] = math.max(0, (self._playerCounts[coin.player] or 0) - 1)
				end
				self:_removeCoin(model)
			end
		end
	end
end

function CoinMagnet:_spawnTick(dt: number)
	if not self._config.autoSpawn then return end
	self._spawnAccum += dt
	if self._spawnAccum < self._config.spawnInterval then return end
	self._spawnAccum = 0
	local active = 0
	for _ in pairs(self._coins) do
		active += 1
	end
	if active >= self._config.maxActiveCoins then return end
	local pos = Vector3.new(math.random(-50, 50), 3, math.random(-50, 50))
	self:AddCoin(pos, nil)
end

function CoinMagnet:_onHeartbeat(dt: number)
	if self._destroyed then return end
	self:_updateMagnets()
	self:_tryRespawn()
	self:_spawnTick(dt)
end

function CoinMagnet:Start()
	if self._destroyed or self._started then return end
	self._started = true
	self._heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		self:_onHeartbeat(dt)
	end)
end

function CoinMagnet:Stop()
	if not self._started then return end
	self._started = false
	if self._heartbeat then
		self._heartbeat:Disconnect()
		self._heartbeat = nil
	end
end

function CoinMagnet:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self:Stop()
	for _, c in ipairs(self._conns) do
		c:Disconnect()
	end
	self._conns = {}
	for _, t in ipairs(self._tweens) do
		t:Cancel()
	end
	self._tweens = {}
	for _, coin in pairs(self._coins) do
		if coin.connection then
			coin.connection:Disconnect()
			coin.connection = nil
		end
	end
	self._coins = {}
	self._coinOrder = {}
	self._magnets = {}
	self._playerCounts = {}
	if self._coinsFolder and self._coinsFolder.Parent then
		self._coinsFolder:Destroy()
	end
	self._coinsFolder = nil
	setmetatable(self, nil)
end

return CoinMagnet
