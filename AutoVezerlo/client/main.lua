local uiOpen = false

-- UI megnyitása/bezárása
function ToggleUI()
    local playerPed = PlayerPedId()
    
    -- Ellenőrizzük, hogy a játékos járműben ül-e
    if IsPedInAnyVehicle(playerPed, false) then
        uiOpen = not uiOpen
        
        -- UI fókusz beállítása
        SetNuiFocus(uiOpen, uiOpen)
        
        -- UI megjelenítése/elrejtése
        SendNUIMessage({
            type = "toggle",
            status = uiOpen
        })
        
        -- Ha az UI megnyitásra került, frissítsük a jármű adatait
        if uiOpen then
            UpdateVehicleInfo()
        end
    elseif uiOpen then
        -- Ha a játékos már nem járműben van, de az UI még nyitva, zárjuk be
        uiOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "toggle",
            status = false
        })
    end
end

-- Jármű információk frissítése
function UpdateVehicleInfo()
    if not uiOpen then return end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        -- Jármű adatok gyűjtése
        local engineOn = GetIsVehicleEngineRunning(vehicle)
        local fuelLevel = GetVehicleFuelLevel(vehicle) or 0
        local lightsOn = GetVehicleLightsState(vehicle)
        
        -- A lámpák állapotának pontosabb meghatározása
        local lightsStatus = false
        if lightsOn then
            if lightsOn == 1 or lightsOn == 2 or (type(lightsOn) == "table" and (lightsOn[1] > 0 or lightsOn[2] > 0)) then
                lightsStatus = true
            end
        end
        
        -- Ajtók állapota
        local doorStatus = {}
        for i = 0, 5 do -- 0: bal első, 1: jobb első, 2: bal hátsó, 3: jobb hátsó, 4: motorháztető, 5: csomagtér
            doorStatus[i] = GetVehicleDoorAngleRatio(vehicle, i) > 0.0
        end
        
        -- Ablakok állapota
        local windowStatus = {}
        for i = 0, 3 do -- 0: bal első, 1: jobb első, 2: bal hátsó, 3: jobb hátsó
            windowStatus[i] = not IsVehicleWindowIntact(vehicle, i)
        end
        
        -- Adatok küldése a NUI-nak
        SendNUIMessage({
            type = "updateVehicleInfo",
            engineStatus = engineOn,
            fuelLevel = fuelLevel,
            lightsStatus = lightsStatus,
            doors = doorStatus,
            windows = windowStatus
        })
    end
    
    -- Frissítés rendszeres időközönként, gyakrabban
    Citizen.SetTimeout(200, UpdateVehicleInfo)
end

-- NUI callback regisztrálása
RegisterNUICallback('close', function(data, cb)
    uiOpen = false
    SetNuiFocus(false, false) -- Ez visszaállítja a játék normál irányítását
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        type = "toggle",
        status = false
    })
    cb('ok')
end)

-- Ajtó kezelése
RegisterNUICallback('toggleDoor', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 and data.doorIndex ~= nil then
        if GetVehicleDoorAngleRatio(vehicle, data.doorIndex) > 0.0 then
            SetVehicleDoorShut(vehicle, data.doorIndex, false)
        else
            SetVehicleDoorOpen(vehicle, data.doorIndex, false, false)
        end
    end
    
    -- Azonnali UI frissítés
    Citizen.SetTimeout(50, function()
        UpdateVehicleInfo()
    end)
    
    cb('ok')
end)

-- Motor kezelése
RegisterNUICallback('toggleEngine', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        local engineRunning = GetIsVehicleEngineRunning(vehicle)
        SetVehicleEngineOn(vehicle, not engineRunning, false, true)
    end
    
    -- Azonnali UI frissítés
    Citizen.SetTimeout(50, function()
        UpdateVehicleInfo()
    end)
    
    cb('ok')
end)

-- Ablak kezelése
RegisterNUICallback('toggleWindow', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 and data.windowIndex ~= nil then
        if IsVehicleWindowIntact(vehicle, data.windowIndex) then
            RollDownWindow(vehicle, data.windowIndex)
        else
            RollUpWindow(vehicle, data.windowIndex)
        end
    end
    
    -- Azonnali UI frissítés
    Citizen.SetTimeout(50, function()
        UpdateVehicleInfo()
    end)
    
    cb('ok')
end)

-- Lámpák kezelése
RegisterNUICallback('toggleLights', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle ~= 0 then
        -- Lámpák állapotának lekérdezése más módon
        local _, lightsOn, highbeamsOn = GetVehicleLightsState(vehicle)
        
        -- Rövid késleltetés a hatékonyabb lámpakapcsoláshoz
        Citizen.CreateThread(function()
            if lightsOn == 1 or highbeamsOn == 1 then
                -- Lámpák kikapcsolása
                SetVehicleLights(vehicle, 1) -- 1: manuális, de ki
            else
                -- Lámpák bekapcsolása
                SetVehicleLights(vehicle, 2) -- 2: manuális, be
            end
        end)
    end
    
    -- Azonnali UI frissítés
    Citizen.SetTimeout(100, function()
        UpdateVehicleInfo()
    end)
    
    cb('ok')
end)

-- F5 billentyű és parancs regisztrálása
RegisterCommand('autovezerlo', function()
    ToggleUI()
end, false)

RegisterKeyMapping('autovezerlo', 'Autóvezérlő UI megnyitása', 'keyboard', 'F5')

-- Figyeljük, ha a játékos kilép a járműből
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(200)
        
        local playerPed = PlayerPedId()
        
        if uiOpen and not IsPedInAnyVehicle(playerPed, false) then
            -- Ha az UI nyitva van, de a játékos már nincs járműben, zárjuk be
            uiOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({
                type = "toggle",
                status = false
            })
        end
    end
end) 