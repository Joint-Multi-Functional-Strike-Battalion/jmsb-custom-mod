#include "script_component.hpp"
/*
 * Author: JMSB
 * Every machine: the server's call table and pending callbacks. On a client,
 * the local player's calls are diffed against the last table and the
 * events and sounds follow from the difference:
 * - jmfsb_voice_callState [callId, state] on every change ("ringing",
 *   "outgoing", "live", "warning", "ended");
 * - jmfsb_voice_callRing [callId, fromUnit] and the ring when he starts
 *   ringing;
 * - connect when his call goes live (the call becomes his active net, the
 *   net before it comes back when it ends), join chime when someone joins,
 *   hang-up when someone leaves or it ends, priority warning before a
 *   FLASH call takes the slot.
 *
 * Arguments:
 * 0: Variable name (unused) <STRING>
 * 1: [call table, callbacks] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jmfsb_voice_callPub", [[], []]] call jmfsb_voice_fnc_receiveCalls
 *
 * Public: No
 */

params ["", ["_pub", [[], []], [[]]]];
_pub params [["_table", [], [[]]], ["_callbacks", [], [[]]]];

GVAR(callTable) = _table;
GVAR(callbackTable) = _callbacks;
if (!hasInterface || isNull player) exitWith {};

private _old = GVAR(myCalls);
private _new = createHashMap;
private _goLive = "";
{
    _x params ["_id", "_slot", "_from", "_members", "_ringing", "", "", "_live", "_bumping"];
    private _state = "";
    if (player in _ringing) then {
        _state = STATE_RINGING;
    } else {
        if (player in _members) then {_state = [STATE_OUTGOING, STATE_LIVE] select _live};
    };
    if (_state isEqualTo "") then {continue};

    private _net = format [CALL_FORMAT, _slot];
    _new set [_id, [_state, count _members, _bumping]];
    (_old getOrDefault [_id, ["", 0, false]]) params ["_was", "_count", "_wasBumping"];

    if (_state isNotEqualTo _was) then {
        [QGVAR(callState), [_id, _state]] call CBA_fnc_localEvent;
        if (_state isEqualTo STATE_RINGING) then {
            [QGVAR(callRing), [_id, _from]] call CBA_fnc_localEvent;
            ["ring", _net] call FUNC(playCue);
        };
        if (_state isEqualTo STATE_LIVE) then {
            ["connect", _net] call FUNC(playCue);
            _goLive = _net;
        };
    } else {
        if (_state isEqualTo STATE_LIVE && count _members > _count) then {["joinChime", _net] call FUNC(playCue)};
        if (_state isEqualTo STATE_LIVE && count _members < _count) then {["hangUp", _net] call FUNC(playCue)};
    };
    if (_bumping && !_wasBumping) then {
        ["priorityWarning", _net] call FUNC(playCue);
        [QGVAR(callState), [_id, STATE_WARNING]] call CBA_fnc_localEvent;
    };
} forEach _table;

{
    if (_x in _new) then {continue};
    [QGVAR(callState), [_x, STATE_ENDED]] call CBA_fnc_localEvent;
    if ((_y select 0) isEqualTo STATE_LIVE) then {["hangUp", ""] call FUNC(playCue)};
} forEach _old;
GVAR(myCalls) = _new;

GVAR(myNets) = [player] call FUNC(nets);
if (_goLive isNotEqualTo "") then {
    if (GVAR(beforeCall) isEqualTo "" && {([GVAR(activeNetId)] call FUNC(netKind)) isNotEqualTo KIND_CALL}) then {
        GVAR(beforeCall) = GVAR(activeNetId);
    };
    GVAR(wantActive) = _goLive;
};
[] call FUNC(checkActive);
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
