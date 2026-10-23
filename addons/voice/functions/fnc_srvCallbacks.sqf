#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, every tick: THE SERVER HOLDS THE CALLBACKS. A request expires after
 * the callback expiry time; it waits while either person is in a call, and
 * is held (not dropped) while either is on EMCON 3. When both can reach each
 * other on DATA and a slot is free, both phones ring (a call with both
 * ringing) and the request is done.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_srvCallbacks
 *
 * Public: No
 */

private _now = CBA_missionTime;
private _keep = [];

{
    _x params ["_from", "_to", "_at"];
    if (isNull _from || isNull _to || (_now - _at) > GVAR(callbackExpire) * SECONDS_PER_MINUTE) then {
        {
            [QGVAR(note), ["CALL BACK", "A callback request expired."], _x] call CBA_fnc_targetEvent;
        } forEach ([_from, _to] select {!isNull _x});
        continue;
    };
    if (([_from] call FUNC(inCall)) isNotEqualTo "" || {([_to] call FUNC(inCall)) isNotEqualTo ""}) then {
        _keep pushBack [_from, _to, _at, CB_WAITING];
        continue;
    };
    private _emcon = [_from, _to] apply {(GVAR(rosterIndex) getOrDefault [getPlayerUID _x, [objNull, "", [], 0]]) select 3};
    if ((selectMax _emcon) >= EMCON_SILENT) then {
        _keep pushBack [_from, _to, _at, CB_HELD];
        continue;
    };
    private _slot = GVAR(slots) find "";
    if (_slot < 0 || {!([_from, _to] call FUNC(dataReach))}) then {
        _keep pushBack [_from, _to, _at, CB_WAITING];
        continue;
    };
    private _id = format ["cb_%1_%2_%3", getPlayerUID _from, getPlayerUID _to, round _now];
    [_id, _from, [], [_from, _to], PRIO_ROUTINE, _slot] call FUNC(srvStart);
} forEach GVAR(callbacks);

GVAR(callbacks) = _keep;
