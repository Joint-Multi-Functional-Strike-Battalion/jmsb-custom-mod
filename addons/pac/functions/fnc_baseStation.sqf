#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: puts a BASE STATION at a staging zone or a patrol base (user,
 * 2026-10-20: "use our patrol base as a relay", "a staging zone or patrol base
 * as a sat uplink"). It is an RF node of the "base" profile (VHF, UHF and SAT;
 * the relay's 20 W, 6 dBi and hop limit 8; powered by its site) holding every
 * net of the plan plus DATA and the default C2 (FUNC(baseStationRegister)),
 * relay and TX on. On the ground it relays the side's mesh round the site; by
 * satellite it links to every other base station and SAT-capable vehicle of
 * the side under open sky, at any distance, in one hop.
 *
 * Not a unit, so nothing for ALiVE to profile: it is a radio on an object
 * that is already there (the zone's object, the patrol base's mast). A zone
 * given as a position gets an invisible helper object (BASE_HELPER_CLASS) at
 * its centre to carry the antenna, removed with the station.
 *
 * One station per object (and per position, to the metre): a second call for
 * the same site answers the station it already has, so every client may
 * report the same staging zone. It goes when FUNC(baseStationRemove) is
 * called, or by itself when its object is destroyed (MPKilled) or deleted
 * (Deleted). Every station is an emitter to EW (an RF node that transmits)
 * and jammable like any node. Does nothing without RF.
 *
 * Arguments:
 * 0: Site: its object, or its centre position <OBJECT or ARRAY>
 * 1: Side (optional, default the players' side, jmfsb_common_fnc_playerSides) <SIDE>
 * 2: Owner, the addon that asked (optional, default "") <STRING>
 *
 * Return Value:
 * RF node id, "" when none was made <STRING>
 *
 * Example:
 * [_beacon, west, "jmfsb_patrol_base"] call jmfsb_pac_fnc_baseStation
 * [getMarkerPos "respawn_west"] call jmfsb_pac_fnc_baseStation
 *
 * Public: Yes
 */

params [["_site", objNull, [objNull, []]], ["_side", sideUnknown, [west]], ["_owner", "", [""]]];

if (!isServer || isNil QEFUNC(rf,register)) exitWith {""};

if (_side isEqualTo sideUnknown) then {
    _side = (call EFUNC(common,playerSides)) param [0, BASE_SIDE_DEFAULT];
};

// A POSITION gets a helper object, once per spot
private _object = objNull;
private _helper = false;
private _posKey = "";
if (_site isEqualType []) then {
    _site params [["_px", 0, [0]], ["_py", 0, [0]]];
    _posKey = format [BASE_POS_FORMAT, round _px, round _py];
    _object = GVAR(basePositions) getOrDefault [_posKey, objNull];
    if (isNull _object) then {
        _object = createVehicle [BASE_HELPER_CLASS, [_px, _py, 0], [], 0, "CAN_COLLIDE"];
        _helper = true;
        GVAR(basePositions) set [_posKey, _object];
    };
} else {
    _object = _site;
};
if (isNull _object || !alive _object) exitWith {""};

private _id = _object getVariable [QGVAR(baseStation), ""];
if (_id in GVAR(baseStations)) exitWith {_id};

GVAR(baseSeq) = GVAR(baseSeq) + 1;
_id = format [BASE_ID_FORMAT, GVAR(baseSeq)];
_object setVariable [QGVAR(baseStation), _id];
GVAR(baseStations) set [_id, [_object, _side, _owner, _helper, _posKey]];

// DESTROYED OR DELETED, the station goes with it - once per object. MPKilled
// so the server hears it wherever the object is local.
if !(_object getVariable [QGVAR(baseStationEh), false]) then {
    _object setVariable [QGVAR(baseStationEh), true];
    _object addMPEventHandler ["MPKilled", {
        if (isServer) then {[_this select 0] call FUNC(baseStationRemove)};
    }];
    _object addEventHandler ["Deleted", {[_this select 0] call FUNC(baseStationRemove)}];
};

[_id] call FUNC(baseStationRegister);
INFO_3("base station %1 up for %2 (%3)",_id,_side,_owner);
_id
