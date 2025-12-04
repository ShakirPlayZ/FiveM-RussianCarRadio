-- Blyad Radio Client Script mit xsound - DEBUG VERSION
-- Erfordert: xsound (https://github.com/Xogy/xsound)

local isInVehicle = false
local radioVisible = false
local currentVolume = 50
local isPlaying = false

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
    maxDistance = 30.0,
    -- Zeige Zuhörer-Anzahl im Lauftext
    showListeners = false
}

-- DEBUG: Prüfe xsound beim Start
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    
    if exports.xsound then
        print("✅ [Radio DEBUG] xsound export gefunden!")
        
        -- Teste xsound
        local testWorked = pcall(function()
            exports.xsound:getInfo(SOUND_ID)
        end)
        
        if testWorked then
            print("✅ [Radio DEBUG] xsound funktioniert!")
        else
            print("❌ [Radio DEBUG] xsound antwortet nicht korrekt")
        end
    else
        print("❌ [Radio DEBUG] xsound export NICHT gefunden! Ist xsound gestartet?")
    end
end)

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
                ShowHelpNotification("Drücke ~INPUT_VEH_FLY_ATTACK_CAMERA~ um das Radio zu öffnen")
                print("✅ [Radio DEBUG] Spieler ist jetzt Fahrer")
            end
        else
            -- Spieler ist nicht in einem Fahrzeug
            if isInVehicle then
                isInVehicle = false
                print("⚠️ [Radio DEBUG] Spieler hat Fahrzeug verlassen")
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
            if IsControlJustReleased(0, Config.radioKey) then -- Q-Taste
                print("🎯 [Radio DEBUG] Q-Taste gedrückt")
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
        print("📻 [Radio DEBUG] Radio wird geöffnet")
        OpenRadio()
    else
        print("📻 [Radio DEBUG] Radio wird geschlossen")
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
    print("✅ [Radio DEBUG] Radio UI geöffnet")
end

-- Radio schließen
function CloseRadio()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = "closeRadio"
    })
    radioVisible = false
    print("✅ [Radio DEBUG] Radio UI geschlossen")
end

-- Radio abspielen mit xsound
function PlayRadio()
    print("🎵 [Radio DEBUG] PlayRadio() aufgerufen")
    
    if isPlaying then
        print("⚠️ [Radio DEBUG] Already playing")
        return
    end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        print("❌ [Radio DEBUG] Not in vehicle")
        return
    end
    
    print("🔊 [Radio DEBUG] Versuche Stream zu starten...")
    print("🔊 [Radio DEBUG] URL: " .. STREAM_URL)
    print("🔊 [Radio DEBUG] Volume: " .. (currentVolume / 100))
    print("🔊 [Radio DEBUG] 3D Sound: " .. tostring(Config.use3DSound))
    
    -- Prüfe ob xsound verfügbar ist
    if not exports.xsound then
        print("❌ [Radio DEBUG] xsound export nicht verfügbar!")
        return
    end
    
    -- Versuche Sound zu erstellen
    local success, error = pcall(function()
        if Config.use3DSound then
            local coords = GetEntityCoords(vehicle)
            print("🔊 [Radio DEBUG] Starte 3D Stream an Position: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
            exports.xsound:PlayUrlPos(SOUND_ID, STREAM_URL, currentVolume / 100, coords, false)
            exports.xsound:Distance(SOUND_ID, Config.maxDistance)
            print("✅ [Radio DEBUG] PlayUrlPos aufgerufen")
        else
            print("🔊 [Radio DEBUG] Starte 2D Stream")
            exports.xsound:PlayUrl(SOUND_ID, STREAM_URL, currentVolume / 100, false)
            print("✅ [Radio DEBUG] PlayUrl aufgerufen")
        end
    end)
    
    if not success then
        print("❌ [Radio DEBUG] Fehler beim Starten: " .. tostring(error))
        return
    end
    
    isPlaying = true
    print("✅ [Radio DEBUG] isPlaying = true")
    
    -- Starte Metadata-Anzeige
    StartMetadataDisplay()
    
    -- Update NUI
    SendNUIMessage({
        action = "updatePlaying",
        isPlaying = true
    })
    
    -- Warte kurz und prüfe Status
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        
        local soundInfo = exports.xsound:getInfo(SOUND_ID)
        if soundInfo then
            print("🔊 [Radio DEBUG] Sound Info nach 2s:")
            print("   - Playing: " .. tostring(soundInfo.playing))
            print("   - Volume: " .. tostring(soundInfo.volume))
            print("   - URL: " .. tostring(soundInfo.url))
        else
            print("❌ [Radio DEBUG] Kein Sound Info verfügbar!")
        end
    end)
end

-- Radio stoppen
function StopRadio()
    if not isPlaying then
        return
    end
    
    print("⏹️ [Radio DEBUG] Stoppe Radio")
    
    -- Stoppe Sound mit xsound
    exports.xsound:Destroy(SOUND_ID)
    isPlaying = false
    
    -- Stoppe Metadata-Anzeige
    StopMetadataDisplay()
    
    print("✅ [Radio DEBUG] Stopped")
    
    -- Update NUI
    SendNUIMessage({
        action = "updatePlaying",
        isPlaying = false
    })
end

-- Lautstärke setzen
function SetRadioVolume(volume)
    currentVolume = volume
    
    print("🔊 [Radio DEBUG] Setze Lautstärke: " .. volume)
    
    if isPlaying then
        exports.xsound:setVolume(SOUND_ID, currentVolume / 100)
        print("✅ [Radio DEBUG] Volume set to: " .. currentVolume)
    end
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    print("📻 [Radio DEBUG] NUI Close callback")
    CloseRadio()
    cb('ok')
end)

RegisterNUICallback('play', function(data, cb)
    print("▶️ [Radio DEBUG] NUI Play callback")
    PlayRadio()
    cb('ok')
end)

RegisterNUICallback('pause', function(data, cb)
    print("⏸️ [Radio DEBUG] NUI Pause callback")
    StopRadio()
    cb('ok')
end)

RegisterNUICallback('volumeChange', function(data, cb)
    print("🔊 [Radio DEBUG] NUI Volume callback: " .. data.volume)
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
        print("🛑 [Radio DEBUG] Resource wird gestoppt")
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

-- Starte Metadata-Anzeige
function StartMetadataDisplay()
    showMetadata = true
    
    -- Fordere initial Metadata an
    TriggerServerEvent('radio:requestMetadata')
    
    -- Starte Thread für regelmäßige Updates
    if metadataThread == nil then
        metadataThread = Citizen.CreateThread(function()
            while showMetadata do
                Citizen.Wait(10000) -- Alle 10 Sekunden updaten
                
                if isPlaying then
                    TriggerServerEvent('radio:requestMetadata')
                end
            end
            metadataThread = nil
        end)
    end
    
    -- Starte Lauftext-Anzeige
    Citizen.CreateThread(function()
        while showMetadata and isPlaying do
            Citizen.Wait(0)
            
            -- Lauftext oben rechts anzeigen
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.0, 0.4)
            SetTextColour(255, 51, 51, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("🎵 " .. currentMetadata)
            DrawText(0.85, 0.02) -- Oben rechts
        end
    end)
end

-- Stoppe Metadata-Anzeige
function StopMetadataDisplay()
    showMetadata = false
    currentMetadata = "Lädt..."
end

-- Empfange Metadata vom Server
RegisterNetEvent('radio:receiveMetadata')
AddEventHandler('radio:receiveMetadata', function(songTitle, listeners)
    if songTitle and songTitle ~= "" then
        currentMetadata = songTitle
        
        -- Optional: Zeige auch Zuhörer-Anzahl
        if Config.showListeners and listeners then
            currentMetadata = songTitle .. " | 👥 " .. listeners
        end
        
        print("[Radio] Metadata update: " .. currentMetadata)
    end
end)

print("✅ [Radio DEBUG] Client Script geladen")
