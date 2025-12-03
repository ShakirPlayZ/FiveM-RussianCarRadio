fx_version 'cerulean'
game 'gta5'

author 'Manuel H.'
description 'Russisches Auto-Radio mit Musik-Streaming (xsound version) + Metadata Display'
version '2.1.0'

-- Dependencies
dependency 'xsound'

-- Client Scripts
client_scripts {
    'client.lua'
}

-- Server Scripts
server_scripts {
    'server.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
