// THE LIST IS STILL THE MISSION'S. It used to be
// #include "..\..\config\config_adminlist.hpp" here, which an addon cannot do -
// an addon compiles once, for every mission. FUNC(adminList) RUNS that same
// file at runtime instead and reads its _admins, so the mission's own
// config\config_adminlist.hpp is unchanged and still the answer.
// THE SERVER PUBLISHES THE LIST NOW (review S2): this is only the start-up
// copy screens read until the server's arrives (XEH_postInit).
if (isNil "admp_authorisedIDs") then {admp_authorisedIDs = [] call FUNC(adminList)};

// Single player has no uid worth the name, and a dev box is where this gets
// used most.
{admp_authorisedIDs pushBackUnique _x} forEach ADMIN_SP_IDS;

// GLOBAL VARIABLES ///////////////////////////////////////////////////////////////////////////////

// general
admp_aceEnabled = true;
admp_returnValue = -1; // used to return remote status from clients

// player camera
admp_camera = objNull;
admp_camera_attachedObject = objNull;
admp_camera_firstPersonMode = false;
admp_camera_NVGmode = false;

// player list
admp_playerlist_selectedPlayer = name player; // player should have themselves selected by default
//admp_groupcombo_selectedPlayer = name player;
admp_playerlist_playerArray = [];
admp_playerlist_playerCount = 0;

// map/marker display
admp_map_markersActive = false;
admp_map_markerArray = [];

admp_map_selectedMarker = "admp_tracker_selected";
createMarkerLocal [admp_map_selectedMarker, [0,0]];
admp_map_selectedMarker setMarkerShapeLocal "ICON";
admp_map_selectedMarker setMarkerTypeLocal "mil_circle_noShadow";
admp_map_selectedMarker setMarkerColorLocal "ColorRed";
admp_map_selectedMarker setMarkerAlphaLocal 0;

// utilities list
admp_utilities_godmode_enabledUnits = [];
admp_utilities_infammo_enabledUnits = [];
admp_utilities_jmfsb_enabledUnits = [];
admp_utilities_infammo_EHindex = -1;

// admin
admp_admin_spectator_EHindex = -1;
admp_admin_zeusLogicGroup = grpNull;
admp_admin_serverLockState = false;
admp_admin_commandText = "";
admp_admin_serverFPS = 0;

// debug menu
admp_debug_previousCode = [];
admp_debug_codeIndex = 0;
admp_debug_latestCode = "";

// mission
admp_mission_endTypes = [];
private _customDebriefs = "true" configClasses (missionConfigFile >> "CfgDebriefing"); // get custom endings from mission config
{admp_mission_endTypes pushBackUnique (configName _x)} forEach _customDebriefs;
{admp_mission_endTypes pushBackUnique _x} forEach ["CPEndTotalVictory", "loser", "endDeath"]; // add some default endings in case there are no custom ones

// message display
admp_message_display_history_local = [];

///////////////////////////////////////////////////////////////////////////////////////////////////

// THE WAY IN. Two keys, both in jmfsb's own settings category rather than a
// category of their own - a suite with eleven addons and eleven keybind headings
// is a suite nobody can find a key in.
//
// Pause/Break is where this has always been. It stays the default because the
// people who use it have the muscle memory, and because it is one of the very
// few keys Arma does not already want.
if (hasInterface) then {
    ["1st Joint Multi-Functional Strike Battalion", QGVAR(openConsole),
        ["Open admin console", "Opens TAC//ADMIN. Refuses, with a reason, if you are not on the mission's admin list."],
        {[] call FUNC(open); true},
        {false},
        [0xC5, [false, false, false]]
    ] call CBA_fnc_addKeybind;

    ["1st Joint Multi-Functional Strike Battalion", QGVAR(openMessage),
        ["Open admin message", "Opens the message box, which anyone may use to reach an admin."],
        {[true] call FUNC(open); true},
        {false},
        [0xC5, [true, false, false]]
    ] call CBA_fnc_addKeybind;

    [] call admp_fnc_playerSetup;
};

// SERVER FPS, ONCE A SECOND, TO EVERYBODY. A spawned while-sleep loop before,
// which survives nothing and shows up in no diagnostic; a per-frame handler on a
// one-second period is the same thing that can be found and stopped.
if (isServer) then {
    [{
        admp_admin_serverFPS = round diag_fps;
        publicVariable "admp_admin_serverFPS";
    }, 1, []] call CBA_fnc_addPerFrameHandler;
};
