local functions = uevr.params.functions

--Preferences
local check_uevr_version = true
local include_header = true

-- Static variables for headers
local config_filename = "main-config.json"
local title = "Oblivion Remastered VR Mod Settings"
local author = "Pande4360"
local profile_name = "6dof Attached Items Profile (Righthand Aiming)"

local required_uevr_commit_count = nil
local uevr_version = nil

if check_uevr_version then
    required_uevr_commit_count = 1343
    uevr_version = functions.get_tag_long() .. "+" .. functions.get_commit_hash()
end

local json_files = {}

-- Initial config setup
config_table = {
    Movement = 1,
    Snap_Turn = false,
    Enable_Lumen_Indoors = false,
    Faster_Projectiles = false,
    Visible_Helmet = true,--(currently not wokring)
    EnableHolster = true,
    Holster_Haptic_Feedback = true,
    Sword_Sideways_Is_Block = false,
    First_Person_Riding = true,
    Extra_Block_Range = 0,
    Melee_Power = 700,
	ReticleAlwaysOn =true,
	UI_Follows_View =true,
	DarkerDarks=false,
	RadialQuickMenu=true,
    ManageLighting=true,
	--HandIndex=2
	--isRhand = true	
}

json_files = fs.glob(config_filename)

--Check if config exists and create it if not
if #json_files == 0 then
    json.dump_file(config_filename, config_table, 4)
end

local re_read_table = json.load_file(config_filename)

for _, key in ipairs(config_table) do
    assert(re_read_table[key] == config_table[key], key .. "is not the same")
end

for key, value in pairs(re_read_table) do
    config_table[key] = value
end

--Assign config variables
if config_table.Movement == 1 then
    HeadBasedMovement = true
else
    HeadBasedMovement = false
end

SnapTurn = config_table.Snap_Turn
Enable_Lumen_Indoors = config_table.Enable_Lumen_Indoors
Faster_Projectiles = config_table.Faster_Projectiles
VisibleHelmet = config_table.Visible_Helmet
EnableHolster = config_table.EnableHolster
HolsterHapticFeedback = config_table.Holster_Haptic_Feedback
FirstPersonRiding = config_table.First_Person_Riding
SwordSidewaysIsBlock = config_table.Sword_Sideways_Is_Block
ExtraBlockRange = config_table.Extra_Block_Range
MeleePower = config_table.Melee_Power
ReticleAlwaysOn = config_table.ReticleAlwaysOn
UIFollowsView = config_table.UI_Follows_View
DarkerDarks=config_table.DarkerDarks
ManageLighting=config_table.ManageLighting
RadialQuickMenu=config_table.RadialQuickMenu
--isRhand = config_table.isRhand


local function uevr_version_check()
    imgui.text("UEVR Version Check: ")
    imgui.same_line()
    if functions.get_total_commits() == required_uevr_commit_count then
        imgui.text_colored("Success", 0xFF00FF00)
    elseif functions.get_total_commits() > required_uevr_commit_count then
        imgui.text_colored("Newer", 0xFF00FF00)
        imgui.text("UEVR Version: " .. uevr_version)
        imgui.same_line()
        imgui.text("UEVR Build Date: " .. functions.get_build_date())
    elseif functions.get_total_commits() < required_uevr_commit_count then
        imgui.text_colored("Failed - Older", 0xFF0000FF)
        imgui.text("UEVR Version: " .. uevr_version)
        imgui.same_line()
        imgui.text("UEVR Build Date: " .. functions.get_build_date())
    end
end

local function create_header()
    imgui.text(title)
    imgui.text("By: " .. author)
    imgui.same_line()
    imgui.text("Profile: " .. profile_name)
   -- imgui.same_line()
    --imgui.text("Version: " .. profile_version)

    if check_uevr_version then
        uevr_version_check()
    end
    imgui.new_line()
end

local function create_dropdown(label_name, key_name, values)
    local changed, new_value = imgui.combo(label_name, config_table[key_name], values)

    if changed then
        config_table[key_name] = new_value
        json.dump_file(config_filename, config_table, 4)
        return new_value
    else
        return config_table[key_name]
    end
end

local function create_checkbox(label_name, key_name)
    local changed, new_value = imgui.checkbox(label_name, config_table[key_name])

    if changed then
        config_table[key_name] = new_value
        json.dump_file(config_filename, config_table, 4)
        return new_value
    else
        return config_table[key_name]
    end
end

local function create_slider_int(label_name, key_name, min, max)
    local changed, new_value = imgui.slider_int(label_name, config_table[key_name], min, max)

    if changed then
        config_table[key_name] = new_value
        json.dump_file(config_filename, config_table, 4)
        return new_value
    else
        return config_table[key_name]
    end
end

uevr.sdk.callbacks.on_draw_ui(function()
    if include_header then
        create_header()
    end

    for _, file in ipairs(json_files) do
        imgui.text(file)
    end
    
    imgui.text("Movement")
    local movement_values = {"Head", "R Controller"}
    local movement = create_dropdown("Movement Based On", "Movement", movement_values)
    if movement == 1 then
        HeadBasedMovement = true
    else
        HeadBasedMovement = false
    end

    SnapTurn = create_checkbox("Snap Turn", "Snap_Turn")
    imgui.new_line()

    imgui.text("Features")
	
    -- Create options for the 'Script UI' section in the UEVR settings menu
	UIFollowsView = create_checkbox("UI Follows View", "UI_Follows_View")
	RadialQuickMenu = create_checkbox("Motion Controlled Radial Quick Menu", "RadialQuickMenu")
    Enable_Lumen_Indoors = create_checkbox("Enable Lumen Indoors", "Enable_Lumen_Indoors")
    Faster_Projectiles = create_checkbox("Faster Projectiles", "Faster_Projectiles")
	--ReticleAlwaysOn = create_checkbox("Reticle Always On", "Reticle Always On")
    -- VisibleHelmet = create_checkbox("Helmet Visibility", "Visible_Helmet")
    EnableHolster=create_checkbox("Enable Holster", "EnableHolster")
    HolsterHapticFeedback = create_checkbox("Holster Haptic Feedback (Required Enable Holster checked)", "Holster_Haptic_Feedback")
    FirstPersonRiding = create_checkbox("First Person Horse Riding", "First_Person_Riding")
    SwordSidewaysIsBlock = create_checkbox("Hold Sword Sideways To Block", "Sword_Sideways_Is_Block")
	--isRhand = create_checkbox("Right Hand Mode", "isRhand")
	DarkerDarks=create_checkbox("Darker interiors and nights (Requires: Manage lighting checked)", "DarkerDarks") 
    ManageLighting=create_checkbox("Manage lighting (Restart required on uncheck)", "ManageLighting") 
	ExtraBlockRange = create_slider_int("Extra Block Range (in cm)", "Extra_Block_Range", 0, 50)
    MeleePower = create_slider_int("Melee Power (swing intensity)", "Melee_Power", 0, 1500)
end)


	--DEBUG VALUES, to test to fix some potnetial issues:
	--1. Collision Capsule: try increase Half Height first. If you start floating before solving the issue, go back and increase capsRad, CapsRad is important to kept low as possible for melee to work as intended. 
	CapsuleHalfHeightWhenMoving= 97  --Vanilla=90 , when not moving it´s 90
	CapsuleRadWhenMoving= 30.480	   --Vanilla=30, when not moving it´s 7.93



	--not functional:
	isRhand = true	
	isLeftHandModeTriggerSwitchOnly = true
	