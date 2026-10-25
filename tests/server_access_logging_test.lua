local handlers,responses,payloads={},{},{}
local groupEnabled=true
Config={Enabled=true,AdminAccess={AllowAdminAce=true,AdminAce='role.admin',AllowScriptAce=true,ScriptAce='zata.redminteractions',Steam64Whitelist={'76561198288053668'},VorpCharacterGroups={'admin'}},Webhook={Url='http://127.0.0.1:50120/api/webhooks/zata_RedmInteractions',Reports={}},Interactions={{scenarios={{name='configured_sit'}}}}}
function GetResourceState()return 'started'end
exports={vorp_core={GetCore=function()return {getUser=function(id)return {getUsedCharacter={group=id==5 and 'admin'or 'user',firstname='Änne',lastname='Jäger',charIdentifier=7}}end}end}}
function GetPlayerIdentifiers(id)return id==3 and {'steam:11000011389a5a4'}or {}end
function IsPlayerAceAllowed(id,ace)return id==1 and ace=='role.admin'or id==2 and ace=='zata.redminteractions'end
function GetPlayerName()return 'Synthetisch'end
function GetPlayerPed()return 1 end
function GetEntityCoords()return {x=1,y=2,z=3}end
function RegisterNetEvent(n,f)handlers[n]=f end
function AddEventHandler(n,f)handlers[n]=f end
function TriggerClientEvent(n,p,id,allowed,token)responses[#responses+1]={n=n,p=p,id=id,allowed=allowed,token=token}end
json={encode=function(v)return v end}
function PerformHttpRequest(url,cb,verb,payload)assert(url==Config.Webhook.Url and verb=='POST');payloads[#payloads+1]=payload;cb(204)end
dofile('server.lua')
local s=InteractionServer
for _,id in ipairs({1,2,3,5})do assert(s.allowed(id)==(id==1 or id==2))end
assert(not s.allowed(4)and not s.allowed(0))
local cfg=Config.AdminAccess
cfg.AllowAdminAce=false;assert(not s.allowed(1));cfg.AllowAdminAce=true
cfg.AllowScriptAce=false;assert(not s.allowed(2));cfg.AllowScriptAce=true
cfg.Steam64Whitelist={};assert(not s.allowed(3));cfg.Steam64Whitelist={'76561198288053668'}
cfg.VorpCharacterGroups={};assert(not s.allowed(5));cfg.VorpCharacterGroups={'admin'}
source=4;handlers['zata_RedmInteractions:request'](1,'debug');assert(not responses[#responses].allowed)
handlers['zata_RedmInteractions:request'](2,'picker');local token=responses[#responses].token;assert(responses[#responses].allowed and token)
local count=#payloads;handlers['zata_RedmInteractions:audit']('wrong','pickerOpened');assert(#payloads==count)
handlers['zata_RedmInteractions:audit'](token,'pickerOpened');assert(#payloads==count+1)
handlers['zata_RedmInteractions:audit'](token,'pickerOpened');assert(#payloads==count+1)
handlers['zata_RedmInteractions:audit'](token,'start',{key='scenario:forged'});assert(not s.sessions[4].active)
handlers['zata_RedmInteractions:audit'](token,'start',{key='scenario:configured_sit'});assert(s.sessions[4].active=='configured_sit')
handlers['zata_RedmInteractions:audit'](token,'stop');assert(not s.sessions[4].active)
Config.Enabled=false;assert(not s.allowed(1));handlers['zata_RedmInteractions:request'](3,'picker');assert(not responses[#responses].allowed);Config.Enabled=true
s.log(4,'ReportInteraction','Unicode-Grenzen',{{'Nachricht',string.rep('ä😄ß',12000)}})
local function units(v)local n=0;for _,c in utf8.codes(v)do n=n+(c>65535 and 2 or 1)end;return n end
for _,payload in ipairs(payloads)do local e=payload.embeds[1];local total=units(e.title)+units(e.footer.text);assert(#payload.allowed_mentions.parse==0 and units(e.title)<=256 and #e.fields<=25);for _,f in ipairs(e.fields)do assert(units(f.name)<=256 and units(f.value)<=1024);total=total+units(f.name)+units(f.value)end;assert(total<=5500)end
local before=#payloads;Config.Webhook.Reports.ReportInteraction=false;s.log(4,'ReportInteraction','Aus',{});assert(before==#payloads)
PerformHttpRequest=function()error('simulierter Fehler')end;assert(pcall(s.log,4,'ReportSecurity','Fehler',{}))
print('PASS: two ACE access paths, disabled paths/resource, public picker, rejected debug, session tokens, configured audit names, UTF-16 limits, report switches and HTTP isolation.')
