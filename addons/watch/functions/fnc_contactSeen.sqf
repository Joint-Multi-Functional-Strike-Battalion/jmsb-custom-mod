#include "script_component.hpp"
/*
 * Author: YonV
 * Whether this player sees a contact, and how (design recon.visibility):
 *
 *     line of sight (any friendly has it)   solid - every friendly within
 *                                            SHARE_RANGE of the contact
 *     no line of sight                       dashed, at the last known position -
 *                                            the spotter's group only, or every
 *                                            friendly in range while it is shared
 *
 * Arguments:
 * 0: A GVAR(contactList) entry <ARRAY>
 *
 * Return Value:
 * 0 not seen, 1 dashed, 2 solid <NUMBER>
 *
 * Example:
 * [_entry] call jmfsb_watch_fnc_contactSeen
 *
 * Public: No
 */

params [["_entry", [], [[]]]];

_entry params [["_obj", objNull], "", ["_side", sideUnknown], ["_group", grpNull], ["_pos", [0, 0, 0]], "", ["_los", false], ["_shared", -1]];
if (side group player isNotEqualTo _side) exitWith {0};
private _near = (player distance (ASLToAGL _pos)) <= SHARE_RANGE;
if (_los && _near) exitWith {2};
if (group player isEqualTo _group || {_near && {serverTime < _shared}}) exitWith {1};
0
