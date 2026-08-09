	--CONFIG
	require(".\\Subsystems\\HelperFunctions")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalDataCustom")
	require(".\\Config\\CONFIG")
	local controllers = require('libs/controllers')
	--local MeleePower = 500 --Default = 1000
	---------------------------------------
	local MeleeDistance=1 -- 30cm + MeleeDistance per meter,e.g. 30cm+ 0.4*1m = 70cm
	--local api = uevr.api
	--local vr = uevr.params.vr
	--local params = uevr.params
	--local callbacks = uevr.params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local WeaponHand_Pos=UEVR_Vector3f.new()
	local WeaponHand_Rot=UEVR_Quaternionf.new()
	local SecondaryHand_Pos=UEVR_Vector3f.new()
	local SecondaryHand_Rot=UEVR_Quaternionf.new()
	local SecondaryHand_Joy=UEVR_Vector2f.new()
	local PosZOld=0
	local PosYOld=0
	local PosXOld=0
	local PosZOldSecondary=0
	local PosYOldSecondary=0
	local PosXOldSecondary=0
	local tickskip=0
	local PosDiffWeaponHand=0
	local PosDiffSecondaryHand=0
	local WeaponHandCanPunch=false
	local SecondaryHandCanPunch=false
	
--VR to key functions
--local function SendKeyPress(key_value, key_up)
--    local key_up_string = "down"
--    if key_up == true then 
--        key_up_string = "up"
--    end
--    
--    api:dispatch_custom_event(key_value, key_up_string)
--end
--
--local function SendKeyDown(key_value)
--    SendKeyPress(key_value, false)
--end
--
--local function SendKeyUp(key_value)
--    SendKeyPress(key_value, true)
--end
--	
--function isButtonPressed(state, button)
--	return state.Gamepad.wButtons & button ~= 0
--end
--function isButtonNotPressed(state, button)
--	return state.Gamepad.wButtons & button == 0
--end
--function pressButton(state, button)
--	state.Gamepad.wButtons = state.Gamepad.wButtons | button
--end
--function unpressButton(state, button)
--	state.Gamepad.wButtons = state.Gamepad.wButtons & ~(button)
--end

--Helper functions

local swinging_fast = nil

local melee_data = {
    right_hand_pos_raw = UEVR_Vector3f.new(),
    right_hand_q_raw = UEVR_Quaternionf.new(),
    right_hand_pos = Vector3f.new(0, 0, 0),
    last_right_hand_raw_pos = Vector3f.new(0, 0, 0),
    last_time_messed_with_attack_request = 0.0,
    first = true,
}

local isHit1=false
local isHit2=false
local isHit3=false
local isHit4=false
local isHit5=false



--Library
--local kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")

--local UGameplayStatics_library= find_static_class("Class /Script/Engine.GameplayStatics")
--local game_engine_class = find_required_object("Class /Script/Engine.GameEngine")

local zero_color = nil
local color_c = find_required_object("ScriptStruct /Script/CoreUObject.LinearColor")
local    actor_c = find_required_object("Class /Script/Engine.Actor")
local zero_color = StructObject.new(color_c)
	
--local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
--local GameplayStaticsDefault= find_required_object("GameplayStatics /Script/Engine.Default__GameplayStatics")
local VWeaponClass= find_static_class("Class /Script/Altar.VWeapon")
local VHitBoxClass= find_required_object("Class /Script/Altar.VHitBoxComponent")
local ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")



local reusable_hit_result1 = StructObject.new(hitresult_c)
local reusable_hit_result2=  StructObject.new(hitresult_c)
local reusable_hit_result3 = StructObject.new(hitresult_c)
local reusable_hit_result4 = StructObject.new(hitresult_c)
local reusable_hit_result5 = StructObject.new(hitresult_c)

local DeltaCheck=0
local Mouse1=false
local DeltaAimMethod =0
local isAimMethodSwitched=false
local Hittest = nil

local isBlock=false
local DeltaBlock=0
local DeltaBlock2Activator=0
local DeltaBlockActivator=0
local ShieldAngle=0
local HeadAngle=0
local BoxX=10
local BoxZ=1
local AttackCount=0
local isAttacking=false
local BoxYLast=0
local BoxY=0
local tgm=false
local AttackDelta=0
local ActorFound=false
local HitBoxReset=true
local HitBoxDelta=0
local SendAttack=false
local Init=false
local InitDelta=0
local RagdollT=0
RagdolledNPCs={}

local LeftController=		 uevr.params.vr.get_left_joystick_source()
local RightController=		 uevr.params.vr.get_right_joystick_source()

function UpdateRagdolls(dDelta)
	if #RagdolledNPCs> 0 then
		RagdollT = RagdollT + dDelta
		local Blend = 1 - RagdollT
		
		
		
		
		if RagdollT>1 then
			for i,comp in ipairs(RagdolledNPCs) do
				comp:SetAllBodiesBelowSimulatePhysics("spine_01",false,true)
			end
			RagdolledNPCs={}
			RagdollT=0
		elseif RagdollT<=1 then
			for i,comp in ipairs(RagdolledNPCs) do
				comp:SetAllBodiesBelowPhysicsBlendWeight("spine_01",Blend,true,false)
			end
		end
	end
end


local function UpdatePlayerCollision(delta)
	if pawn.CapsuleComponent~=nil and Init==false then
	InitDelta=InitDelta+delta
	pawn.CapsuleComponent.CapsuleHalfHeight= 200.0
	end
	if Init==false and InitDelta>10 then
		pawn:Crouch(true)
		Init=true
		print("init")
	end
	
		if not isRiding and Init==true then
			if math.abs(ThumbLX)>=20000 or math.abs(ThumbLY) >= 20000 then
				--pawn.CapsuleComponent.CapsuleHalfHeight= CapsuleHalfHeightWhenMoving
				--pawn.CapsuleComponent.CapsuleRadius= CapsuleRadWhenMoving
			else pawn.CapsuleComponent.CapsuleRadius=11.480
				
				--pawn.CharacterMovement:SetWalkableFloorAngle(90)
			end
		end
end

--uevr.sdk.callbacks.on_pre_engine_tick(
--function(engine, delta)
--print(isRiding)
function Melee(pawn,player,engine,delta)
	if left_hand_component	== nil then-- print("no l")
	return end
	if right_hand_component	== nil then-- print("no r")
	return end
	if hmd_component		== nil then-- print("no h") 
	 return end
	UpdateRagdolls(delta)
	if not isRiding then
		DeltaCheck=DeltaCheck+delta
		--print("notRiding")
		--player= api:get_player_controller(0)
		--pawn = api:get_local_pawn(0)
		if isRhand then
			WHandIndex=2
			SHandIndex=1
		else HandIndex=1
			SHandIndex=2
		end
		--print(isRiding)
		--local SecondaryHandIndex = uevr.params.vr.get_right_controller_index()
		uevr.params.vr.get_pose(WHandIndex, WeaponHand_Pos, WeaponHand_Rot)
		
		local PosXNew=WeaponHand_Pos.x
		local PosYNew=WeaponHand_Pos.y
		local PosZNew=WeaponHand_Pos.z
		
		PosDiffWeaponHand = math.sqrt((PosXNew-PosXOld)^2+(PosYNew-PosYOld)^2+(PosZNew-PosZOld)^2)*(1/delta)*200
		PosZOld=PosZNew
		PosYOld=PosYNew
		PosXOld=PosXNew
		
		uevr.params.vr.get_pose(SHandIndex, SecondaryHand_Pos, SecondaryHand_Rot)
		local PosXNewSecondary=SecondaryHand_Pos.x
		local PosYNewSecondary=SecondaryHand_Pos.y
		local PosZNewSecondary=SecondaryHand_Pos.z
		
		PosDiffSecondaryHand = math.sqrt((PosXNewSecondary-PosXOldSecondary)^2+(PosYNewSecondary-PosYOldSecondary)^2+(PosZNewSecondary-PosZOldSecondary)^2)*(1/delta)*200
		PosZOldSecondary=PosZNewSecondary
		PosYOldSecondary=PosYNewSecondary
		PosXOldSecondary=PosXNewSecondary
		--print(PosDiffWeaponHand)
	--Praydog VARIUANT:	use swinging_fast
		--vr.get_pose(vr.get_right_controller_index(), melee_data.right_hand_pos_raw, melee_data.right_hand_q_raw)
		--
		---- Copy without creating new userdata
		--melee_data.right_hand_pos:set(melee_data.right_hand_pos_raw.x, melee_data.right_hand_pos_raw.y, melee_data.right_hand_pos_raw.z)
		--
		--if melee_data.first then
		--    melee_data.last_right_hand_raw_pos:set(melee_data.right_hand_pos.x, melee_data.right_hand_pos.y, melee_data.right_hand_pos.z)
		--    melee_data.first = false
		--end
		--
		--local velocity = (melee_data.right_hand_pos - melee_data.last_right_hand_raw_pos) * (1 / delta)
		--
		---- Clone without creating new userdata
		--melee_data.last_right_hand_raw_pos.x = melee_data.right_hand_pos_raw.x
		--melee_data.last_right_hand_raw_pos.y = melee_data.right_hand_pos_raw.y
		--melee_data.last_right_hand_raw_pos.z = melee_data.right_hand_pos_raw.z
		--melee_data.last_time_messed_with_attack_request = melee_data.last_time_messed_with_attack_request + delta
	
	
		--local vel_len = velocity:length()
		--    
		--if velocity.y < 0 then
		--swinging_fast = vel_len >= 2.5
		--end
	--
		UpdatePlayerCollision(delta)
		
		local _class ={VWeaponClass}
		--print(pawn.WeaponsPairingComponent.WeaponActor:GetOverlappingComponents())
		local _actors = {}
		local _actors2={}
		local _ShieldComp ={}
		---pcall(function()
		--pawn.WeaponsPairingComponent.WeaponActor.VHitBox:TriggerTrapBegin()
		if pawn.WeaponsPairingComponent.WeaponActor ~=nil then
			local VHitBox = pawn.WeaponsPairingComponent.WeaponActor.VHitBox
			if VHitBox ~=nil  then
			
				VHitBox:SetCollisionEnabled(1)
				VHitBox:SetCollisionObjectType(22)
				VHitBox:K2_AttachToComponent(pawn.WeaponsPairingComponent.WeaponActor.RootComponent,"",2,2,0,true)
				--print(pawn.Mesh.AnimScriptInstance.bAttackingRequest)
				if pawn.Mesh.AnimScriptInstance.bAttackingRequest then
					isAttacking=true
				end
				if isAttacking  then
					--BoxX=
					--BoxZ=40
				--	print("yes")
					--pawn.WeaponsPairingComponent.WeaponActor.VHitBox.RelativeLocation.X=-40
					--AttackCount=AttackCount+delta
				else	
					pawn.WeaponsPairingComponent.WeaponActor.VHitBox.RelativeLocation.X=10+ExtraBlockRange
					BoxX=10+ExtraBlockRange
					BoxZ=1
				end
				if AttackCount>1 then
					AttackCount=0
					isAttacking=false
				end
					if pawn.WeaponsPairingComponent.WeaponActor.VHitBox.BoxExtent.Y -BoxYLast==00 then 
						BoxY = pawn.WeaponsPairingComponent.WeaponActor.VHitBox.BoxExtent.Y -00
					else BoxY=pawn.WeaponsPairingComponent.WeaponActor.VHitBox.BoxExtent.Y end
					
						BoxYLast=BoxY
					
		
					
					
					local BoxVector = Vector3f.new( BoxX, BoxY+00,BoxZ)
					
					pawn.WeaponsPairingComponent.WeaponActor.VHitBox:SetBoxExtent(BoxVector,true)
					--pawn.WeaponsPairingComponent.WeaponActor.VHitBox.BoxExtent.X=80 
				--end
				--pawn.WeaponsPairingComponent.WeaponActor.VHitBox.BoxExtent.Z=15
				--pawn.WeaponsPairingComponent.WeaponActor.VHitBox.BoxExtent.Y=50
				pawn.WeaponsPairingComponent.WeaponActor.VHitBox:GetOverlappingComponents(_actors)
				--pawn.WeaponsPairingComponent.ShieldActor:GetOverlappingComponents(_ShieldComp)
			end
		else
			pawn.RightHandHitBox_FP:SetCollisionEnabled(1)
			pawn.RightHandHitBox_FP:SetCollisionObjectType(22)
			pawn.RightHandHitBox_FP:GetOverlappingComponents(_actors)
			pawn.LeftHandHitBox_FP:SetCollisionEnabled(1)
			pawn.LeftHandHitBox_FP:SetCollisionObjectType(22)
			pawn.LeftHandHitBox_FP:GetOverlappingComponents(_actors2)		
		end
		
		--print(_actors)
		--pawn.WeaponsPairingComponent.WeaponActor.VHitBox:SetRenderInMainPass(true)
		ActorFound=false
		SendAttack=true
		
		for i, comp in ipairs(_actors) do
			
		
				if not string.find(comp:GetOwner():get_fname():to_string(),"Player") then
					--print(comp:GetOwner():get_fname():to_string())
					if comp:GetOwner():GetOwner()~=nil then
						if not string.find(comp:GetOwner():GetOwner():get_fname():to_string(),"Player") then	
							if comp:GetOwner().bIsEquipped ==nil then
								ActorFound=true
								SendAttack=false
								comp:GetOwner().Mesh:SetAllBodiesBelowSimulatePhysics("spine_01",true,false)
								local ForceVec = kismet_math_library:Subtract_VectorVector(right_hand_component:K2_GetComponentLocation(), comp:GetOwner().Mesh:K2_GetComponentLocation())
								
								comp:GetOwner().Mesh:AddImpulse(ForceVec*-10,"spine_02",true)
								table.insert(RagdolledNPCs,comp:GetOwner().Mesh)
								if  HitBoxReset and PosDiffWeaponHand>MeleePower*1.7 then
									HitBoxReset=false
									SendAttack=false	
									uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 5.0, RightController)
									
									if GetPlayerValues(pawn).Stamina>30 then
										pawn:SendMeleeHitOnPairedPawn(comp:GetOwner(),true,2)
										player:SendToConsole("player.modav Fatigue -30")
									elseif GetPlayerValues(pawn).Stamina>5 then
										pawn:SendMeleeHitOnPairedPawn(comp:GetOwner(),false,2)
										player:SendToConsole("player.modav Fatigue -5")
									else
										isTired=true
									end
									
								elseif  HitBoxReset and PosDiffWeaponHand>MeleePower then
									HitBoxReset=false
									SendAttack=false	
									uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 5, RightController)								
									if GetPlayerValues(pawn).Stamina>5 then
										pawn:SendMeleeHitOnPairedPawn(comp:GetOwner(),false,2)
										player:SendToConsole("player.modav Fatigue -5")
									else
										isTired=true
									end
								end
								print(comp:GetOwner():get_fname():to_string())
							end
							if comp:GetOwner().bIsEquipped ~=nil and not string.find(comp:GetOwner():get_fname():to_string(),"Shield") then
								print(comp:GetOwner().bIsEquipped)--get_fname():to_string())
								if comp:GetOwner().bIsEquipped  then
						--print("Blocked")			
									--if not isAimMethodSwitched then 
										isBlock=true
										--pawn:SendAttack(3,5)
										--pawn:SendAttackStartedEvent()
										uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, RightController)
										pawn:SendBlockHit()
										--pawn:SendMeleeHitOnPairedPawn(comp:GetOwner():GetOwner(),false,1)
										DeltaBlock=0
										break
									--end
								end
							end
						
						end
				
					end
				end	
		end
		
			
			
			
		for i, comp in ipairs(_actors2) do
		
		
			if not string.find(comp:GetOwner():get_fname():to_string(),"Player") then
				--print(comp:GetOwner():get_fname():to_string())
				if comp:GetOwner():GetOwner()~=nil then
					if not string.find(comp:GetOwner():GetOwner():get_fname():to_string(),"Player") then	
						if comp:GetOwner().bIsEquipped ==nil then
							ActorFound=true
							SendAttack=false
							if  HitBoxReset and PosDiffSecondaryHand>MeleePower*1.7 then
								HitBoxReset=false
								SendAttack=false	
								uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 5.0, LeftController)
								pawn:SendMeleeHitOnPairedPawn(comp:GetOwner(),true,2)
								player:SendToConsole("player.modav Fatigue -30")
							elseif  HitBoxReset and PosDiffSecondaryHand>MeleePower then
								HitBoxReset=false
								SendAttack=false	
								uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 5, LeftController)								
								pawn:SendMeleeHitOnPairedPawn(comp:GetOwner(),false,2)
								player:SendToConsole("player.modav Fatigue -5")
							end
							print(comp:GetOwner():get_fname():to_string())
						end
						if comp:GetOwner().bIsEquipped ~=nil and not string.find(comp:GetOwner():get_fname():to_string(),"Shield") then
							print(comp:GetOwner().bIsEquipped)--get_fname():to_string())
							if comp:GetOwner().bIsEquipped  then
					--print("Blocked")			
								--if not isAimMethodSwitched then 
									isBlock=true
									--pawn:SendAttack(3,5)
									--pawn:SendAttackStartedEvent()
									uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 100.0, LeftController)
									pawn:SendBlockHit()
									--pawn:SendMeleeHitOnPairedPawn(comp:GetOwner():GetOwner(),false,1)
									DeltaBlock=0
									break
								--end
							end
						end
					
					end
			
				end
			end	
		end
	
		
		
		--HitBox TImer
		if HitBoxReset==false then
		HitBoxDelta=HitBoxDelta+delta
		end
		
		--Reset Hitbox:
		if ActorFound==false and HitBoxDelta> 0.1 then
			HitBoxReset=true
			HitBoxDelta=0
		end
		
		
		if pawn.WeaponsPairingComponent.ShieldActor~=nil then
			
			if pawn.WeaponsPairingComponent.ShieldActor:GetComponentByClass(VHitBoxClass)== nil then
					
				
				--local vec= Vector3f.new(0,0,0)
				
				local zero_transform = StructObject.new(ftransform_c)
				--local scene_capture_component_c = find_required_object("Class /Script/Engine.SceneCaptureComponent2D")
				zero_transform.Rotation.W = 1.0
				zero_transform.Scale3D = Vector3f.new(1.0, 1.0, 1.0)
				pawn.WeaponsPairingComponent.ShieldActor:AddComponentByClass(VHitBoxClass,false,zero_transform, false)
			end
			local HitBoxComponent= pawn.WeaponsPairingComponent.ShieldActor:GetComponentByClass(VHitBoxClass)
			HitBoxComponent.RelativeLocation.X=24.15
			HitBoxComponent.RelativeLocation.Y= 20.28+ExtraBlockRange
			HitBoxComponent.RelativeLocation.Z=0.66
			HitBoxComponent.BoxExtent.X=30.82
			HitBoxComponent.BoxExtent.Y=20.27+ExtraBlockRange
			HitBoxComponent.BoxExtent.Z=37.33
			--HitBoxComponent,BodyInstance.CollisionEnabled=1
			--HitBoxComponent,BodyInstance.CollisionResponses.ResponseToChannels
			HitBoxComponent:GetOverlappingComponents(_ShieldComp)
			
			for i, comp in ipairs(_ShieldComp) do
				
			
					if not string.find(comp:GetOwner():get_fname():to_string(),"Player") then
						-- print(comp:GetOwner():get_fname():to_string())
						if comp:GetOwner():GetOwner()~=nil then
							if not string.find(comp:GetOwner():GetOwner():get_fname():to_string(),"Player") then	
								
								print(comp:GetOwner():GetOwner():get_fname():to_string())
							--	if comp:GetOwner().bIsEquipped ~=nil then
									print("Shield")--get_fname():to_string())
									--if comp:GetOwner().bIsEquipped then
							--print("Blocked")			
										--if not isAimMethodSwitched then 
											isBlock=true
											uevr.params.vr.trigger_haptic_vibration(0.0, 0.1, 1.0, 255.0, LeftController)
											pawn:SendBlockHit()
											DeltaBlock=0
											break
										--end
									--end
								--end
							
							end
						--else SendAttack=true					
						end
					end	
			end
		end
		--print(" ")
		--Hitscan
		local WeaponMesh=nil
		local PMesh=nil
		if pawn.WeaponsPairingComponent.WeaponActor ~=nil then
			if pawn.WeaponsPairingComponent.WeaponActor.MainStaticMeshComponent ~=nil then
				PMesh=	pawn.WeaponsPairingComponent.WeaponActor.MainStaticMeshComponent
				WeaponMesh=pawn.WeaponsPairingComponent.WeaponActor.MainStaticMeshComponent
			end
		elseif pawn.WeaponsPairingComponent.WeaponActor==nil then
			WeaponMesh=pawn.RightHandHitBox_FP
		end
		
		if left_hand_component:K2_GetComponentRotation().y <0 then 
			ShieldAngle=left_hand_component:K2_GetComponentRotation().y+360
			--print (left_hand_component:K2_GetComponentRotation().y+360)
		else ShieldAngle=left_hand_component:K2_GetComponentRotation().y
		--print(left_hand_component:K2_GetComponentRotation().y)
		end
		if hmd_component:K2_GetComponentRotation().y <0 then 
			HeadAngle=hmd_component:K2_GetComponentRotation().y+360
			--print (hmd_component:K2_GetComponentRotation().y+360)
		else HeadAngle=hmd_component:K2_GetComponentRotation().y
	--	print(hmd_component:K2_GetComponentRotation().y)
		end
		--print(left_hand_component:K2_GetComponentRotation.y)
		--Check if no weapon in hand and no shield, if so, can possibly use secondary hand to punch
		if WeaponMesh == nil and pawn.WeaponsPairingComponent.ShieldActor == nil then
			SecondaryHandCanPunch = true
		else SecondaryHandCanPunch = false
		end
		if WeaponMesh == nil then
			WeaponHandCanPunch = true
		else WeaponHandCanPunch = false
		end
		if WeaponMesh ~=nil then--Weapon condition
			--local MeleeMesh= right_hand_component:K2_GetComponentLocation()--pawn.CurrentMeleeWeapon.StaticMesh
			local game_engine = engine--UEVR_UObjectHook.get_first_object_by_class(game_engine_class)
			local viewport = game_engine.GameViewport
			local world = viewport.World
			local ignore2_actors = {}
			local Array_Objects ={}
			local Upvector=WeaponMesh:GetUpVector()
			local RightVector= WeaponMesh:GetRightVector()
		--	local MeshLocation1=WeaponMesh:K2_GetComponentLocation()+RightVector*20+WeaponMesh:GetForwardVector()*30
		--	local endPos1=MeshLocation1+(WeaponMesh:GetForwardVector())*8192
		--	local MeshLocation2=WeaponMesh:K2_GetComponentLocation()+RightVector*-20+WeaponMesh:GetForwardVector()*30
		--	local endPos2=MeshLocation2+(WeaponMesh:GetForwardVector())*8192
		--	local MeshLocation3=WeaponMesh:K2_GetComponentLocation()+Upvector*20+WeaponMesh:GetForwardVector()*30
		--	local endPos3=MeshLocation3+(WeaponMesh:GetForwardVector())*8192
		--	local MeshLocation4=WeaponMesh:K2_GetComponentLocation()+Upvector*-20+WeaponMesh:GetForwardVector()*30
		--	local endPos4=MeshLocation4+(WeaponMesh:GetForwardVector())*8192
			local MeshLocation5=WeaponMesh:K2_GetComponentLocation()+WeaponMesh:GetForwardVector()*30
			local endPos5=MeshLocation5+(WeaponMesh:GetForwardVector())*8192
		--	GameplayStaticsDefault:FindCollisionUV(reusable_hit_result1, 2,UV, true)
		--reusable_hit_result2.Actor= 
		--	local hit1 = kismet_system_library:LineTraceSingle(world, MeshLocation1, endPos1, 0, true, ignore2_actors, 0, reusable_hit_result1, true, zero_color, zero_color, 1.0)
		--	local hit2 = kismet_system_library:LineTraceSingle(world, MeshLocation2, endPos2,0, true, ignore2_actors, 0, reusable_hit_result2, true, zero_color, zero_color,  1.0)
		--	--local FHitRes= UGameplayStatics_library:BreakHitResult(reusable_hit_result2)
		--	local hit3 = kismet_system_library:LineTraceSingle(world, MeshLocation3, endPos3, 0, true, ignore2_actors, 0, reusable_hit_result3, true, zero_color, zero_color, 1.0)
		--	local hit4 = kismet_system_library:LineTraceSingle(world, MeshLocation4, endPos4, 0, true, ignore2_actors, 0, reusable_hit_result4, true, zero_color, zero_color, 1.0)
			local hit5 = kismet_system_library:LineTraceSingle(world, MeshLocation5, endPos5, 0, true, ignore2_actors, 0, reusable_hit_result5, true, zero_color, zero_color, 1.0)
		--	local hit6= world:LineTraceSingleByChannel()
		--	if hit1 and reusable_hit_result1.Distance < 100*MeleeDistance then
		--		isHit1=true
		--	else isHit1=false
		--	end
		--	
		--	if hit2 and reusable_hit_result2.Distance < 100*MeleeDistance then
		--		isHit2=true
		--	else isHit2=false
		--	end
		--	if hit3 and reusable_hit_result3.Distance < 100*MeleeDistance then
		--		isHit3=true
		--	else isHit3=false
		--	end
		--	if hit4 and reusable_hit_result4.Distance < 100*MeleeDistance then
		--		isHit4=true
		--	else isHit4=false
		--	end
			if hit5 and reusable_hit_result5.Distance < 20*MeleeDistance then
				isHit5=true
			else isHit5=false
			end
			--if reusable_hit_result2.Actor ~=nil then
		Hittest = reusable_hit_result5
	--print(Hittest[8])
	--print(Hittest[3])
	--print(Hittest[4])
	--print(Hittest[5])
	--print(Hittest.HitObjectHandle)
	--	print(reusable_hit_result2.Actor)
		--print(Hittest.Component)
	--	print(Hittest.Item)
		--print(Hittest.bBlockingHit)
	-- --print(api:get_item(Hittest.Item))
	--	print(" ")
		--end
			
			--print(reusable_hit_result2.Distance)
			--print(isHit1)
			--print(isHit2)
			--print(isHit3)
			--print(isHit4)
		--	print(isHit5)
			--print("  ")
		end
		if Mouse1==true then
			
			if DeltaCheck >=0.3 then
			--uevr.params.vr.set_mod_value("VR_AimMethod", "2")
			Mouse1 =false
			DeltaCheck=0
			--isHit1=false
			--	isHit2=false
			--	isHit3=false
			--	isHit4=false
			--	uevr.params.vr.set_mod_value("VR_AimMethod", "2")
			--uevr.params.vr.set_mod_value("VR_ControllerPitchOffset", "-21")
			end
		end
	
		--DeltaAimMethod=DeltaAimMethod+delta
	if isBow ==false and isRiding==false and not isMenu then
		if isRhand then
		uevr.params.vr.set_mod_value("VR_AimMethod", "2")
		else uevr.params.vr.set_mod_value("VR_AimMethod", "3") end
			if isHit5  then
			--pawn:SendAttack(0,1)
			--isHit5=false
			--DeltaAimMethod=DeltaAimMethod+delta
			--	if DeltaAimMethod > 0.1 and isAimMethodSwitched==false then
			--	isAimMethodSwitched=true
			--	uevr.params.vr.set_mod_value("VR_AimMethod", "0")
			--	DeltaAimMethod=0
			end
			--end
			--if DeltaAimMethod>0.5 or PMesh.AnimScriptInstance.bAttackingRequest or PMesh.AnimScriptInstance.bCanExitAttack then
			--	uevr.params.vr.set_mod_value("VR_AimMethod", "2")
			--	isAimMethodSwitched=false
			--	
			--end
			if right_hand_component:K2_GetComponentRotation().z > -105 and right_hand_component:K2_GetComponentRotation().z<-75 and PosDiffWeaponHand<100 then
				DeltaBlockActivator=DeltaBlockActivator+delta
				if DeltaBlockActivator > 0.15 and PosDiffWeaponHand<100 then
					if SwordSidewaysIsBlock then
						isBlock=true
						pawn:SendBlockHit()
					end
				end
			else 
				DeltaBlockActivator=0
				
			end
			--print (ShieldAngle-HeadAngle)
			if ShieldAngle-HeadAngle > 60 and ShieldAngle-HeadAngle< 100 and pawn.WeaponsPairingComponent.ShieldActor ~=nil then
				DeltaBlock2Activator=DeltaBlock2Activator+delta
				if DeltaBlock2Activator > 0.15   then
				--isBlock=true
				end
			elseif ShieldAngle-HeadAngle <-260 and ShieldAngle-HeadAngle >-295 and pawn.WeaponsPairingComponent.ShieldActor ~=nil then
				DeltaBlock2Activator=DeltaBlock2Activator+delta
				if DeltaBlock2Activator > 0.15 then
			--	isBlock=true
				end
			else 
				DeltaBlock2Activator=0		
			end
					
			
			if isBlock then
			--uevr.params.vr.set_mod_value("VR_AimMethod", "1")
			DeltaBlock=DeltaBlock+delta
				if DeltaBlock >1.15 then
					pawn:SendBlock(false)
				isBlock=false
				DeltaBlock=0
				
				end
			end
		elseif (isBow and RTrigger ~= 0) or isMenu then uevr.params.vr.set_mod_value("VR_AimMethod", "0")
		elseif (isBow and RTrigger == 0) or isMenu then uevr.params.vr.set_mod_value("VR_AimMethod", "0")
		
		end
		AttackDelta=AttackDelta+delta
	--if riding:
	else uevr.params.vr.set_mod_value("VR_AimMethod", "0") 
	pawn.CapsuleComponent.CapsuleRadius=50
	end

end


	
local Prep=false
local PrepR=false

--uevr.sdk.callbacks.on_xinput_get_state(
--function(retval, user_index, state)

function MeleeInput(state)

if Init==true then
	
	Init=2
end
--print(isBlock)

--local TriggerR = state.Gamepad.bRightTrigger
--if PosDiffWeaponHand >= MeleePower and Prep == false then
--	Prep=true
--elseif PosDiffWeaponHand <=150 and Prep ==true then
--	SendKeyDown('0x01')
--	Prep=false
--	Mouse1=true
--end
--state.Gamepad.bRightTrigger=0



--if PosDiffSecondaryHand >= MeleePower and PrepR == false then
--	Prep=true
--elseif PosDiffSecondaryHand <=10 and PrepR ==true then
--	state.Gamepad.bRightTrigger= 255
--	PrepR=false
--end	

--if isHit1 or isHit2 or isHit3 or isHit4 or isHit5 and Mouse1==false then

if isWeaponDrawn and isBow==false then
	if Mouse1==false and AttackDelta>2.2 and (PosDiffWeaponHand >= MeleePower and isHit5 and HitBoxReset== true) then
	
	AttackDelta=0
		--uevr.params.vr.set_mod_value("VR_AimMethod", "1")
		if state.Gamepad.bRightTrigger==255 then
			state.Gamepad.bRightTrigger=0
		elseif state.Gamepad.bRightTrigger==0 then
			state.Gamepad.bRightTrigger=255
		end
		DeltaCheck=0
		--isHit1=false
		--isHit2=false
		--isHit3=false
		--isHit4=false
		Mouse1=true
		Prep=false
		--print("Collision Hit")
	end

end





--Read Gamepad stick input for rotation compensation
	
	
 
	--testrotato.Y= CurrentPressAngle


		--RotationOffset
	--ConvertedAngle= kismet_math_library:Quat_MakeFromEuler(testrotato)
	--print("x: " .. ConvertedAngle.X .. "     y: ".. ConvertedAngle.Y .."     z: ".. ConvertedAngle.Z .. "     w: ".. ConvertedAngle.W)





end