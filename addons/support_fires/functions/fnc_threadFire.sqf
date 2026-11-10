#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a battery tasked by a call for fire fires its next salvo (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 6) - the first one from FUNC(srvThread), or
 * at the observer's CONFIRM; every one after at his call (FUNC(threadReply)).
 *
 * THE BOARD'S ADJUST MACHINERY, REUSED. The call is the board's ADJ_* in the
 * order's options (OPT_ADJUST):
 *   ADJ_ROUND  one adjusting round from one gun on the point
 *   ADJ_FFE    the whole order on the point
 * Laid (nothing fired yet): the mission's first salvo (FUNC(fireMission)) on
 * the wait FUNC(srvThread) worked out - it holds for the issuer once it is
 * down, as an adjust mission from the board does. Held: the held mission's
 * next salvo (FUNC(adjustNext)), at the battery's quickest.
 *
 * The point the call gives becomes the mission's (a correction moves it);
 * rounds per gun can be given for this salvo (the `ffe` card's ROUNDS). Any
 * prompt waiting for an answer is answered. A cruise missile or loitering
 * munition launcher launches instead (FUNC(threadLaunch), 2026-11-01).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The call, ADJ_ROUND or ADJ_FFE <NUMBER>
 * 2: Who called it <OBJECT>
 * 3: The point, [] for the mission's own <ARRAY> (optional, default [])
 * 4: Rounds per gun, -1 for the mission's own <NUMBER> (optional, default -1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, 1, _observer] call jmfsb_support_fires_fnc_threadFire
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_call", ADJ_ROUND, [0]],
    ["_who", objNull, [objNull]],
    ["_target", [], [[]]],
    ["_rounds", -1, [0]]
];

if (!isServer || {isNull _logic}) exitWith {};

private _order = _logic getVariable [QGVAR(threadOrder), createHashMap];
if (count _order isEqualTo 0) exitWith {};
if (_target isEqualTo []) then {_target = _order getOrDefault ["target", []]};
if (_target isEqualTo []) exitWith {};
if (isNull _who) then {_who = _order getOrDefault ["issuer", objNull]};

// The prompt is answered: its waits are over.
_logic setVariable [QGVAR(promptSeq), (_logic getVariable [QGVAR(promptSeq), 0]) + 1];

// A cruise missile or loitering munition launcher (2026-11-01): a launch, not
// a salvo - no adjust call, no rounds per gun.
if ((_logic getVariable [QGVAR(type), ""]) isNotEqualTo TYPE_ARTY) exitWith {
    [_logic, _who] call FUNC(threadLaunch);
};

private _opts = +(_order getOrDefault ["opts", []]);
if (_rounds > 0) then {
    _opts set [1, (round _rounds) max 1 min (_logic getVariable [QGVAR(maxRounds), 1])];
};
_opts set [OPT_ADJUST, _call];
_order set ["target", _target];
_order set ["call", _call];

private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];

if ((_logic getVariable [QGVAR(status), ""]) isEqualTo STATUS_LAID) exitWith {
    [_logic, _target, _opts, _who, _logic getVariable [QGVAR(token), -1], _assetId, _order getOrDefault ["wait", 0]] call FUNC(fireMission);
    // Still laid: the mission was refused (stock or range changed since).
    if ((_logic getVariable [QGVAR(status), ""]) isEqualTo STATUS_LAID) then {
        [_logic, SAID_CANNOT_FIRE] call FUNC(threadEnd);
    };
};

[_logic, _target, _opts, _call, _who, _assetId] call FUNC(adjustNext);
// Not firing: the salvo was refused (that round is spent). Asked again, with
// the D9 waits, rather than left holding in silence.
if ((_logic getVariable [QGVAR(status), ""]) isNotEqualTo STATUS_FIRING) then {
    [_logic, format ["%1 - %2", PROMPT_ADJUST, SAID_CANNOT_FIRE], ANSWERS_ADJUST] call FUNC(threadPrompt);
};
