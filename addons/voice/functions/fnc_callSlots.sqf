#include "script_component.hpp"
/*
 * Author: JMSB
 * The server-wide call slots (VON custom channels 3-10), for the CALLS tab.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[slot 1..8, callId or "", members count], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_callSlots
 *
 * Public: Yes
 */

if (!GVAR(active)) exitWith {[]};
private _out = [];
for "_slot" from 1 to CALL_SLOTS do {
    private _i = GVAR(callTable) findIf {(_x select 1) isEqualTo _slot};
    if (_i < 0) then {
        _out pushBack [_slot, "", 0];
    } else {
        private _row = GVAR(callTable) select _i;
        _out pushBack [_slot, _row select 0, count (_row select 3)];
    };
};
_out
