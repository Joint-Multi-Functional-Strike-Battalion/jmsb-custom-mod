#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts one read module on the board: its type, callsign and side on the logic,
 * public, and the logic in the broadcast ledger whose index is its asset id.
 *
 * WHOSE IT IS COMES FROM JMSB - Core, NOT FROM AN ATTRIBUTE (D59). The module
 * belongs to the players' side, the first of jmfsb_common_fnc_playerSides.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Asset type, a TYPE_* token <STRING>
 * 2: Callsign as typed in Eden, "" for the default <STRING>
 * 3: Default callsign <STRING>
 *
 * Return Value:
 * Asset id number, -1 when not registered <NUMBER>
 *
 * Example:
 * [_logic, "varty", "", "THUNDER"] call jmfsb_support_fires_fnc_register
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_type", "", [""]], ["_callsign", "", [""]], ["_default", "FIRES", [""]]];

if (!isServer || {isNull _logic}) exitWith {-1};

if (_callsign isEqualTo "") then {_callsign = _default};
private _side = (call EFUNC(common,playerSides)) param [0, west];

_logic setVariable [QGVAR(type), _type, true];
_logic setVariable [QGVAR(callsign), toUpper _callsign, true];
_logic setVariable [QGVAR(side), _side, true];
_logic setVariable [QGVAR(status), STATUS_IDLE, true];
_logic setVariable [QGVAR(readyAt), 0, true];
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(token), 0];

GVAR(entities) pushBack _logic;
private _id = count GVAR(entities) - 1;
_logic setVariable [QGVAR(id), _id, true];
publicVariable QGVAR(entities);

INFO_3("'%1' (%2) on the board for %3",toUpper _callsign,_type,_side);

_id
