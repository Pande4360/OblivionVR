local uevrUtils = require("libs/uevr_utils")
--local flickerFixer = require("libs/flicker_fixer")
--local controllersModule = require("libs/controllers")
uevrUtils.initUEVR(uevr)
local animation = require("libs/animation")
local handAnimations = require("addons/hand_animations")
local hands = require("addons/hands")
local controllers = require("libs/controllers")
require(".\\Subsystems\\UEHelper")
require(".\\Subsystems\\GlobalData")

require(".\\Subsystems\\GlobalDataCustom")
local weaponConnected = false
local isHoldingWeapon = false

function on_level_change(level)
	print("Level changed\n")
	--controllers.onLevelChange()
	--controllers.createController(0)
	--controllers.createController(1)
	--controllers.createController(2)
	weaponConnected = true	
	--flickerFixer.create()
	--hands.destroyHands()
	hands.reset()
	animation.pose("right_hand", "grip_right_weapon")
	animation.pose("left_hand", "grip_left_weapon")
end

--function Reset_on_change_gear()
--	if 

function on_lazy_poll()
	if not hands.exists() then
		if not  string.find(pawn:get_fname():to_string(),"Horse") then
			if pawn.FirstPersonUpperBodyChildActorComponent.ChildActor ~=nil then
				if string.find(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Robe") then
					hands.create(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent)
				else--if 	--string.find(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Cuirass") then
					if pawn.FirstPersonHandsChildActorComponent.ChildActor ~=nil then
						hands.create(pawn.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent)
						
					else --hands.create(pawn.MainSkeletalMeshComponent)	
					end
				end
			elseif pawn.FirstPersonHandsChildActorComponent.ChildActor ~=nil then
						hands.create(pawn.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent)
					
					
			end	
		animation.pose("right_hand", "grip_right_weapon")
		animation.pose("left_hand", "grip_left_weapon")
		--else
		--	if pawn.Rider.FirstPersonUpperBodyChildActorComponent.ChildActor ~=nil then
		--			if string.find(pawn.Rider.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Robe") then
		--				hands.create(pawn.Rider.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent)
		--			else--if 	--string.find(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Cuirass") then
		--				if pawn.Rider.FirstPersonHandsChildActorComponent.ChildActor ~=nil then
		--					hands.create(pawn.Rider.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent)
		--				else --hands.create(pawn.FirstPersonSkeletalMeshComponent)
		--				end
		--			end
		--	end 
		end
		animation.pose("right_hand", "grip_right_weapon")
		animation.pose("left_hand", "grip_left_weapon")
	end
	--attachWeaponToController()
	--if pawn.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent ~= nil then
	--	fixPlayerFOV(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent)
	--end

end

function attachWeaponToController()
	if weaponConnected == false and pawn.GetCurrentWeapon ~= nil then
		local weapon = pawn:GetCurrentWeapon()
		if weapon ~= nil  then
			local mesh = weapon.SkeletalMeshComponent
			if mesh ~= nil then
				print(mesh:get_full_name())
				--print(weapon:get_full_name())
				mesh:DetachFromParent(false,false)
				mesh:SetVisibility(true, true)
				mesh:SetHiddenInGame(false, true)
				weaponConnected = controllers.attachComponentToController(1, mesh)
				uevrUtils.set_component_relative_transform(mesh, {X=0,Y=0,Z=0}, {Pitch=0,Yaw=0,Roll=0})
				fixWeaponFOV()
			end
		end
	end

end

function fixPlayerFOV(playerMesh)
	local propertyName = "ForegroundPriorityEnabled"
	local propertyFName = uevrUtils.fname_from_string(propertyName)	
	local value = 0.0
	
	local mesh = playerMesh
	if mesh ~= nil then
		local materials = mesh.OverrideMaterials
		for i, material in ipairs(materials) do
			--local oldValue = material:K2_GetScalarParameterValue(propertyFName)
			material:SetScalarParameterValue(propertyFName, value)
			--local newValue = material:K2_GetScalarParameterValue(propertyFName)
			--print("Material:",i, material:get_full_name(), oldValue, newValue,"\n")
		end

		children = mesh.AttachChildren
		if children ~= nil then
			for i, child in ipairs(children) do
				if child:is_a(static_mesh_component_c) then
					local materials = child.OverrideMaterials
					for i, material in ipairs(materials) do
						--local oldValue = material:K2_GetScalarParameterValue(propertyFName)
						material:SetScalarParameterValue(propertyFName, value)
						--local newValue = material:K2_GetScalarParameterValue(propertyFName)
						--print("Child Material:",i, material:get_full_name(), oldValue, newValue,"\n")
					end
				end
				
				if child:is_a(uevrUtils.get_class("Class /Script/Niagara.NiagaraComponent")) then
					child:SetNiagaraVariableFloat(propertyName, value)
					--print("Child Niagara Material:", child:get_full_name(),"\n")
				end
			end
		end
	end
end

function fixWeaponFOV()
	local propertyName = "ForegroundPriorityEnabled"
	local propertyFName = uevrUtils.fname_from_string(propertyName)	
	local value = 0.0
	
	local weapon = pawn:GetCurrentWeapon()
	if weapon ~= nil  then
		local mesh = weapon.SkeletalMeshComponent
		if mesh ~= nil then
			local materials = mesh.OverrideMaterials
			for i, material in ipairs(materials) do
				--local oldValue = material:K2_GetScalarParameterValue(propertyFName)
				material:SetScalarParameterValue(propertyFName, value)
				--local newValue = material:K2_GetScalarParameterValue(propertyFName)
				--print("Material:",i, material:get_full_name(), oldValue, newValue,"\n")
			end

			children = mesh.AttachChildren
			if children ~= nil then
				for i, child in ipairs(children) do
					if child:is_a(static_mesh_component_c) then
						local materials = child.OverrideMaterials
						for i, material in ipairs(materials) do
							--local oldValue = material:K2_GetScalarParameterValue(propertyFName)
							material:SetScalarParameterValue(propertyFName, value)
							--local newValue = material:K2_GetScalarParameterValue(propertyFName)
							--print("Child Material:",i, material:get_full_name(), oldValue, newValue,"\n")
						end
					end
					
					if child:is_a(uevrUtils.get_class("Class /Script/Niagara.NiagaraComponent")) then
						child:SetNiagaraVariableFloat(propertyName, value)
						--print("Child Niagara Material:", child:get_full_name(),"\n")
					end
				end
			end
		end
	end
end
-- Weapon FX get created at fire time so this needs to be called per tick
-- NiagaraComponent children get added and do not get deleted on each fire so the childlist could get 
--   large as the game proceeds
function fixWeaponFXFOV()
	local propertyName = "ForegroundPriorityEnabled"
	local value = 0.0
	
	if pawn.GetCurrentWeapon ~= nil then
		local weapon = pawn:GetCurrentWeapon()
		if weapon ~= nil  then
			local mesh = weapon.SkeletalMeshComponent
			if mesh ~= nil then
				children = mesh.AttachChildren
				if children ~= nil then
					for i, child in ipairs(children) do				
						if child:is_a(uevrUtils.get_class("Class /Script/Niagara.NiagaraComponent")) then
							child:SetNiagaraVariableFloat(propertyName, value)
							--print("Child Niagara Material:", child:get_full_name(),"\n")
						end
					end
				end
			end
		end
	end
end

function on_xinput_get_state(retval, user_index, state)
	--hands.handleInput(state, isHoldingWeapon)
end


function on_post_engine_tick(engine, delta)
	--fixWeaponFXFOV()
	
	if pawn.FPVMesh ~= nil then
		pawn.FPVMesh:SetVisibility(false,true)
	end
	--animation.updateSkeletalVisualization(hands.getHandComponent(1))

end



hook_function("Class /Script/Indiana.IndianaPlayerCharacter", "WeaponHolstered", true, 
	function(fn, obj, locals, result)
		print("IndianaPlayerCharacter WeaponHolstered")
		--isHoldingWeapon = false
		animation.pose("right_hand", "open_right")
		return false
	end
, nil, true)

hook_function("Class /Script/Indiana.IndianaPlayerCharacter", "WeaponUnholstered", true, 
	function(fn, obj, locals, result)
		print("IndianaPlayerCharacter WeaponUnholstered")
		--isHoldingWeapon = true
		animation.pose("right_hand", "grip_right_weapon")
		return false
	end
, nil, true)


register_key_bind("F1", function()
    print("F1 pressed\n")
	animation.logBoneNames(pawn.FPVMesh)
	animation.getHierarchyForBone(pawn.FPVMesh, "r_LowerArm_JNT")
	--animation.createSkeletalVisualization(hands.getHandComponent(1), 0.003)
end)

local currentHand = 0
local currentIndex = 1
local currentFinger = 1
register_key_bind("F2", function()
    print("F2 pressed\n")
	currentIndex = currentIndex + 1
	if currentIndex > 3 then currentIndex = 1 end
	print("Current finger joint", currentFinger, currentIndex)
end)

register_key_bind("F3", function()
    print("F3 pressed\n")
	currentFinger = currentFinger + 1
	if currentFinger > 10 then currentFinger = 1 end
	print("Current finger joint", currentFinger, currentIndex)
end)

--pitch
register_key_bind("y", function()
    print("y pressed\n")
	hands.adjustLocation(currentHand, 1, 0.5)
	--hands.adjustRotation(currentHand, 1, 45)
	--hands.setFingerAngles(currentFinger, currentIndex, 0, 5)
end)
register_key_bind("b", function()
    print("b pressed\n")
	hands.adjustLocation(currentHand, 1, -0.5)
	--hands.adjustRotation(currentHand, 1, -45)
	--setFingerAngles(currentFinger, currentIndex, 0, -5)
end)

--yaw
register_key_bind("h", function()
    print("h pressed\n")
	hands.adjustLocation(currentHand, 2, 0.5)
	--hands.adjustRotation(currentHand, 2, 45)
	--setFingerAngles(currentFinger, currentIndex, 1, 5)
end)
register_key_bind("g", function()
    print("g pressed\n")
	hands.adjustLocation(currentHand, 2, -0.5)
	--hands.adjustRotation(currentHand, 2, -45)
	--setFingerAngles(currentFinger, currentIndex, 1, -5)
end)

--roll
register_key_bind("n", function()
    print("n pressed\n")
	hands.adjustLocation(currentHand, 3, 0.5)
	--hands.adjustRotation(currentHand, 3, 45)
	--setFingerAngles(currentFinger, currentIndex, 2, 5)
end)
register_key_bind("v", function()
    print("v pressed\n")
	hands.adjustLocation(currentHand, 3, -0.5)
	--hands.adjustRotation(currentHand, 3, -45)
	--setFingerAngles(currentFinger, currentIndex, 2, -5)
end)
local isHoldingWeaponLast=false
local isChanged=false
local MenuChanged=false
--local NextChangeReset=false
uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)

if isMenu then
	MenuChanged=true
	--NextChangeReset=true
end
if not isMenu and MenuChanged then
	MenuChanged=false
	if rightHandComponent ~= nil then
		rightHandComponent:SetVisibility(false)
	end
	if leftHandComponent ~= nil then
		leftHandComponent:SetVisibility(false)
	end
	hands.destroyHands()
	hands.reset()
end
local BowHMDDiff=0
local BowHMDDist=0
if rightHandComponent~=nil then
	BowHMDDiff= rightHandComponent:K2_GetComponentLocation()- hmd_component:K2_GetComponentLocation()

	BowHMDDist= math.sqrt(BowHMDDiff.x^2+BowHMDDiff.y^2+BowHMDDiff.z^2)
end
if isBow and BowHMDDist< 15 and not isMenu then 
	if rightHandComponent ~= nil then
		rightHandComponent:SetVisibility(false)
	end
elseif isBow and not isMenu then
	if rightHandComponent ~= nil then
		rightHandComponent:SetVisibility(true)
	end
end
if not hands.exists() and not  string.find(pawn:get_fname():to_string(),"Horse")  then
	if pawn.FirstPersonUpperBodyChildActorComponent.ChildActor ~=nil then
			hands.destroyHands()
			--hands.reset()
			if string.find(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Robe") then
				hands.create(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent)
				
			else--if 	--string.find(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Cuirass") then
				if pawn.FirstPersonHandsChildActorComponent.ChildActor ~=nil then
					hands.destroyHands()
					--hands.reset()
					hands.create(pawn.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent)
					
				else --hands.create(pawn.FirstPersonSkeletalMeshComponent)
				end
			end
	elseif pawn.FirstPersonHandsChildActorComponent.ChildActor ~=nil then
			hands.destroyHands()
		--	hands.reset()
						hands.create(pawn.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent)
				
					
	end	
--else
--	if pawn.Rider.FirstPersonUpperBodyChildActorComponent.ChildActor ~=nil then
--			if string.find(pawn.Rider.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Robe") then
--				hands.create(pawn.Rider.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent)
--			else--if 	--string.find(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor:get_fname():to_string(),"Cuirass") then
--				if pawn.Rider.FirstPersonHandsChildActorComponent.ChildActor ~=nil then
--					hands.create(pawn.Rider.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent)
--				else --hands.create(pawn.FirstPersonSkeletalMeshComponent)
--				end
--			end
--	else 
--	end	
	--hands.reset()
	animation.pose("right_hand", "grip_right_weapon")
	animation.pose("left_hand", "grip_left_weapon")
end

if isWeaponDrawn and isHoldingWeapon==false then
	isHoldingWeapon=true
	animation.pose("right_hand", "grip_right_weapon")
	animation.pose("left_hand", "grip_left_weapon")
elseif not isWeaponDrawn and isHoldingWeapon==true then
isHoldingWeapon=false
animation.pose("right_hand", "open_right")
animation.pose("left_hand", "open_left")
animation.updateAnimation("left_hand", "left_trigger", false)
--animation.updateAnimation("right_hand", "right_grip", rShoulder)
 end
 if isHoldingWeaponLast ~= isHoldingWeapon then
	isChanged =true
end
 isHoldingWeaponLast=isHoldingWeapon
if isHoldingWeapon== false then
	animation.updateAnimation("right_hand", "right_grip", rShoulder)
	animation.updateAnimation("left_hand", "left_trigger", false)
	if LTrigger==0 then
	--animation.updateAnimation("right_hand", "right_grip", true)
	animation.updateAnimation("left_hand", "left_grip", lShoulder)
	animation.updateAnimation("left_hand", "left_trigger", LTrigger>0)
	elseif LTrigger ~= 0 and lShoulder then 
	animation.updateAnimation("left_hand", "left_trigger", LTrigger>0)
	end
end

--if  isChanged==true then
--	isChanged=false
	--if isBow and isWeaponDrawn then
		currentLeftLocation={-145, -26, 33}
	--	hands.SetLocation(0, currentLeftLocation)
		--hands.adjustLocation(currentHand, 1, 0.5)
	--else	
		--currentLeftLocation={-145, -26, 30}
		
--		local currentLeftRotation = {-90, -90, 0}
--		local location = uevrUtils.vector(currentLeftLocation[1], currentLeftLocation[2], currentLeftLocation[3])
--		local rotation = uevrUtils.rotator(currentLeftRotation[1], currentLeftRotation[2], currentLeftRotation[3])
--		
--		animation.initPoseableComponent((hand == 1) and rightHandComponent or leftHandComponent, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
--	else
		--currentLeftLocationOG = {-140, -28, 32}
--		hands.SetLocation(0, currentLeftLocationOG)
	--end
--end
--	 local currentLeftRotation = {-90, -90, 0}
--	local location = uevrUtils.vector(currentLeftLocation[1], currentLeftLocation[2], currentLeftLocation[3])
--	local rotation = uevrUtils.rotator(currentLeftRotation[1], currentLeftRotation[2], currentLeftRotation[3])
--	animation.initPoseableComponent((hand == 1) and rightHandComponent or leftHandComponent, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
--	end
--end


end)

--hands.reset() 
--on_level_change(level)
--on_lazy_poll()
--animation.logBoneNames(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent)
--animation.getHierarchyForBone(pawn.FirstPersonUpperBodyChildActorComponent.ChildActor.RootSkeletalMeshComponent,"lowerarm_r")
--animation.logBoneRotators(rightHandComponent, handBoneList)

		
