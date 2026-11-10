#include "script_component.hpp"
/*
 * Author: YonV
 * Put the listed vehicle classes on their side's sensor network.
 *
 * A SETTING, NOT A MISSION FILE (user, 2026-09-09: "Radar network needs to be
 * a cba setting"). This used to be twenty lines in every mission's
 * initServer.sqf reading config\config_radar.hpp, so adding a radar to the
 * network was a mission repack. It is a CBA setting now - and the mission class
 * and the database list are still read and added to it, so nothing that worked
 * before stops working.
 *
 * TWO SOURCES, ADDED TOGETHER, neither required:
 *   the setting     jmfsb_Settings_radarClasses - what a person types in the
 *                   settings menu, comma or newline separated
 *   the mission     missionConfigFile >> Radar_Network >> classes
 *
 * NOT THE DATABASE (user, 2026-09-09: "Radar network ... this is a cba
 * settings, make it a fucking cba settings, it should not be in pac"). It read
 * <unit>.radar as a third source, which meant the answer to "why is that thing
 * on the datalink" was in three places. The setting is the place.
 *
 * A CLASS EVENT HANDLER, not a sweep of `vehicles`: every vehicle of a listed
 * class joins the moment it exists, including the ones ALiVE spawns an hour in.
 * Applied to what is already placed as well - that is what the `true` at the
 * end of addClassEventHandler does.
 *
 * setDatalink switches reporting and receiving on; the radar itself is the one
 * flag it does not touch, so this sets it.
 *
 * Server only: a datalink is a shared picture, and every client doing this
 * would be the same work fifty times.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * How many classes were wired <NUMBER>
 *
 * Public: No
 */

if (!isServer) exitWith {0};
if (!EGVAR(Settings,radarNetwork)) exitWith {
    INFO("init","Radar network off - no vehicle put on the datalink.");
    0
};

// The setting, split on commas or newlines so a paste from anywhere works.
private _typed = EGVAR(Settings,radarClasses);
if !(_typed isEqualType "") then {_typed = ""};
private _classes = (_typed splitString ",;" + endl) apply {trim _x};

// The mission's own class, for a mission that still ships config_radar.hpp.
_classes append (getArray (missionConfigFile >> "Radar_Network" >> "classes"));

private _wired = 0;
private _unknown = [];
{
    private _class = _x;
    if (_class isEqualTo "") then {continue};
    // A CLASS THAT IS NOT LOADED IS NOT AN ERROR - it is a mod that is not on
    // this server - but it is worth saying once, because a typo looks exactly
    // the same and costs somebody an evening.
    if (!isClass (configFile >> "CfgVehicles" >> _class)) then {
        _unknown pushBackUnique _class;
        continue;
    };
    [_class, "init", {
        params ["_veh"];
        if (local _veh) then {
            [_veh] call EFUNC(common,setDatalink);
            _veh setVehicleRadar 1;
        };
    }, true, [], true] call CBA_fnc_addClassEventHandler;
    _wired = _wired + 1;
} forEach (_classes arrayIntersect _classes);      // once each

if (_unknown isNotEqualTo []) then {
    WARNING_1("init","Radar network: %1 are not vehicle classes on this server - a mod that is not loaded, or a typo",_unknown);
};
INFO_1("init","Radar network: %1 vehicle class(es) on the datalink.",_wired);

_wired
