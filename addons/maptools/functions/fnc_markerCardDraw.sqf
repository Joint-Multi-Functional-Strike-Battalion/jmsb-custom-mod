#include "script_component.hpp"
/*
 * Author: YonV
 * Draws the marker card from its state (QGVAR(cardState)): built afresh on
 * every pick, beside its point on the map, inside the host.
 *
 *   MARK / EDIT MARK                     the point's ten-digit grid   (ink band)
 *   the tabs, one row: BASIC MIL BLU OPF IND CIV FLAG JMSB
 *   a page of the tab's icons, square cells six to a row
 *   <                  2 / 4                  >
 *   the colours: square swatches, nine to a row
 *   S  M  L                   <    045°    >
 *   the text box - Enter places
 *   the channels: MY MAP, then each the engine allows now
 *   PLACE   CANCEL   (DELETE, on a marker of his own)
 *
 * (user, 2026-11-02: "need more map markers in the map marker solution" - "and
 * all that are in this mod" - and the card "is ugly"). The icons and colours
 * are the game's whole useful set and this mod's, from FUNC(markerCardCatalog);
 * the header is an app's ink band; every row stands in one column with the same
 * margin and the same air between sections; PLACE is the one filled button.
 *
 * NEVER TALLER THAN THE HOST: the icon grid gets the rows the host has left
 * after everything else (CARD_PAGE_ROWS at most, one at least), and the pager
 * turns the rest.
 *
 * The picked icon in the picked colour, size and direction stands on the map
 * at the point while the card is open (QGVAR(cardPreview), drawn by
 * FUNC(draw)), as the game's dialog shows its marker.
 *
 * Only the tacpad's primitives and theme tokens; the colour swatches are the
 * marker colours themselves, the one thing a swatch is for. Default's swatch
 * is the picked icon's own colour - what Default gives it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_maptools_fnc_markerCardDraw
 *
 * Public: No
 */

private _state = uiNamespace getVariable [QGVAR(cardState), createHashMap];
private _map = _state getOrDefault ["map", controlNull];

ctrlDelete (uiNamespace getVariable [QGVAR(card), controlNull]);
if (isNull _map) exitWith {[] call FUNC(markerCardClose)};

private _display = ctrlParent _map;
private _pos = _state get "pos";
private _edit = _state getOrDefault ["edit", ""];
private _type = _state getOrDefault ["type", MARK_TYPE];
private _colour = _state getOrDefault ["color", MARK_COLOR];
private _size = _state getOrDefault ["size", CARD_SIZE_NORMAL];
private _dir = _state getOrDefault ["dir", 0];
private _channels = [] call FUNC(markerChannels);
private _colours = ([] call FUNC(markerCardCatalog)) # 1;

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];
private _dim = ["dim"] call EFUNC(tacpad,theme);

// THE COLUMN. Every row runs from the margin to the margin; a row of cells is
// laid across _span - the column and the one pad each cell leaves after it.
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mx = CARD_MARGIN * _pad;
private _my = CARD_MARGIN * _padY;
private _gap = CARD_GAP * _padY;
private _rowH = ([TEXT_BODY] call EFUNC(tacpad,textH)) + 2 * _padY;
private _headH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;
private _w = CARD_W * HOST_W;
private _colW = _w - 2 * _mx;
private _span = _colW + _pad;

// SQUARE CELLS: a cell's drawn width made the same number of pixels high.
private _iconW = _span / CARD_COLS;
private _iconH = (((_iconW - _pad) * pixelH / pixelW) + _padY) min (CARD_ICON_ROWS * _rowH);
private _swatchW = _span / CARD_SWATCH_COLS;
private _swatchH = (((_swatchW - _pad) * pixelH / pixelW) + _padY) min _rowH;
private _swatchRows = (ceil (count _colours / CARD_SWATCH_COLS)) max 1;

// Top to bottom. Everything under the icon grid first, so the grid gets what
// is left of the host.
private _yTabs = _headH + _gap;
private _yGrid = _yTabs + _rowH + _gap;
private _below = _rowH + _gap + _swatchRows * _swatchH + 4 * (_gap + _rowH) + _my;
private _pageRows = ((floor ((HOST_H - _yGrid - _below) / _iconH)) min CARD_PAGE_ROWS) max 1;
private _yPager = _yGrid + _pageRows * _iconH;
private _yColors = _yPager + _rowH + _gap;
private _yStyle = _yColors + _swatchRows * _swatchH + _gap;
private _yText = _yStyle + _rowH + _gap;
private _yChannels = _yText + _rowH + _gap;
private _yButtons = _yChannels + _rowH + _gap;
private _h = _yButtons + _rowH - _padY + _my;

// BESIDE THE POINT, never over it: to its right, or its left where the right
// runs out of host, and held inside the host either way.
(_map ctrlMapWorldToScreen _pos) params ["_sx", "_sy"];
private _offset = CARD_OFFSET * HOST_W;
private _cardX = _sx + _offset;
if (_cardX + _w > HOST_X + HOST_W) then {
    _cardX = _sx - _offset - _w;
};
_cardX = (_cardX max HOST_X) min (HOST_X + HOST_W - _w);
private _cardY = ((_sy - _h / 2) max HOST_Y) min (HOST_Y + HOST_H - _h);

private _card = _display ctrlCreate [QEGVAR(tacpad,panel), -1];
_card ctrlSetPosition [_cardX, _cardY, _w, _h];
_card ctrlCommit 0;
uiNamespace setVariable [QGVAR(card), _card];

// Solid ground: the card stands over map detail, and the panels' opacity
// setting is for panels that sit there all the time.
[_card, [0, 0, _w, _h], _solid] call EFUNC(tacpad,drawFill);
[_card, [0, 0, _w, _h], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);

// THE HEADER, as an app's: an ink band, the title in the ground, the grid
// right-aligned in the value face.
[_card, [0, 0, _w, _headH], _ink] call EFUNC(tacpad,drawFill);
[_card, [_mx, 0, _colW, _headH], ["MARK", "EDIT MARK"] select (_edit isNotEqualTo ""), _solid, TEXT_TITLE, true] call EFUNC(tacpad,drawText);
[_card, [_mx, 0, _colW, _headH], [_pos] call FUNC(gridText), _solid, TEXT_BODY, false, "right", false, FONT_MONO] call EFUNC(tacpad,drawText);

[_card, [_mx, _span], [_yTabs, _yGrid, _yPager], [_rowH, _iconH, _pageRows]] call FUNC(markerCardIcons);

// THE COLOURS. Default draws the picked icon in its own colour, so its swatch
// is that colour - the ink where the icon has none a swatch can show.
private _ownColour = _ink;
private _ownCfg = configFile >> "CfgMarkers" >> _type >> "color";
if (count getArray _ownCfg == 4) then {
    _ownColour = _ownCfg call BIS_fnc_colorConfigToRGBA;
};
[
    _card, [_mx, _yColors, _span, _swatchH],
    _colours apply {
        _x params ["_class", "_name", "_rgba"];
        ["", "", [_rgba, _ownColour] select (_class isEqualTo CARD_COLOR_DEFAULT), _class, _name]
    },
    _colour, "color", CARD_SWATCH_COLS
] call FUNC(markerCardCells);

// SIZE and DIRECTION, one row: S M L on the left half; on the right a turn key
// at each end, a column wide, and the direction between them.
[
    _card, [_mx, _yStyle, _span / 2, _rowH],
    CARD_SIZES apply {[_x # 0, "", [], _x # 1, _x # 2]},
    _size, "size", count CARD_SIZES
] call FUNC(markerCardCells);
private _dirX = _mx + _span / 2;
[_card, [_dirX, _yStyle, _iconW, _rowH], [[CARD_PREV, "", [], (_dir - CARD_DIR_STEP + DEG_PER_TURN) mod DEG_PER_TURN, "Turn left"]], "", "dir", 1] call FUNC(markerCardCells);
[_card, [_mx + _span - _iconW, _yStyle, _iconW, _rowH], [[CARD_NEXT, "", [], (_dir + CARD_DIR_STEP) mod DEG_PER_TURN, "Turn right"]], "", "dir", 1] call FUNC(markerCardCells);
[
    _card, [_dirX + _iconW - _pad, _yStyle, _span / 2 - 2 * _iconW + _pad, _rowH - _padY],
    format [CARD_DIR_FORMAT, [round _dir, CARD_DIR_DIGITS] call CBA_fnc_formatNumber],
    _ink, TEXT_BODY, false, "center", false, FONT_MONO
] call EFUNC(tacpad,drawText);

// THE TEXT BOX, as GO TO GRID's: outlined like its neighbours, a hint under it
// until something is typed, the typed text kept in the state on every key so
// a rebuild never loses it. Enter places.
private _boxRect = [_mx, _yText, _colW, _rowH - _padY];
[_card, _boxRect, _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
private _typed = _state getOrDefault ["text", ""];
private _inner = [_mx + _pad, _yText, _colW - 2 * _pad, _rowH - _padY];
private _hint = [_card, _inner, CARD_TEXT_HINT, _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
_hint ctrlShow (_typed isEqualTo "");
private _box = _display ctrlCreate [QEGVAR(tacpad,input), -1, _card];
_box ctrlSetPosition _inner;
_box ctrlSetBackgroundColor [0, 0, 0, 0];
_box ctrlSetTextColor _ink;
_box ctrlSetFontHeight (_rowH * CARD_EDIT_FONT_K);
_box ctrlSetText _typed;
_box ctrlCommit 0;
_box setVariable [QGVAR(cardHint), _hint];
_box ctrlAddEventHandler ["KeyUp", {
    params ["_ctrl"];
    (uiNamespace getVariable [QGVAR(cardState), createHashMap]) set ["text", ctrlText _ctrl];
    (_ctrl getVariable [QGVAR(cardHint), controlNull]) ctrlShow ((ctrlText _ctrl) isEqualTo "");
    false
}];
_box ctrlAddEventHandler ["KeyDown", {
    params ["_ctrl", "_key"];
    if !(_key in [KEY_ENTER, KEY_NUMPAD_ENTER]) exitWith {false};
    (uiNamespace getVariable [QGVAR(cardState), createHashMap]) set ["text", ctrlText _ctrl];
    {[] call FUNC(markerCardPlace)} call CBA_fnc_execNextFrame;
    true
}];

[
    _card, [_mx, _yChannels, _span, _rowH],
    _channels apply {[_x # 1, "", [], _x # 0, ""]},
    _state get "channel", "channel", count _channels
] call FUNC(markerCardCells);

// PLACE in the accent fill - the one thing the card is for; CANCEL outlined;
// DELETE outlined in the accent, on a marker of his own only.
private _buttons = [["PLACE", "place"], ["CANCEL", "cancel"]];
if (_edit isNotEqualTo "") then {
    _buttons pushBack ["DELETE", "delete"];
};
private _buttonW = _span / count _buttons;
{
    _x params ["_label", "_act"];
    private _rect = [_mx + _forEachIndex * _buttonW, _yButtons, _buttonW - _pad, _rowH - _padY];
    private _primary = _act isEqualTo "place";
    private _tone = [_ink, _accent] select (_act isEqualTo "delete");
    if (_primary) then {
        [_card, _rect, _accent] call EFUNC(tacpad,drawFill);
    } else {
        [_card, _rect, _tone, RULE_THICK] call EFUNC(tacpad,drawFrame);
    };
    [_card, _rect, _label, [_tone, _solid] select _primary, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    private _hit = [_card, _rect, {
        params ["_ctrl"];
        // Next frame: every button here goes with the card.
        [{
            params ["_act"];
            switch (_act) do {
                case "place": {[] call FUNC(markerCardPlace)};
                case "delete": {
                    [(uiNamespace getVariable [QGVAR(cardState), createHashMap]) getOrDefault ["edit", ""]] call FUNC(markerDelete);
                    [] call FUNC(markerCardClose);
                };
                default {[] call FUNC(markerCardClose)};
            };
        }, [_ctrl getVariable [QGVAR(cardAct), ""]]] call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(cardAct), _act];
} forEach _buttons;

ctrlSetFocus _box;

// THE PREVIEW: the icon in the picked colour - Default its own - at the
// picked size and direction.
private _previewColour = _ownColour;
if (_colour isNotEqualTo CARD_COLOR_DEFAULT) then {
    private _at = _colours findIf {(_x # 0) isEqualTo _colour};
    if (_at > -1) then {
        _previewColour = (_colours # _at) # 2;
    };
};
GVAR(cardPreview) = [_pos, getText (configFile >> "CfgMarkers" >> _type >> "icon"), _previewColour, _size, _dir];
