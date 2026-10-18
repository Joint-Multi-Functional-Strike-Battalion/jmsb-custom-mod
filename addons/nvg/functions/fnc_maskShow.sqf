#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Puts the tube mask up on the mission display, or changes its picture if it is
 * up already. Placed the way ACE places its own border at the default view.
 *
 * ON DISPLAY 46, NOT A TITLE LAYER: the mission display dies with the mission,
 * so the mask cannot be left behind on the main menu.
 *
 * Arguments:
 * 0: Texture <STRING>
 * 1: Eye cups <BOOL>
 *
 * Return Value:
 * Shown <BOOL>
 *
 * Example:
 * [MASK_DEFAULT, false] call jmfsb_nvg_fnc_maskShow
 *
 * Public: No
 */

params [["_texture", MASK_DEFAULT, [""]], ["_eyeCups", false, [false]]];

private _ctrl = uiNamespace getVariable [QGVAR(mask), controlNull];

if (isNull _ctrl) then {
    private _display = findDisplay IDD_MISSION;
    if (isNull _display) exitWith {};

    _ctrl = _display ctrlCreate [QGVAR(mask), -1];
    uiNamespace setVariable [QGVAR(mask), _ctrl];
};
if (isNull _ctrl) exitWith {false};

// ACE: BORDER_SIZE screen heights tall, 3:4 of that wide, centred; scaled about
// the centre, but never narrower than the screen (ultra-wide monitors).
private _h = MASK_BORDER_SIZE * safeZoneH;
private _w = MASK_ASPECT * _h;
private _scale = MASK_ZOOM max (safeZoneW / _w);
_w = _w * _scale;
_h = _h * _scale;

_ctrl ctrlSetText _texture;
_ctrl ctrlSetFade ([MASK_FADE_NO_EYECUPS, MASK_FADE_EYECUPS] select _eyeCups);
_ctrl ctrlSetPosition [SCREEN_CENTRE - _w / 2, SCREEN_CENTRE - _h / 2, _w, _h];
_ctrl ctrlCommit 0;

true
