#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_hackComplete

Description:
    A hack finished. What happens next depends on what was hacked and, for towers
    and units, on the intel chosen before it started - the pick is already made,
    so completion just cashes it in.

Parameters:
    _device : OBJECT - what was hacked.
    _kind   : STRING - "tower" | "drone" | "wreck" | "unit".
    _intel  : STRING - the chosen product, or "none" for a drone.
    _action : STRING - HACK_ACTION_SPOOF to spoof a unit's net's GPS instead
              of pulling the product (FUNC(canSpoof)); optional, default the
              kind's own.

Author:
    JMSB
---------------------------------------------------------------------------- */
params ["_device", "_kind", "_intel", ["_action", HACK_ACTION_DEFAULT, [""]]];

if (isNull _device) exitWith {};

// THE FAIL ROLL (new.md section 2). Towers and units have security worth
// beating; a wreck does not - there is nobody left to notice you reading it.
// A player already carrying a silent flag fails at three times the odds, and
// is never told why.
// ONE FLAT GUARD AT FUNCTION SCOPE. The roll used to exitWith inside the
// then-block, which exits only the block - "Intrusion FAILED" printed, the
// reaction fired, and the hack then delivered anyway. A tower could never
// actually fail. Same trap, same fix, as reaction's SATCOM exemption.
private _failed = false;
if (_kind in ["tower", "unit"] && {!isNil "jmfsb_reaction_fnc_flagged"}) then {
    ([player] call jmfsb_reaction_fnc_flagged) params ["", "_mult"];
    private _fail = (missionNamespace getVariable ["jmfsb_reaction_failChance", 15]) * _mult;
    _failed = random 100 < _fail;
};
if (_failed) exitWith {
    _device setVariable [QGVAR(lastHack), CBA_missionTime, true];
    ["Hack", "Intrusion FAILED.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
    [QEGVAR(reaction,event), [player, "hack"]] call CBA_fnc_serverEvent;
};

switch (_kind) do {
    // --- drone: no intel, the hack IS the effect --------------------------
    case "drone": {
        _device setVariable [QGVAR(hacked), true, true];
        [QGVAR(deleteDrone), _device] call CBA_fnc_serverEvent;
        ["Hack", "Drone downed.", [0.6, 1, 0.6, 1]] call EFUNC(notify,notify);
    };

    // --- downed drone: the intel it was carrying when it fell -------------
    // No counter-detection and no cooldown: a wreck is not calling anyone, and
    // there is nothing to come back for. One card, one pull.
    case "wreck": {
        _device setVariable [QGVAR(stripped), true, true];
        [QGVAR(pick), [_intel, getPosASL _device, side group player, player, _device]] call CBA_fnc_serverEvent;
    };

    // --- remote unit: fail roll, then the chosen intel --------------------
    case "unit": {
        private _pos = getPosASL _device;
        _device setVariable [QGVAR(hacked), true, true];

        // THE WHOLE NET GOES, not the one handset. The list offers a group, so
        // breaking it has to close the group - otherwise the next scan just
        // offers the man standing beside him and the same net can be worked
        // over and over for as many phones as it carries.
        // A vehicle carrying a set is its crew's net (FUNC(scanDevices)).
        private _grp = group ([_device, effectiveCommander _device] select !(_device isKindOf "CAManBase"));
        if (!isNull _grp) then {
            _grp setVariable [QGVAR(hacked), true, true];
            { _x setVariable [QGVAR(hacked), true, true] } forEach (units _grp);
        };

        // EVERY NET AFTER THE FIRST COSTS MORE - see FUNC(netFailChance). Booked
        // before the roll, so this break counts against itself: the man who has
        // just done five is taking the risk of a sixth, not of a first.
        [] call FUNC(netBroken);
        private _failChance = [] call FUNC(netFailChance);
        if (random 100 < _failChance) exitWith {
            ["Hack", "Intrusion detected - they know someone was in their net.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
            [QGVAR(remoteFail), [player, getPosASL player]] call CBA_fnc_serverEvent;
        };

        // SPOOF: the net's GPS walks off true (jmfsb_ew's engine, its own
        // length and drift settings) instead of a product. Past the same
        // fail roll and the same detection roll as a TAP.
        if (_action isEqualTo HACK_ACTION_SPOOF && !isNil QEFUNC(ew,spoofNode)) exitWith {
            [_grp, player] call EFUNC(ew,spoofNode);
            ["Hack", format ["GPS spoof injected - %1's sets are walking off their true position.", groupId _grp], [0.6, 1, 0.6, 1]] call EFUNC(notify,notify);
        };

        [QGVAR(pick), [_intel, _pos, side group player, player, _device]] call CBA_fnc_serverEvent;
    };

    // --- tower: cooldown, then the chosen intel ---------------------------
    default {
        _device setVariable [QGVAR(hacked), true, true];
        _device setVariable [QGVAR(lastHack), CBA_missionTime, true];
        [QGVAR(pick), [_intel, getPosASL _device, side group player, player, _device]] call CBA_fnc_serverEvent;
    };
};
