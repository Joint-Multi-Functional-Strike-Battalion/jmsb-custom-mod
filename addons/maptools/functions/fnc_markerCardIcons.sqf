#include "script_component.hpp"
/*
 * Author: YonV
 * The marker card's icons (user, 2026-11-02: "need more map markers in the map
 * marker solution"): the tabs in one row, a page of the open tab's icons in an
 * even grid, and the pager under it.
 *
 *   BASIC  MIL  BLU  OPF  IND  CIV  FLAG  JMSB
 *   [ ][ ][ ][ ][ ][ ]
 *   [ ][ ][ ][ ][ ][ ]      as many rows as the host has room for
 *   <        2 / 4        >
 *
 * THE OPEN TAB is the one last pressed; on opening, the one holding the picked
 * icon. THE PAGE turns with the pager (it wraps, so neither key is ever dead)
 * and, when the tab changes, starts on the page holding the picked icon - or
 * the first. Both are kept in the card's state ("tab", "page", "pageTab"). One
 * page, no pager keys: only the readout.
 *
 * Each icon is drawn with its own texture - a shape in the ink, a flag or this
 * mod's picture in its own colours - and named on hover.
 *
 * Arguments:
 * 0: The card <CONTROL>
 * 1: [x, w] - where the column starts, and its width with the cells' trailing
 *    pad <ARRAY>
 * 2: [tabs y, grid y, pager y] <ARRAY>
 * 3: [row height, icon cell height, icon rows a page] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_card, [_x, _w], [_yTabs, _yGrid, _yPager], [_rowH, _iconH, 4]] call jmfsb_maptools_fnc_markerCardIcons
 *
 * Public: No
 */

params [
    ["_card", controlNull, [controlNull]],
    ["_span", [0, 0], [[]], 2],
    ["_ys", [0, 0, 0], [[]], 3],
    ["_sizes", [0, 0, 1], [[]], 3]
];

if (isNull _card) exitWith {};

_span params ["_x0", "_w"];
_ys params ["_yTabs", "_yGrid", "_yPager"];
_sizes params ["_rowH", "_iconH", "_pageRows"];

private _state = uiNamespace getVariable [QGVAR(cardState), createHashMap];
private _tabs = ([] call FUNC(markerCardCatalog)) # 0;
if (_tabs isEqualTo []) exitWith {};

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _padY = PAD * HOST_H;
private _type = _state getOrDefault ["type", MARK_TYPE];

// The open tab: the one asked for, else the one holding the picked icon.
private _tabId = _state getOrDefault ["tab", ""];
private _ti = _tabs findIf {(_x # 0) isEqualTo _tabId};
if (_ti < 0) then {
    _ti = (_tabs findIf {((_x # 4) findIf {(_x # 0) isEqualTo _type}) > -1}) max 0;
};
(_tabs # _ti) params ["_id", "", "", "_own", "_types"];

private _perPage = CARD_COLS * _pageRows;
private _pages = (ceil (count _types / _perPage)) max 1;
private _page = _state getOrDefault ["page", 0];
if ((_state getOrDefault ["pageTab", ""]) isNotEqualTo _id) then {
    private _at = _types findIf {(_x # 0) isEqualTo _type};
    _page = [0, floor (_at / _perPage)] select (_at > -1);
};
_page = (_page max 0) min (_pages - 1);
_state set ["tab", _id];
_state set ["page", _page];
_state set ["pageTab", _id];

[
    _card, [_x0, _yTabs, _w, _rowH],
    _tabs apply {[_x # 1, "", [], _x # 0, _x # 2]},
    _id, "tab", count _tabs
] call FUNC(markerCardCells);

[
    _card, [_x0, _yGrid, _w, _iconH],
    (_types select [_page * _perPage, _perPage]) apply {["", _x # 1, [], _x # 0, _x # 2, _own]},
    _type, "type", CARD_COLS
] call FUNC(markerCardCells);

// THE PAGER: a key at each end, a column wide, the readout centred in the
// column between them.
private _pad = PAD * HOST_W;
private _keyW = _w / CARD_COLS;
if (_pages > 1) then {
    [_card, [_x0, _yPager, _keyW, _rowH], [[CARD_PREV, "", [], (_page - 1 + _pages) mod _pages, "Previous page"]], "", "page", 1] call FUNC(markerCardCells);
    [_card, [_x0 + _w - _keyW, _yPager, _keyW, _rowH], [[CARD_NEXT, "", [], (_page + 1) mod _pages, "Next page"]], "", "page", 1] call FUNC(markerCardCells);
};
[_card, [_x0 + _keyW - _pad, _yPager, _w - 2 * _keyW + _pad, _rowH - _padY], format [CARD_PAGE_FORMAT, _page + 1, _pages], _ink, TEXT_BODY, false, "center", false, FONT_MONO] call EFUNC(tacpad,drawText);
