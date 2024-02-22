fx_version 'cerulean'
game 'gta5'

author 'Randolio'
description 'Cargo Deliveries'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}

client_scripts {
    'bridge/client/**.lua',
    'cl_cargo.lua',
}

server_scripts {
    'bridge/server/**.lua',
    'sv_routes.lua',
    'sv_cargo.lua',
}

lua54 'yes'
