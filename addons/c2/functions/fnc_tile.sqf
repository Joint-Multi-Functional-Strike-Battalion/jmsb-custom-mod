#include "script_component.hpp"
/*
 * Author: YonV
 * The C2 tile, for team leads and ATLs: how many measures the side has, and
 * the last reportable event while it can still be reported.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile entries, [] or one [appId, kicker, qualifier, value, detail, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_c2_fnc_tile
 *
 * Public: No
 */

if !([player] call FUNC(canEdit)) exitWith {[]};

private _count = {(_x # 7) isEqualTo side group player} count GVAR(measureList);
GVAR(event) params [["_text", ""], ["_at", -1]];
private _live = _text isNotEqualTo "" && {(CBA_missionTime - _at) <= REPORT_WINDOW};
[[APP_ID, "C2", "MEASURES", str _count, [format ["%1 ON THE MAP", _count], _text + " - 9: REPORT"] select _live, ["rest", "warn"] select _live]]
