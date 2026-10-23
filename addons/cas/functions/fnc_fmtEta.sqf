#include "script_component.hpp"
/*
 * Author: JMSB
 * A time as the support board's verdict line reads it: whole seconds under a
 * minute, then minutes and seconds rounded to ETA_STEP ("40 S", "3 MIN",
 * "2 MIN 40 S"). Shared by both CAS providers - this addon's drones and
 * support_air, which requires this addon - so every ETA on the board is
 * written the same way.
 *
 * Arguments:
 * 0: Seconds <NUMBER>
 *
 * Return Value:
 * Text <STRING>
 *
 * Example:
 * [160] call jmfsb_cas_fnc_fmtEta
 *
 * Public: No
 */

params [["_s", 0, [0]]];

_s = 0 max _s;
if (_s < ETA_MINUTE) exitWith {format ["%1 S", round _s]};

private _t = (round (_s / ETA_STEP)) * ETA_STEP;
private _min = floor (_t / ETA_MINUTE);
private _sec = _t - _min * ETA_MINUTE;
if (_sec isEqualTo 0) exitWith {format ["%1 MIN", _min]};

format ["%1 MIN %2 S", _min, _sec]
