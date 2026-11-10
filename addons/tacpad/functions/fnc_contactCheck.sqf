#include "script_component.hpp"
/*
 * Author: YonV
 * The quiet check on the watched TIC (FUNC(contactArm)), queued by
 * FUNC(contactAgain). Contact within CONTACT_QUIET_S: queued again for the
 * rest of the quiet time from the last sign. Quiet that long: CONTACT OVER?
 * SEND SITREP, once - upper right, and as the kicker over SEND SITREP on the
 * TIC thread's row (FUNC(readerQuickTiles)), where one press opens the SITREP
 * (FUNC(sitrepAfterTic)). It stays until contact resumes (it is armed again),
 * he sends a SITREP or the thread closes (FUNC(contactDrop)).
 *
 * A thread no longer in his index - swept, or a mission's msg.clear - ends
 * the watch, as a closed one does.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_contactCheck
 *
 * Public: No
 */

GVAR(contactPending) = false;

private _threadId = GVAR(contactThread);
if (_threadId isEqualTo "") exitWith {};

private _rows = missionNamespace getVariable [QEGVAR(messaging,index), []];
private _rowAt = _rows findIf {
    _x isEqualType createHashMap && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
};
if (_rowAt < 0) exitWith {[] call FUNC(contactDrop)};
private _row = _rows select _rowAt;
if ((_row getOrDefault ["status", ""]) in CONTACT_CLOSED) exitWith {[] call FUNC(contactDrop)};

private _left = CONTACT_QUIET_S - (CBA_missionTime - GVAR(contactLast));
if (_left > 0) exitWith {
    GVAR(contactPending) = true;
    [{[] call FUNC(contactCheck)}, [], _left] call CBA_fnc_waitAndExecute;
};

if (GVAR(contactPrompted)) exitWith {};
GVAR(contactPrompted) = true;

private _anchor = _row getOrDefault ["anchorPos", []];
if !(_anchor isEqualType []) then {_anchor = []};
private _grid = "";
if (count _anchor >= 2) then {_grid = mapGridPosition _anchor};
[CONTACT_PROMPT, format [CONTACT_PROMPT_TEXT, _grid], "high"] call EFUNC(messaging,notify);

if (!isNull (uiNamespace getVariable [QGVAR(reader), displayNull])) then {
    [QGVAR(readerDraw), {[] call FUNC(readerDraw)}] call FUNC(nextFrameOnce);
};
