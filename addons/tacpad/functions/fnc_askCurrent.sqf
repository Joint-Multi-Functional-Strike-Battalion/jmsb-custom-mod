#include "script_component.hpp"
/*
 * Author: YonV
 * The one question the walking view's keys answer now (user, 2026-11-06): the
 * first waiting one (FUNC(askList) - FLASH first, then the newest); with none
 * waiting, the newest support request this player is the crew for, whose
 * questions he may ask (ASK_CREW_QUESTIONS). A new question starts on its
 * first page, with no distance pick open.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * 0: Id - thread id or local key, "" none <STRING>
 * 1: Question <HASHMAP>
 * 2: Its place among the waiting ones, 1 first (0 for a crew's) <NUMBER>
 * 3: How many wait <NUMBER>
 *
 * Example:
 * ([] call jmfsb_tacpad_fnc_askCurrent) params ["_id", "_ask", "_n", "_of"]
 *
 * Public: No
 */

private _asks = [] call FUNC(askList);
private _id = "";
private _ask = createHashMap;
private _n = 0;
if (_asks isNotEqualTo []) then {
    (_asks select 0) params ["_first", "_question"];
    _id = _first;
    _ask = _question;
    _n = 1;
} else {
    private _newest = -1;
    {
        private _at = _y getOrDefault ["at", 0];
        if (_at > _newest) then {
            _newest = _at;
            _id = _x;
            _ask = _y;
        };
    } forEach GVAR(askCrew);
};

if (_id isNotEqualTo GVAR(askShown)) then {
    GVAR(askShown) = _id;
    GVAR(askPage) = 0;
    if ((GVAR(askPick) param [0, ""]) isNotEqualTo _id) then {GVAR(askPick) = []};
};

[_id, _ask, _n, count _asks]
