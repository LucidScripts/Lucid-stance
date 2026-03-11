local stanceCache = {}       -- plate -> saved stance values
local defaultOffsets = {}    -- entity -> stock wheel offsets so I can work from base values
local uiOpen = false
local currentStance = nil    -- current values sitting in the menu
local editingVehicle = nil   -- vehicle currently being edited
local activeStance = nil     -- live preview values while the menu is open
local lastVehiclePlate = nil

local function normalizeStance(stance)
    local normalized = stance or {}
    local legacyHeight = ((tonumber(normalized.height_front) or 0.0) + (tonumber(normalized.height_rear) or 0.0)) / 2

    return {
        camber_front = tonumber(normalized.camber_front) or Config.Defaults.camber_front,
        camber_rear = tonumber(normalized.camber_rear) or Config.Defaults.camber_rear,
        ride_height = tonumber(normalized.ride_height) or legacyHeight or Config.Defaults.ride_height,
        track_width_front = tonumber(normalized.track_width_front) or tonumber(normalized.wheel_offset) or Config.Defaults.track_width_front,
        track_width_rear = tonumber(normalized.track_width_rear) or tonumber(normalized.wheel_offset) or Config.Defaults.track_width_rear,
    }
end

-- Pull the full cache once when the resource starts.
CreateThread(function()
    TriggerServerEvent('lucid-stance:server:requestAllStances')
end)

-- Full cache sync for this client.
RegisterNetEvent('lucid-stance:client:loadAllStances', function(cache)
    stanceCache = {}

    for plate, stance in pairs(cache or {}) do
        stanceCache[plate] = normalizeStance(stance)
    end
end)

-- Single vehicle update after a save/reset.
RegisterNetEvent('lucid-stance:client:syncStance', function(plate, stanceData)
    stanceCache[plate] = stanceData and normalizeStance(stanceData) or nil

    if not stanceData then
        for entity, _ in pairs(defaultOffsets) do
            if DoesEntityExist(entity) then
                local vehPlate = string.gsub(GetVehicleNumberPlateText(entity), '%s+', '')
                if vehPlate == plate then
                    defaultOffsets[entity] = nil
                end
            end
        end
    end
end)

-- Grab the stock offsets once so track width stays relative to the vehicle's base setup.
local function cacheDefaults(vehicle)
    if defaultOffsets[vehicle] then return end

    defaultOffsets[vehicle] = {}
    for i = 0, 3 do
        defaultOffsets[vehicle][i] = GetVehicleWheelXOffset(vehicle, i)
    end
end

local function applyRideHeight(vehicle, stance)
    if not DoesEntityExist(vehicle) or not stance then return end

    SetVehicleSuspensionHeight(vehicle, stance.ride_height or 0.0)
end

-- Camber and track width need to be pushed constantly or the game will undo them.
local function applyPerFrame(vehicle, stance)
    if not DoesEntityExist(vehicle) or not stance then return end

    local offsets = defaultOffsets[vehicle]
    if not offsets then return end

    SetVehicleWheelYRotation(vehicle, 0, stance.camber_front)
    SetVehicleWheelYRotation(vehicle, 1, -stance.camber_front)
    SetVehicleWheelYRotation(vehicle, 2, stance.camber_rear)
    SetVehicleWheelYRotation(vehicle, 3, -stance.camber_rear)

    local front = stance.track_width_front or 0.0
    local rear = stance.track_width_rear or 0.0
    SetVehicleWheelXOffset(vehicle, 0, offsets[0] - front)
    SetVehicleWheelXOffset(vehicle, 1, offsets[1] + front)
    SetVehicleWheelXOffset(vehicle, 2, offsets[2] - rear)
    SetVehicleWheelXOffset(vehicle, 3, offsets[3] + rear)
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 then
            local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '%s+', '')

            if plate ~= lastVehiclePlate then
                lastVehiclePlate = plate
                cacheDefaults(vehicle)
                TriggerServerEvent('lucid-stance:server:requestApply', plate)
            end
        else
            lastVehiclePlate = nil
        end

        Wait(750)
    end
end)

-- Main loop for the stuff that gets reset every frame.
CreateThread(function()
    while true do
        local vehicles = GetGamePool('CVehicle')
        local hasWork = false

        for _, vehicle in ipairs(vehicles) do
            local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '%s+', '')
            local stance = stanceCache[plate]

            if vehicle == editingVehicle and activeStance then
                stance = activeStance
            end

            if stance then
                hasWork = true
                cacheDefaults(vehicle)
                applyPerFrame(vehicle, stance)
            end
        end

        if hasWork then
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- Ride height is lighter work, so this runs on a slower timer.
CreateThread(function()
    while true do
        local vehicles = GetGamePool('CVehicle')
        local hasWork = false

        for _, vehicle in ipairs(vehicles) do
            local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '%s+', '')
            local stance = stanceCache[plate]

            if vehicle == editingVehicle and activeStance then
                stance = activeStance
            end

            if stance then
                hasWork = true
                applyRideHeight(vehicle, stance)
            end
        end

        if hasWork then
            Wait(100)
        else
            Wait(500)
        end
    end
end)

-- Clear dead entity references out of the cache.
CreateThread(function()
    while true do
        Wait(10000)
        for entity, _ in pairs(defaultOffsets) do
            if not DoesEntityExist(entity) then
                defaultOffsets[entity] = nil
            end
        end
    end
end)

-- Command

RegisterCommand(Config.Command, function()
    if uiOpen then return end

    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        TriggerEvent('ox_lib:notify', {
            type = 'error',
            description = 'You must be in a vehicle.'
        })
        return
    end

    local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '%s+', '')
    editingVehicle = vehicle
    cacheDefaults(vehicle)

    TriggerServerEvent('lucid-stance:server:requestStance', plate)
end, false)

-- NUI callbacks

RegisterNetEvent('lucid-stance:client:openUI', function(stanceData)
    currentStance = normalizeStance(stanceData)
    activeStance = currentStance
    uiOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        stance = currentStance,
        limits = Config.Limits,
    })
end)

RegisterNUICallback('lucid-stance:preview', function(data, cb)
    if data.stance then
        currentStance = normalizeStance(data.stance)
        activeStance = currentStance

        if editingVehicle and DoesEntityExist(editingVehicle) then
            cacheDefaults(editingVehicle)
            applyRideHeight(editingVehicle, activeStance)
            applyPerFrame(editingVehicle, activeStance)
        end
    end

    cb('ok')
end)

RegisterNUICallback('lucid-stance:save', function(data, cb)
    if not editingVehicle or not DoesEntityExist(editingVehicle) then
        cb('ok')
        return
    end

    if data and data.stance then
        currentStance = normalizeStance(data.stance)
        activeStance = currentStance
    end

    if not currentStance then
        cb('ok')
        return
    end

    local plate = string.gsub(GetVehicleNumberPlateText(editingVehicle), '%s+', '')
    TriggerServerEvent('lucid-stance:server:save', plate, currentStance)
    cb('ok')
end)

RegisterNUICallback('lucid-stance:reset', function(_, cb)
    currentStance = normalizeStance(nil)
    activeStance = currentStance

    if editingVehicle and DoesEntityExist(editingVehicle) then
        cacheDefaults(editingVehicle)
        applyRideHeight(editingVehicle, currentStance)
        applyPerFrame(editingVehicle, currentStance)

        local plate = string.gsub(GetVehicleNumberPlateText(editingVehicle), '%s+', '')
        TriggerServerEvent('lucid-stance:server:delete', plate)
    end

    SendNUIMessage({
        action = 'updateStance',
        stance = currentStance,
    })

    cb('ok')
end)

RegisterNUICallback('lucid-stance:close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    activeStance = nil
    editingVehicle = nil
    cb('ok')
end)

RegisterNetEvent('lucid-stance:client:applyStance', function(plate, stanceData)
    if not plate then return end

    if stanceData then
        stanceCache[plate] = normalizeStance(stanceData)
    else
        stanceCache[plate] = nil
    end

    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
        cacheDefaults(vehicle)

        if stanceData then
            applyRideHeight(vehicle, stanceCache[plate])
            applyPerFrame(vehicle, stanceCache[plate])
        end
    end
end)

-- Cleanup

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if uiOpen then
        SetNuiFocus(false, false)
    end
    activeStance = nil
    editingVehicle = nil
    stanceCache = {}
    defaultOffsets = {}
end)
