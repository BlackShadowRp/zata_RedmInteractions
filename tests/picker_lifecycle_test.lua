local state = {}
local permission=true
local messages={}
local loaded=false
local played=0
local network={}
function RegisterNetEvent(name,fn)network[name]=fn end
function TriggerServerEvent(name,id,kind)
    if name=='zata_RedmInteractions:request'then network['zata_RedmInteractions:response'](id,permission,'synthetic:1')end
end
function SetTimeout()end
function SetNuiFocus(keyboard)state.nui=keyboard end
function SetNuiFocusKeepInput()end

local now=100
local exportCalls=0
local lightCalls=0
local threads, prompts = {}, {}
Citizen = {CreateThread=function(f) threads[#threads+1]=coroutine.create(f) end, Wait=function() coroutine.yield() end}
Uiprompt = {new=function(_, control, label) local p={enabled=false,label=label}; function p:isEnabled() return self.enabled end; function p:setEnabledAndVisible(v) self.enabled=v end; prompts[#prompts+1]=p; return p end}
local callbacks={}
function RegisterNUICallback(name, callback) callbacks[name]=callback end
local handlers={}
local commands={}
function RegisterCommand(name, callback) commands[name]=callback end
function AddEventHandler(name, callback) handlers[name]=callback end
function PlayerPedId() return 1 end
function PlayerId() return 0 end
function DoesEntityExist() return true end
function IsEntityDead() return state.dead or false end
IsPedDeadOrDying=IsEntityDead
function IsPedOnMount() return state.mount or false end
function IsPedEnteringAnyTransport() return state.entering or false end
function IsPedInAnyVehicle() return state.vehicle or false end
for _, name in ipairs({'IsPedRagdoll','IsPedFalling','IsPedClimbing','IsPedSwimming','IsPedHogtied','IsPedCuffed','IsPedInCombat','IsPedJumping','IsPedAimingFromCover','IsPlayerFreeAiming','IsPedShooting','IsEntityAttached'}) do _G[name]=function() return false end end
function IsNuiFocused() return state.nui or false end
function IsPauseMenuActive() return state.pause or false end
function IsPlayerControlOn() return not state.playerControlOff end
function IsPedStill() return true end
local speedCalls=0
function GetEntitySpeed() speedCalls=speedCalls+1;return 0 end
function IsPedUsingAnyScenario() return state.scenario or false end
function GetResourceState(r) return state[r] and 'started' or 'missing' end
exports=setmetatable({}, {__index=function(_,r) return {zata_IsMenuOpen=function() if not state.lightweight then error("not installed") end;lightCalls=lightCalls+1;return r=="feather-menu" and (state.featherOpen or false) or r=="vorp_menu" and (state.vorpOpen or false) end,initiate=function() exportCalls=exportCalls+1;if state.exportError then error("simulated export failure") end; return {activeMenu=state.featherOpen and {} or nil} end,GetMenuData=function() exportCalls=exportCalls+1;if state.exportError then error("simulated export failure") end; return {GetOpenedMenus=function() return state.vorpOpen and {{name="test"}} or {false} end} end} end})
function IsDisabledControlPressed(_,key) return state.disabled and state[key] or false end
function IsControlEnabled() return not state.disabled end
function IsControlPressed(_,key) return state[key] or false end
function IsControlJustPressed(_,key) return state[key] or false end
function GetControlNormal(_,key) return state[key] and 1 or 0 end
function GetFrameTime() return 1/60 end
local heading=0
function GetEntityHeading() return heading end
function SetEntityHeading(_,h) heading=h end
function GetGameTimer() return now end
local vectorMeta={}
function vector3(x,y,z)return setmetatable({x=x,y=y,z=z},vectorMeta)end
vectorMeta.__sub=function(a,b)return vector3(a.x-b.x,a.y-b.y,a.z-b.z)end
vectorMeta.__len=function(a)return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z)end
function GetEntityCoords()return vector3(1,2,3)end
json={encode=function(v)return v end}
function DoesAnimDictExist()return true end
function RequestAnimDict()end
function HasAnimDictLoaded()return loaded end
function RemoveAnimDict()end
function TaskPlayAnim()played=played+1 end
local clears, frozen, moved=0,false,false
function ClearPedTasksImmediately() clears=clears+1 end
function FreezeEntityPosition(_,v) frozen=v end
function SetEntityCoordsNoOffset() moved=true end
function GetHashKey(v) return v end
function TaskStartScenarioAtPosition() end
function SendNUIMessage(data)messages[#messages+1]=data end
Config={InteractControl='down',StopControl='up',StopLabel='Aufstehen',Interactions={},Turn={enabled=true,leftControl='left',rightControl='right',degreesPerSecond=90,maxSpeed=.1},IsInputBlocked=function() return state.custom or false end}
local file=assert(io.open('client.lua'));local source=file:read('*a');file:close()
source=source:gsub('`([^`]+)`','"%1"')
assert(load(source,'@client.lua'))()

assert(not IsCompatible({isCompatible=function()return 0 end},1));assert(IsCompatible({isCompatible=function()return 1 end},1))
StartInteraction();assert(not state.nui and #messages==0,'no focus before browser asset readiness');callbacks.uiReady({},function()end)
Config.Interactions={{radius=2,x=1,y=2,z=3,heading=90,scenarios={{name='configured_sit'}}}}
permission=false;StartInteraction();assert(not state.nui and #messages==0,'server refusal must keep UI closed')
permission=true;StartInteraction();assert(state.nui and messages[#messages].type=='showInteractionPicker')
local version=messages[#messages].version
local answer
callbacks.startInteraction({selection=1,version=version+1,x=99999},function(v)answer=v end);assert(not answer.ok and not frozen and not state.nui,'stale and forged NUI input rejected and closed')
StartInteraction();version=messages[#messages].version
callbacks.startInteraction({selection=1,version=version,x=99999,scenario='malicious'},function(v)answer=v end)
assert(answer.ok and frozen and not state.nui,'cached configured selection accepted and focus released')
StopInteraction(true);assert(not frozen)
StartInteraction();assert(state.nui);callbacks.closePicker({},function(v)answer=v end);assert(answer.ok and not state.nui)
Config.Enabled=false;StartInteraction();assert(not state.nui);Config.Enabled=true
local co=coroutine.create(function()StartInteractionAtCoords({x=1,y=2,z=3,heading=90,animation={dict='test',name='test'}})end)
assert(coroutine.resume(co));assert(coroutine.status(co)=='suspended'and frozen)
StopInteraction(true);loaded=true;assert(coroutine.resume(co));assert(played==0 and not frozen,'cancelled animation load must not start later')
print('PASS: refused/disabled opening, own NUI focus, stale/forged selection, trusted entry, close release and cancelled animation loading.')
