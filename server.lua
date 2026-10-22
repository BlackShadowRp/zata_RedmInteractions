-- Serverseitige Freigaben und Protokolle, ohne eigene Datenbank oder Spielerauszahlungen.
local S={sessions={}}
InteractionServer=S
local Core
if GetResourceState('vorp_core')=='started'then local ok,core=pcall(function()return exports.vorp_core:GetCore()end);if ok then Core=core end end
local function chunks(value)
    value=tostring(value==nil and '—' or value)
    local out,part,count={},{},0
    for _,code in utf8.codes(value)do
        part[#part+1]=utf8.char(code);count=count+1
        if count==450 then out[#out+1]=table.concat(part);part={};count=0 end
    end
    if #part>0 then out[#out+1]=table.concat(part)end
    if #out==0 then out[1]='—'end
    return out
end
local function shortTitle(value)
    local out={};for _,code in utf8.codes(tostring(value))do if #out>=100 then break end;out[#out+1]=utf8.char(code)end;return table.concat(out)
end
local audit=0
function S.log(player,report,title,fields)
    local ok=pcall(function()
        local cfg=Config.Webhook or {}
        if cfg.Url==nil or cfg.Url=='' or (cfg.Reports or {})[report]==false then return end
        local user=Core and player and player>0 and Core.getUser(player);local c=user and user.getUsedCharacter
        if type(c)=='function'then c=c()end
        local name=c and ((c.firstname or '')..' '..(c.lastname or '')) or (player and GetPlayerName(player)) or 'System'
        local ped=player and player>0 and GetPlayerPed(player) or 0
        local p=ped~=0 and GetEntityCoords(ped)
        local input={{'Spieler',('%s (sessionid=%s, charid=%s)'):format(name,player or 0,c and (c.charIdentifier or c.charidentifier)or '—')},{'Koordinaten',p and ('x=%.3f, y=%.3f, z=%.3f'):format(p.x,p.y,p.z)or 'nicht verfügbar'}}
        for _,f in ipairs(fields or {})do input[#input+1]=f end
        audit=audit+1;local id=('%d-%d'):format(os.time(),audit)
        local parts,current,total={},{},0
        for _,field in ipairs(input)do
            for n,value in ipairs(chunks(field[2]))do
                local key=shortTitle(field[1])..(n>1 and (' / '..n)or '')
                local cost=#key+#value
                if #current>=10 or total+cost>4500 then parts[#parts+1]=current;current={};total=0 end
                current[#current+1]={name=key,value=value,inline=false};total=total+cost
            end
        end
        if #current>0 then parts[#parts+1]=current end
        for n,part in ipairs(parts)do
            part[#part+1]={name='Audit-ID',value=id,inline=false}
            local payload={allowed_mentions={parse={}},embeds={{title=shortTitle(title)..(#parts>1 and (' · Teil %d/%d'):format(n,#parts)or ''),fields=part,footer={text='zata_RedmInteractions · '..os.date('!%Y-%m-%d %H:%M:%S UTC')}}}}
            PerformHttpRequest(cfg.Url,function(status)if status~=200 and status~=204 then print('[zata_RedmInteractions] LogBridge nicht erreichbar, HTTP '..tostring(status))end end,'POST',json.encode(payload),{['Content-Type']='application/json'})
        end
    end)
    if not ok then print('[zata_RedmInteractions] Protokollierung fehlgeschlagen.')end
end

function S.allowed(player)
    if Config.Enabled==false or not player or player<=0 then return false end
    local cfg=Config.AdminAccess or {}
    if cfg.AllowAdminAce and type(cfg.AdminAce)=='string'and cfg.AdminAce~=''and IsPlayerAceAllowed(player,cfg.AdminAce)then return true end
    if cfg.AllowScriptAce and type(cfg.ScriptAce)=='string'and cfg.ScriptAce~=''and IsPlayerAceAllowed(player,cfg.ScriptAce)then return true end
    for _,id in ipairs(GetPlayerIdentifiers(player))do
        local hex=id:match('^steam:(%x+)$');local value=hex and tonumber(hex,16)
        if value then for _,known in ipairs(cfg.Steam64Whitelist or {})do if ('%d'):format(value)==tostring(known)then return true end end end
    end
    local user=Core and Core.getUser(player);local c=user and user.getUsedCharacter
    if type(c)=='function'then c=c()end
    for _,group in ipairs(cfg.VorpCharacterGroups or {})do if c and type(c.group or c.Group)=='string'and (c.group or c.Group):lower()==tostring(group):lower()then return true end end
    return false
end
local definitions={}
for _,entry in ipairs(Config.Interactions)do
    for _,row in ipairs(entry.scenarios or {})do definitions['scenario:'..row.name]={name=row.name,effect=entry.effect}end
    for _,row in ipairs(entry.animations or {})do definitions['animation:'..row.dict..':'..row.name]={name=row.dict..' / '..row.name,effect=entry.effect}end
end
local sequence=0
RegisterNetEvent('zata_RedmInteractions:request',function(id,kind)
    local player=source
    if type(id)~='number'or id%1~=0 or id<1 or id>2147483647 then return end
    if kind~='picker'and kind~='debug'and kind~='turndebug'then return end
    local allowed=Config.Enabled~=false and (kind=='picker'or S.allowed(player))
    local token
    if allowed and kind=='picker'then
        sequence=sequence+1;token=('%d:%d'):format(player,sequence)
        local old=S.sessions[player]
        S.sessions[player]={token=token,opened=false,expires=os.time()+300,active=old and old.active}
    end
    if kind~='picker'then S.log(player,allowed and 'ReportAdmin'or 'ReportSecurity',allowed and 'Diagnose freigegeben'or 'Diagnose abgelehnt',{{'Nachricht',allowed and 'Clientdiagnose autorisiert; Ausgabe bleibt lokal.'or 'Keine Adminberechtigung oder Resource deaktiviert.'},{'Aktion',kind}})end
    TriggerClientEvent('zata_RedmInteractions:response',player,id,allowed,token)
end)
RegisterNetEvent('zata_RedmInteractions:audit',function(token,action,data)
    local player=source;local session=S.sessions[player]
    if not session or type(token)~='string'or session.token~=token then return end
    if action=='pickerClosed'then
        if session.opened then session.opened=false;S.log(player,'ReportPicker','Interaktionsauswahl geschlossen',{{'Nachricht','Client hat die Auswahl geschlossen.'}})end
        return
    end
    if action=='stop'then
        if session.active then S.log(player,'ReportInteraction','Interaktion beendet',{{'Nachricht','Client meldet Ende oder Unterbrechung; native Ausführung ist nicht serverseitig beweisbar.'},{'Interaktion',session.active}});session.active=nil end
        return
    end
    if Config.Enabled==false or session.expires<os.time()then return end
    if action=='pickerOpened'then
        if not session.opened then session.opened=true;S.log(player,'ReportPicker','Interaktionsauswahl geöffnet',{{'Nachricht','Client bestätigt die freigegebene Auswahl.'}})end
        return
    end
    if action~='start'and action~='failed'then return end
    if type(data)~='table'or type(data.key)~='string'or #data.key>512 or not definitions[data.key]then return end
    local name=definitions[data.key].name
    if action=='start'then session.active=name end
    S.log(player,'ReportInteraction',action=='start'and 'Interaktionsstart gemeldet'or 'Interaktionsstart fehlgeschlagen',{{'Nachricht',action=='start'and 'Client meldet Start einer konfigurierten Interaktion; kein serverseitiger Animationsnachweis.'or 'Client meldet einen Lade-, Kompatibilitäts- oder Startfehler.'},{'Interaktion',name}})
end)
AddEventHandler('playerDropped',function()
    if S.sessions[source]then S.log(source,'ReportPicker','Interaktionssitzung beendet',{{'Nachricht','Verbindung getrennt.'}});S.sessions[source]=nil end
end)

AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName()then return end
    for player,session in pairs(S.sessions)do
        S.log(player,'ReportInteraction','Interaktionssitzung beendet',{{'Nachricht','Resource wird gestoppt.'},{'Interaktion',session.active or 'keine aktive Interaktion'}})
    end
end)
