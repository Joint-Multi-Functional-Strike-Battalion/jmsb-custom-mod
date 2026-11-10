#include "script_component.hpp"
/*
 * Author: YonV
 * Which of PTT 2-4 a net is on, for the RADIO app's PTT tag. With a net given
 * next: the RADIO app's PTT key steps the net to the next of PTT 2, 3, 4 and
 * none (FUNC(pttNet)). A key moved to this net leaves the net it had; the key
 * it steps off goes back to its default place, or to nothing (PTT_OFF) where
 * that place is this same net.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Step it to the next key <BOOL> (optional, default false)
 *
 * Return Value:
 * PTT key 2..4 the net is on now, 0 for none <NUMBER>
 *
 * Example:
 * ["C2"] call jmfsb_voice_fnc_pttKey
 * ["C2", true] call jmfsb_voice_fnc_pttKey
 *
 * Public: Yes
 */

params [["_net", "", [""]], ["_step", false, [false]]];

if (_net isEqualTo "") exitWith {0};

private _fnc_on = {
    private _on = 0;
    for "_k" from PTT_ACTIVE + 1 to PTT_KEYS do {
        if (_on isEqualTo 0 && {([_k] call FUNC(pttNet)) isEqualTo _net}) then {_on = _k};
    };
    _on
};

private _on = call _fnc_on;
if (!_step) exitWith {_on};

// Off its key, onto the next; past PTT 4 it is on none.
if (_on > 0) then {
    GVAR(pttNets) deleteAt _on;
    if (([_on] call FUNC(pttNet)) isEqualTo _net) then {GVAR(pttNets) set [_on, PTT_OFF]};
};
private _next = [_on + 1, PTT_ACTIVE + 1] select (_on isEqualTo 0);
if (_next <= PTT_KEYS) then {GVAR(pttNets) set [_next, _net]};
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
call _fnc_on
