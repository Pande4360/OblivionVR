require(".\\Subsystems\\UEHelper")
require(".\\Config\\CONFIG")
local api = uevr.api
local vr = uevr.params.vr

local skylightIntensityDay = 0.7
local skylightIntensityNight = 0.0
local sceneBrightnessSkylightScalar = 1.0
local settingUpdatesPPV = false

local currentSkylightIntensity = 0.7

local isInterior = false
local isDarkInterior = false

local PPVSettingsCache = {}
local PPVCache = {}
--local ppvIniData = LoadIni(iniPath .. "PPVSettings.ini")

local hasUpdatedSkylightSetting = false
local dynamicSkylight = true

local mappingToSkylightIntensity = {}
--l-ocal levelLabels = LoadIni(iniPath .. "level_labels.ini")['levels']

local interiorSunriseOffset = 0.05
local interiorSunsetOffset = 0.05
local interiorDayOffset = 0.10
local interiorNightOffset = -0.02

local sunrise = 5
local sunset = 5
local isSunrise = false
local isSunset = false
local isDay = true
local isNight = false

local sunSideAngle = 0
local sunAngleOffset = 0
local sunAngleIncreasing = false
local sunSideAngleIncreasing = false

local currentLevel = ''

local lastScattering = -1
local skyAtmosphere = nil
local sun = nil
local Reset=false
local sunrisePercentLast=1
local sunsetPercentLast=1
local skylightIntensityLast=0
local BrightnessLast=0
--local currentLightingMode = 'standard'
local last_level=nil
local lowerDiffuseLumen = false

local function doSkylightUpdate()
--	print("doing skylight update")
			--print("Day")
			--print(isDay)
			--print("night")
			--print(isNight)
			--print("Sunrise")
			--print(isSunrise)
			--print("interior")
			--print(isInterior)
			sun = find_first_of('Class /Script/Altar.VAltarSunActor',false)

			if not sun  then
			--	print("could not find instance of BP_Sun_C")
			else
				--print('valid sun')
				local newSunSideAngle = math.abs(sun['Sun Side Angle'])
				local newSunAngleOffset = math.abs(sun['SunAngleOffset'])

				isDay = false
				isNight = false
				isSunset = false
				isSunrise = false

				if newSunAngleOffset == 0 and newSunSideAngle == 0 then
					skyAtmosphere = find_first_of('Class /Script/Engine.SkyAtmosphereComponent')
					if skyAtmosphere  then
						
						local mieScattering = skyAtmosphere['MieScatteringScale']

				--		print('using sky atmosphere for the time ' .. mieScattering)

						if mieScattering > 0.03 then
							isDay = true
						elseif mieScattering > 0.01 then
							isDay = false
							isNight = false

							if mieScattering > lastScattering and lastScattering ~= -1 then
								isSunrise = true
								sunAngleOffset = (mieScattering - 0.01) * 25
								sunSideAngle = 0
							elseif mieScattering < lastScattering and lastScattering ~= -1 then
								isSunset = true
								sunAngleOffset = (mieScattering - 0.01) * 25
								sunSideAngle = 0
							else
								isSunset = false
								isSunrise = false
							end
						else
							isNight = true
						end

						lastScattering = mieScattering
					end
				else
					lastScattering = -1
					sunSideAngleIncreasing = newSunSideAngle > sunSideAngle
					sunAngleIncreasing = newSunAngleOffset > sunAngleOffset

					sunSideAngle = newSunSideAngle
					sunAngleOffset = newSunAngleOffset

					-- print("Sun info: " .. sunSideAngle .. ' ' .. sunAngleOffset)

					isSunset = sunSideAngle < sunrise and sunSideAngle > 0
					isSunrise = sunAngleOffset < sunrise and sunAngleOffset > 0

					isDay = sunSideAngle > 0
					isNight = sunAngleOffset > 0

					if isSunset and sunSideAngleIncreasing then
						isSunrise = true
						isSunset = false
					elseif isSunrise and sunAngleIncreasing then
						isSunrise = false
						isSunset = true
						sunAngleOffset = 0
					end
				end
			end
			local tempNight = skylightIntensityNight

			if isInterior then
				--tempNight = currentSkylightIntensity
			end
			
			
			--	if isNight or isInterior then
			--		uevr.api:execute_command("r.LightMaxDrawDistanceScale 20")
			--		uevr.api:execute_command("Altar.GraphicsOptions.Brightness -4")
			--		uevr.api:execute_command("r.SkylightIntensityMultiplier 0.00")
			--		elseif isDay and not isInterior then
			--		uevr.api:execute_command("r.LightMaxDrawDistanceScale 1")
			--		uevr.api:execute_command("Altar.GraphicsOptions.Brightness 0")
			--		uevr.api:execute_command("r.SkylightIntensityMultiplier 0.90")
			--		end

			local skylightIntensity = currentSkylightIntensity
			local Brightness = 4
			local MaxBrightness =0
			local MinBrightness =-3
		
			local diffNightDay = currentSkylightIntensity - tempNight
			
			-- print("Current: " .. currentSkylightIntensity)
			-- print("Night: " .. tempNight)
			
			if isSunrise and not isInterior then
				--print("sunrise")
				local sunrisePercent = (sunAngleOffset + sunSideAngle) / sunrise
				if sunrisePercentLast-sunrisePercent< 0 and 0-sunrisePercent <-0.01 or isMenu then
				skylightIntensity = tempNight + diffNightDay * sunrisePercent
				Brightness = MinBrightness + (MaxBrightness-MinBrightness)*sunrisePercent
				else 
				skylightIntensity=tempNight
				Brightness=MinBrightness
				end
				sunrisePercentLast=sunrisePercent
				--print(sunrisePercent)
				BrightnessLast=Brightness
						skylightIntensityLast=skylightIntensity		
			elseif isSunset and not isInterior then
				--print("sunset " .. sunSideAngle .. ' ' .. sunAngleOffset)
				local sunsetPercent = (sunset - (sunSideAngle + sunAngleOffset)) / sunset
				if sunsetPercentLast-sunsetPercent< 0 and 0-sunsetPercent <-0.01 or isMenu then
				skylightIntensity = skylightIntensity - diffNightDay * sunsetPercent
				Brightness= MaxBrightness - (MaxBrightness-MinBrightness)*sunsetPercent
				else 
				skylightIntensity=skylightIntensityNight
				Brightness=MinBrightness
				end
				skylightIntensityLast=skylightIntensity
				print(sunsetPercent)
				BrightnessLast=Brightness
				sunsetPercentLast=sunsetPercent
			elseif isDay and not isInterior then
				--print("day")
				Brightness=MaxBrightness
			--	if isInterior and not isDarkInterior then
					skylightIntensity = skylightIntensity --+ interiorDayOffset
				--end
				skylightIntensityLast=skylightIntensity
				BrightnessLast=Brightness
			elseif isNight or isInterior then
				--print("night")
				Brightness=MinBrightness
				skylightIntensity = tempNight
			--isNight or isInterior then
					uevr.api:execute_command("r.LightMaxDrawDistanceScale 20")
					--uevr.api:execute_command("Altar.GraphicsOptions.Brightness -4")
					--uevr.api:execute_command("r.SkylightIntensityMultiplier 0.00")
			--	if isInterior and not isDarkInterior then
			--		skylightIntensity = skylightIntensity + interiorNightOffset
			--	end
			skylightIntensityLast=skylightIntensity
			BrightnessLast=Brightness
		
			else
				print("neither")
				skylightIntensity = currentSkylightIntensity/2
				Brightness=(MaxBrightness+MinBrightness)/2
			end
			
			 --;print(string.format("new skylight is %s", skylightIntensity))
			if isMenu then
				print("Menu")
				skylightIntensity = skylightIntensityLast
				Brightness=BrightnessLast
			end
			
			uevr.api:execute_command('r.SkylightIntensityMultiplier' .." ".. skylightIntensity)
			uevr.api:execute_command('Altar.GraphicsOptions.Brightness' .." ".. Brightness)
			
			
	
end


uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

if DarkerDarks then
	doSkylightUpdate()
  local viewport = engine.GameViewport
        if viewport then
            local world = viewport.World
    
            if world then
                local level = world.PersistentLevel
				
				
				
				if last_level ~= level  then
			
				local WorldName = world:get_full_name()
					print(world:get_full_name())
					if not WorldName:find("World/")  then
						print("Interior")
						isInterior=true
					else
						print("Exterior.")
						isInterior=false
					end
					if WorldName:find("World /Game/Maps/World/L_ICImperialPalace.L_ICImperialPalace") then
						isInterior=false
					end
					PointlightClass= find_required_object("Class /Script/Engine.PointLightComponent")
					pcall(function()
					VStreetLightClass= find_required_object("BlueprintGeneratedClass /Game/Art/Prefabs/Fires/BP_PF_ICStreetlight01_Sta.BP_PF_ICStreetlight01_Sta_C")
					end)
					pcall(function()
					VStreetLightClass2= find_required_object("BlueprintGeneratedClass /Game/Art/Prefabs/Fires/BP_PF_ICStreetlight02_Sta.BP_PF_ICStreetlight02_Sta_C")
					end)
					
					local PointlightArray= PointlightClass:get_objects_matching(false)
					for x, i in ipairs (PointlightArray) do
						if i ~= nil and not i:get_full_name():find("Torch") then
							i:SetAttenuationRadius(3500)
							print(i:get_full_name())
							--i["1_PointLight"]:SetIntensity(1155.5)
						elseif i:get_full_name():find("Torch") then
							i:SetAttenuationRadius(1500)
				
						end
					end
				if VStreetLightClass ~= nil then
					local StrretLightArray= VStreetLightClass:get_objects_matching(false)
					for x, i in ipairs (StrretLightArray) do
						if i["1_PointLight"] ~= nil then
							i["1_PointLight"]:SetAttenuationRadius(4000)
						i["1_PointLight"]:SetIntensity(2000.5)
						i["1_PointLight"]:SetLightFalloffExponent(2.1)
						end
					end
				end
				if VStreetLightClass2 ~= nil then
					local StreetLightArray2= VStreetLightClass2:get_objects_matching(false)
					for x, i in ipairs (StreetLightArray2) do
						if i["1_PointLight"] ~= nil then
							i["1_PointLight"]:SetAttenuationRadius(4000)
							i["1_PointLight"]:SetIntensity(2000.5)
							i["1_PointLight"]:SetLightFalloffExponent(2.1)
						end
					end
				end
				end
				last_level=level
			end
		end
	
	


local pawn= api:get_local_pawn(0)

if pawn.WeaponsPairingComponent.TorchActor~=nil then
	local Intensity=1.5
	pawn.WeaponsPairingComponent.TorchActor["1_PointLight"]:SetIntensity(Intensity)
	pawn.WeaponsPairingComponent.TorchActor["1_PointLight"]:SetAttenuationRadius(3500)
	pawn.WeaponsPairingComponent.TorchActor["1_PointLight"]:SetLightFalloffExponent(7.1)
	pawn.WeaponsPairingComponent.TorchActor.BaseLightIntensity=Intensity
end
elseif	Reset==false then
	Reset=true
					uevr.api:execute_command("r.LightMaxDrawDistanceScale 10")
					uevr.api:execute_command("Altar.GraphicsOptions.Brightness 0")
					uevr.api:execute_command("r.SkylightIntensityMultiplier 0.90")
end
end)