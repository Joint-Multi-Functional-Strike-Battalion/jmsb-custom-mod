#include "script_component.hpp"
/*
 * Author: JMSB
 * Is this object a jammer that is still jamming - a terminal that holds a
 * zone in the published registry and has not been disabled or hacked? The
 * ACE actions on a terminal ask this before they offer anything; a dead
 * site, a prop or a terminal somebody has already silenced gets no menu.
 *
 * Arguments:
 * 0: The object <OBJECT>
 *
 * Return Value:
 * Live jammer <BOOL>
 *
 * Example:
 * [cursorObject] call jmfsb_jamming_fnc_isLiveJammer
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj || {!alive _obj}) exitWith {false};
if (_obj getVariable [QGVAR(disabled), false]) exitWith {false};
if (_obj getVariable [QEGVAR(hacking,hacked), false]) exitWith {false};

private _zones = missionNamespace getVariable [QGVAR(jammers), []];
(_zones findIf {(_x param [ZONE_OBJ, objNull]) isEqualTo _obj}) >= 0
