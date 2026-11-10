#include "script_component.hpp"
/*
 * Author: YonV
 * The device keys while a watch profile is on (decided 2026-11-07; 2026-11-08:
 * "use the arrow keys to select them then f keys", "f2 should be a share
 * key"): the arrows pick a slot (FUNC(selected)), F1 reports it, F2 shares it
 * (the profile's "share" - medical: every medic within 5 m), F3 all off, F4
 * squad view. Hooked into the walking view (jmfsb_devices' buttonHooks);
 * answers false - the key stays the device's - while nothing is watched, for
 * the arrows with fewer than two slots, and for a key whose profile has
 * nothing behind it.
 *
 * Arguments:
 * 0: Device button index, 0-3 F1-F4, 4-5 the arrows <NUMBER>
 *
 * Return Value:
 * Taken <BOOL>
 *
 * Example:
 * [0] call jmfsb_watch_fnc_button
 *
 * Public: No
 */

params [["_index", -1, [0]]];

private _id = [] call FUNC(current);
if (_id isEqualTo "") exitWith {false};
private _spec = GVAR(profiles) getOrDefault [_id, createHashMap];
private _slots = GVAR(slots) getOrDefault [_id, []];
private _picked = [_id] call FUNC(selected);
private _target = [objNull, (_slots param [_picked, [objNull]]) # 0] select (_picked >= 0);

switch (_index) do {
    case KEY_REPORT;
    case KEY_SHARE: {
        private _code = _spec getOrDefault [["report", "share"] select (_index isEqualTo KEY_SHARE), {}];
        if (_code isEqualTo {} || {isNull _target}) exitWith {false};
        [_target] call _code;
        true
    };
    case KEY_ALL_OFF: {
        [] call FUNC(allOff);
        true
    };
    // any profile he has that offers one (team lead), whichever is current
    case KEY_SQUAD: {
        private _code = {};
        {
            if ((_y getOrDefault ["squad", {}]) isNotEqualTo {} && {[player] call (_y getOrDefault ["gate", {false}])}) exitWith {_code = _y get "squad"};
        } forEach GVAR(profiles);
        if (_code isEqualTo {}) exitWith {false};
        [] call _code;
        true
    };
    case KEY_LEFT;
    case KEY_RIGHT: {
        private _count = count _slots;
        if (_count < 2) exitWith {false};
        GVAR(selected) set [_id, (_picked + ([-1, 1] select (_index isEqualTo KEY_RIGHT)) + _count) mod _count];
        true
    };
    default {false};
}
