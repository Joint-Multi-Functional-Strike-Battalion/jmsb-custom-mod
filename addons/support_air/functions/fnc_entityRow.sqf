#include "script_component.hpp"
/*
 * Author: YonV
 * One module as one TAC//SUPPORT row, in the core's shape:
 *
 *   [id, type, callsign, platform, status, ordnance, guns, vehicle, plan, stationFirst]
 *
 * ORDNANCE IS A CAS AIRCRAFT'S OWN STORES, read the way the CAS drones read
 * theirs (EFUNC(cas,stores)) so both kinds of CAS offer the same words for
 * the same pylons: AUTO first, then what is hung on it, heaviest first. A
 * synced aircraft is read live - its pylons may have been changed in Eden.
 *
 * THE VEHICLE goes in field 7 while it is out, so the map marks it and a
 * transport row lists who is aboard.
 *
 * THE PLAN goes in field 8 - the points of the task it is flying, labelled
 * ([[pos, "VIA"], [pos, "LZ"], ...]) - so TAC//SUPPORT draws Simplex-style
 * task markers and the route on its map in both hosts.
 *
 * ON STATION FIRST goes in field 9 (2026-11-01, the composer's @ mentions;
 * doc 1.1): true for a fixed-wing CAS aircraft the AI flies - FUNC(srvThread)
 * answers its strike card NOT ON STATION until it holds - so a message to it
 * opens REQUEST ON STATION. A helicopter strikes from base, and a player at
 * the controls answers the request by hand: false.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The row, [] when the logic is gone <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_entityRow
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[]};

private _kind = _logic getVariable [QGVAR(kind), ""];
private _cls = _logic getVariable [QGVAR(cls), ""];
([_logic] call FUNC(available)) params ["", "_status"];

private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _ordnance = [];
private _stationFirst = false;
if (_kind isEqualTo KIND_CAS) then {
    private _synced = _logic getVariable [QGVAR(synced), objNull];
    private _src = [_cls, _synced] select (alive _synced);
    _ordnance = ["AUTO"] + (([_src] call EFUNC(cas,stores)) apply {_x select 1});
    _stationFirst = !(_src isKindOf "Helicopter") && !(isPlayer (driver _veh));
};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _kind,
    _logic getVariable [QGVAR(callsign), "AIR"],
    getText (configFile >> "CfgVehicles" >> _cls >> "displayName"),
    _status,
    _ordnance,
    0,
    _veh,
    _logic getVariable [QGVAR(plan), []],
    _stationFirst
]
