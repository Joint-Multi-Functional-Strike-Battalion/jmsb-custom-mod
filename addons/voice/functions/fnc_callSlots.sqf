#include "script_component.hpp"
/*
 * Author: YonV
 * The server-wide call slots, for the CALLS tab: under game VON the eight
 * custom channels 3-10; on the voice server as many as the highest slot a
 * call holds (no limit to the number of calls, user 2026-11-01 -
 * FUNC(srvSlot)), never fewer than CALL_SLOTS.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[slot 1..n, callId or "", members count, live], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_callSlots
 *
 * Public: Yes
 */

if (!GVAR(active)) exitWith {[]};
private _last = selectMax ((GVAR(callTable) apply {_x select 1}) + [CALL_SLOTS]);
private _out = [];
for "_slot" from 1 to _last do {
    private _i = GVAR(callTable) findIf {(_x select 1) isEqualTo _slot};
    if (_i < 0) then {
        _out pushBack [_slot, "", 0, false];
    } else {
        private _row = GVAR(callTable) select _i;
        _out pushBack [_slot, _row select 0, count (_row select 3), _row select 7];
    };
};
_out
