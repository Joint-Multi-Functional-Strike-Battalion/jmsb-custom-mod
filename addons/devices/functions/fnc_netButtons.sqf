#include "script_component.hpp"
/*
 * Author: YonV
 * Puts the player's nets on the twelve net buttons - three pages of four,
 * page 1 the QUICK ACCESS page (user, 2026-11-07: "4 quick access and then 2
 * pages of 4 additional") - and says which page the rows show.
 *
 * WHAT GOES WHERE. The player's choice is GVAR(netButtons) (set on the
 * tablet's RADIO app, NETS > BUTTONS; FUNC(netAssign)): a net id per button,
 * NET_BUTTON_AUTO for an AUTO button.
 * - A net assigned to a button sits on it while he is on that net - on every
 *   button it is assigned to, so one net can be on more than one page.
 * - Every other net he is on fills the AUTO buttons in the voice API's order,
 *   quick buttons first.
 * - A NET ASSIGNED TO A BUTTON HE IS NOT ON LEAVES IT EMPTY - a dim cell - so
 *   the nets he set keep their keys. Only when the AUTO buttons are all taken
 *   do the nets left over fill those empty buttons, so no net he is on is
 *   ever off the row.
 *
 * THE PAGE SHOWN is the one he turned to (GVAR(netPage), FUNC(netPageStep))
 * while it has a net on it; a page with no nets is skipped - the nearest one
 * below it with nets is shown, else the first that has any.
 *
 * A RINGING CALL IS ALWAYS ON THE PAGE SHOWN: its RING cell takes the page's
 * first empty cell or, with none, its last cell, standing over that net for
 * as long as it rings.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [buttons - NET_BUTTONS FUNC(netEntries) entries, [] for an empty button,
 * page shown (0-based), the pages with something on them (0-based, in order)]
 * <ARRAY>
 *
 * Example:
 * ([] call jmfsb_devices_fnc_netButtons) params ["_buttons", "_page", "_pages"]
 *
 * Public: No
 */

private _entries = [] call FUNC(netEntries);
private _ring = _entries select {(_x select 7) isEqualTo NET_KIND_RING};
private _nets = _entries select {(_x select 7) isNotEqualTo NET_KIND_RING};

private _assigned = GVAR(netButtons);
private _buttons = _assigned apply {[]};
private _rest = [];
{
    private _entry = _x;
    private _netId = _entry select 3;
    private _placed = false;
    if (_netId isNotEqualTo NET_BUTTON_AUTO) then {
        {
            if (_x isEqualTo _netId) then {
                _buttons set [_forEachIndex, _entry];
                _placed = true;
            };
        } forEach _assigned;
    };
    if (!_placed) then {_rest pushBack _entry};
} forEach _nets;

// The AUTO buttons, in order.
{
    if (_rest isEqualTo []) exitWith {};
    if (_x isEqualTo NET_BUTTON_AUTO) then {_buttons set [_forEachIndex, _rest deleteAt 0]};
} forEach _assigned;
// More nets than AUTO buttons: the rest go on the buttons left empty.
{
    if (_rest isEqualTo []) exitWith {};
    if (_x isEqualTo []) then {_buttons set [_forEachIndex, _rest deleteAt 0]};
} forEach _buttons;

private _pages = [];
for "_p" from 0 to (NET_PAGES - 1) do {
    private _on = (_buttons select [_p * NET_PAGE_SIZE, NET_PAGE_SIZE]) findIf {_x isNotEqualTo []};
    if (_on >= 0) then {_pages pushBack _p};
};

private _page = _pages param [0, 0];
{
    if (_x <= GVAR(netPage)) then {_page = _x};
} forEach _pages;

if (_ring isNotEqualTo []) then {
    private _first = _page * NET_PAGE_SIZE;
    private _free = (_buttons select [_first, NET_PAGE_SIZE]) findIf {_x isEqualTo []};
    _buttons set [_first + ([NET_PAGE_SIZE - 1, _free] select (_free >= 0)), _ring select 0];
    _pages pushBackUnique _page;
    _pages sort true;
};

[_buttons, _page, _pages]
