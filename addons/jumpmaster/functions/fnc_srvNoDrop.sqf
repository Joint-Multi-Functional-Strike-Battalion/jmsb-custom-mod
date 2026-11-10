#include "script_component.hpp"
/*
 * Author: YonV
 * Server: NO DROP from the leader (docs/DESIGN_MESSAGE_TEMPLATES.md tree 2,
 * 2026-11-09; FM 3-21.38 Table 3-3: "do not drop - fly another pass or await
 * orders"), from FUNC(srvReply):
 *
 *   on the run-in, at the red light or the green
 *                   no jump this pass - the green light is not given, and men
 *                   still going out stop; it circles to the run-in for another
 *                   pass, which is not counted (NO DROP - CIRCLING FOR PASS n)
 *   holding over the DZ after the last pass
 *                   no more men put out; it holds and asks for GO again
 *   not on the run (before WHEELS UP or BOARD, circling, leaving)
 *                   nothing to stop - it says so
 *
 * Arguments:
 * 0: The run <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st] call jmfsb_jumpmaster_fnc_srvNoDrop
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvNoDrop: refused - remote call from machine %1",remoteExecutedOwner);
};

private _veh = _st get "veh";
private _phase = _st get "phase";

if (_phase isEqualTo PHASE_HOLD) exitWith {
    _st set ["go", false];
    private _aboard = [_st] call FUNC(aboard);
    [_st, "NO DROP. Holding over the drop zone: JUMP when told.", false] call FUNC(srvLight);
    [_st get "assetId", _st get "thread", format [PROMPT_NO_DROP_HOLD, count _aboard], PROMPT_NO_DROP_ANSWERS, _st get "callsign", {}, false] call EFUNC(support,prompt);
};

if (!alive _veh || {!(_phase in [PHASE_IN, PHASE_RED, PHASE_GREEN])}) exitWith {
    [_st get "assetId", _st get "thread", SAID_NO_DROP_NOT_RUN, false, _st get "callsign"] call EFUNC(support,threadEvent);
};

// Another pass: the same pass number again, the men of this pass still aboard
// going on it.
_st set ["goNow", false];
_st set ["phase", PHASE_CIRCLE];
[_veh, _st get "start", "NORMAL"] call EFUNC(support_air,moveTo);
[_st, "NO DROP. Circling for another pass.", false] call FUNC(srvLight);
[_st get "assetId", _st get "thread", format [SAID_NO_DROP_CIRCLE, (_st get "pass") + 1], false, _st get "callsign"] call EFUNC(support,threadEvent);
INFO_2("srvNoDrop: %1 circling, pass %2 again",_st get "callsign",(_st get "pass") + 1);
