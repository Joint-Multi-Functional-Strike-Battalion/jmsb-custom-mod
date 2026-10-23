#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether the player may add people now: with no live (or dialling) call any
 * press starts a new one, which he owns; in a call only its OWNER - who started
 * it, or who it passed to when he left - invites (user, 2026-10-20: "its not
 * the rto inviting folks its the channel owner so who started the call").
 * The voice addon refuses anyone else's add; this keeps the screens from
 * offering a press that would only be refused.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * May add <BOOL>
 *
 * Example:
 * [] call jmfsb_tacpad_apps_fnc_radioCanAdd
 *
 * Public: Yes
 */

if (isNil QEFUNC(voice,calls)) exitWith {false};

private _calls = [] call EFUNC(voice,calls);
private _i = _calls findIf {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};
if (_i < 0) exitWith {true};

private _owner = (_calls select _i) param [5, objNull];
isNull _owner || {_owner isEqualTo (call CBA_fnc_currentUnit)}
