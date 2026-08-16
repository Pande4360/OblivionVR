local controllers = require('libs/controllers')
--require(".\\Main\\MainHandler")
require(".\\Subsystems\\MeleePower")
require(".\\Subsystems\\GlobalData")

require(".\\Subsystems\\GlobalDataCustom")
--require(".\\Main\\MeleeCombat")
require(".\\Subsystems\\HelperFunctions")






local ReusableHit={}




--	if PhysicsComp and not Grabbed then
--	--Grabbed=true
--		--PhysicsComp:GrabComponentAtLocationWithRotation(AffectedMesh, " ", dpawn:K2_GetActorLocation() + dpawn:GetActorForwardVector()*100 +dpawn:GetActorUpVector()*100,dpawn:K2_GetActorRotation())
--		--PhysicsComp:SetLinearDamping(2)
--		--PhysicsComp:SetLinearStiffness(2)
--		--PhysicsComp:SetAngularDamping(2)
--		--PhysicsComp:SetAngularStiffness(2)
--		
--		--AffectedMesh:SetLinearDamping(0)
--	end
	
		
	
		
	
		
		
		
	--	AnchorMesh:SetMassOverrideInKg("",		1000,true)
	--	AnchorMesh:SetMassScale("",				1)
	--	AnchorMesh:SetCollisionEnabled(1)
	--	
	--	--AnchorMesh:SetSimulatePhysics(false)
	--	AffectedMesh:SetShouldUpdatePhysicsVolume(true)
	--	AffectedMesh:SetMassOverrideInKg("",10000.1,true)
	--	AffectedMesh:SetAllMassScale(		1.1)
	
		--AnchorMesh:K2_SetWorldLocation(AnchorMesh:K2_GetComponentLocation(),false,ReusableHit,false)	
		




--local  ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
local zero_transform = StructObject.new(ftransform_c)
local zero_transform1 = {} 
 
 --local AtriClass = find_required_object("Class /Script/LOTF2.AnathemaAbilitySystemComponent")
 --local AtriSet_C = find_required_object("Class /Script/LOTF2.AttributesAttributeSet")




--INIT
	local dpawn=nil	
	dpawn=api:get_local_pawn(0)	

local TrueMeshLast = nil


	
local function SetMesh(pawn)

	if TrueMesh~=nil then
		TrueMesh = GetCurrentWeaponMesh(pawn)
		for i = 1, 30 ,1 do
			TrueMesh:SetCollisionResponsToChannel(i,i)
			end
		
		--TrueMesh:SetCollisionEnabled(1)
		
		
		
	end	
end
	--AffectedMesh:DetachFromParent(true)
function CreatePhysicsHandleLogic(dpawn,world_context)


	if dpawn == nil then return end
		--if not string.find(dpawn:get_full_name(), "AnathemaPlayerCharacter")  then return end
		local WpnMesh =GetCurrentWeaponMesh(dpawn)
		if WpnMesh==nil then return end
		--right_hand_component= controllers.getController(1)
		if right_hand_component~=nil then
					
			--return right_hand_Constraint
		--else 
		--	right_hand_component =	controllers.createController(1)
		end
		
		
		ConstraintActor = Statics:BeginDeferredActorSpawnFromClass(world_context, actor_c,zero_transform, 1, nil)
		
		local CurrentWpnBP = WpnMesh:get_outer()
		local ConstraintAttach= right_hand_component:get_outer()
		AffectedMesh =nil
		--AnchorMesh=nil
		right_hand_Constraint=nil
		
			
		AffectedMesh = ConstraintActor:AddComponentByClass(staic_mesh_component_c, false, zero_transform1, false)
		
		AffectedMesh:SetStaticMesh(plane)
		
		local Comps3 = dpawn:K2_GetComponentsByClass(PhysicsComp_C)
		if Comps3~=nil and  #Comps3 > 0 then
			right_hand_Constraint = Comps3[1]
		else
			right_hand_Constraint =  dpawn:AddComponentByClass(PhysicsComp_C, false, zero_transform1, false)	
		end
		--AffectedMesh:K2_AttachToComponent(right_hand_component," ", 2,2,0,true)
		--right_hand_Constraint:K2_AttachToComponent(right_hand_component," ", 2,2,0,true)
		
		AffectedMesh.RelativeScale3D.X = 1.1
		AffectedMesh.RelativeScale3D.Y = 1.1
		AffectedMesh.RelativeScale3D.Z = 1.1
		AffectedMesh.RelativeRotation.Pitch= -40
	--	AffectedMesh.RelativeLocation.X  =0
	--	AffectedMesh.RelativeLocation.Y  =0
	--	AffectedMesh.RelativeLocation.Z  =0
		
	
		
		
		--AffectedMesh.BodyInstance.bAutoWeld=false
		--PhysMat = find_required_object("PhysicalMaterial /Game/Art/Materials/PhysicalMaterials/Metal.Metal")
		--AnchorMesh:SetPhysMaterialOverride(PhysMat)
		--AffectedMesh:SetPhysMaterialOverride(PhysMat)
		
		--AffectedMesh:SetShouldUpdatePhysicsVolume(true)
		--AffectedMesh:SetMassOverrideInKg("",0.001,true)
	--	AffectedMesh:SetAllMassScale(		0.001)
		
		
		AffectedMesh:SetEnableGravity(false)
		print("ConstraineMesh Configured")
end
	

 function CreateConstraintLogic(dpawn,world_context)	
		if dpawn == nil then return end
		
		local HandActor = nil
		local actor = nil
		if right_hand_component~=nil then
			HandActor = right_hand_component:get_outer()
		
		
		local zero_transform = StructObject.new(ftransform_c)
		

			local ConstraintAttach= right_hand_component:get_outer()
		AffectedMesh =nil
		AnchorMesh=nil
		AnchorMesh_parent=nil
		right_hand_Constraint=nil
		right_hand_Constraint_parent= nil
		
		left_hand_Constraint=nil
		AffectedMeshL =nil
		AnchorMeshL=nil
		--AnchorMesh_parentL=nil
		--right_hand_ConstraintL=nil
		--right_hand_Constraint_parentL= nil
		
		actor = Statics:BeginDeferredActorSpawnFromClass(world_context, actor_c,zero_transform, 1, nil)
		actorL = Statics:BeginDeferredActorSpawnFromClass(world_context, actor_c,zero_transform, 1, nil)
		ConstraintActor = actor
		
		 
		 actor:SetTickGroup(0)
		AffectedMesh = actor:AddComponentByClass(staic_mesh_component_c, false, zero_transform1, false) --CANNOT BE ON WEAPON BP
		AffectedMeshL = actorL:AddComponentByClass(staic_mesh_component_c, false, zero_transform1, false)
		
		AnchorMesh = pawn:AddComponentByClass(VHitSphereClass, false, zero_transform1, false)	
		AnchorMeshL = pawn:AddComponentByClass(VHitSphereClass, false, zero_transform1, false)
		AnchorMesh:SetMassOverrideInKg("None",1,true)
	
		AnchorMesh_parent= actor:AddComponentByClass(VHitBoxClass, false, zero_transform1, false)
	
		Statics:FinishSpawningActor(actor, zero_transform)
		
		local Comps1 = dpawn:K2_GetComponentsByClass(staic_mesh_component_c)
		
		if Comps1~=nil and  #Comps1 > 0 then
		
		end
		print("weapon attached")
		plane = find_required_object_no_cache(Mesh_C, "StaticMesh /Engine/BasicShapes/Cube.Cube")
		
		AffectedMesh:SetStaticMesh(plane)
		AffectedMeshL:SetStaticMesh(plane)
		if AnchorMesh == nil then  print("anchor not found") return end
		
			print("right Constraint attached")
			local Comps3 = actor:K2_GetComponentsByClass(PhysicsConstraint_C)
			if Comps3~=nil and  #Comps3 > 1 then				
				right_hand_Constraint = Comps3[1]				
				right_hand_Constraint_parent = Comps3[2]				
				print(right_hand_Constraint:GetOwner():get_full_name())
			else
				right_hand_Constraint =  actor:AddComponentByClass(PhysicsConstraint_C, false, zero_transform1, false)				
				right_hand_Constraint_parent =  actor:AddComponentByClass(PhysicsConstraint_C, false, zero_transform1, false)
				
			end
			local Comps4 = actorL:K2_GetComponentsByClass(PhysicsConstraint_C)
			if Comps4~=nil and  #Comps4 > 1 then				
				left_hand_Constraint = Comps4[1]				
				--right_hand_Constraint_parent = Comps4[2]				
				--print(right_hand_Constraint:GetOwner():get_full_name())
			else
				left_hand_Constraint =  actorL:AddComponentByClass(PhysicsConstraint_C, false, zero_transform1, false)				
				--right_hand_Constraint_parent =  actor:AddComponentByClass(PhysicsConstraint_C, false, zero_transform1, false)
				
			end
		--end
		--AffectedMesh:AddTickPrerequisiteComponent(right_hand_Constraint)
		--print(AffectedMesh:get_full_name())
		--print(AnchorMesh:get_full_name())	
		--print(right_hand_Constraint:get_full_name())
		--print(right_hand_Constraint_parent:get_full_name())
		end
end		
		
function ConfigureConstrainMeshes(bShow,ARel, BRel)		
		
		
		
	if not ARel or not BRel then	
		if not bShow then
			--AnchorMesh.bHiddenInGame=true
			AffectedMesh.bHiddenInGame=true
		else 
				AffectedMesh.bHiddenInGame=false
				AffectedMesh:SetVisibility(true,true)
		end
		if AnchorMesh~=nil then
		AnchorMesh.RelativeLocation.Z= 0
		AnchorMesh.RelativeLocation.X= 0
		AnchorMesh.RelativeScale3D.X = 0.01
		AnchorMesh.RelativeScale3D.Y = 0.01
		AnchorMesh.RelativeScale3D.Z = 0.01
		AnchorMeshL.RelativeLocation.Z= 0
		AnchorMeshL.RelativeLocation.X= 0
		AnchorMeshL.RelativeScale3D.X = 0.01
		AnchorMeshL.RelativeScale3D.Y = 0.01
		AnchorMeshL.RelativeScale3D.Z = 0.01
		
		AnchorMesh_parent.RelativeScale3D.X = 0.01
		AnchorMesh_parent.RelativeScale3D.Y = 0.01
		AnchorMesh_parent.RelativeScale3D.Z = 0.01
		--AnchorMesh.BodyInstance.bAutoWeld=false
		
		
		--AnchorMesh:SetCollisionProfileName("IgnoreAll")--SetCollisionEnabled(1)
		AnchorMesh_parent:SetCollisionProfileName("IgnoreAll")
		AnchorMesh_parent:SetSimulatePhysics(false)
			AnchorMesh_parent:SetCollisionResponseToChannel(4,0)
			AnchorMesh_parent:SetCollisionResponseToChannel(2,0)
			AnchorMesh_parent:SetCollisionResponseToChannel(28,0)
		AnchorMesh_parent:SetCollisionResponseToChannel(1,0)
		
	--	AnchorMesh:SetCollisionResponseToChannel(4,0)
	--	AnchorMesh:SetCollisionResponseToChannel(2,0)
	--	AnchorMesh:SetCollisionResponseToChannel(28,0)
	--	AnchorMesh:SetCollisionResponseToChannel(1,0)
		--AnchorMesh:SetTickGroup(0)
		AnchorMesh.BodyInstance.bAutoWeld=false
		AnchorMeshL.BodyInstance.bAutoWeld=false
		--AnchorMesh:AddTickPrerequisiteActor(AnchorMesh:GetOwner())
		
		AffectedMesh:SetCollisionObjectType(30)
		AffectedMeshL:SetCollisionObjectType(31)
		
		
		--AffectedMesh.RelativeScale3D.X = 2
		--AffectedMesh.RelativeScale3D.Y = 2
		--AffectedMesh.RelativeScale3D.Z = 2
		--AffectedMesh.RelativeRotation.Pitch= 40
		
		
				AffectedMesh:SetTickGroup(2)
				AffectedMesh:AddTickPrerequisiteComponent(right_hand_Constraint)
				AnchorMesh:SetTickGroup(0)
				
				right_hand_Constraint:SetTickGroup(2)
				right_hand_Constraint:AddTickPrerequisiteComponent(AnchorMesh)
				right_hand_Constraint.PrimaryComponentTick.EndTickGroup=2
				
				AffectedMeshL:SetTickGroup(2)
				AffectedMeshL:AddTickPrerequisiteComponent(left_hand_Constraint)
				AnchorMeshL:SetTickGroup(0)				
				left_hand_Constraint:SetTickGroup(2)
				left_hand_Constraint:AddTickPrerequisiteComponent(AnchorMeshL)
				left_hand_Constraint.PrimaryComponentTick.EndTickGroup=2
							--AffectedMesh:SetOwnerNoSee(true)
		
		end
		
		
	--	AffectedMesh.RelativeLocation.X  =0
	--	AffectedMesh.RelativeLocation.Y  =0
	--	AffectedMesh.RelativeLocation.Z  =0
	--	AffectedMesh:SetTickGroup(0)
		--AffectedMesh:AddTickPrerequisiteActor(AffectedMesh:GetOwner())
		
		
		--AffectedMesh.BodyInstance.bAutoWeld=false
		--PhysMat = find_required_object("PhysicalMaterial /Game/Art/Materials/PhysicalMaterials/Metal.Metal")
		--AnchorMesh:SetPhysMaterialOverride(PhysMat)
		--AffectedMesh:SetPhysMaterialOverride(PhysMat)
		
		--AffectedMesh:SetShouldUpdatePhysicsVolume(true)
	--	AnchorMesh:SetMassOverrideInKg("None",10.001,true)
	--	AnchorMeshL:SetMassOverrideInKg("None",10.001,true)
	--	
	--	AffectedMesh:SetMassOverrideInKg("Root",0.1,true)
	--	AffectedMesh:SetAllMassScale(		1.0)
	--	AffectedMesh:SetSimulatePhysics(false)
	--	AffectedMesh:SetSimulatePhysics(true)
	--	AffectedMesh:SetEnableGravity(false)
	--	print("ConstraineMesh Configured")
	end
end
	

 function SetPhysicsHandlerAttachLogic(dpawn)
		local WpnMesh =GetCurrentWeaponMesh(dpawn)
		--AffectedMesh:K2_AttachToComponent(right_hand_component," ", 2,2,0,true)
		--right_hand_Constraint:K2_AttachToComponent(right_hand_component," ", 2,2,0,true)
		--WpnMesh:SetCollisionEnabled(0)
		
		WpnMesh.bAbsoluteScale=true
		--AnchorMesh:DetachFromParent(true)
		WpnMesh:DetachFromParent(true)
		WpnMesh:K2_AttachToComponent(AffectedMesh," ", 2,2,0,true)
		WpnMesh:SetCollisionEnabled(0)
		--
	
		
		WpnMesh.RelativeLocation.X  =0
		WpnMesh.RelativeLocation.Y  =0
		WpnMesh.RelativeLocation.Z  =0
 
		AffectedMesh:SetSimulatePhysics(false)	
		--AffectedMesh:SetCollisionEnabled(1)
		AffectedMesh:SetCollisionObjectType(30)
		AffectedMesh:SetCollisionProfileName("IgnoreAll")
		AffectedMesh:SetCollisionResponseToChannel(4,0)
		AffectedMesh:SetCollisionResponseToChannel(2,0)
 
		
 end

 function SetConstrainAttachLogic(dpawn)	
		AnchorMesh:K2_AttachToComponent(right_hand_component,"",2,2,0,false)
		AnchorMeshL:K2_AttachToComponent(left_hand_component,"",2,2,0,false)
		AnchorMesh.RelativeLocation.X=100
		
		AnchorMesh_parent:K2_AttachToComponent(hmd_component," ", 0,0,0,true)
		right_hand_Constraint:K2_AttachToComponent(AnchorMesh," ", 2,2,0,true)
		left_hand_Constraint:K2_AttachToComponent(AnchorMeshL," ", 2,2,0,true)
		right_hand_Constraint_parent:K2_AttachToComponent(hmd_component," ", 2,2,0,false)
		
		--UEVR_UObjectHook.get_or_add_motion_controller_state(AnchorMesh):set_hand(1)
		--UEVR_UObjectHook.get_or_add_motion_controller_state(AnchorMeshL):set_hand(0)
		
end


local AffectedItemLast = nil
local WpnHost=nil
local ReleaseCooldownR=0
local InitRelease=false
function SetItemToConstrain(dWpnMesh,Ddelta)
		
		
		
		local AfMesh = nil
		if dWpnMesh then
			AfMesh = dWpnMesh
		else
				
			--AfMesh= Item
		end
		
	--	if AfMesh~=  AffectedItemLast then
	--		if AffectedMesh.AttachChildren ~=nil then
	--			local Ar = AffectedMesh.AttachChildren
	--			for i, comp in ipairs(Ar) do
	--				if comp~= LHandM then
	--				comp:DetachFromParent(false,false)
	--				comp:SetSimulatePhysics(true)
	--				end
	--			end
	--		end
	--		AffectedItemLast= AfMesh
	--	end	
			
		
	--	AffectedMesh:SetSimulatePhysics(true)	
	--	AffectedMesh:SetTickGroup(0)
		if AfMesh~=nil and AfMesh.AttachParent~=AffectedMesh and dpawn.bInCombatStance and Grabbed then
			WpnHost = AfMesh.AttachParent
			AfMesh:SetVisibility(true,false)
			
			ReleaseCooldownR=0
		--	AfMesh:SetCollisionEnabled(0)
			--AfMesh:SetTickGroup(0)
			AfMesh.bAbsoluteScale=true
			--AnchorMesh:DetachFromParent(true)
			InitRelease=false
			--AfMesh:DetachFromParent(true)
			--AfMesh:K2_AttachToComponent(AffectedMesh," ", 2,2,0,true)
			--AfMesh:SetCollisionEnabled(0)
			--
			
			
			
			
		--	local BoxExtend= AfMesh.StaticMesh.ExtendedBounds.BoxExtent
		--						--AffectedMesh.bAbsoluteScale=true
		--						
		--	AffectedMesh.RelativeScale3D.X = 1/50*BoxExtend.X*0.7
		--	AffectedMesh.RelativeScale3D.Y = 1/50*BoxExtend.Z--BoxExtend.Y*0.5
		--	AffectedMesh.RelativeScale3D.Z = 1/50*BoxExtend.Y*0.8--*BoxExtend.Z
			--AfMesh:SetCollisionProfileName("IgnoreAll")	
			
			AfMesh:SetCollisionEnabled(2)
			AfMesh:SetCollisionProfileName("VPPhysicsActorIgnoreCamera")
			--AfMesh:SetCollisionResponseToAllChannels(0)
			AfMesh:SetCollisionResponseToChannel(30,0)
			AfMesh:SetCollisionResponseToChannel(31,2)
			AfMesh:SetCollisionResponseToChannel(4,0)
			AfMesh:SetCollisionResponseToChannel(1,0)
			AfMesh:SetCollisionResponseToChannel(2,0)
		
		
		
			AfMesh:SetEnableGravity(false)
			AfMesh.RelativeLocation.X  =0
			AfMesh.RelativeLocation.Y  =0
			AfMesh.RelativeLocation.Z  = 0---BoxExtend.Y
		--	AfMesh.RelativeRotation.Pitch = 90
			AfMesh.RelativeRotation.Roll = 90
		--	AfMesh.RelativeRotation.Yaw = 0
		elseif not Grabbed and  dpawn.bInCombatStance then
			ReleaseCooldownR=ReleaseCooldownR+Ddelta
			--AfMesh:DetachFromParent(false)
			if not InitRelease  then
				InitRelease=true
				AffectedMesh:SetCollisionResponseToChannel(5,0)
				--AfMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+Vector3d.new(10,0,0),false,ReusableHit,true)	
				local Rot= right_hand_component:K2_GetComponentRotation() 
				Rot.Yaw = Rot.Yaw-90
			--	AfMesh:K2_SetWorldRotation(Rot,false,ReusableHit,true)
				--AfMesh:SetCollisionEnabled(1)
				AfMesh:SetCollisionProfileName("VPPhysicsActorIgnoreCamera")	
				AfMesh:SetCollisionResponseToChannel(31,2)
				AfMesh:SetCollisionResponseToChannel(30,0)
				AfMesh:SetCollisionResponseToChannel(4,0)
				AfMesh:SetCollisionResponseToChannel(1,0)
				AfMesh:SetCollisionResponseToChannel(2,0)
				AfMesh:SetEnableGravity(true)
				--AfMesh:SetSimulatePhysics(true)
			AffectedMesh.RelativeScale3D.X = 1/50*15
		    AffectedMesh.RelativeScale3D.Y = 1/50*1
		    AffectedMesh.RelativeScale3D.Z = 1/50*10
		--	AffectedMesh:SetCollisionProfileName("IgnoreAll")
			end
			--if ReleaseCooldownR> 1 then
		

			--AfMesh:SetCollisionResponseToChannel(4,0)
			--AfMesh:SetCollisionResponseToChannel(2,0)
			--else
		--	AfMesh:SetCollisionProfileName("VPPhysicsActorIgnoreCamera")
			--end
			
		
		
		elseif not dpawn.bInCombatStance then
			
			--AfMesh:K2_AttachToComponent(WpnHost,"Weapon_Socket", 0,0,0,true)
			--AffectedMesh:K2_AttachToComponent(RHandM," ", 0,0,0,true)
			AffectedMesh.RelativeScale3D.X = 1/50*10
		    AffectedMesh.RelativeScale3D.Y = 1/50*1
		    AffectedMesh.RelativeScale3D.Z = 1/50*10
			
		end
		
		
		
		--AffectedMesh:SetCollisionEnabled(3)
		if RHandM~=nil then
			RHandM:SetCollisionProfileName("IgnoreAll")
		end
		AnchorMesh:SetCollisionProfileName("IgnoreAll")
		AffectedMesh:SetCollisionProfileName("IgnoreAll")
		RHandM:SetCollisionObjectType(30)
		--AffectedMesh:SetCollisionObjectType(2)
		AffectedMesh:SetCollisionResponseToChannel(4,0)
--		if AffectedMesh:GetCollisionProfileName():to_string()~= "IgnoreAll" then
--		for i = 15, 50,1 do
--			AffectedMesh:SetCollisionResponseToChannel(i,1)
--		end
--		end
		AffectedMesh:SetCollisionResponseToChannel(2,0)
	--	AffectedMesh:SetCollisionResponseToChannel(0,0)
		AffectedMesh:SetCollisionResponseToChannel(5,0)
		AffectedMesh:SetCenterOfMass(Vector3d.new(0,0,20),"Root")
		
		if LHandM~=nil then
			LHandM:SetCollisionProfileName("IgnoreAll")
		end
		AnchorMeshL:SetCollisionProfileName("IgnoreAll")
		AffectedMeshL:SetCollisionProfileName("IgnoreAll")
		LHandM:SetCollisionObjectType(30)
		--AffectedMesh:SetCollisionObjectType(2)
		AffectedMeshL:SetCollisionResponseToChannel(4,0)
--		if AffectedMesh:GetCollisionProfileName():to_string()~= "IgnoreAll" then
--		for i = 15, 50,1 do
--			AffectedMesh:SetCollisionResponseToChannel(i,1)
--		end
--		end
		AffectedMeshL:SetCollisionResponseToChannel(2,0)
	--	AffectedMesh:SetCollisionResponseToChannel(0,0)
		AffectedMeshL:SetCollisionResponseToChannel(5,2)
		AffectedMeshL:SetCenterOfMass(Vector3d.new(0,0,20),"Root")
		AffectedMeshL.RelativeScale3D.X = 1/50*1
		 AffectedMeshL.RelativeScale3D.Y = 1/50*20
		 AffectedMeshL.RelativeScale3D.Z = 1/50*6
		AffectedMeshL:SetVisibility(false,false)
		
	--	print("Setting AfMesh")	
	--	AffectedMesh:SetSimulatePhysics(true)	
		return AfMesh
end				
		

 Grabbed=false
local PawnLocLast = nil		
function CounterMoveAffected(pawn,dPos)
	if pawn==nil or right_hand_component==nil  then return end
	local FinalLoc=nil
	local FinalLocL=nil
	local PawnLoc = pawn:K2_GetActorLocation()--_GetComponentLocation()
	PawnLoc.Z = 0
	if PawnLocLast==nil then
		PawnLocLast=PawnLoc
	end
	local PawnLocDiff = kismet_math_library:Subtract_VectorVector(PawnLoc,PawnLocLast)
	--PawnLocLast = PawnLoc
	local AnchorMeshLoc = right_hand_component:K2_GetComponentLocation()
	local AnchorMeshLocL = left_hand_component:K2_GetComponentLocation()
--	local AffectedMeshLoc = AffectedMesh:K2_GetComponentLocation()
--	local AnchLocDiff = kismet_math_library:Subtract_VectorVector(AnchorMeshLoc,AffectedMeshLoc)
--	local AnchLocDist = math.sqrt(AnchLocDiff.x^2+AnchLocDiff.y^2+AnchLocDiff.z^2)
	
	
	if AffectedMesh~=nil  then
--		print("he")
	--	AffectedMesh:SetPhysicsLinearVelocity(PawnLocDiff*1000,true,"Root")--,{},false)
		--AffectedMesh:AddVelocityChangeImpulseAtLocation(PawnLocDiff*10000,AffectedMeshLoc,"Root")--,{},false)
		
		FinalLoc = AnchorMeshLoc+PawnLocDiff*1
		AnchorMesh:K2_SetWorldLocation(FinalLoc,false,{},false)
		FinalLocL = AnchorMeshLocL+PawnLocDiff*1
		AnchorMeshL:K2_SetWorldLocation(FinalLocL,false,{},false)
	end
	PawnLocLast=PawnLoc
	return PawnLocDiff
end		
 function ConfigureHandlerComp(dpawn)			
			
			local Stats = GetStats(dpawn)
			local StrDiff = (Stats.Str - Stats.ReqStr)
			if StrDiff>20 then StrDiff=20 end
			if StrDiff<0 then StrDiff=0 end
			local StrFactor = Stats.Str/Stats.ReqStr
			
			local AnchorMeshLoc = right_hand_component:K2_GetComponentLocation()
			local AffectedMeshLoc = AffectedMesh:K2_GetComponentLocation()
			local AnchLocDiff = kismet_math_library:Subtract_VectorVector(AnchorMeshLoc,AffectedMeshLoc)
			local AnchLocDist = math.sqrt(AnchLocDiff.x^2+AnchLocDiff.y^2+AnchLocDiff.z^2)
			
			
			
			
			local WpnMesh= GetCurrentWeaponMesh(dpawn)
			if right_hand_Constraint~=nil then	
				print("COnfighre ConstarintCOmp")
				local PowerMaxLinear		=((Stats.Str*1)/Stats.ReqStr + 20  * StrDiff/20	)
					--if PowerMaxLinear> 30 then PowerMaxLinear = 30 end
				local VeloMaxLinear 		= 1/AnchLocDist*10--PowerMaxLinear/Stats.ReqStr
				local MinPowerLinear 		=1
				local PowerMaxAngular	    =(Stats.Str*30) + 60*StrDiff/20
				local MinPowerAngular		=10
				local VeloMaxAngular		= 5-- PowerMaxAngular/10
				local PowerWantedAngular    =0
				
				right_hand_Constraint:SetLinearDamping(2) 	--break?
				right_hand_Constraint:SetLinearStiffness(5)	--max speed
				right_hand_Constraint:SetAngularDamping(50)
				right_hand_Constraint:SetAngularStiffness(155)
				right_hand_Constraint:SetInterpolationSpeed(10) --max accel
				--right_hand_Constraint.bIsVelocityDrive= true--:SetLinearDamping
				--right_hand_Constraint.bIsPositionDrive= false
				WpnMesh.RelativeLocation.Z=-WpnMesh.StaticMesh.ExtendedBounds.BoxExtent.Z*0.5
				WpnMesh.RelativeRotation.Pitch =0--42
				WpnMesh.RelativeRotation.Yaw   =0
				WpnMesh.RelativeRotation.Roll  =0
				--right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
				print("Costraint configured")
			end
			
end					


 function ConfigureConstraintComp(dpawn)			
			--if Get
			local WpnMesh= GetCurrentWeaponMesh(dpawn)
			
			local Stats = nil-- GetStats(dpawn)
			local StrDiff = nil--(Stats.Str - Stats.ReqStr)
			--if StrDiff>0 then StrDiff=0 end
			--if StrDiff<-10 or -StrDiff>Stats.Str then StrDiff=-10 end
			local StrFactor = nil --Stats.Str/Stats.ReqStr
			
			
			if WpnMesh~= nil then 	
				--Stats = GetStats(dpawn)
				--StrDiff = (Stats.Str - Stats.ReqStr)
			--	if StrDiff>0 then StrDiff=0 end
			--	if StrDiff<-10 or -StrDiff>Stats.Str then StrDiff=-10 end
			--	StrFactor = Stats.Str/Stats.ReqStr
			end
		--	local AnchorMeshLoc = right_hand_component:K2_GetComponentLocation()
		--	local AffectedMeshLoc = AffectedMesh:K2_GetComponentLocation()
		--	local AnchLocDiff = kismet_math_library:Subtract_VectorVector(AnchorMeshLoc,AffectedMeshLoc)
		--	local AnchLocDist = math.sqrt(AnchLocDiff.x^2+AnchLocDiff.y^2+AnchLocDiff.z^2)
			
			
			
			
			
			if right_hand_Constraint~=nil then	
				print("COnfighre ConstarintCOmp")
				local PowerMaxLinear		=800/100*100	--1000+(Stats.Str*700 + 700  * StrDiff	)
				local InForceLinear 		=40005/100*150 	--PowerMaxLinear/2 --(600 to 12000) --if PowerMaxLinear> 30 then PowerMaxLinear = 30 end
				local VeloMaxLinear 		=2000000--1/AnchLocDist*10--PowerMaxLinear/Stats.ReqStr
				local MinPowerLinear 		=1
				local PowerMaxAngular	    =160
				if WpnMesh~=nil then
				--	PowerMaxAngular = 15+ (Stats.Str*14) + 14*StrDiff
				end
				local MinPowerAngular		=10
				local VeloMaxAngular		=  PowerMaxAngular/10
				local PowerWantedAngular    =0
				right_hand_Constraint_parent:SetLinearXLimit(1,75)
				right_hand_Constraint_parent:SetLinearYLimit(1,75)
				right_hand_Constraint_parent:SetLinearZLimit(1,75)
				right_hand_Constraint_parent:SetAngularSwing1Limit(0,360)
				right_hand_Constraint_parent:SetAngularSwing2Limit(0,360)
				right_hand_Constraint_parent:SetAngularTwistLimit (0,360)
				right_hand_Constraint_parent:SetLinearVelocityDrive(false,false,false)
				right_hand_Constraint_parent:SetLinearPositionDrive(false,false,false)
				right_hand_Constraint_parent:SetDisableCollision(true)
				right_hand_Constraint_parent.ConstraintInstance.bScaleLinearLimits=false
				--right_hand_Constraint_parent:SetProjectionEnabled(false)
				right_hand_Constraint_parent.ConstraintInstance.ProfileInstance.LinearLimit.ContactDistance =100
				right_hand_Constraint_parent.ConstraintInstance.ProfileInstance.bParentDominates=false
				right_hand_Constraint_parent.ConstraintInstance.ProfileInstance.LinearLimit.bSoftConstraint=false
				
				right_hand_Constraint:SetDisableCollision(true)
				right_hand_Constraint.ConstraintActor1 = ConstraintActor
				right_hand_Constraint.ConstraintActor2 = ConstraintActor
				right_hand_Constraint.ConstraintInstance.ProfileInstance.LinearLimit.bSoftConstraint=false
							right_hand_Constraint.ConstraintInstance.bScaleLinearLimits=false
							
							right_hand_Constraint:SetLinearXLimit(0,0)
							right_hand_Constraint:SetLinearYLimit(0,0)
							right_hand_Constraint:SetLinearZLimit(0,0)
							right_hand_Constraint.ConstraintInstance.ProfileInstance.LinearLimit.ContactDistance =20000
							right_hand_Constraint.ConstraintInstance.ProfileInstance.LinearLimit.Stiffness =0
							right_hand_Constraint.ConstraintInstance.ProfileInstance.LinearLimit.Damping = 0
							right_hand_Constraint.ConstraintInstance.ProfileInstance.ContactTransferScale = 11001
							right_hand_Constraint.ConstraintInstance.ProfileInstance.LinearBreakThreshold = 0
				
			--	right_hand_Constraint:SetLinearXLimit(1,200)
			--	right_hand_Constraint:SetLinearYLimit(1,200)
			--	right_hand_Constraint:SetLinearZLimit(1,200)
				right_hand_Constraint:SetOrientationDriveSLERP(true)
				right_hand_Constraint:SetAngularVelocityDriveSLERP(true)
				right_hand_Constraint:SetAngularOrientationDrive(true,true)
				right_hand_Constraint:SetAngularDriveParams(PowerMaxAngular,VeloMaxAngular,00)		--(22,5,100)
				--right_hand_Constraint:SetLinearDriveParams(8000,1000,4000)
				right_hand_Constraint:SetLinearDriveParams(PowerMaxLinear,VeloMaxLinear,InForceLinear)	---(200,10,600000)  -- Stiffness,Damping,InForceLimit
			--	right_hand_Constraint:SetLinearVelocityDrive(false,false,false)
			--	right_hand_Constraint:SetLinearPositionDrive(false,false,false)
				right_hand_Constraint:SetLinearVelocityDrive(true,true,true)
				right_hand_Constraint:SetLinearPositionDrive(true,true,true)
	--			right_hand_Constraint:SetLinearPlasticity(false,10,1)  -- trheshold, type
	--			
	--			
				--right_hand_Constraint:SetProjectionEnabled(false)
			--	right_hand_Constraint:SetProjectionParams(11.1,.1,11.2,.10)
	--			
	--			
	--			--right_hand_Constraint:SetContactTransferScale(0)
				left_hand_Constraint:SetLinearXLimit(0,0)
				left_hand_Constraint:SetLinearYLimit(0,0)
				left_hand_Constraint:SetLinearZLimit(0,0)
				
	
	
				left_hand_Constraint:SetAngularSwing1Limit(0,20)
				left_hand_Constraint:SetAngularSwing2Limit(0,20)
				left_hand_Constraint:SetAngularTwistLimit (0,20)
				
					--	left_hand_Constraint:SetLinearXLimit(1,200)
			--	left_hand_Constraint:SetLinearYLimit(1,200)
			--	left_hand_Constraint:SetLinearZLimit(1,200)
				left_hand_Constraint:SetOrientationDriveSLERP(true)
				left_hand_Constraint:SetAngularVelocityDriveSLERP(true)
				left_hand_Constraint:SetAngularOrientationDrive(true,true)
				left_hand_Constraint:SetAngularDriveParams(PowerMaxAngular,VeloMaxAngular,00)		--(22,5,100)
				left_hand_Constraint.ConstraintInstance.ProfileInstance.LinearLimit.bSoftConstraint=false
				left_hand_Constraint.ConstraintInstance.bScaleLinearLimits=false
				
				--left_hand_Constraint:SetLinearDriveParams(8000,1000,4000)
				left_hand_Constraint:SetLinearDriveParams(PowerMaxLinear,VeloMaxLinear,InForceLinear)	---(200,10,600000)  -- Stiffness,Damping,InForceLimit
			--	left_hand_Constraint:SetLinearVelocityDrive(false,false,false)
			--	left_hand_Constraint:SetLinearPositionDrive(false,false,false)
				left_hand_Constraint:SetLinearVelocityDrive(false,false,false)
				left_hand_Constraint:SetLinearPositionDrive(true,true,true)
	--			left_hand_Constraint:SetLinearPlasticity(false,10,1)  -- trheshold, type
	--			
	--			
				--left_hand_Constraint:SetProjectionEnabled(false)
			--	left_hand_Constraint:SetProjectionParams(11.1,.1,11.2,.10)
	--			
	--			
	--			--left_hand_Constraint:SetContactTransferScale(0)
				left_hand_Constraint:SetAngularSwing1Limit(0,20)
				left_hand_Constraint:SetAngularSwing2Limit(0,20)
				left_hand_Constraint:SetAngularTwistLimit (0,20)
				
				
				
				
				
				
				
				
				
				
				
				
				
				
		if WpnMesh~=nil then
				WpnMesh.RelativeRotation.Pitch =0
				WpnMesh.RelativeRotation.Yaw   =0
				WpnMesh.RelativeRotation.Roll  =0
		end
				--right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
				print("Costraint configured")
			end
			
end					


	
local MeshLocLast= Vector3d.new(0,0,0)

local isActive = false
local EmptyHandInit= false
local PreRot = nil
function UpdateHandMeshLogic(pawn,WpnMesh)
	if RHandM==nil then return end
	if AffectedMesh==nil or WpnMesh==nil then return end
	
	--	local WpnMesh= GetCurrentWeaponMesh(pawn)
	if Grabbed and  dpawn.bInCombatStance and RHandM~=nil  then
		PreRot = RHandM.RelativeRotation
		
		RHandM:K2_AttachToComponent(WpnMesh,"Socket_Start",2,2,0,false)
		RHandM.RelativeRotation.Pitch = -90--PreRot.Pitch
			RHandM.RelativeRotation.Yaw = -90
			RHandM.RelativeRotation.Roll = 0
			RHandM.RelativeLocation.X = -7 
			RHandM.RelativeLocation.Y = 10 
			RHandM.RelativeLocation.Z = 0 
	elseif not Grabbed and  dpawn.bInCombatStance then
		--if PreRot~=nil then
			
			--RHandM:K2_AttachToComponent(AffectedMesh,"",2,2,0,false)
			--RHandM.bAbsoluteScale=false
			RHandM.RelativeRotation.Pitch =0 --PreRot.Pitch
			RHandM.RelativeRotation.Yaw = -90
			RHandM.RelativeRotation.Roll = 0--PreRot.Roll
			RHandM.RelativeLocation.X = -30 
			RHandM.RelativeLocation.Y = 0 
			RHandM.RelativeLocation.Z = 0 
		--end
	end	
	--AffectedMeshL.RelativeScale3D.X = 1
	--AffectedMeshL.RelativeScale3D.Y = 1
	--AffectedMeshL.RelativeScale3D.Z = 1
	--LHandM:K2_AttachToComponent(AffectedMeshL,"",2,2,0,true)
	--LHandM.bAbsoluteScale=false
	--LHandM.RelativeRotation.Pitch =0 --PreRot.Pitch
	--LHandM.RelativeRotation.Yaw = -90
	--LHandM.RelativeRotation.Roll = 0--PreRot.Roll
	--LHandM.RelativeLocation.X = -30 
	--LHandM.RelativeLocation.Y = 0 
	--LHandM.RelativeLocation.Z = 0 
	
	
	
end
local GrabbedL=false
function UpdatePhysicsConstraintLogic(pawn,world_context,ddelta)
		if pawn~=nil and LHandM ~=nil then	
			
			--print("starting")
			local WpnMesh= GetCurrentWeaponMesh(pawn)
			UpdateHandMeshLogic(pawn,WpnMesh)
			
			if (AffectedMesh== nil or AnchorMesh==nil) 	then
				--print("found wpn and isnt attahced")
				--print(WpnMesh.AttachParent== pawn.Mesh)
				
				--
				--for i = 1, 30 ,1 do
				--WpnMesh:SetCollisionResponseToChannel(i,0)
				--end
				
					CreateConstraintLogic(pawn,world_context)	
				if AnchorMesh ~=nil and AffectedMesh~=nil and right_hand_Constraint~= nil then-- and right_hand_component~=nil then
				--	print("Continued attach")
					SetConstrainAttachLogic(pawn)
					ConfigureConstrainMeshes(false,nil,nil)						
					ConfigureConstraintComp(pawn)
				--	right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
				end
				
				TrueMeshLast=WpnMesh
			elseif WpnMesh==nil then
				TrueMeshLast=nil
			end
			
			local newHit ={}
			--if not Grabbed then
				--print(rShoulder)
			if AnchorMesh ~=nil and AffectedMesh~=nil and WpnMesh~=nil then		
				--print("done")
				
				--pawn:AddTickPrerequisiteComponent(right)
				if Grabbed then
					WpnMesh:WakeAllRigidBodies()
				end
				--WpnMesh:SetTickGroup(0)
				--WpnMesh:SetMassOverrideInKg("None",0.001,true)
				--WpnMesh:AddTickPrerequisiteComponent(right_hand_Constraint)
				--pawn.GrabArmComponent:SetTickGroup(2)
				----pawn:SetTickGroup(0)
				
				
				local GrabbedItem = SetItemToConstrain(WpnMesh,ddelta)
				
				
				
				local CurCapVel = dpawn.CapsuleComponent:GetComponentVelocity()
				local CapsRot = dpawn.CapsuleComponent:K2_GetComponentRotation()
				if not Grabbed then
						--RHandM:DetachFromParent(false)
						--RHandM:K2_AttachToComponent(AffectedMesh,"",2,2,0,false)
						RHandM:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+AffectedMesh:GetRightVector()*0,false,ReusableHit,true)	
						--RHandM:K2_SetWorldRotation(AffectedMesh:K2_GetComponentRotation(),false,ReusableHit,true)
						local PreRot =AffectedMesh:K2_GetComponentRotation()
						local hand_quat = kismet_math_library:Conv_RotatorToQuaternion(PreRot)
						local offset_rot =AffectedMesh:K2_GetComponentRotation()
						offset_rot.Pitch=0
						offset_rot.Roll=0
						offset_rot.Yaw = -90
						--local offset_quat = kismet_math_library:Conv_RotatorToQuaternion(offset_rot)
						--local final_quat = kismet_math_library:Multiply_QuatQuat(hand_quat, offset_quat)
						--
						--local final_rot2 = kismet_math_library:Quat_RotateVector(offset_quat,PreRot)
						--	OffRot.Pitch=0
						--	OffRot.Roll=0
						--local FinalRot = kismet_math_library:ComposeRotators(PreRot,OffRot)
						RHandM:K2_SetWorldRotation(PreRot,false,ReusableHit,true)
						RHandM:K2_AddLocalRotation(offset_rot, false, ReusableHit, true)
						--AffectedMesh:WakeAllRigidBodies()
						--AffectedMesh:SetSimulatePhysics(true)
						--right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
						--right_hand_Constraint:SetConstraintReferencePosition(0,Vector3d.new(0,0,0))					
				
				end
				
				--local BoxExtend= WpnMesh.StaticMesh.ExtendedBounds.BoxExtent
				--			--AffectedMesh.bAbsoluteScale=true
				--AffectedMesh.RelativeScale3D.X = 1/50*BoxExtend.X*0.7
				--AffectedMesh.RelativeScale3D.Y = 1/50*BoxExtend.Y*0.5
				--AffectedMesh.RelativeScale3D.Z = 1/50*BoxExtend.Z
				
				
			
				
				
				--right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
				if right_hand_Constraint~= nil and UEVR_UObjectHook.exists(AffectedMesh) then
				--	print("done as well")
					
						--if right_hand_component then
						-- Get the world rotation of the hand anchor
						--	local hand_transform = right_hand_component:K2_GetComponentToWorld()
						--	
						--	local null_vector = Vector3d.new(0,0,0)
						--	local scale_vector = Vector3d.new(1,1,1)
						--	CapsRot.Pitch=0
						--	CapsRot.Roll=0
						--	local stable_transform = kismet_math_library:MakeTransform(null_vector, CapsRot, scale_vector)
						--	local testv = kismet_math_library:InverseTransformDirection(stable_transform,CurCapVel)
						--	
						--	print(testv.X)
						--	AnchorMesh:K2_SetWorldRotation(CapsRot,false,ReusableHit,true)
						--	right_hand_Constraint:SetLinearVelocityTarget(CurCapVel)
						--end
					if GrabbedItem ~= nil and dpawn.bInCombatStance then
					--	print("try grab wepn=")
						EmptyHandInit=false
					--	right_hand_Constraint:BreakConstraint()
					--	right_hand_Constraint_parent:BreakConstraint()
						
						if rShoulder then
							GrabbedItem:SetPhysicsLinearVelocity(CurCapVel,false,"None")
						end
						
						if rShoulder and not Grabbed then--
							Grabbed=true	
							--RHandM:WakeAllRigidBodies()
							--LHandM:WakeAllRigidBodies()
							SetItemToConstrain(WpnMesh,ddelta)
							ConfigureConstraintComp(pawn)
							AffectedMesh:SetEnableGravity(false)
							
						
							WpnMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+Vector3d.new(0,0,0),false,ReusableHit,true)	
							--WpnMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+Vector3d.new(0,0,0),false,ReusableHit,true)	
							local CurrentRRot = right_hand_component:K2_GetComponentRotation()	
							local hand_quat = kismet_math_library:Conv_RotatorToQuaternion(CurrentRRot)
							local offset_rot =right_hand_component:K2_GetComponentRotation()
							offset_rot.Pitch=0
							offset_rot.Roll=80
							offset_rot.Yaw = 80
							
							
							
							WpnMesh:K2_SetWorldRotation(offset_rot,false,ReusableHit,true)
							
							--right_hand_Constraint:AddTickPrerequisiteActor(pawn)
							--AffectedMesh.bAbsoluteLocation=true
							--GrabbedItem:SetSimulatePhysics(false)
							--AffectedMesh.BodyInstance.InertiaTensorScale.X=1
							--AffectedMesh.BodyInstance.InertiaTensorScale.Y=1
							--AffectedMesh.BodyInstance.InertiaTensorScale.Z=1
							--GrabbedItem:SetLinearDamping(0)
							--AffectedMesh:SetSimulatePhysics(true)	
							AnchorMesh:SetSimulatePhysics(false)
							AnchorMesh.bHiddenInGame=false
							
							local BoxExtend= WpnMesh.StaticMesh.ExtendedBounds.BoxExtent
						
							
							--print(hmd_component:get_full_name())
							--hmd_component:SetCollisionProfileName("PhysicsBody")
							--right_hand_Constraint_parent:SetConstrainedComponents(AnchorMesh_parent,"None",AffectedMesh,"None")
							--right_hand_Constraint_parent:SetConstraintReferencePosition(0,Vector3d.new(0,0,0))
							
							
							
							
						
							--WpnMesh:SetUseCCD(true,"None")
							--right_hand_Constraint.ConstraintInstance.ProfileInstance.LinearLimit.ContactDistance =1
							
							--AnchorMesh:WakeAllRigidBodies()
							--AffectedMesh:WakeAllRigidBodies()
							--right_hand_Constraint:SetProjectionEnabled(true)
							WpnMesh:SetSimulatePhysics(true)
							--AnchorMesh:AddTickPrerequisiteComponent(right_hand_component)
							WpnMesh.RelativeRotation.Yaw=0
							WpnMesh.RelativeRotation.Pitch=0
							WpnMesh.RelativeRotation.Roll=90
							
							right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",WpnMesh,"None")
						--WpnMesh:WakeAllRigidBodies()
						--pawn.GrabArmComponent.GrabAnchorComponent:DetachFromParent(true,true)
						--AnchorMesh:K2_AttachToComponent(pawn.GrabArmComponent,"GrabAnchorSocket",2,2,0,true)
						
						
						--if dpawn.bInCombatStance then
							right_hand_Constraint:SetConstraintReferencePosition(1,Vector3d.new(0,0,0))--BoxExtend.Y*0.8))
							right_hand_Constraint:SetConstraintReferenceOrientation(1,Vector3d.new(1,0,0),Vector3d.new(0,0,1))
						--else 
						--		right_hand_Constraint:SetConstraintReferencePosition(0,Vector3d.new(5,0,0))
						--end
							
							--WpnMesh:SetLinearDamping(0.0)
							--WpnMesh:SetAngularDamping(0.0)
							----WpnMesh.BodyInstance:UpdateInstanceDamping()
							
						--	print("Applying constraint")
							---NEED TO ADD LOGIC FOR WEAPON UNSHEATHED EMPTY HAND:
						elseif not rShoulder and Grabbed then
								Grabbed=false
								SetItemToConstrain(WpnMesh,ddelta)
								-- WpnMesh:WakeAllRigidBodies()
								right_hand_Constraint:BreakConstraint()
								right_hand_Constraint_parent:BreakConstraint()
								--AffectedMesh:SetEnableGravity(true)
								AffectedMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+right_hand_component:GetForwardVector()*-5,false,ReusableHit,true)	
								local CurrentRRot = right_hand_component:K2_GetComponentRotation()	
							
								AffectedMesh:K2_SetWorldRotation(CurrentRRot,false,ReusableHit,true)
								--AnchorMesh:SetSimulatePhysics(false)
							--AnchorMesh.bHiddenInGame=false
							--	RHandM:SetCollisionProfileName("PhysicsBody")
								AffectedMesh:SetSimulatePhysics(true)
								
								
								
								right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
								--RHandM.RelativeRotation.Yaw = -90
								right_hand_Constraint:SetConstraintReferencePosition(1,Vector3d.new(5,0,0))--BoxExtend.Y*0.8))
								--right_hand_Constraint:SetConstraintReferenceOrientation(0,Vector3d.new(1,0,0),Vector3d.new(0,0,1))	
								
						end
						if not Grabbed then
						RHandM:DetachFromParent(true)
						RHandM:K2_SetWorldLocation(AffectedMesh:K2_GetComponentLocation()+AffectedMesh:GetRightVector()*0,false,ReusableHit,true)	
						local PreRot =AffectedMesh:K2_GetComponentRotation()
						local hand_quat = kismet_math_library:Conv_RotatorToQuaternion(PreRot)
						local offset_rot = kismet_math_library:MakeRotator(Vector3d.new(0.0, 90.0, 0.0)) -- Pitch, Yaw, Roll
						local offset_quat = kismet_math_library:Conv_RotatorToQuaternion(offset_rot)
						local final_quat = kismet_math_library:Multiply_QuatQuat(hand_quat, offset_quat)

						local final_rot = kismet_math_library:Quat_Rotator(final_quat)
						--	OffRot.Pitch=0
						--	OffRot.Roll=0
						--local FinalRot = kismet_math_library:ComposeRotators(PreRot,OffRot)
						RHandM:SetSimulatePhysics(false)
						--RHandM:K2_SetWorldRotation(final_rot,false,ReusableHit,true)
						--RHandM.RelativeRotation.Yaw = -90
						end
						
					else
						AffectedMesh:WakeAllRigidBodies()
						AffectedMesh:SetSimulatePhysics(true)
						right_hand_Constraint:SetConstrainedComponents(pawn.GrabArmComponent.GrabAnchorComponent,"None",AffectedMesh,"None")
						right_hand_Constraint:SetConstraintReferencePosition(0,Vector3d.new(0,0,0))										
					end
					
					
					
				end
			end
			if left_hand_Constraint~= nil and UEVR_UObjectHook.exists(AffectedMeshL) then
					--print("done as well")
					LHandM:DetachFromParent(true)
					LHandM:K2_SetWorldLocation(AffectedMeshL:K2_GetComponentLocation()+AffectedMeshL:GetRightVector()*6,false,ReusableHit,true)	
					LHandM:K2_SetWorldRotation(left_hand_component:K2_GetComponentRotation(),false,ReusableHit,true)	
					if lShoulder and not GrabbedL then
						GrabbedL=true
						AffectedMeshL:SetSimulatePhysics(true)
						AffectedMeshL:K2_SetWorldLocation(left_hand_component:K2_GetComponentLocation()+Vector3d.new(0,0,0),false,ReusableHit,true)	
					
						left_hand_Constraint:SetConstrainedComponents(AnchorMeshL,"None",AffectedMeshL,"None")
						left_hand_Constraint:SetConstraintReferencePosition(0,Vector3d.new(0,0,0))					
					end
					if not lShoulder and GrabbedL then
						GrabbedL=false
						--AffectedMeshL:K2_SetWorldLocation(left_hand_component:K2_GetComponentLocation()+Vector3d.new(0,0,0),false,ReusableHit,true)	
					
						left_hand_Constraint:SetConstrainedComponents(AnchorMeshL,"None",AffectedMeshL,"None")
						left_hand_Constraint:SetConstraintReferencePosition(1,Vector3d.new(5,0,0))	
						
						
					end
	--				if dpawn.bInCombatStance then
	--					--print("try grab wepn=")
	--					EmptyHandInitL=false
	--				--	right_hand_Constraint:BreakConstraint()
	--				--	right_hand_Constraint_parent:BreakConstraint()
	--					if GrabbedL then
	--					
	--					end
	--					if lShoulder and not GrabbedL then--
	--						GrabbedL=true	
	--						 SetItemToConstrain(WpnMesh,ddelta)
	--						ConfigureConstraintComp(pawn)
	--						AffectedMesh:SetEnableGravity(false)
	--						
	--					
	--						WpnMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+Vector3d.new(0,0,0),false,ReusableHit,true)	
	--						local CurrentRRot = right_hand_component:K2_GetComponentRotation()	
	--						
	--						--WpnMesh:K2_SetWorldRotation(CurrentRRot,false,ReusableHit,true)
	--						
	--						--right_hand_Constraint:AddTickPrerequisiteActor(pawn)
	--						--AffectedMesh.bAbsoluteLocation=true
	--						GrabbedItem:SetSimulatePhysics(false)
	--						AffectedMesh.BodyInstance.InertiaTensorScale.X=1
	--						AffectedMesh.BodyInstance.InertiaTensorScale.Y=1
	--						AffectedMesh.BodyInstance.InertiaTensorScale.Z=1
	--						--GrabbedItem:SetLinearDamping(0)
	--						AffectedMesh:SetSimulatePhysics(true)	
	--						AnchorMesh:SetSimulatePhysics(false)
	--						AnchorMesh.bHiddenInGame=false
	--						
	--						local BoxExtend= WpnMesh.StaticMesh.ExtendedBounds.BoxExtent
	--					
	--						
	--						--print(hmd_component:get_full_name())
	--						--hmd_component:SetCollisionProfileName("PhysicsBody")
	--						--right_hand_Constraint_parent:SetConstrainedComponents(AnchorMesh_parent,"None",AffectedMesh,"None")
	--						--right_hand_Constraint_parent:SetConstraintReferencePosition(0,Vector3d.new(0,0,0))
	--						
	--						
	--						
	--						
	--					
	--						
	--						--right_hand_Constraint.ConstraintInstance.ProfileInstance.LinearLimit.ContactDistance =1
	--						
	--						--right_hand_Constraint:SetProjectionEnabled(true)
	--					WpnMesh:SetSimulatePhysics(true)
	--						AnchorMesh:AddTickPrerequisiteComponent(right_hand_component)
	--					WpnMesh.RelativeRotation.Yaw=0
	--					WpnMesh.RelativeRotation.Pitch=0
	--					WpnMesh.RelativeRotation.Roll=90
	--					right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",WpnMesh,"None")
	--					--pawn.GrabArmComponent.GrabAnchorComponent:DetachFromParent(true,true)
	--					--AnchorMesh:K2_AttachToComponent(pawn.GrabArmComponent,"GrabAnchorSocket",2,2,0,true)
	--					
	--					
	--					--if dpawn.bInCombatStance then
	--						right_hand_Constraint:SetConstraintReferencePosition(0,Vector3d.new(0,0,0))--BoxExtend.Y*0.8))
	--						right_hand_Constraint:SetConstraintReferenceOrientation(1,Vector3d.new(1,0,0),Vector3d.new(0,0,1))
	--					--else 
	--					--		right_hand_Constraint:SetConstraintReferencePosition(0,Vector3d.new(5,0,0))
	--					--end
	--						WpnMesh:SetUseCCD(true,"None")
	--						--WpnMesh:SetLinearDamping(0.0)
	--						--WpnMesh:SetAngularDamping(0.0)
	--						----WpnMesh.BodyInstance:UpdateInstanceDamping()
	--						--WpnMesh:WakeAllRigidBodies()
	--						print("Applying constraint")
	--						---NEED TO ADD LOGIC FOR WEAPON UNSHEATHED EMPTY HAND:
	--					elseif not rShoulder and Grabbed and not InitRelease then
	--							Grabbed=false
	--							 SetItemToConstrain(WpnMesh,ddelta)
	--							right_hand_Constraint:BreakConstraint()
	--							right_hand_Constraint_parent:BreakConstraint()
	--							--AffectedMesh:SetEnableGravity(true)
	--							AffectedMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+right_hand_component:GetForwardVector()*-5,false,ReusableHit,true)	
	--							local CurrentRRot = right_hand_component:K2_GetComponentRotation()	
	--						
	--							AffectedMesh:K2_SetWorldRotation(CurrentRRot,false,ReusableHit,true)
	--							AnchorMesh:SetSimulatePhysics(false)
	--						--AnchorMesh.bHiddenInGame=false
	--						--	RHandM:SetCollisionProfileName("PhysicsBody")
	--						--	RHandM:SetSimulatePhysics(true)
	--							
	--							
	--							
	--							right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
	--							--right_hand_Constraint:SetConstraintReferencePosition(1,Vector3d.new(5,0,0))--BoxExtend.Y*0.8))
	--							--right_hand_Constraint:SetConstraintReferenceOrientation(1,Vector3d.new(1,0,0),Vector3d.new(0,0,1))	
	--							
	--					end
	--				else
	--					right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
	--					right_hand_Constraint:SetConstraintReferencePosition(0,Vector3d.new(0,0,0))										
	--				end
	--				
	--				
	--				
				end
			end
		end



function UpdatePhysicsHandleLogic(pawn,world_context)
		if pawn~=nil then
			local WpnMesh= GetCurrentWeaponMesh(pawn)
			--TrueMesh=GetCurrentWeaponMesh(pawn)
			--print(WpnMesh)
			--print(AnchorMesh)
			
			if WpnMesh~=nil and AffectedMesh==nil  then
				--GenerateCollisionLogic(pawn) --FROM MELEECOMBAT.lUA, recheck collision
				
				print("found wpn and isnt attahced")
				--print(WpnMesh.AttachParent== pawn.Mesh)
				
				--
				--for i = 1, 30 ,1 do
				--WpnMesh:SetCollisionResponseToChannel(i,0)
				--end
				
					CreatePhysicsHandleLogic(pawn,world_context)	
				if  AffectedMesh~=nil and right_hand_Constraint~= nil then-- and right_hand_component~=nil then
					print("Continued attach")
					SetPhysicsHandlerAttachLogic(pawn)
					--ConfigureConstrainMeshes(true,nil,nil)	
					
					ConfigureHandlerComp(pawn)
				--	right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
				end
				
				TrueMeshLast=WpnMesh
			elseif WpnMesh==nil then
				TrueMeshLast=nil
			end
			
			local newHit ={}
			--if not Grabbed then
				--print(rShoulder)
			if  AffectedMesh~=nil then		
				--print("done")
				--right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None")
				if right_hand_Constraint~= nil and UEVR_UObjectHook.exists(AffectedMesh) then
					--print("done as well")
					right_hand_Constraint:SetActive(true)
					--right_hand_Constraint:K2_AttachToComponent(right_hand_component," ",2,2,0,false)
					if rShoulder then--and not Grabbed then
						if not Grabbed then
								Grabbed=true	
						--	AffectedMesh:SetEnableGravity(true)
						
							       ConstraintActor:SetTickGroup(0)
										--AnchorMesh:SetTickGrou0p()
									  AffectedMesh:SetTickGroup(0)
							 right_hand_Constraint:SetTickGroup(0)
							  right_hand_component:SetTickGroup(0)
								
							
							
							
							AffectedMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation()+right_hand_component:GetUpVector()*14+right_hand_component:GetForwardVector()*5,false,ReusableHit,true)	
							AffectedMesh:K2_SetWorldRotation(right_hand_component:K2_GetComponentRotation(),false,ReusableHit,true)
							
							
							LHandM:SetCollisionEnabled(0)
							local BoxExtend= WpnMesh.StaticMesh.ExtendedBounds.BoxExtent
							
							AffectedMesh.RelativeScale3D.X = 1/50*BoxExtend.X*0.7
							AffectedMesh.RelativeScale3D.Y = 1/50*BoxExtend.Y*0.5
							AffectedMesh.RelativeScale3D.Z = 1/50*BoxExtend.Z
							AffectedMesh:SetOwnerNoSee(false)
							--AffectedMesh.RelativeRotation.Pitch= -40
							AffectedMesh:SetMassOverrideInKg("Root",1.0,false)
							AffectedMesh:SetAllMassScale(		1.0)
							AffectedMesh:WakeAllRigidBodies()
							AffectedMesh:SetSimulatePhysics(true)
							--AffectedMesh:DetachFromParent(true,false)
							--
							--WpnMesh:SetSimulatePhysics(false)
							right_hand_Constraint:SetTargetLocation(LHandM:K2_GetComponentLocation())
							right_hand_Constraint:GrabComponentAtLocationWithRotation(AffectedMesh, "Root",right_hand_component:K2_GetComponentLocation(),right_hand_component:K2_GetComponentRotation())	--AffectedMesh:K2_GetComponentLocation()+AffectedMesh:GetUpVector()*(-BoxExtend.Z*10.9)
						--	right_hand_Constraint:SetTargetRotation(right_hand_component:K2_GetComponentRotation())
						end
						--AffectedMesh:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation(),false,ReusableHit,false)	
						--AffectedMesh:K2_SetWorldRotation(right_hand_component:K2_GetComponentRotation(),false,ReusableHit,false)
						
						--AffectedMesh:WakeAllRigidBodies()
						--right_hand_Constraint:GrabComponentAtLocationWithRotation(AffectedMesh, " ",Vector3d.new(0,0,0),right_hand_component:K2_GetComponentRotation())	--AffectedMesh:K2_GetComponentLocation()+AffectedMesh:GetUpVector()*(-BoxExtend.Z*10.9)
						
						---right_hand_Constraint:ReceiveTick(1)
						--AffectedMesh:SetUseCCD(false,"Root")
						--AffectedMesh:SetSimulatePhysics(true)	
						
					--right_hand_Constraint:SetConstrainedComponents(AnchorMesh,"None",AffectedMesh,"None") right_hand_component:K2_GetComponentLocation()
						--right_hand_Constraint:GrabComponent(AffectedMesh, " ",AffectedMesh:K2_GetComponentLocation(),false)--,right_hand_component:K2_GetComponentRotation(),true)
					--right_hand_Constraint:GrabComponentAtLocation(AffectedMesh, " ",Vector3d.new(0,0,0))--,right_hand_component:K2_GetComponentRotation())
						
						--right_hand_Constraint:SetTargetLocation(right_hand_component:K2_GetComponentLocation())
						--right_hand_Constraint:SetTargetRotation(right_hand_component:K2_GetComponentRotation())
						local NewLoc = kismet_math_library:Subtract_VectorVector( right_hand_component:K2_GetComponentLocation(),right_hand_pos_Pretick)
						--print(NewLoc.X)
						local NewLocFinal = kismet_math_library:Add_VectorVector(right_hand_component:K2_GetComponentLocation(),NewLoc*8)
						--WpnMesh:K2_SetWorldLocation(NewLocFinal,false,{},true)
						right_hand_Constraint:SetTargetLocation(NewLocFinal)
						right_hand_Constraint:SetTargetRotation(right_hand_component:K2_GetComponentRotation())
						print("Applying constraint")
						
					--	print("Applying constraint")
					else-- not rShoulder and Grabbed then
						Grabbed=false
						right_hand_Constraint:ReleaseComponent()
						--WpnMesh:K2_AttachToComponent(AffectedMesh," ",2,2,0,false)
						--right_hand_Constraint:BreakConstraint()
						--AffectedMesh:SetEnableGravity(false)
						--AffectedMesh:SetSimulatePhysics(true)	
					end
						--local CurrLoc = pawn.Mesh:K2_GetComponentLocation()
						--local Offset = kismet_math_library:Subtract_VectorVector(CurrLoc,MeshLocLast)
						--AffectedMesh:K2_AddWorldOffset(Offset*0.1,false,newHit,false)
						--MeshLocLast=CurrLoc
				end
			end
		
		end

end



uevr.sdk.callbacks.on_post_engine_tick(
function(engine, delta)
--	



if right_hand_component then
	--MeshLocLast = right_hand_component:K2_GetComponentLocation()
	--right_hand_Constraint:SetTargetLocation(MeshLocLast)
	--right_hand_Constraint:SetTargetRotation(right_hand_component:K2_GetComponentRotation())
end
--	
--	
--	local dpawn = api:get_local_pawn(0)
--	
--	
--
--
--
--
end)










--
--		local PreRot
--		local DiffRot
--		local DecoupledYawCurrentRotLast=0
--		uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
--		
--		local pawn = api:get_local_pawn(0)	
--		if pawn~=nil and not isCinematic  then
--			
--			
--		--	rotation.y = DecoupledYawCurrentRot
--			
--			
--			--vr.recenter_view()
--		
--			--local default_transform = pawn.Mesh:GetSocketTransform("headSocket",2).Translation.Z
--			--print(default_transform)
--			
--			position.z = pawn:K2_GetActorLocation().z+90
--		--	--if default_transform<100 then
--		--	--	position.z = pawn:K2_GetActorLocation().z+10
--		--	--end
--			position.x = pawn:K2_GetActorLocation().x
--			position.y = pawn:K2_GetActorLocation().y
--		end
--		
--		end)
--
--






