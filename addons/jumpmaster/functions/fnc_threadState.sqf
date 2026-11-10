#include "script_component.hpp"
/*
 * Author: YonV
 * Server: moves the run's thread (EFUNC(support,state), naming it; 2026-11-02)
 * under the aircraft's call sign - ACCEPTED is the WILCO, IN_PROGRESS at
 * WHEELS UP, CLOSED when it leaves or is lost, DECLINED when it never flew.
 * A state at or behind the thread's, or after it is over, is not said.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: State - "ACCEPTED", "IN_PROGRESS", "CLOSED", "DECLINED" <STRING>
 * 2: What the aircraft says, "" nothing <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st, "CLOSED", "STICK OUT - LEAVING THE DZ"] call jmfsb_jumpmaster_fnc_threadState
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_state", "", [""]], ["_said", "", [""]]];

if (!isServer) exitWith {};

// THE DZ OUTLASTS THE THREAD (user, 2026-11-02): it closes as the aircraft
// leaves the DZ, with the stick still in the air - the DZ stays in the side's
// AiTR until every jumper is down (EFUNC(support,zonesHold)). A run never flown
// (DECLINED) takes it with its close.
if (_state isEqualTo "CLOSED") then {
    [_st getOrDefault ["thread", ""], _st getOrDefault ["jumpers", []]] call EFUNC(support,zonesHold);
};

[_st getOrDefault ["assetId", ""], _state, _said, _st getOrDefault ["callsign", JUMP_CALLSIGN], false, _st getOrDefault ["thread", ""]] call EFUNC(support,state);
