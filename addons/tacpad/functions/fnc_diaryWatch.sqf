#include "script_component.hpp"
/*
 * Author: JMSB
 * Hides every panel while the map's diary or briefing pane is open, and brings
 * them back when it closes.
 *
 * The diary is the addon list, the briefing, the tasks and the credits - the
 * pages behind the tabs at the top left of the map. It opens over the same
 * screen the tacpad lives on, and a squad rail sitting on top of your addon
 * list is worse than no squad rail.
 *
 * HIDDEN, NOT MOVED. The diary is transient: reserving that much of the screen
 * permanently would ruin the layout for the ninety-odd percent of the time it
 * is shut, and shoving four panels somewhere else and back again would leave
 * the player hunting for them.
 *
 * The pane is found by asking the display for its diary controls rather than by
 * naming an idc - the tab list and the page body are both standard map controls
 * and either being visible means the player is reading, not navigating.
 *
 * Arguments (CBA per-frame handler):
 * 0: Arguments <ARRAY> - unused
 * 1: Handle <NUMBER> - unused
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params ["", ""];

private _display = HOST_DISPLAY;
if (isNull _display) exitWith {};

// CA_ContentBackgroundd, idc 1023 on RscDisplayMainMap, is the diary PAGE
// BODY - shown only while a page is actually open, so it is the one control
// that means "the player is reading, not navigating". Read out of the game's
// own ui_f config rather than guessed.
//
// It WAS guessed once, at 1001/1002, and that hid every panel permanently. A
// missing control is treated as closed, so a wrong idc can now only ever fail
// towards showing the panels.
private _ctrl = _display displayCtrl 1023;
private _open = !isNull _ctrl && {ctrlShown _ctrl};

if (_open isEqualTo GVAR(diaryOpen)) exitWith {};
GVAR(diaryOpen) = _open;

// ctrlShow false is enough on its own: a hidden control receives no mouse
// events, so a panel behind the diary cannot swallow a click meant for the page.
// The suite used to carry a mute flag as well, for a dispatcher that read
// rectangles rather than controls and could not tell a hidden panel from a
// shown one.
{
    _y params ["_group"];
    if (!isNull _group) then {
        _group ctrlShow !_open;
    };
} forEach GVAR(open);
