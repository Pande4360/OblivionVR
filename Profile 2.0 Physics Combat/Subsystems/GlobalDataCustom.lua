require(".\\Subsystems\\HelperFunctions")
require(".\\Subsystems\\GlobalData")


 DebugStats=false
 DebugForce=true





 
  AtriClass = nil--find_required_object("Class /Script/LOTF2.AnathemaAbilitySystemComponent")
  AtriSet_C = nil--find_required_object("Class /Script/LOTF2.AttributesAttributeSet")
  WpnSet_C  = nil--find_required_object("Class /Script/LOTF2.WeaponAttributeSet")
  AtriStr_C = nil--find_required_object("Class /Script/G1R.AttributeSet_Strength")
  
  
  
  Mesh_C = find_required_object("Class /Script/Engine.StaticMesh")
  staic_mesh_component_c = find_required_object("Class /Script/Engine.StaticMeshComponent")
  
  plane = find_required_object_no_cache(Mesh_C, "StaticMesh /Engine/BasicShapes/Cube.Cube")
  Sphere = find_required_object_no_cache(Mesh_C, "StaticMesh /Engine/BasicShapes/Sphere.Sphere")
  
  Stats_C = find_required_object("Class /Script/Altar.VStatsMenuViewModel")
  
  StatsComp = nil
  
  --PhysCombat:
  isTired=false
  
  
  
  --PhysMat = find_required_object("PhysicalMaterial /Game/Art/Materials/PhysicalMaterials/Metal.Metal")
 
 local function GetHmdTiltOffset(Rotator)

	--if hmd_component==nil then return end
	
	
	local HmdRotator = Rotator
	local Offset= HmdRotator.x/90* 20
	
	return Offset
	
	
end
		local GameTime= 0
function UpdateBowStatus(pawn)

	isBow=false
	if isRiding==false then
		if pawn.WeaponsPairingComponent.WeaponActor~=nil then
			if pawn.WeaponsPairingComponent.WeaponActor.MainSkeletalMeshComponent ~=nil then
					if string.find(pawn.WeaponsPairingComponent.WeaponActor:get_fname():to_string(), "Bow") then
						isBow=true
					end
			end
		end
	end
end
function UpdateRidingStatus(Pawn)
	isRiding=false
	if string.find(Pawn:get_fname():to_string(),"Horse") then
		isRiding=true

	end
end		

 function UpdateMenuStatus(Player)
	if Player.bShowMouseCursor then
		isMenu=true
	else isMenu=false
	end
end
 function UpdateCombatStanceStatus(pawn)
	if pawn == nil then return end
	if pawn.bInCombatStance then
		isWeaponDrawn=true
	else isWeaponDrawn=false
	end
end
 function UpdateSprintStatus()

	if lShoulder and ThumbLY >=28000  then 
		isSprinting=true
	end
	if   ThumbLY<15000 then
			isSprinting=false
	end
	
end		




	Diff_Vector_LR=	{}--	 right_hand_component:K2_GetComponentLocation() - left_hand_component:K2_GetComponentLocation()
    Diff_Rotator_LR={}-- 	kismet_math_library:Conv_VectorToRotator(Diff_Vector_LR)
	Diff_Vector_HR= {}--	right_hand_component:K2_GetComponentLocation() - hmd_component:K2_GetComponentLocation()
    Diff_Rotator_HR={}--	 kismet_math_library:Conv_VectorToRotator(Diff_Vector_HR)
	RightRotator =	{}-- right_hand_component:K2_GetComponentRotation()
	LeftRotator =	{}--left_hand_component:K2_GetComponentRotation()
	HmdRotator =	{}-- hmd_component:K2_GetComponentRotation()
	RHandLocation=	{}--right_hand_component:K2_GetComponentLocation()
	LHandLocation=	{}--left_hand_component:K2_GetComponentLocation()
	HmdLocation=	{}-- hmd_component:K2_GetComponentLocation()	












function CalculateHelperVectors()
if hmd_component==nil or right_hand_component== nil then return end
	Diff_Vector_LR= right_hand_component:K2_GetComponentLocation() - left_hand_component:K2_GetComponentLocation()
    Diff_Rotator_LR= kismet_math_library:Conv_VectorToRotator(Diff_Vector_LR)
	Diff_Vector_HR= right_hand_component:K2_GetComponentLocation() - hmd_component:K2_GetComponentLocation()
    Diff_Rotator_HR= kismet_math_library:Conv_VectorToRotator(Diff_Vector_HR)
	RightRotator = right_hand_component:K2_GetComponentRotation()
	LeftRotator =left_hand_component:K2_GetComponentRotation()
	HmdRotator = hmd_component:K2_GetComponentRotation()
	RHandLocation=right_hand_component:K2_GetComponentLocation()
	LHandLocation=left_hand_component:K2_GetComponentLocation()
	HmdLocation= hmd_component:K2_GetComponentLocation()	
end		

function CustomInput(pawn,dDelta)
	if pawn==nil then return end
	--VecY =  pawn.Mesh:GetRightVector() 
	--VecY.X = VecY.X * ThumbLY/32767
	--VecY.Y = VecY.Y * ThumbLY/32767
	--VecY.Z = VecY.Z * ThumbLY/32767 
	----VecX = pawn.Mesh:GetForwardVector()
	--VecX.X = VecX.X * (-ThumbLX/32767)
	--VecX.Y = VecX.Y * (-ThumbLX/32767)
	--VecX.Z = VecX.Z * (-ThumbLX/32767)
	--UE5.5.4 fix:
	local CurrentYaw = pawn.Controller.ControlRotation.Yaw
	VecY ={}
	VecY.Y = math.sin(CurrentYaw/180*math.pi)  * ThumbLY/32767
	VecY.X = math.cos(CurrentYaw/180*math.pi)  * ThumbLY/32767
	VecX ={}
	VecX.Y = math.cos((CurrentYaw)/180*math.pi) * (ThumbLX/32767)
	VecX.X = math.sin((CurrentYaw+180)/180*math.pi) * (ThumbLX/32767)
	VecNew ={}
	VecNew.X = VecY.X+VecX.X
	VecNew.Y = VecY.Y+VecX.Y
	local Factor = 300000
	Vector3d.new(VecNew.X*Factor,VecNew.Y*Factor,0)
	
	--pawn:AddMovementInput(VecNew,Factor,true)
	pawn.CapsuleComponent:AddForce(VecNew,"Root",true)--.ControlInputVector.X = VecNew.X
	print(VecNew.X)
	--pawn:AddForce(--.ControlInputVector.Y = VecNew.Y
end
 
 
function RotateMesh(pawn)
	if pawn==nil then return end
	if pawn.Mesh~=nil  and hmd_component~=nil then
		local Rot = hmd_component:K2_GetComponentRotation()
		Rot.Pitch= 0
		Rot.Roll=0
		Rot.Yaw = Rot.Yaw-90
--		pawn.Mesh:K2_AttachToComponent(hmd_component," ",2,2,0,true)
--		
--		local Def_trans = pawn.Mesh:GetSocketTransform("Head",2)
--		local loc_Diff  = kismet_math_library:Subtract_VectorVector(
--			Def_trans.Translation, Vector3f.new(0,0,0)
--			)
--		
--		
--		local lossy_offset = Vector3f.new(loc_Diff.y-GetHmdTiltOffset(Rot), loc_Diff.z+GetHmdTiltOffset(Rot), -loc_Diff.x)
--		UEVR_UObjectHook.get_or_add_motion_controller_state(pawn.Mesh):set_hand(2)
--		  UEVR_UObjectHook.get_or_add_motion_controller_state(pawn.Mesh):set_location_offset(lossy_offset)
--		  UEVR_UObjectHook.get_or_add_motion_controller_state(pawn.Mesh):set_rotation_offset(Vector3f.new(Rot.x/180*math.pi,math.pi/2,Rot.Roll/180*math.pi))
		  pawn.Mesh:HideBoneByName("Head",0)
		
		pawn.Mesh:K2_SetWorldRotation(Rot, false, {},true)
		--pawn.Mesh.RelativeRotation.Yaw=0
		return Rot
	end
	
end
 
function GetCurrentWeaponMesh(dpawn)
	--local function update_weapon_offset(Body_mesh)
	
    if not dpawn and not dpawn.WeaponsPairingComponent then print("nil") return end
	
	
   -- local attach_socket_name = weapon_mesh.AttachSocketName
		local PairingComponent= pawn.WeaponsPairingComponent
	
		local WeaponMesh=nil
	
	--x=pitch 
	--local PairingComponentsOut = {}
	
	
	
	
	
	
	
		--ResetShotArrows()
		if not isRiding then
			if PairingComponent.WeaponActor~=nil then
				if PairingComponent.WeaponActor.MainStaticMeshComponent ~=nil then
					if PairingComponent ~=nil then
					local WpnACtor = PairingComponent:GetEquippedWeaponActor()
						if WpnACtor~=nil and WpnACtor.MainStaticMeshComponent~=nil then
						WeaponMesh=PairingComponent:GetEquippedWeaponActor().MainStaticMeshComponent
						--UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_hand(1)
						--UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_rotation_offset(Vector3f.new(0,-30/190*math.pi,-math.pi/2))
						--UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_location_offset(Vector3f.new(0.5,0,1.5))
						--print("foundWeapon")
							if isWeaponDrawn then 
						--		WeaponMesh:SetVisibility(true)
						--		UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_permanent(true)
						--	else WeaponMesh:SetVisibility(false)
						--		UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_permanent(false)
							end
							--UEVR_UObjectHook.get_or_add_motion_controller_state(WeaponMesh):set_permanent(true)
						end
					end
					--if PairingComponent.WeaponActor.ScabbardMeshComponent ~= nil then
					--	ScabbardMesh=PairingComponent.WeaponActor.ScabbardMeshComponent
					--if isWeaponDrawn then
					--	ScabbardMesh:SetVisibility(false)
					--end
				end	
			end
		end	
		return WeaponMesh
	
end
 
 

function HandleCamera()
	local pawn = api:get_local_pawn(0)
	local player =api:get_player_controller(0)
	if pawn ~=nil and UEVR_UObjectHook.exists(hmd_component) then
	--local RotatorXYZ= right_hand_component:K2_GetComponentRotation()
			local RotatorHMD= 	hmd_component:K2_GetComponentRotation()
			HmdVector=hmd_component:GetForwardVector()
			HandVector= right_hand_component:GetForwardVector()
			
			local HmdXY= hmd_component:K2_GetComponentRotation()
		
		
			player:ClientSetRotation(RotatorHMD,false)
	
			SnapAngle = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))
			if SnapTurn  then
				if StickR.x >0.2 and RXState ==0  then
					DecoupledYawCurrentRot =DecoupledYawCurrentRot + SnapAngle
					RXState=1
				elseif StickR.x <-0.2 and RXState ==0   then
					DecoupledYawCurrentRot =DecoupledYawCurrentRot - SnapAngle
					RXState=1
				elseif StickR.x <= 0.200 and StickR.x >=-0.200  then
					RXState=0
				end
		
			
			else
				
				SmoothTurnRate = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))/90
			
			
				local rate = StickR.x
							rate =  rate*rate*rate
				if StickR.x >0.1 and not isMenu and not TactiNavVisible then
					DecoupledYawCurrentRot =DecoupledYawCurrentRot + SmoothTurnRate * rate
					
				elseif StickR.x <-0.1 and not isMenu and not TactiNavVisible  then
					DecoupledYawCurrentRot =DecoupledYawCurrentRot + SmoothTurnRate * rate
				
				end
			end
		end
--print(DecoupledYawCurrentRot)

end
 
 
 function GetPlayerValues(dpawn)
	if dpawn==nil then return end
	if StatsComp== nil then StatsComp= UEVR_UObjectHook.get_first_object_by_class(Stats_C,false) end
	if StatsComp==nil then return 0 end
	local Health  =0
	local Magicka =0
	local Stamina =0
	
	Health  =	StatsComp.Health.CurrentValue
	Stamina =	StatsComp.Fatigue.CurrentValue
	Magicka =	StatsComp.Magicka.CurrentValue
	
	local ValVec = {}
--	if StatsComp~=nil then
		ValVec.Health = Health
		ValVec.Magicka = Magicka
		ValVec.Stamina = Stamina
--	end
	return ValVec
end
	
	
 
 
 function GetStats(dpawn)
	if GetCurrentWeaponMesh(dpawn) == nil then return {} end
	--if StatsComp== nil then StatsComp= UEVR_UObjectHook.find_first_of(Stats_C,false)
	local Stats ={}
	local WeaponPrimary = GetCurrentWeaponMesh(dpawn)-- dpawn.m_CarryComponent:GetItemVisual()
	local WeaponSecondary = nil--dpawn.m_CarryComponent:GetSecondaryWeaponEquipment()
	local WeaponRange = nil--dpawn.m_CarryComponent:GetRangedWeaponEquipment()

	local WFac1	= 0--WeaponPrimary.SpawnedActorInstance
	local WFac2 = 0

--	if WeaponPrimary.SpawnedActorInstance~=nil then
--		WFac1 = WeaponPrimary.SpawnedActorInstance:GetComponentByClass(AtriClass).SpawnedAttributes[5].Weight.CurrentValue
--	--	print(WeaponPrimary.SpawnedActorInstance:get_full_name())
--	end
--	if WeaponSecondary~=nil and WeaponSecondary.SpawnedActorInstance~=nil and dpawn.Mesh.AnimScriptInstance.CachedMeleeStance==2 then
--		WFac2 = WeaponSecondary.SpawnedActorInstance:GetComponentByClass(AtriClass).SpawnedAttributes[5].Weight.CurrentValue
--		
----	print(WeaponSecondary.SpawnedActorInstance:get_full_name())
--	
--	end
	
	
	local CurrentWeaponWeight = WFac1 + WFac2
	--local AtriComp = dpawn:GetComponentByClass(AtriClass)
	local NeededStrength = WeaponPrimary.Item.m_StartRegenerateSc
	local Strength = dpawn.m_CharacterState.AbilitySystemComponent:GetAttributeCurrentValueChecked(AtriStr_C,"Strength")
	--print(Strength)
	Stats.Str = Strength
	Stats.WpnWt= CurrentWeaponWeight
	Stats.ReqStr = NeededStrength
	
	if DebugStats then
		--print(CurrentWeaponWeight)
		--print(Strength)	
		print(WeaponPrimary.SpawnedActorInstance:get_full_name())
		print(WeaponSecondary.SpawnedActorInstance:get_full_name())
	end
	return Stats
end
 
 ConstraintActor= nil
 AffectedMesh=nil
 AnchorMesh=nil
 AffectedMeshL =nil
AnchorMeshL=nil
 AnchorMesh_parent = nil
 right_hand_Constraint=nil
 right_hand_Constraint_parent=nil
 SendBlock=false
 SendAttack=false
 ACount=0
 isAttacking=false
 isBlocking=false
 CurrWpnM =nil
 CurrentCollision = nil
 
 right_hand_pos_Pretick = Vector3f.new(0,0,0)
