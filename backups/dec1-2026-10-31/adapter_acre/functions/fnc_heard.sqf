#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, on ACRE's acre_remoteStartedSpeaking / acre_remoteStoppedSpeaking:
 * another player started or stopped talking. A radio transmission is kept,
 * with the net of the radio he talks on (fnc_radioNet), until he stops;
 * direct speech is not radio and is dropped.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 * 1: On a radio, now talking (false: stopped, or not on a radio) <BOOL>
 * 2: His radio id <STRING> (default: "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, true, "ACRE_PRC152_ID_3"] call jmfsb_adapter_acre_fnc_heard
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_on", false, [false]], ["_radioId", "", [""]]];

if (isNull _unit || {_unit isEqualTo player}) exitWith {};
private _uid = getPlayerUID _unit;
private _net = if (_on) then {([_radioId] call FUNC(radioNet)) select 0} else {""};
if (_net isNotEqualTo "") exitWith {GVAR(heard) set [_uid, [_unit, _net]]};
GVAR(heard) deleteAt _uid;
