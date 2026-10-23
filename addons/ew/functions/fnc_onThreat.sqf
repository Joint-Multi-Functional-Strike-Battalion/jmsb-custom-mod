#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: a threat warning from the server (FUNC(warn)) on the notification
 * rail - kind as the title, the detail and what to do as the line. The
 * OVERVIEW tab keeps the recent ones from the slice.
 *
 * Arguments:
 * 0: Kind <STRING>
 * 1: Detail <STRING>
 * 2: What to do <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["DF ON YOU", "EAST CUT ON YOUR VHF SET", "MOVE"] call jmfsb_ew_fnc_onThreat
 *
 * Public: No
 */

params [["_kind", "", [""]], ["_detail", "", [""]], ["_advice", "", [""]]];

if (!hasInterface) exitWith {};

private _text = [_detail, format ["%1 - %2", _detail, _advice]] select (_advice isNotEqualTo "");
[format ["EW: %1", _kind], _text, THREAT_COLOUR] call EFUNC(notify,notify);
