# Coin Magnet (Luau / Roblox)

Modul kolektibel koin dengan magnet power-up. Menarik koin dalam radius pemain, membatasi koin per pemain, dan mengembalikan koin setelah cooldown.

## Fitur

- Satu `ModuleScript` yang mengembalikan tabel dengan `.new(config)`.
- `game:GetService(...)` untuk service, tanpa `wait()` (memakai `task.wait` / `RunService.Heartbeat`).
- Semua koneksi event dibersihkan di `:Destroy()` (bebas memory leak).
- Konfigurasi angka & boolean via `config.json`.
- Gaya Luau modern + anotasi tipe opsional, `selene` (std=roblox) friendly.

## Cara Pakai

1. Letakkan `CoinMagnet.lua` di `ReplicatedStorage` sebagai `ModuleScript` dengan nama `CoinMagnet`.
2. Letakkan `config.json` di `ReplicatedStorage/CoinMagnetConfig` (opsional) — atau inline config di script.
3. Di server script:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoinMagnet = require(ReplicatedStorage:WaitForChild("CoinMagnet"))

local config = {
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

local module = CoinMagnet.new(config)
module:SetupCoin(someCoinModel)   -- daftarkan model koin yang sudah ada
module:AddCoin(Vector3.new(0, 3, 0)) -- spawn koin baru

-- Berikan efek magnet ke pemain
somePlayer.CharacterAdded:Connect(function() end)
module:GrantMagnet(somePlayer)

module:Start() -- aktifkan Heartbeat loop

-- Saat unload/cleanup:
-- module:Destroy()
```

## Contoh Pemasangan (StarterScript di ServerScriptService)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoinMagnet = require(ReplicatedStorage:WaitForChild("CoinMagnet"))

local cfg = {
    magnetRadius = 20,
    magnetDuration = 10,
    magnetStrength = 40,
    maxCoinsPerPlayer = 50,
    coinCooldown = 6,
    collectRadius = 5,
    spawnInterval = 4,
    autoSpawn = true,
    maxActiveCoins = 30,
}

local coinMagnet = CoinMagnet.new(cfg)
coinMagnet:Start()

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart")
        coinMagnet:AddCoin(hrp.Position + Vector3.new(0, 2, 0))
    end)
end)

-- Berikan magnet ke pemain saat sentuh power-up khusus:
-- coinMagnet:GrantMagnet(player)
```

## Batasan / Catatan

- Magnet hanya menarik koin yang sudah terdaftar via `SetupCoin` atau dibuat via `AddCoin`.
- Mode koin: model koin harus punya `PrimaryPart` atau `BasePart` anak untuk deteksi `Touched`.
- `Touched` dipakai untuk deteksi koleksi — untuk skala besar disarankan ganti ke spatial query (`Workspace:GetPartBoundsInRadius`) di modifikasi lanjutan.
- `autoSpawn` memakai posisi acak dalam kotak ±50 unit di sekitar origin; sesuaikan secara manual dengan mengganti `_spawnTick` (fork).
- Efek magnet tidak direplikasi visual secara otomatis; perlu `RemoteEvent` tambahan jika klien butuh feedback.
- `maxCoinsPerPlayer` adalah hitungan koin yang sedang dikumpulkan (belum cooldown kembali); reset parsial terjadi saat cooldown koin selesai.
- Tidak memakai `task.wait()` di dalam modul; loop berjalan di `RunService.Heartbeat` sehingga performa stabil.
- Module ini server-only. Jangan `require` di `LocalScript` untuk logika otoritatif.

## Versi Selene

Disarankan: `selene --config selene.toml CoinMagnet.lua` dengan `std = "roblox"`.
