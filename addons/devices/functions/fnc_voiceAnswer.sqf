#include "script_component.hpp"
/*
 * Author: JMSB
 * Answers the call that is ringing the player, if one is (user, 2026-10-24:
 * "a pop up on the phone that says press ... 9 on the key pad to answer").
 * The TROOPS IN CONTACT key - numpad 9 by default - calls this first and
 * only files a contact report when nothing was ringing; the device F1 key
 * still answers as well (FUNC(voiceAction)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * A call was answered <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_voiceAnswer
 *
 * Public: Yes
 */

if (isNil QEFUNC(voice,calls) || {isNil QEFUNC(voice,callAccept)}) exitWith {false};

private _ring = ([] call EFUNC(voice,calls)) select {(_x param [1, ""]) isEqualTo CALL_RINGING};
if (_ring isEqualTo []) exitWith {false};

[(_ring select 0) select 0] call EFUNC(voice,callAccept);
true
