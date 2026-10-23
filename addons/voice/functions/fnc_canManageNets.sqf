#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether a man may make, people and remove RTO nets, as a client can tell:
 * he holds the RTO job (FUNC(isRto)) or jmfsb_common has flagged his unit a
 * logged-in admin. This decides what the RADIO app draws and what
 * FUNC(netAdd) sends; the server re-checks every request with
 * FUNC(canFlash), the same right a FLASH call needs.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * May manage <BOOL>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_canManageNets
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};

[_unit] call FUNC(isRto) || {(_unit getVariable [ADMIN_FLAG, false]) isEqualTo true}
