fx_version 'cerulean'
game 'gta5'

author 'Manuel H.'
description 'Russisches Auto-Radio mit Musik-Streaming (xsound version)'
version '2.0.0'

-- Dependencies
dependency 'xsound'

-- Client Scripts
client_scripts {
    'client.lua'
}

-- UI Files
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
