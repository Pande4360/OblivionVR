-- HolsterScript.lua: Manages VR holster interactions, input remapping, and UI toggling.
-- This script relies on other UEVR Lua modules for core functionalities.

-- Region: Module Imports
--------------------------------------------------------------------------------
-- Imports tracking-related functions and HMD/hand component management.
-- This module is expected to define 'TrackersInit' and 'right_hand_component',
-- 'left_hand_component', 'hmd_component'.
require(".\\Trackers\\Trackers")
-- Imports configuration settings from CONFIG.lua.
-- This module is expected to define 'configInit', 'SitMode', 'isRhand',
-- 'isLeftHandModeTriggerSwitchOnly', 'HapticFeedback', etc.
require(".\\Config\\CONFIG")
-- Imports utility functions for Unreal Engine object manipulation and input handling.
-- This module is expected to define global XInput button constants (e.g., XINPUT_GAMEPAD_A),
-- and potentially influence 'inMenu', 'ThumbLX', 'LTrigger', etc.
require(".\\Subsystems\\UEHelper")
-- Imports definitions of spatial zones used for holster and interaction areas.
-- This module is expected to define zone tables like 'RHZoneRSh', 'LHZoneHead', etc.
require(".\\libs\\zones")
-- Imports control input processing and quick menu management.
-- This module also has its own 'on_xinput_get_state' callback and might manage
-- global input variables used here.
require(".\\Subsystems\\ControlInput")
-- Imports general UEVR utility functions. 'utils' provides functions like 'uevr.params.vr.get_mod_value'.
local utils = require(".\\libs\\uevr_utils")
--------------------------------------------------------------------------------
-- EndRegion: Module Imports


-- Region: Initialization and Global Variables
--------------------------------------------------------------------------------
HolsterInit = true -- Flag to indicate if HolsterScript has been initialized.

-- Confirm if required modules were loaded.
if TrackersInit and configInit then
    print("HolsterScript.lua: Trackers loaded")
    print("HolsterScript.lua: Config Loaded")
end

-- Seated mode offset for adjusting holster positions if SitMode is enabled in CONFIG.lua.
local SeatedOffset = 0
if SitMode then
    SeatedOffset = 20
end

-- UEVR API and parameter access.
local api = uevr.api
local params = uevr.params
local callbacks = params.sdk.callbacks
local pawn = api:get_local_pawn(0) -- Reference to the local player's pawn.
-- local vr = uevr.params.vr -- Commented out, but 'uevr.params.vr' is directly used later.

-- Standard controller indices for UEVR.
local lControllerIndex = 1
local rControllerIndex = 2

-- Global variables for tracking input states, holster zones, and action flags.
local rGrabActive = false -- True if the right controller's grab button (RShoulder) is held.
local lGrabActive = false -- True if the left controller's grab button (LShoulder) is held.
local LZone = 0 -- Current active Left Hand Zone ID (0 if not in any zone).
local RZone = 0 -- Current active Right Hand Zone ID (0 if not in any zone).
local LWeaponZone = 0 -- Current active Left Hand Weapon Interaction Zone ID.
local RWeaponZone = 0 -- Current active Right Hand Weapon Interaction Zone ID.

-- Thumbstick switch states for single press detection (debouncing).
local lThumbSwitchState = 0 -- State for left thumbstick button.
local lThumbOut = false     -- True if left thumbstick was just pressed (single-press detection).
local rThumbSwitchState = 0 -- State for right thumbstick button.
local rThumbOut = false     -- True if right thumbstick was just pressed (single-press detection).

local isReloading = false -- Flag to trigger a reload action.
local ReadyUpTick = 0     -- Unused, possibly for a "ready player" mechanic.
local inMenu = false      -- Flag to check if a game menu is active (managed by UEHelper).

-- Debounce variables for controller triggers and buttons.
local LTriggerWasPressed = 0 -- State for Left Trigger debouncing.
local RTriggerWasPressed = 0 -- State for Right Trigger debouncing.
local isFlashlightToggle = false -- Unused.
local isButtonA = false -- Flag for XInput A button press.
local isButtonB = false -- Flag for XInput B button press.
local isButtonX = false -- Flag for XInput X button press.
local isButtonY = false -- Flag for XInput Y button press.
local isRShoulder = false -- Flag for Right Shoulder button (remapped).
local isCrouch = false    -- Flag for crouch state.
local StanceButton = false -- Unused.
local isJournal = 0       -- Unused.
local GrenadeReady = false -- Flag to indicate if grenade is ready to be thrown.

-- Flags for keyboard key presses (triggered by VR interactions).
local KeyG = false    -- Flag for 'G' key press.
local KeyM = false    -- Flag for 'M' key press.
local KeyF = false    -- Unused.
local KeyB = false    -- Flag for 'B' key press.
local KeyI = false    -- Flag for 'I' key press.
local KeySpace = false -- Flag for 'Spacebar' key press.
local KeyCtrl = false -- Flag for 'Left Control' key press.

local vecy = 0 -- Vertical component of joystick input.
local isJump = false -- Flag for jump state.
local isInventoryPDA = false -- Unused.
local LastWorldTime = 0.000 -- Unused.
local WorldTime = 0.000     -- Unused.

-- Flags for Right Shoulder button interactions when hand is over head.
local isRShoulderHeadR = false -- Right shoulder button pressed with Right Hand over head.
local isRShoulderHeadL = false -- Right shoulder button pressed with Left Hand over head.

-- Previous zone states for debouncing and detecting zone entry/exit.
local RZoneLast = RZone         -- Previous Right Hand Zone.
local rGrabStart = false        -- True when right grab starts.
local LZoneLast = LZone         -- Previous Left Hand Zone.
local lGrabStart = false        -- True when left grab starts.
local RWeaponZoneLast = 0       -- Previous Right Hand Weapon Zone.

-- Quick menu state flags (managed by ControlInput.lua, but also used here).
local Quick1 = false
local Quick2 = false
local Quick3 = false
local Quick4 = false
local Quick5 = false
local Quick6 = false
local Quick7 = false
local Quick8 = false
local Quick9 = false

local GUIState = true -- Current visibility state of the game UI (true = visible).
local isToggled = false -- Flag to prevent rapid UI toggling from a single input.
--------------------------------------------------------------------------------
-- EndRegion: Initialization and Global Variables


-- Region: Helper Functions
--------------------------------------------------------------------------------
-- This function is present in HolsterScript.lua but is also defined in UEHelper.lua and Trackers.lua.
-- It's not explicitly called within this script's active logic.
-- Finds a required Unreal Engine object by its full name.
-- Throws an error if the object is not found.
local function find_required_object(name)
    local obj = uevr.api:find_uobject(name)
    if not obj then
        error("HolsterScript.lua: Cannot find " .. name)
        return nil
    end
    return obj
end

-- This function is present in HolsterScript.lua but is also defined in UEHelper.lua and Trackers.lua.
-- It's not explicitly called within this script's active logic.
-- Finds the class default object for a given Unreal Engine class name.
local find_static_class = function(name)
    local c = find_required_object(name)
    return c:get_class_default_object()
end

-- Checks if a specific button is pressed on the gamepad state.
-- This function is also defined in UEHelper.lua.
function isButtonPressed(state, button)
    return state.Gamepad.wButtons & button ~= 0
end

-- Checks if a specific button is NOT pressed on the gamepad state.
-- This function is also defined in UEHelper.lua.
function isButtonNotPressed(state, button)
    return state.Gamepad.wButtons & button == 0
end

-- Presses a virtual button on the gamepad state by setting its bit.
-- This function is also defined in UEHelper.lua.
function pressButton(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons | button
end

-- Unpresses a virtual button on the gamepad state by clearing its bit.
-- This function is also defined in UEHelper.lua.
function unpressButton(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end

-- Sends a key press event to the game using UEVR's custom event dispatch.
-- `key_value` can be a single character string or a virtual key code (e.g., '0x20' for space).
-- `key_up` (boolean): true for key release, false for key press.
local function SendKeyPress(key_value, key_up)
    local key_up_string = "down"
    if key_up == true then
        key_up_string = "up"
    end
    api:dispatch_custom_event(key_value, key_up_string)
end

-- Convenience function to send a key down event.
local function SendKeyDown(key_value)
    SendKeyPress(key_value, false)
end

-- Convenience function to send a key up event.
local function SendKeyUp(key_value)
    SendKeyPress(key_value, true)
end

-- Toggles the visibility of specific UI elements in the game.
-- It retrieves instances of UMG widgets by their blueprint class paths and sets their visibility.
local function ToggleUI()
    if not isToggled then -- Debounce: only allow toggling once per "press" cycle.
        isToggled = true

        -- Retrieve UI widget blueprint classes.
        local CompassClass = uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/Compass/WBP_ModernHud_Compass.WBP_ModernHud_Compass_C")
        local HealthClass = uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_Health.WBP_ModernHud_Health_C")
        local StaminaClass = uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_Fatigue.WBP_ModernHud_Fatigue_C")
        local MagicClass = uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_MagicIcon.WBP_ModernHud_MagicIcon_C")
        local WeaponClass = uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/WBP_ModernHud_WeaponIcon.WBP_ModernHud_WeaponIcon_C")

        -- Get active instances of the UI components. UEVR_UObjectHook.get_objects_by_class
        -- returns a table of objects, usually the first element [1] or [2] is the active one.
        local CompassComponent = UEVR_UObjectHook.get_objects_by_class(CompassClass, false)
        local HealthCOmponent = UEVR_UObjectHook.get_objects_by_class(HealthClass, false)
        local StaminaComponent = UEVR_UObjectHook.get_objects_by_class(StaminaClass, false)
        local MagicComponent = UEVR_UObjectHook.get_objects_by_class(MagicClass, false)
        local WeaponComponent = UEVR_UObjectHook.get_objects_by_class(WeaponClass, false)

        -- Toggle visibility based on the current GUIState.
        -- SetVisibility(0) = Visible, SetVisibility(1) = Collapsed (Hidden, occupies no space).
        -- There might be a typo in the original script where `SetVisibility(1)` was used for hiding.
        if GUIState then -- If UI is currently visible (GUIState is true), hide it.
            if CompassComponent and CompassComponent[2] then CompassComponent[2]:SetVisibility(1) end
            -- if HealthCOmponent and HealthCOmponent[2] then HealthCOmponent[2]:SetVisibility(1) end -- Commented out in original
            -- if StaminaComponent and StaminaComponent[3] then StaminaComponent[3]:SetVisibility(1) end -- Commented out in original
            if MagicComponent and MagicComponent[2] then MagicComponent[2]:SetVisibility(1) end
            if WeaponComponent and WeaponComponent[2] then WeaponComponent[2]:SetVisibility(1) end
        else -- If UI is currently hidden (GUIState is false), show it.
            if CompassComponent and CompassComponent[2] then CompassComponent[2]:SetVisibility(0) end
            if MagicComponent and MagicComponent[2] then MagicComponent[2]:SetVisibility(0) end
            -- if HealthCOmponent and HealthCOmponent[2] then HealthCOmponent[2]:SetVisibility(0) end -- Commented out in original
            -- if StaminaComponent and StaminaComponent[3] then StaminaComponent[3]:SetVisibility(0) end -- Commented out in original
            if WeaponComponent and WeaponComponent[2] then WeaponComponent[2]:SetVisibility(0) end
        end
        GUIState = not GUIState -- Invert the state for the next call.
        -- print("HolsterScript.lua: "..HealthCOmponent[2]:get_full_name()) -- Debug print.
    end
end
--------------------------------------------------------------------------------
-- EndRegion: Helper Functions


-- Region: XInput Callback
--------------------------------------------------------------------------------
-- This callback is triggered by UEVR's SDK whenever XInput (gamepad) state is updated.
-- It allows modification of the gamepad state before it's sent to the game.
uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)

	-- Do nothing if Holster is disabled in the UEVR settings UI
	if not EnableHolster then return end

    -- Read Gamepad stick and trigger input values.
    -- These variables (ThumbLX, LTrigger, etc.) are expected to be set by UEHelper's
    -- on_xinput_get_state callback, which is likely called before this script's callback.
    -- ThumbLX = state.Gamepad.sThumbLX
    -- ThumbLY = state.Gamepad.sThumbLY
    -- ThumbRX = state.Gamepad.sThumbRX
    -- ThumbRY = state.Gamepad.sThumbRY
    -- LTrigger= state.Gamepad.bLeftTrigger
    -- RTrigger= state.Gamepad.bRightTrigger
    -- rShoulder= isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
    -- lShoulder= isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
    -- lThumb   = isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB)
    -- rThumb   = isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB)
    -- Abutton  = isButtonPressed(state, XINPUT_GAMEPAD_A)
    -- Bbutton  = isButtonPressed(state, XINPUT_GAMEPAD_B)
    -- Xbutton  = isButtonPressed(state, XINPUT_GAMEPAD_X)
    -- Ybutton  = isButtonPressed(state, XINPUT_GAMEPAD_Y)

    -- Only apply custom control logic if not in a game menu (inMenu is controlled by UEHelper).
    if isMenu == false then
        -- Debounce for trigger presses in weapon zones.
        if LTrigger < 10 then
            LTriggerWasPressed = 0
        end
        if RTrigger < 10 then
            RTriggerWasPressed = 0
        end

        -- DISABLE DPAD
        -- if isRhand then
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_UP)
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_RIGHT)
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_LEFT)
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_DOWN)
        -- else
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_UP)
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_RIGHT)
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_LEFT)
        --     unpressButton(state,XINPUT_GAMEPAD_DPAD_DOWN)
        -- end

        -- Disable Buttons
        -- if isRhand or isLeftHandModeTriggerSwitchOnly then
        --     unpressButton(state,XINPUT_GAMEPAD_A)
        --     unpressButton(state,XINPUT_GAMEPAD_B)
        --     unpressButton(state,XINPUT_GAMEPAD_X)
        --     unpressButton(state,XINPUT_GAMEPAD_Y)
        -- end
        -- if lThumb and SwapLShoulderLThumb then
        --     unpressButton(state,XINPUT_GAMEPAD_LEFT_THUMB)
        -- end

        -- Left Handed Mode Configuration: Remaps controls for left-handed players.
        -- 'isRhand' and 'isLeftHandModeTriggerSwitchOnly' are configured in CONFIG.lua.
        if not isRhand then
            -- Swap triggers.
            state.Gamepad.bLeftTrigger = RTrigger
            state.Gamepad.bRightTrigger = LTrigger

            if not isLeftHandModeTriggerSwitchOnly then
                -- Swap thumbstick axes.
                state.Gamepad.sThumbRX = ThumbLX
                state.Gamepad.sThumbRY = ThumbLY
                state.Gamepad.sThumbLX = ThumbRX
                state.Gamepad.sThumbLY = ThumbRY
                state.Gamepad.bLeftTrigger = RTrigger
                state.Gamepad.bRightTrigger = LTrigger

                -- Unpress standard gamepad buttons to prepare for remapping.
                unpressButton(state, XINPUT_GAMEPAD_B)
                unpressButton(state, XINPUT_GAMEPAD_A)
                unpressButton(state, XINPUT_GAMEPAD_X)
                unpressButton(state, XINPUT_GAMEPAD_Y)
                -- unpressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT)
                -- unpressButton(state, XINPUT_GAMEPAD_DPAD_LEFT)
                -- unpressButton(state, XINPUT_GAMEPAD_DPAD_UP)
                -- unpressButton(state, XINPUT_GAMEPAD_DPAD_DOWN)
                -- unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
                unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
                unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
                unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)

                -- Remap face buttons (Y<->X, B<->A).
                if Ybutton then pressButton(state, XINPUT_GAMEPAD_X) end
                if Bbutton then pressButton(state, XINPUT_GAMEPAD_A) end
                if Xbutton then pressButton(state, XINPUT_GAMEPAD_Y) end
                if Abutton then pressButton(state, XINPUT_GAMEPAD_B) end

                -- Remap shoulder and thumb buttons.
                if lShoulder then pressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER) end
                if rShoulder then pressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER) end
                if lThumb then pressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB) end
                if rThumb then pressButton(state, XINPUT_GAMEPAD_LEFT_THUMB) end
            end
        end

        -- Press DPad buttons if corresponding flags are set (flags are set in on_pre_engine_tick).
        if isDpadUp then pressButton(state, XINPUT_GAMEPAD_DPAD_UP); isDpadUp = false end
        if isDpadRight then pressButton(state, XINPUT_GAMEPAD_DPAD_RIGHT); isDpadRight = false end
        if isDpadLeft then pressButton(state, XINPUT_GAMEPAD_DPAD_LEFT); isDpadLeft = false end
        if isDpadDown then pressButton(state, XINPUT_GAMEPAD_DPAD_DOWN); isDpadDown = false end

        -- Press Face buttons if corresponding flags are set (flags are set in on_pre_engine_tick).
        if isButtonX then pressButton(state, XINPUT_GAMEPAD_X); isButtonX = false end
        if isButtonB then pressButton(state, XINPUT_GAMEPAD_B); isButtonB = false end
        if isButtonA then pressButton(state, XINPUT_GAMEPAD_A); isButtonA = false end
        if isButtonY then pressButton(state, XINPUT_GAMEPAD_Y); isButtonY = false end

        -- Prevent conflicting inputs when in an active holster zone.
        -- This unpresses certain buttons if a hand is in a holster zone,
        -- ensuring the game doesn't receive unwanted inputs while interacting with holsters.
        if isRhand or isLeftHandModeTriggerSwitchOnly then -- Right-handed or trigger-only switch mode.
            if RZone ~= 0 then -- If Right Hand is in a holster zone.
                unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
                unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
                -- unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB) -- This was commented out in original.
                unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
            end
        else -- Left-handed mode.
            if LZone ~= 0 then -- If Left Hand is in a holster zone.
                unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
                unpressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
                unpressButton(state, XINPUT_GAMEPAD_LEFT_THUMB)
                -- unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB) -- This was commented out in original.
            end
        end

        -- Debug print.
        -- print("HolsterScript.lua: "..RWeaponZone .. "   " .. RZone)

        -- Disable Left Trigger if Right Hand is in Weapon Zone 2 (e.g., for fire mode switch).
        if RWeaponZone == 2 then
            state.Gamepad.bLeftTrigger = 0
        end

        -- Disable Right Thumb button if Left Hand is in Weapon Zone 3 (e.g., for flashlight).
        if LWeaponZone == 3 then
            unpressButton(state, XINPUT_GAMEPAD_RIGHT_THUMB)
        end

        -- Attachment single press fix: Debouncing for thumbstick button presses.
        -- Ensures that `lThumbOut`/`rThumbOut` is true only for a single tick after press.
        if lThumb and lThumbSwitchState == 0 then
            lThumbOut = true
            lThumbSwitchState = 1
        elseif lThumb and lThumbSwitchState == 1 then
            lThumbOut = false
        elseif not lThumb and lThumbSwitchState == 1 then
            lThumbOut = false
            lThumbSwitchState = 0
            isRShoulder = false -- Resets 'isRShoulder' when thumbstick is released.
        end

        if rThumb and rThumbSwitchState == 0 then
            rThumbOut = true
            rThumbSwitchState = 1
        elseif rThumb and rThumbSwitchState == 1 then
            rThumbOut = false
        elseif not rThumb then
            rThumbOut = false
            rThumbSwitchState = 0
            isRShoulder = false -- Resets 'isRShoulder' when thumbstick is released.
        end

        -- Manage Right Shoulder button press for head-related interactions.
        -- This allows the RShoulder button to be passed through to the game
        -- if the hand is in a specific overhead zone AND a grab is active.
        if isRShoulderHeadR == true then
            pressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
            if rGrabActive == false then -- Release the button if grab ends.
                isRShoulderHeadR = false
            end
        end
        if isRShoulderHeadL == true then
            pressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
            if lGrabActive == false then -- Release the button if grab ends.
                isRShoulderHeadL = false
            end
        end
        -- print("HolsterScript.lua: "..rThumbOut) -- Debug print.

        -- Trigger reload action if 'isReloading' flag is true.
        if isReloading then
            pressButton(state, XINPUT_GAMEPAD_X)
            isReloading = false
        end

        -- Ready Up (commented out, likely an unfinished or disabled feature).
        -- if lGrabActive and rGrabActive then ... end

        -- Grab Activation Logic: Detects when shoulder buttons are held or released.
        -- Sets 'rGrabActive'/'lGrabActive' and manages 'rGrabStart'/'lGrabStart' for debouncing.
        if rShoulder then
            rGrabActive = true
            if rGrabStart == false then
                RZoneLast = RZone -- Store the zone at the start of the grab.
                rGrabStart = true
            end
        else
            rGrabActive = false
            rGrabStart = false
        end

        if lShoulder then
            lGrabActive = true
            if lGrabStart == false then
                LZoneLast = LZone           -- Store the LZone at the start of the grab.
                RWeaponZoneLast = RWeaponZone -- Store the RWeaponZone at the start of the grab.
                lGrabStart = true
            end
            -- unpressButton(state, XINPUT_GAMEPAD_LEFT_SHOULDER) -- This was commented out in original.
        else
            lGrabActive = false
            lGrabStart = false
        end

        -- Reset UI toggle state if both shoulder buttons are released.
        -- This prevents unintended rapid toggling if the user holds a grab button.
        if not lShoulder and not rShoulder then
            isToggled = false
        end

        pawn = api:get_local_pawn(0) -- Refresh local pawn reference (might be redundant if already up-to-date).

        -- Control edits: Handling key releases for quick slots and other actions.
        -- These `SendKeyUp` calls ensure that simulated key presses are released.
        -- The associated `KeyX = false` flags reset their state for the next press.
        if Key1 and not rGrabActive then SendKeyUp('1'); Key1 = false end
        if Key2 and not rGrabActive then SendKeyUp('2'); Key2 = false end
        if Key3 and not rGrabActive then SendKeyUp('3'); Key3 = false end
        if Key4 and not rGrabActive then SendKeyUp('4'); Key4 = false end
        if Key5 and not rGrabActive then SendKeyUp('5'); Key5 = false end
        if Key6 and not rGrabActive then SendKeyUp('6'); Key6 = false end
        if Key7 and not rGrabActive then SendKeyUp('7'); Key7 = false end
        if KeyM and not rGrabActive then SendKeyUp('M'); KeyM = false end
        if KeyI == true then SendKeyUp('I'); KeyI = false end
        if KeyB then SendKeyUp('B'); KeyB = false end
        if KeyCtrl then SendKeyUp('0xA2'); KeyCtrl = false end -- 0xA2 is virtual key code for Left Control
        if KeySpace then SendKeyUp('0x20'); KeySpace = false end -- 0x20 is virtual key code for Spacebar

        -- Jump and Crouch logic based on vertical joystick input (`vecy`).
        -- 'vecy' is determined in the 'on_pre_engine_tick' callback.
        if math.abs(vecy) < 0.1 and isJump == true then
            isJump = false
        end
        if math.abs(vecy) < 0.1 and isCrouch == true then
            isCrouch = false
        end
        if vecy > 0.8 and isJump == false then -- If joystick pushed up beyond threshold and not already jumping.
            KeySpace = true
            SendKeyDown('0x20')
            isJump = true
        end
        if vecy < -0.8 and isCrouch == false then -- If joystick pushed down beyond threshold and not already crouching.
            KeyCtrl = true
            SendKeyDown('0xA2')
            isCrouch = true
        end

        -- Grenade ready state and input.
        -- If 'GrenadeReady' is true and right grab is released, send 'G' key.
        if GrenadeReady then
            if rGrabActive == false then
                SendKeyDown('G')
                GrenadeReady = false
                KeyG = true -- Set KeyG true to allow 'SendKeyUp' in the next tick if needed.
            end
        end

        -- Manage Right Shoulder button (likely a passthrough or conditional press).
        -- If 'isRShoulder' is true, ensure the Right Shoulder button is pressed.
        if isRShoulder then
            -- unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER) -- This was commented out in original.
            pressButton(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
        end
    end
end)
--------------------------------------------------------------------------------
-- EndRegion: XInput Callback


-- Region: Pre-Engine Tick Callback
--------------------------------------------------------------------------------
-- Variables for hand and HMD locations (initialized to zero vectors).
local RHandLocation = Vector3f.new(0, 0, 0)
local LHandLocation = Vector3f.new(0, 0, 0)
local HmdLocation = Vector3f.new(0, 0, 0)

-- Haptic zone flags: True if a hand is currently within a haptic feedback zone.
local isHapticZoneR = false   -- Right Hand general zone.
local isHapticZoneL = false   -- Left Hand general zone.
local isHapticZoneWR = false  -- Right Hand weapon zone.
local isHapticZoneWL = false  -- Left Hand weapon zone.

-- Last state of haptic zones for debouncing haptic feedback.
local isHapticZoneRLast = false
local isHapticZoneLLast = false
local isHapticZoneWRLast = false
local isHapticZoneWLLast = false

-- Controller source references for joystick axis and haptic feedback.
local LeftController = uevr.params.vr.get_left_joystick_source()
local RightController = uevr.params.vr.get_right_joystick_source()
local RightJoystickIndex = uevr.params.vr.get_right_joystick_source() -- Redundant, same as RightController.
local RAxis = UEVR_Vector2f.new() -- Temporary vector for storing joystick axis input.
params.vr.get_joystick_axis(RightJoystickIndex, RAxis) -- Populate RAxis initially (might be done in first tick).

local leanState = 0 -- Unused; 1 = left, 2 = right (commented out leaning logic).

-- This callback is executed by UEVR's SDK before each engine tick.
-- It's used for continuous updates, position tracking, and complex logic.
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

	-- Holster is not checked in the UEVR UI
	if not EnableHolster then
		
		-- If holster haptic feedback is enabled, disable it.
		if HolsterHapticFeedback then
			HolsterHapticFeedback = false
			config_table.Holster_Haptic_Feedback = false
		end

		-- Holster is unchecked in the UEVR menu, so do no further logic.
		return
	end

    pawn = api:get_local_pawn(0) -- Re-obtain local player pawn.
    player = api:get_player_controller(0) -- Re-obtain player controller.

    -- Determine vertical joystick input ('vecy') based on handedness preference.
    -- 'isRhand' and 'isLeftHandModeTriggerSwitchOnly' are from CONFIG.lua.
    if isRhand or isLeftHandModeTriggerSwitchOnly then
        params.vr.get_joystick_axis(RightJoystickIndex, RAxis)
        vecy = RAxis.y
    else
        params.vr.get_joystick_axis(LeftController, RAxis)
        vecy = RAxis.y
    end
    -- print("HolsterScript.lua: vecyy" .. vecy) -- Debug print.

    -- Get current world locations and rotations of the HMD and tracked controllers.
    -- `right_hand_component`, `left_hand_component`, and `hmd_component` are expected
    -- to be global variables populated by Trackers.lua.
    RHandLocation = right_hand_component:K2_GetComponentLocation()
    LHandLocation = left_hand_component:K2_GetComponentLocation()
    HmdLocation = hmd_component:K2_GetComponentLocation()

    local HmdRotation = hmd_component:K2_GetComponentRotation()
    local RHandRotation = right_hand_component:K2_GetComponentRotation()
    local LHandRotation = left_hand_component:K2_GetComponentRotation()

    -- 'inMenu' flag (managed by UEHelper) indicates if a game menu is open.
    -- print("HolsterScript.lua: "..inMenu) -- Debug print.

    -- LEANING (commented out section, suggesting this feature is disabled or under development).
    -- if PhysicalLeaning then ... end

    -- Coordinate Transformations: Transform hand locations relative to the HMD.
    -- This normalizes hand positions to be relative to the player's forward direction,
    -- effectively rotating the coordinates around the HMD's yaw.
    local RotDiff = HmdRotation.y -- Yaw rotation of HMD in degrees.

    -- Left Hand relative to HMD.
    local LHandNewX = (LHandLocation.x - HmdLocation.x) * math.cos(-RotDiff / 180 * math.pi) - (LHandLocation.y - HmdLocation.y) * math.sin(-RotDiff / 180 * math.pi)
    local LHandNewY = (LHandLocation.x - HmdLocation.x) * math.sin(-RotDiff / 180 * math.pi) + (LHandLocation.y - HmdLocation.y) * math.cos(-RotDiff / 180 * math.pi)
    local LHandNewZ = LHandLocation.z - HmdLocation.z

    -- Right Hand relative to HMD.
    local RHandNewX = (RHandLocation.x - HmdLocation.x) * math.cos(-RotDiff / 180 * math.pi) - (RHandLocation.y - HmdLocation.y) * math.sin(-RotDiff / 180 * math.pi)
    local RHandNewY = (RHandLocation.x - HmdLocation.x) * math.sin(-RotDiff / 180 * math.pi) + (RHandLocation.y - HmdLocation.y) * math.cos(-RotDiff / 180 * math.pi)
    local RHandNewZ = RHandLocation.z - HmdLocation.z

    -- Transformations for Right-Handed Weapon: Transform Left Hand location relative to Right Hand's weapon orientation.
    -- This is crucial for two-handed weapon interactions like reloading or foregripping.
    local RotWeaponZ = RHandRotation.y -- Yaw of Right Hand.
    local LHandWeaponX = (LHandLocation.x - RHandLocation.x) * math.cos(-RotWeaponZ / 180 * math.pi) - (LHandLocation.y - RHandLocation.y) * math.sin(-RotWeaponZ / 180 * math.pi)
    local LHandWeaponY = (LHandLocation.x - RHandLocation.x) * math.sin(-RotWeaponZ / 180 * math.pi) + (LHandLocation.y - RHandLocation.y) * math.cos(-RotWeaponZ / 180 * math.pi)
    local LHandWeaponZ = (LHandLocation.z - RHandLocation.z)

    -- Apply Right Hand's Roll (X-axis rotation) to the relative Left Hand coordinates.
    local RotWeaponX = RHandRotation.z
    LHandWeaponY = LHandWeaponY * math.cos(RotWeaponX / 180 * math.pi) - LHandWeaponZ * math.sin(RotWeaponX / 180 * math.pi)
    LHandWeaponZ = LHandWeaponY * math.sin(RotWeaponX / 180 * math.pi) + LHandWeaponZ * math.cos(RotWeaponX / 180 * math.pi)

    -- Apply Right Hand's Pitch (Y-axis rotation) to the relative Left Hand coordinates.
    local RotWeaponY = RHandRotation.x
    LHandWeaponX = LHandWeaponX * math.cos(-RotWeaponY / 180 * math.pi) - LHandWeaponZ * math.sin(-RotWeaponY / 180 * math.pi)
    LHandWeaponZ = LHandWeaponX * math.sin(-RotWeaponY / 180 * math.pi) + LHandWeaponZ * math.cos(-RotWeaponY / 180 * math.pi)

    -- Transformations for Left-Handed Weapon: Transform Right Hand location relative to Left Hand's weapon orientation.
    -- This is for left-handed players using two-handed weapons.
    local RotWeaponLZ = LHandRotation.y
    local RHandWeaponX = (RHandLocation.x - LHandLocation.x) * math.cos(-RotWeaponLZ / 180 * math.pi) - (RHandLocation.y - LHandLocation.y) * math.sin(-RotWeaponLZ / 180 * math.pi)
    local RHandWeaponY = (RHandLocation.x - LHandLocation.x) * math.sin(-RotWeaponLZ / 180 * math.pi) + (RHandLocation.y - LHandLocation.y) * math.cos(-RotWeaponLZ / 180 * math.pi)
    local RHandWeaponZ = (RHandLocation.z - LHandLocation.z)

    -- Apply Left Hand's Roll (X-axis rotation) to the relative Right Hand coordinates.
    local RotWeaponLX = LHandRotation.z
    RHandWeaponY = RHandWeaponY * math.cos(RotWeaponLX / 180 * math.pi) - RHandWeaponZ * math.sin(RotWeaponLX / 180 * math.pi)
    RHandWeaponZ = RHandWeaponY * math.sin(RotWeaponLX / 180 * math.pi) + RHandWeaponZ * math.cos(RotWeaponLX / 180 * math.pi)

    -- Apply Left Hand's Pitch (Y-axis rotation) to the relative Right Hand coordinates.
    local RotWeaponLY = LHandRotation.x
    RHandWeaponX = RHandWeaponX * math.cos(-RotWeaponLY / 180 * math.pi) - RHandWeaponZ * math.sin(-RotWeaponLY / 180 * math.pi)
    RHandWeaponZ = RHandWeaponX * math.sin(-RotWeaponLY / 180 * math.pi) + RHandWeaponZ * math.cos(-RotWeaponLY / 180 * math.pi)

    -- Haptic feedback for entering and leaving defined zones.
    -- 'HolsterHapticFeedback' is a boolean preference from CONFIG.lua.
    if HolsterHapticFeedback then
        -- Right Hand general zone haptics.
        if isHapticZoneRLast ~= isHapticZoneR then
            uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, RightController)
            isHapticZoneRLast = isHapticZoneR
        end
        -- Left Hand general zone haptics.
        if isHapticZoneLLast ~= isHapticZoneL then
            uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
            isHapticZoneLLast = isHapticZoneL
        end
        -- Right Hand weapon zone haptics.
        if isHapticZoneWRLast ~= isHapticZoneWR then
            uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, RightController)
            isHapticZoneWRLast = isHapticZoneWR
        end
        -- Left Hand weapon zone haptics.
        if isHapticZoneWLLast ~= isHapticZoneWL then
            uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
            isHapticZoneWLLast = isHapticZoneWL
        end
    end

    -- Region: Zone Checking Functions (Local to on_pre_engine_tick for scope).
    --------------------------------------------------------------------------------
    -- Checks if the Right Hand's transformed location is within a specified 3D zone.
    -- ZoneVec6 format: {Zmin, Zmax, Ymin, Ymax, Xmin, Xmax} relative to HMD.
    local function RCheckZone(ZoneVec6)
        if RHandNewZ > ZoneVec6[1] and RHandNewZ < ZoneVec6[2] and
           RHandNewY > ZoneVec6[3] and RHandNewY < ZoneVec6[4] and
           RHandNewX > ZoneVec6[5] and RHandNewX < ZoneVec6[6] then
            return true
        else
            return false
        end
    end

    -- Checks if the Left Hand's transformed location is within a specified 3D zone.
    local function LCheckZone(ZoneVec6)
        if LHandNewZ > ZoneVec6[1] and LHandNewZ < ZoneVec6[2] and
           LHandNewY > ZoneVec6[3] and LHandNewY < ZoneVec6[4] and
           LHandNewX > ZoneVec6[5] and LHandNewX < ZoneVec6[6] then
            return true
        else
            return false
        end
    end

    -- Checks if the Right Hand's current general zone is the same as its previous zone.
    -- Used for debouncing actions triggered by entering/exiting zones while grabbing.
    local function isRZoneValidAction(RZone)
        if RZoneLast == RZone then
            return true
        else
            return false
        end
    end

    -- Checks if the Left Hand's current general zone is the same as its previous zone.
    local function isLZoneValidAction(LZone)
        if LZoneLast == LZone then
            return true
        else
            return false
        end
    end

    -- Checks if the Right Hand Weapon Zone's current zone is the same as its previous zone.
    local function isRWeaponZoneValidAction(RWeaponZone)
        if RWeaponZoneLast == RWeaponZone then
            return true
        else
            return false
        end
    end
    --------------------------------------------------------------------------------
    -- EndRegion: Zone Checking Functions


    -- Region: Holster Zone Definitions and Logic
    --------------------------------------------------------------------------------
    -- Determine the current RZone (Right Hand general zone) and trigger haptics.
    -- RHZoneRSh, RHZoneHead, etc., are coordinate definitions imported from zones.lua.
    if RCheckZone(RHZoneRSh) then       -- Right Shoulder Zone
        isHapticZoneR = true
        RZone = 1
    elseif RCheckZone(RHZoneHead) then  -- Over Head Zone
        isHapticZoneR = true
        RZone = 3
    elseif RCheckZone(RHZoneRHip) then  -- Right Hip Zone
        isHapticZoneR = true
        RZone = 4
    elseif RCheckZone(RHZoneRChest) then -- Right Chest Zone
        isHapticZoneR = true
        RZone = 7
    else
        isHapticZoneR = false
        RZone = 0 -- No specific zone.
    end

    -- Determine the current LZone (Left Hand general zone) and trigger haptics.
    -- LHZoneRSh, LHZoneLSh, etc., are coordinate definitions imported from zones.lua.
    if LCheckZone(LHZoneRSh) then       -- Right Shoulder Zone (for Left Hand)
        isHapticZoneL = true
        LZone = 1
    elseif LCheckZone(LHZoneLSh) then   -- Left Shoulder Zone
        isHapticZoneL = true
        LZone = 2
    elseif LCheckZone(LHZoneHead) then  -- Over Head Zone (for Left Hand)
        isHapticZoneL = true
        LZone = 3
    elseif LCheckZone(LHZoneLHip) then  -- Left Hip Zone
        isHapticZoneL = true
        LZone = 5
    elseif LCheckZone(LHZoneLChest) then -- Left Chest Zone
        isHapticZoneL = true
        LZone = 6
    elseif LCheckZone(LHZoneRChest) then -- Right Chest Zone (for Left Hand)
        isHapticZoneL = true
        LZone = 7
    else
        isHapticZoneL = false
        LZone = 0 -- No specific zone.
    end

    -- Defines Haptic Zones and RWeaponZone for Right-handed player's weapon interactions.
    -- This uses the Left Hand's position relative to the Right Hand (which is assumed to hold the weapon).
    if isRhand then
        -- LHandWeaponZ is vertical (up/down), LHandWeaponX is horizontal (left/right), LHandWeaponY is forward/backward.
        if LHandWeaponZ < -5 and LHandWeaponZ > -30 and
           LHandWeaponX < 20 and LHandWeaponX > -15 and
           LHandWeaponY < 12 and LHandWeaponY > -12 then
            isHapticZoneWL = true
            RWeaponZone = 1 -- Below gun, e.g., for magazine reload.
        elseif LHandWeaponZ < 10 and LHandWeaponZ > 0 and
               LHandWeaponX < 10 and LHandWeaponX > -5 and
               LHandWeaponY < 12 and LHandWeaponY > -12 then
            isHapticZoneWL = true
            RWeaponZone = 2 -- Close above Right Hand (weapon), e.g., for weapon mode switch.
        elseif LHandWeaponZ < 25 and LHandWeaponZ > 0 and
               LHandWeaponX < 45 and LHandWeaponX > 15 and
               LHandWeaponY < 15 and LHandWeaponY > -15 then
            isHapticZoneWL = true
            RWeaponZone = 3 -- Front at barrel (left side relative to weapon), e.g., for attachments.
        else
            RWeaponZone = 0
            isHapticZoneWL = false
        end
    else -- Defines Haptic Zones and LWeaponZone for Left-handed player's weapon interactions.
        -- This uses the Right Hand's position relative to the Left Hand (which is assumed to hold the weapon).
        if RHandWeaponZ < -5 and RHandWeaponZ > -30 and
           RHandWeaponX < 20 and RHandWeaponX > -5 and
           RHandWeaponY < 12 and RHandWeaponY > -12 then
            isHapticZoneWR = true
            LWeaponZone = 1 -- Below gun, e.g., for magazine reload.
        elseif RHandWeaponZ < 10 and RHandWeaponZ > 0 and
               RHandWeaponX < 10 and RHandWeaponX > -5 and
               RHandWeaponY < 12 and RHandWeaponY > -12 then
            isHapticZoneWR = true
            LWeaponZone = 2 -- Close above Left Hand (weapon), e.g., for weapon mode switch.
        elseif RHandWeaponZ < 25 and RHandWeaponZ > 0 and
               RHandWeaponX < 45 and RHandWeaponX > 15 and
               RHandWeaponY < 12 and RHandWeaponY > -12 then
            isHapticZoneWR = true
            LWeaponZone = 3 -- Front at barrel (right side relative to weapon), e.g., for attachments.
        else
            LWeaponZone = 0
            isHapticZoneWR = false
        end
    end
    --------------------------------------------------------------------------------
    -- EndRegion: Holster Zone Definitions and Logic


    -- Region: Quick Slot and Action Triggers
    --------------------------------------------------------------------------------
    -- Code to Depress: Resets quick slot button states for single-press behavior.
    -- These calls ensure that `Input_Released` events are sent to the game after an item is "quick-slotted."
    if Quick1 then Quick1 = false; player:Quick1Input_Released() end
    if Quick2 then Quick2 = false; player:Quick2Input_Released() end
    if Quick3 then Quick3 = false; player:Quick3Input_Released() end
    if Quick4 then Quick4 = false; player:Quick4Input_Released() end
    if Quick5 then Quick5 = false; player:Quick5Input_Released() end
    if Quick6 then Quick6 = false; player:Quick6Input_Released() end
    if Quick7 then Quick7 = false; player:Quick7Input_Released() end
    if Quick8 then Quick8 = false; player:Quick8Input_Released() end
    if Quick9 then Quick9 = false; player:Quick9Input_Released() end

    -- Main logic to equip items or trigger actions based on hand position and grab state.
    -- 'isRhand' is a configuration from CONFIG.lua.
    if isRhand then -- Right-handed player setup.
        if RZone == 1 and rGrabActive and RWeaponZone == 0 then -- Right Shoulder (Primary Weapon)
            -- local Primary= pawn.Inventory:GetPrimaryWeapon() -- Commented out in original.
            player:Quick1Input_Pressed()
            Quick1 = true -- Set Quick1 true to trigger release in the next tick.
        elseif RZone == 2 and rGrabActive then -- Zone 2 (e.g., secondary weapon/item). No corresponding zone in `zones.lua` starting with RHZone2.
            Key4 = true
            SendKeyDown('4')
        elseif RZone == 4 and rGrabActive then -- Right Hip (e.g., secondary item/grenade).
            Quick2 = true
            player:Quick2Input_Pressed()
        elseif RZone == 5 and rGrabActive then -- Zone 5. No corresponding zone in `zones.lua` starting with RHZone5.
            Key1 = true
            SendKeyDown('1')
        elseif LZone == 1 and lGrabActive and RWeaponZone == 0 then -- Left Hand, Right Shoulder equivalent (for an off-hand item).
            Quick8 = true
            player:Quick8Input_Pressed()
        elseif RZone == 8 and rGrabActive then -- Zone 8. No corresponding zone in `zones.lua` starting with RHZone8.
            Key1 = true
            SendKeyDown('1')
        elseif RZone == 6 and rGrabActive then -- Zone 6 (commented out action). No corresponding zone in `zones.lua` starting with RHZone6.
            -- No action defined in original script.
        elseif RZone == 7 and rGrabActive then -- Right Chest (e.g., health item).
            Quick3 = true
            player:Quick3Input_Pressed()
        elseif LZone == 2 and lGrabActive then -- Left Shoulder (Left Hand).
            player:Quick7Input_Pressed()
            Quick7 = true
        elseif LZone == 5 and lGrabActive then -- Left Hip (Left Hand).
            player:Quick6Input_Pressed()
            Quick6 = true
        elseif RZone == 3 and rGrabActive then -- Over Head (Right Hand) - UI Toggle.
            ToggleUI()
        elseif LZone == 3 and lGrabActive and isRShoulderHeadL == false then -- Over Head (Left Hand) - UI Toggle.
            ToggleUI()
        elseif LZone == 7 and lGrabActive then -- Left Chest (Left Hand).
            player:Quick5Input_Pressed()
            Quick5 = true
        elseif LZone == 6 and lGrabActive then -- Left Chest (Left Hand).
            -- isDpadLeft=true -- Commented out in original.
            player:Quick4Input_Pressed()
            Quick4 = true
        end
    else -- Left-handed player setup.
        if LZone == 2 and lGrabActive then -- Left Shoulder (Left Hand).
            Key3 = true
            SendKeyDown('3')
        elseif LZone == 1 and lGrabActive then -- Right Shoulder (Left Hand).
            Key4 = true
            SendKeyDown('4')
        elseif LZone == 5 and lGrabActive then -- Left Hip (Left Hand).
            Key2 = true
            SendKeyDown('2')
        elseif RZone == 3 and rGrabActive and isRShoulderHeadR == false then
            -- print("HolsterScript.lua: "..isRShoulder) -- Debug print.
            -- No explicit action, but it's checking `isRShoulderHeadR`.
        elseif LZone == 3 and lGrabActive and isRShoulderHeadL == false then
            -- print("HolsterScript.lua: "..isRShoulder) -- Debug print.
            -- No explicit action, but it's checking `isRShoulderHeadL`.
        elseif LZone == 8 and lGrabActive then -- Zone 8. No corresponding zone in `zones.lua` starting with LHZone8.
            Key1 = true
            SendKeyDown('1')
        elseif LZone == 6 and lGrabActive then -- Left Chest (Left Hand).
            Key5 = true
            SendKeyDown('5')
        elseif LZone == 7 and lGrabActive then -- Right Chest (Left Hand).
            Key6 = true
            SendKeyDown('6')
        elseif RZone == 1 and rGrabActive and LWeaponZone == 0 then -- Right Hand, Right Shoulder equivalent (for an off-hand item).
            KeyI = true
            SendKeyDown('I')
        elseif RZone == 2 and rGrabActive and LWeaponZone == 0 then -- Zone 2 (Right Hand). No corresponding zone in `zones.lua` starting with RHZone2.
            isDpadLeft = true
        elseif LZone == 4 and lGrabActive then -- Right Hip (Left Hand).
            Key1 = true
            SendKeyDown('1')
        elseif RZone == 7 and rGrabActive and LWeaponZone == 0 then -- Right Chest (Right Hand).
            Key7 = true
            SendKeyDown('7')
        elseif RZone == 6 and rGrabActive and LWeaponZone == 0 then -- Zone 6 (Right Hand). No corresponding zone in `zones.lua` starting with RHZone6.
            KeyM = true
            SendKeyDown('M')
        end
    end

    -- Code to trigger Weapon actions (e.g., reload, fire mode switch, attachment toggles).
    -- These actions depend on the off-hand being in a specific "weapon zone" relative to the main hand.
    if isRhand then -- Right-handed player weapon interactions.
        if RWeaponZone == 1 and lGrabActive then -- Left Hand in weapon reload zone (below gun) and Left Grab is active.
            -- print("HolsterScript.lua: "..pawn.Equipped_Primary:Jig_CanChamberWeapon()) -- Commented out in original.
            isReloading = true -- Set reload flag to trigger 'X' button press in xinput callback.
        elseif RWeaponZone == 2 and LTrigger > 230 and LTriggerWasPressed == 0 then -- Left Trigger pulled hard in weapon mode switch zone.
            -- pawn:ChamberWeapon(false) -- Commented out in original.
            KeyB = true
            SendKeyDown('B')
            LTriggerWasPressed = 1 -- Debounce trigger.
        elseif RWeaponZone == 3 and lThumbOut then -- Left Thumbstick pressed in attachment zone (front of barrel).
            if string.sub(uevr.params.vr:get_mod_value("VR_AimMethod"), 1, 1) == "2" then -- Checks if VR Aim Method is '2' (e.g., "Two-Handed Aim").
                isRShoulder = true -- Triggers Right Shoulder button press (likely for an attachment toggle).
            end
        end
    else -- Left-handed player weapon interactions.
        if LWeaponZone == 1 then -- Right Hand in weapon reload zone.
            if rGrabActive then
                isReloading = true
            else
                isReloading = false
            end
        elseif LWeaponZone == 2 and RTrigger > 230 and RTriggerWasPressed == 0 then -- Right Trigger pulled hard in weapon mode switch zone.
            KeyB = true
            SendKeyDown('B')
            RTriggerWasPressed = 1
        elseif LWeaponZone == 3 and rThumbOut then -- Right Thumbstick pressed in attachment zone.
            -- No action defined in original script for Left-handed player.
        end
    end
    -- print("HolsterScript.lua: "..LWeaponZone) -- Debug print.

    -- DEBUG PRINTS (commented out sections for displaying coordinates, useful for calibrating zones).
    -- To enable, uncomment the desired `print` statements.

    -- COORDINATES FOR HOLSTERS (HMD-relative positions)
    -- print("HolsterScript.lua: RHandz: " .. RHandLocation.z .. "     Rhandx: ".. RHandLocation.x )
    -- print("HolsterScript.lua: RHandx: " .. RHandNewX .. "     Lhandx: ".. LHandNewX .."      HMDx: " .. HmdLocation.x)
    -- print("HolsterScript.lua: RHandy: " .. RHandNewY .. "     Lhandy: ".. LHandNewY .."      HMDy: " .. HmdLocation.y)
    -- print("HolsterScript.lua: "..HmdRotation.y)
    -- print("HolsterScript.lua:                    ")
    -- print("HolsterScript.lua:                    ")
    -- print("HolsterScript.lua:                    ")

    -- COORDINATES FOR WEAPON ZONES (Hand-relative positions)
    -- print("HolsterScript.lua: RHandz: " .. RHandWeaponZ .. "     Lhandz: ".. LHandWeaponZ )
    -- print("HolsterScript.lua: RHandx: " .. RHandWeaponX .. "     Lhandx: ".. LHandWeaponX )
    -- print("HolsterScript.lua: RHandy: " .. RHandWeaponY .. "     Lhandy: ".. LHandWeaponY )
    -- print("HolsterScript.lua:                    ")
    -- print("HolsterScript.lua:                    ")
    -- print("HolsterScript.lua:                    ")
end)
--------------------------------------------------------------------------------
-- EndRegion: Pre-Engine Tick Callback