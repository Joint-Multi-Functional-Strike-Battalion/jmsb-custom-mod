#include "script_component.hpp"
/*
 * Author: YonV
 * An @ mention of a support asset on the CC line, picked from the @ list or
 * typed in full (user, 2026-11-01: "want to use an @[unit] to enable ai
 * support units"; "need to have the proper template also for the type of
 * unit").
 *
 * THE ASSET IS ADDRESSED. Its own box, "B:SUPPORT:<assetId>", goes on the TO
 * line beside what is there - the box the server answers as the asset, so the
 * AI gets the thread and acts on it - and the TO line reads its call sign
 * (EFUNC(support,boxName)). The @ name comes off the CC line.
 *
 * ITS CARD IS OPENED, the one its row names (EFUNC(support,mailboxes)): CAS
 * `cas` (a player pilot too - one CAS card, 2026-11-02), a fixed-wing not on
 * station `onstation`, artillery `callforfire` (CFF GRID; CFF POLAR and SHIFT
 * written first are kept - it takes all three), transport `hlz` (LIFT
 * REQUEST; an EXTRACTION written first is kept), logistics `resupply`, QRF
 * `qrf`. Several mentioned at once:
 * the last one's. A card the deck does not carry keeps the card being written,
 * and the status line beside SEND says which one is missing. A CARD THE ASSET
 * TAKES IS KEPT (user, 2026-11-02: "on station is not a fire mission its just
 * an order to get in the air"): REQUEST ON STATION written, then @HAWK, went as
 * HAWK's `cas` card - a strike, refused DANGER CLOSE. The row's field 10 lists
 * what it answers now; the card being written stays when it is one. What was typed
 * goes across (FUNC(composeMentionSwitch)); what would not, is asked about
 * first - SWITCH or KEEP (FUNC(composeMentionAsk)) - and nothing is dropped
 * without that press.
 *
 * Arguments:
 * 0: Asset rows, as FUNC(composeToSupport) gives them <ARRAY>
 * 1: The CC line without them <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[_row], "@HQ, "] call jmfsb_tacpad_fnc_composeMention
 *
 * Public: No
 */

params [["_rows", [], [[]]], ["_cc", "", [""]]];

if (_rows isEqualTo []) exitWith {};

// Harvest first, like every press on this pane - then the CC line as it is
// without the names just taken off it.
[] call FUNC(composeHarvest);
GVAR(composeCc) = _cc;

private _to = ((GVAR(composeTo) splitString ",") apply {trim _x}) select {_x isNotEqualTo ""};
{
    _to pushBackUnique (_x select 0);
} forEach _rows;
GVAR(composeTo) = _to joinString ", ";

(_rows select -1) params ["", ["_callsign", "", [""]], "", "", "", "", "", "", ["_card", "", [""]]];
private _takes = (_rows select -1) param [MENTION_ROW_CARDS, [], [[]]];
if (GVAR(composeTemplate) in _takes) then {_card = GVAR(composeTemplate)};

GVAR(composeNote) = "";
GVAR(composeMentionAsk) = [];
if (_card isNotEqualTo "" && _card isNotEqualTo GVAR(composeTemplate)) then {
    if (count ([_card] call EFUNC(messaging,template)) isEqualTo 0) exitWith {
        GVAR(composeNote) = format [MENTION_NO_CARD, toUpper _card];
    };
    ([_card, false] call FUNC(composeMentionSwitch)) params ["_switched", "_lost"];
    if (!_switched) then {
        GVAR(composeMentionAsk) = [_card, _callsign, _lost];
    };
};

// NEXT FRAME - a press handler or the CC line's own KeyUp is running - and
// the keyboard back on the CC line, where the next name is typed.
{
    [] call FUNC(readerDraw);
    {
        if (_x getVariable [QGVAR(ccField), false]) exitWith {ctrlSetFocus _x};
    } forEach (allControls (uiNamespace getVariable [QGVAR(reader), displayNull]));
} call CBA_fnc_execNextFrame;
