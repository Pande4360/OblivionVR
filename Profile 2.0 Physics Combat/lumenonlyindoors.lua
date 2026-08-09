require(".\\Config\\CONFIG")
------------------------------------------------------------------------------------
-- Helper section
------------------------------------------------------------------------------------
local api = uevr.api
local vr = uevr.params.vr

function set_cvar_int(cvar, value)
    local console_manager = api:get_console_manager()
    
    local var = console_manager:find_variable(cvar)
    if(var ~= nil) then
        var:set_int(value)
    end
end

-------------------------------------------------------------------------------
-- xinput helpers
-------------------------------------------------------------------------------
function is_button_pressed(state, button)
    return state.Gamepad.wButtons & button ~= 0
end
function press_button(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons | button
end
function clear_button(state, button)
    state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
end

-------------------------------------------------------------------------------
-- hook_function
--
-- Hooks a UEVR function. 
--
-- class_name = the class to find, such as "Class /Script.GunfireRuntime.RangedWeapon"
-- function_name = the function to Hook
-- native = true or false whether or not to set the native function flag.
-- prefn = the function to run if you hook pre. Pass nil to not use
-- postfn = the function to run if you hook post. Pass nil to not use.
-- dbgout = true to print the debug outputs, false to not
--
-- Example:
--    hook_function("Class /Script/GunfireRuntime.RangedWeapon", "OnFireBegin", true, nil, gun_firingbegin_hook, true)
--
-- Returns: true on success, false on failure.
-------------------------------------------------------------------------------
local function hook_function(class_name, function_name, native, prefn, postfn, dbgout)
	if(dbgout) then print("Hook_function for ", class_name, function_name) end
    local result = false
    local class_obj = uevr.api:find_uobject(class_name)
    if(class_obj ~= nil) then
        if dbgout then print("hook_function: found class obj for", class_name) end
        local class_fn = class_obj:find_function(function_name)
        if(class_fn ~= nil) then 
            if dbgout then print("hook_function: found function", function_name, "for", class_name) end
            if (native == true) then
                class_fn:set_function_flags(class_fn:get_function_flags() | 0x400)
                if dbgout then print("hook_function: set native flag") end
            end
            
            class_fn:hook_ptr(prefn, postfn)
            result = true
            if dbgout then print("hook_function: set function hook for", prefn, "and", postfn) end
        end
    end
    
    return result
end


-------------------------------------------------------------------------------
-- Logs to the log.txt
-------------------------------------------------------------------------------
local function log_info(message)
	uevr.params.functions.log_info(message)
end


local game_engine_class = api:find_uobject("Class /Script/Engine.GameEngine")


-- runs on level change begin
local function FadeToBlackBegin(fn, obj, locals, result)
    if not Enable_Lumen_Indoors then return end
    print("level change begin, disabling lumen\n")
    set_cvar_int("r.DynamicGlobalIlluminationMethod", 0)
    set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 0)
end

-- runs on game level load
local function FadeToGameBegin(fn, obj, locals, result)
    if not Enable_Lumen_Indoors then return end
    print("Fade to game\n")
    local game_engine = UEVR_UObjectHook.get_first_object_by_class(game_engine_class)

    local viewport = game_engine.GameViewport
    if viewport == nil then 
		print("Viewport is nil")
        return
    end
    local world = viewport.World
    
    if world == nil then
        print("World is nil")
        return
    end
    
    
    
    local WorldName = world:get_full_name()
    
    if not WorldName:find("World/") then
        print("Interior, enabling lumen")
        set_cvar_int("r.DynamicGlobalIlluminationMethod", 1)
        set_cvar_int("r.Lumen.DiffuseIndirect.Allow", 1)
    else
        print("Exterior, leaving luemn disabled.")
    end
end


hook_function("Class /Script/Altar.VLevelChangeData", "OnFadeToBlackBeginEventReceived", false, nil, FadeToBlackBegin, false)
hook_function("Class /Script/Altar.VLevelChangeData", "OnFadeToGameBeginEventReceived", false, nil, FadeToGameBegin, false)



