-- Blyad Radio - EXTENDED DEBUG mit Audio-Test
-- Test verschiedene xsound Funktionen

local isInVehicle = false
local radioVisible = false
local currentVolume = 50
local isPlaying = false

local STREAM_URL = "https://service4gamer.net/live"
local SOUND_ID = "car_radio_stream"

local Config = {
    radioKey = 85,
    maxVolume = 100,
    use3DSound = true,
    maxDistance = 30.0,
    showListeners = false
}

-- AUDIO TEST beim Start
Citizen.CreateThread(function()
    Citizen.Wait(5000) -- Warte 5 Sekunden nach Start
    
    print("=" .. string.rep("=", 60))
    print("🔊 [AUDIO TEST] Starte Diagnose...")
    print("=" .. string.rep("=", 60))
    
    -- Test 1: xsound verfügbar?
    if not exports.xsound then
        print("❌ [AUDIO TEST] xsound export nicht verfügbar!")
        return
    end
    print("✅ [AUDIO TEST] xsound export OK")
    
    -- Test 2: Test-Sound abspielen (lokal, nicht Stream)
    print("🔊 [AUDIO TEST] Teste lokalen Sound...")
    local testSuccess = pcall(function()
        -- Spiele einen kurzen Test-Ton (falls verfügbar)
        exports.xsound:PlayUrl("test_beep", "https://www.soundjay.com/button/beep-07.mp3", 0.3, false)
        Citizen.Wait(2000)
        exports.xsound:Destroy("test_beep")
    end)
    
    if testSuccess then
        print("✅ [AUDIO TEST] Test-Sound Befehl erfolgreich")
        print("   → Hast du einen kurzen Piep-Ton gehört? (Ja/Nein in F8 schreiben)")
    else
        print("❌ [AUDIO TEST] Test-Sound Befehl fehlgeschlagen")
    end
    
    -- Test 3: Prüfe GTA Audio Settings
    print("🔊 [AUDIO TEST] Prüfe GTA Audio...")
    local sfxVolume = GetProfileSetting(300) -- SFX Volume
    print("   → GTA SFX Volume: " .. tostring(sfxVolume))
    if sfxVolume == 0 then
        print("❌ [AUDIO TEST] WARNUNG: GTA SFX Volume ist auf 0!")
        print("   → Lösung: ESC → Settings → Audio → Effects Volume erhöhen")
    end
    
    -- Test 4: Teste Stream-URL Erreichbarkeit
    print("🔊 [AUDIO TEST] Teste Stream-URL...")
    PerformHttpRequest(STREAM_URL, function(code, data, headers)
        if code == 200 then
            print("✅ [AUDIO TEST] Stream-URL erreichbar (Status: " .. code .. ")")
            if headers["content-type"] then
                print("   → Content-Type: " .. headers["content-type"])
            end
        else
            print("❌ [AUDIO TEST] Stream-URL nicht erreichbar (Status: " .. code .. ")")
        end
    end, "HEAD")
    
    print("=" .. string.rep("=", 60))
    print("🔊 [AUDIO TEST] Diagnose abgeschlossen")
    print("=" .. string.rep("=", 60))
end)

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
end

function PlayRadio()
    print("=" .. string.rep("=", 60))
    print("🎵 [PLAY] Versuche Radio zu starten...")
    print("=" .. string.rep("=", 60))
    
    if isPlaying then
        print("⚠️ [PLAY] Already playing - stoppe zuerst")
        StopRadio()
        Citizen.Wait(500)
    end
    
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        print("❌ [PLAY] Not in vehicle")
        return
    end
    
    print("🔊 [PLAY] Settings:")
    print("   → URL: " .. STREAM_URL)
    print("   → Volume: " .. currentVolume .. "% (" .. (currentVolume/100) .. ")")
    print("   → 3D Sound: " .. tostring(Config.use3DSound))
    print("   → Sound ID: " .. SOUND_ID)
    
    -- Destroy alter Sound falls vorhanden
    pcall(function()
        exports.xsound:Destroy(SOUND_ID)
        print("🗑️ [PLAY] Alter Sound destroyed")
    end)
    
    Citizen.Wait(100)
    
    -- Starte Stream
    local success, error = pcall(function()
        if Config.use3DSound then
            local coords = GetEntityCoords(vehicle)
            print("🔊 [PLAY] Starte 3D Stream")
            print("   → Position: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
            print("   → Max Distance: " .. Config.maxDistance .. "m")
            
            exports.xsound:PlayUrlPos(SOUND_ID, STREAM_URL, currentVolume / 100, coords, false)
            exports.xsound:Distance(SOUND_ID, Config.maxDistance)
        else
            print("🔊 [PLAY] Starte 2D Stream")
            exports.xsound:PlayUrl(SOUND_ID, STREAM_URL, currentVolume / 100, false)
        end
    end)
    
    if not success then
        print("❌ [PLAY] FEHLER: " .. tostring(error))
        print("=" .. string.rep("=", 60))
        return
    end
    
    print("✅ [PLAY] xsound Befehl ausgeführt")
    isPlaying = true
    
    -- Starte Metadata
    StartMetadataDisplay()
    
    -- Update NUI
    SendNUIMessage({
        action = "updatePlaying",
        isPlaying = true
    })
    
    -- Ausführliche Status-Checks
    Citizen.CreateThread(function()
        for i = 1, 5 do
            Citizen.Wait(1000 * i) -- 1s, 2s, 3s, 4s, 5s
            
            local info = exports.xsound:getInfo(SOUND_ID)
            
            print("🔊 [STATUS CHECK " .. i .. "/5] Nach " .. i .. " Sekunden:")
            
            if info then
                print("   ✅ Sound existiert")
                print("   → Playing: " .. tostring(info.playing))
                print("   → Volume: " .. tostring(info.volume))
                print("   → Position: " .. tostring(info.position or "N/A"))
                print("   → Duration: " .. tostring(info.duration or "Stream (endlos)"))
                print("   → URL: " .. tostring(info.url))
                
                if info.playing == false then
                    print("   ⚠️ WARNUNG: Sound spielt NICHT!")
                    print("   → Versuche manuell zu starten...")
                    
                    pcall(function()
                        exports.xsound:Play(SOUND_ID)
                    end)
                end
            else
                print("   ❌ Kein Sound Info verfügbar!")
                print("   → Sound existiert möglicherweise nicht")
            end
            
            if i == 5 then
                print("=" .. string.rep("=", 60))
                print("🎯 [FINAL CHECK] Finale Diagnose:")
                
                if info and info.playing then
                    print("✅ Sound spielt laut xsound!")
                    print("")
                    print("🔊 WENN DU TROTZDEM NICHTS HÖRST:")
                    print("   1. Prüfe GTA Audio: ESC → Settings → Audio")
                    print("      → Effects Volume MUSS > 0 sein")
                    print("   2. Prüfe Windows Audio Mixer")
                    print("      → FiveM MUSS Ton erlauben")
                    print("   3. Teste mit Headset vs. Lautsprecher")
                    print("   4. Teste andere Audio-Quelle (YouTube in GTA)")
                    print("   5. xsound config.lua prüfen (im xsound Ordner)")
                else
                    print("❌ Sound spielt NICHT!")
                    print("")
                    print("🔧 MÖGLICHE PROBLEME:")
                    print("   1. Stream-URL liefert kein Audio")
                    print("   2. xsound kann Format nicht abspielen")
                    print("   3. CORS/Network blockiert Stream")
                    print("   4. xsound config falsch")
                end
                
                print("=" .. string.rep("=", 60))
            end
        end
    end)
end

function StopRadio()
    if not isPlaying then
        return
    end
    
    print("⏹️ [STOP] Stoppe Radio")
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
        print("🔊 [VOLUME] " .. currentVolume .. "%")
    end
end

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseRadio()
    cb('ok')
end)

RegisterNUICallback('play', function(data, cb)
    print("▶️ [NUI] Play Button geklickt")
    PlayRadio()
    cb('ok')
end)

RegisterNUICallback('pause', function(data, cb)
    print("⏸️ [NUI] Pause Button geklickt")
    StopRadio()
    cb('ok')
end)

RegisterNUICallback('volumeChange', function(data, cb)
    SetRadioVolume(data.volume)
    cb('ok')
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
    print("📝 [METADATA] Starte Metadata Display")
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
        print("✅ [METADATA] Update-Thread gestartet")
    end
    
    -- Lauftext-Thread
    Citizen.CreateThread(function()
        print("✅ [METADATA] Lauftext-Thread gestartet")
        print("   → Position: Oben Rechts (0.85, 0.02)")
        print("   → Farbe: Rot (#ff3333)")
        
        while showMetadata and isPlaying do
            Citizen.Wait(0)
            
            SetTextFont(4)
            SetTextProportional(1)
            SetTextScale(0.0, 0.5) -- Größer zum Testen
            SetTextColour(255, 51, 51, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("🎵 " .. currentMetadata)
            DrawText(0.85, 0.02)
        end
        
        print("⏹️ [METADATA] Lauftext-Thread gestoppt")
    end)
end

function StopMetadataDisplay()
    print("⏹️ [METADATA] Stoppe Metadata Display")
    showMetadata = false
    currentMetadata = "Lädt..."
end

RegisterNetEvent('radio:receiveMetadata')
AddEventHandler('radio:receiveMetadata', function(songTitle, listeners)
    if songTitle and songTitle ~= "" then
        currentMetadata = songTitle
        
        if Config.showListeners and listeners then
            currentMetadata = songTitle .. " | 👥 " .. listeners
        end
        
        print("📝 [METADATA] Update: " .. currentMetadata)
    else
        print("⚠️ [METADATA] Leere Metadata empfangen")
    end
end)

-- TEST COMMANDS
RegisterCommand('radiotest', function()
    print("")
    print("🧪 MANUELLER RADIO TEST")
    print("Starte Radio programmatisch...")
    PlayRadio()
end, false)

RegisterCommand('radiosound', function()
    local info = exports.xsound:getInfo(SOUND_ID)
    print("")
    print("🔊 SOUND STATUS:")
    if info then
        for k, v in pairs(info) do
            print("   " .. k .. " = " .. tostring(v))
        end
    else
        print("   ❌ Kein Sound gefunden")
    end
end, false)

print("✅ [RADIO] Extended Debug Client geladen")
print("📝 Commands verfügbar: /radiotest, /radiosound")
