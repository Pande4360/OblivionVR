
 api = uevr.api
	
	 params = uevr.params
	 callbacks = params.sdk.callbacks
	 pawn = api:get_local_pawn(0)
	 vr=uevr.params.vr



function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name)
        return nil
    end

    return obj
end
function find_static_class(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

function find_first_of(className, includeDefault)
	if includeDefault == nil then includeDefault = false end
	local class =  find_required_object(className)
	if class ~= nil then
		return UEVR_UObjectHook.get_first_object_by_class(class, includeDefault)
	end
	return nil
end

function find_required_object_no_cache(class, full_name)


    local matches = class:get_objects_matching(false)


    for i, obj in ipairs(matches) do


        if obj ~= nil and obj:get_full_name() == full_name then


            return obj


        end


    end


    return nil


end

function SearchSubObjectArrayForObject(ObjArray, string_partial)
local FoundItem= nil
	for i, InvItems in ipairs(ObjArray) do
				if string.find(InvItems:get_fname():to_string(), string_partial) then
				--	print("found")
					FoundItem=InvItems
					--return FoundItem
				break
				end
	end
return	FoundItem
end

--INPUT functions:-------------
-------------------------------

--VR to key functions
function SendKeyPress(key_value, key_up)
    local key_up_string = "down"
    if key_up == true then 
        key_up_string = "up"
    end
    
    api:dispatch_custom_event(key_value, key_up_string)
end

function SendKeyDown(key_value)
    SendKeyPress(key_value, false)
end

function SendKeyUp(key_value)
    SendKeyPress(key_value, true)
end

function PositiveIntegerMask(text)
	return text:gsub("[^%-%d]", "")
end
--
--Xinput helpers
function isButtonPressed(state, button)
	return state.Gamepad.wButtons & button ~= 0
end
function isButtonNotPressed(state, button)
	return state.Gamepad.wButtons & button == 0
end
function pressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons | button
end
function unpressButton(state, button)
	state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end
--

--GLOBAL VARIABLES
current_scope_state=false
left_hand_component = nil
right_hand_component = nil
hmd_component = nil
Diff_Vector_LR  =nil
Diff_Rotator_LR =nil
RightRotator     =nil
LeftRotator=nil					

	HmdRotator = nil--hmd_component:K2_GetComponentRotation()					

--Dynamic helper functions:
 ThumbLX   = 0
 ThumbLY   = 0
 ThumbRX   = 0
 ThumbRY   = 0
 LTrigger  = 0
 RTrigger  = 0
 rShoulder = false
 lShoulder = false
 lThumb    = false
 rThumb    = false
 Abutton = false
 Bbutton = false
 Xbutton = false
 Ybutton = false
 SelectButton=false


isSprinting=false
isDriving=false
isMenu=false
isWeaponDrawn=false
local GameTime= 0
isBow=false
isRiding=false
local function UpdateBowStatus(pawn)

	isBow=false
	if isRiding==false then
		if pawn.WeaponsPairingComponent.WeaponActor~=nil then
			if pawn.WeaponsPairingComponent.WeaponActor.MainSkeletalMeshComponent ~=nil then
					if string.find(pawn.WeaponsPairingComponent.WeaponActor:get_fname():to_string(), "Bow") then
						isBow=true
					end
			end
		end
	end
end
local function UpdateRidingStatus(Pawn)
	isRiding=false
	if string.find(Pawn:get_fname():to_string(),"Horse") then
		isRiding=true

	end
end


--function UpdateInput(state)
--
----Read Gamepad stick input 
--	ThumbLX = state.Gamepad.sThumbLX
--	ThumbLY = state.Gamepad.sThumbLY
--	ThumbRX = state.Gamepad.sThumbRX
--	ThumbRY = state.Gamepad.sThumbRY
--	LTrigger= state.Gamepad.bLeftTrigger
--	RTrigger= state.Gamepad.bRightTrigger
--	rShoulder= isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
--	lShoulder= isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
--	lThumb   = isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB)
--	rThumb   = isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB)
--	Abutton  = isButtonPressed(state, XINPUT_GAMEPAD_A)
--	Bbutton  = isButtonPressed(state, XINPUT_GAMEPAD_B)
--	Xbutton  = isButtonPressed(state, XINPUT_GAMEPAD_X)
--	Ybutton  = isButtonPressed(state, XINPUT_GAMEPAD_Y)
--
--	
--
--	
----UnpressButton
--
--	--	unpressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
--	--	unpressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
--	
--	--if lThumb then
--	--	pressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
--	--end
--	--if lShoulder then
--	--	pressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
--	--end
--
--end



local function UpdateMenuStatus(Player)
	if Player.bShowMouseCursor then
		isMenu=true
	else isMenu=false
	end
end
local function UpdateCombatStanceStatus(pawn)
	if pawn == nil then return end
	if pawn.bInCombatStance then
		isWeaponDrawn=true
	else isWeaponDrawn=false
	end
end
local function UpdateSprintStatus()

	if lShoulder and ThumbLY >=28000  then 
		isSprinting=true
	end
	if   ThumbLY<15000 then
			isSprinting=false
	end
	
end

--uevr.sdk.callbacks.on_xinput_get_state(
--function(retval, user_index, state)
--local dpawn=nil
--dpawn=api:get_local_pawn(0)
--
--
--	--UpdateDriveStatus(dpawn)
--	
--
--
----Read Gamepad stick input 
----if PhysicalDriving then
--	UpdateInput(state)
--
----end
--
--end)

uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
local dpawn=nil
dpawn=api:get_local_pawn(0)	
local Player=api:get_player_controller(0)	
--local PMesh=pawn.FirstPersonSkeletalMeshComponent
UpdateRidingStatus(dpawn)
UpdateMenuStatus(Player)
UpdateCombatStanceStatus(dpawn)	
UpdateBowStatus(dpawn)	
UpdateSprintStatus()
end)