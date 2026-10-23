#include "script_component.hpp"
/*
 * Author: JMSB
 * One virtual gun fires one round: it comes off the battery's stock now,
 * counts towards the mission's per-round cooldown, and arrives a time of
 * flight later within the battery's dispersion of its aim point. A round
 * whose mission was recalled or finished in the meantime is never fired, and
 * so never spent.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Mission token <NUMBER>
 * 2: Round kind <STRING>
 * 3: Ammo class <STRING>
 * 4: The round's aim point, ATL <ARRAY>
 * 5: Descent angle (deg) <NUMBER>
 * 6: High-angle descent, the fallback when terrain masks the low one (deg) <NUMBER>
 * 7: Time of flight (s) <NUMBER>
 * 8: Bearing, battery to target (deg) <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, 1, "he", "Sh_155mm_AMOS", _aim, 70, 70, 52, 45] call jmfsb_support_fires_fnc_virtualShot
 *
 * Public: No
 */

params ["_logic", "_token", "_kind", "_cls", "_aim", "_angle", "_steep", "_tof", "_dir"];

if (isNull _logic || {(_logic getVariable [QGVAR(token), -1]) isNotEqualTo _token}) exitWith {};

private _stock = _logic getVariable [QGVAR(stock), []];
private _index = _stock findIf {(_x select 3) isEqualTo _kind};
if (_index < 0) exitWith {};
private _entry = _stock select _index;
private _left = _entry param [1, 0];
if (_left isEqualTo 0) exitWith {};
if (_left > 0) then {
    _entry set [1, _left - 1];
    _logic setVariable [QGVAR(stock), _stock, true];
};
_logic setVariable [QGVAR(fired), (_logic getVariable [QGVAR(fired), 0]) + 1];

private _disp = _logic getVariable [QGVAR(dispersion), 0];
private _impact = _aim getPos [_disp * sqrt random 1, random 360];

[{_this call FUNC(virtualRound)}, [_logic, _cls, _impact, _angle, _steep, _dir], (_tof - VA_DESCENT_TIME) max 0] call CBA_fnc_waitAndExecute;
