#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one JMSB - Logistics Drop module and puts the drop on TAC//SUPPORT.
 *
 * SLING NEEDS A HELICOPTER THAT CAN LIFT THE CRATE. Anything else falls back
 * to the parachute here, once, with a warning - not at the grid, with a
 * section waiting for a crate that never comes off the hook.
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
 * [_logic, [], true] call jmfsb_support_air_fnc_moduleLogistics
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
    [{(call EFUNC(common,playerSides)) isNotEqualTo []}, FUNC(moduleLogistics), _this] call CBA_fnc_waitUntilAndExecute;
};

private _crate = _logic getVariable ["crateClass", "B_supplyCrate_F"];
if !(isClass (configFile >> "CfgVehicles" >> _crate)) then {
    WARNING_1("logistics module names crate '%1', which is not a class - B_supplyCrate_F instead",_crate);
    _crate = "B_supplyCrate_F";
};

private _drops = round (_logic getVariable ["drops", 3]);
_logic setVariable [QGVAR(left), [_drops, -1] select (_drops <= 0), true];
_logic setVariable [QGVAR(stock), _drops max 0, true];
_logic setVariable [QGVAR(crateClass), _crate, true];
_logic setVariable [QGVAR(arsenalLists), _logic getVariable ["arsenalLists", "magazines"], true];
// LOADS, separated by ';' - the requester picks one per drop (CONTENTS, see
// FUNC(tasks)). One load, or none, is the module deciding alone.
private _loads = ((_logic getVariable [QGVAR(arsenalLists), ""]) splitString ";") apply {trim _x} select {_x isNotEqualTo ""};
if (_loads isEqualTo []) then {_loads = [""]};
_logic setVariable [QGVAR(loads), _loads, true];
// The module's crate signal: its combo 0 smoke .. 4 none is the request
// table without MODULE.
private _signal = (round (_logic getVariable ["signal", 0])) max 0 min (count CRATE_SIGNAL_CLASSES - 1 - CRATE_SIGNAL_MODULE_OFFSET);
_logic setVariable [QGVAR(signalClass), CRATE_SIGNAL_CLASSES select (_signal + CRATE_SIGNAL_MODULE_OFFSET), true];
_logic setVariable [QGVAR(magCount), 0 max round (_logic getVariable ["magCount", 10]), true];
_logic setVariable [QGVAR(itemCount), 0 max round (_logic getVariable ["itemCount", 2]), true];
_logic setVariable [QGVAR(dropHeight), 100 max (_logic getVariable ["dropHeight", 250]), true];

if !([_logic, KIND_LOGISTICS, "MULE", "Air", false] call FUNC(register)) exitWith {};

private _sling = (_logic getVariable ["method", 0]) isEqualTo 1;
private _cls = _logic getVariable [QGVAR(cls), ""];
if (_sling && {!(_cls isKindOf "Helicopter") || {getNumber (configFile >> "CfgVehicles" >> _cls >> "slingLoadMaxCargoMass") <= 0}}) then {
    WARNING_1("logistics: '%1' cannot carry a sling load - this module drops by parachute",_cls);
    _sling = false;
};
_logic setVariable [QGVAR(sling), _sling, true];
