#include "script_component.hpp"
/*
 * Author: YonV
 * The contacts in the world, through the AiTR goggles (the hud is the
 * goggles'): a box on a contact someone has in sight, a dashed box at the last
 * known position of one nobody has - with how long it has been lost - and the
 * kind and range under it. Draw3D, this machine only.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_watch_fnc_contactDraw
 *
 * Public: No
 */

if (GVAR(contactList) isEqualTo [] || {!([] call FUNC(goggles))}) exitWith {};

{
    _x params ["_obj", "_kind", "", "", "_pos", "_seen", "_los"];
    if !([["recon", "engineer"] select (_kind isEqualTo "threat")] call FUNC(hudOn)) then {continue};
    private _how = [_x] call FUNC(contactSeen);
    if (_how isEqualTo 0) then {continue};
    private _at = if (_how isEqualTo 2 && {!isNull _obj}) then {_obj modelToWorldVisual [0, 0, 1]} else {(ASLToAGL _pos) vectorAdd [0, 0, 1]};
    private _dist = round (player distance _at);
    if (_dist > SHARE_RANGE) then {continue};
    private _label = format ["%1  %2 M", toUpper ([_obj, _kind] call FUNC(contactName)), _dist];
    if (_how isEqualTo 1) then {_label = _label + format ["  LOST %1", [serverTime - _seen, "MM:SS"] call BIS_fnc_secondsToString]};
    drawIcon3D [[BOX_DASHED, BOX_SOLID] select (_how isEqualTo 2), [COLOUR_GREY, [COLOUR_RED, COLOUR_AMBER] select (_kind isEqualTo "threat")] select (_how isEqualTo 2),
        _at, BOX_SIZE, BOX_SIZE, 0, _label, 2, HUD_TAG_SIZE, HUD_FONT, "center"];
} forEach GVAR(contactList);
