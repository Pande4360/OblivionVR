require(".\\Subsystems\\MeleePower")
--local uevrUtils = require('libs/uevr_utils')
--local hands = require('libs/hands')
local controllers = require('libs/controllers')
require(".\\Config\\CONFIG")
require(".\\Subsystems\\GlobalData")
require(".\\Subsystems\\GlobalDataCustom")
require(".\\Subsystems\\HelperFunctions")

--SpecialExtensions:
require(".\\Main\\CameraManager")
require(".\\Main\\VRHud")
require(".\\Main\\Attachements")
require(".\\Main\\HolsterScript")
require(".\\Main\\Melee")
require(".\\Main\\hands")
require(".\\Main\\PhysicsMassEmu")
--require(".\\Subsystems\\test")
 
 
 
 
local function CinematicStatus(pawn)
	if pawn ==nil then return end
	if not UEVR_UObjectHook.exists(CameraManager) then
--	if CameraManager.ViewTarget==nil then
		CameraManager= UEVR_UObjectHook.get_first_object_by_class(CameraManager_C)
	end
 	if CameraManager.ViewTarget.Target ~= pawn then
		isCinematic=true
		--UEVR_UObjectHook.set_disabled(true)
	else isCinematic=false
		if not isMenu then
		--	UEVR_UObjectHook.set_disabled(false)
		end
	end
	--print(isCinematic)
end 




--local function MenuStatus(Player)
--	if Player.bShowMouseCursor then
--		isMenu=true
--		--	UEVR_UObjectHook.set_disabled(true)
--			uevr.params.vr.set_mod_value("UI_FollowView","false")
--			uevr.params.vr.set_mod_value("VR_DecoupledPitch","false")
--			--uevr.params.vr.set_mod_value("VR_AimMethod","0")
--			--Player.bShowMouseCursor=true
--			
--			--uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor","true")
--			uevr.params.vr.set_mod_value("VR_DecoupledPitch","true")
--			if not wasRecentered then
--				vr.recenter_view()
--				wasRecentered=true
--			end
--	else
--		isMenu=false
--		wasRecentered=false
--		--uevr.params.vr.set_mod_value("VR_AimMethod","1")
--		--uevr.params.vr.set_mod_value("FrameworkConfig_AlwaysShowCursor","false")
--		uevr.params.vr.set_mod_value("UI_FollowView","true")
--		uevr.params.vr.set_mod_value("VR_DecoupledPitch","true")
--		
--			
--	end
--end
 
--local function SprintRoll(state,cpawn)
--	if isThumbMotion and math.abs(StickR.y) < 0.2 then
--		isThumbMotion=false
--		SendKeyUp("0x20")
--			SendKeyUp("C")
--	end
--		
--	
--	--print(StickR.x)
--	--print(StickR.y)
--	if not isMenu and not TactiNavVisible then 
--		if StickR.y>0.8 and not isThumbMotion then
--			SendKeyDown("0x20")
--			
--			isThumbMotion=true
--		elseif StickR.y<-0.8 and not isThumbMotion then
--			isThumbMotion=true
--			SendKeyDown("C")
--			WpnLocationUpdate=true
--			WpnUpdateDelta=0
--		--	pressButton(state, XINPUT_GAMEPAD_B)
--		--	pawn:InpActEvt_Crouch_K2Node_InputActionEvent_13(Key)
--		
--		end
--		
--		
--		
--		
--	end
--	if cpawn~=nil  then
--		
--		
--		if Abutton and cpawn.CharacterMovement~=nil and not isSprinting and canPressA then
--			canPressA=false
--			isSprinting=true
--			cpawn.CharacterMovement.MaxWalkSpeed = 580 
--			cpawn.CharacterMovement.MaxWalkSpeedCrouched = 240
--		elseif ((Abutton and canPressA) or math.abs(ThumbLY)<20000) and isSprinting and cpawn.CharacterMovement~=nil then
--			isSprinting=false
--			canPressA=false
--			cpawn.CharacterMovement.MaxWalkSpeed = 280
--			cpawn.CharacterMovement.MaxWalkSpeedCrouched = 140
--		end
--	end
--	if not Abutton then
--			canPressA=true
--	end
--	
--	
--	
--end

--WasReloadPressed =false
--local function CollisionFunctionExecute(state,pawn)
--	--local MeshArray1 = pawn.Children
--	
--	--checkMaterial(pawn,MeshArray1,"FOV_Alpha") --from FOV FIXER
--	if pressY then
--		--unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
--		pressButton(state,XINPUT_GAMEPAD_Y)
--		if not rShoulder then
--			pressY=false
--		end
--	end
--	
--	if ReloadInProgress  then
--		--WasReloadPressed=true
--		--SendKeyDown("R")
--		--ReloadCount=ReloadCount+delta
--	else --SendKeyUp("R")
--	end
--	-- EDIT COLLISION BODY BOXES:
--	
--	if pressRS then
--		--pressButton(state,XINPUT_GAMEPAD_DPAD_UP)
--		SendKeyDown("1")
--		if not lShoulder and not rShoulder then
--			pressRS=false
--			--SendKeyDown("1")
--			SendKeyUp("1")
--			
--		end
--	end
--	if pressLS then
--		SendKeyDown("4")
--		--print("pressed2")
--		--pressLS=false
--		--pressButton(state,XINPUT_GAMEPAD_DPAD_DOWN)
--		if not lShoulder and not rShoulder then
--			pressLS=false
--			--SendKeyDown("2")
--			SendKeyUp("4")
--		end
--	end
--	if pressLH then
--		SendKeyDown("G")
--		--pressButton(state,XINPUT_GAMEPAD_DPAD_DOWN)
--		if not lShoulder and not rShoulder then
--			pressLH=false
--			--SendKeyDown("2")
--			SendKeyUp("G")
--		end
--	end
--	if pressRH then
--		SendKeyDown("2")
--		--pressButton(state,XINPUT_GAMEPAD_DPAD_RIGHT)
--		if not lShoulder and not rShoulder then
--			pressRH=false
--			--SendKeyDown("3")
--			SendKeyUp("2")
--		end
--	end
--	if pressRC then
--		--pressButton(state,XINPUT_GAMEPAD_DPAD_LEFT)
--		SendKeyDown("3")
--		if not lShoulder and not rShoulder then
--			pressRC=false
--			--SendKeyDown("4")
--			SendKeyUp("3")
--		end
--	end
--end
local wasMouseRight= false
local LTriggerLast=false
local rShoulderLast=false
--local CanReload=true
function UpdateInput(state,cpawn)

--Read Gamepad stick input 
	ThumbLX = state.Gamepad.sThumbLX
	ThumbLY = state.Gamepad.sThumbLY
	ThumbRX = state.Gamepad.sThumbRX
	ThumbRY = state.Gamepad.sThumbRY
	LTrigger= state.Gamepad.bLeftTrigger
	RTrigger= state.Gamepad.bRightTrigger
	rShoulder= isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER)
	lShoulder= isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER)
	lThumb   = isButtonPressed(state, XINPUT_GAMEPAD_LEFT_THUMB)
	rThumb   = isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_THUMB)
	Abutton  = isButtonPressed(state, XINPUT_GAMEPAD_A)
	Bbutton  = isButtonPressed(state, XINPUT_GAMEPAD_B)
	Xbutton  = isButtonPressed(state, XINPUT_GAMEPAD_X)
	Ybutton  = isButtonPressed(state, XINPUT_GAMEPAD_Y)
	DPAD_Up   =isButtonPressed(state, XINPUT_GAMEPAD_DPAD_UP)
	DPAD_Right=isButtonPressed(state, XINPUT_GAMEPAD_DPAD_RIGHT)
    DPAD_Left =isButtonPressed(state, XINPUT_GAMEPAD_DPAD_LEFT)
	DPAD_Down =isButtonPressed(state, XINPUT_GAMEPAD_DPAD_DOWN)
	vr.get_joystick_axis(vr.get_right_joystick_source(), StickR)
	if not isCinematic and not isMenu then
		--unpressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
		--unpressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		--unpressButton(state,XINPUT_GAMEPAD_X)
		--state.Gamepad.bLeftTrigger=0
		--state.Gamepad.bRightTrigger=0
		-- state.Gamepad.sThumbLX=0
		-- state.Gamepad.sThumbLY=0
	end

	
	if DPAD_Up   
	   or DPAD_Right
	   or DPAD_Left 
	   or DPAD_Down
		then
		WpnSwitch=true
		ChangeReq=true
	end
	--if  WasReloadPressed then
		--SendKeyUp("R")
	--	WasReloadPressed=false
	--end
	
	
	
	if  lShoulder  then-- and not canChange then
	--	SendKeyDown("0x02")
		wasMouseRight=true
		--print("heee")
	elseif wasMouseRight then
		--SendKeyUp("0x02")
		wasMouseRight=false
	end
	--if  GetHandDistance() <=10 and lShoulder and rShoulder then
	--	pressButton(state,XINPUT_GAMEPAD_LEFT_SHOULDER)
		--pressButton(state,XINPUT_GAMEPAD_RIGHT_SHOULDER)
	--end
	if Xbutton and PosDiffWeaponHand > 30 then
		--pressButton(state,XINPUT_GAMEPAD_RIGHT_THUMB)
	end
	
	
--	SprintRoll(state,cpawn)	
--	CollisionFunctionExecute(state,cpawn)
	--print(PosDiffWeaponHand)
--	print(pressLS)
	
--	if LTrigger~=LTriggerLast or rShoulder~=rShoulderLast then
--	WpnLocationUpdate=true 	
--	WpnUpdateDelta=0
--	end 
--	LTriggerLast=LTrigger
--	rShoulderLast=rShoulder
end





uevr.sdk.callbacks.on_xinput_get_state(
function(retval, user_index, state)
	local dpawn=nil
	dpawn=api:get_local_pawn(0)
	--from here
	UpdateInput(state,dpawn)
	--HolsterScript
	HolsterInput(state)	
	--MeleeScript
	MeleeInput(state)
	--CameraScript
	CameraInput(state)
	--Controlinputscript
	--CustomInput
	ControlInputInput(state)
end)

local last_level=nil
local engine =nil
local function OnLevelChange()
		if engine==nil then
			engine = game_engine_class:get_first_object_matching(false)
		end
		if not engine then
			return
		end
	
		local viewport = engine.GameViewport
	
		if viewport then
			 world = viewport.World
	
			if world then
				local level = world.PersistentLevel
	
				if last_level ~= level then					
					
					right_hand_component=nil
					left_hand_component=nil	
					Diff_Vector_LR  =nil
					Diff_Rotator_LR =nil
					RightRotator     =nil
					LeftRotator=nil	
				--	hmd_component=nil
					
					ResetDelta=0
					
					right_hand_Constraint=nil
					AffectedMesh=nil
					AnchorMesh  =nil
					 AffectedMeshL =nil
					AnchorMeshL=nil
					left_hand_Constraint=nil
					--RHandM=nil
				--	LHandM=nil
					StatsComp=nil
					
					CurrentWeaponMesh=nil
					HandSceneComp=nil
					Cam=nil
					StatsComp=nil
					if UEVR_UObjectHook.exists(RHandM) then
					--	RHandM:DestroyComponent()
					end
					if UEVR_UObjectHook.exists(LHandM)then
					--	LHandM:DestroyComponent()
					end
				--	LHandM= nil
				--	RHandM= nil
					
					CameraManager= UEVR_UObjectHook.get_first_object_by_class(CameraManager_C)
					--controllers.destroyControllers()
				----	AssignMotionComp(1)
				--	AssignMotionComp(2)
				--	AssignMotionComp(0)
			--		controllers.onLevelChange()
					--if not controllers.controllerExists(2)then
						if controllers.getHMDController() then
							hmd_component = controllers.getHMDController()
						else
							hmd_component=controllers.createHMDController()--controllers.createHMDController()		
						end
						
					--else hmd_component = controllers.getController(2)
					--end
			--			UEVR_UObjectHook.get_or_add_motion_controller_state(hmd_component):set_hand(2)
			--		--print(hmd_component)
					if not controllers.controllerExists(0) then
						left_hand_component =	controllers.createController(0)
						left_hand_component=controllers.getController(0)
					else left_hand_component=controllers.getController(0)
					end
					--left_hand_component= controllers.createControllerComponent(createActor(0), "Left", 0)	
					if not controllers.controllerExists(1) then
						right_hand_component =	controllers.createController(1)
						right_hand_component= controllers.getController(1)
					else right_hand_component= controllers.getController(1)
					end
					
					InitH=false
					isInitH=false
					
					
					--VRHUD
					UpdateHudOnLevelChange()
					--HANDS:
		--			local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
		--			local configName = 'Main' -- the name you gave your config
		--			local animationName = 'Shared' -- the name you gave your animation
		--			--if not hands.exists() then
		--				hands.destroyHands()
		--			--	hands.createFromConfig(paramsFile, configName, animationName)
		--			--end
		--			RHandM=hands.getHandComponent(Handed.Right)
		--			LHandM= hands.getHandComponent(Handed.Left) 
			--		if pawn.FirstPersonHandsChildActorComponent.ChildActor then
			--			pawn.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent:SetVisibility(false)
			--		end
			--		
			--		end
			--		
			--		if RHandM ~=nil then
			--			RHandM.bAbsoluteScale=false--:SetVisibility(true,false)
			--		end
			--		if LHandM ~=nil then
			--			LHandM.bAbsoluteScale=false--:SetVisibility(true,false)
				


				end
					
					
	
				last_level = level
			end
		end
end
local dENGINE=nil
local dDelta = 0
local CurrentPos={}
uevr.sdk.callbacks.on_pre_engine_tick(
	function(engine, delta)
	--if dpawn==nil then 
	local dpawn=api:get_local_pawn(0)	
	--end
	dENGINE = engine
	dDelta=delta
	if right_hand_component == nil and controllers.controllerExists(1) then
		right_hand_component = controllers.getController(1)
	elseif not  controllers.controllerExists(1) then
	--else print("foundright")
	end
	if left_hand_component == nil and controllers.controllerExists(0) then
		left_hand_component = controllers.getController(0)
	elseif not controllers.controllerExists(0) then
		controllers.createController(0)
	--else print(left_hand_component)
	end
	
	--RHandM=hands.getHandComponent(Handed.Right)
	--LHandM= hands.getHandComponent(Handed.Left) 
	local Player=api:get_player_controller(0)	
	--Player.bShowMouseCursor=true
		
		OnLevelChange()
		--hmd_component=controllers.createHMDController()
		--CustomInput(dpawn,delta)
		--print("hey")
		--CinematicStatus(pawn)
		--MenuStatus(Player)
		UpdateRidingStatus(dpawn)
		
		--print(hmd_component)
		--if WidgetComponent==nil then
		
		UpdateMenuStatus(Player)
		UpdateCombatStanceStatus(dpawn)	
		UpdateBowStatus(dpawn)	
		UpdateSprintStatus()
		--Custom:
		CalculateHelperVectors()
		--CameraManager
		UpdateCameraManager(dpawn,Player)
		
		--VRHUD:
		InitHud(dpawn)
		
		--Attachements:
		local WeaponMesh=dpawn.WeaponsPairingComponent
		local BodyMesh= dpawn.MainSkeletalMeshComponent
		--
		
		update_weapon_offset(WeaponMesh)
		update_Body_Meshes(BodyMesh)
		--HolsterScript: Still in holsterscirpt lua fully
		HolsterScript(dpawn,Player)
		--MELEE:
		--print(GetPlayerValues(dpawn).Stamina)
		Melee(dpawn,Player,engine,delta)
		--Hands
		
		--PhysicsEmuTest:
		--print(dpawn.CapsuleComponent:GetComponentVelocity().X)
		
		CounterMoveAffected(dpawn, CurrentPos)
		--UpdatePhysicsConstraintLogic(dpawn,engine.GameViewport.World,delta)
		--	WeaponMesh.WeaponActor.RootComponent:K2_AttachToComponent(right_hand_component,"",0,0,0,true)
		--	WeaponMesh.WeaponActor.RootComponent.RelativeLocation.X=0
		--	WeaponMesh.WeaponActor.RootComponent.RelativeLocation.Y=0
		--	WeaponMesh.WeaponActor.RootComponent.RelativeLocation.Z=0
	--	CustomInput(dpawn,delta)
end)
uevr.sdk.callbacks.on_post_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
local dpawn=api:get_local_pawn(0)	
CurrentPos = position
if dENGINE ~=nil then
	--UpdatePhysicsConstraintLogic(dpawn,dENGINE.GameViewport.World,dDelta)
			local WeaponMesh=dpawn.WeaponsPairingComponent
		--CounterMoveAffected(dpawn)
		UpdatePhysicsConstraintLogic(dpawn,dENGINE.GameViewport.World,dDelta)
	--WeaponMesh.WeaponActor.RootComponent:K2_SetWorldLocation(right_hand_component:K2_GetComponentLocation(),false, {},true)
	--WeaponMesh.WeaponActor.RootComponent:SetEnableGravity(false)
	--WeaponMesh.WeaponActor.RootComponent:K2_SetWorldRotation(right_hand_component:K2_GetComponentRotation(),false,{},true)
	
end
		
end)