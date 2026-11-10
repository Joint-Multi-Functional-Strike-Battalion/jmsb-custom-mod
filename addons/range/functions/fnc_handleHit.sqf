#include "..\script_component.hpp"
/*
 * Author: YonV
 * The pop-up targets' HitPart handler (config, replacing the game's). Runs
 * on the shooter's machine.
 *
 * Off a running range it does what the game's did: the target drops and
 * comes back up after POPUP_DELAY, unless the mission set nopop or the
 * target is on an instructor's board (FUNC(targetGroups)). On a
 * running range a hit counts only for the shooter who started it, only on
 * a target that is up for the run, and only once.
 *
 * Arguments:
 * 0: Target <OBJECT>
 * 1: Shooter <OBJECT>
 * 2-4: Unused
 * 5: Selections hit <ARRAY>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_target", "_shooter", "", "", "", ["_parts", [], [[]]]];

if ((_parts findIf {(toLower _x) in TARGET_PARTS}) < 0) exitWith {};

private _range = _target getVariable [QGVAR(range), objNull];
private _run = if (isNull _range) then {[]} else {_range getVariable [QGVAR(run), []]};

if (_run isEqualTo []) exitWith {
    if (_target call FUNC(isDown)) exitWith {};
    [_target, TARGET_DOWN] call FUNC(setTarget);
    if ((missionNamespace getVariable ["nopop", false]) isEqualTo true) exitWith {};
    if (_target getVariable [QGVAR(stayDown), false]) exitWith {};
    [{[_this, TARGET_UP] call FUNC(setTarget)}, _target, POPUP_DELAY] call CBA_fnc_waitAndExecute;
};

private _shooterRun = _run select 0;
if (_shooter isNotEqualTo _shooterRun) exitWith {
    if (local _shooter && {hasInterface}) then {
        [NOTE_TITLE, format ["%1 is in use by %2 - hold your fire.",
            (_range getVariable [QGVAR(cfg), createHashMap]) getOrDefault ["name", ""], name _shooterRun], NOTE_BAD] call EFUNC(notify,notify);
    };
};

private _s = GVAR(session);
if (count _s isEqualTo 0 || {(_s get "range") isNotEqualTo _range}) exitWith {};
if ((_s get "phase") isNotEqualTo "run" || {_target getVariable [QGVAR(hit), true]}) exitWith {};

_target setVariable [QGVAR(hit), true];
_s set ["hits", (_s get "hits") + 1];
[_target, TARGET_DOWN] call FUNC(setTarget);
[QGVAR(say), [_target, SOUND_HIT]] call CBA_fnc_globalEvent;
