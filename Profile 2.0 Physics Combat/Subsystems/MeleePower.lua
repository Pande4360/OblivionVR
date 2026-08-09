	--CONFIG
	--require(".\\Subsystems\\UEHelper")
	
	--local MeleePower = 500 --Default = 1000
	---------------------------------------
	
	--require(".\\Config\\CONFIG")
	local controllers = require('libs/controllers')
	local MeleeDistance=1 -- 30cm + MeleeDistance per meter,e.g. 30cm+ 0.4*1m = 70cm
	local api = uevr.api
	local vr = uevr.params.vr
	--local params = uevr.params
	local callbacks = uevr.params.sdk.callbacks
	local pawn = api:get_local_pawn(0)
	local WeaponHand_Pos=UEVR_Vector3f.new()
	local WeaponHand_Rot=UEVR_Quaternionf.new()
	local SecondaryHand_Pos=UEVR_Vector3f.new()
	local SecondaryHand_Rot=UEVR_Quaternionf.new()
	
	local Hmd_Pos=UEVR_Vector3f.new()
	local Hmd_Rot=UEVR_Quaternionf.new()
	
	local SecondaryHand_Joy=UEVR_Vector2f.new()
	local PosZOld=0
	local PosYOld=0
	local PosXOld=0
	local PosZOldSecondary=0
	local PosYOldSecondary=0
	local PosXOldSecondary=0
	local PosZOldHMD = 0
	local PosYOldHMD = 0
	local PosXOldHMD = 0
	local tickskip=0
	 PosDiffWeaponHand=0
	 PosDiffSecondaryHand=0
	 PosDiffHMD = 0
	local WeaponHandCanPunch=false
	local SecondaryHandCanPunch=false
	local isRhand=true






local WHandIndex=2
local SHandIndex=1
local HHandIndex=0

NaloRhWt = 1
NaloLhWt =1
NaloHWt=1

uevr.sdk.callbacks.on_pre_engine_tick(
function(engine, delta)


	
	if isRhand then
		WHandIndex=2
		SHandIndex=1
	else WHandIndex=1
		SHandIndex=2
	end
	--print(isRiding)
	--local SecondaryHandIndex = uevr.params.vr.get_right_controller_index()
	uevr.params.vr.get_pose(WHandIndex, WeaponHand_Pos, WeaponHand_Rot)	
	local PosXNew=WeaponHand_Pos.x
	local PosYNew=WeaponHand_Pos.y
	local PosZNew=WeaponHand_Pos.z
	
	PosDiffWeaponHand = math.sqrt((PosXNew-PosXOld)^2+(PosYNew-PosYOld)^2+(PosZNew-PosZOld)^2)*(1/delta)*10*NaloRhWt
	PosZOld=PosZNew
	PosYOld=PosYNew
	PosXOld=PosXNew
	
	uevr.params.vr.get_pose(SHandIndex, SecondaryHand_Pos, SecondaryHand_Rot)
	local PosXNewSecondary=SecondaryHand_Pos.x
	local PosYNewSecondary=SecondaryHand_Pos.y
	local PosZNewSecondary=SecondaryHand_Pos.z
	
	PosDiffSecondaryHand = math.sqrt((PosXNewSecondary-PosXOldSecondary)^2+(PosYNewSecondary-PosYOldSecondary)^2+(PosZNewSecondary-PosZOldSecondary)^2)*(1/delta)*10*NaloLhWt
	PosZOldSecondary=PosZNewSecondary
	PosYOldSecondary=PosYNewSecondary
	PosXOldSecondary=PosXNewSecondary
	
	uevr.params.vr.get_pose(HHandIndex, Hmd_Pos, Hmd_Rot)
	local PosXNewHMD=Hmd_Pos.x
	local PosYNewHMD=Hmd_Pos.y
	local PosZNewHMD=Hmd_Pos.z
	
	PosDiffHMD = math.sqrt((PosXNewHMD-PosXOldHMD)^2+(PosYNewHMD-PosYOldHMD)^2+(PosZNewHMD-PosZOldHMD)^2)*(1/delta)*10*NaloHWt
	PosZOldHMD=PosZNewHMD
	PosYOldHMD=PosYNewHMD
	PosXOldHMD=PosXNewHMD
	--print(PosDiffHMD)
	
end)