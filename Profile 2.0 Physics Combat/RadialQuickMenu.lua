--require(".\\Trackers\\Trackers")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalDataCustom")
require(".\\Subsystems\\HelperFunctions")
require(".\\Subsystems\\ControlInput")
require(".\\Config\\CONFIG")
local api = uevr.api
local QuickMenuJustOpened=false
local QuickMenuOriginalPosition
local QuickMenuOriginalTransform
local QuickMenuSelectedSlot=0
local QuickMenuSimulatedStickX=0
local QuickMenuSimulatedStickY=0
local QuickMenuSloMoActive=false

local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

local kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")

local function CheckQuickSlotPosition(currentPos_World, originalMenuTransform_World, currentSelectedSlotForDeadzone)
    local inverseOriginalTransform = kismet_math_library:InvertTransform(originalMenuTransform_World)
    local controllerPos_Local = kismet_math_library:TransformLocation(inverseOriginalTransform, currentPos_World)

    local local_y_for_atan = controllerPos_Local.y
    local local_z_for_atan = controllerPos_Local.z

    local deadzoneRadiusSq = 0.03 * 0.03 -- 3cm squared, adjust as needed
    if (local_y_for_atan * local_y_for_atan + local_z_for_atan * local_z_for_atan) < deadzoneRadiusSq then
        return currentSelectedSlotForDeadzone -- Return current/last slot if in deadzone
    end

    local radians = math.atan(local_y_for_atan, local_z_for_atan) -- Angle relative to local +Z (up)
                                                                -- +Z (12 o'clock) -> 0 rad
                                                                -- +Y (3 o'clock)  -> PI/2 rad
    if radians < 0 then
        radians = radians + (2 * math.pi)
    end

    local arcSize = (2 * math.pi) / 8
    local rawIndex = radians / arcSize
    local index = math.floor(rawIndex + 0.5)
    local wrapped = index % 8
    
    -- For debugging:
    -- print(string.format("LocalY: %.2f, LocalZ: %.2f, Radians: %.2f, RawIndex: %.2f, Slot: %d", local_y_for_atan, local_z_for_atan, radians, rawIndex, wrapped + 1))

    return wrapped + 1
end

local function AngleToThumbstick(angleDeg, maxMag)
    maxMag = maxMag or 32767
    local rad = math.rad(angleDeg)
    local x = math.sin(rad) * maxMag
    local y = math.cos(rad) * maxMag
    return math.floor(x + 0.5), math.floor(y + 0.5)
end

local function SlotToThumbstick(slotIndex, maxMag)
    -- slotIndex is 1…8, where 1 is 0°, 2 is 45°, … 8 is 315°
    local centerAngle = (slotIndex - 1) * 45
    return AngleToThumbstick(centerAngle, maxMag)
end

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)
--In rare event radial quick menu option is changed midstream, reset state
if not RadialQuickMenu then
	QuickMenuJustOpened=false
	QuickMenuSelectedSlot=0
	QuickMenuSimulatedStickX=0
	QuickMenuSimulatedStickY=0
	if QuickMenuSloMoActive then
		QuickMenuSloMoActive=false
		local playerController = api:get_player_controller(0)
		if playerController ~= nil then
			local CheatManager = playerController.CheatManager
			if CheatManager ~= nil then
				CheatManager:Slomo(1.0)
			end
		end
	end
end

--If Quick menu is open and option for RadialQuickMenu is on, then activate slow motion, grab initial position of player's hand to compare to movement while menu open
if QuickMenu==true and RadialQuickMenu then
	if not QuickMenuJustOpened then
		QuickMenuJustOpened=true
		QuickMenuOriginalPosition=right_hand_component:K2_GetComponentLocation()
		QuickMenuOriginalTransform=right_hand_component:K2_GetComponentToWorld()
		local playerController = api:get_player_controller(0)
		if playerController ~= nil then
			local CheatManager = playerController.CheatManager

			if CheatManager ~= nil then
				CheatManager:Slomo(0.1)
				QuickMenuSloMoActive=true
			end
		end
	end
	local current_controller_position=right_hand_component:K2_GetComponentLocation()
    QuickMenuSelectedSlot = CheckQuickSlotPosition(current_controller_position, QuickMenuOriginalTransform, QuickMenuSelectedSlot)
	QuickMenuSimulatedStickX, QuickMenuSimulatedStickY = SlotToThumbstick(QuickMenuSelectedSlot)
else QuickMenuJustOpened=false
end
end)

uevr.sdk.callbacks.on_xinput_get_state(function(retval, user_index, state)

--If Quick menu no longer open, return time to normal scale
if QuickMenu==false and RadialQuickMenu then
	if QuickMenuSloMoActive then
		QuickMenuSloMoActive=false
		local playerController = api:get_player_controller(0)
		if playerController ~= nil then
			local CheatManager = playerController.CheatManager
			if CheatManager ~= nil then
				CheatManager:Slomo(1.0)
			end
		end
	end
end

--if QuickMenu==true and not isBow and uevr.params.vr:get_mod_value("UI_FollowView") then
--If not holding the bow and quickmenu is open, use hand motion to simulate right stick input to rotate the selector
if QuickMenu==true  and RadialQuickMenu then
	if state ~= nil then
		state.Gamepad.sThumbRX = QuickMenuSimulatedStickX
		state.Gamepad.sThumbRY = QuickMenuSimulatedStickY
	end
end

end)