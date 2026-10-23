#include "script_component.hpp"
/*
 * Author: JMSB
 * Rings people: into the player's live (or dialling) call when he has one -
 * + ADD, a group add, the recent list, the walking view's quick add - or as a
 * new call when he has none (CALL). One place, so the tablet and the small
 * devices cannot disagree about who a press rings.
 *
 * A CALL HOLDS CALL_SIZE_MAX PEOPLE. Adds stop when it is full (DESIGN_VOICE.md:
 * "Group adds skip people out of reach and stop at 8"); the voice API refuses
 * and says why for anything else (no route, no slot, busy).
 *
 * Arguments:
 * 0: Units to ring <ARRAY of OBJECTs>
 * 1: Priority for a new call, "ROUTINE" or "FLASH" <STRING> (optional, default "ROUTINE")
 *
 * Return Value:
 * The call rung into, "" when nothing was rung <STRING>
 *
 * Example:
 * [[_unit]] call jmfsb_tacpad_apps_fnc_radioDial
 *
 * Public: No
 */

params [["_units", [], [[]]], ["_priority", CALL_ROUTINE, [""]]];

if (isNil QEFUNC(voice,calls) || {isNil QEFUNC(voice,call)} || {isNil QEFUNC(voice,callAdd)}) exitWith {""};

private _me = call CBA_fnc_currentUnit;
_units = (_units arrayIntersect _units) select {!isNull _x && _x isNotEqualTo _me};
if (_units isEqualTo []) exitWith {""};

private _calls = [] call EFUNC(voice,calls);
private _i = _calls findIf {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};

if (_i < 0) exitWith {
    [_units select [0, CALL_SIZE_MAX - 1], _priority] call EFUNC(voice,call)
};

(_calls select _i) params ["_callId", "", ["_members", [], [[]]], "", "", ["_owner", objNull, [objNull]]];
// ONLY THE OWNER INVITES (user, 2026-10-20) - who started the call. Anyone
// else's add is not sent; the press says why instead.
if (!isNull _owner && _owner isNotEqualTo _me) exitWith {
    ["RADIO", "Only the call's owner can add people - " + name _owner, "normal"] call EFUNC(messaging,notify);
    ""
};
private _room = CALL_SIZE_MAX - count _members;
_units = _units - _members;
if (_room <= 0 || {_units isEqualTo []}) exitWith {""};

[_callId, _units select [0, _room]] call EFUNC(voice,callAdd);
_callId
