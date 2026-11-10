#include "script_component.hpp"
/*
 * Author: YonV
 * Autofill source "squadAce:<letter>" (report-card review, user 2026-11-02,
 * D21, D22): the worst of the sender's squad's ACE letter - A ammunition, C
 * casualties, E equipment - for a SITREP's STATUS. Each man's letters are the
 * ones jmfsb_tacpad_apps' Squad app publishes on him, [A, C, E], 0 best to 3
 * worst; a man who has not reported reads best, as the Squad app reads him.
 * C is what the engine says where it knows better: a dead man 3, a man down
 * 2 - the Squad app's own rule.
 *
 * Arguments:
 * 0: The letter, "A", "C" or "E" <STRING>
 *
 * Return Value:
 * GREEN, YELLOW, RED or BLACK; "" for a letter that is not one <STRING>
 *
 * Example:
 * ["A"] call jmfsb_tacpad_fnc_autoSquadAce
 *
 * Public: No
 */

params [["_letter", "", [""]]];

private _at = AUTO_ACE_LETTERS find (toUpper _letter);
if (_at < 0) exitWith {""};

private _worst = 0;
{
    private _unit = _x;
    private _level = (_unit getVariable [QEGVAR(tacpad_apps,ace), []]) param [_at, 0];
    if !(_level isEqualType 0) then {_level = 0};

    if (_at isEqualTo AUTO_ACE_C) then {
        if (!alive _unit) then {
            _level = AUTO_ACE_DEAD;
        } else {
            private _down = if (isNil QEFUNC(common,isUnconscious)) then {
                lifeState _unit == "INCAPACITATED"
            } else {
                [_unit] call EFUNC(common,isUnconscious)
            };
            if (_down) then {_level = _level max AUTO_ACE_DOWN};
        };
    };

    _worst = _worst max _level;
} forEach (units group player);

AUTO_STATES select ((_worst max 0) min (count AUTO_STATES - 1))
