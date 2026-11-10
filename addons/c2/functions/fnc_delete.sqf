#include "script_component.hpp"
/*
 * Author: YonV
 * Deletes a C2 measure - the creator, a team lead or an ATL. Server only.
 *
 * Arguments:
 * 0: Measure id <STRING>
 * 1: Who asks <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["M3", player] call jmfsb_c2_fnc_delete
 *
 * Public: No
 */

params [["_mid", "", [""]], ["_who", objNull, [objNull]]];

if (!isServer || {!(_mid in GVAR(measures))}) exitWith {};
private _creator = (GVAR(measures) get _mid) # 4;
if (getPlayerUID _who isNotEqualTo _creator && {!([_who] call FUNC(canEdit))}) exitWith {};
GVAR(measures) deleteAt _mid;
[] call FUNC(publish);
