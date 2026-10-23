#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: publishes the call table and the pending callbacks to everyone
 * (jmfsb_voice_callPub), only when they changed. Small by construction:
 * at most CALL_SLOTS calls of CALL_MAX_MEMBERS people.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_srvPublish
 *
 * Public: No
 */

private _calls = (values GVAR(calls)) apply {
    [_x get "slot", [
        _x get "id",
        _x get "slot",
        _x get "from",
        +(_x get "members"),
        (_x get "ringing") apply {_x select 0},
        _x get "priority",
        _x get "startedAt",
        _x get "live",
        (_x get "bumpAt") >= 0,
        _x getOrDefault ["owner", _x get "from"]
    ]]
};
_calls sort true;
_calls = _calls apply {_x select 1};

private _pub = [_calls, +GVAR(callbacks)];
if (_pub isEqualTo GVAR(published)) exitWith {};
GVAR(published) = _pub;
GVAR(callPub) = _pub;
publicVariable QGVAR(callPub);
[QGVAR(callPub), _pub] call FUNC(receiveCalls);
