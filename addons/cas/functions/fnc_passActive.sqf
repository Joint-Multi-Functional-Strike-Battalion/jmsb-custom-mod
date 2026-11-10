#include "script_component.hpp"
/*
 * Author: YonV
 * Is there a pass on this aircraft for its owner's watch to tick
 * (FUNC(passBegin), FUNC(passTick)) - under way, lining up or in its dive,
 * or over with its result not yet read? One the owner ended and forgot
 * (FUNC(passEnd)) is not.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * A pass to tick <BOOL>
 *
 * Example:
 * [_veh] call jmfsb_cas_fnc_passActive
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]]];

if (isNull _veh) exitWith {false};

count (_veh getVariable [QGVAR(pass), createHashMap]) > 0
