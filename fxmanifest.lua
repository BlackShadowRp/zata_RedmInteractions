fx_version "cerulean"
lua54 "yes"
game "rdr3"
rdr3_warning "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."

files {
	"ui/index.html",
	"ui/style.css",
	"ui/script.js"
}

ui_page "ui/index.html"

shared_scripts {
    'common.lua',
    'translations_scenarios.lua',
    'translations_props.lua',
    'config.lua',
}
client_scripts {'@uiprompt/uiprompt.lua', 'client.lua'}
server_script 'server.lua'
dependencies {'uiprompt', 'unbrokenassets'}
