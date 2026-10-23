#include "script_component.hpp"
/*
 * Author: JMSB
 * Lets a CAS crew off the leash for a SAD (COMBAT, RED, targeting on) or
 * holds it on one for a run or a loiter (CARELESS, BLUE, targeting off) -
 * see FUNC(casLaunch). Every switch is set either way: a synced aircraft
 * keeps its crew between sorties, and a LOITER's leash must not carry over
 * into the next SAD - nor a SAD's freedom into a repositioned LOITER.
 *
 * Arguments:
 * 0: The crew <GROUP>
 * 1: "sad", "loiter" or "run" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_grp, "sad"] call jmfsb_support_air_fnc_casPosture
 *
 * Public: No
 */

params [["_grp", grpNull, [grpNull]], ["_mode", "run", [""]]];

if (isNull _grp) exitWith {};

private _free = _mode isEqualTo "sad";
_grp setBehaviour (["CARELESS", "COMBAT"] select _free);
_grp setCombatMode (["BLUE", "RED"] select _free);
{
    if (_free) then {
        _x enableAI "TARGET";
        _x enableAI "AUTOTARGET";
        _x enableAI "AUTOCOMBAT";
    } else {
        _x disableAI "TARGET";
        _x disableAI "AUTOTARGET";
        _x disableAI "AUTOCOMBAT";
    };
} forEach units _grp;
