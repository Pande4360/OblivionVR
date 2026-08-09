local uevrUtils = require("libs/uevr_utils")
local controllers = require("libs/controllers")
local animation = require("libs/animation")
local handAnimations = require("addons/hand_animations")

--[[
Instruction for positioning hands
	1) Figure out in the UEVR UI how to access the skeletal mesh component that contains the hands. In TOW it is pawn.FPVMesh
		In HL it is the hands and gloves components that are children of the pawn.Mesh
	2) Call animation.logBoneNames(skeletalMeshComponent) where skeletalMeshComponent is the thing found in step 1.
	3) In the log you will see a list of names for bones in the skeleton. Find the one for either the wrist or lower arm 
		joint (depending on how much of the arm you want to see) for both the left and right arms. Assign these values 
		to leftJointName and rightJointName below
	4) Find the left and right shoulders the same way and assign them to leftShoulderName and rightShoulderName. Note that if
		you still have visual artifacts when using the shoulder bone you may need to use the bone one step closer to the root 
	5) Call animation.getHierarchyForBone(skeletalMeshComponent,rightJointName)
		For TOW this is animation.getHierarchyForBone(pawn.FPVMesh, "r_LowerArm_JNT")
	6) In the log you will see the bone hierarchy back to the root. Take the root name (the one before "None") and 
		put it in defaultRootBoneName
	7) In your main.lua call 
			hands.reset() 
		in on_level_change(level)
		If you dont already have motionControllers set up, call
			controllers.onLevelChange()
			controllers.createController(0)
			controllers.createController(1)
		in on_level_change(level) as well
	8) In your main.lua call
			if not hands.exists() then
				hands.create(skeletalMeshComponent)
			end
		in the on_lazy_poll() function where skeletalMeshComponent is the component you found in step 1
	9) Run the game and the hands should be relatively close to where you would expect them to be. They
		will likely be rotated the wrong way but you can use code similar to the following to make adjustments
		in realtime while wearing the hmd to get them positioned perfectly. The updated positions
		will be printed to the log so you can take the last printed position and put the info in either
		currentRightRotation, currentLeftRotation, currentRightLocation or currentLeftLocation below
		
			local currentHand = 1
			register_key_bind("y", function()
				--hands.adjustLocation(currentHand, 1, 1)
				hands.adjustRotation(currentHand, 1, 45)
			end)
			register_key_bind("b", function()
				--hands.adjustLocation(currentHand, 1, -1)
				hands.adjustRotation(currentHand, 1, -45)
			end)
			register_key_bind("h", function()
				--hands.adjustLocation(currentHand, 2, 1)
				hands.adjustRotation(currentHand, 2, 45)
			end)
			register_key_bind("g", function()
				--hands.adjustLocation(currentHand, 2, -1)
				hands.adjustRotation(currentHand, 2, -45)
			end)
			register_key_bind("n", function()
				--hands.adjustLocation(currentHand, 3, 1)
				hands.adjustRotation(currentHand, 3, 45)
			end)
			register_key_bind("v", function()
				--hands.adjustLocation(currentHand, 3, -1)
				hands.adjustRotation(currentHand, 3, -45)
			end)


Instructions for getting hand animations
	1) Get a list of all the bones for your skeletal component
		animation.logBoneNames(rightHandComponent)
	2) Create a bonelist by viewing the list from step one. A bonelist is an array of the
		indexes of the knuckle bone of each finger starting from the thumb for each hand
		The list should be length 10, one for each finger
		local handBoneList = {50, 41, 46, 29, 34, 65, 70, 75, 80, 85}
	3) Log the bone rotators for all of the fingers
		animation.logBoneRotators(rightHandComponent, handBoneList)
	4) The printout gives you the default pose angles that can be used in the hand_animations.lua file. These can be
		your resting pose angles if you wish (the "off" values)
	5) Map keypresses to calls to modify bones dynamically as you view them in game. Once you have a hand posed as you like, use the printed values in	
		the hand_animations files(the "on" values)
		example keypress mapping:
		]]--

		


local M = {}

--for location x is +up/-down-pitch   y is left/right-roll z is +back/-forth-yaw
local currentRightRotation = {77, 34, -85}
local currentRightLocation = {-136.5, -18.4, 32.5}
local currentLeftRotation = {-90, -90, 0}
 currentLeftLocation = {-145, -26, 33}--{-140, -28, 32}
local currentScale = 1.0

 rightHandComponent = nil
 leftHandComponent = nil

 leftJointName = "lowerarm_l"
 rightJointName = "lowerarm_r"
 leftShoulderName = "Pelvis" --"l_shoulder_JNT"
 rightShoulderName = "Pelvis" --"r_shoulder_JNT"
 local defaultRootBoneName = "spine_05"
 rootBoneName = defaultRootBoneName

local rootBones = {}
rootBones[1] = {bone=defaultRootBoneName, offset={X=0, Y=0, Z=0, Pitch=0, Yaw=0, Roll=0}}

local boneList = {31, 53, 74,92,114,167,189,211,233,254}

 handBoneList = {31, 53, 74,92,114,167,189,211,233,254 }

function M.print(text)
	uevrUtils.print("[hands] " .. text)
end

function M.reset()
	rightHandComponent = nil
	leftHandComponent = nil
end

function M.exists()
	return rightHandComponent ~= nil or leftHandComponent ~= nil
end
local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local vr=uevr.params.vr

--local skeletalMeshComponent = pawn.FirstPersonHandsChildActorComponent.AttachChildren[1]
function M.create(skeletalMeshComponent)
	if skeletalMeshComponent ~= nil then
		M.print("Creating hands from " .. skeletalMeshComponent:get_full_name() )	
		rightHandComponent = M.createComponent(skeletalMeshComponent, "Arms", 1)
		if rightHandComponent ~= nil then
			leftHandComponent = M.createComponent(skeletalMeshComponent, "Arms", 0)	
			
			animation.add("right_hand", rightHandComponent, handAnimations)
			animation.add("left_hand", leftHandComponent, handAnimations)			
		end
	else
		M.print("SkeletalMesh component is nil in create" )
	end
end

function M.createComponent(skeletalMeshComponent, name, hand)
	local component = nil
	if uevrUtils.validate_object(skeletalMeshComponent) ~= nil  then
		--not using an existing actor as owner. Mesh affects the hands opacity so its not appropriate
		component = animation.createPoseableComponent(skeletalMeshComponent, nil)
		if component ~= nil then
			--fixes flickering but > 1 causes a perfomance hit with dynamic shadows according to unreal doc
			--a better way to do this should be found
			component.BoundsScale = 16.0
			component.bCastDynamicShadow = false

			rootBoneName = defaultRootBoneName
			local rootOffset = nil
			for index = 1 , #rootBones do			
				local elem = rootBones[index]
				if animation.hasBone(component, elem["bone"]) then
					rootBoneName = elem["bone"]
					rootOffset = elem["offset"]
					break
				end
			end
			
			print("Using",rootBoneName,"\n")
			controllers.attachComponentToController(hand, component)
			uevrUtils.set_component_relative_transform(component, rootOffset, rootOffset)	

			local location = hand == 1 and uevrUtils.vector(currentRightLocation[1], currentRightLocation[2], currentRightLocation[3]) or uevrUtils.vector(currentLeftLocation[1], currentLeftLocation[2], currentLeftLocation[3])
			local rotation = hand == 1 and uevrUtils.rotator(currentRightRotation[1], currentRightRotation[2], currentRightRotation[3]) or uevrUtils.rotator(currentLeftRotation[1], currentLeftRotation[2], currentLeftRotation[3])
			animation.initPoseableComponent(component, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
		end
	end
	return component
end
   
function M.getHandComponent(hand)
	local component = nil
	if hand == 0 then
		component = leftHandComponent
	else
		component = rightHandComponent
	end
	return component
end 

function M.handleInput(state, isHoldingWeapon)
	
	local triggerValue = state.Gamepad.bLeftTrigger
	animation.updateAnimation("left_hand", "left_trigger", triggerValue > 100)

	animation.updateAnimation("left_hand", "left_grip", uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_LEFT_SHOULDER))

    local left_controller = uevr.params.vr.get_left_joystick_source()
    local h_left_rest = uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchLeft")    
	animation.updateAnimation("left_hand", "left_thumb", uevr.params.vr.is_action_active(h_left_rest, left_controller))
 
 	if not isHoldingWeapon then
		local triggerValue = state.Gamepad.bRightTrigger
		animation.updateAnimation("right_hand", "right_trigger", triggerValue > 100)

		animation.updateAnimation("right_hand", "right_grip", uevrUtils.isButtonPressed(state, XINPUT_GAMEPAD_RIGHT_SHOULDER))

		local right_controller = uevr.params.vr.get_right_joystick_source()
		local h_right_rest = uevr.params.vr.get_action_handle("/actions/default/in/ThumbrestTouchRight")  
		animation.updateAnimation("right_hand", "right_thumb", uevr.params.vr.is_action_active(h_right_rest, right_controller))
	else
		local triggerValue = state.Gamepad.bRightTrigger
		animation.updateAnimation("right_hand", "right_trigger_weapon", triggerValue > 100)
	end

end

function M.setFingerAngles(fingerIndex, jointIndex, angleID, angle)
	animation.setFingerAngles(fingerIndex < 6 and leftHandComponent or rightHandComponent, handBoneList, fingerIndex, jointIndex, angleID, angle)
end

function M.adjustRotation(hand, axis, delta)
	local currentLocation = hand == 1 and currentRightLocation or currentLeftLocation
	local currentRotation = hand == 1 and currentRightRotation or currentLeftRotation
	currentRotation[axis] = currentRotation[axis] + delta
	print("Hand: ",hand," Rotation:",currentRotation[1], currentRotation[2], currentRotation[3],"\n")
	local location = uevrUtils.vector(currentLocation[1], currentLocation[2], currentLocation[3])
	local rotation = uevrUtils.rotator(currentRotation[1], currentRotation[2], currentRotation[3])
	animation.initPoseableComponent((hand == 1) and rightHandComponent or leftHandComponent, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
end

function M.adjustLocation(hand, axis, delta)
	local currentLocation = hand == 1 and currentRightLocation or currentLeftLocation
	local currentRotation = hand == 1 and currentRightRotation or currentLeftRotation
	currentLocation[axis] = currentLocation[axis] + delta
	print("Hand: ",hand," Location:",currentLocation[1], currentLocation[2], currentLocation[3],"\n")
	local location = uevrUtils.vector(currentLocation[1], currentLocation[2], currentLocation[3])
	local rotation = uevrUtils.rotator(currentRotation[1], currentRotation[2], currentRotation[3])
	animation.initPoseableComponent((hand == 1) and rightHandComponent or leftHandComponent, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
end

function M.SetLocation(hand, Desiredlocation)
	local currentLocation = Desiredlocation
	local currentRotation = hand == 1 and currentRightRotation or currentLeftRotation
	--currentLocation[axis] = currentLocation[axis] + delta
	print("Hand: ",hand," Location:",currentLocation[1], currentLocation[2], currentLocation[3],"\n")
	local location = uevrUtils.vector(currentLocation[1], currentLocation[2], currentLocation[3])
	local rotation = uevrUtils.rotator(currentRotation[1], currentRotation[2], currentRotation[3])
	animation.initPoseableComponent((hand == 1) and rightHandComponent or leftHandComponent, (hand == 1) and rightJointName or leftJointName, (hand == 1) and rightShoulderName or leftShoulderName, (hand == 1) and leftShoulderName or rightShoulderName, location, rotation, uevrUtils.vector(currentScale, currentScale, currentScale), rootBoneName)
end

function M.destroyHands()
	--since we didnt use an existing actor as parent in createComponent(), destroy the owner actor too
	uevrUtils.detachAndDestroyComponent(rightHandComponent, true)	
	uevrUtils.detachAndDestroyComponent(leftHandComponent, true)	
end
local api = uevr.api
	
	local params = uevr.params
	local callbacks = params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local vr=uevr.params.vr


local currentIndex = 1
		local currentFinger = 1
		register_key_bind("NumPadEight", function()
			animation.setFingerAngles(leftHandComponent,boneList,currentFinger, currentIndex, 0, 5)
		end)
		register_key_bind("NumPadTwo", function()
			animation.setFingerAngles(leftHandComponent,boneList,currentFinger, currentIndex, 0, -5)
		end)
		register_key_bind("NumPadSix", function()
			animation.setFingerAngles(leftHandComponent,boneList,currentFinger, currentIndex, 1, 5)
		end)
		register_key_bind("NumPadFive", function() -- switch the current finger
			currentFinger = currentFinger + 1
			if currentFinger > 10 then currentFinger = 1 end
			print("Current finger joint", currentFinger, currentIndex)
		end)
		register_key_bind("NumPadFour", function()
			animation.setFingerAngles(leftHandComponent,boneList,currentFinger, currentIndex, 1, -5)
		end)
		register_key_bind("NumPadNine", function()
			animation.setFingerAngles(leftHandComponent,boneList,currentFinger, currentIndex, 2, 5)
		end)
		register_key_bind("NumPadThree", function()
			animation.setFingerAngles(leftHandComponent,boneList,currentFinger, currentIndex, 2, -5)
		end)
		register_key_bind("NumPadZero", function() --switch to the next bone in the current finger
			currentIndex = currentIndex + 1
			if currentIndex > 3 then currentIndex = 1 end
			print("Current finger joint", currentFinger, currentIndex)
		end)


return M

--animation.logBoneNames(rightHandComponent)

-- lowerarm_r -> upperarm_r -> clavicle_r -> spine_05 -> spine_04 -> spine_03 -> spine_02 -> spine_01 -> pelvis -> Root -> None
-- 155			154			153				6			5			4			3			2			1

--lowerarm_l -> upperarm_r -> clavicle_r -> spine_05 -> spine_04 -> spine_03 -> spine_02 -> spine_01 -> pelvis -> Root -> None	
--19			18				17

--animation.logBoneRotators(rightHandComponent, handBoneList)