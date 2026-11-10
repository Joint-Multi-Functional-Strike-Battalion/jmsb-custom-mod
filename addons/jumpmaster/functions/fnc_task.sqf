#include "script_component.hpp"
/*
 * Author: YonV
 * The "task" code the support core requires of every provider. The jump
 * aircraft takes its order by message only (user, 2026-11-02): a JUMP
 * REQUEST filed to its box (FUNC(srvThread)). An order through
 * jmfsb_support_fnc_request - a mission script's - is refused, RTB included:
 * the leader's ABORT or RTB in the thread stands a run down.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Task <STRING>
 * 2: Point <ARRAY>
 * 3: Parameters <ARRAY>
 *
 * Return Value:
 * [ok, why] - always refused <ARRAY>
 *
 * Example:
 * ["jump:west", "jump", [], []] call jmfsb_jumpmaster_fnc_task
 *
 * Public: No
 */

[false, WHY_BY_CARD]
