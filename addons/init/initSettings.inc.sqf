// Make settings name
// The Mission & Admin page of the JMSB Addon Options (user, 2026-10-24: "break
// all our options up a bit the big single page is hard to tell folks where to
// find things").
private _YMFsettings = "JMSB - Mission & Admin";

[ // Mission Type
    QEGVAR(Settings,setMissionType),
    "LIST",
    ["Mission Type", "This will deside on what kind of startup hint you get on mission start."],
    [_YMFsettings, "Mission"],
    [[0,1,2,3], ["Custom", "Operation", "Training", "Public"], 1],
    true,
    {},
    true
] call CBA_fnc_addSetting;
// AI SKILL ADJUSTMENT, OFF BY DEFAULT (user, 2026-09-01).
//
// "Arma Default" means config\config_skill.hpp does nothing at all - no
// setSkill call is made and every AI keeps the skill its own config and the
// difficulty profile give it. The other two run the mission's skill block on
// every AI the mission ever creates, which on an ALiVE mission is a four-figure
// number of units per session.
//
// This is the only switch: nothing else in the mod or the mission writes AI
// skill, so index 0 here is the whole off state.
[ // Ai setting
    QEGVAR(Settings,setAiSystemDifficulty),
    "LIST",
    ["AI Setting", "Adjusts AI skill so they are less godlike. Arma Default leaves every AI's skill exactly as its own config sets it and runs no skill script at all."],
    [_YMFsettings, "Mission"],
    [[0,1,2], ["Arma Default", "Adjusted", "Faction Based"], 0],
    true,
    {},
    true
] call CBA_fnc_addSetting;

// No Radios page: radio distribution, squad channels and vehicle racks were
// ACRE's and TFAR's (DEC1, 2026-10-31).

[ // Documents
    QEGVAR(Settings,showDiaryRecords),
    "CHECKBOX",
    ["Documents","Allow the mission to write diary help documents."],
    [_YMFsettings, "Player"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Rank
    QEGVAR(Settings,setPlayerRank),
    "CHECKBOX",
    ["Rank","Allow mission to apply arma rank based on name rank prefixes."],
    [_YMFsettings, "Player"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

[ // Insignia
    QEGVAR(Settings,allowInsigniaApplication),
    "CHECKBOX",
    ["Insignia","Put the battalion patch on every player's uniform. A patch a player picks in the arsenal (Medic, EOD, JFIRE...) is kept."],
    [_YMFsettings, "Player"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Apply Earplugs
    QEGVAR(Settings,addEarplugs),
    "CHECKBOX",
    ["Apply Earplugs","Automaticly apply earplugs to players on spawn and respawn."],
    [_YMFsettings, "Player"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;


[ // Enable
    QEGVAR(Settings,enableStagingSystem),
    "CHECKBOX",
    ["Enable","Enables the staging system."],
    [_YMFsettings, "Staging"],
    true,
    true,
    {},
    false
] call CBA_fnc_addSetting;
[ // Enable
    QEGVAR(Settings,enableVehicleSystem),
    "CHECKBOX",
    ["Enable", "Enables scripted settings and functions to apply to vehicles."],
    [_YMFsettings, "Vehicle"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Pylon
    QEGVAR(Settings,enableVehiclePylon),
    "CHECKBOX",
    ["Pylon", "Enables scripted loadouts or pylon to be applied to vehicles based on faction"],
    [_YMFsettings, "Vehicle"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Loadouts
    QEGVAR(Settings,enableVehicleInventory),
    "CHECKBOX",
    ["Inventory", "Enables scripted inventory to be applied to vehicles based on faction"],
    [_YMFsettings, "Vehicle"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

[ // Factions
    QEGVAR(Settings,vehicleFactions),
    "EDITBOX",
    ["Factions","Array of factions allowing system loadout and pylon changes"],
    [_YMFsettings, "Vehicle"],
    '["BLU_CTRG_F","BLU_W_F","BLU_T_F","BLU_NATO_lxWS","BLU_F","USAF","tweed_UA_21","jmfsb_EUDF","jmfsb_EUDF_arc","jmfsb_EUDF_des","jmfsb_EUDF_tna","jmfsb_EUDF_wdl","jmfsb_GEN","jmfsb_HIMF","jmfsb_Marine_des","jmfsb_Marine_wdl","jmfsb_faction_jmsb_ocp","jmfsb_US_JTF_des","jmfsb_US_JTF_ocp","jmfsb_US_JTF_tna","jmfsb_US_JTF_wdl"]',
    true,
    {},
    true
] call CBA_fnc_addSetting;


// 7; Combat Jump Simulation
[ // Simulation Type
    QEGVAR(Settings,jumpSimulation),
    "LIST",
    ["Simulation Type","Combat jump simulation is a system that checks for lose equiped gear in the form of;\nnight vision googles, hats or glasses and make you lose the on a combat jump.\n    None: No simulation is done.\n    Basic: Lose gear unassigned.\n    Advanced: Lose gear is removed."],
    [_YMFsettings, "Combat Jump Simulation"],
    [[0,1,2], ["None", "Basic", "Advanced"], 2],
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Include Night Vision Googles
    QEGVAR(Settings,jumpSimulationNVG),
    "CHECKBOX",
    ["Include Night Vision Googles","Include equiped Night Vison Googles in the simulation."],
    [_YMFsettings, "Combat Jump Simulation"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Include Non-combat Googles
    QEGVAR(Settings,jumpSimulationGlasses),
    "CHECKBOX",
    ["Include Non-combat Googles","Include Non-combat Googles in the simulation. This refere to sunshades and simular non-safety googles."],
    [_YMFsettings, "Combat Jump Simulation"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;
[ // Include Non-combat Headgear
    QEGVAR(Settings,jumpSimulationHat),
    "CHECKBOX",
    ["Include Non-combat Headgear","Include Non-combat Headgear in the simulation. This refere to hats bandanas and baretes."],
    [_YMFsettings, "Combat Jump Simulation"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

// THE RADAR NETWORK, AS A SETTING (2026-09-09). It used to be twenty lines in
// every mission's initServer.sqf reading config\config_radar.hpp, so adding a
// radar to the datalink was a mission repack. The mission class and the
// database list are still added to whatever is typed here - see
// jmfsb_init_fnc_radarNetwork - so nothing that worked before stops working.
[
    QEGVAR(Settings,radarNetwork),
    "CHECKBOX",
    ["Radar network", "Put the vehicle classes below on their side's sensor network at mission start. Off means no vehicle is touched, whatever is listed."],
    [_YMFsettings, "Radar"],
    true,
    true,
    {},
    true
] call CBA_fnc_addSetting;

[
    QEGVAR(Settings,radarClasses),
    "EDITBOX",
    ["Vehicle classes", "Classnames, separated by commas or new lines. Each one joins its side's datalink the moment it exists, including vehicles spawned an hour in. A class this server has not loaded is skipped and named once in the .rpt."],
    [_YMFsettings, "Radar"],
    "",
    true,
    {},
    true
] call CBA_fnc_addSetting;

// AI SKILL, AS SLIDERS (2026-09-09). Every number config\config_skill.hpp used
// to set is a setting now; the file itself is gone from the missions that take
// their config from the database. Kept in its own file because it is twenty-two
// settings and they would bury everything else in here.
#include "aiSkillSettings.inc.sqf"
