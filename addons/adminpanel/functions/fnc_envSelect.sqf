#include "script_component.hpp"
/*
 * Author: JMSB
 * Selects the row of a TIME / WEATHER combo whose value is nearest the one
 * given, so a world value between two steps still lands on a row.
 *
 * Arguments:
 * 0: Combo <CONTROL>
 * 1: Value <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_combo, 35] call jmfsb_adminpanel_fnc_envSelect
 *
 * Public: No
 */

params ["_ctrl", "_value"];

if (lbSize _ctrl == 0) exitWith {};

private _best = 0;
private _gap = abs ((_ctrl lbValue 0) - _value);
for "_i" from 1 to (lbSize _ctrl - 1) do {
    private _here = abs ((_ctrl lbValue _i) - _value);
    if (_here < _gap) then {
        _gap = _here;
        _best = _i;
    };
};

_ctrl lbSetCurSel _best;
