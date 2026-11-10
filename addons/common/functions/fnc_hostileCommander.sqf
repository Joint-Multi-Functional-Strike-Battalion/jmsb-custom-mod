#include "script_component.hpp"
/*
 * Author: YonV
 * Who answers a side: the first commander hostile to it - what kind of war it
 * fights and its faction.
 *
 * WITH ALiVE, the first ALiVE commander hostile to that side, exactly as QRF
 * and reaction each read it before this was shared.
 *
 * WITHOUT ALiVE (user, 2026-11-02: "works with or without"), the mission's
 * enemy (FUNC(enemySide), off the player slots and the side relations) when it
 * is hostile to that side, its faction off its own men (FUNC(sideFaction)). No
 * control type: a commander that does not exist runs no kind of war, and a
 * caller treats "" as "nothing to ask".
 *
 * Arguments:
 * 0: The side being answered <SIDE>
 *
 * Return Value:
 * [side <SIDE>, controltype <STRING>, faction <STRING>] - sideUnknown when
 * nobody is hostile <ARRAY>
 *
 * Example:
 * ([west] call jmfsb_common_fnc_hostileCommander) params ["_answering", "_ctype", "_faction"];
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [sideUnknown]]];

private _out = [sideUnknown, "", ""];
if (_side isEqualTo sideUnknown) exitWith {_out};

// ALiVE loaded with no commanders is not loaded (user, 2026-11-02: "same as
// not loaded") - FUNC(aliveLoaded) says no once the adapter has given up.
if (!isNil QEFUNC(adapter_alive,commanders) && {[] call FUNC(aliveLoaded)}) exitWith {
    {
        _x params ["_cside", "_ctype", "_faction"];
        if (_cside getFriend _side < COMMANDER_HOSTILE_BELOW) exitWith {
            _out = [_cside, _ctype, _faction];
        };
    } forEach (call EFUNC(adapter_alive,commanders));
    _out
};

private _enemy = call FUNC(enemySide);
if (_enemy isEqualTo _side || {_enemy getFriend _side >= COMMANDER_HOSTILE_BELOW}) exitWith {_out};

[_enemy, "", [_enemy] call FUNC(sideFaction)]
