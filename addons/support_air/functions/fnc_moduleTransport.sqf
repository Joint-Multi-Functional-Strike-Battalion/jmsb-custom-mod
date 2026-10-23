#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one JMSB - Transport module and puts the helicopter it describes on
 * TAC//SUPPORT, with the tasks the module allows.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, [], true] call jmfsb_support_air_fnc_moduleTransport
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic} || {!isServer}) exitWith {};
if (_logic in GVAR(entities)) exitWith {};

// THE SIDE IS READ ONCE, FROM THE SLOTS (FUNC(register)). A dedicated server
// that starts the mission empty has none to read yet, and a guess would fix
// the asset on the wrong side for good - so it waits for the first player.
if ((call EFUNC(common,playerSides)) isEqualTo []) exitWith {
    INFO_1("%1 waits for a player side before it goes on the board",_logic);
    [{(call EFUNC(common,playerSides)) isNotEqualTo []}, FUNC(moduleTransport), _this] call CBA_fnc_waitUntilAndExecute;
};

// WHICH TASKS THIS ONE OFFERS. A transport the mission wants as a taxi only
// (no shut-downs at the LZ, no extractions) says so here, and TAC//SUPPORT
// shows that helicopter only those rows - see FUNC(tasks). The asks are read
// now; what the airframe can do (a hook, FRIES) once it is known, below.
private _asked = [];
{
    _x params ["_attr", "_token"];
    if ([_logic getVariable [_attr, true]] call FUNC(bool)) then {_asked pushBack _token};
} forEach [
    ["allowPickup", TASK_PICKUP],
    ["allowLand", TASK_LAND],
    ["allowLandOff", TASK_LAND_OFF],
    ["allowMove", TASK_MOVE],
    ["allowExtract", TASK_EXTRACT],
    ["allowLift", TASK_LIFT],
    ["allowOrbit", TASK_ORBIT],
    ["allowFastrope", TASK_FASTROPE],
    ["allowHelocast", TASK_HELOCAST],
    ["allowParadrop", TASK_PARADROP],
    ["allowSlingload", TASK_SLING]
];
if (_asked isEqualTo []) exitWith {
    WARNING_1("transport module %1 allows no task at all - no asset placed",_logic);
};

_logic setVariable [QGVAR(jumpHeight), 100 max (_logic getVariable ["jumpHeight", 250]), true];
_logic setVariable [QGVAR(seats), 0 max round (_logic getVariable ["seats", 0]), true];
_logic setVariable [QGVAR(airframes), 0 max round (_logic getVariable ["airframes", 2]), true];
_logic setVariable [QGVAR(height), 20 max (_logic getVariable ["height", 80]), true];
_logic setVariable [QGVAR(waitTime), 0 max (_logic getVariable ["waitTime", 300]), true];
_logic setVariable [QGVAR(left), -1, true];

if !([_logic, KIND_TRANSPORT, "RAVEN", "Helicopter", true] call FUNC(register)) exitWith {};

// WHAT THE AIRFRAME CAN DO. A sling task without a hook, or ropes without
// FRIES or ACE fast-roping, is a row that could only ever be refused.
private _cls = _logic getVariable [QGVAR(cls), ""];
private _allowed = _asked select {
    switch (_x) do {
        case TASK_SLING: {getNumber (configFile >> "CfgVehicles" >> _cls >> "slingLoadMaxCargoMass") > 0};
        case TASK_FASTROPE: {[_cls] call FUNC(canRope)};
        default {true};
    };
};
if (count _allowed < count _asked) then {
    INFO_2("transport '%1' cannot fly %2 - not offered",_logic getVariable [ARR_2(QGVAR(callsign),"")],_asked - _allowed);
};
_logic setVariable [QGVAR(allowed), _allowed, true];

// A synced helicopter that may fast-rope carries ACE's rope item from the
// start (FUNC(stockRopes)); a class one gets it at launch.
[_logic, _logic getVariable [QGVAR(synced), objNull]] call FUNC(stockRopes);
