#include "script_component.hpp"
/*
 * Author: JMSB
 * Lays the walking view out for one device on one edge: the frame, the
 * ground, the status cells, the map, the squad list, the talking
 * chip and the call strip, from the screen rectangle FUNC(overlayLayout)
 * answers and the rows FUNC(overlayRows) cuts it into. The net cells are
 * placed by FUNC(overlayDraw), because how many there are changes with the
 * radio in hand.
 *
 * Run once per placement, not per tick - FUNC(overlayTick) calls it only
 * when the device, the edge, the size, the opacity or the colour scheme has
 * changed.
 *
 * OPACITY is the player's (GVAR(overlayOpacity)): every control's fade is
 * one minus it, so the whole device - frame included - goes see-through
 * together.
 *
 * Arguments:
 * 0: The layer's display <DISPLAY>
 * 1: Device class in CfgJmfsbDevices <STRING>
 * 2: Edge for a side device - "left" or "right" <STRING>
 *
 * Return Value:
 * Placed <BOOL>
 *
 * Example:
 * [_display, "phone", ""] call jmfsb_devices_fnc_overlayPlace
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_device", "phone", [""]], ["_edge", "right", [""]]];

if (isNull _display) exitWith {false};

([_device, _edge] call FUNC(overlayLayout)) params ["_framePos", "_screenPos", "_texture"];
if (_texture isEqualTo "") exitWith {false};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink"];
private _rows = [_screenPos] call FUNC(overlayRows);
private _textH = _rows get "textH";

private _frame = _display displayCtrl IDC_OVERLAY_FRAME;
_frame ctrlSetText _texture;
_frame ctrlSetPosition _framePos;

// The ground is the scheme's, fully opaque: the device is a thing in the
// hand, not a window over the world.
private _groundCtrl = _display displayCtrl IDC_OVERLAY_GROUND;
_groundCtrl ctrlSetPosition _screenPos;
_groundCtrl ctrlSetBackgroundColor [_ground # 0, _ground # 1, _ground # 2, 1];

private _call = _display displayCtrl IDC_OVERLAY_CALL;
_call ctrlSetPosition (_rows get "call");
_call ctrlSetFontHeight _textH;
_call ctrlSetBackgroundColor COLOUR_BAR_SCRIM;

{
    private _cell = _display displayCtrl IDC_OVERLAY_CELL(_forEachIndex);
    _cell ctrlSetPosition _x;
    _cell ctrlSetFontHeight (_textH min ((_x select 3) * OVERLAY_CELL_TEXT_FIT));
} forEach (_rows get "status");

private _talk = _display displayCtrl IDC_OVERLAY_TALK;
_talk ctrlSetPosition (_rows get "talk");
_talk ctrlSetFontHeight _textH;
_talk ctrlSetBackgroundColor COLOUR_BAR_SCRIM;

// The squad list: one column over the phone's map, two under the side
// devices'. Its height on the phone follows its length (FUNC(overlayDraw)).
private _squadRects = _rows get "squad";
{
    private _ctrl = _display displayCtrl _x;
    if (_forEachIndex < count _squadRects) then {
        _ctrl ctrlSetPosition (_squadRects select _forEachIndex);
        _ctrl ctrlSetFontHeight _textH;
        _ctrl ctrlShow true;
    } else {
        _ctrl ctrlShow false;
    };
} forEach [IDC_OVERLAY_SQUAD, IDC_OVERLAY_SQUAD2];

private _fade = 1 - (GVAR(overlayOpacity) max 0 min 1);
{
    _x ctrlSetFade _fade;
    _x ctrlCommit 0;
} forEach (allControls _display);

// THE MAP IS MOVED WITH ctrlMapSetPosition, AFTER THE COMMIT. It is declared
// 0 x 0 at the top left (overlay.hpp), and a map moved with ctrlSetPosition
// keeps that declared viewport for its world transform - so ctrlMapAnimAdd
// centred the player on the old origin, not on the screen hole, and the phone
// showed the squad's marks with the player off the edge (user screenshot,
// 2026-10-20). ctrlMapSetPosition moves the control and its transform together.
private _map = _display displayCtrl IDC_OVERLAY_MAP;
_map ctrlMapSetPosition (_rows get "map");

// Open on the player at the player's zoom; FUNC(overlayFollow) keeps it there.
[_map] call FUNC(overlayFollow);

true
