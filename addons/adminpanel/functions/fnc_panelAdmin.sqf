#include "script_component.hpp"
/*
 * Author: JMSB
 * The ADMIN button, between SETTINGS and HIDE ALL on the map screen.
 *
 * IT IS ONLY THERE FOR ADMINS. Not disabled for everyone else - absent. The
 * panel is registered with a condition on FUNC(isAdmin) (see XEH_preInit), which
 * the shell checks every time the map opens, so a player who is not on the
 * mission's list never sees a button whose only possible answer to them is no.
 * A grant mid-mission takes effect the next time they open the map.
 *
 * WHY A BUTTON AND NOT ONLY A KEYBIND. Pause/Break opens the console and always
 * has, and the people who use it every session know that. Everyone else does not
 * read keybind lists - the reason the tacpad puts its settings under the reader
 * rather than in Options is the same reason this is on the map: the screen you
 * are looking at when you decide you need it.
 *
 * NO TITLE BAR. Registered chromeless, like the two strips either side of it, so
 * the three read as one row of buttons rather than three little windows.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel id <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_id", "", [""]]];

if (isNull _body) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _w = (ctrlPosition _body) # 2;
// HOST UNITS, as the TOOLS, SETTINGS and HIDE strips beside it: on a tablet
// the host is the map area, and FUNC(fit) multiplies by HOST_H.
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _labelSize = TEXT_BODY;
private _cellH = ([_labelSize] call EFUNC(tacpad,textH)) + 2 * _padY;

private _cellY = _padY * 1.5;
private _cellX = _pad;
private _cellW = _w - _cellX - _pad;

// OUTLINED IN THE ACCENT, not filled with it. The suite gives one loud control
// per screen and the map screen's is TROOPS IN CONTACT; an admin console is a
// tool, not an alarm. The accent edge is enough to say this button is not the
// same kind of thing as the two beside it.
[_body, [_cellX, _cellY, _cellW, _cellH], _accent, RULE_THICK] call EFUNC(tacpad,drawFrame);

[
    _body, [_cellX + _pad, _cellY, _cellW - 2 * _pad, _cellH],
    "ADMIN", _accent, _labelSize, true, "center"
] call EFUNC(tacpad,drawText);

// THE WHOLE STRIP IS THE BUTTON, minus the gutter. Hunting for the live part of
// a bar this size is not an interaction.
[_body, [_cellX, 0, _w - _cellX, _cellH + 3 * _padY], {
    // NEXT FRAME, ALL OF IT. Closing the map deletes every panel on it -
    // including this button - and a handler that pulls its own control out from
    // under itself is the one reliable way to lose the press.
    //
    // The map closes because the console is a full-screen dialog: leaving the
    // map open behind it means the map's own Escape fights the dialog's, and
    // closing the console drops the player onto a map they did not ask to still
    // be looking at.
    //
    // ON A TABLET THERE IS NO MAP TO CLOSE: the console opens over the device,
    // fitted to its screen (FUNC(fitHost)), and ESC drops back onto it.
    {
        if (HOST_NATIVE) then {openMap false};
        [] call FUNC(open);
    } call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

[_id, 0, (_cellH + 3 * _padY) / HOST_H] call EFUNC(tacpad,fit);
