#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: whether a player may make a FLASH call that bumps a ROUTINE one -
 * the RTO (FUNC(isRto), the one RTO test: the RTO console is a player job,
 * user 2026-10-20) or a logged-in admin. The permission table's "C2 / A2G,
 * calls, bump" row (docs/DESIGN_VOICE.md), the same right the tablet's CALLS
 * offers FLASH by.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * May bump <BOOL>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_canFlash
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {false};
if ((admin (owner _unit)) > ADMIN_NONE) exitWith {true};
[_unit] call FUNC(isRto)
