#include "script_component.hpp"
/*
 * Author: JMSB
 * A hack finished on this tablet. What happens next depends on what was
 * hacked and, for towers and units, on the intel chosen before it started -
 * the pick is already made, so completion just cashes it in.
 *
 * THE SERVER DOES THE WORK (review S7). This machine rolls what is its own -
 * the fail roll and a net's detection roll, which only ever cost the hacker -
 * and sends the result by remoteExec to FUNC(srvHackComplete), which checks
 * the sender, the device, the clock and the product before it downs a drone,
 * marks anything broken or pulls a product. Nothing here names a side, a
 * position or a hacker for the server to believe.
 *
 * Arguments:
 * 0: What was hacked <OBJECT>
 * 1: Kind, "tower" | "drone" | "wreck" | "unit" <STRING>
 * 2: The chosen product, "none" for a drone <STRING>
 * 3: HACK_ACTION_SPOOF to spoof a unit's net's GPS instead of pulling the
 *    product (FUNC(canSpoof)) (optional, default the kind's own) <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_device, "tower", "aa"] call jmfsb_hacking_fnc_hackComplete
 *
 * Public: No
 */

params [["_device", objNull, [objNull]], ["_kind", "", [""]], ["_intel", "", [""]], ["_action", HACK_ACTION_DEFAULT, [""]]];

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
    // His own failure, by remoteExec so the server knows it is his (review R1).
    if (!isNil QEFUNC(reaction,report)) then {
        [player, "hack"] remoteExecCall [QEFUNC(reaction,report), SERVER_OWNER];
    };
};

private _outcome = HACK_ACTION_DEFAULT;

switch (_kind) do {
    // --- drone: no intel, the hack IS the effect --------------------------
    case "drone": {
        ["Hack", "Drone downed.", [0.6, 1, 0.6, 1]] call EFUNC(notify,notify);
    };

    // --- remote unit: the net's detection roll, then SPOOF or the intel ----
    case "unit": {
        // EVERY NET AFTER THE FIRST COSTS MORE - see FUNC(netFailChance). Booked
        // before the roll, so this break counts against itself: the man who has
        // just done five is taking the risk of a sixth, not of a first.
        [] call FUNC(netBroken);
        private _failChance = [] call FUNC(netFailChance);
        if (random 100 < _failChance) exitWith {
            ["Hack", "Intrusion detected - they know someone was in their net.", [1, 0.3, 0.3, 1]] call EFUNC(notify,notify);
            _outcome = HACK_OUTCOME_DETECTED;
        };

        // SPOOF: the net's GPS walks off true (jmfsb_ew's engine, its own
        // length and drift settings) instead of a product. Past the same
        // fail roll and the same detection roll as a TAP.
        if (_action isEqualTo HACK_ACTION_SPOOF && !isNil QEFUNC(ew,spoofNode)) exitWith {
            private _grp = group ([_device, effectiveCommander _device] select !(_device isKindOf "CAManBase"));
            ["Hack", format ["GPS spoof injected - %1's sets are walking off their true position.", groupId _grp], [0.6, 1, 0.6, 1]] call EFUNC(notify,notify);
            _outcome = HACK_ACTION_SPOOF;
        };
    };
};

// review S7: the server checks and acts - the device's own position, the
// sender's own side, the product only if the device offers it.
[_device, _kind, _intel, _outcome] remoteExecCall [QFUNC(srvHackComplete), SERVER_OWNER];
