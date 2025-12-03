-- Russian Car Radio Server Script
-- Fetcht Metadata vom Icecast2 Server

local METADATA_URL = "https://service4gamer.net/streamstatus"
local UPDATE_INTERVAL = 10000 -- 10 Sekunden

local currentSongTitle = "Lädt..."
local listeners = 0

-- Metadata regelmäßig abrufen
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(UPDATE_INTERVAL)
        
        -- Fetch Metadata
        PerformHttpRequest(METADATA_URL, function(statusCode, response, headers)
            if statusCode == 200 and response then
                -- Parse HTML für "Currently playing"
                local songTitle = response:match('<td>Currently playing:</td>%s*<td class="streamstats">(.-)</td>')
                
                if songTitle and songTitle ~= "" then
                    currentSongTitle = songTitle
                    print("[Radio Metadata] Song: " .. currentSongTitle)
                else
                    currentSongTitle = "Unbekannt"
                end
                
                -- Parse Listeners (optional)
                local listenerCount = response:match('<td>Listeners %(current%):</td>%s*<td class="streamstats">(%d+)</td>')
                if listenerCount then
                    listeners = tonumber(listenerCount) or 0
                end
            else
                print("[Radio Metadata] Fehler beim Abrufen: " .. statusCode)
                currentSongTitle = "Stream Offline"
            end
        end, "GET")
    end
end)

-- Server Event: Client fragt nach aktuellem Song
RegisterNetEvent('radio:requestMetadata')
AddEventHandler('radio:requestMetadata', function()
    local source = source
    TriggerClientEvent('radio:receiveMetadata', source, currentSongTitle, listeners)
end)

-- Command zum manuellen Testen
RegisterCommand('radioinfo', function(source, args, rawCommand)
    TriggerClientEvent('chat:addMessage', source, {
        color = {255, 51, 51},
        multiline = true,
        args = {"[Radio]", "🎵 Aktueller Song: " .. currentSongTitle .. " | 👥 Zuhörer: " .. listeners}
    })
end, false)

print("[Radio Metadata] Server gestartet - Metadata-Abruf alle " .. (UPDATE_INTERVAL/1000) .. " Sekunden")
