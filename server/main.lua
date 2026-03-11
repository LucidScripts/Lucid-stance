local stanceCache = {}

local function normalizeStance(row)
    local stance = row or {}
    local legacyHeight = ((tonumber(stance.height_front) or 0.0) + (tonumber(stance.height_rear) or 0.0)) / 2

    return {
        camber_front = tonumber(stance.camber_front) or Config.Defaults.camber_front,
        camber_rear = tonumber(stance.camber_rear) or Config.Defaults.camber_rear,
        ride_height = tonumber(stance.ride_height) or legacyHeight or Config.Defaults.ride_height,
        track_width_front = tonumber(stance.track_width_front) or tonumber(stance.wheel_offset) or Config.Defaults.track_width_front,
        track_width_rear = tonumber(stance.track_width_rear) or tonumber(stance.wheel_offset) or Config.Defaults.track_width_rear,
    }
end

local function ensureSchema()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `lucid_stance` (
            `plate` VARCHAR(8) NOT NULL,
            `camber_front` FLOAT NOT NULL DEFAULT 0.0,
            `camber_rear` FLOAT NOT NULL DEFAULT 0.0,
            `height_front` FLOAT NOT NULL DEFAULT 0.0,
            `height_rear` FLOAT NOT NULL DEFAULT 0.0,
            `track_width_front` FLOAT NOT NULL DEFAULT 0.0,
            `track_width_rear` FLOAT NOT NULL DEFAULT 0.0,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`plate`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])

    pcall(function()
        MySQL.query.await('ALTER TABLE lucid_stance ADD COLUMN `track_width_front` FLOAT NOT NULL DEFAULT 0.0')
    end)

    pcall(function()
        MySQL.query.await('ALTER TABLE lucid_stance ADD COLUMN `track_width_rear` FLOAT NOT NULL DEFAULT 0.0')
    end)
end

-- Make sure the table exists, then warm the cache.
CreateThread(function()
    ensureSchema()

    local rows = MySQL.query.await('SELECT * FROM lucid_stance')
    local count = 0
    if rows then
        for _, row in ipairs(rows) do
            stanceCache[row.plate] = normalizeStance(row)
            count = count + 1
        end
    end

    print('^2[lucid-stance]^0 Loaded ' .. count .. ' stanced vehicles from database.')
end)

-- Full cache sync for a joining player.
RegisterNetEvent('lucid-stance:server:requestAllStances', function()
    local src = source
    TriggerClientEvent('lucid-stance:client:loadAllStances', src, stanceCache)
end)

-- Open the menu with the saved values for this plate.
RegisterNetEvent('lucid-stance:server:requestStance', function(plate)
    local src = source
    if not plate or plate == '' then return end

    if Config.OwnerOnly then
        local player = exports.qbx_core:GetPlayer(src)
        if not player then return end
        local citizenid = player.PlayerData.citizenid
        local owned = MySQL.scalar.await(
            'SELECT 1 FROM player_vehicles WHERE plate = ? AND citizenid = ?',
            { plate, citizenid }
        )
        if not owned then
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = 'You do not own this vehicle.'
            })
            return
        end
    end

    local stanceData = stanceCache[plate] or nil
    TriggerClientEvent('lucid-stance:client:openUI', src, stanceData)
end)

-- Quiet sync used when someone gets back into a vehicle.
RegisterNetEvent('lucid-stance:server:requestApply', function(plate)
    local src = source
    if not plate or plate == '' then return end

    local stanceData = stanceCache[plate] or nil
    TriggerClientEvent('lucid-stance:client:applyStance', src, plate, stanceData)
end)

local function clamp(val, min, max)
    val = tonumber(val) or 0.0
    if val < min then return min end
    if val > max then return max end
    return val
end

RegisterNetEvent('lucid-stance:server:save', function(plate, stance)
    local src = source
    if not plate or plate == '' or not stance then return end

    stance = normalizeStance(stance)

    local clean = {
        camber_front = clamp(stance.camber_front, Config.Limits.camber_front.min, Config.Limits.camber_front.max),
        camber_rear = clamp(stance.camber_rear, Config.Limits.camber_rear.min, Config.Limits.camber_rear.max),
        ride_height = clamp(stance.ride_height, Config.Limits.ride_height.min, Config.Limits.ride_height.max),
        track_width_front = clamp(stance.track_width_front, Config.Limits.track_width_front.min, Config.Limits.track_width_front.max),
        track_width_rear = clamp(stance.track_width_rear, Config.Limits.track_width_rear.min, Config.Limits.track_width_rear.max),
    }

    stanceCache[plate] = clean

    MySQL.query([[
        INSERT INTO lucid_stance (plate, camber_front, camber_rear, height_front, height_rear,
                                  track_width_front, track_width_rear)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            camber_front      = VALUES(camber_front),
            camber_rear       = VALUES(camber_rear),
            height_front      = VALUES(height_front),
            height_rear       = VALUES(height_rear),
            track_width_front = VALUES(track_width_front),
            track_width_rear  = VALUES(track_width_rear)
    ]], {
        plate,
        clean.camber_front, clean.camber_rear,
        clean.ride_height, clean.ride_height,
        clean.track_width_front, clean.track_width_rear,
    })

    TriggerClientEvent('lucid-stance:client:syncStance', -1, plate, clean)

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = 'Stance saved!'
    })
end)

RegisterNetEvent('lucid-stance:server:delete', function(plate)
    local src = source
    if not plate or plate == '' then return end

    stanceCache[plate] = nil
    MySQL.query('DELETE FROM lucid_stance WHERE plate = ?', { plate })

    TriggerClientEvent('lucid-stance:client:syncStance', -1, plate, nil)

    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = 'Stance reset!'
    })
end)
