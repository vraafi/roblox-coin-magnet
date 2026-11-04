# Coin Magnet

Modul Luau untuk Roblox yang membuat koin kolektibel dengan efek magnet: koin dalam radius pemain akan tertarik dan dikumpulkan, dengan batas per pemain dan cooldown respawn.

## Cara Pakai

1. Letakkan `CoinMagnet.lua` sebagai `ModuleScript` di `ServerScriptService` atau `ReplicatedStorage`.
2. Tandai part koin dengan tag `CoinMagnet_Coin` menggunakan `CollectionService:AddTag(part, "CoinMagnet_Coin")`.
3. Buat Script server yang me-require modul dan memanggil `CoinMagnet.new(config)`.

```lua
local CoinMagnet = require(script.Parent.CoinMagnet)
local CollectionService = game:GetService("CollectionService")

-- Tandai koin
for _, coin in ipairs(workspace.Coins:GetChildren()) do
    if coin:IsA("BasePart") then
        CollectionService:AddTag(coin, "CoinMagnet_Coin")
    end
end

local magnet = CoinMagnet.new({
    magnetRadius = 25,
    magnetStrength = 60,
    maxCoinsPerPlayer = 10,
    coinRespawnCooldown = 5,
    updateInterval = 0.1,
})

-- Saat selesai:
-- magnet:Destroy()
```

## Parameter config.json

| Kunci | Tipe | Default | Deskripsi |
|-------|------|---------|-----------|
| `magnetRadius` | number | 25 | Radius tarik magnet (studs) |
| `magnetStrength` | number | 60 | Kecepatan tarik koin |
| `maxCoinsPerPlayer` | number | 10 | Batas koin terkumpul per pemain |
| `coinRespawnCooldown` | number | 5 | Waktu respawn koin (detik) |
| `updateInterval` | number | 0.1 | Interval update Heartbeat (detik) |

## Pemasangan

- Modul harus dijalankan di server.
- Koin harus berupa `BasePart` yang diberi tag `CoinMagnet_Coin`.
- Pemain harus memiliki `HumanoidRootPart` di karakter.
- Panggil `:Destroy()` untuk membersihkan koneksi dan state.

## Batasan

- Hanya mendukung `BasePart` sebagai koin.
- Tidak ada replikasi efek visual khusus; koin hanya dipindahkan secara fisik.
- Cooldown respawn bersifat global per koin, bukan per pemain.
- Batas `maxCoinsPerPlayer` dihitung dari koin yang masih dalam status terkumpul.
- Tidak menangani kasus koin dihapus permanen saat terkumpul.
