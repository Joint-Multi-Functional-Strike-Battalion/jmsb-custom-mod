#include "script_component.hpp"
/*
 * Author: JMSB
 * The tablet's who-is-talking chip (docs/DESIGN_TABLET.md, "Map area": top,
 * right of the rail): TX or VOX, the member's number and name - the same chip
 * the walking view draws, from the same function (FUNC(overlayTalker)).
 *
 * Shown only while somebody is talking and no app page is over the map area;
 * redrawn only when what it says has changed.
 *
 * Arguments:
 * 0: The chip's body <CONTROL>
 * 1: The rows' last drawn keys <HASHMAP>
 *
 * Return Value:
 * Redrawn <BOOL>
 *
 * Example:
 * [_body, _keys] call jmfsb_devices_fnc_tabletTalk
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_keys", createHashMap, [createHashMap]]];
if (isNull _body) exitWith {false};

private _chip = [] call FUNC(overlayTalker);
if ((uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isNotEqualTo "") then {
    _chip = "";
};

if (_chip isEqualTo (_keys getOrDefault ["talk", ""])) exitWith {false};
_keys set ["talk", _chip];

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

(ctrlParentControlsGroup _body) ctrlShow (_chip isNotEqualTo "");
if (_chip isEqualTo "") exitWith {true};

(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = _w * TABLET_GAP / (TABLET_DESIGN_W * (TABLET_TALK select 2));

// drawText sizes and centres the line; the chip's own colours are structured
// text, so the line is set again with them once it is placed.
private _ctrl = [_body, [_pad, 0, _w - 2 * _pad, _h], "", COLOUR_TEXT, TABLET_TEXT_TALK, true] call EFUNC(tacpad,drawText);
_ctrl ctrlSetStructuredText parseText format ["<t font='RobotoCondensedBold' size='%1'>%2</t>", TABLET_TEXT_TALK, _chip];

true
