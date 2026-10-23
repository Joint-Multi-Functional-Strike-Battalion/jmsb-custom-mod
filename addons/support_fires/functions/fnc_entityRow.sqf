#include "script_component.hpp"
/*
 * Author: JMSB
 * One module as one support-page row, in the core's shape
 * (addons/support/README.md):
 *
 *   [id, type, callsign, platform, status, ordnance, guns, vehicle]
 *
 * Ordnance is [[name, roundsLeft, key], ...] for every type - the artillery
 * shape - so the support page's own artillery reading of field 5 works on a
 * battery of ours too. Guns is a battery's tube count and 0 otherwise. Nothing here has a single airframe to mark, so vehicle is null.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The row, [] when the logic is gone <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_entityRow
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[]};

([_logic] call FUNC(available)) params ["", "_status"];

private _type = _logic getVariable [QGVAR(type), ""];

private _platform = switch (_type) do {
    case TYPE_ARTY: {_logic getVariable [QGVAR(platform), "VIRTUAL BATTERY"]};
    case TYPE_CRUISE: {"CRUISE MISSILE LAUNCHER"};
    case TYPE_LOITER: {getText (configFile >> "CfgVehicles" >> (_logic getVariable [QGVAR(cls), ""]) >> "displayName")};
    default {""};
};

private _guns = switch (_type) do {
    case TYPE_ARTY: {_logic getVariable [QGVAR(gunCount), 0]};
    default {0};
};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _type,
    _logic getVariable [QGVAR(callsign), "FIRES"],
    _platform,
    _status,
    [_logic] call FUNC(ordnance),
    _guns,
    objNull
]
