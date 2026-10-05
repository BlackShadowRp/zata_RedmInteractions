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
AddEventHandler("FeatherMenu:opened", function() MenuEvents.feather = true end)
AddEventHandler("FeatherMenu:closed", function() MenuEvents.feather = false end)
AddEventHandler("vorp_menu:openmenu", function() MenuEvents.vorp = true end)
AddEventHandler("vorp_menu:closemenu", function() MenuEvents.vorp = false end)
AddEventHandler("onClientResourceStop", function(resource)
    if resource == "feather-menu" then MenuEvents.feather = false end
    if resource == "vorp_menu" then MenuEvents.vorp = false end
    MenuWarnings[resource] = nil
end)

local function WarnMenuFailure(resource, result)
    if MenuWarnings[resource] then return end
    MenuWarnings[resource] = true
    print(("[zata_RedmInteractions] %s-Menueabfrage fehlgeschlagen: %s; nutze NUI-Fokus und Menue-Ereignisse.")
        :format(resource, tostring(result)))
end

local function ExternalInputBlockReason()
    if AsBoolean(IsNuiFocused()) then return "nui_focus" end
    if AsBoolean(IsPauseMenuActive()) then return "pause_menu" end
    if GetResourceState("feather-menu") == "started" then
        local ok, menu = pcall(function() return exports["feather-menu"]:initiate() end)
        if ok and type(menu) == "table" then
            if type(menu.activeMenu) == "table" then return "feather_menu" end
        else
            WarnMenuFailure("feather-menu", menu)
            if MenuEvents.feather then return "feather_menu_event" end
        end
    end
    if GetResourceState("vorp_menu") == "started" then
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
    if Config.IsInputBlocked and AsBoolean(Config.IsInputBlocked()) then return "custom_block" end
end

local function InputBlockReason(ped)
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
    return ExternalInputBlockReason()
end

local function CanUseInputs(ped)
    return InputBlockReason(ped) == nil
end

local function TurnBlockReason(ped)
    local reason = InputBlockReason(ped)
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
    if not AsBoolean(IsControlEnabled(0, control)) then return false end
    local rawKey = Config.Turn[side .. "RawKey"]
    if rawKey and type(IsRawKeyDown) == "function" then
        return AsBoolean(IsRawKeyDown(rawKey))
    end
    return AsBoolean(IsControlPressed(0, control))
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
            GetEntityHeading(ped), tostring(TurnDebugTarget), tostring(TurnKeyDown("left")),
            tostring(TurnKeyDown("right")), table.concat(keys, " ")))
end

local function SetPromptVisible(prompt, visible)
    if prompt and prompt:isEnabled() ~= visible then
        prompt:setEnabledAndVisible(visible)
    end
end

local function ClosePicker()
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

function PlayAnimation(ped, anim)
	if not DoesAnimDictExist(anim.dict) then
		print("Invalid animation: " .. anim.dict)
		return
	end

	RequestAnimDict(anim.dict)
    local deadline = GetGameTimer() + 5000
    while not HasAnimDictLoaded(anim.dict) do
        if GetGameTimer() > deadline or ped ~= PlayerPedId() or IsPlayerDead(ped) then
            RemoveAnimDict(anim.dict)
            return
        end
        Citizen.Wait(0)
    end
    if ped ~= PlayerPedId() or IsPlayerDead(ped) then return end

	TaskPlayAnim(ped, anim.dict, anim.name, 0.0, 0.0, -1, 1, 1.0, false, false, false, "", false)

	RemoveAnimDict(anim.dict)
end

function StartInteractionAtCoords(interaction)
	local x = interaction.x
	local y = interaction.y
	local z = interaction.z
	local h = interaction.heading

	local ped = PlayerPedId()
	if not CanUseInputs(ped) then return end
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
		PlayAnimation(ped, interaction.animation)
	end

	if interaction.effect then
		Config.Effects[interaction.effect]()
	end

	CurrentInteraction = interaction
end

function StartInteractionAtObject(interaction)
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
end

function IsCompatible(t, ped)
	return not t.isCompatible or t.isCompatible(ped)
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
			return a.object < b.object
		end
	else
		return a.distance < b.distance
	end
end

function AddInteractions(availableInteractions, interaction, playerPed, playerCoords, targetCoords, modelName, object)
	local distance = #(playerCoords - targetCoords)

	if interaction.scenarios then
		for _, scenario in ipairs(interaction.scenarios) do
			if IsCompatible(scenario, playerPed) then
				table.insert(availableInteractions, {
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

	for _, interaction in ipairs(Config.Interactions) do
		if IsCompatible(interaction, playerPed) then
			if interaction.objects then
				for _, object in ipairs(GetNearbyObjects(playerCoords)) do
					local objectCoords = GetEntityCoords(object)

					local modelName = CanStartInteractionAtObject(interaction, object, playerCoords, objectCoords)

					if modelName then
						AddInteractions(availableInteractions, interaction, playerPed, playerCoords, objectCoords, modelName, object)
					end
				end
			else
				local targetCoords = vector3(interaction.x, interaction.y, interaction.z)

				if #(playerCoords - targetCoords) <= interaction.radius then
					AddInteractions(availableInteractions, interaction, playerPed, playerCoords, targetCoords)
				end
			end
		end
	end

	table.sort(availableInteractions, SortInteractions)

	return availableInteractions
end

function StartInteraction()
	if PickerIsOpen or not CanUseInputs(PlayerPedId()) then return end
	local availableInteractions = GetAvailableInteractions()

	if #availableInteractions > 0 then
		SendNUIMessage({
			type = "showInteractionPicker",
			interactions = json.encode(availableInteractions)
		})
		PickerIsOpen = true
	else
		SendNUIMessage({
			type = "hideInteractionPicker"
		})
		SetInteractionMarker()
		PickerIsOpen = false

		if CurrentInteraction then
			StopInteraction()
		end
	end
end

function StopInteraction(interrupted, cancelExternal)
    local ped = InteractionPed or (cancelExternal and PlayerPedId())
    local coords = StartingCoords
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
            if coords then
                SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z)
            end
        end
    end
end

function SetInteractionMarker(target)
	InteractionMarker = target
end

function DrawInteractionMarker()
	local x, y, z

	if type(InteractionMarker) == "number" then
		x, y, z = table.unpack(GetEntityCoords(InteractionMarker))
	else
		x, y, z = table.unpack(InteractionMarker)
	end

	DrawMarker(Config.MarkerType, x, y, z, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, Config.MarkerColor[1], Config.MarkerColor[2], Config.MarkerColor[3], Config.MarkerColor[4], 0, 0, 2, 0, 0, 0, 0)
end

function IsPedUsingInteraction(ped, interaction)
	if interaction.scenario then
		return IsPedUsingScenarioHash(ped, GetHashKey(interaction.scenario))
	elseif interaction.animation then
		return IsEntityPlayingAnim(ped, interaction.animation.dict, interaction.animation.name, 1)
	else
		return false
	end
end

function IsInteractionNearby(playerPed)
	local playerCoords = GetEntityCoords(playerPed)

	for _, interaction in ipairs(Config.Interactions) do
		if IsCompatible(interaction, playerPed) then
			if interaction.objects then
				for _, object in ipairs(GetNearbyObjects(playerCoords)) do
					local objectCoords = GetEntityCoords(object)

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

RegisterNUICallback("startInteraction", function(data, cb)
	if data.object then
		StartInteractionAtObject(data)
	else
		StartInteractionAtCoords(data)
	end
	cb({})
end)

RegisterNUICallback("stopInteraction", function(data, cb)
	StopInteraction(false, true)
	cb({})
end)

RegisterNUICallback("setInteractionMarker", function(data, cb)
	if data.entity then
		SetInteractionMarker(data.entity)
	elseif data.x and data.y and data.z then
		SetInteractionMarker(vector3(data.x, data.y, data.z))
	else
		SetInteractionMarker()
	end
	cb({})
end)

RegisterCommand("zata_interact", function(source, args, raw)
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

        SetPromptVisible(InteractPrompt, CanStartInteraction and (NearbyInteraction or CurrentInteraction ~= nil)
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
                PickerIsOpen = false
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
            elseif not TurnBlockReason(ped) then
                local left = TurnKeyDown("left")
                local right = TurnKeyDown("right")
                if left ~= right then
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

RegisterCommand("zata_interactionsdebug", function()
    local ped = PlayerPedId()
    local reason = InputBlockReason(ped) or "none"
    print(("[zata_RedmInteractions] ped=%s dead=%s blocked=%s nearby=%s radius=%s picker=%s interaction=%s playerControl=%s")
        :format(tostring(ped), tostring(IsPlayerDead(ped)), reason, tostring(NearbyInteraction),
            tostring(MaxRadius), tostring(PickerIsOpen), tostring(CurrentInteraction ~= nil),
            tostring(IsPlayerControlOn(PlayerId()))))
    print(("[zata_RedmInteractions] interactControl=%s promptEnabled=%s feather=%s vorp=%s")
        :format(tostring(Config.InteractControl), tostring(InteractPrompt and InteractPrompt:isEnabled()),
            GetResourceState("feather-menu"), GetResourceState("vorp_menu")))
end, false)

RegisterCommand("zata_interactionsturndebug", function()
    TurnDebugUntil = GetGameTimer() + 10000
    TurnDebugNext = 0
    TurnDebugTarget = nil
    print("[zata_RedmInteractions turn] Diagnose fuer 10 Sekunden aktiv. Links/rechts halten; Tastenwerte: enabled/pressed/disabledPressed.")
end, false)
