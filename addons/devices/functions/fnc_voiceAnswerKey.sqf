#include "script_component.hpp"
/*
 * Author: JMSB
 * The answer key - numpad * in the numpad standard (user, 2026-10-30): in the
 * quick-add list, adds the one under the cursor; else answers the call that
 * is ringing (FUNC(voiceAnswer)); with nothing ringing, hangs up the call he
 * is in or is dialling.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Acted <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_voiceAnswerKey
 *
 * Public: No
 */

// In the quick-add list (F1 during a call) it adds the one under the cursor.
if (GVAR(quickOpen)) exitWith {[BUTTON_CALL_ACCEPT] call FUNC(voiceAction)};
if ([] call FUNC(voiceAnswer)) exitWith {true};
if (isNil QEFUNC(voice,calls) || {isNil QEFUNC(voice,hangUp)}) exitWith {false};

private _live = ([] call EFUNC(voice,calls)) select {(_x param [1, ""]) in [CALL_LIVE, CALL_OUTGOING]};
if (_live isEqualTo []) exitWith {false};

[(_live select 0) select 0] call EFUNC(voice,hangUp);
true
