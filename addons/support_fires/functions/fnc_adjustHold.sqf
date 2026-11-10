#include "script_component.hpp"
/*
 * Author: YonV
 * ADJUST FIRE, on the server (TAC//SUPPORT v2 build step 6, 2026-11-01): an
 * adjust mission's salvo is down and the battery HOLDS for its observer
 * instead of ending the mission - status STATUS_ADJUST, the token kept, the
 * target still marked, the thread still open. FUNC(fireVirtual) calls it where
 * an ordinary mission calls FUNC(finish).
 *
 * The observer's next call (FUNC(adjustNext)) fires again; END, a CHECK FIRE
 * (FUNC(abort)) or ADJ_HOLD seconds with no call end the mission. Each call
 * moves QGVAR(holdSeq) on, so a wait that was overtaken does nothing.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The mission's token <NUMBER>
 * 2: What the battery says, "" for nothing <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, 3, "rounds complete, over"] call jmfsb_support_fires_fnc_adjustHold
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_token", -1, [0]], ["_said", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
if (_token isNotEqualTo (_logic getVariable [QGVAR(token), -1])) exitWith {};

_logic setVariable [QGVAR(status), STATUS_ADJUST, true];
private _seq = (_logic getVariable [QGVAR(holdSeq), 0]) + 1;
_logic setVariable [QGVAR(holdSeq), _seq];

if (_said isNotEqualTo "") then {
    [_logic, _said, "normal"] call FUNC(say);
};

[{
    params ["_logic", "_token", "_seq"];
    if (isNull _logic) exitWith {};
    if (_token isNotEqualTo (_logic getVariable [QGVAR(token), -1])) exitWith {};
    if (_seq isNotEqualTo (_logic getVariable [QGVAR(holdSeq), 0])) exitWith {};
    [_logic, _token, "end of mission - no call from the observer, over"] call FUNC(finish);
}, [_logic, _token, _seq], ADJ_HOLD] call CBA_fnc_waitAndExecute;
