#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a threat warning to one player (DESIGN_EW "Threat warning": time,
 * detail and what to do). Kept on the server for his slice - the OVERVIEW
 * tab lists the recent ones - and raised on his machine at once, where
 * FUNC(onThreat) puts it on the notification rail.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Kind, e.g. "DF ON YOU" <STRING>
 * 2: Detail <STRING>
 * 3: What to do <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, "DF ON YOU", "EAST CUT ON YOUR VHF SET", "MOVE"] call jmfsb_ew_fnc_warn
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_kind", "", [""]], ["_detail", "", [""]], ["_advice", "", [""]]];

if (!isServer || {isNull _unit} || {!isPlayer _unit}) exitWith {};

private _key = getPlayerUID _unit;
private _list = GVAR(threats) getOrDefault [_key, []];
_list pushBack [round CBA_missionTime, _kind, _detail, _advice];
if (count _list > THREATS_KEPT) then {_list deleteRange [0, count _list - THREATS_KEPT]};
GVAR(threats) set [_key, _list];

// By remoteExec, taken only from the server (review R1: a CBA event any client
// could raise to put a fake EW warning on anyone's screen).
[_kind, _detail, _advice] remoteExecCall [QFUNC(onThreat), _unit];
