#include "script_component.hpp"
/*
 * Author: YonV
 * Opens a new mission on an asset, on the server: a new token, the recall
 * flag down, nothing claimed, no rounds counted yet.
 *
 * THE MISSION TOKEN. Every order bumps the logic's token and every delayed
 * piece of a mission - a scheduled round, a splash call, the finish - carries
 * the token it was made under. A recall or a finish moves the token on, and
 * whatever was still queued for the old mission sees it and does nothing.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * The mission's token <NUMBER>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_openMission
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {-1};

private _token = (_logic getVariable [QGVAR(token), 0]) + 1;
_logic setVariable [QGVAR(token), _token];
_logic setVariable [QGVAR(abort), false, true];
_logic setVariable [QGVAR(claimed), []];
_logic setVariable [QGVAR(fired), 0];
_logic setVariable [QGVAR(partners), []];
// ADJUST FIRE (2026-11-01): a new mission holds for nobody yet, and its
// rounds count from one. Public values are only sent when they change.
// A launcher's QGVAR(salvo) is its module's salvo size, never reset (2026-11-01).
if ((_logic getVariable [QGVAR(type), ""]) isEqualTo TYPE_ARTY) then {_logic setVariable [QGVAR(salvo), 0]};
_logic setVariable [QGVAR(roundNo), 0];
// AIMING ERROR (user, 2026-11-02): a new mission's first salvo has the
// module's whole error - no correction called yet (FUNC(aimError)).
_logic setVariable [QGVAR(aimSteps), 0];
_logic setVariable [QGVAR(aimFfe), false];
if ((_logic getVariable [QGVAR(holdBy), ""]) isNotEqualTo "") then {_logic setVariable [QGVAR(holdBy), "", true]};
if ((_logic getVariable [QGVAR(rounds), []]) isNotEqualTo []) then {_logic setVariable [QGVAR(rounds), [], true]};
// CALL FOR FIRE BY MESSAGE (2026-11-01, step 6): a new mission fires for no
// thread until FUNC(srvThread) names one.
_logic setVariable [QGVAR(thread), ""];
_logic setVariable [QGVAR(threadOrder), createHashMap];

_token
