-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

name 'qb-compensation'
version '1.0.0'
description 'QBCore Compensation System with ox_inventory'
author 'YourName'
lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'qb-core',
    'ox_inventory',
    'oxmysql'
}
