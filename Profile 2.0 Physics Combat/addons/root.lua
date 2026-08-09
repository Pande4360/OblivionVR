local uevrUtils = require("libs/uevr_utils")
local flickerFixer = require("libs/flicker_fixer")
local controllersModule = require("libs/controllers")

local M = {}

--calculates a world yaw based on head and hand positions
local function calculateYawAngle(headX, headY, headZ, leftHandX, leftHandY, leftHandZ, rightHandX, rightHandY, rightHandZ)
    -- Calculate the midpoint of the hands
    local midHandX = (leftHandX + rightHandX) / 2
    local midHandY = (leftHandY + rightHandY) / 2
    local midHandZ = (leftHandZ + rightHandZ) / 2

    -- Calculate the direction vector from head to the hand midpoint
    local dirX = midHandX - headX
    local dirY = midHandY - headY
    local dirZ = midHandZ - headZ -- We won't use Z for yaw calculation

    -- Reference vector for yaw (positive X-axis)
    local refX, refY = 1, 0 -- (1, 0) points along the X-axis

    -- Dot product of the direction vector and the reference vector
    local dotProduct = dirX * refX + dirY * refY

    -- Magnitudes of the vectors
    local dirMagnitude = math.sqrt(dirX^2 + dirY^2)
    local refMagnitude = math.sqrt(refX^2 + refY^2)

    -- Cosine of the angle using the dot product formula
    local cosTheta = dotProduct / (dirMagnitude * refMagnitude)

    -- Ensure cosTheta is within the valid range for acos (to avoid numerical errors)
    cosTheta = math.max(-1, math.min(1, cosTheta))

    -- Calculate the angle in radians
    local yaw = math.acos(cosTheta)

    -- Determine the direction of the angle (clockwise or counterclockwise)
    if dirY < 0 then
        yaw = -yaw
    end

    -- Convert the angle to degrees
    return math.deg(yaw)
end


local function detachCamera()
	if pawn.FPVCamera ~= nil then
		local parent = pawn.FPVCamera.AttachParent
		pawn.FPVCamera:DetachFromParent(true, false)
		pawn.FPVCamera:K2_AttachTo(pawn.RootComponent, uevrUtils.fname_from_string(""), 1, false)
	end
end

local function createRootComponent()
	local rootComponent = uevrUtils.create_component_of_class("Class /Script/Engine.SceneComponent", false)
	controllersModule.attachComponentToController(2, rootComponent, "", 0, false)
	return rootComponent
end

local function updateRootComponent()
	if m_rootComponent ~= nil then
		local rightLocation = controllersModule.getControllerLocation(1)
		local leftLocation = controllersModule.getControllerLocation(0)
		local hmdLocation = controllersModule.getControllerLocation(2)
		local yawAngle = calculateYawAngle(hmdLocation.X, hmdLocation.Y, hmdLocation.Z, leftLocation.X, leftLocation.Y, leftLocation.Z, rightLocation.X, rightLocation.Y, rightLocation.Z)
		
		local hmdRotation = controllersModule.getControllerRotation(2)
		m_rootComponent.RelativeRotation.Yaw =  yawAngle - hmdRotation.Yaw
	end

end

local function on_pre_engine_tick(engine, delta)
	--call this in tick
--	updateRootComponent()
	print("Root pre tick")
end

function M.create(skeletalMeshComponent)
	-- controllersModule.createController(2) 
	-- detachCamera()
	-- m_rootComponent = createRootComponent()
	-- skeletalMeshComponent:DetachFromParent(true,false)
	-- skeletalMeshComponent:K2_AttachTo(m_rootComponent, uevrUtils.fname_from_string(""), 0, false)
		
	uevrUtils.registerPreEngineTickCallback(on_pre_engine_tick)
end

return M