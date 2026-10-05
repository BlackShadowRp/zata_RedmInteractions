local state = {}
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
function GetEntitySpeed() return 0 end
function IsPedUsingAnyScenario() return state.scenario or false end
function GetResourceState(r) return state[r] and 'started' or 'missing' end
exports=setmetatable({}, {__index=function(_,r) return {initiate=function() if state.exportError then error("simulated export failure") end; return {activeMenu=state.featherOpen and {} or nil} end,GetMenuData=function() if state.exportError then error("simulated export failure") end; return {GetOpenedMenus=function() return state.vorpOpen and {{name="test"}} or {false} end} end} end})
function IsDisabledControlPressed(_,key) return state.disabled and state[key] or false end
function IsControlEnabled() return not state.disabled end
function IsControlPressed(_,key) return state[key] or false end
function IsControlJustPressed(_,key) return state[key] or false end
function GetControlNormal(_,key) return state[key] and 1 or 0 end
function GetFrameTime() return 1/60 end
local heading=0
function GetEntityHeading() return heading end
function SetEntityHeading(_,h) heading=h end
function GetGameTimer() return 100 end
function GetEntityCoords() return {x=1,y=2,z=3} end
local clears, frozen, moved=0,false,false
function ClearPedTasksImmediately() clears=clears+1 end
function FreezeEntityPosition(_,v) frozen=v end
function SetEntityCoordsNoOffset() moved=true end
function GetHashKey(v) return v end
function TaskStartScenarioAtPosition() end
function SendNUIMessage() end
Config={InteractControl='down',StopControl='up',StopLabel='Aufstehen',Interactions={},Turn={enabled=true,leftControl='left',rightControl='right',degreesPerSecond=90,maxSpeed=.1},IsInputBlocked=function() return state.custom or false end}
local file=assert(io.open('client.lua'));local source=file:read('*a');file:close()
source=source:gsub('`([^`]+)`','"%1"')
assert(load(source,'@client.lua'))()
IsInteractionNearby=function() return true end
IsPedUsingInteraction=function() return true end
local function frame() local ok,err=coroutine.resume(threads[2]); assert(ok,err) end
local ok,err=coroutine.resume(threads[1]);assert(ok,err)
frame(); assert(prompts[1].enabled and not prompts[2].enabled)
state.left=true;frame();assert(math.abs(heading-.125)<1e-9, "Smooth first frame")
state.playerControlOff=true;local before=heading;frame();assert(heading==before and prompts[1].enabled,'Control lock must block turning without declaring the player dead');state.playerControlOff=nil
for _, key in ipairs({'dead','mount','entering','vehicle','nui','pause','disabled','scenario','custom','INPUT_MOVE_LR','INPUT_MOVE_UD'}) do state[key]=true;local before=heading;frame();assert(heading==before,key);state[key]=nil end
for _, resource in ipairs({'feather-menu','vorp_menu'}) do state[resource]=true;state.featherOpen=true;state.vorpOpen=true;local before=heading;frame();assert(heading==before,resource);state[resource]=nil end
state.featherOpen=nil;state.vorpOpen=nil
state['feather-menu']=true;state['vorp_menu']=true;state.exportError=true
local before=heading;frame();assert(heading~=before,'Broken exports must not permanently block all inputs')
handlers['FeatherMenu:opened']();before=heading;frame();assert(heading==before)
handlers['FeatherMenu:closed']();handlers['vorp_menu:openmenu']();frame();assert(heading==before)
handlers['vorp_menu:closemenu']();state.exportError=nil
state['feather-menu']=nil;state['vorp_menu']=nil
state.dead=0;before=heading;frame();assert(heading~=before,'Numeric zero must mean alive')
state.dead=nil
state.right=true;local before=heading;frame();assert(heading==before);state.left=nil;frame();assert(math.abs(heading-(before-.125))<1e-9);state.right=nil
state.left=true;local start=heading;for i=1,12 do frame() end;local previous=heading;frame();assert(math.abs(heading-previous-1.5)<1e-9,'Reach configured speed after ramp');state.left=nil;previous=heading;frame();assert(heading==previous,'Release must stop immediately');state.left=true;frame();assert(math.abs(heading-previous-.125)<1e-9,'Restart must ramp again');state.left=nil;frame()
StartInteractionAtCoords({x=0,y=0,z=0,heading=0,scenario='sit'});frame();assert(frozen and prompts[2].enabled and prompts[1].enabled)
local originalStart=StartInteraction;local switched=false;StartInteraction=function() switched=true end;state.down=true;local seatedHeading=heading;frame();assert(switched and frozen and heading==seatedHeading,'Down must select another pose without standing or rotating');state.down=nil;StartInteraction=originalStart
state.up=true;frame();assert(not frozen and moved and not prompts[2].enabled and clears==2);state.up=nil
StartInteractionAtCoords({x=0,y=0,z=0,heading=0,scenario='sit'});local oldClears=clears;moved=false;state.dead=true;frame();assert(not frozen and not moved and clears==oldClears);assert(not prompts[1].enabled and not prompts[2].enabled)
state.dead=nil;state.scenario=true;local oldClears=clears;local replied=false;callbacks.stopInteraction({},function() replied=true end);assert(replied and clears==oldClears+1 and not frozen,'Cancel must clear external/native seating');state.scenario=0;state.left=true;local before=heading;frame();assert(heading~=before,'Numeric-zero scenario must not block turning');state.left=nil
Config.Turn.leftRawKey=0x25;Config.Turn.rightRawKey=0x27
function IsRawKeyDown(key) return state[key] or false end
state[0x25]=1;state.left=false
for i=1,12 do state.left=i%4==0;frame() end
local previous=heading;state.left=false;frame()
assert(math.abs(heading-previous-1.5)<1e-9,'Held raw key must reach full speed despite pulsed/absent menu control')
state.disabled=true;previous=heading;frame();assert(heading==previous,'Raw input must respect disabled controls');state.disabled=nil
state.nui=true;frame();assert(heading==previous,'Raw input must respect menus');state.nui=nil
state[0x25]=nil;frame();assert(heading==previous,'Raw release must stop immediately')
state[0x27]=true;for i=1,12 do frame() end;previous=heading;frame();assert(math.abs(heading-previous+1.5)<1e-9,'Held right raw key must rotate at full speed')
state[0x25]=true;previous=heading;frame();assert(heading==previous,'Both raw keys must cancel')
state[0x25]=nil;state[0x27]=nil;frame()
commands.zata_interactionsturndebug();frame()
assert(#prompts==2,'turning must not create prompts')
print('PASS: rotation, simultaneous keys, input/menu gates, prompt switching, instant stop, death cleanup, no turn prompts')
