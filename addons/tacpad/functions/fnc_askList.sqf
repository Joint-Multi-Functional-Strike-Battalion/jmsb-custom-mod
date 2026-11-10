#include "script_component.hpp"
/*
 * Author: YonV
 * The questions waiting for this player, in the order the walking view shows
 * them (user, 2026-11-06): FLASH first, then the newest. Takes down any whose
 * thread his index now reads as over, or whose own timeout has run out, so
 * a question he can no longer answer never holds the keys.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [id, question <HASHMAP>] pairs <ARRAY>
 *
 * Example:
 * private _asks = [] call jmfsb_tacpad_fnc_askList
 *
 * Public: No
 */

private _rows = missionNamespace getVariable [QEGVAR(messaging,index), []];
private _fnc_over = {
    params ["_threadId"];
    private _at = _rows findIf {
        _x isEqualType createHashMap && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
    };
    _at >= 0 && {((_rows select _at) getOrDefault ["status", ""]) in ASK_OVER_STATES}
};

private _gone = false;
{
    private _until = _y getOrDefault ["until", 0];
    private _local = (_y getOrDefault ["kind", ""]) isEqualTo ASK_MODE_LOCAL;
    if ((_local && {_until > 0 && CBA_missionTime > _until}) || {!_local && {[_x] call _fnc_over}}) then {
        GVAR(asks) deleteAt _x;
        _gone = true;
    };
} forEach +GVAR(asks);
{
    if ([_x] call _fnc_over) then {
        GVAR(askCrew) deleteAt _x;
        _gone = true;
    };
} forEach +GVAR(askCrew);
if (_gone) then {[] call FUNC(askChanged)};

private _keyed = [];
{
    _keyed pushBack [[0, 1] select (_y getOrDefault ["flash", false]), _y getOrDefault ["at", 0], _x];
} forEach GVAR(asks);
_keyed sort false;

_keyed apply {[_x select 2, GVAR(asks) get (_x select 2)]}
