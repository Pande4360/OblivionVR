local uevrUtils = require('libs/uevr_utils')
local hands = require('libs/hands')
require(".\\Subsystems\\GlobalData")

require(".\\Subsystems\\GlobalDataCustom")
local controllers = require('libs/controllers')

function on_level_change(level)
	--if not controllers.controllerExists(0) then
	--					left_hand_component =	controllers.createController(0)
	--					left_hand_component=controllers.getController(0)
	--				else left_hand_component=controllers.getController(0)
	--				end
	--				--left_hand_component= controllers.createControllerComponent(createActor(0), "Left", 0)	
	--				if not controllers.controllerExists(1) then
	--					right_hand_component =	controllers.createController(1)
	--					right_hand_component= controllers.getController(1)
	--				else right_hand_component= controllers.getController(1)
	--				end
	--hands.reset()
	--hmd_component=controllers.createHMDController()
	local paramsFile = 'hands_parameters' -- found in the [game profile]/data directory
	local configName = 'Main' -- the name you gave your config
	local animationName = 'Shared' -- the name you gave your animation
	if not hands.exists() then
	hands.createFromConfig(paramsFile, configName, animationName)
	RHandM=hands.getHandComponent(Handed.Right)
	LHandM= hands.getHandComponent(Handed.Left) 
	if pawn.FirstPersonHandsChildActorComponent.ChildActor then
		pawn.FirstPersonHandsChildActorComponent.ChildActor.RootSkeletalMeshComponent:SetVisibility(false)
	end
	
	end
	
	if RHandM ~=nil then
		RHandM.bAbsoluteScale=false--:SetVisibility(true,false)
	end
	if LHandM ~=nil then
		LHandM.bAbsoluteScale=false--:SetVisibility(true,false)
	end
	
	
	--pawn.Mesh:SetMaterial(0,nil)
end

function on_xinput_get_state(retval, user_index, state)
	if hands.exists() then
		local isHoldingWeapon = false
		local hand = Handed.Right
		hands.handleInput(state, isHoldingWeapon, hand)
	end
end