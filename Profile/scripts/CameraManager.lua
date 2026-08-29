require(".\\Trackers\\Trackers") -- Includes the Trackers.lua script for hand and HMD tracking functionalities
require(".\\Subsystems\\UEHelper") -- Includes the UEHelper.lua script, likely containing utility functions for UEVR
require(".\\Config\\CONFIG") -- Includes the CONFIG.lua script, providing access to user-defined settings
require(".\\Subsystems\\ControlInput") -- Includes the ControlInput.lua script, managing gamepad input handling

local api = uevr.api -- UEVR API object
local params = uevr.params -- UEVR parameters object
local callbacks = params.sdk.callbacks -- UEVR SDK callbacks for event handling
local vr = uevr.params.vr -- UEVR VR-specific parameters and functions

-- Function to find a required UObject by name
local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("Cannot find " .. name) -- Throws an error if the object is not found
        return nil
    end
    return obj
end

-- Function to find a static class by name and get its default object
local find_static_class = function(name)
    local c = find_required_object(name) -- Find the UObject for the class
    return c:get_class_default_object() -- Get the class default object
end

-- isBow is a global variable. It is created and managed in Subsystems\UEHelper.lua
--   isBow is truthy if the player is wielding a bow.
-- isRiding is a global variable. It is created and managed in Subsystems\UEHelper.lua
--   isRiding is truthy if the player is riding a horse.
-- isMenu is a global variable. It is created and managed in Subsystems\UEHelper.lua
--   isMenu is truthy if the player is in the game menu.

local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult") -- UObject for HitResult struct
local reusable_hit_result1 = StructObject.new(hitresult_c) -- Reusable instance of HitResult

local CamAngle = RightRotator -- Initial camera angle, likely based on the right controller's rotation
local AttackDelta = 0 -- Timer for attack animation or state
local HandVector = Vector3f.new(0.0, 0.0, 0.0) -- Vector representing hand orientation
local HmdVector = Vector3f.new(0.0, 0.0, 0.0) -- Vector representing HMD orientation
local VecAlpha = Vector3f.new(0, 0, 0) -- Vector for angle calculation
local Alpha = nil -- Angle variable
local AlphaDiff -- Difference in angles
local LastState = isBow -- Stores the previous state of 'isBow'
local ConditionChagned = false -- Flag to indicate a change in bow condition
local isMenuEnter = false -- Flag to track menu entry
local YawLast = 0 -- Stores the last yaw value

local LeftRightScaleFactor = 0 -- Scaling factor for left/right movement
local ForwardBackwardScaleFactor = 0 -- Scaling factor for forward/backward movement
local IsRecentered = false -- Flag to check if view has been recentered

-- Callback function executed before each engine tick
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

    local pawn = api:get_local_pawn(0) -- Get the local player pawn

    -- Handle UI behavior when entering/exiting a menu
    if isMenu and isMenuEnter == false then
        uevr.params.vr.set_mod_value("UI_FollowView", "false") -- Disable UI following view
        isMenuEnter = true -- Set menu entry flag
        vr:recenter_view() -- Recenter the VR view
        local player = api:get_player_controller(0) -- Get the player controller
        player:ClientSetRotation(Vector3f.new(0, YawLast, 0), true) -- Set player rotation to last known yaw
    elseif not isMenu and isMenuEnter then
        isMenuEnter = false -- Reset menu entry flag
        if UIFollowsView then -- Check user setting for UI follow view
            uevr.params.vr.set_mod_value("UI_FollowView", "true") -- Enable UI following view
        else
            uevr.params.vr.set_mod_value("UI_FollowView", "false") -- Disable UI following view
        end
    end

    -- Store current HMD yaw when not in menu
    if not isMenu then
        YawLast = hmd_component:K2_GetComponentRotation().y
    end

    -- Handle movement based on riding status
    if not isRiding then
        
        uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "true") -- Enable roomscale movement

        if isBow then -- If a bow is equipped
            
            uevr.params.vr.set_mod_value("VR_MovementOrientation", "0") -- Set movement orientation to 0 (likely HMD-based)

            local pawn = api:get_local_pawn(0) -- Get local pawn
            local player = api:get_player_controller(0) -- Get player controller
            local CameraManager = player.PlayerCameraManager -- Get camera manager
            local CameraComp = CameraManager.ViewTarget.Target.CameraComponent -- Get camera component

            -- Adjust camera angle based on bow aiming and attack state
            if isBow and RTrigger ~= 0 then
                AttackDelta = 0 -- Reset attack delta
                CamAngle = Diff_Rotator_LR_Arrow -- Set camera angle to difference between left and right controller (for aiming)
            end
            if RTrigger == 0 and AttackDelta < 2 then
                AttackDelta = AttackDelta + delta -- Increment attack delta
            end
            if isBow and RTrigger == 0 and AttackDelta > 1 then
                CamAngle = RightRotator -- If bow not active and enough time passed, revert to right controller rotation
            elseif not isBow and AttackDelta > 1 then
                CamAngle = RightRotator -- If no bow and enough time passed, revert to right controller rotation
            elseif AttackDelta <= 1 then
                CamAngle = Diff_Rotator_LR_Arrow -- If attack delta is small, keep aiming angle
            end

            local CamPitch = -CamAngle.x -- Calculate camera pitch
            local CamYaw = CamAngle.y -- Calculate camera yaw

            if not isBow then -- If not using bow, adjust pitch and yaw
                CamYaw = CamAngle.y
                CamPitch = CamAngle.x
            end
            if isBow and RTrigger == 0 and AttackDelta > 1 then
                CamYaw = CamAngle.y
                CamPitch = CamAngle.x
            elseif isBow and AttackDelta <= 1 then
                CamPitch = CamAngle.x
                CamYaw = CamAngle.y
            end

            -- Set player rotation if not in quick menu
            if not QuickMenu then
                player:ClientSetRotation(Vector3f.new(CamPitch - 7, CamYaw + 2, 0), true)
            end

            -- Calculate vectors for HMD and hand 
            HmdVector = hmd_component:GetForwardVector()
            HandVector = right_hand_component:GetForwardVector()

            -- Calculate AlphaDiff (angle between hand and HMD forward vectors)
            -- This complex calculation determines the angle in 2D plane
            local VecAlphaX = HandVector.x - HmdVector.x
            local VecAlphaY = HandVector.y - HmdVector.y
            local Alpha1 -- Angle for HandVector
            local Alpha2 -- Angle for HmdVector


            -- Determine Alpha1 based on HandVector's quadrant
            if HandVector.x >= 0 and HandVector.y >= 0 then
                Alpha1 = math.pi / 2 - math.asin(HandVector.x / math.sqrt(HandVector.y^2 + HandVector.x^2))
            elseif HandVector.x < 0 and HandVector.y >= 0 then
                Alpha1 = math.pi / 2 - math.asin(HandVector.x / math.sqrt(HandVector.y^2 + HandVector.x^2))
            elseif HandVector.x < 0 and HandVector.y < 0 then
                Alpha1 = math.pi + math.pi / 2 + math.asin(HandVector.x / math.sqrt(HandVector.y^2 + HandVector.x^2))
            elseif HandVector.x >= 0 and HandVector.y < 0 then
                Alpha1 = 3 / 2 * math.pi + math.asin(HandVector.x / math.sqrt(HandVector.y^2 + HandVector.x^2))
            end

            -- Determine Alpha2 based on HmdVector's quadrant
            if HmdVector.x >= 0 and HmdVector.y >= 0 then
                Alpha2 = math.pi / 2 - math.asin(HmdVector.x / math.sqrt(HmdVector.y^2 + HmdVector.x^2))
            elseif HmdVector.x < 0 and HmdVector.y >= 0 then
                Alpha2 = math.pi / 2 - math.asin(HmdVector.x / math.sqrt(HmdVector.y^2 + HmdVector.x^2))
            elseif HmdVector.x < 0 and HmdVector.y < 0 then
                Alpha2 = math.pi + math.pi / 2 + math.asin(HmdVector.x / math.sqrt(HmdVector.y^2 + HmdVector.x^2))
            elseif HmdVector.x >= 0 and HmdVector.y < 0 then
                Alpha2 = 3 / 2 * math.pi + math.asin(HmdVector.x / math.sqrt(HmdVector.y^2 + HmdVector.x^2))
            end

            AlphaDiff = Alpha2 - Alpha1 -- Calculate the difference between the angles
            if isBow and RTrigger ~= 0 then
                AlphaDiff = AlphaDiff - math.pi * 20 / 180 -- Apply an offset when aiming with a bow
            end

        elseif HeadBasedMovementOrientation then -- If head-based movement is enabled
            uevr.params.vr.set_mod_value("VR_MovementOrientation", "1") -- Set movement orientation to 1 (likely Head)
        elseif not HeadBasedMovementOrientation then -- If head-based movement is disabled
            uevr.params.vr.set_mod_value("VR_MovementOrientation", "2") -- Set movement orientation to 2 (likely Controller)
        end

        -- Apply movement input if not sprinting
        if not isSprinting then
            LeftRightScaleFactor = ThumbLX / 32767 -- Scale factor for left/right movement based on thumbstick X
            ForwardBackwardScaleFactor = ThumbLY / 32767 -- Scale factor for forward/backward movement based on thumbstick Y

            if HeadBasedMovementOrientation then -- If movement is head-based
                pawn:AddMovementInput(hmd_component:GetForwardVector(), ForwardBackwardScaleFactor, true) -- Add forward/backward movement based on HMD
                pawn:AddMovementInput(hmd_component:GetRightVector(), LeftRightScaleFactor, true) -- Add left/right movement based on HMD
                uevr.params.vr.set_mod_value("VR_MovementOrientation", "0") -- Set movement orientation to 0
            else -- If movement is controller-based
                if config_table.Movement == 2 then
                    pawn:AddMovementInput(right_hand_component:GetForwardVector(), ForwardBackwardScaleFactor, true) -- Add forward/backward movement based on right hand
                    pawn:AddMovementInput(right_hand_component:GetRightVector(), LeftRightScaleFactor, true) -- Add left/right movement based on right hand
                    uevr.params.vr.set_mod_value("VR_MovementOrientation", "0") -- Set movement orientation to 0
                elseif config_table.Movement == 3 then
                    pawn:AddMovementInput(left_hand_component:GetForwardVector(), ForwardBackwardScaleFactor, true) -- Add forward/backward movement based on right hand
                    pawn:AddMovementInput(left_hand_component:GetRightVector(), LeftRightScaleFactor, true) -- Add left/right movement based on right hand
                    uevr.params.vr.set_mod_value("VR_MovementOrientation", "0") -- Set movement orientation to 0
                end
            end
        end
        IsRecentered = false -- Reset recenter flag
    else -- If riding
        uevr.params.vr.set_mod_value("VR_MovementOrientation", "0") -- Set movement orientation to 0
        if not IsRecentered then
            vr:recenter_view() -- Recenter view
            IsRecentered = true -- Set recenter flag
        end
        uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false") -- Disable roomscale movement
    end

    -- Check if bow state has changed
    if LastState == not isBow then
        LastState = isBow
        ConditionChagned = true
        print("ConditionChagned") -- Debug print
    end
end)

local DecoupledYawCurrentRot = 0 -- Current decoupled yaw rotation
local RXState = 0 -- State for right thumbstick X input
local SnapAngle -- Snap turn angle

-- Callback function for XInput get state event
uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
    if isBow then -- If bow is equipped
        
        -- Compensate for rotation based on hand/HMD alignment if head-based movement is enabled
        if HeadBasedMovement then
            state.Gamepad.sThumbLX = ThumbLX * math.cos(-AlphaDiff) - ThumbLY * math.sin(-AlphaDiff)
            state.Gamepad.sThumbLY = math.sin(-AlphaDiff) * ThumbLX + ThumbLY * math.cos(-AlphaDiff)
        end

        SnapAngle = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle")) -- Get snap turn angle from UEVR settings
        if SnapTurn then -- If snap turn is enabled
            if ThumbRX > 200 and RXState == 0 and not isMenu then
                DecoupledYawCurrentRot = DecoupledYawCurrentRot + SnapAngle -- Apply positive snap turn
                RXState = 1 -- Set RXState to prevent repeated turns
            elseif ThumbRX < -200 and RXState == 0 and not isMenu then
                DecoupledYawCurrentRot = DecoupledYawCurrentRot - SnapAngle -- Apply negative snap turn
                RXState = 1 -- Set RXState to prevent repeated turns
            elseif ThumbRX <= 200 and ThumbRX >= -200 then
                RXState = 0 -- Reset RXState when thumbstick is neutral
            end
        else -- If smooth turn is enabled
            SmoothTurnRate = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle")) / 90 -- Calculate smooth turn rate

            local rate = state.Gamepad.sThumbRX / 32767 -- Get raw thumbstick X input
            rate = rate * rate * rate -- Apply cubic scaling to rate for smoother acceleration

            if ThumbRX > 2200 and not isMenu then
                DecoupledYawCurrentRot = DecoupledYawCurrentRot + SmoothTurnRate * rate -- Apply positive smooth turn
            elseif ThumbRX < -2200 and not isMenu then
                DecoupledYawCurrentRot = DecoupledYawCurrentRot + SmoothTurnRate * rate -- Apply negative smooth turn
            end
        end
    end
end)

local PreRot -- Stores rotation before offset calculation
local DiffRot -- Stores difference in rotation
local DecoupledYawCurrentRotLast = 0 -- Stores last decoupled yaw rotation

-- Callback function for early stereo view offset calculation
uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(
function(device, view_index, world_to_meters, position, rotation, is_double)
    PreRot = rotation.y -- Store initial yaw rotation
    DiffRot = HmdRotator.y - RightRotator.y -- Calculate difference between HMD and right controller yaw

    if isBow then -- If bow is equipped
        rotation.y = DecoupledYawCurrentRot -- Apply decoupled yaw rotation

        if ConditionChagned then -- If bow condition changed
            ConditionChagned = false -- Reset flag
            -- vr.recenter_view() -- commented out: Recenter view
            -- rotation.y=DecoupledYawCurrentRotLast -- commented out: apply last decoupled yaw
        end
    else -- If bow is not equipped
        if ConditionChagned then -- If bow condition changed
            local player = api:get_player_controller(0)
            player:ClientSetRotation(Vector3f.new(HmdRotator.x, DecoupledYawCurrentRotLast, 0), true) -- Set player rotation based on HMD and last decoupled yaw
            ConditionChagned = false -- Reset flag
            vr.recenter_view() -- Recenter view
        end
        DecoupledYawCurrentRot = HmdRotator.y - DiffRot -- Update decoupled yaw based on HMD and right controller difference
    end

end)

-- Callback function for post stereo view offset calculation
uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(
function(device, view_index, world_to_meters, position, rotation, is_double)
    local pawn = api:get_local_pawn(0) -- Get local pawn

    -- Adjust camera position for first-person horse riding
    if isRiding and FirstPersonRiding then
        -- pawn.Rider.Mesh:SetVisibility(false,true) -- commented out: hide rider mesh
        NewLoc = pawn.Rider.MainSkeletalMeshComponent:GetSocketLocation("Head_Socket") -- Get head socket location
        position.x = NewLoc.x + pawn.Mesh:GetRightVector().x * 10 -- Adjust X position
        position.y = NewLoc.y + pawn.Mesh:GetRightVector().y * 10 -- Adjust Y position
        position.z = NewLoc.z + 10 -- Adjust Z position
    else
        -- pawn.Mesh:SetVisibility(false,true) -- commented out: hide pawn mesh
    end

    -- Store last decoupled yaw rotation if bow is equipped
    if isBow then
        DecoupledYawCurrentRotLast = rotation.y
    end
end)