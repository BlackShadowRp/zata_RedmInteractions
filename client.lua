local PickerIsOpen = false
local InteractionMarker
local StartingCoords
local CurrentInteraction
local CanStartInteraction = false
local NearbyInteraction = false
local InteractionPed
local InteractionStartedAt = 0
local MaxRadius = 0.0
local TurnDebugUntil = 0
local TurnDebugNext = 0
local TurnDebugTarget
local AvailablePicker={}
local PickerVersion=0
local AuthToken
local PendingPermissions={}
local RequestSequence=0
local InteractionGeneration=0
local UIReady=false
local PickerRequestPending=false
local PickerExpires=0

local function RequestPermission(kind,callback)
    if Config.Enabled==false then return end
    RequestSequence=(RequestSequence%2147483647)+1
    local id=RequestSequence
    PendingPermissions[id]=callback
    TriggerServerEvent('zata_RedmInteractions:request',id,kind)
    SetTimeout(5000,function()local pending=PendingPermissions[id];PendingPermissions[id]=nil;if pending then pending(false)end end)
end
RegisterNetEvent('zata_RedmInteractions:response',function(id,allowed,token)
    local callback=PendingPermissions[id];PendingPermissions[id]=nil
    if callback and Config.Enabled~=false then callback(allowed==true,token)end
end)
local function Audit(action,entry)
    if not AuthToken then return end
    local key=entry and (entry.scenario and 'scenario:'..entry.scenario or entry.animation and 'animation:'..entry.animation.dict..':'..entry.animation.name)
    TriggerServerEvent('zata_RedmInteractions:audit',AuthToken,action,key and {key=key}or {})
end

local InteractPrompt = Config.InteractControl and Uiprompt:new(Config.InteractControl, "Nutzen", nil, false)
local StopPrompt = Config.StopControl and Uiprompt:new(Config.StopControl, Config.StopLabel, nil, false)

-- Some RedM natives/integrations return 0/1 instead of Lua booleans.
local function AsBoolean(value)
    return value ~= nil and value ~= false and value ~= 0
end

local function IsPlayerDead(ped)
    -- Same checks as zata_Camps:isBuildActionDeadOrDying.
    if not ped or ped == 0 or not DoesEntityExist(ped) then return true end
    return AsBoolean(IsEntityDead(ped)) or AsBoolean(IsPedDeadOrDying(ped, true))
        or AsBoolean(IsPedDeadOrDying(ped, false))
end

local MenuEvents = { feather = false, vorp = false }
local MenuWarnings = {}
local LightweightMenus = {}
local MenuCacheUntil = 0
local MenuCacheReason
AddEventHandler("FeatherMenu:opened", function() MenuEvents.feather = true; MenuCacheUntil = 0 end)
AddEventHandler("FeatherMenu:closed", function() MenuEvents.feather = false; MenuCacheUntil = 0 end)
AddEventHandler("vorp_menu:openmenu", function() MenuEvents.vorp = true; MenuCacheUntil = 0 end)
AddEventHandler("vorp_menu:closemenu", function() MenuEvents.vorp = false; MenuCacheUntil = 0 end)
AddEventHandler("onClientResourceStop", function(resource)
    if resource == "feather-menu" then MenuEvents.feather = false end
    if resource == "vorp_menu" then MenuEvents.vorp = false end
    MenuWarnings[resource] = nil
    LightweightMenus[resource] = nil
    MenuCacheUntil = 0
end)

local function WarnMenuFailure(resource, result)
    if MenuWarnings[resource] then return end
    MenuWarnings[resource] = true
    print(("[zata_RedmInteractions] %s-Menüabfrage fehlgeschlagen: %s; nutze NUI-Fokus und Menü-Ereignisse.")
        :format(resource, tostring(result)))
end

local function LightweightMenuState(resource)
    if LightweightMenus[resource] == false then return nil end
    local ok, open = pcall(function() return exports[resource]:zata_IsMenuOpen() end)
    if ok and (type(open) == "boolean" or open == 0 or open == 1) then
        LightweightMenus[resource] = true
        return AsBoolean(open)
    end
    LightweightMenus[resource] = false
    print(("[zata_RedmInteractions] %s: leichter Menü-Export fehlt; bisheriger Adapter bleibt aktiv bis zum Menü-Resource-Neustart."):format(resource))
end

local function QueryMenuBlockReason()
    if GetResourceState("feather-menu") == "started" then
        local lightweight = LightweightMenuState("feather-menu")
        if lightweight then return "feather_menu" end
        if lightweight == nil then
            local ok, menu = pcall(function() return exports["feather-menu"]:initiate() end)
            if ok and type(menu) == "table" then
                if type(menu.activeMenu) == "table" then return "feather_menu" end
            else
                WarnMenuFailure("feather-menu", menu)
                if MenuEvents.feather then return "feather_menu_event" end
            end
        end
    end
    if GetResourceState("vorp_menu") == "started" then
        local lightweight = LightweightMenuState("vorp_menu")
        if lightweight then return "vorp_menu" end
        if lightweight == nil then
            local ok, menus = pcall(function()
                local api = exports["vorp_menu"]:GetMenuData()
                return api.GetOpenedMenus()
            end)
            if ok and type(menus) == "table" then
                -- Do not treat false entries/holes in Opened as active menus.
                for _, menu in pairs(menus) do
                    if type(menu) == "table" then return "vorp_menu" end
                end
            else
                WarnMenuFailure("vorp_menu", menus)
                if MenuEvents.vorp then return "vorp_menu_event" end
            end
        end
    end
end

local function ExternalInputBlockReason(forceRefresh)
    -- Am Schachtisch übernehmen die eigenen Sitz- und Brettkamera-Prompts.
    if GetResourceState("zata_Chess") == "started" then
        local ok, blocked = pcall(function() return exports.zata_Chess:blocksInteractions() end)
        if ok and blocked == true then return "chess" end
    end
    if AsBoolean(IsNuiFocused())and not PickerIsOpen then return "nui_focus" end
    if AsBoolean(IsPauseMenuActive()) then return "pause_menu" end
    local now = GetGameTimer()
    if forceRefresh or now >= MenuCacheUntil then
        MenuCacheReason = QueryMenuBlockReason()
        MenuCacheUntil = now + 100
    end
    if MenuCacheReason then return MenuCacheReason end
    if Config.IsInputBlocked and AsBoolean(Config.IsInputBlocked()) then return "custom_block" end
end

local function InputBlockReason(ped, forceRefresh)
    if Config.Enabled==false then return "resource_disabled" end
    if IsPlayerDead(ped) then return "dead_or_invalid_ped" end
    if AsBoolean(IsPedOnMount(ped)) then return "mounted" end
    if AsBoolean(IsPedEnteringAnyTransport(ped)) then return "entering_transport" end
    if AsBoolean(IsPedInAnyVehicle(ped, false)) then return "vehicle" end
    if AsBoolean(IsPedRagdoll(ped)) then return "ragdoll" end
    if AsBoolean(IsPedFalling(ped)) then return "falling" end
    if AsBoolean(IsPedClimbing(ped)) then return "climbing" end
    if AsBoolean(IsPedSwimming(ped)) then return "swimming" end
    if AsBoolean(IsPedHogtied(ped)) then return "hogtied" end
    if AsBoolean(IsPedCuffed(ped)) then return "cuffed" end
    if AsBoolean(IsPedInCombat(ped)) then return "combat" end
    return ExternalInputBlockReason(forceRefresh)
end

local function CanUseInputs(ped, forceRefresh)
    return InputBlockReason(ped, forceRefresh) == nil
end

local function TurnBlockReason(ped, inputsChecked)
    local reason = not inputsChecked and InputBlockReason(ped)
    if reason then return reason end
    if PickerIsOpen then return "picker_open" end
    if CurrentInteraction then return "active_interaction" end
    if not Config.Turn.enabled then return "turn_disabled" end
    if not AsBoolean(IsPlayerControlOn(PlayerId())) then return "player_control_off" end
    if GetEntitySpeed(ped) > Config.Turn.maxSpeed then return "moving_speed" end
    if math.abs(GetControlNormal(0, `INPUT_MOVE_LR`)) >= 0.1 then return "movement_axis_lr" end
    if math.abs(GetControlNormal(0, `INPUT_MOVE_UD`)) >= 0.1 then return "movement_axis_ud" end
    if AsBoolean(IsPedUsingAnyScenario(ped)) then return "scenario" end
    if AsBoolean(IsPedJumping(ped)) then return "jumping" end
    if AsBoolean(IsPedAimingFromCover(ped)) then return "cover_aiming" end
    if AsBoolean(IsPlayerFreeAiming(PlayerId())) then return "aiming" end
    if AsBoolean(IsPedShooting(ped)) then return "shooting" end
    if AsBoolean(IsEntityAttached(ped)) then return "attached" end
    if not AsBoolean(IsControlEnabled(0, `INPUT_MOVE_LR`)) then return "movement_lr_disabled" end
    if not AsBoolean(IsControlEnabled(0, `INPUT_MOVE_UD`)) then return "movement_ud_disabled" end
end

local function TurnKeyDown(side)
    local control = Config.Turn[side .. "Control"]
    local rawKey = Config.Turn[side .. "RawKey"]
    local down
    if rawKey and type(IsRawKeyDown) == "function" then
        down = AsBoolean(IsRawKeyDown(rawKey))
    else
        down = AsBoolean(IsControlPressed(0, control))
    end
    return down and AsBoolean(IsControlEnabled(0, control))
end

local function TraceTurning(ped)
    local now = GetGameTimer()
    if now >= TurnDebugUntil or now < TurnDebugNext then return end
    TurnDebugNext = now + 500
    local keys = {}
    for group = 0, 2 do
        for _, side in ipairs({"left", "right"}) do
            local control = Config.Turn[side .. "Control"]
            keys[#keys + 1] = ("g%s.%s=%s/%s/%s"):format(group, side,
                tostring(IsControlEnabled(group, control)), tostring(IsControlPressed(group, control)),
                tostring(IsDisabledControlPressed(group, control)))
        end
    end
    print(("[zata_RedmInteractions turn] block=%s speed=%.3f axes=%.3f/%.3f heading=%.3f lastTarget=%s held=%s/%s %s")
        :format(TurnBlockReason(ped) or "none", GetEntitySpeed(ped),
            GetControlNormal(0, `INPUT_MOVE_LR`), GetControlNormal(0, `INPUT_MOVE_UD`),
            GetEntityHeading(ped), (TurnDebugTarget and ("%.3f"):format(TurnDebugTarget)or "nil"), tostring(TurnKeyDown("left")),
            tostring(TurnKeyDown("right")), table.concat(keys, " ")))
end

local function SetPromptVisible(prompt, visible)
    if prompt and prompt:isEnabled() ~= visible then
        prompt:setEnabledAndVisible(visible)
    end
end

local function ClosePicker()
    if PickerIsOpen then
        Audit('pickerClosed')
        SetNuiFocus(false,false)
        if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false)end
    end
    AvailablePicker={}
    SendNUIMessage({type = "hideInteractionPicker"})
    InteractionMarker = nil
    PickerIsOpen = false
end

function DrawMarker(type, posX, posY, posZ, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
	Citizen.InvokeNative(0x2A32FAA57B937173, type, posX, posY, posZ, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
end

function IsPedUsingScenarioHash(ped, scenarioHash)
	return Citizen.InvokeNative(0x34D6AC1157C8226C, ped, scenarioHash)
end

function GetNearbyObjects(coords)
	local itemset = CreateItemset(true)
	local size = Citizen.InvokeNative(0x59B57C4B06531E1E, coords, MaxRadius, itemset, 3, Citizen.ResultAsInteger())

	local objects = {}

	if size > 0 then
		for i = 0, size - 1 do
			table.insert(objects, GetIndexedItemInItemset(i, itemset))
		end
	end

	if IsItemsetValid(itemset) then
		DestroyItemset(itemset)
	end

	return objects
end

function HasCompatibleModel(entity, models)
	local entityModel = GetEntityModel(entity)

	for _, model in ipairs(models) do
		if entityModel  == GetHashKey(model) then
			return model
		end
	end

	return nil
end

function CanStartInteractionAtObject(interaction, object, playerCoords, objectCoords)
	if #(playerCoords - objectCoords) > interaction.radius then
		return nil
	end

	return HasCompatibleModel(object, interaction.objects)
end

function PlayAnimation(ped, anim, generation)
	if not DoesAnimDictExist(anim.dict) then
		print("Ungültige Animation: " .. anim.dict)
		return false
	end

	RequestAnimDict(anim.dict)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(anim.dict) do
        if GetGameTimer() > deadline or ped ~= PlayerPedId() or not CanUseInputs(ped)or generation~=InteractionGeneration then
            RemoveAnimDict(anim.dict)
            return false
        end
        Citizen.Wait(0)
    end
    if ped ~= PlayerPedId() or not CanUseInputs(ped)or generation~=InteractionGeneration then RemoveAnimDict(anim.dict);return false end

	TaskPlayAnim(ped, anim.dict, anim.name, 0.0, 0.0, -1, 1, 1.0, false, false, false, "", false)

	RemoveAnimDict(anim.dict)
    return true
end

function StartInteractionAtCoords(interaction)
    InteractionGeneration=InteractionGeneration+1
    local generation=InteractionGeneration
	local x = interaction.x
	local y = interaction.y
	local z = interaction.z
	local h = interaction.heading

	local ped = PlayerPedId()
	if not CanUseInputs(ped, true) then return end
	InteractionPed = ped
	InteractionStartedAt = GetGameTimer()

	if not StartingCoords then
		StartingCoords = GetEntityCoords(ped)
	end

	ClearPedTasksImmediately(ped)

	FreezeEntityPosition(ped, true)

	if interaction.scenario then
		TaskStartScenarioAtPosition(ped, GetHashKey(interaction.scenario), x, y, z, h, -1, false, true)
	elseif interaction.animation then
		SetEntityCoordsNoOffset(ped, x, y, z)
		SetEntityHeading(ped, h)
        if not PlayAnimation(ped,interaction.animation,generation)then
            if generation==InteractionGeneration then
                Audit('failed',interaction)
                StopInteraction(true)
            end
            return false
        end
	end

	if interaction.effect then
		if Config.Effects[interaction.effect]then Config.Effects[interaction.effect]()end
	end

	CurrentInteraction = interaction
    Audit("start",interaction)
    return true
end

function StartInteractionAtObject(interaction)
    -- Zeppelinbänke benötigen einen mitbewegten Sitz statt fester Weltkoordinaten.
    local handled, started = false, false
    local ped = PlayerPedId()
    if not CanUseInputs(ped, true) then return end
    TriggerEvent("zata_Zeppelin:client:startBenchInteraction", interaction, function(result)
        handled = type(result) == "table" and result.handled == true
        started = handled and result.started == true
    end)
    if handled then
        if started then
            InteractionPed = ped
            InteractionStartedAt = GetGameTimer()
            StartingCoords = nil
            CurrentInteraction = interaction
            CurrentInteraction.zeppelinBench = true
            Audit("start",interaction)
        end
        return
    end
	local objectHeading = GetEntityHeading(interaction.object)
	local objectCoords = GetEntityCoords(interaction.object)

	local r = math.rad(objectHeading)
	local cosr = math.cos(r)
	local sinr = math.sin(r)

	local x = interaction.x * cosr - interaction.y * sinr + objectCoords.x
	local y = interaction.y * cosr + interaction.x * sinr + objectCoords.y
	local z = interaction.z + objectCoords.z
	local h = interaction.heading + objectHeading

	interaction.x = x
	interaction.y = y
	interaction.z = z
	interaction.heading = h

	StartInteractionAtCoords(interaction)
    -- Erst nach dem unveränderten Möbelstart die optionale Mitnahme anmelden.
    if CurrentInteraction ~= interaction then return end
    TriggerEvent('zata_Zeppelin:client:benchInteractionStarted', interaction, function(managed)
        if managed == true and CurrentInteraction == interaction then
            CurrentInteraction.zeppelinBench = true
            StartingCoords = nil
        end
    end)
end

function IsCompatible(t, ped)
	return not t.isCompatible or AsBoolean(t.isCompatible(ped))
end

function GetTranslatedLabel(translations, key, fallback)
	if type(translations) ~= "table" then
		return fallback
	end

	local translatedLabel = translations[key]

	if type(translatedLabel) ~= "string" then
		return fallback
	end

	translatedLabel = translatedLabel:match("^%s*(.-)%s*$")

	if translatedLabel == "" then
		return fallback
	end

	return translatedLabel
end

function GetScenarioLabel(scenarioName)
	return GetTranslatedLabel(ScenarioTranslations, scenarioName, scenarioName)
end

function GetAnimationLabel(animation)
	if not animation then
		return nil
	end

	return GetTranslatedLabel(AnimationTranslations, animation.name, animation.label or animation.name)
end

function GetPropLabel(modelName)
	return GetTranslatedLabel(PropTranslations, modelName, modelName)
end

function GetInteractionLabel(label)
	return GetTranslatedLabel(InteractionLabelTranslations, label, label)
end

function SortInteractions(a, b)
	if a.distance == b.distance then
		if a.object == b.object then
			local aLabel = a.scenarioLabel or a.scenario or a.animationLabel or a.animation.label
			local bLabel = b.scenarioLabel or b.scenario or b.animationLabel or b.animation.label
			return aLabel < bLabel
		else
			return tostring(a.object or "") < tostring(b.object or "")
		end
	else
		return a.distance < b.distance
	end
end

function AddInteractions(availableInteractions, interaction, playerPed, playerCoords, targetCoords, modelName, object, definition)
	local distance = #(playerCoords - targetCoords)

	if interaction.scenarios then
		for _, scenario in ipairs(interaction.scenarios) do
			if IsCompatible(scenario, playerPed) then
				table.insert(availableInteractions, {
					definition = definition,
					x = interaction.x,
					y = interaction.y,
					z = interaction.z,
					heading = interaction.heading,
					scenario = scenario.name,
					scenarioLabel = GetScenarioLabel(scenario.name),
					object = object,
					modelName = modelName,
					modelLabel = modelName and GetPropLabel(modelName) or nil,
					distance = distance,
					label = interaction.label and GetInteractionLabel(interaction.label) or nil,
					effect = interaction.effect
				})
			end
		end
	end

	if interaction.animations then
		for _, animation in ipairs(interaction.animations) do
			if IsCompatible(animation, playerPed) then
				table.insert(availableInteractions, {
					definition = definition,
					x = interaction.x,
					y = interaction.y,
					z = interaction.z,
					heading = interaction.heading,
					animation = animation,
					animationLabel = GetAnimationLabel(animation),
					object = object,
					modelName = modelName,
					modelLabel = modelName and GetPropLabel(modelName) or nil,
					distance = distance,
					label = interaction.label and GetInteractionLabel(interaction.label) or nil,
					effect = interaction.effect
				})
			end
		end
	end
end

function GetAvailableInteractions()
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local availableInteractions = {}
    local nearbyObjects
    local objectCoordsCache = {}

	for definition, interaction in ipairs(Config.Interactions) do
		if IsCompatible(interaction, playerPed) then
			if interaction.objects then
				nearbyObjects = nearbyObjects or GetNearbyObjects(playerCoords)
				for _, object in ipairs(nearbyObjects) do
                    local objectCoords = objectCoordsCache[object]
                    if not objectCoords then
                        objectCoords = GetEntityCoords(object)
                        objectCoordsCache[object] = objectCoords
                    end

					local modelName = CanStartInteractionAtObject(interaction, object, playerCoords, objectCoords)

					if modelName then
						AddInteractions(availableInteractions, interaction, playerPed, playerCoords, objectCoords, modelName, object, definition)
					end
				end
			else
				local targetCoords = vector3(interaction.x, interaction.y, interaction.z)

				if #(playerCoords - targetCoords) <= interaction.radius then
					AddInteractions(availableInteractions, interaction, playerPed, playerCoords, targetCoords, nil, nil, definition)
				end
			end
		end
	end

	table.sort(availableInteractions, SortInteractions)

	return availableInteractions
end

function StartInteraction()
    if not UIReady or PickerIsOpen or PickerRequestPending or not CanUseInputs(PlayerPedId(),true)then return end
    PickerRequestPending=true
    RequestPermission('picker',function(allowed,token)
        PickerRequestPending=false
        if not allowed or type(token)~='string'or PickerIsOpen or not CanUseInputs(PlayerPedId(),true)then return end
        local available=GetAvailableInteractions()
        if #available==0 then
            if CurrentInteraction then StopInteraction()end
            return
        end
        AuthToken=token;PickerExpires=GetGameTimer()+300000;AvailablePicker=available;PickerVersion=PickerVersion+1;PickerIsOpen=true
        SetNuiFocus(true,true)
        if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false)end
        SendNUIMessage({type='showInteractionPicker',interactions=json.encode(available),version=PickerVersion})
        Audit('pickerOpened')
    end)
end

function StopInteraction(interrupted, cancelExternal)
    InteractionGeneration=InteractionGeneration+1
    if CurrentInteraction then Audit("stop",CurrentInteraction)end
    local ped = InteractionPed or (cancelExternal and PlayerPedId())
    local coords = StartingCoords
    local zeppelinBench = CurrentInteraction and CurrentInteraction.zeppelinBench
    CurrentInteraction = nil
    StartingCoords = nil
    InteractionPed = nil
    ClosePicker()
    SetPromptVisible(StopPrompt, false)
    if ped and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false)
        -- Death/other interruptions must preserve the new task and position.
        if not interrupted and not IsPlayerDead(ped) then
            ClearPedTasksImmediately(ped)
            if coords and not zeppelinBench then
                SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z)
            end
        end
    end
    -- Erst die alte Möbelaufgabe beenden, dann den Zeppelinadapter zurückgeben.
    -- Ein anschließendes ClearPedTasks würde dessen Deck-Warmup wieder lösen.
    if zeppelinBench then
        TriggerEvent("zata_Zeppelin:client:stopBenchInteraction", ped, interrupted == true)
    end
end

AddEventHandler('zata_Zeppelin:client:benchInteractionEnded', function(ped)
    if CurrentInteraction and CurrentInteraction.zeppelinBench and InteractionPed == ped then
        -- Die Zeppelinseite hat bereits aufgeräumt oder an eine andere Steuerung
        -- übergeben. Hier weder die neue Aufgabe noch Attach/Fokuszustand verändern.
        CurrentInteraction = nil
        StartingCoords = nil
        InteractionPed = nil
        SetPromptVisible(StopPrompt, false)
    end
end)

function SetInteractionMarker(target)
	InteractionMarker = target
end

function DrawInteractionMarker()
	local x, y, z

	if type(InteractionMarker) == "number" then
        if not DoesEntityExist(InteractionMarker)then InteractionMarker=nil;return end
		x, y, z = table.unpack(GetEntityCoords(InteractionMarker))
	else
		x, y, z = table.unpack(InteractionMarker)
	end

	DrawMarker(Config.MarkerType, x, y, z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, Config.MarkerColor[1], Config.MarkerColor[2], Config.MarkerColor[3], Config.MarkerColor[4], 0, 0, 2, 0, 0, 0, 0)
end

function IsPedUsingInteraction(ped, interaction)
    if interaction.zeppelinBench then
        local active = false
        TriggerEvent('zata_Zeppelin:client:benchInteractionActive', ped, function(value) active = value == true end)
        return active
    end
	if interaction.scenario then
		return AsBoolean(IsPedUsingScenarioHash(ped, GetHashKey(interaction.scenario)))
	elseif interaction.animation then
		return AsBoolean(IsEntityPlayingAnim(ped, interaction.animation.dict, interaction.animation.name, 1))
	else
		return false
	end
end

function IsInteractionNearby(playerPed)
	local playerCoords = GetEntityCoords(playerPed)
    local nearbyObjects
    local objectCoordsCache = {}

	for _, interaction in ipairs(Config.Interactions) do
		if IsCompatible(interaction, playerPed) then
			if interaction.objects then
				nearbyObjects = nearbyObjects or GetNearbyObjects(playerCoords)
				for _, object in ipairs(nearbyObjects) do
                    local objectCoords = objectCoordsCache[object]
                    if not objectCoords then
                        objectCoords = GetEntityCoords(object)
                        objectCoordsCache[object] = objectCoords
                    end

					local modelName = CanStartInteractionAtObject(interaction, object, playerCoords, objectCoords)

					if modelName then
						return true
					end
				end
			else
				local targetCoords = vector3(interaction.x, interaction.y, interaction.z)

				if #(playerCoords - targetCoords) <= interaction.radius then
					return true
				end
			end
		end
	end

	return false
end

local function SelectedEntry(data)
    if not PickerIsOpen or GetGameTimer()>PickerExpires or type(data)~='table'or data.version~=PickerVersion then return end
    local index=tonumber(data.selection)
    if not index or index%1~=0 then return end
    return AvailablePicker[index]
end
RegisterNUICallback('uiReady',function(_,cb)UIReady=true;cb({enabled=Config.Enabled~=false})end)
RegisterNUICallback('closePicker',function(_,cb)ClosePicker();cb({ok=true})end)
RegisterNUICallback('startInteraction',function(data,cb)
    local entry=SelectedEntry(data)
    local definition=entry and Config.Interactions[entry.definition]
    local ped=PlayerPedId()
    if not entry or not definition or not IsCompatible(definition,ped)then ClosePicker();cb({ok=false});return end
    local valid
    if entry.object then
        valid=DoesEntityExist(entry.object)and CanStartInteractionAtObject(definition,entry.object,GetEntityCoords(ped),GetEntityCoords(entry.object))
    else
        valid=#(GetEntityCoords(ped)-vector3(entry.x,entry.y,entry.z))<=definition.radius
    end
    if not valid then Audit('failed',entry);ClosePicker();cb({ok=false});return end
    ClosePicker()
    if entry.object then StartInteractionAtObject(entry)else StartInteractionAtCoords(entry)end
    cb({ok=CurrentInteraction==entry})
end)
RegisterNUICallback('stopInteraction',function(_,cb)StopInteraction(false,true);cb({ok=true})end)
RegisterNUICallback('setInteractionMarker',function(data,cb)
    local entry=SelectedEntry(data)
    if entry then SetInteractionMarker(entry.object or vector3(entry.x,entry.y,entry.z))else SetInteractionMarker()end
    cb({ok=entry~=nil})
end)

RegisterCommand("zata_redminteractions_interact", function(source, args, raw)
	StartInteraction()
end, false)

Citizen.CreateThread(function()
    for _, interaction in ipairs(Config.Interactions) do
        MaxRadius = math.max(MaxRadius, interaction.radius)
    end
    while true do
        local ped = PlayerPedId()
        NearbyInteraction = CanUseInputs(ped) and IsInteractionNearby(ped)
        Citizen.Wait(500)
    end
end)

Citizen.CreateThread(function()
    local turnVelocity = 0.0
    while true do
        local ped = PlayerPedId()
        CanStartInteraction = CanUseInputs(ped)
        local turnApplied = false
        TraceTurning(ped)

        if CurrentInteraction and (ped ~= InteractionPed or IsPlayerDead(ped)
            or AsBoolean(IsPedOnMount(ped)) or AsBoolean(IsPedInAnyVehicle(ped, false))
            or AsBoolean(IsPedRagdoll(ped)) or AsBoolean(IsPedHogtied(ped)) or AsBoolean(IsPedCuffed(ped))) then
            StopInteraction(true)
        end
        if CurrentInteraction and GetGameTimer() - InteractionStartedAt > 1500
            and not IsPedUsingInteraction(ped, CurrentInteraction) then
            StopInteraction(true)
        end

        SetPromptVisible(InteractPrompt, UIReady and CanStartInteraction and (NearbyInteraction or CurrentInteraction ~= nil)
            and not PickerIsOpen)
        SetPromptVisible(StopPrompt, CanStartInteraction and CurrentInteraction ~= nil and not PickerIsOpen)

        if PickerIsOpen and not CanStartInteraction then ClosePicker() end

        if PickerIsOpen then
            DisableAllControlActions(0)
            if IsDisabledControlJustPressed(0, Config.MenuUpControl) then
                SendNUIMessage({type = "moveSelectionUp"})
            end
            if IsDisabledControlJustPressed(0, Config.MenuDownControl) then
                SendNUIMessage({type = "moveSelectionDown"})
            end
            if IsDisabledControlJustPressed(0, Config.MenuAcceptControl) then
                SendNUIMessage({type = "startInteraction"})
                InteractionMarker = nil
            elseif IsDisabledControlJustPressed(0, Config.MenuCancelControl) then
                StopInteraction(false, true)
            end
            if InteractionMarker then DrawInteractionMarker() end
        elseif CanStartInteraction then
            if CurrentInteraction and Config.StopControl and IsControlEnabled(0, Config.StopControl)
                and IsControlJustPressed(0, Config.StopControl) then
                StopInteraction()
            elseif Config.InteractControl and (NearbyInteraction or CurrentInteraction ~= nil)
                and IsControlEnabled(0, Config.InteractControl)
                and IsControlJustPressed(0, Config.InteractControl) then
                StartInteraction()
            elseif Config.Turn.enabled and not CurrentInteraction then
                local left = TurnKeyDown("left")
                local right = TurnKeyDown("right")
                if left ~= right and not TurnBlockReason(ped, true)
                    and (turnVelocity ~= 0.0 or CanUseInputs(ped, true)) then
                    local dt = math.min(GetFrameTime(), 0.05)
                    local speed = math.max(0.0, Config.Turn.degreesPerSecond)
                    local target = left and speed or -speed
                    local ramp = math.max(0.0, Config.Turn.accelerationSeconds or 0.2)
                    local step = ramp > 0 and speed * dt / ramp or math.huge
                    turnVelocity = turnVelocity + math.max(-step, math.min(step, target - turnVelocity))
                    local targetHeading = (GetEntityHeading(ped) + turnVelocity * dt) % 360.0
                    SetEntityHeading(ped, targetHeading)
                    if GetGameTimer() < TurnDebugUntil then TurnDebugTarget = targetHeading end
                    turnApplied = true
                end
            end
        end
        if not turnApplied then turnVelocity = 0.0 end
        Citizen.Wait(0)
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        StopInteraction(true)
    end
end)

RegisterCommand("zata_redminteractions_debug", function()
    RequestPermission("debug",function(allowed)
    if not allowed then return end
    local ped = PlayerPedId()
    local reason = InputBlockReason(ped) or "none"
    print(("[zata_RedmInteractions] ped=%s dead=%s blocked=%s nearby=%s radius=%s picker=%s interaction=%s playerControl=%s")
        :format(tostring(ped), tostring(IsPlayerDead(ped)), reason, tostring(NearbyInteraction),
            tostring(MaxRadius), tostring(PickerIsOpen), tostring(CurrentInteraction ~= nil),
            tostring(IsPlayerControlOn(PlayerId()))))
    print(("[zata_RedmInteractions] interactControl=%s promptEnabled=%s feather=%s vorp=%s")
        :format(tostring(Config.InteractControl), tostring(InteractPrompt and InteractPrompt:isEnabled()),
            GetResourceState("feather-menu"), GetResourceState("vorp_menu")))
    end)
end, false)

RegisterCommand("zata_redminteractions_turndebug", function()
    RequestPermission("turndebug",function(allowed)
    if not allowed then return end
    TurnDebugUntil = GetGameTimer() + 10000
    TurnDebugNext = 0
    TurnDebugTarget = nil
    print("[zata_RedmInteractions turn] Diagnose für 10 Sekunden aktiv. Links/rechts halten; Tastenwerte: enabled/pressed/disabledPressed.")
    end)
end, false)
