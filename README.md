# lucid-stance

A clean stance editor for FiveM with a React NUI, live preview, per-vehicle saves, and separate front/rear track width.

Built for people who want something simple to use in-game and simple to maintain in a real server folder.

## What It Does

- Opens a stance menu with `/stance`
- Live previews changes while you move sliders
- Saves stance by plate
- Reapplies saved stance when the vehicle comes back out
- Supports:
  - front camber
  - rear camber
  - ride height
  - front track width
  - rear track width
- Optional owner-only editing check through `player_vehicles`
- React UI with Vite build output directly into `nui/`

## Stack

- FiveM Lua
- React
- TypeScript
- Vite
- oxmysql

## Requirements

- `oxmysql`
- a framework using `player_vehicles` if you want `OwnerOnly = true`

This resource was built around a Qbox-style setup, but if you do not need ownership checks you can just turn them off in the config.

## Install

### 1. Drop the resource in your standalone folder

Put `lucid-stance` in your server resources directory.

### 2. Import the SQL

Run the SQL in [install/stance.sql](install/stance.sql).

### 3. Make sure dependencies are started

At minimum:

```cfg
ensure oxmysql
ensure lucid-stance
```

### 4. Build the UI if you edit the web source

If you change anything inside [web](web), build it again:

```bash
cd web
npm install
npm run build
```

That writes the production files into [nui](nui).

## Config

Main config lives in [config.lua](config.lua).

```lua
Config.Command = 'stance'
Config.OwnerOnly = true
```

Owner check supports:

- Qbox
- QBCore
- ESX
- custom setups through `Config.OwnerCheck`

Current slider limits:

```lua
Config.Limits = {
    camber_front      = { min = -0.35, max = 0.35, step = 0.001 },
    camber_rear       = { min = -0.35, max = 0.35, step = 0.001 },
    ride_height       = { min = -0.18, max = 0.18, step = 0.002 },
    track_width_front = { min = -0.3,  max = 0.3,  step = 0.005 },
    track_width_rear  = { min = -0.3,  max = 0.3,  step = 0.005 },
}
```

If you want more or less travel, just change the config and restart the resource.

## Ownership Check

When `Config.OwnerOnly = true`, the script will try to detect your framework and use the right ownership lookup automatically.

Default mappings:

- Qbox: `player_vehicles.plate -> citizenid`
- QBCore: `player_vehicles.plate -> citizenid`
- ESX: `owned_vehicles.plate -> owner`

If your setup is different, you can override it in [config.lua](config.lua):

```lua
Config.OwnerCheck = {
  Framework = 'custom',
  VehicleTable = 'your_vehicle_table',
  PlateColumn = 'plate',
  OwnerColumn = 'owner_identifier',
  GetIdentifier = function(src)
    return GetPlayerIdentifierByType(src, 'license')
  end,
}
```

If you do not want ownership restrictions at all, set `Config.OwnerOnly = false`.

## Web UI Workflow

Source lives in [web/src](web/src).

Useful commands:

```bash
npm install
npm run dev
npm run build
```

Vite is set up to build straight into the resource's `nui` folder.

## File Layout

```text
lucid-stance/
├─ client/
├─ server/
├─ install/
├─ nui/
├─ web/
├─ config.lua
└─ fxmanifest.lua
```

## Notes

- Ride height is handled as a single slider on purpose.
- Track width is split front/rear and saved by plate.
- Saved stance is refreshed when the player gets back into the vehicle.
- The UI is built, so the resource works as-is without touching the web folder.

## Why I Made It This Way

I wanted something that felt modern in-game without turning into a bloated tuning system.

Most stance scripts either stop at basic offsets or get annoying to maintain once you start changing things. This one keeps the editable stuff in the config, keeps the UI separate, and stays easy to tweak if you are running a live server and do not have time to babysit it.

## Future Ideas

- stance presets
- location/job restrictions
- item-based access
- export hooks for garages/custom shops
- wheel fitment presets per model

## License

Use it, tweak it, ship it on your server.


If you repost it publicly, at least leave the resource name and credit intact.
