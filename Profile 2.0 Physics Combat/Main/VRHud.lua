require(".\\Config\\CONFIG")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalDataCustom")
require(".\\Subsystems\\HelperFunctions")
local controllers = require('libs/controllers')

local utils=require(".\\libs\\uevr_utils")
--utils.initUEVR(uevr)

--local api = uevr.api
--local vr = uevr.params.vr
local temp_vec3 = Vector3d.new(0, 0, 0)
local LocVec = Vector3d.new(0, 0, 0)

--load classes
local hud_material_name = "MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent"
--local    ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
--local  hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local WidgetClass= find_required_object("Class /Script/UMG.WidgetComponent")
local ParMat= uevr.api:find_uobject("Material /Engine/EngineMaterials/Widget3DPassThrough.Widget3DPassThrough")
local wanted_mat = uevr.api:find_uobject("MaterialInstanceConstant /Engine/EngineMaterials/Widget3DPassThrough_Translucent.Widget3DPassThrough_Translucent")
		 ParMat:set_property("BlendMode", 0)
		 ParMat.bDisableDepthTest = true
local flinearColor_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")

--create instances

local reusable_hit_result = StructObject.new(hitresult_c)
local zero_transform = StructObject.new(ftransform_c)
if not zero_transform then return false end
  zero_transform.Rotation.W = 1.0
  zero_transform.Scale3D = temp_vec3:set(1.5, 1.5, 1.5)
local color = StructObject.new(flinearColor_c)
color.R = 100
color.G = 100
color.B = 100
color.A = 0.7


local WidgetComponent=nil   

function UpdateHudOnLevelChange()
	if right_hand_component==nil then return end
	local right_hand_actor = right_hand_component:get_outer()
	 WidgetComponent=right_hand_actor:AddComponentByClass(WidgetClass,false,zero_transform,false)
	local ReticleClass= uevr.api:find_uobject("WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Reticle/WBP_ModernHud_Reticle.WBP_ModernHud_Reticle_C")	--"WidgetBlueprintGeneratedClass /Game/UI/Modern/HUD/Main/Compass/WBP_ModernHud_CompassIcon.WBP_ModernHud_CompassIcon_C")
	local ReticleComponent= UEVR_UObjectHook.get_objects_by_class(ReticleClass,false)
	
	local ReticleWidget= nil
	for i, comp in ipairs(ReticleComponent) do
		if string.find(comp:get_full_name(), "VAltarHud") then
			print(comp:get_full_name())
			ReticleWidget=comp
		end
	
	end

	ReticleWidget:RemoveFromViewport()
	--right_hand_component:SetMaterial(0,hud_material_name)
	WidgetComponent:SetWidget(ReticleWidget)
	WidgetComponent:SetDrawSize(utils.vector_2(200, 70))
	WidgetComponent:SetVisibility(true,true)
	WidgetComponent:SetHiddenInGame(false,false)
	WidgetComponent:SetMaterial(0,wanted_mat)
	WidgetComponent.BlendMode=2
	WidgetComponent:SetTintColorAndOpacity(color)
	right_hand_actor:FinishAddComponent(WidgetComponent,false, zero_transform)
	WidgetComponent:K2_AttachToComponent(right_hand_component,"",2,2,0,true)
	WidgetComponent:K2_SetRelativeLocation(LocVec:set(2500, 0, 0), false, reusable_hit_result, false)
	WidgetComponent:K2_SetRelativeRotation(LocVec:set(0, 180, 0), false, reusable_hit_result, false)
end


local Init=false
local isInit=false
local last_level=nil


function InitHud(pawn)
	if string.find( pawn:get_fname():to_string(),"Player") then
		Init=true
	end
	
	
	if Init and isInit==false then
	isInit=true
	UpdateHudOnLevelChange()
	end

end



--uevr.sdk.callbacks.on_pre_engine_tick(
--function(engine, delta)
--local pawn =api:get_local_pawn(0)
--
--
--if string.find( pawn:get_fname():to_string(),"Player") then
--	Init=true
--end
--
--
--if Init and isInit==false then
--isInit=true
--UpdateHudOnLevelChange()
--end
--
--
--local viewport = engine.GameViewport
--	if viewport then
--    local world = viewport.World
--
--		if world then
--        local level = world.PersistentLevel
--
--
--			if last_level ~= level  then
--				UpdateHudOnLevelChange()
--				
--			end
--			    last_level = level
--		end
--	end
--end)