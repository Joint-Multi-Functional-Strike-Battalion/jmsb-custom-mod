#include "script_component.hpp"
/*
 * Author: YonV
 * The one detection roll, for every way of being noticed.
 *
 * Degrees (new.md section 2):
 *   not detected      nothing happens, and nothing is said. A system that
 *                     announces its own passes teaches players to read the
 *                     chat instead of the ground.
 *   detected, clean   SMALL - a silent flag. THE PLAYER IS NOT TOLD. That is
 *                     the whole mechanic: walk away and you are fine, try
 *                     again and you find out.
 *   detected, flagged MAJOR - the full reply.
 *
 * Arguments:
 * 0: The player caught <OBJECT>
 * 1: Source tag - "hack", "drone", "radio" <STRING>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_source", "?", [""]]];

// THE MODULE IS THE ENABLE. This system has no placement and no schedule of
// its own - it only answers events - so the gate has to sit on the answer.
// Without a module the events still fire and simply go unanswered.
if (!GVAR(moduleUp)) exitWith {};

if (isNull _unit) exitWith {};

private _id = netId _unit;

// BURN-THROUGH IS NOT ROLLED FOR (user, 2026-08-31: "more powerful radio can
// cut through but will get a QRF"). Every other source here is something that
// MIGHT have been noticed; this one is a set deliberately radiating hard enough
// to beat a jammer, from inside ground the enemy is spending an emitter to keep
// quiet. There is nothing to roll: they heard it.
//
// It skips the flag ladder entirely - straight to MAJOR - and then asks for the
// QRF on top, which is the part that makes the choice cost something. The
// flag is still set on the way past, so a second burn-through by the same man
// is walking into an already-alerted commander.
if (_source isEqualTo "burnthrough") exitWith {
    GVAR(flags) set [_id, CBA_missionTime + REACT_FLAG_DECAY];
    _unit setVariable [QGVAR(flaggedUntil), CBA_missionTime + REACT_FLAG_DECAY, true];

    [_unit, _source] call FUNC(major);

    // The QRF, if the mission fields one. Guarded rather than required: reaction
    // answers events on missions that load no QRF at all, and a missing reply is
    // a quieter mission, not a broken one.
    if (!isNil "jmfsb_qrf_fnc_onCaptured") then {
        ["BURN-THROUGH", side group _unit, getPosATL _unit, REACT_BURN_QRF_RADIUS]
            call jmfsb_qrf_fnc_onCaptured;
    };

    INFO_1("BURN-THROUGH by %1 - MAJOR and a QRF, no roll",name _unit);
};

([_unit] call FUNC(flagged)) params ["_isFlagged", "_mult"];
// The town's word - see REACT_HOSTILITY_FLOOR. ALiVE's civilian model only;
// without ALiVE the town has no word and the roll is the chance as set - nor
// with ALiVE loaded but no commanders (user, 2026-11-02: "same as not loaded").
if (!isNil QEFUNC(adapter_alive,hostilityAt) && {[] call EFUNC(common,aliveLoaded)}) then {
    private _h = [getPosATL _unit, side group _unit] call EFUNC(adapter_alive,hostilityAt);
    _mult = _mult * (REACT_HOSTILITY_FLOOR + (_h / 100));
};

if (random 100 >= (GVAR(detectChance) * _mult)) exitWith {
    // Expired flags are cleared on the way past rather than by a sweeper -
    // the map is only ever wrong while somebody is asking.
    if (!_isFlagged) then { GVAR(flags) deleteAt _id };
};

if (_isFlagged) exitWith {
    [_unit, _source] call FUNC(major);
};

GVAR(flags) set [_id, CBA_missionTime + REACT_FLAG_DECAY];
// Mirrored onto the unit for the CLIENT-side readers (the hacking console's
// fail roll) - see FUNC(flagged). Expired mirrors self-invalidate.
_unit setVariable [QGVAR(flaggedUntil), CBA_missionTime + REACT_FLAG_DECAY, true];
INFO_2("SMALL flag on %1 (%2) - silent by design",name _unit,_source);
