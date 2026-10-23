#include "script_component.hpp"
/*
 * Author: JMSB
 * Server-only. Consumes the dropped kits (items + kit objects) within range and
 * builds a patrol base: a beacon, a named map marker (pencil task icon), an
 * Unbuild action, a radio base station on the beacon (setting "Patrol base
 * radio relay", jmfsb_pac_fnc_baseStation) and the on-deploy hook.
 *
 * Arguments:
 * 0: Position ATL <ARRAY>
 * 1: Direction <NUMBER>
 * 2: Base name <STRING>
 * 3: Side <SIDE>
 * 4: Builder (for feedback) <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

if !(isServer) exitWith {};

params [["_pos", [], [[]]], ["_dir", 0, [0]], ["_name", "", [""]], ["_side", west, [west]], ["_builder", objNull, [objNull]]];
if (_pos isEqualTo []) exitWith {};

private _req   = missionNamespace getVariable [QGVAR(kitCount), 4];
private _max   = missionNamespace getVariable [QGVAR(maxCount), 3];
private _range = missionNamespace getVariable [QGVAR(kitRange), 5];
private _kitItems = KIT_ITEMS;

private _bases = missionNamespace getVariable [QGVAR(bases), []];
if (count _bases >= _max) exitWith {
    ["Patrol Base", format ["Patrol base limit reached (%1).", _max], [1, 0.3, 0.3, 1]] remoteExec [QEFUNC(notify,notify), _builder];
};

private _have = [_pos] call FUNC(countKits);
if (_have < _req) exitWith {
    ["Patrol Base", format ["Not enough kits (found %1, need %2).", _have, _req], [1, 0.3, 0.3, 1]] remoteExec [QEFUNC(notify,notify), _builder];
};

// --- Consume: strip kit items from holders, delete kit objects -------------
{
    private _holder = _x;
    private _cargo = itemCargo _holder;
    if ((_cargo arrayIntersect _kitItems) isNotEqualTo []) then {
        private _others = _cargo select {!(_x in _kitItems)};
        clearItemCargoGlobal _holder;
        { _holder addItemCargoGlobal [_x, 1] } forEach _others;
    };
} forEach (nearestObjects [_pos, ["WeaponHolderSimulated", "GroundWeaponHolder", "WeaponHolder"], _range]);
{ deleteVehicle _x } forEach (nearestObjects [_pos, KIT_OBJECTS, _range]);

// --- Beacon (configurable; marks the location + carries the Unbuild action) -
// Falls back on a blank setting AND on a class that is not loaded. A missing
// class would otherwise createVehicle nothing, leaving a base with no beacon and
// therefore no Unbuild action - a base nobody can take down. The default is
// jmfsb's own SatCom mast, which carries a Pack Up action of its own; that action
// checks the isBase variable set below and refuses, so the mast holding a base
// together cannot be pocketed out from under it.
private _beaconClass = missionNamespace getVariable [QGVAR(beaconClass), BASE_BEACON];
if (_beaconClass isEqualTo "" || {!isClass (configFile >> "CfgVehicles" >> _beaconClass)}) then {
    _beaconClass = BASE_BEACON;
};
private _beacon = createVehicle [_beaconClass, _pos, [], 0, "CAN_COLLIDE"];
_beacon setDir _dir;
_beacon setPosATL _pos;
_beacon allowDamage false;
_beacon setVariable [QGVAR(isBase), true, true];

// --- Named marker (pencil task icon), coloured by side ----------------------
private _color = switch (_side) do {
    case west: {"ColorWEST"};
    case east: {"ColorEAST"};
    case independent: {"ColorGUER"};
    default {"ColorCIV"};
};
private _idx = (missionNamespace getVariable [QGVAR(counter), 0]) + 1;
missionNamespace setVariable [QGVAR(counter), _idx];
private _mrk = createMarker [format ["jmfsb_patrol_base_mrk_%1", _idx], _pos];
_mrk setMarkerTypeLocal MARKER_TYPE;
_mrk setMarkerColorLocal _color;
_mrk setMarkerText _name;

// --- Register + Unbuild action (all clients + JIP) --------------------------
_bases pushBack [_beacon, _name, _side, _mrk, _req];
missionNamespace setVariable [QGVAR(bases), _bases, true];
[_beacon] remoteExec [QFUNC(addUnbuildAction), 0, _beacon];

// --- Radio relay: a base station on the beacon (setting "Patrol base radio
// relay"). It relays the builder's side's nets round the base and uplinks by
// satellite to the staging zone and every other base. It goes when the base is
// unbuilt, or by itself when the beacon is destroyed or deleted.
if (GVAR(radioRelay) && !isNil QEFUNC(pac,baseStation)) then {
    [_beacon, _side, QUOTE(ADDON)] call EFUNC(pac,baseStation);
};

// --- On-deploy hook ---------------------------------------------------------
[missionNamespace getVariable [QGVAR(onDeployCode), ""], [_beacon, _pos, _name, _side, _builder]] call FUNC(runHook);

[_name, "Patrol base established.", [0.6, 1, 0.6, 1]] call EFUNC(notify,broadcast);
