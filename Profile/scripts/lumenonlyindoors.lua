-- Require the configuration file for global settings.
-- This file is expected to contain a boolean variable like 'Enable_Lumen_Indoors'.
require(".\\Config\\CONFIG")

------------------------------------------------------------------------------------
-- Helper section
------------------------------------------------------------------------------------
-- Alias for the UEVR API, providing access to various engine functionalities.
local api = uevr.api
-- Alias for UEVR VR parameters, likely containing VR-specific settings (though not used in this script).
local vr = uevr.params.vr

--- Sets an integer value for a console variable (cvar).
-- This function interacts with Unreal Engine's console system to change engine settings.
-- @param cvar The name of the console variable as a string (e.g., "r.DynamicGlobalIlluminationMethod").
-- @param value The integer value to set (e.g., 0 for off, 1 for on).
function set_cvar_int(cvar, value)
    -- Get the console manager, which is responsible for finding and setting console variables.
    local console_manager = api:get_console_manager()

    -- Find the specific console variable by its name.
    local var = console_manager:find_variable(cvar)
    -- Check if the variable was successfully found.
    if(var ~= nil) then
        -- Set the integer value of the found console variable.
        var:set_int(value)
        -- Print a debug message to confirm the action.
        print(string.format("LumensOnlyIndoors.lua: Set CVar '%s' to %d", cvar, value))
    else
        -- Print an error if the CVar could not be found.
        print(string.format("LumensOnlyIndoors.lua: ERROR: CVar '%s' not found.", cvar))
    end
end

-------------------------------------------------------------------------------
-- hook_function
-- This is a generic helper to hook into Unreal Engine UFunctions (native or blueprint).
--
-- @param class_name The full name of the UClass containing the function (e.g., "Class /Script.Engine.GameEngine").
-- @param function_name The name of the UFunction to hook (e.g., "Tick").
-- @param native True if the function is a native (C++) function, false if it's Blueprint. Native functions sometimes require special flags.
-- @param prefn The Lua function to execute *before* the original Unreal function. Pass nil if not needed.
-- @param postfn The Lua function to execute *after* the original Unreal function. Pass nil if not needed.
-- @param dbgout True to print verbose debug outputs for this hook, false to suppress.
--
-- @return True on successful hook, false on failure.
-------------------------------------------------------------------------------
local function hook_function(class_name, function_name, native, prefn, postfn, dbgout)
    -- Print debug message if dbgout is true.
    if(dbgout) then print("LumensOnlyIndoors.lua: Hook_function for ", class_name, function_name) end
    local result = false
    -- Find the UObject class by its full name.
    local class_obj = uevr.api:find_uobject(class_name)
    -- If the class object is found.
    if(class_obj ~= nil) then
        if dbgout then print("LumensOnlyIndoors.lua: hook_function: found class obj for", class_name) end
        -- Find the specific function within the found class.
        local class_fn = class_obj:find_function(function_name)
        -- If the function is found.
        if(class_fn ~= nil) then
            if dbgout then print("LumensOnlyIndoors.lua: hook_function: found function", function_name, "for", class_name) end
            -- If the function is a native C++ function, set the Native flag (0x400) to ensure proper hooking.
            if (native == true) then
                class_fn:set_function_flags(class_fn:get_function_flags() | 0x400)
                if dbgout then print("LumensOnlyIndoors.lua: hook_function: set native flag") end
            end

            -- Apply the pre and post hooks to the function's execution pointer.
            class_fn:hook_ptr(prefn, postfn)
            result = true
            if dbgout then print("LumensOnlyIndoors.lua: hook_function: set function hook for", prefn, "and", postfn) end
        end
    end

    return result
end

-------------------------------------------------------------------------------
-- Logs to the log.txt file (UEVR's log output).
-------------------------------------------------------------------------------
local function log_info(message)
    uevr.params.functions.log_info(message)
end

-- Find the GameEngine class object. This is typically needed to get the current world.
local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")

--- Callback function that runs when fading back into the game (level load complete).
-- This function determines if the current world is an interior or exterior based on its name,
-- and then adjusts Lumen global illumination and reflections via console variables.
--
-- @param fn The function object being hooked (e.g., OnFadeToGameBeginEventReceived).
-- @param obj The object instance the function belongs to.
-- @param locals A table containing the function's local variables (parameters).
-- @param result The original return value of the function (not used in this post-hook).
local function FadeToGameBegin(fn, obj, locals, result)

    -- Only proceed if 'Enable_Lumen_Indoors' is set to true in the CONFIG file.
    if not Enable_Lumen_Indoors then
        print("LumensOnlyIndoors.lua: Lumen indoors disabled by config. Script will not modify Lumen settings.")
        return
    end

    print("LumensOnlyIndoors.lua: Fade to game initiated (Level changed event received).")

    -- Get the first active GameEngine object instance in the current world.
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
    if game_engine == nil then
        print("LumensOnlyIndoors.lua: ERROR: GameEngine object not found.")
        return
    end

    -- Get the GameViewport, which manages the display of the game world.
    local viewport = game_engine.GameViewport
    if viewport == nil then
        print("LumensOnlyIndoors.lua: ERROR: GameViewport is nil.")
        return
    end
    -- Get the current UWorld object from the viewport.
    local world = viewport.World
    if world == nil then
        print("LumensOnlyIndoors.lua: ERROR: World is nil.")
        return
    end

    -- Get the full name of the current world (level).
    local WorldName = world:get_full_name()
    print("LumensOnlyIndoors.lua: Current World: " .. WorldName)

    -- Check if the world name contains "World/", which is a common convention
    -- for exterior (open world) maps in Unreal Engine projects.
    if WorldName:find("World/") then
        print("LumensOnlyIndoors.lua: Detected EXTERIOR world. Disabling Lumen Global Illumination and Reflections.")
        -- Disable Lumen Dynamic Global Illumination
        set_cvar_int("r.DynamicGlobalIlluminationMethod", 0) -- 0: None, 1: Lumen, 2: Screen Space GI
        set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 0)     -- Disables Lumen's diffuse indirect lighting

        -- Disable Lumen Reflections
        set_cvar_int("r.Lumen.Reflections.Allow", 0)       -- Specific Lumen reflections allowance
        set_cvar_int("r.Lumen.Reflections.Temporal", 0)    -- Disables temporal accumulation for Lumen reflections (can reduce ghosting)

        -- Disables screen traces for Lumen probe gathering (can help prevent lingering GI artifacts)
        set_cvar_int("r.Lumen.ScreenProbeGather.ScreenTraces", 0)
                
        -- Globally disable hardware ray tracing (affects all ray-traced features, including Lumen's use of HRT)
        set_cvar_int("r.RayTracing.Enable", 0)

    else
        print("LumensOnlyIndoors.lua: Detected INTERIOR world. Enabling Lumen Global Illumination and Reflections.")
        -- Enable Lumen Dynamic Global Illumination
        set_cvar_int("r.DynamicGlobalIlluminationMethod", 1) -- 0: None, 1: Lumen, 2: Screen Space GI
        set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 1)     -- Enables Lumen's diffuse indirect lighting

        -- Enable Lumen Reflections
        set_cvar_int("r.Lumen.Reflections.Allow", 1)       -- Specific Lumen reflections allowance
        set_cvar_int("r.Lumen.Reflections.Temporal", 1)    -- Enables temporal accumulation for Lumen reflections
        
        -- Enables screen traces for Lumen probe gathering
        set_cvar_int("r.Lumen.ScreenProbeGather.ScreenTraces", 1)
        
        
        -- Globally enable hardware ray tracing
        set_cvar_int("r.RayTracing.Enable", 1)
    end
end

-- Hook the "OnFadeToGameBeginEventReceived" function in the "VLevelChangeData" class.
-- This event is typically triggered when a new game level has loaded and the fade-in process begins.
-- We use a post-hook (nil for prefn, FadeToGameBegin for postfn) to ensure the world is ready.
-- The 'true' at the end enables debug output for this specific hook.
hook_function("Class /Script/Altar.VLevelChangeData", "OnFadeToGameBeginEventReceived", false, nil, FadeToGameBegin, true)