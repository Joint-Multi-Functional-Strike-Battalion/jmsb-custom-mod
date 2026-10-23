#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, every tick, per call:
 * - a call marked for a FLASH bump ends when its warning time is up, and the
 *   FLASH dial is made again into the freed slot;
 * - ringing longer than the ring time is no answer (the caller is told, with
 *   CALL BACK offered);
 * - members who are gone or dead leave; a member of a live call without
 *   reach on DATA to any other member for longer than the drop time is
 *   dropped (calls drop when the link drops).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_srvCallTick
 *
 * Public: No
 */

private _now = CBA_missionTime;

{
    private _id = _x;
    private _call = GVAR(calls) getOrDefault [_id, createHashMap];
    if (count _call == 0) then {continue};

    private _bumpAt = _call get "bumpAt";
    if (_bumpAt >= 0 && _now >= _bumpAt) then {
        private _for = _call get "bumpFor";
        [_id, REASON_BUMPED] call FUNC(srvEnd);
        _for call FUNC(srvCall);
        continue;
    };

    private _from = _call get "from";
    private _ringing = _call get "ringing";
    private _late = _ringing select {isNull (_x select 0) || (_now - (_x select 1)) > GVAR(ringTime)};
    if (_late isNotEqualTo []) then {
        _call set ["ringing", _ringing - _late];
        private _who = (_late apply {_x select 0}) select {!isNull _x};
        if (!isNull _from && _who isNotEqualTo []) then {
            [QGVAR(callFailed), [_id, REASON_NO_ANSWER, _who], _from] call CBA_fnc_targetEvent;
        };
    };

    private _members = _call get "members";
    private _lost = _call get "lost";
    private _drop = [];
    {
        private _unit = _x;
        if (isNull _unit || {!alive _unit}) then {
            _drop pushBack _unit;
            continue;
        };
        if !(_call get "live") then {continue};
        private _uid = getPlayerUID _unit;
        if (((_members - [_unit]) findIf {[_unit, _x] call FUNC(dataReach)}) >= 0) then {
            _lost deleteAt _uid;
        } else {
            private _since = _lost getOrDefault [_uid, _now];
            _lost set [_uid, _since];
            if ((_now - _since) > GVAR(callDrop)) then {
                _drop pushBack _unit;
                [QGVAR(callFailed), [_id, REASON_DROPPED, [_unit]], _unit] call CBA_fnc_targetEvent;
            };
        };
    } forEach _members;
    {
        [_id, _x] call FUNC(srvLeave);
    } forEach _drop;

    [_id] call FUNC(srvCheck);
} forEach (keys GVAR(calls));
