--require(".\\Trackers\\Trackers")
local controllers = require('libs/controllers')
require(".\\Subsystems\\GlobalDataCustom")
require(".\\Subsystems\\HelperFunctions")
require(".\\Subsystems\\GlobalData")
require(".\\Config\\CONFIG")
--require(".\\Subsystems\\ControlInput")
--local api = uevr.api
--local params = uevr.params
--local callbacks = params.sdk.callbacks
--local vr=uevr.params.vr
--local function find_required_object(name)
--    local obj = uevr.api:find_uobject(name)
--    if not obj then
--        error("Cannot find " .. name)
--        return nil
--    end
--
--    return obj
--end
--local find_static_class = function(name)
--    local c = find_required_object(name)
--    return c:get_class_default_object()
--end
--
--local hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult")
local reusable_hit_result1 = StructObject.new(hitresult_c)
local CamAngle=RightRotator
local AttackDelta=0
local HandVector= Vector3f.new(0.0,0.0,0.0)
local HmdVector = Vector3f.new(0.0,0.0,0.0)
local VecAlpha  = Vector3f.new(0,0,0)
local Alpha  	= nil
local AlphaDiff= 0
local LastState= isBow
local ConditionChagned=false
local isMenuEnter=false
local YawLast=0
local DecoupledYawCurrentRot = 0
local LeftRightScaleFactor		=0
local ForwardBackwardScaleFactor=0
local IsRecentered=false

function UpdateCameraManager(pawn,player)
	--hmd_component=controllers.createHMDController()	
	if isMenu and isMenuEnter==false then
		uevr.params.vr.set_mod_value("UI_FollowView", "false")
		isMenuEnter=true
		--print("CHeck")
		vr:recenter_view()
		
		player:ClientSetRotation(Vector3f.new(0,YawLast,0),true)
		DecoupledYawCurrentRot=YawLast
	elseif  not isMenu and isMenuEnter  then
		DecoupledYawCurrentRot=YawLast
		isMenuEnter=false
		if UIFollowsView then 
		uevr.params.vr.set_mod_value("UI_FollowView", "true")
		else uevr.params.vr.set_mod_value("UI_FollowView", "false") end
		
	end
	if not isMenu then
		YawLast= 0
		if hmd_component~=nil then
			YawLast=hmd_component:K2_GetComponentRotation().y
		end
	end
	
	--print(isRiding
	if not isRiding then
		--uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "true")
		if isBow then
			--print("calc")
		--	uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
			
			--local pawn = api:get_local_pawn(0)
			--local player =api:get_player_controller(0)
			local CameraManager=player.PlayerCameraManager
			local CameraComp= CameraManager.ViewTarget.Target.CameraComponent
			
			
			--print(isBow)
			
			-- Diff_Rotator_LR
			if isBow and RTrigger ~= 0 then
				
					AttackDelta=0
					
				CamAngle=Diff_Rotator_LR_Arrow
				
				
			end
			if RTrigger ==0 and AttackDelta < 2 then
				AttackDelta=AttackDelta+delta
			end 
			if isBow and RTrigger ==0 and AttackDelta> 1 then
				CamAngle=RightRotator
			elseif not isBow  and AttackDelta>1 then CamAngle=RightRotator
			elseif AttackDelta <= 1 then CamAngle=Diff_Rotator_LR_Arrow
			end
			
			local CamPitch=-CamAngle.x
			local CamYaw=CamAngle.y
			if not isBow then
				CamYaw=CamAngle.y
				CamPitch=CamAngle.x
			end
			if isBow and RTrigger == 0 and AttackDelta>1 then
				CamYaw=CamAngle.y
				CamPitch=CamAngle.x
			elseif isBow and AttackDelta<=1 then 
				CamPitch=CamAngle.x
				CamYaw=CamAngle.y
			end
		----pcall(function()
			if not QuickMenu then
				player:ClientSetRotation(Vector3f.new(CamPitch-7,CamYaw+2,0),true)
			end
		--end)
		
			
			
			
			
			HmdVector=hmd_component:GetForwardVector()
			HandVector= right_hand_component:GetForwardVector()
			
		--	VecAlpha = (HandVector.x - HmdVector.x, HandVector.y - HmdVector.y, HandVector.z - HmdVector.z)
								local VecAlphaX= HandVector.x - HmdVector.x
								local VecAlphaY= HandVector.y - HmdVector.y
								local Alpha1
								local Alpha2
								if HandVector.x >=0 and HandVector.y>=0 then	
								Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
								--print("Quad1")
								elseif HandVector.x <0 and HandVector.y>=0 then
								--print("Quad2")
								Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
								elseif HandVector.x <0 and HandVector.y<0 then
								--print("Quad3")
								Alpha1 =math.pi+math.pi/2+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
								elseif HandVector.x >=0 and HandVector.y<0 then
								--print("Quad4")
								Alpha1 =3/2*math.pi+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
								end
								
								if HmdVector.x >=0 and HmdVector.y>=0 then	
								Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
								--print("Quad1")
								elseif HmdVector.x <0 and HmdVector.y>=0 then
								--print("Quad2")
								Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
								elseif HmdVector.x <0 and HmdVector.y<0 then
								--print("Quad3")
								Alpha2 =math.pi+math.pi/2+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
								elseif HmdVector.x >=0 and HmdVector.y<0 then
								--print("Quad4")
								Alpha2 =3/2*math.pi+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
								end
								
								
								AlphaDiff= Alpha2-Alpha1
								if isBow and RTrigger ~= 0 then
									AlphaDiff=AlphaDiff-math.pi*20/180
								end
			
			
			
		elseif HeadBasedMovement then 
			uevr.params.vr.set_mod_value("VR_MovementOrientation", "1")
		elseif HeadBasedMovement==false then
			uevr.params.vr.set_mod_value("VR_MovementOrientation", "2")
		end
		
		
				
		if not isSprinting then
			LeftRightScaleFactor= ThumbLX/32767		
			ForwardBackwardScaleFactor = ThumbLY/32767
			--pawn.Controller.ControlRotation.Yaw = hmd_component:K2_GetComponentRotation().Yaw
			--vr.recenter_view()
			if HeadBasedMovement and hmd_component~=nil then
				--HandVector= right_hand_component:GetForwardVector()
				hmd_component:GetForwardVector()
								
				pawn:AddMovementInput(hmd_component:GetForwardVector(),ForwardBackwardScaleFactor,true)
				pawn:AddMovementInput(hmd_component:GetRightVector(),LeftRightScaleFactor,true)
				uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
			elseif not HeadBasedMovement then
				--HandVector= right_hand_component:GetForwardVector()
				right_hand_component:GetForwardVector()
									
				pawn:AddMovementInput(right_hand_component:GetForwardVector(),ForwardBackwardScaleFactor,true)
				pawn:AddMovementInput(right_hand_component:GetRightVector(),LeftRightScaleFactor,true)
				uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
			end
		end
		IsRecentered=false
	else uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
		if not IsRecentered then
			vr:recenter_view()
			IsRecentered=true
		end
		--uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
	end
	
	if LastState == not isBow then
		LastState=isBow
		ConditionChagned=true
		--print("ConditionChagned")
	end

end





--uevr.sdk.callbacks.on_pre_engine_tick(
--function(engine, delta)
--local pawn = api:get_local_pawn(0)
--if isMenu and isMenuEnter==false then
--	uevr.params.vr.set_mod_value("UI_FollowView", "false")
--	isMenuEnter=true
--	print("CHeck")
--	vr:recenter_view()
--	local player =api:get_player_controller(0)
--	player:ClientSetRotation(Vector3f.new(0,YawLast,0),true)
--	DecoupledYawCurrentRot=YawLast
--elseif  not isMenu and isMenuEnter  then
--	DecoupledYawCurrentRot=YawLast
--	isMenuEnter=false
--	if UIFollowsView then 
--	uevr.params.vr.set_mod_value("UI_FollowView", "true")
--	else uevr.params.vr.set_mod_value("UI_FollowView", "false") end
--	
--end
--if not isMenu then
--	YawLast= 0
--	if hmd_component~=nil then
--		YawLast=hmd_component:K2_GetComponentRotation().y
--	end
--end
--
----print(isRiding
--if not isRiding then
--	uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "true")
--	if isBow then
--	
--		uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
--		
--		local pawn = api:get_local_pawn(0)
--		local player =api:get_player_controller(0)
--		local CameraManager=player.PlayerCameraManager
--		local CameraComp= CameraManager.ViewTarget.Target.CameraComponent
--		
--		
--		--print(isBow)
--		
--		-- Diff_Rotator_LR
--		if isBow and RTrigger ~= 0 then
--			
--				AttackDelta=0
--				
--			CamAngle=Diff_Rotator_LR_Arrow
--			
--			
--		end
--		if RTrigger ==0 and AttackDelta < 2 then
--			AttackDelta=AttackDelta+delta
--		end 
--		if isBow and RTrigger ==0 and AttackDelta> 1 then
--			CamAngle=RightRotator
--		elseif not isBow  and AttackDelta>1 then CamAngle=RightRotator
--		elseif AttackDelta <= 1 then CamAngle=Diff_Rotator_LR_Arrow
--		end
--		
--		local CamPitch=-CamAngle.x
--		local CamYaw=CamAngle.y
--		if not isBow then
--			CamYaw=CamAngle.y
--			CamPitch=CamAngle.x
--		end
--		if isBow and RTrigger == 0 and AttackDelta>1 then
--			CamYaw=CamAngle.y
--			CamPitch=CamAngle.x
--		elseif isBow and AttackDelta<=1 then 
--			CamPitch=CamAngle.x
--			CamYaw=CamAngle.y
--		end
--	----pcall(function()
--		if not QuickMenu then
--			player:ClientSetRotation(Vector3f.new(CamPitch-7,CamYaw+2,0),true)
--		end
--	--end)
--	
--		
--		
--		
--		
--		HmdVector=hmd_component:GetForwardVector()
--		HandVector= right_hand_component:GetForwardVector()
--		
--	--	VecAlpha = (HandVector.x - HmdVector.x, HandVector.y - HmdVector.y, HandVector.z - HmdVector.z)
--							local VecAlphaX= HandVector.x - HmdVector.x
--							local VecAlphaY= HandVector.y - HmdVector.y
--							local Alpha1
--							local Alpha2
--							if HandVector.x >=0 and HandVector.y>=0 then	
--							Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--							--print("Quad1")
--							elseif HandVector.x <0 and HandVector.y>=0 then
--							--print("Quad2")
--							Alpha1 =math.pi/2-math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--							elseif HandVector.x <0 and HandVector.y<0 then
--							--print("Quad3")
--							Alpha1 =math.pi+math.pi/2+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--							elseif HandVector.x >=0 and HandVector.y<0 then
--							--print("Quad4")
--							Alpha1 =3/2*math.pi+math.asin( HandVector.x/ math.sqrt(HandVector.y^2+HandVector.x^2))
--							end
--							
--							if HmdVector.x >=0 and HmdVector.y>=0 then	
--							Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--							--print("Quad1")
--							elseif HmdVector.x <0 and HmdVector.y>=0 then
--							--print("Quad2")
--							Alpha2 =math.pi/2-math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--							elseif HmdVector.x <0 and HmdVector.y<0 then
--							--print("Quad3")
--							Alpha2 =math.pi+math.pi/2+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--							elseif HmdVector.x >=0 and HmdVector.y<0 then
--							--print("Quad4")
--							Alpha2 =3/2*math.pi+math.asin( HmdVector.x/ math.sqrt(HmdVector.y^2+HmdVector.x^2))
--							end
--							
--							
--							AlphaDiff= Alpha2-Alpha1
--							if isBow and RTrigger ~= 0 then
--								AlphaDiff=AlphaDiff-math.pi*20/180
--							end
--		
--		
--		
--	elseif HeadBasedMovement then uevr.params.vr.set_mod_value("VR_MovementOrientation", "1")
--	elseif HeadBasedMovement==false then uevr.params.vr.set_mod_value("VR_MovementOrientation", "2")
--	end
--	
--	
--			
--	if not isSprinting then
--		LeftRightScaleFactor= ThumbLX/32767		
--		ForwardBackwardScaleFactor = ThumbLY/32767
--		if HeadBasedMovement and hmd_component~=nil then
--			--HandVector= right_hand_component:GetForwardVector()
--			hmd_component:GetForwardVector()
--							
--			pawn:AddMovementInput(hmd_component:GetForwardVector(),ForwardBackwardScaleFactor,true)
--			pawn:AddMovementInput(hmd_component:GetRightVector(),LeftRightScaleFactor,true)
--			uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
--		elseif not HeadBasedMovement then
--			--HandVector= right_hand_component:GetForwardVector()
--			right_hand_component:GetForwardVector()
--								
--			pawn:AddMovementInput(right_hand_component:GetForwardVector(),ForwardBackwardScaleFactor,true)
--			pawn:AddMovementInput(right_hand_component:GetRightVector(),LeftRightScaleFactor,true)
--			uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
--		end
--	end
--	IsRecentered=false
--else uevr.params.vr.set_mod_value("VR_MovementOrientation", "0")
--	if not IsRecentered then
--		vr:recenter_view()
--		IsRecentered=true
--	end
--	uevr.params.vr.set_mod_value("VR_RoomscaleMovement", "false")
--end
--
--if LastState == not isBow then
--	LastState=isBow
--	ConditionChagned=true
--	print("ConditionChagned")
--end
--end)


local RXState=0
local SnapAngle
 



--uevr.sdk.callbacks.on_xinput_get_state(
--function(retval, user_index, state)
function CameraInput(state)
--print(isBow)
if isBow  then

--Read Gamepad stick input for rotation compensation
	if HeadBasedMovement   then
	
	
		
	
	
		state.Gamepad.sThumbLX= ThumbLX*math.cos(-AlphaDiff)- ThumbLY*math.sin(-AlphaDiff)
				
		state.Gamepad.sThumbLY= math.sin(-AlphaDiff)*ThumbLX + ThumbLY*math.cos(-AlphaDiff)
		
	end
--print("hey")


	SnapAngle = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))
	if SnapTurn then
		if ThumbRX >200 and RXState ==0 and not isMenu then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SnapAngle
			RXState=1
		elseif ThumbRX <-200 and RXState ==0 and not isMenu  then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot - SnapAngle
			RXState=1
		elseif ThumbRX <= 200 and ThumbRX >=-200  then
			RXState=0
		end
 
	
	else
		
		SmoothTurnRate = PositiveIntegerMask(uevr.params.vr:get_mod_value("VR_SnapturnTurnAngle"))/90
	
	
		local rate = state.Gamepad.sThumbRX/32767
					rate =  rate*rate*rate
					--print(rate)
		if ThumbRX >2200 and not isMenu   then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SmoothTurnRate * rate
			
		elseif ThumbRX <-2200 and not isMenu   then
			DecoupledYawCurrentRot=DecoupledYawCurrentRot + SmoothTurnRate * rate
		
		end
	end

end
--print(DecoupledYawCurrentRot)
end



local PreRot
local DiffRot
local DecoupledYawCurrentRotLast=0
uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
PreRot=rotation.y

if isBow then
	if RightRotator==nil then
	print("CamMan 452")
	end
	if HmdRotator~=nil and RightRotator ~=nil and RightRotator.y ~=nil then
		DiffRot= HmdRotator.y - RightRotator.y
	
	
	
	
	local pawn = api:get_local_pawn(0)
	
	if pawn~=nil then
		position.x  = pawn:K2_GetActorLocation().x
		position.y  = pawn:K2_GetActorLocation().y
		position.z  = pawn:K2_GetActorLocation().z +80
	end
	
	if isBow  then	
		rotation.y = DecoupledYawCurrentRot
		
		if ConditionChagned then
		ConditionChagned=false
		-- vr.recenter_view()
		-- rotation.y=DecoupledYawCurrentRotLast	
		end
		
	else 
		if ConditionChagned then
		local player =api:get_player_controller(0)
		--rotation.y=DecoupledYawCurrentRotLast
		player:ClientSetRotation(Vector3f.new(HmdRotator.x , DecoupledYawCurrentRotLast	,0),true)
		ConditionChagned=false
		vr.recenter_view()
		end
		----rotation.y=DecoupledYawCurrentRotLast
		DecoupledYawCurrentRot=HmdRotator.y - DiffRot
	end
	end
end
end)

uevr.sdk.callbacks.on_early_calculate_stereo_view_offset(function(device, view_index, world_to_meters, position, rotation, is_double)
	--print(DecoupledYawCurrentRot)
local pawn=api:get_local_pawn(0)
if isRiding and FirstPersonRiding then
	--pawn.Rider.Mesh:SetVisibility(false,true)
	
	NewLoc=pawn.Rider.MainSkeletalMeshComponent:GetSocketLocation("Head_Socket")
	--pawn:GetForwardVector()
--	NewRot=pawn:GetActorRotation()
	position.x=NewLoc.x +pawn.Mesh:GetRightVector().x*10
	position.y=NewLoc.y +pawn.Mesh:GetRightVector().y*10
	position.z=NewLoc.z +10
	--rotation=NewRot
else
	position.x=pawn:K2_GetActorLocation().x
	position.y=pawn:K2_GetActorLocation().y
	position.z=pawn:K2_GetActorLocation().z+70


	--pawn.Mesh:SetVisibility(false,true)
end
	
if isBow  then	
	
	DecoupledYawCurrentRotLast=rotation.y	
else-- if ConditionChagned then
	--print("ok2")
	-- ConditionChagned=false
	---- vr.recenter_view()
	-- rotation.y=DecoupledYawCurrentRotLast	
	--end
end
end)