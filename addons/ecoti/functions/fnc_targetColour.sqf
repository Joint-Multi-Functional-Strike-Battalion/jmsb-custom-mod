#include "script_component.hpp"
/*
 * Author: JMSB
 * The colour a target is drawn in (user, 2026-10-17):
 *
 *   blue    your own faction                        (Own faction colour)
 *   green   another faction on a side friendly to yours (Same side colour)
 *   red     hostile to your side, or a civilian with a weapon (Armed colour)
 *   white   an unarmed civilian
 *   yellow  unknown - an empty vehicle, an animal, anyone of no side
 *
 * A vehicle is what its commander is (the first live crewman if he is not
 * aboard), and red if any civilian aboard is armed.
 *
 * Arguments:
 * 0: Man, vehicle or animal <OBJECT>
 *
 * Return Value:
 * Colour, RGB <ARRAY>
 *
 * Example:
 * [cursorTarget] call jmfsb_ecoti_fnc_targetColour
 *
 * Public: No
 */

params [["_target", objNull, [objNull]]];

private _crew = if (_target isKindOf "CAManBase") then {[_target]} else {(crew _target) select {alive _x}};
if (_crew isEqualTo []) exitWith {UNKNOWN_RGB};

private _lead = effectiveCommander _target;
if !(_lead in _crew) then {_lead = _crew select 0};

private _side = side group _lead;
if (_side == civilian) exitWith {
    private _armed = _crew findIf {
        primaryWeapon _x != "" || {handgunWeapon _x != ""} || {secondaryWeapon _x != ""}
    } >= 0;
    [CIVILIAN_RGB, GVAR(colorEnemy)] select _armed
};
if (_side in UNKNOWN_SIDES) exitWith {UNKNOWN_RGB};
if (((side group player) getFriend _side) < FRIENDLY_MIN) exitWith {GVAR(colorEnemy)};
if (faction _lead == faction player) exitWith {GVAR(colorPlayer)};

GVAR(colorFriendly)
