-- Blyad Radio Client Script - FINALE VERSION
-- Problem behoben: NUI Callbacks + GTA Audio

local isInVehicle = false
local radioVisible = false
local currentVolume = 50
local isPlaying = false

local STREAM_URL = "https://service4gamer.net/live"
local SOUND_ID = "car_radio_stream"

local Config = {
    radioKey = 85, -- Q-Taste
    maxVolume = 100,
    use3DSound = false, -- 2D Sound - 3D hatte Fade-Out Probleme beim Fahren
    maxDistance = 30.0,
    showListeners = false
}

print("🎵 [Blyad Radio] Loading...")

-- Initialisierung
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed then
            if not isInVehicle then
                isInVehicle = true
                ShowHelpNotification("Drücke ~INPUT_VEH_FLY_ATTACK_CAMERA~ um das Radio zu öffnen")
            end
        else
            if isInVehicle then
                isInVehicle = false
                if radioVisible then
                    CloseRadio()
                end
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
            if IsControlJustReleased(0, Config.radioKey) then
                ToggleRadio()
            end
        end
        
        if not isInVehicle and radioVisible then
            CloseRadio()
        end
    end
end)

function ToggleRadio()
    radioVisible = not radioVisible
    if radioVisible then
        OpenRadio()
    else
        CloseRadio()
    end
end

function OpenRadio()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({
        action = "openRadio",
        volume = currentVolume,
        isPlaying = isPlaying
    })
    radioVisible = true
end

function CloseRadio()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = "closeRadio"
    })
    radioVisible = false
    -- MUSIK LÄUFT WEITER! Nur UI wird geschlossen
end

function PlayRadio()
    print("🎵 [Radio] Starting playback...")
    
    if isPlaying then
        print("⚠️ [Radio] Already playing, restarting...")
        StopRadio()
        Citizen.Wait(300)
    end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        print("❌ [Radio] Not in vehicle!")
        return
    end
    
    -- Destroy alter Sound
    pcall(function()
        exports.xsound:Destroy(SOUND_ID)
    end)
    
    Citizen.Wait(100)
    
    -- Starte Stream
    local success = pcall(function()
        if Config.use3DSound then
            local coords = GetEntityCoords(vehicle)
            exports.xsound:PlayUrlPos(SOUND_ID, STREAM_URL, currentVolume / 100, coords, false)
            exports.xsound:Distance(SOUND_ID, Config.maxDistance)
            print("✅ [Radio] 3D Stream started")
        else
            exports.xsound:PlayUrl(SOUND_ID, STREAM_URL, currentVolume / 100, false)
            print("✅ [Radio] 2D Stream started")
        end
    end)
    
    if not success then
        print("❌ [Radio] Failed to start stream!")
        return
    end
    
    isPlaying = true
    
    -- Starte Metadata
    StartMetadataDisplay()
    
    -- Update NUI
    SendNUIMessage({
        action = "updatePlaying",
        isPlaying = true
    })
    
    -- Status Check nach 2 Sekunden
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        local info = exports.xsound:getInfo(SOUND_ID)
        if info then
            print("🔊 [Radio] Status: Playing=" .. tostring(info.playing) .. ", Volume=" .. tostring(info.volume))
        end
    end)
end

function StopRadio()
    if not isPlaying then
        return
    end
    
    print("⏹️ [Radio] Stopping...")
    exports.xsound:Destroy(SOUND_ID)
    isPlaying = false
    
    StopMetadataDisplay()
    
    SendNUIMessage({
        action = "updatePlaying",
        isPlaying = false
    })
end

function SetRadioVolume(volume)
    currentVolume = volume
    if isPlaying then
        exports.xsound:setVolume(SOUND_ID, currentVolume / 100)
    end
end

-- NUI Callbacks mit korrektem JSON Response
RegisterNUICallback('close', function(data, cb)
    print("📻 [NUI] Close")
    CloseRadio()
    cb({status = 'ok'})
end)

RegisterNUICallback('play', function(data, cb)
    print("▶️ [NUI] Play callback received!")
    PlayRadio()
    cb({status = 'ok'})
end)

RegisterNUICallback('pause', function(data, cb)
    print("⏸️ [NUI] Pause")
    StopRadio()
    cb({status = 'ok'})
end)

RegisterNUICallback('volumeChange', function(data, cb)
    if data and data.volume then
        SetRadioVolume(data.volume)
    end
    cb({status = 'ok'})
end)

function ShowHelpNotification(msg)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if radioVisible then
            SetNuiFocus(false, false)
        end
        if isPlaying then
            exports.xsound:Destroy(SOUND_ID)
        end
        StopMetadataDisplay()
    end
end)

-- ==========================================
-- METADATA DISPLAY SYSTEM
-- ==========================================

local metadataThread = nil
local currentMetadata = "Lädt..."
local showMetadata = false

function StartMetadataDisplay()
    showMetadata = true
    TriggerServerEvent('radio:requestMetadata')
    
    if metadataThread == nil then
        metadataThread = Citizen.CreateThread(function()
            while showMetadata do
                Citizen.Wait(10000)
                if isPlaying then
                    TriggerServerEvent('radio:requestMetadata')
                end
            end
            metadataThread = nil
        end)
    end
    
    -- Sende initial "Lädt..." ans UI
    SendNUIMessage({
        action = "updateNowPlaying",
        songTitle = "Lädt..."
    })
end

function StopMetadataDisplay()
    showMetadata = false
    currentMetadata = "Lädt..."
    
    -- Reset UI Display
    SendNUIMessage({
        action = "updateNowPlaying",
        songTitle = ""
    })
end

RegisterNetEvent('radio:receiveMetadata')
AddEventHandler('radio:receiveMetadata', function(songTitle, listeners)
    if songTitle and songTitle ~= "" then
        currentMetadata = songTitle
        if Config.showListeners and listeners then
            currentMetadata = songTitle .. " | 👥 " .. listeners
        end
        
        -- Sende Metadata ans UI
        SendNUIMessage({
            action = "updateNowPlaying",
            songTitle = currentMetadata
        })
    end
end)

-- WICHTIG: Commands für Notfall-Steuerung
RegisterCommand('radioplay', function()
    if isInVehicle then
        print("📻 [Command] Starting radio via command")
        PlayRadio()
    else
        print("❌ [Command] Must be in vehicle as driver")
    end
end, false)

RegisterCommand('radiostop', function()
    print("📻 [Command] Stopping radio via command")
    StopRadio()
end, false)

RegisterCommand('radiovolume', function(source, args)
    if args[1] then
        local vol = tonumber(args[1])
        if vol and vol >= 0 and vol <= 100 then
            SetRadioVolume(vol)
            print("🔊 [Command] Volume set to " .. vol .. "%")
        end
    end
end, false)

print("✅ [Blyad Radio] Loaded successfully!")
print("📝 Commands: /radioplay, /radiostop, /radiovolume [0-100]")
