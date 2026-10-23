#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_radioFromMission

Description:
    Reads the radio plan a mission handed over - config_radio.hpp, run by
    the mission's own loadConfigs.sqf at its preInit, which sets the
    jmfsbFR_radio_* globals - into the structure's "radio" section, so a
    database that has no plan yet is seeded with the mission's and a
    mission that still ships one keeps working exactly as before.

    Server only, at boot step 1: the mission's preInit has run by then
    and the globals are the mission's (or FUNC(radioApply)'s defaults from
    this addon's preInit, which is how "no plan" is told apart - a plan
    names channels, the defaults name none).

Parameters:
    None

Returns:
    Whether the mission had a plan <BOOL>

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {false};

private _radio = createHashMap;
{
    _x params ["_key"];
    private _name = "jmfsbFR_radio_" + _key;
    if (!isNil _name) then {_radio set [_key, missionNamespace getVariable _name]};
} forEach ([] call FUNC(radioKeys));

private _has = (_radio getOrDefault ["srChannels", []]) isNotEqualTo []
    || {(_radio getOrDefault ["mrChannels", []]) isNotEqualTo []}
    || {(_radio getOrDefault ["tfarNets", []]) isNotEqualTo []}
    || {(_radio getOrDefault ["vonNets", []]) isNotEqualTo []};
if (!_has) exitWith {false};

GVAR(structure) set ["radio", _radio];
true
