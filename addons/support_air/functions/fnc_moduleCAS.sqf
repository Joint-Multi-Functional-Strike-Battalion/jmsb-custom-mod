#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one JMSB - CAS module and puts the aircraft it describes on
 * TAC//SUPPORT. Many modules are many aircraft; nothing here is global.
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
 * [_logic, [], true] call jmfsb_support_air_fnc_moduleCAS
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
    [{(call EFUNC(common,playerSides)) isNotEqualTo []}, FUNC(moduleCAS), _this] call CBA_fnc_waitUntilAndExecute;
};

// Sorties are the stock: -1 is unlimited, so "0 left" can mean spent.
private _sorties = round (_logic getVariable ["sorties", 4]);
_logic setVariable [QGVAR(left), [_sorties, -1] select (_sorties <= 0), true];
_logic setVariable [QGVAR(stock), _sorties max 0, true];
_logic setVariable [QGVAR(altitude), 50 max (_logic getVariable ["altitude", 600]), true];
_logic setVariable [QGVAR(runIn), 1000 max (_logic getVariable ["runIn", 3000]), true];
_logic setVariable [QGVAR(stationTime), 60 max (_logic getVariable ["stationTime", 600]), true];
_logic setVariable [QGVAR(searchRadius), 0 max (_logic getVariable ["searchRadius", 300]), true];
_logic setVariable [QGVAR(ingressDistance), INGRESS_FLOOR max (_logic getVariable ["ingressDistance", 6000]), true];
_logic setVariable [QGVAR(friendlyRange), 0 max (_logic getVariable ["friendlyRange", 100]), true];

[_logic, KIND_CAS, "HOG", "Air", true] call FUNC(register);
