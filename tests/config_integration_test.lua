local child,human,male=0,true,1
Citizen={InvokeNative=function()return child end}
function IsPedHuman()return human end
function IsPedMale()return male end
dofile('common.lua')
assert(IsPedAdult(1));child=1;assert(not IsPedAdult(1));child=true;assert(not IsPedAdult(1));child=false;assert(IsPedAdult(1));human=0;assert(not IsPedAdult(1));human=true
assert(IsPedAdultMale(1)and IsPedHumanMale(1));male=0;assert(IsPedAdultFemale(1)and IsPedHumanFemale(1)and not IsPedHumanMale(1));male=nil;assert(not IsPedHumanFemale(1)and not IsPedHumanMale(1));male=1
local f=assert(io.open('config.lua'));local text=f:read('*a');f:close();text=text:gsub('`[^`]+`','0');assert(load(text,'@config.lua'))()
local count=0;local bath=false;local king=0
for _,entry in ipairs(Config.Interactions)do
 for _,anim in ipairs(entry.animations or {})do
  if anim.dict=='script_story@sal1@ig@sal1_18_lenny_on_lenny'then count=count+1;assert(entry.isCompatible==IsPedAdult)end
 end
 if entry.x==-1682.58 and entry.y==-332.92 and entry.z==173.82 then bath=true end
 for _,model in ipairs(entry.objects or {})do if model=='p_bedking01x'then king=king+1 end end
end
assert(count==28 and bath and king==2)
print('PASS: 28 guarded upstream variants, preserved house bath/king bed positions and native boolean normalization.')
