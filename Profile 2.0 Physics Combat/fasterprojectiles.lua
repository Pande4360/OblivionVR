require(".\\Config\\CONFIG")


------------------------------------------------------------------------------------
-- Helper section
------------------------------------------------------------------------------------

local api = uevr.api
local vr = uevr.params.vr

------------------------------------------------------------------------------------
-- Add code here
------------------------------------------------------------------------------------
local Settings_Class = api:find_uobject("Class /Script/UE5AltarPairing.VOblivionInitialSettings")
local Static_Settings = api:find_uobject("VOblivionInitialSettings /Script/UE5AltarPairing.Default__VOblivionInitialSettings")


uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
	if Faster_Projectiles then
		if Static_Settings ~= nil then
			Static_Settings.MagicProjectileSpeedMultiplier = 99999.0
		end
    elseif not Faster_Projectiles then
		if Static_Settings ~= nil then
			Static_Settings.MagicProjectileSpeedMultiplier = 1950.0
		end
	end
end)

