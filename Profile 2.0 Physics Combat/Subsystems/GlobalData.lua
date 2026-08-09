require(".\\Subsystems\\HelperFunctions")





 --Trackers
 hmd_component = nil
 right_hand_component= nil
 left_hand_component=nil 
 right_hand_handler = nil
 left_hand_handler = nil

--HandScriptGlobals:
LHandM = nil
RHandM = nil


Diff_Vector_LR  =nil
Diff_Rotator_LR =nil
RightRotator     =nil
LeftRotator=nil	
 HmdRotator = nil
 RHandLocation=		nil--	right_hand_component:K2_GetComponentLocation()
	LHandLocation=	nil--	left_hand_component:K2_GetComponentLocation()
	HmdLocation= 	nil--	hmd_component:K2_GetComponentLocation()
	
	DecoupledYawCurrentRot =0
  --Collisions:
 BoxCompLH=nil
 BoxCompRH=nil
 BoxCompHmdChestRight	=nil
 BoxCompHmdRightHip     =nil
 BoxCompHmdLeftHip      =nil
 BoxCompHmdRightShoulder=nil
 BoxCompHmdLeftShoulder=nil
 MagBox=nil
 
 --ControlInput
  ThumbLX   = 0
 ThumbLY   = 0
 ThumbRX   = 0
 ThumbRY   = 0
 LTrigger  = 0
 RTrigger  = 0
 rShoulder = false
 lShoulder = false
 lThumb    = false
 rThumb    = false
 Abutton = false
 Bbutton = false
 Xbutton = false
 Ybutton = false
 DPAD_Up   = false
 DPAD_Right= false
 DPAD_Left = false
 DPAD_Down = false
 StickR=UEVR_Vector2f.new()
 SelectButton=false
 AbsThumbFactor = 0
 canPressA=true
 
 --Statusses
 isSprinting=false
isDriving=false
isMenu=false
isWeaponDrawn=false
local GameTime= 0
isBow=false
isRiding=false
--local function UpdateBow
 
 
 
 --StaticClasses
 game_engine_class = find_required_object("Class /Script/Engine.GameEngine")
 kismet_string_library = find_static_class("Class /Script/Engine.KismetStringLibrary")
 kismet_math_library = find_static_class("Class /Script/Engine.KismetMathLibrary")
 kismet_system_library = find_static_class("Class /Script/Engine.KismetSystemLibrary")
 Statics = find_static_class("Class /Script/Engine.GameplayStatics")
 --Classes
 VHitBoxClass= find_required_object("Class /Script/Engine.BoxComponent")
 VHitSphereClass= find_required_object("Class /Script/Engine.SphereComponent")
 hitresult_c = find_required_object("ScriptStruct /Script/Engine.HitResult") 
 CameraManager_C = find_required_object("Class /Script/Engine.PlayerCameraManager")
 Key_C= find_required_object("ScriptStruct /Script/InputCore.Key")
 PhysicsComp_C= find_required_object("Class /Script/Engine.PhysicsHandleComponent")
 PhysicsConstraint_C = find_required_object("Class /Script/Engine.PhysicsConstraintComponent")
 ftransform_c = find_required_object("ScriptStruct /Script/CoreUObject.Transform")
  Rotator_c = find_required_object("ScriptStruct /Script/CoreUObject.Rotator")
 Vector_C = find_required_object("ScriptStruct /Script/CoreUObject.Vector")
 actor_c = find_required_object("Class /Script/Engine.Actor")
 --TempStructs:
 TempKey = StructObject.new(Key_C)
 Temphitresult = StructObject.new(hitresult_c)
 
 --Globals:
 CurrentEquipmentArray = {}

 LeftController=uevr.params.vr.get_left_joystick_source()
 StickFactor = 0
 gDelta = 0
 isMenu=false
 isSprinting=false

 CameraManager=UEVR_UObjectHook.get_first_object_by_class(CameraManager_C)
DecoupledYawCurrentRot = 0


 WpnLocationUpdate=false
 
 isThumbMotion=false

 CurrentWeaponMesh=nil
  
 FireWeapon=true
 world= nil
 isCinematic=false

 unpressShoulder=false

 wasRecentered=false
 isSprinting = false

 TrueMesh= nil

-- global functions:
function GetHandDistance()
	if right_hand_component == nil or left_hand_component==nil then return 0 end
	local rightLoc= right_hand_component:K2_GetComponentLocation()
	local leftLoc = left_hand_component:K2_GetComponentLocation()
	local Dist = kismet_math_library:Vector_Distance(rightLoc,leftLoc)
	return Dist
end

