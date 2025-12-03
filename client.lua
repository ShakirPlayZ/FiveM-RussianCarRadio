-- Russian Car Radio Client Script mit xsound
-- Erfordert: xsound (https://github.com/Xogy/xsound)

local isInVehicle = false
local radioVisible = false
local currentVolume = 50
local isPlaying = false
local radioSound = nil

-- FESTE STREAM URL - HTTPS mit SSL
local STREAM_URL = "https://service4gamer.net/live"
local SOUND_ID = "car_radio_stream"

-- Konfiguration
local Config = {
    -- Taste zum Öffnen des Radios (Q-Taste)
    radioKey = 85,
    -- Maximale Lautstärke
    maxVolume = 100,
    -- 3D Sound aktivieren (Sound kommt aus dem Fahrzeug)
    use3DSound = true,
    -- Max Distanz für 3D Sound (in Metern)
    maxDistance = 30.0
}

-- Initialisierung
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
            -- Spieler ist Fahrer eines Fahrzeugs
            if not isInVehicle then
                isInVehicle = true
                ShowHelpNotification("Drücke ~INPUT_PICKUP~ um das Radio zu öffnen")
            end
            
            -- Update 3D Sound Position wenn aktiviert
            if isPlaying and Config.use3DSound and radioSound then
                local coords = GetEntityCoords(vehicle)
                exports.xsound:Position(SOUND_ID, coords.x, coords.y, coords.z)
            end
        else
            -- Spieler ist nicht in einem Fahrzeug
            if isInVehicle then
                isInVehicle = false
                if radioVisible then
                    CloseRadio()
                end
                -- Stop Audio wenn Fahrzeug verlassen
                if isPlaying then
                    StopRadio()
                end
            end
        end
    end
end)

-- Tasteneingabe überwachen
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if isInVehicle then
            if IsControlJustReleased(0, Config.radioKey) then -- E-Taste
                ToggleRadio()
            end
        end
        
        if not isInVehicle and radioVisible then
            CloseRadio()
        end
    end
end)

-- Radio öffnen/schließen
function ToggleRadio()
    radioVisible = not radioVisible
    
    if radioVisible then
        OpenRadio()
    else
        CloseRadio()
    end
end

-- Radio öffnen
function OpenRadio()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true) -- Erlaube weiterhin Fahrzeug-Steuerung
    SendNUIMessage({
        action = "openRadio",
        volume = currentVolume,
        isPlaying = isPlaying
    })
    radioVisible = true
end

-- Radio schließen
function CloseRadio()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = "closeRadio"
    })
    radioVisible = false
end

-- Radio abspielen mit xsound
function PlayRadio()
    if isPlaying then
        print("[Radio] Already playing")
        return
    end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        print("[Radio] Not in vehicle")
        return
    end
    
    -- Erstelle Sound mit xsound
    if Config.use3DSound then
        local coords = GetEntityCoords(vehicle)
        exports.xsound:PlayUrlPos(SOUND_ID, STREAM_URL, currentVolume / 100, coords, false)
        exports.xsound:Distance(SOUND_ID, Config.maxDistance)
        print("[Radio] Playing 3D stream at vehicle position")
    else
        exports.xsound:PlayUrl(SOUND_ID, STREAM_URL, currentVolume / 100, false)
        print("[Radio] Playing 2D stream")
    end
    
    isPlaying = true
    
    -- Update NUI
    SendNUIMessage({
        action = "updatePlaying",
        isPlaying = true
    })
end

-- Radio stoppen
function StopRadio()
    if not isPlaying then
        return
    end
    
    -- Stoppe Sound mit xsound
    exports.xsound:Destroy(SOUND_ID)
    isPlaying = false
    
    print("[Radio] Stopped")
    
    -- Update NUI
    SendNUIMessage({
        action = "updatePlaying",
        isPlaying = false
    })
end

-- Lautstärke setzen
function SetRadioVolume(volume)
    currentVolume = volume
    
    if isPlaying then
        exports.xsound:setVolume(SOUND_ID, currentVolume / 100)
        print("[Radio] Volume set to: " .. currentVolume)
    end
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseRadio()
    cb('ok')
end)

RegisterNUICallback('play', function(data, cb)
    PlayRadio()
    cb('ok')
end)

RegisterNUICallback('pause', function(data, cb)
    StopRadio()
    cb('ok')
end)

RegisterNUICallback('volumeChange', function(data, cb)
    SetRadioVolume(data.volume)
    cb('ok')
end)

-- Hilfsfunktion für Benachrichtigungen
function ShowHelpNotification(msg)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- Beim Ressourcen-Stopp aufräumen
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if radioVisible then
            SetNuiFocus(false, false)
        end
        if isPlaying then
            exports.xsound:Destroy(SOUND_ID)
        end
    end
end)
