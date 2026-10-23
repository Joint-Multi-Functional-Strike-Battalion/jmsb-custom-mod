#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one JMSB - QRF Insertion module and puts the squad it describes on
 * TAC//SUPPORT, with the insertions the module allows.
 *
 * AIR ASSAULT NEEDS A HELICOPTER. A module flying a transport plane offers
 * the static-line jump and not the landing, rather than offering a landing a
 * plane would fly into the treeline trying to make.
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
 * [_logic, [], true] call jmfsb_support_air_fnc_moduleQRF
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
    [{(call EFUNC(common,playerSides)) isNotEqualTo []}, FUNC(moduleQRF), _this] call CBA_fnc_waitUntilAndExecute;
};

private _squads = round (_logic getVariable ["squads", 2]);
_logic setVariable [QGVAR(left), [_squads, -1] select (_squads <= 0), true];
_logic setVariable [QGVAR(stock), _squads max 0, true];
_logic setVariable [QGVAR(groupClass), _logic getVariable ["groupClass", ""], true];
_logic setVariable [QGVAR(unitClasses), _logic getVariable ["unitClasses", ""], true];
_logic setVariable [QGVAR(onLanding), _logic getVariable ["onLanding", 0], true];
_logic setVariable [QGVAR(defendRadius), 25 max (_logic getVariable ["defendRadius", 100]), true];
_logic setVariable [QGVAR(staticAlt), 120 max (_logic getVariable ["staticAlt", 250]), true];

if !([_logic, KIND_QRF, "REACH", "Air", false] call FUNC(register)) exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), ""];
private _heli = (_logic getVariable [QGVAR(cls), ""]) isKindOf "Helicopter";
private _allowed = [];
{
    _x params ["_attr", "_token", ["_needsHeli", false]];
    if ([_logic getVariable [_attr, true]] call FUNC(bool) && {_heli || !_needsHeli}) then {_allowed pushBack _token};
} forEach [
    ["allowStatic", TASK_STATIC],
    ["allowAssault", TASK_ASSAULT, true]
];
if (_allowed isEqualTo []) then {
    WARNING_1("QRF '%1' allows no insertion its aircraft can fly - it will refuse every request",_callsign);
};
_logic setVariable [QGVAR(allowed), _allowed, true];

// The squad is resolved now so a bad class is found at mission start, not
// with a section waiting on it - and the answer is kept, so the row reads
// EXPENDED (FUNC(available)) rather than idle with every task refused.
private _hasSquad = ([_logic] call FUNC(qrfSquad)) isNotEqualTo [];
_logic setVariable [QGVAR(hasSquad), _hasSquad, true];
if (!_hasSquad) then {
    WARNING_1("QRF '%1' names no soldier class that exists - it will refuse every request",_callsign);
};
