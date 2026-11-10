#include "script_component.hpp"
/*
 * Author: YonV
 * A man's health in a word and a colour, for the team lead's panel and the
 * squad view: DEAD grey, DOWN red (unconscious or cardiac arrest), BLEEDING
 * amber, HURT amber, OK green. ACE medical's when loaded, else the engine's
 * damage.
 *
 * Arguments:
 * 0: The man <OBJECT>
 *
 * Return Value:
 * [word, colour] <ARRAY>
 *
 * Example:
 * [_unit] call jmfsb_watch_fnc_health
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!alive _unit) exitWith {["DEAD", COLOUR_GREY]};
if (_unit getVariable ["ACE_isUnconscious", false] || {_unit getVariable ["ace_medical_inCardiacArrest", false]}) exitWith {["DOWN", COLOUR_RED]};
if ((_unit getVariable ["ace_medical_woundBleeding", 0]) > 0) exitWith {["BLEEDING", COLOUR_AMBER]};
if (damage _unit > HURT_DAMAGE || {(_unit getVariable ["ace_medical_pain", 0]) > PAIN_HURT}) exitWith {["HURT", COLOUR_AMBER]};
["OK", COLOUR_GREEN]
