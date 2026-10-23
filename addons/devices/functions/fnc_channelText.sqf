#include "script_component.hpp"
/*
 * Author: JMSB
 * The custom-channel gauge every device shows (user, 2026-10-21: "add to all
 * devices a net use % of the 10 custom channels"): "CH 3/10 30%", from
 * jmfsb_voice_fnc_channelUse. Game voice has ten custom channels in all -
 * C2, A2G, each live CALL and anything the mission made - so this is how close
 * the next call is to having none. "" under TFAR / ACRE or before the
 * server's first count.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Gauge text, "" for none <STRING>
 *
 * Example:
 * [] call jmfsb_devices_fnc_channelText
 *
 * Public: No
 */

if (isNil QEFUNC(voice,channelUse)) exitWith {""};
([] call EFUNC(voice,channelUse)) params [["_used", -1, [0]], ["_of", 0, [0]]];
if (_used < 0 || _of <= 0) exitWith {""};
format ["CH %1/%2 %3%4", _used, _of, round (_used / _of * PERCENT), "%"]
