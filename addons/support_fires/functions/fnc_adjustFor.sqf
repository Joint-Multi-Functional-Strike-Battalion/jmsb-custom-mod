#include "script_component.hpp"
/*
 * Author: YonV
 * ADJUST FIRE (TAC//SUPPORT v2 build step 6, 2026-11-01): whether an order is
 * the observer's next call on the mission this battery holds for him, an order
 * of its own, or refused - the one answer FUNC(check) (on the requester's
 * machine and again on the server) and FUNC(request) read.
 *
 * The call is the order's SLOT_ADJUST (ADJ_*). A battery fired with ADJ_ROUND
 * or ADJ_FFE HOLDS once its salvo is down (FUNC(adjustHold)) for the player
 * who ordered it, by Steam id (QGVAR(holdBy), public). Then:
 *
 *   ADJ_NONE                     an order of its own - the battery is busy
 *   another player               refused: it is adjusting for someone else
 *   ADJ_ROUND / ADJ_FFE, held    the held mission's next salvo - only while
 *                                the battery waits (STATUS_ADJUST), not while
 *                                its last salvo is still in the air
 *   ADJ_END, held                the held mission ends, any time
 *   ADJ_END, nothing held        refused: no mission to end
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The requester <OBJECT>
 * 2: The support page's parameter array <ARRAY>
 *
 * Return Value:
 * 0: ADJ_STATE_REFUSED, ADJ_STATE_NEW or ADJ_STATE_HELD <NUMBER>
 * 1: Why it is refused, "" otherwise <STRING>
 * 2: The call, ADJ_* <NUMBER>
 *
 * Example:
 * [_logic, player, _prm] call jmfsb_support_fires_fnc_adjustFor
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_unit", objNull, [objNull]], ["_prm", [], [[]]]];

private _mode = _prm param [SLOT_ADJUST, ADJ_NONE];
if (isNil "_mode" || {!(_mode isEqualType 0)}) then {_mode = ADJ_NONE};
_mode = (round _mode) max ADJ_NONE min ADJ_END;

if (isNull _logic || _mode isEqualTo ADJ_NONE) exitWith {[ADJ_STATE_NEW, "", _mode]};

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _by = _logic getVariable [QGVAR(holdBy), ""];

switch (true) do {
    case (_by isEqualTo "" && _mode isEqualTo ADJ_END): {
        [ADJ_STATE_REFUSED, format ["%1 is not adjusting", _callsign], _mode]
    };
    case (_by isEqualTo ""): {[ADJ_STATE_NEW, "", _mode]};
    case (_by isNotEqualTo getPlayerUID _unit): {
        [ADJ_STATE_REFUSED, format ["%1 is adjusting for another observer", _callsign], _mode]
    };
    case (_mode isNotEqualTo ADJ_END && (_logic getVariable [QGVAR(status), STATUS_IDLE]) isNotEqualTo STATUS_ADJUST): {
        [ADJ_STATE_REFUSED, format ["%1: rounds in the air - wait for the splash", _callsign], _mode]
    };
    default {[ADJ_STATE_HELD, "", _mode]};
}
