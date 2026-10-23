#include "script_component.hpp"
/*
 * Author: JMSB
 * What an asset has left to fire, one entry per type, in the order the
 * support page steps through them:
 *
 *   [name, roundsLeft, key]
 *
 * roundsLeft -1 is unlimited. A type with nothing left is not listed, so the
 * ORDNANCE stepper can never offer a round the asset does not have. The key is
 * what the server fires by - the round's kind ("he", "smoke", ... or, for a
 * retired Artillery Battery module, the magazine or ammo class it was given).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * Ordnance entries <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_ordnance
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[]};

switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {
        ((_logic getVariable [QGVAR(stock), []]) select {(_x select 1) isNotEqualTo 0}) apply {
            [_x select 0, _x select 1, _x select 3]
        }
    };
    case TYPE_CRUISE: {
        private _left = _logic getVariable [QGVAR(left), 0];
        [[], [["MISSILE", _left, ""]]] select (_left > 0)
    };
    case TYPE_LOITER: {
        private _left = _logic getVariable [QGVAR(left), 0];
        [[], [["MUNITION", _left, ""]]] select (_left > 0)
    };
    default {[]};
}
