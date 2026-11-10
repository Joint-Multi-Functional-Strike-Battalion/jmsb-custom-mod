#include "script_component.hpp"
/*
 * Author: YonV
 * The jam registry applied (client, every half second and on every new
 * source): expired sources dropped, GVAR(jammed) set while any remain, and a
 * cue at each edge - nothing here is player-triggered, so a silent comms
 * failure would read as a bug. The ACRE lever it also set went with ACRE
 * (DEC1, 2026-10-31).
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

private _now = CBA_missionTime;
{
    if (_y <= _now) then { GVAR(jamSources) deleteAt _x };
} forEach +GVAR(jamSources);

private _jammed = (count GVAR(jamSources)) > 0;
if (_jammed isEqualTo GVAR(jammed)) exitWith {};
GVAR(jammed) = _jammed;

if (_jammed) then {
    playSound "Beep_Target";
    ["RF BURST", "Radio and datalink down.", [1, 0.776, 0.102, 1]] call EFUNC(notify,notify);
    // a moment of chromatic smear on the screen, gone in two seconds
    private _pp = ppEffectCreate ["ChromAberration", 1600];
    _pp ppEffectEnable true;
    _pp ppEffectAdjust [0.03, 0.03, true];
    _pp ppEffectCommit 0;
    [{
        params ["_pp"];
        _pp ppEffectAdjust [0, 0, true];
        _pp ppEffectCommit 1.5;
        [{ ppEffectDestroy (_this select 0) }, [_pp], 2] call CBA_fnc_waitAndExecute;
    }, [_pp], 0.5] call CBA_fnc_waitAndExecute;
} else {
    playSound "ClickSoft";
    ["RF BURST", "Radio back.", [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
};
