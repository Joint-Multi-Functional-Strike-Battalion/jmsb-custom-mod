#include "script_component.hpp"
/*
 * Author: YonV
 * The SQUAD app's LINK: how well the local player reaches one man on DATA -
 * the net a call needs - as jmfsb_voice_fnc_linkQuality reads it off the
 * player's RF slice (the best link between any node of his and any of the
 * other man's). The RADIO app's CONTACTS reads REACH / NO ROUTE off the same
 * number, so the two screens cannot disagree about who can be called.
 *
 * UNKNOWN IS NOT A CUT (the devices' squad list's rule): an AI has no sets,
 * you are not linked to yourself, and without jmfsb_voice or jmfsb_rf - or
 * before the player holds a node of his own - nothing is known. Each of those
 * answers QUALITY_UNKNOWN rather than 0.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Quality 0..1, or QUALITY_UNKNOWN <NUMBER>
 *
 * Example:
 * private _q = [_unit] call jmfsb_tacpad_apps_fnc_squadLink
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!isPlayer _unit} || {_unit isEqualTo player}) exitWith {QUALITY_UNKNOWN};
if (isNil QEFUNC(voice,linkQuality) || {isNil QEFUNC(rf,link)}) exitWith {QUALITY_UNKNOWN};
if (([] call FUNC(radioRfNodes)) isEqualTo []) exitWith {QUALITY_UNKNOWN};

[_unit, RADIO_NET_DATA] call EFUNC(voice,linkQuality)
