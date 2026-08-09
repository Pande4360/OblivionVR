require(".\\Config\\CONFIG")
local controllers = require('libs/controllers')
--require(".\\Trackers\\Trackers")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalDataCustom")
--require(".\\Subsystems\\UEHelper")
require(".\\Subsystems\\HelperFunctions")
local uevrUtils = require("libs/uevr_utils")
--local api = uevr.api
--local params = uevr.params
--local callbacks = params.sdk.callbacks
--local vr=uevr.params.vr
--
--local function find_required_object(name)
--	local obj = uevr.api:find_uobject(name)
--	if not obj then
--		print("Cannot find " .. name)
--		return nil
--	end
--
--	return obj
--end
--local find_static_class = function(name)
--    local c = find_required_object(name)
--    return c:get_class_default_object()
--end

--local testfind= find_static_class("Class /Script/Engine.PoseableMeshComponent")

--local pawn = api:get_local_pawn(0)
local lossy_offset= Vector3f.new(0,math.pi/2,0)
local glove_mesh = nil
local master_mat = nil
local has_found_overlays = false
local can_disable_overlays = false
local goggles = nil
local masks = nil

--local last_level = nil
--local kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")


--local  hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result = StructObject.new(hitresult_c)


local loadout = nil
local in_loadout = false
local check_refill = false
local last_refill = false
local might_be_refilling = false
local ArrowMeshOld=nil



local function ResetShotArrows()
	if ArrowMeshOld~=nil then
		if ArrowMeshOld~=ArrowMesh then
		-- print(ArrowMeshOld:GetOwner():get_fname():to_string())
		end
	end
end

local function GetHmdTiltOffset()

	if HmdRotator==nil then return 0 end
	
	local Offset= HmdRotator.x/90* 20
	
	
	return Offset
	
	
end

local Neutral = 0
local Offset=0
local HmdRotatorYLast=0
local function GetHmdYawOffset()
	if HmdRotator==nil then return end
	--print(HmdRotator.y)
	
	
	local deltaOffset= 0
	if math.abs(HmdRotator.y - HmdRotatorYLast) < 90 then
		deltaOffset=HmdRotator.y - HmdRotatorYLast
	else
		deltaOffset= 1
	end
	
	if math.abs(Offset) <= 70 then
		Offset= Offset+deltaOffset
	elseif Offset >70 then
		Offset=70
	elseif Offset< -70 then
		Offset=-70
	end
	
	if math.abs(ThumbLY)>5000 or math.abs(ThumbLX)>5000 then
			Offset=Offset/4
	end
	if isBow and RTrigger > 100 then
		Offset = 50
	end
	local YawOffset= Offset/180*math.pi
	
	HmdRotatorYLast=HmdRotator.y
	--print(Offset)
	--print(YawOffset)
	return YawOffset
end

 function update_Body_Meshes(Mesh)
	if not VisibleBody then
	 UEVR_UObjectHook.remove_motion_controller_state(Mesh)
	 Mesh:SetVisibility(false,true)
	return end
	if Mesh == nil then return end
	local pawn = api:get_local_pawn(0)
	if not isRiding then
		
			
		--local attach_socket_name = weapon_mesh.AttachSocketName
		--local PMesh= pawn.Mesh1P
		-- Get socket transforms
		if pawn.bIsUsingFirstPersonMesh and not  pawn:IsRagdolling()  then
		
			
			local default_transform = Mesh:GetSocketTransform("Root",2)--Transform(attach_socket_name, 2)
			local offset_transform = Mesh:GetSocketTransform("head",2)--weapon_mesh:GetSocketTransform("jnt_offset", 2)
			
			--local middle_translation = kismet_math_library:Add_VectorVector(default_transform.Translation, offset_transform.Translation)
			local location_diff = kismet_math_library:Subtract_VectorVector(
				default_transform.Translation,
				offset_transform.Translation--Vector3f.new(0,0,0)
			)
			-- from UE to UEVR X->Z Y->-X, Z->-Y
			-- Z - forward, X - negative right, Y - negative up
			local lossy_offset = Vector3f.new(-location_diff.y-GetHmdTiltOffset(), -location_diff.z+GetHmdTiltOffset()+10, location_diff.x)
			
			Mesh:HideBoneByName(uevrUtils.fname_from_string("lowerarm_r"))
			Mesh:HideBoneByName(uevrUtils.fname_from_string("lowerarm_l"))
			
			Mesh:SetRenderInMainPass(false)
			SearchSubObjectArrayForObject(Mesh.AttachChildren,"Hands"):SetVisibility(1)
			
			SearchSubObjectArrayForObject(Mesh.AttachChildren,"Upper"):SetVisibility(0,true)
			SearchSubObjectArrayForObject(Mesh.AttachChildren,"Lower"):SetVisibility(0,true)
			SearchSubObjectArrayForObject(Mesh.AttachChildren,"Feet"):SetVisibility(0,true)
			--Mesh:SetVisibility(0,true)
			--Mesh:SetVisibility(0,false)
			Mesh:SetVisibility(1,false)
			
			--Mesh.AttachChildren[4]:SetVisibility(1,true)
			--Mesh.AttachChildren
			--Mesh.AttachChildren.["ChildActorComponent Upper Body"].AttachChildren.["SkeletalMeshComponent Root SkeletalMesh"]:SetVisibility(0)
			if HmdRotator~=nil then
			print("found HmdRot")
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_hand(2)
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_rotation_offset(Vector3f.new(HmdRotator.x/180*math.pi,95/180*math.pi+GetHmdYawOffset(),HmdRotator.z/180*math.pi))
			UEVR_UObjectHook.get_or_add_motion_controller_state(Mesh):set_location_offset(lossy_offset)
			end
			if pawn:IsRagdolling() then
				UEVR_UObjectHook.remove_motion_controller_state(Mesh)
			end
		else
			Mesh:UnHideBoneByName(uevrUtils.fname_from_string("lowerarm_r"))
			Mesh:UnHideBoneByName(uevrUtils.fname_from_string("lowerarm_l"))
			--local RiderHead = SearchSubObjectArrayForObject(pawn.MainSkeletalMeshComponent.AttachChildren, "Head")
			--RiderHead:SetVisibility(true)
			--RiderHead:SetRenderInMainPass(true)
			--local RiderHeadChildren= RiderHead.AttachChildren
			--for i, comp in ipairs(RiderHeadChildren) do
			--	comp:SetVisibility(true)
			--	pcall(function()
			--	comp:SetRenderInMainPass(true)
			--	end)
			--end
				
				
			UEVR_UObjectHook.remove_motion_controller_state(Mesh)
			--pawn.MainSkeletalMeshComponent:SetVisibility(0, false)
			pawn.MainSkeletalMeshComponent:SetRenderInMainPass(true)
			--SearchSubObjectArrayForObject(Mesh.AttachChildren,"Hands"):SetVisibility(1)
		end
		
	else
		--pawn.Rider.Mesh:UnHideBoneByName(uevrUtils.fname_from_string("lowerarm_r"))
		--pawn.Rider.Mesh:UnHideBoneByName(uevrUtils.fname_from_string("lowerarm_l"))
		pawn.Rider.MainSkeletalMeshComponent:SetVisibility(0)
		pawn.Rider.MainSkeletalMeshComponent:SetRenderInMainPass(false)
		local RiderHead = SearchSubObjectArrayForObject(pawn.Rider.MainSkeletalMeshComponent.AttachChildren, "Head Component")
			RiderHead:SetVisibility(false)
			--RiderHead:SetRenderInMainPass(false)
			local RiderHeadChildren2= RiderHead.AttachChildren
			for i, comp in ipairs(RiderHeadChildren2) do
				comp:SetVisibility(false)
				pcall(function()
				comp:SetRenderInMainPass(false)
				end)
			end
		pawn.Rider.Mesh:K2_SetRelativeLocation(Vector3d.new(0,0,-90),false,reusable_hit_result,false)
		UEVR_UObjectHook.remove_motion_controller_state(pawn.Rider.MainSkeletalMeshComponent)
		UEVR_UObjectHook.remove_motion_controller_state(pawn.MainSkeletalMeshComponent)
		--pawn.Rider.Mesh
	end
end

 function update_weapon_offset(Body_mesh)
    if not Body_mesh then print("nil") return end
	
   -- local attach_socket_name = weapon_mesh.AttachSocketName
	local PairingComponent= Body_mesh
	
	local WeaponMesh=nil
	local ShieldMesh=nil
	local ArrowMesh=nil
	local BowMesh=nil
	local QuiverMesh=nil
	--x=pitch 
	local PairingComponentsOut = {}
	
	
	
	
	
	
	
	ResetShotArrows()
	if not isRiding then
		if PairingComponent.WeaponActor~=nil then
			if PairingComponent.WeaponActor.MainStaticMeshComponent ~=nil then
			--	if PairingComponent.WeaponActor.MainStaticMeshComponent.AttachSocketName:to_string()=="Weapon_Socket" then
			--	WeaponMesh=PairingComponent.WeaponActor.MainStaticMeshComponent
			--	UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_hand(1)
			--	UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_rotation_offset(Vector3f.new(0,-30/190*math.pi,-math.pi/2))
			--	UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_location_offset(Vector3f.new(0.5,0,1.5))
			--	--print("foundWeapon")
			--		if isWeaponDrawn then 
			--			WeaponMesh:SetVisibility(true)
			--			UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_permanent(true)
			--		else WeaponMesh:SetVisibility(false)
			--			UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_permanent(false)
			--		end
			--		--UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_permanent(true)
			--	end
				if PairingComponent.WeaponActor.ScabbardMeshComponent ~= nil then
					ScabbardMesh=PairingComponent.WeaponActor.ScabbardMeshComponent
				--if isWeaponDrawn then
					ScabbardMesh:SetVisibility(false)
				end
			end	
			local reusableHitResult ={}
			if PairingComponent.WeaponActor.MainSkeletalMeshComponent ~=nil then
				if PairingComponent.WeaponActor.MainSkeletalMeshComponent.AttachSocketName:to_string()== "Torch_Socket" then
					BowMesh=PairingComponent.WeaponActor.MainSkeletalMeshComponent
		--			print("foundShield")
					--BowMesh:K2_SetWorldLocation(left_hand_component:K2_GetComponentLocation(),false,reusableHitResult,false)
					UEVR_UObjectHook.get_or_add_motion_controller_state(BowMesh):set_hand(0)
					if isWeaponDrawn then
						BowMesh:SetVisibility(true)
						
					else BowMesh:SetVisibility(false) 
					end
					
					
					local LeftZCounterFactor= 0
					if LeftRotator.z >90 then LeftZCounterFactor=90
					elseif LeftRotator.z <=90 and LeftRotator.z > 0 then
						LeftZCounterFactor=LeftRotator.z
					elseif LeftRotator.z<0 and LeftRotator.z >=-90 then LeftZCounterFactor=-LeftRotator.z
					else LeftZCounterFactor=-90
					end
					local Diff_Rotator_LR_Arrow_ConvY=0
					if Diff_Rotator_LR_Arrow.y <0 then Diff_Rotator_LR_Arrow_ConvY=360+ Diff_Rotator_LR_Arrow.y
					else Diff_Rotator_LR_Arrow_ConvY = Diff_Rotator_LR_Arrow.y end
					local LeftRotatorYConv=LeftRotator.y
					if LeftRotator.y<0 then
						LeftRotatorYConv = 360+ LeftRotator.y
					end
					
					local DiffY =0
					if Diff_Rotator_LR.y-LeftCompRotation.y >180 then
						DiffY=  (Diff_Rotator_LR.y-LeftCompRotation.y)-360
					else DiffY = Diff_Rotator_LR.y-LeftCompRotation.y
					end
					
					if RTrigger >0 then
						--print(Diff_Rotator_LR_Arrow.y-LeftRotator.y)
						UEVR_UObjectHook.get_or_add_motion_controller_state(BowMesh):set_rotation_offset(Vector3f.new(
						((DiffY)/180*math.pi)*math.cos(LeftCompRotation.z/180*math.pi)+math.sin(LeftCompRotation.z/180*math.pi)* ((-Diff_Rotator_LR.x+LeftCompRotation.x)/180*math.pi+12/180*math.pi),
						(-Diff_Rotator_LR.x)/180*math.pi*math.cos(LeftCompRotation.z/180*math.pi)*math.cos(LeftCompRotation.z/180*math.pi)+math.sin(LeftCompRotation.z/180*math.pi)* ((-DiffY)/180*math.pi),
						math.pi/2))
																											
						--BowMesh:K2_SetWorldRotation(Vector3f.new(Diff_Rotator_LR_Arrow.x+180,Diff_Rotator_LR_Arrow.y,LeftRotator.z+90),false, reusableHitResult, false)
						UEVR_UObjectHook.get_or_add_motion_controller_state(BowMesh):set_location_offset(Vector3f.new(0,3.4,1))--(0,-3.4,1))
					else
						--BowMesh:K2_SetWorldRotation(Vector3f.new(LeftRotator.x,LeftRotator.y,LeftRotator.z+90),true, reusableHitResult, true)
						UEVR_UObjectHook.get_or_add_motion_controller_state(BowMesh):set_rotation_offset(Vector3f.new(0,0,math.pi/2))
						UEVR_UObjectHook.get_or_add_motion_controller_state(BowMesh):set_location_offset(Vector3f.new(0,3.4,1))
					end
					UEVR_UObjectHook.get_or_add_motion_controller_state(BowMesh):set_permanent(false)
					--BowMesh:K2_SetWorldRotation(Diff_Rotator_LR_Arrow,false, reusableHitResult, false)
				end
				
			end
		end
		if PairingComponent.ShieldActor~=nil then
			if PairingComponent.ShieldActor.MainStaticMeshComponent.AttachSocketName:to_string()=="Shield_Socket" then
				ShieldMesh=PairingComponent.ShieldActor.MainStaticMeshComponent
					if isWeaponDrawn and not isBow then
						ShieldMesh:SetVisibility(true, true)
						UEVR_UObjectHook.get_or_add_motion_controller_state(ShieldMesh):set_permanent(true)
						--ShieldMesh:SetRenderInMainPass(true)
					else ShieldMesh:SetVisibility(false, true)
						UEVR_UObjectHook.get_or_add_motion_controller_state(ShieldMesh):set_permanent(false)
						--ShieldMesh:SetRenderInMainPass(false)
					end
					if isBow then ShieldMesh:SetVisibility(false, true) end
		--		print("foundShield")
				UEVR_UObjectHook.get_or_add_motion_controller_state(ShieldMesh):set_hand(0)
				UEVR_UObjectHook.get_or_add_motion_controller_state(ShieldMesh):set_rotation_offset(Vector3f.new(math.pi,math.pi,0))
				UEVR_UObjectHook.get_or_add_motion_controller_state(ShieldMesh):set_location_offset(Vector3f.new(2,-6,-30))
				
			end
				
		end
		--print(isBow)
			
		if PairingComponent.QuiverActor~=nil then --string.find(Mesh:get_fname():to_string(),"Drawn Arrow") then
			if PairingComponent.QuiverActor.MainStaticMeshComponent.AttachSocketName:to_string()=="Quiver_Socket" then
				QuiverMesh= PairingComponent.QuiverActor.MainStaticMeshComponent
				QuiverMesh:SetVisibility(false,true)
			end
		end
		if pawn.DrawnArrowMeshComponent~=nil then --string.find(Mesh:get_fname():to_string(),"Drawn Arrow") then
		ArrowMesh=pawn.DrawnArrowMeshComponent
			--if pawn.DrawnArrowMeshComponent.AttachSocketName:to_string()=="Quiver_Socket" then
				UEVR_UObjectHook.get_or_add_motion_controller_state(ArrowMesh):set_hand(1)
				if isBow then
				UEVR_UObjectHook.get_or_add_motion_controller_state(ArrowMesh):set_rotation_offset(Vector3d.new(Diff_Rotator_LR_Arrow.x/180*math.pi-RightRotator.x/180*math.pi-7/180*math.pi,
																												-(-Diff_Rotator_LR_Arrow.y/180*math.pi+RightRotator.y/180*math.pi)+2/180*math.pi,
																												RightRotator.z/180*math.pi+math.pi))
				UEVR_UObjectHook.get_or_add_motion_controller_state(ArrowMesh):set_location_offset(Vector3f.new(-1,8,70))
				UEVR_UObjectHook.get_or_add_motion_controller_state(ArrowMesh):set_permanent(true)
				else
				UEVR_UObjectHook.get_or_add_motion_controller_state(ArrowMesh):set_permanent(false)
				end
			--end	
		end
	
	
		--if VisibleHelmet then
		--	if pawn.HeadwearChildActorComponent.ChildActor.StaticMesh~=nil or pawn.HeadwearChildActorComponent.ChildActor.RootSkeletalMeshComponent ~=nil then
		--		pawn.HeadwearChildActorComponent:SetVisibility(true)
		--		pcall(function()
		--		pawn.HeadwearChildActorComponent.ChildActor.StaticMesh:SetVisibility(true)
		--		end)
		--		pawn.HeadwearChildActorComponent.ChildActor.RootSkeletalMeshComponent:SetVisibility(true)
		--	end
		--end
		ArrowMeshOld=ArrowMesh
	end
	--print(Diff_Rotator_LR.x)
	--	
	PairingComponentsOut.Weapon = WeaponMesh
	PairingComponentsOut.Shield = ShieldMesh
	PairingComponentsOut.Arrow = ArrowMesh
	PairingComponentsOut.Bow = BowMesh
	PairingComponentsOut.Quiver = QuiverMesh
	return PairingComponentsOut
end

--uevr.sdk.callbacks.on_pre_engine_tick(function(engine, delta)
----print(testfind:get_fname())
-- pawn = api:get_local_pawn(0)
-- local WeaponMesh=pawn.WeaponsPairingComponent
-- local BodyMesh= pawn.MainSkeletalMeshComponent
-- update_weapon_offset(WeaponMesh)
-- update_Body_Meshes(BodyMesh)
--
--end)