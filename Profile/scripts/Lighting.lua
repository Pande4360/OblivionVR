-- Required libraries for UEHelper functions and configuration.
require(".\\Subsystems\\UEHelper")
require(".\\Config\\CONFIG")

-- Aliases for UEVR API and VR parameters for easier access.
local api = uevr.api
local vr = uevr.params.vr

-- Configuration for skylight intensity during day and night.
local SKYLIGHT_INTENSITY_DAY = 0.7
local SKYLIGHT_INTENSITY_NIGHT = 0.0

-- Scalar for scene brightness affecting skylight.
local SCENE_BRIGHTNESS_SKYLIGHT_SCALAR = 1.0

-- Flag to indicate if Post-Process Volume settings are being updated.
local SETTING_UPDATES_PPV = false

-- Current skylight intensity, initialized to day intensity.
local currentSkylightIntensity = SKYLIGHT_INTENSITY_DAY

-- Flags to determine if the player is in an interior or dark interior area.
local isInterior = false
local isDarkInterior = false

-- Caches for Post-Process Volume settings and general PPV data (currently unused).
local PPVSettingsCache = {}
local PPVCache = {}
--local ppvIniData = LoadIni(iniPath .. "PPVSettings.ini") -- Example of loading ini data, currently commented out.

-- Flags for tracking skylight updates and dynamic skylight behavior.
local hasUpdatedSkylightSetting = false
local dynamicSkylight = true

-- Mapping for skylight intensity (currently unused).
local mappingToSkylightIntensity = {}
--local levelLabels = LoadIni(iniPath .. "level_labels.ini")['levels'] -- Example of loading level labels, currently commented out.

-- Offsets for skylight intensity when in interiors during different times of day.
local INTERIOR_SUNRISE_OFFSET = 0.05
local INTERIOR_SUNSET_OFFSET = 0.05
local INTERIOR_DAY_OFFSET = 0.10
local INTERIOR_NIGHT_OFFSET = -0.02

-- Thresholds for sunrise and sunset detection based on sun angles.
local SUNRISE_THRESHOLD = 5
local SUNSET_THRESHOLD = 5

-- Flags for current time of day.
local isSunrise = false
local isSunset = false
local isDay = true
local isNight = false

-- Variables to store sun angles and their direction of change.
local sunSideAngle = 0
local sunAngleOffset = 0
local sunAngleIncreasing = false
local sunSideAngleIncreasing = false

-- Stores the current level's name.
local currentLevel = ''

-- Variables for tracking sky atmosphere and sun objects.
local lastScattering = -1
local skyAtmosphere = nil
local sun = nil

-- Flag to reset lighting settings.
local Reset = false

-- Variables to store previous percentage values for smooth transitions.
local sunrisePercentLast = 1
local sunsetPercentLast = 1

-- Variables to store last applied skylight intensity and brightness.
local skylightIntensityLast = 0
local BrightnessLast = 0

--local currentLightingMode = 'standard' -- Example of a lighting mode, currently commented out.
local last_level = nil -- Stores the last processed level object to detect level changes.
local lowerDiffuseLumen = false -- Currently unused.

--- Handles the update of skylight intensity and scene brightness based on time of day and interior status.
local function doSkylightUpdate()
    -- Attempt to find the sun actor in the scene.
    sun = find_first_of('Class /Script/Altar.VAltarSunActor', false)

    if not sun then
        -- If sun actor is not found, attempt to use SkyAtmosphereComponent for time detection.
        skyAtmosphere = find_first_of('Class /Script/Engine.SkyAtmosphereComponent')
        if skyAtmosphere then
            local mieScattering = skyAtmosphere['MieScatteringScale']

            -- Determine time of day based on MieScatteringScale.
            if mieScattering > 0.03 then
                isDay = true
                isNight = false
                isSunrise = false
                isSunset = false
            elseif mieScattering > 0.01 then
                -- Transition period (sunrise/sunset)
                isDay = false
                isNight = false
                if mieScattering > lastScattering and lastScattering ~= -1 then
                    isSunrise = true
                    isSunset = false
                    sunAngleOffset = (mieScattering - 0.01) * 25
                    sunSideAngle = 0
                elseif mieScattering < lastScattering and lastScattering ~= -1 then
                    isSunset = true
                    isSunrise = false
                    sunAngleOffset = (mieScattering - 0.01) * 25
                    sunSideAngle = 0
                else
                    isSunset = false
                    isSunrise = false
                end
            else
                isNight = true
                isDay = false
                isSunrise = false
                isSunset = false
            end
            lastScattering = mieScattering
        end
    else
        -- If sun actor is found, use its properties for time detection.
        lastScattering = -1 -- Reset last scattering as sun actor is dominant.
        local newSunSideAngle = math.abs(sun['Sun Side Angle'])
        local newSunAngleOffset = math.abs(sun['SunAngleOffset'])

        -- Determine if sun angles are increasing (for sunrise/sunset detection).
        sunSideAngleIncreasing = newSunSideAngle > sunSideAngle
        sunAngleIncreasing = newSunAngleOffset > sunAngleOffset

        sunSideAngle = newSunSideAngle
        sunAngleOffset = newSunAngleOffset

        -- Determine time of day based on sun angles and thresholds.
        isSunset = sunSideAngle < SUNRISE_THRESHOLD and sunSideAngle > 0
        isSunrise = sunAngleOffset < SUNRISE_THRESHOLD and sunAngleOffset > 0

        isDay = sunSideAngle > 0
        isNight = sunAngleOffset > 0

        -- Adjust sunrise/sunset flags based on angle direction.
        if isSunset and sunSideAngleIncreasing then
            isSunrise = true
            isSunset = false
        elseif isSunrise and sunAngleIncreasing then
            isSunrise = false
            isSunset = true
            sunAngleOffset = 0 -- Reset offset if transitioning to sunset.
        end
    end

    local tempNight = SKYLIGHT_INTENSITY_NIGHT
    -- The following block is commented out, but if uncommented, it would adjust tempNight if inside.
    -- if isInterior then
    --     tempNight = currentSkylightIntensity
    -- end

    local skylightIntensity = currentSkylightIntensity
    local Brightness = 4 -- Initial brightness value.
    local MAX_BRIGHTNESS = 0
    local MIN_BRIGHTNESS = -3

    local diffNightDay = currentSkylightIntensity - tempNight

    -- Adjust skylight intensity and brightness based on time of day and interior status.
    if isSunrise and not isInterior then
        print("Sunrise detected.")
        local sunrisePercent = (sunAngleOffset + sunSideAngle) / SUNRISE_THRESHOLD
        -- Smooth transition for skylight intensity and brightness during sunrise.
        if sunrisePercentLast - sunrisePercent < 0 and 0 - sunrisePercent < -0.01 or isMenu then
            skylightIntensity = tempNight + diffNightDay * sunrisePercent
            Brightness = MIN_BRIGHTNESS + (MAX_BRIGHTNESS - MIN_BRIGHTNESS) * sunrisePercent
        else
            skylightIntensity = tempNight
            Brightness = MIN_BRIGHTNESS
        end
        sunrisePercentLast = sunrisePercent
        BrightnessLast = Brightness
        skylightIntensityLast = skylightIntensity
    elseif isSunset and not isInterior then
        print("Sunset detected.")
        local sunsetPercent = (SUNSET_THRESHOLD - (sunSideAngle + sunAngleOffset)) / SUNSET_THRESHOLD
        -- Smooth transition for skylight intensity and brightness during sunset.
        if sunsetPercentLast - sunsetPercent < 0 and 0 - sunsetPercent < -0.01 or isMenu then
            skylightIntensity = skylightIntensity - diffNightDay * sunsetPercent
            Brightness = MAX_BRIGHTNESS - (MAX_BRIGHTNESS - MIN_BRIGHTNESS) * sunsetPercent
        else
            skylightIntensity = SKYLIGHT_INTENSITY_NIGHT
            Brightness = MIN_BRIGHTNESS
        end
        skylightIntensityLast = skylightIntensity
        BrightnessLast = Brightness
        sunsetPercentLast = sunsetPercent
    elseif isDay and not isInterior then
        print("Day detected.")
        Brightness = MAX_BRIGHTNESS
        skylightIntensity = SKYLIGHT_INTENSITY_DAY -- Set to full day intensity.
        skylightIntensityLast = skylightIntensity
        BrightnessLast = Brightness
    elseif isNight or isInterior then
        print("Night or Interior detected.")
        Brightness = MIN_BRIGHTNESS
        skylightIntensity = tempNight -- Set to night intensity or adjusted interior night intensity.

        -- Apply specific commands for night/interior.
        uevr.api:execute_command("r.LightMaxDrawDistanceScale 20")
        skylightIntensityLast = skylightIntensity
        BrightnessLast = Brightness
    else
        print("Neither day, night, sunrise, sunset, nor interior detected. Setting average lighting.")
        skylightIntensity = currentSkylightIntensity / 2
        Brightness = (MAX_BRIGHTNESS + MIN_BRIGHTNESS) / 2
    end

    -- If in a menu, revert to last known lighting settings to avoid abrupt changes.
    if isMenu then
        print("Menu detected. Using last known lighting settings.")
        skylightIntensity = skylightIntensityLast
        Brightness = BrightnessLast
    end

    -- Apply the calculated skylight intensity and brightness.
    uevr.api:execute_command('r.SkylightIntensityMultiplier' .. " " .. skylightIntensity)
    uevr.api:execute_command('Altar.GraphicsOptions.Brightness' .. " " .. Brightness)
end

-- Callback function executed before each engine tick.
uevr.sdk.callbacks.on_pre_engine_tick(
    function(engine, delta)

		--Skip lighting management if user specified to skip.
		if not ManageLighting then
			return
		end

        -- Only apply lighting adjustments if the 'DarkerDarks' setting is enabled.
        if DarkerDarks then
            doSkylightUpdate() -- Call the function to update skylight and brightness.

            local viewport = engine.GameViewport
            if viewport then
                local world = viewport.World
                if world then
                    local level = world.PersistentLevel

                    -- Detect if the level has changed.
                    if last_level ~= level then
                        local WorldName = world:get_full_name()
                        print("World Name: " .. WorldName)

                        -- Determine if the current location is an interior or exterior based on world name.
                        if not WorldName:find("World/") then
                            print("Location: Interior")
                            isInterior = true
                        else
                            print("Location: Exterior.")
                            isInterior = false
                        end

                        -- Specific override for Imperial Palace to be considered exterior.
                        if WorldName:find("World /Game/Maps/World/L_ICImperialPalace.L_ICImperialPalace") then
                            isInterior = false
                        end

                        -- Find light classes for adjustment.
                        local PointlightClass = find_required_object("Class /Script/Engine.PointLightComponent")
                        local VStreetLightClass
                        local VStreetLightClass2

                        -- Safely attempt to find street light blueprint classes.
                        pcall(function()
                            VStreetLightClass = find_required_object("BlueprintGeneratedClass /Game/Art/Prefabs/Fires/BP_PF_ICStreetlight01_Sta.BP_PF_ICStreetlight01_Sta_C")
                        end)
                        pcall(function()
                            VStreetLightClass2 = find_required_object("BlueprintGeneratedClass /Game/Art/Prefabs/Fires/BP_PF_ICStreetlight02_Sta.BP_PF_ICStreetlight02_Sta_C")
                        end)

                        -- Adjust attenuation radius for all PointLightComponents.
                        local PointlightArray = PointlightClass:get_objects_matching(false)
                        for x, i in ipairs(PointlightArray) do
                            if i ~= nil and not i:get_full_name():find("Torch") then
                                i:SetAttenuationRadius(3500)
                                print("Adjusted PointLight: " .. i:get_full_name())
                            elseif i:get_full_name():find("Torch") then
                                i:SetAttenuationRadius(1500)
                            end
                        end

                        -- Adjust street light properties if classes are found.
                        if VStreetLightClass ~= nil then
                            local StrretLightArray = VStreetLightClass:get_objects_matching(false)
                            for x, i in ipairs(StrretLightArray) do
                                if i["1_PointLight"] ~= nil then
                                    i["1_PointLight"]:SetAttenuationRadius(4000)
                                    i["1_PointLight"]:SetIntensity(2000.5)
                                    i["1_PointLight"]:SetLightFalloffExponent(2.1)
                                end
                            end
                        end

                        if VStreetLightClass2 ~= nil then
                            local StreetLightArray2 = VStreetLightClass2:get_objects_matching(false)
                            for x, i in ipairs(StreetLightArray2) do
                                if i["1_PointLight"] ~= nil then
                                    i["1_PointLight"]:SetAttenuationRadius(4000)
                                    i["1_PointLight"]:SetIntensity(2000.5)
                                    i["1_PointLight"]:SetLightFalloffExponent(2.1)
                                end
                            end
                        end
                        last_level = level -- Update last processed level.
                    end
                end
            end

            -- Adjust torch light properties if the player has a torch equipped.
            local pawn = api:get_local_pawn(0)
            if pawn and pawn.WeaponsPairingComponent and pawn.WeaponsPairingComponent.TorchActor then
                local torchIntensity = 1.5
                pawn.WeaponsPairingComponent.TorchActor["1_PointLight"]:SetIntensity(torchIntensity)
                pawn.WeaponsPairingComponent.TorchActor["1_PointLight"]:SetAttenuationRadius(3500)
                pawn.WeaponsPairingComponent.TorchActor["1_PointLight"]:SetLightFalloffExponent(7.1)
                pawn.WeaponsPairingComponent.TorchActor.BaseLightIntensity = torchIntensity
            end
        elseif Reset == false then
            -- If 'DarkerDarks' is disabled, reset lighting settings to default.
            Reset = true
            uevr.api:execute_command("r.LightMaxDrawDistanceScale 10")
            uevr.api:execute_command("Altar.GraphicsOptions.Brightness 0")
            uevr.api:execute_command("r.SkylightIntensityMultiplier 0.90")
        end
    end
)