#include "..\script_component.hpp"
/*
 * Author: JMSB
 * `#jmfsb adsite`: what the intercept system holds and what it costs - units
 * by weapon, alarm areas, threats in the air, whether the engagement PFH is
 * running, the last and worst pass in ms, and the running totals. To the RPT
 * as well as to whoever asked (the debug command replies with the return).
 *
 * Arguments: None
 *
 * Return Value:
 * The status line <STRING>
 *
 * Example:
 * [] call jmfsb_adsite_fnc_status
 *
 * Public: No
 */

private _guns = 0;
private _missiles = 0;
{
    if ((_y select U_GUN) isNotEqualTo []) then { _guns = _guns + 1 };
    if ((_y select U_MISSILE) isNotEqualTo []) then { _missiles = _missiles + 1 };
} forEach GVAR(units);

private _engaged = {(_x select T_UNIT) isNotEqualTo ""} count GVAR(threats);
private _s = GVAR(stats);
private _line = format [
    "adsite: %1 unit(s) (%2 gun, %3 missile) in %4 area(s) | %5 threat(s) in the air, %6 engaged | PFH %7 | pass %8 ms, worst %9 ms | %10 threats, %11 intercepted, %12 missed rolls, %13 landed, %14 dropped over cap",
    count GVAR(units), _guns, _missiles, count GVAR(areas),
    count GVAR(threats), _engaged, ["off", "on"] select (GVAR(pfh) >= 0),
    GVAR(lastMs) toFixed 2, GVAR(maxMs) toFixed 2,
    _s get "threats", _s get "intercepts", _s get "misses", _s get "leaks", _s get "dropped"
];
INFO_1("%1",_line);
_line
