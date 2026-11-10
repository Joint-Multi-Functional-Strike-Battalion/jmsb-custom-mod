#include "script_component.hpp"
/*
 * Author: YonV
 * May this player pull the plug on this jammer by hand? A live jammer, and -
 * unless the setting says anyone - an engineer, an explosives specialist
 * (the unit traits ACE and the mission set) or an ISR operator.
 *
 * Arguments:
 * 0: The terminal <OBJECT>
 * 1: The player <OBJECT>
 *
 * Return Value:
 * Allowed <BOOL>
 *
 * Example:
 * [cursorObject, player] call jmfsb_jamming_fnc_canDisable
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit}) exitWith {false};
if !([_obj] call FUNC(isLiveJammer)) exitWith {false};
if (!GVAR(disableNeedsEngineer)) exitWith {true};

// ISR operators too (user, 2026-10-24: "isr also") - the same flag hacking uses.
(_unit getUnitTrait TRAIT_ENGINEER) || {_unit getUnitTrait TRAIT_EOD} || {[_unit] call EFUNC(common,isISR)}
