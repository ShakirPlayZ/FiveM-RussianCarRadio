-- Blyad Radio Server Script
-- Fetcht Metadata vom Icecast2 Server für alle Stations

local BASE_URL = "https://service4gamer.net"
local METADATA_URL = BASE_URL .. "/radio/streamstatus"
local UPDATE_INTERVAL = 10000 -- 10 Sekunden

-- Metadata Cache für jede Station
local stationMetadata = {
    russian = {song = "Lädt...", listeners = 0},
    cyberpunk = {song = "Lädt...", listeners = 0},
    techno = {song = "Lädt...", listeners = 0},
    familie = {song = "Lädt...", listeners = 0},
    lang = {song = "Lädt...", listeners = 0},
}

-- Metadata für alle Stationen regelmäßig abrufen
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(UPDATE_INTERVAL)
        
        -- Fetch Metadata einmal für alle Stationen
        PerformHttpRequest(METADATA_URL, function(statusCode, response, headers)
            if statusCode == 200 and response then
                print("[Radio Metadata] Status abgerufen (" .. string.len(response) .. " bytes)")
                
                -- Parse Metadata für jede Station
                for mount, data in pairs(stationMetadata) do
                    -- Mount Pattern: <h3 class="mount">Mount Point /MOUNT</h3>
                    local mountPattern = 'class="mount">Mount Point /' .. mount .. '</h3>'
                    local mountPos = response:find(mountPattern)
                    
                    if mountPos then
                        -- Suche nach "Currently playing" oder "Currentlyplaying" nach dem mount
                        local afterMount = response:sub(mountPos)
                        
                        -- Versuche beide Varianten (mit und ohne Leerzeichen)
                        local songTitle = afterMount:match('<td>Currently playing:</td>%s*<td class="streamstats">(.-)</td>')
                        if not songTitle or songTitle == "" then
                            songTitle = afterMount:match('<td>Currentlyplaying:</td>%s*<td class="streamstats">(.-)</td>')
                        end
                        
                        if songTitle and songTitle ~= "" and songTitle ~= "-" then
                            data.song = songTitle
                            print("[Radio Metadata] " .. mount .. ": " .. songTitle)
                        else
                            data.song = "Kein Titel"
                        end
                        
                        -- Parse Listeners für diesen Mount
                        local listenerCount = afterMount:match('<td>Listeners %(current%):</td>%s*<td class="streamstats">(%d+)</td>')
                        if listenerCount then
                            data.listeners = tonumber(listenerCount) or 0
                        else
                            data.listeners = 0
                        end
                    else
                        -- Mount nicht im Status gefunden
                        data.song = "Stream Offline"
                        data.listeners = 0
                        print("[Radio Metadata] " .. mount .. ": Nicht im Status gefunden")
                    end
                end
            else
                print("[Radio Metadata] Fehler beim Abrufen: " .. statusCode)
                -- Alle Stationen auf Offline setzen
                for mount, data in pairs(stationMetadata) do
                    data.song = "Stream Offline"
                    data.listeners = 0
                end
            end
        end, "GET")
    end
end)

-- Server Event: Client fragt nach aktuellem Song für Station
RegisterNetEvent('radio:requestMetadata')
AddEventHandler('radio:requestMetadata', function(mount)
    local source = source
    
    -- Fallback auf russian wenn kein mount angegeben
    if not mount or mount == "" then
        mount = "russian"
    end
    
    local data = stationMetadata[mount]
    if data then
        TriggerClientEvent('radio:receiveMetadata', source, data.song, data.listeners)
    else
        TriggerClientEvent('radio:receiveMetadata', source, "Unbekannt", 0)
    end
end)

-- Command zum manuellen Testen
RegisterCommand('radioinfo', function(source, args, rawCommand)
    local station = args[1] or "russian"
    local data = stationMetadata[station]
    
    if data then
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 51, 51},
            multiline = true,
            args = {"[Radio]", "🎵 " .. station .. ": " .. data.song .. " | 👥 " .. data.listeners}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            color = {255, 51, 51},
            args = {"[Radio]", "Station nicht gefunden: " .. station}
        })
    end
end, false)

print("[Radio Metadata] Server gestartet - " .. #stationMetadata .. " Stationen - Update alle " .. (UPDATE_INTERVAL/1000) .. " Sekunden")
