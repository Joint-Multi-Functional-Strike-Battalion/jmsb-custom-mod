#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether the local player could hear a speaker soon, so his audio is
 * received at all (the extension's auto-subscribe is off: nobody is
 * downloaded and decoded unless asked - not the other side's men, not a net
 * he is not on). True while they share a net by the server's roster
 * (jmfsb_voice_fnc_rosterNets against the listener's own nets), sit in one
 * vehicle, or stand within the local voice range times
 * SUBSCRIBE_RANGE_FACTOR - a margin, so a man walking up is received before
 * he is in earshot. Never while the listener is dead.
 *
 * Arguments:
 * 0: Speaker <OBJECT>
 *
 * Return Value:
 * Could hear him <BOOL>
 *
 * Example:
 * [_unit] call jmfsb_adapter_livekit_fnc_canHear
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {isNull player} || {!alive player}) exitWith {false};

private _vehicle = objectParent player;
if (!isNull _vehicle && {_vehicle isEqualTo objectParent _unit}) exitWith {true};
if ((player distance _unit) < (GVAR(localRange) max LOCAL_RANGE_MIN) * SUBSCRIBE_RANGE_FACTOR) exitWith {true};

private _mine = (missionNamespace getVariable [QEGVAR(voice,myNets), []]) apply {_x select 0};
(([_unit] call EFUNC(voice,rosterNets)) findIf {_x in _mine}) >= 0
