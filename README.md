# Coin Magnet Module

This module provides a **Coin Magnet** power‑up for Roblox games. When activated, a player will attract nearby coins within a configurable radius. Collected coins are temporarily disabled and respawn after a cooldown.

## Installation

1. **Create a ModuleScript** in `ReplicatedStorage` (or any suitable location) and paste the contents of `CoinMagnet.lua`.
2. **Add a configuration file** (`config.json`) to the same folder or load it from a `DataStore`/`ServerScriptService`.
3. **Tag your coin parts** with the `Coin` tag using `CollectionService`.
4. **Trigger the power‑up** by calling `AddPlayer` when the player obtains the magnet.

```lua
local CoinMagnet = require(game.ReplicatedStorage.C
