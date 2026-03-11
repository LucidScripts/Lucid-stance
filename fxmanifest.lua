fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'lucid-stance'
author 'Lucid Scripts'
description 'Vehicle stance editor with React NUI'
version '1.0.0'

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/assets/**/*',
}

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'oxmysql',
}
